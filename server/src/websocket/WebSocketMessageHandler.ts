import { WebSocket } from "ws";
import { GameSession } from "../types/game.types.js";
import { GameController } from "../game/GameController.js";

export class WebSocketMessageHandler {
  private gameController: GameController;
  private activeGames: Map<string, GameSession>;

  constructor(activeGames: Map<string, GameSession>) {
    this.gameController = new GameController();
    this.activeGames = activeGames;
  }

  public handleMessage(message: string, clientId: string, ws: WebSocket): void {
    try {
      const data = JSON.parse(message);

      switch (data.type) {
        case "definirNome":
          this.handleSetPlayerName(data.payload, clientId);
          break;
        case "moverPeca":
          const session = this.findGameByPlayerId(clientId);
          if (!session) {
            console.warn(`Sessão não encontrada para cliente ${clientId}`);
            return;
          }
          this.handleMoveRequest(data.payload, session, clientId, ws);
          break;
        default:
          console.warn(`Tipo de mensagem desconhecido: ${data.type}`);
      }
    } catch (error) {
      console.error("Erro ao processar mensagem:", error);
      this.sendErrorMessage(ws, "Erro ao processar mensagem do cliente.");
    }
  }

  private handleSetPlayerName(payload: any, clientId: string): void {
    const { nome } = payload;
    if (nome && typeof nome === "string") {
      console.log(
        `Recebida solicitação para definir nome: ${nome} para cliente ${clientId}`
      );

      // Encontra o jogador e atualiza seu nome em jogos ativos
      let nomeAtualizado = false;
      for (const session of this.activeGames.values()) {
        const jogador = session.jogadores.find((j) => j.id === clientId);
        if (jogador) {
          console.log(
            `Atualizando nome do jogador em sessão ativa: ${jogador.nome} -> ${nome}`
          );
          // Atualiza o nome no jogador da sessão
          jogador.nome = nome;
          // Atualiza o nome no estado do jogo
          const jogadorEstado = session.estadoJogo.jogadores.find(
            (j) => j.id === clientId
          );
          if (jogadorEstado) {
            jogadorEstado.nome = nome;
            this.broadcastGameState(session);
          }
          nomeAtualizado = true;
          break;
        }
      }

      if (!nomeAtualizado) {
        console.log(
          `Jogador ${clientId} não encontrado em sessões ativas. Pode estar aguardando partida.`
        );
      }

      console.log(`Nome do jogador ${clientId} definido como: ${nome}`);
    }
  }

  private handleMoveRequest(
    payload: any,
    session: GameSession,
    clientId: string,
    ws: WebSocket
  ): void {
    const { idPeca, novaPosicao } = payload;

    if (!idPeca || !novaPosicao) {
      this.sendErrorMessage(ws, "Dados de movimento inválidos.");
      return;
    }

    const result = this.gameController.moverPeca(
      session.estadoJogo,
      idPeca,
      novaPosicao,
      clientId
    );

    if (result.novoEstado) {
      session.estadoJogo = result.novoEstado;
      this.broadcastGameState(session);
    } else if (result.erro) {
      this.sendErrorMessage(ws, result.erro);
    }
  }

  private findGameByPlayerId(clientId: string): GameSession | undefined {
    for (const session of this.activeGames.values()) {
      if (session.jogadores.some((j) => j.id === clientId)) {
        return session;
      }
    }
    return undefined;
  }

  private broadcastGameState(session: GameSession): void {
    const estadoParaCliente = session.estadoJogo;
    const message = JSON.stringify({
      type: "atualizacaoEstado",
      payload: estadoParaCliente,
    });

    session.jogadores.forEach((player) => {
      if (player.ws.readyState === WebSocket.OPEN) {
        player.ws.send(message);
      }
    });
  }

  private sendErrorMessage(ws: WebSocket, mensagem: string): void {
    if (ws.readyState === WebSocket.OPEN) {
      ws.send(
        JSON.stringify({
          type: "erroMovimento",
          payload: { mensagem },
        })
      );
    }
  }
}
