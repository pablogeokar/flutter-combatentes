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
      const session = this.findGameByPlayerId(clientId);

      if (!session) {
        console.warn(`Sessão não encontrada para cliente ${clientId}`);
        return;
      }

      switch (data.type) {
        case "moverPeca":
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
