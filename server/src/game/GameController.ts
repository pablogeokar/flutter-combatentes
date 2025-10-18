import {
  EstadoJogo,
  PecaJogo,
  PosicaoTabuleiro,
  Jogador,
  Equipe,
  Patentes,
  ResultadoMovimento,
  ResultadoCombate,
} from "../types/game.types.js";

export class GameController {
  private static readonly lagos: Set<string> = new Set([
    "4-2",
    "4-3",
    "5-2",
    "5-3",
    "4-6",
    "4-7",
    "5-6",
    "5-7",
  ]);

  public moverPeca(
    estadoAtual: EstadoJogo,
    idPeca: string,
    novaPosicao: PosicaoTabuleiro,
    idJogadorQueSolicitou: string
  ): ResultadoMovimento {
    const pecaAMover = estadoAtual.pecas.find((p) => p.id === idPeca);
    if (!pecaAMover) return { erro: "Peça não encontrada." };

    const jogadorAtual = estadoAtual.jogadores.find(
      (j) => j.id === idJogadorQueSolicitou
    );
    if (!jogadorAtual || jogadorAtual.equipe !== pecaAMover.equipe) {
      return { erro: "Peça não pertence ao jogador." };
    }

    if (estadoAtual.idJogadorDaVez !== idJogadorQueSolicitou) {
      return { erro: "Não é o seu turno." };
    }

    const erroMovimento = this.validarMovimento(
      pecaAMover,
      novaPosicao,
      estadoAtual.pecas
    );
    if (erroMovimento) return { erro: erroMovimento };

    let pecasAtualizadas = [...estadoAtual.pecas];
    const pecaDefensora = pecasAtualizadas.find(
      (p) =>
        p.posicao.linha === novaPosicao.linha &&
        p.posicao.coluna === novaPosicao.coluna
    );

    if (pecaDefensora) {
      const resultadoCombate = this.resolverCombate(pecaAMover, pecaDefensora);
      pecasAtualizadas = this.processarCombate(
        pecasAtualizadas,
        pecaAMover,
        pecaDefensora,
        novaPosicao,
        resultadoCombate
      );
    } else {
      const indicePeca = pecasAtualizadas.findIndex((p) => p.id === idPeca);
      pecasAtualizadas[indicePeca] = { ...pecaAMover, posicao: novaPosicao };
    }

    const proximoJogador = estadoAtual.jogadores.find(
      (j) => j.id !== estadoAtual.idJogadorDaVez
    )!;

    const estadoIntermediario: EstadoJogo = {
      ...estadoAtual,
      pecas: pecasAtualizadas,
      idJogadorDaVez: proximoJogador.id,
    };

    const estadoFinal = this.verificarVitoria(
      estadoIntermediario,
      jogadorAtual
    );
    return { novoEstado: estadoFinal };
  }

  private validarMovimento(
    peca: PecaJogo,
    novaPosicao: PosicaoTabuleiro,
    pecas: PecaJogo[]
  ): string | null {
    if (peca.patente === "minaTerrestre" || peca.patente === "prisioneiro")
      return "Esta peça não pode se mover.";

    if (
      peca.posicao.linha === novaPosicao.linha &&
      peca.posicao.coluna === novaPosicao.coluna
    )
      return "Movimento inválido.";

    if (
      peca.posicao.linha !== novaPosicao.linha &&
      peca.posicao.coluna !== novaPosicao.coluna
    )
      return "Movimentos na diagonal não são permitidos.";

    if (GameController.lagos.has(`${novaPosicao.linha}-${novaPosicao.coluna}`))
      return "Não é possível mover para um lago.";

    const pecaNoDestino = pecas.find(
      (p) =>
        p.posicao.linha === novaPosicao.linha &&
        p.posicao.coluna === novaPosicao.coluna
    );
    if (pecaNoDestino && pecaNoDestino.equipe === peca.equipe)
      return "Não é possível mover para uma casa ocupada por uma peça aliada.";

    const distancia =
      Math.abs(peca.posicao.linha - novaPosicao.linha) +
      Math.abs(peca.posicao.coluna - novaPosicao.coluna);

    if (peca.patente !== "soldado" && distancia > 1)
      return "Esta peça só pode se mover uma casa por vez.";

    // Validação de caminho livre para o soldado
    if (peca.patente === "soldado" && distancia > 1) {
      return this.validarCaminhoSoldado(peca.posicao, novaPosicao, pecas);
    }

    return null;
  }

  private validarCaminhoSoldado(
    posicaoAtual: PosicaoTabuleiro,
    novaPosicao: PosicaoTabuleiro,
    pecas: PecaJogo[]
  ): string | null {
    if (posicaoAtual.linha === novaPosicao.linha) {
      // Movimento horizontal
      const direcao = novaPosicao.coluna > posicaoAtual.coluna ? 1 : -1;
      for (
        let c = posicaoAtual.coluna + direcao;
        c !== novaPosicao.coluna;
        c += direcao
      ) {
        if (
          pecas.some(
            (p) =>
              p.posicao.linha === posicaoAtual.linha && p.posicao.coluna === c
          )
        ) {
          return "O caminho do soldado está bloqueado.";
        }
      }
    } else {
      // Movimento vertical
      const direcao = novaPosicao.linha > posicaoAtual.linha ? 1 : -1;
      for (
        let l = posicaoAtual.linha + direcao;
        l !== novaPosicao.linha;
        l += direcao
      ) {
        if (
          pecas.some(
            (p) =>
              p.posicao.linha === l && p.posicao.coluna === posicaoAtual.coluna
          )
        ) {
          return "O caminho do soldado está bloqueado.";
        }
      }
    }
    return null;
  }

  private resolverCombate(
    atacante: PecaJogo,
    defendida: PecaJogo
  ): ResultadoCombate {
    // Regra especial: Agente Secreto vs General
    if (atacante.patente === "agenteSecreto" && defendida.patente === "general")
      return { vencedor: atacante, perdedor: defendida };

    // Regra especial: Mina Terrestre
    if (defendida.patente === "minaTerrestre") {
      return atacante.patente === "cabo"
        ? { vencedor: atacante, perdedor: defendida }
        : { vencedor: defendida, perdedor: atacante };
    }

    // Combate padrão por força
    const forcaAtacante = Patentes[atacante.patente]?.forca || 0;
    const forcaDefendida = Patentes[defendida.patente]?.forca || 0;

    if (forcaAtacante > forcaDefendida)
      return { vencedor: atacante, perdedor: defendida };
    if (forcaDefendida > forcaAtacante)
      return { vencedor: defendida, perdedor: atacante };
    return { vencedor: null, perdedor: null }; // Empate
  }

  private processarCombate(
    pecasAtualizadas: PecaJogo[],
    atacante: PecaJogo,
    defensora: PecaJogo,
    novaPosicao: PosicaoTabuleiro,
    resultado: ResultadoCombate
  ): PecaJogo[] {
    // Remove as peças do combate
    pecasAtualizadas = pecasAtualizadas.filter(
      (p) => p.id !== atacante.id && p.id !== defensora.id
    );

    if (resultado.vencedor) {
      if (resultado.vencedor.id === atacante.id) {
        // Atacante venceu - move para nova posição e revela
        pecasAtualizadas.push({
          ...atacante,
          posicao: novaPosicao,
          foiRevelada: true,
        });
      } else {
        // Defensor venceu - permanece na posição e revela
        pecasAtualizadas.push({
          ...defensora,
          foiRevelada: true,
        });
      }
    }
    // Em caso de empate, ambas as peças são removidas (já filtradas acima)

    return pecasAtualizadas;
  }

  private verificarVitoria(
    estado: EstadoJogo,
    jogadorQueMoveu: Omit<Jogador, "ws">
  ): EstadoJogo {
    const equipeAdversaria =
      jogadorQueMoveu.equipe === Equipe.Preta ? Equipe.Verde : Equipe.Preta;

    // Vitória por capturar o prisioneiro (bandeira) adversário
    const prisioneiroAdversario = estado.pecas.find(
      (p) => p.patente === "prisioneiro" && p.equipe === equipeAdversaria
    );

    if (!prisioneiroAdversario) {
      return { ...estado, jogoTerminou: true, idVencedor: jogadorQueMoveu.id };
    }

    // Vitória por deixar o adversário sem peças móveis
    const pecasMoveisAdversarias = estado.pecas.some(
      (p) =>
        p.equipe === equipeAdversaria &&
        p.patente !== "minaTerrestre" &&
        p.patente !== "prisioneiro"
    );

    if (!pecasMoveisAdversarias) {
      return { ...estado, jogoTerminou: true, idVencedor: jogadorQueMoveu.id };
    }

    return estado;
  }
}
