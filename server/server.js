
const express = require('express');
const http = require('http');
const { WebSocketServer } = require('ws');
const { v4: uuidv4 } = require('uuid');

// -----------------------------------------------------------------------------
// 1. MODELOS DE DADOS E LÓGICA DO JOGO EM JAVASCRIPT
// -----------------------------------------------------------------------------

const Equipe = {
  Verde: 'verde',
  Preta: 'preta',
};

const Patentes = {
  prisioneiro: { id: 'prisioneiro', forca: 0, nome: 'Prisioneiro' },
  agenteSecreto: { id: 'agenteSecreto', forca: 1, nome: 'Agente Secreto' },
  soldado: { id: 'soldado', forca: 2, nome: 'Soldado' },
  cabo: { id: 'cabo', forca: 3, nome: 'Cabo' },
  sargento: { id: 'sargento', forca: 4, nome: 'Sargento' },
  tenente: { id: 'tenente', forca: 5, nome: 'Tenente' },
  capitao: { id: 'capitao', forca: 6, nome: 'Capitão' },
  major: { id: 'major', forca: 7, nome: 'Major' },
  coronel: { id: 'coronel', forca: 8, nome: 'Coronel' },
  general: { id: 'general', forca: 10, nome: 'General' },
  minaTerrestre: { id: 'minaTerrestre', forca: 11, nome: 'Mina Terrestre' },
};

class GameControllerServer {
  static lagos = new Set([
    '4-2', '4-3', '5-2', '5-3',
    '4-6', '4-7', '5-6', '5-7',
  ]);

  moverPeca(estadoAtual, idPeca, novaPosicao, idJogadorQueSolicitou) {
    const pecaAMover = estadoAtual.pecas.find(p => p.id === idPeca);
    if (!pecaAMover) return { erro: 'Peça não encontrada.' };

    const jogadorAtual = estadoAtual.jogadores.find(j => j.id === idJogadorQueSolicitou);
    if (!jogadorAtual || jogadorAtual.equipe !== pecaAMover.equipe) {
        return { erro: 'Peça não pertence ao jogador.' };
    }

    if (estadoAtual.idJogadorDaVez !== idJogadorQueSolicitou) {
        return { erro: 'Não é o seu turno.' };
    }
    
    const erroMovimento = this._validarMovimento(pecaAMover, novaPosicao, estadoAtual.pecas);
    if (erroMovimento) return { erro: erroMovimento };

    let pecasAtualizadas = [...estadoAtual.pecas];
    const pecaDefensora = pecasAtualizadas.find(p => p.posicao.linha === novaPosicao.linha && p.posicao.coluna === novaPosicao.coluna);

    if (pecaDefensora) {
        const resultadoCombate = this._resolverCombate(pecaAMover, pecaDefensora);
        // A peça defensora é sempre revelada no combate
        const idxDefensora = pecasAtualizadas.findIndex(p => p.id === pecaDefensora.id);
        if(idxDefensora > -1) pecasAtualizadas[idxDefensora].foiRevelada = true;

        pecasAtualizadas = pecasAtualizadas.filter(p => p.id !== resultadoCombate.perdedor?.id);
        
        if (resultadoCombate.vencedor) {
            const idxVencedora = pecasAtualizadas.findIndex(p => p.id === resultadoCombate.vencedor.id);
            if(idxVencedora > -1) {
                pecasAtualizadas[idxVencedora].foiRevelada = true;
                // Se o atacante venceu, ele se move
                if (resultadoCombate.vencedor.id === pecaAMover.id) {
                    pecasAtualizadas[idxVencedora].posicao = novaPosicao;
                }
            }
        } else { // Empate
            pecasAtualizadas = pecasAtualizadas.filter(p => p.id !== pecaAMover.id && p.id !== pecaDefensora.id);
        }
    } else {
        const indicePeca = pecasAtualizadas.findIndex(p => p.id === idPeca);
        pecasAtualizadas[indicePeca].posicao = novaPosicao;
    }

    const proximoJogador = estadoAtual.jogadores.find(j => j.id !== estadoAtual.idJogadorDaVez);
    let estadoIntermediario = { ...estadoAtual, pecas: pecasAtualizadas, idJogadorDaVez: proximoJogador.id };
    
    const estadoFinal = this._verificarVitoria(estadoIntermediario, jogadorAtual);

    return { novoEstado: estadoFinal };
  }

  _validarMovimento(peca, novaPosicao, pecas) {
    if (Patentes[peca.patente].id === 'minaTerrestre' || Patentes[peca.patente].id === 'prisioneiro') return "Esta peça não pode se mover.";
    if (peca.posicao.linha === novaPosicao.linha && peca.posicao.coluna === novaPosicao.coluna) return "Movimento inválido.";
    if (peca.posicao.linha !== novaPosicao.linha && peca.posicao.coluna !== novaPosicao.coluna) return "Movimentos na diagonal não são permitidos.";
    if (GameControllerServer.lagos.has(`${novaPosicao.linha}-${novaPosicao.coluna}`)) return "Não é possível mover para um lago.";

    const pecaNoDestino = pecas.find(p => p.posicao.linha === novaPosicao.linha && p.posicao.coluna === novaPosicao.coluna);
    if (pecaNoDestino && pecaNoDestino.equipe === peca.equipe) return "Não é possível mover para uma casa ocupada por uma peça aliada.";

    const distancia = Math.abs(peca.posicao.linha - novaPosicao.linha) + Math.abs(peca.posicao.coluna - novaPosicao.coluna);
    if (Patentes[peca.patente].id !== 'soldado' && distancia > 1) return "Esta peça só pode se mover uma casa por vez.";
    
    return null;
  }

  _resolverCombate(atacante, defendida) {
    const forcaAtacante = Patentes[atacante.patente].forca;
    const forcaDefendida = Patentes[defendida.patente].forca;

    if (Patentes[atacante.patente].id === 'agenteSecreto' && Patentes[defendida.patente].id === 'general') return { vencedor: atacante, perdedor: defendida };
    if (Patentes[defendida.patente].id === 'minaTerrestre') {
        return Patentes[atacante.patente].id === 'cabo' ? { vencedor: atacante, perdedor: defendida } : { vencedor: defendida, perdedor: atacante };
    }
    if (forcaAtacante > forcaDefendida) return { vencedor: atacante, perdedor: defendida };
    if (forcaDefendida > forcaAtacante) return { vencedor: defendida, perdedor: atacante };
    return { vencedor: null, perdedor: null }; // Empate
  }

  _verificarVitoria(estado, jogadorQueMoveu) {
      const equipeAdversaria = jogadorQueMoveu.equipe === Equipe.Preta ? Equipe.Verde : Equipe.Preta;
      const prisioneiroAdversario = estado.pecas.find(p => p.patente === 'prisioneiro' && p.equipe === equipeAdversaria);

      if (!prisioneiroAdversario) {
          return { ...estado, jogoTerminou: true, idVencedor: jogadorQueMoveu.id };
      }
      
      const pecasMoveisAdversarias = estado.pecas.some(p => p.equipe === equipeAdversaria && p.patente !== 'minaTerrestre' && p.patente !== 'prisioneiro');
      if (!pecasMoveisAdversarias) {
          return { ...estado, jogoTerminou: true, idVencedor: jogadorQueMoveu.id };
      }

      return estado;
  }
}

// -----------------------------------------------------------------------------
// 3. LÓGICA DO SERVIDOR WEBSOCKET
// -----------------------------------------------------------------------------

const app = express();
const server = http.createServer(app);
const wss = new WebSocketServer({ server });

const PORT = process.env.PORT || 8080;

let pendingClient = null;
const activeGames = new Map();
const gameController = new GameControllerServer();

wss.on('connection', (ws) => {
    console.log('Cliente conectado.');
    const clientId = uuidv4();

    if (!pendingClient) {
        pendingClient = { id: clientId, nome: `Jogador 1`, equipe: Equipe.Preta, ws };
        ws.send(JSON.stringify({ type: 'mensagemServidor', payload: 'Aguardando outro jogador...' }));
    } else {
        const player1 = pendingClient;
        const player2 = { id: clientId, nome: `Jogador 2`, equipe: Equipe.Verde, ws };
        pendingClient = null;

        console.log(`Partida iniciada entre ${player1.id} e ${player2.id}`);
        const gameId = uuidv4();
        const estadoInicial = createInitialGameState(gameId, player1, player2);
        
        const session = {
            id: gameId,
            jogadores: [player1, player2],
            estadoJogo: estadoInicial,
        };
        activeGames.set(gameId, session);

        broadcastGameState(session);
    }

    ws.on('message', (message) => {
        try {
            const data = JSON.parse(message);
            const session = findGameByPlayerId(clientId);
            if (!session) return;

            switch (data.type) {
                case 'moverPeca':
                    const { idPeca, novaPosicao } = data.payload;
                    const result = gameController.moverPeca(session.estadoJogo, idPeca, novaPosicao, clientId);

                    if (result.novoEstado) {
                        session.estadoJogo = result.novoEstado;
                        broadcastGameState(session);
                    } else if (result.erro) {
                        ws.send(JSON.stringify({ type: 'erroMovimento', payload: { mensagem: result.erro } }));
                    }
                    break;
            }
        } catch (error) {
            console.error('Erro ao processar mensagem:', error);
        }
    });

    ws.on('close', () => {
        console.log('Cliente desconectado.');
        if (pendingClient && pendingClient.id === clientId) {
            pendingClient = null;
        }
        const session = findGameByPlayerId(clientId);
        if (session) {
            const otherPlayer = session.jogadores.find(j => j.id !== clientId);
            otherPlayer?.ws.send(JSON.stringify({ type: 'mensagemServidor', payload: 'O oponente desconectou.' }));
            activeGames.delete(session.id);
        }
    });
});

function broadcastGameState(session) {
    // O estado do jogo agora está sempre limpo, então podemos enviá-lo diretamente.
    const estadoParaCliente = session.estadoJogo;
    const message = JSON.stringify({ type: 'atualizacaoEstado', payload: estadoParaCliente });
    session.jogadores.forEach(player => {
        if (player.ws.readyState === 1 /* WebSocket.OPEN */) {
            player.ws.send(message);
        }
    });
}

function findGameByPlayerId(clientId) {
    for (const session of activeGames.values()) {
        if (session.jogadores.some(j => j.id === clientId)) {
            return session;
        }
    }
    return undefined;
}

function createInitialGameState(gameId, p1, p2) {
    // Remove a propriedade 'ws' dos objetos de jogador antes de incluí-los no estado.
    const { ws: ws1, ...player1_clean } = p1;
    const { ws: ws2, ...player2_clean } = p2;

    const pecas = [];
    const contagemPecas = {
      general: 1, coronel: 1, major: 2, capitao: 3, tenente: 4, sargento: 4,
      cabo: 4, soldado: 5, agenteSecreto: 1, prisioneiro: 1, minaTerrestre: 6,
    };

    let posicoesPretas = [];
    for (let i = 0; i < 4; i++) for (let j = 0; j < 10; j++) posicoesPretas.push({ linha: i, coluna: j });
    posicoesPretas.sort(() => Math.random() - 0.5);

    let posIndexPreto = 0;
    for (const key in contagemPecas) {
        for (let i = 0; i < contagemPecas[key]; i++) {
            pecas.push({
                id: `preta_${key}_${i}`,
                patente: key,
                equipe: Equipe.Preta,
                posicao: posicoesPretas[posIndexPreto++],
                foiRevelada: false,
            });
        }
    }

    let posicoesVerdes = [];
    for (let i = 6; i < 10; i++) for (let j = 0; j < 10; j++) posicoesVerdes.push({ linha: i, coluna: j });
    posicoesVerdes.sort(() => Math.random() - 0.5);
    
    let posIndexVerde = 0;
    for (const key in contagemPecas) {
        for (let i = 0; i < contagemPecas[key]; i++) {
            pecas.push({
                id: `verde_${key}_${i}`,
                patente: key,
                equipe: Equipe.Verde,
                posicao: posicoesVerdes[posIndexVerde++],
                foiRevelada: false,
            });
        }
    }

    return {
        idPartida: gameId,
        jogadores: [player1_clean, player2_clean],
        pecas: pecas,
        idJogadorDaVez: p1.id,
        jogoTerminou: false,
        idVencedor: null,
    };
}

server.listen(PORT, () => {
    console.log(`Servidor rodando na porta ${PORT}`);
});
