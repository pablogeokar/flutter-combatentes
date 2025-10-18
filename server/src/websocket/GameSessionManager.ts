import { WebSocket } from "ws";
import { v4 as uuidv4 } from "uuid";
import { Jogador, Equipe, GameSession } from "../types/game.types.js";
import { GameStateManager } from "../game/GameStateManager.js";
import { WebSocketMessageHandler } from "./WebSocketMessageHandler.js";

export class GameSessionManager {
  private pendingClient: Jogador | null = null;
  private activeGames = new Map<string, GameSession>();
  private messageHandler: WebSocketMessageHandler;

  constructor() {
    this.messageHandler = new WebSocketMessageHandler(this.activeGames);
  }

  public handleNewConnection(ws: WebSocket): void {
    console.log("Cliente conectado.");
    const clientId = uuidv4();

    if (!this.pendingClient) {
      this.pendingClient = {
        id: clientId,
        nome: `Jogador 1`,
        equipe: Equipe.Preta,
        ws,
      };

      this.sendMessage(ws, "mensagemServidor", "Aguardando outro jogador...");
    } else {
      this.createNewGame(clientId, ws);
    }

    this.setupWebSocketHandlers(ws, clientId);
  }

  private createNewGame(clientId: string, ws: WebSocket): void {
    const player1 = this.pendingClient!;
    const player2 = {
      id: clientId,
      nome: `Jogador 2`,
      equipe: Equipe.Verde,
      ws,
    };

    this.pendingClient = null;

    console.log(`Partida iniciada entre ${player1.id} e ${player2.id}`);

    const gameId = uuidv4();
    const estadoInicial = GameStateManager.createInitialGameState(
      gameId,
      player1,
      player2
    );

    const session: GameSession = {
      id: gameId,
      jogadores: [player1, player2],
      estadoJogo: estadoInicial,
    };

    this.activeGames.set(gameId, session);
    this.broadcastGameState(session);
  }

  private setupWebSocketHandlers(ws: WebSocket, clientId: string): void {
    ws.on("message", (message: string) => {
      this.messageHandler.handleMessage(message, clientId, ws);
    });

    ws.on("close", () => {
      this.handleDisconnection(clientId);
    });
  }

  private handleDisconnection(clientId: string): void {
    console.log("Cliente desconectado.");

    if (this.pendingClient && this.pendingClient.id === clientId) {
      this.pendingClient = null;
    }

    const session = this.findGameByPlayerId(clientId);
    if (session) {
      const otherPlayer = session.jogadores.find((j) => j.id !== clientId);
      if (otherPlayer) {
        this.sendMessage(
          otherPlayer.ws,
          "mensagemServidor",
          "O oponente desconectou."
        );
      }
      this.activeGames.delete(session.id);
    }
  }

  public broadcastGameState(session: GameSession): void {
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

  public findGameByPlayerId(clientId: string): GameSession | undefined {
    for (const session of this.activeGames.values()) {
      if (session.jogadores.some((j) => j.id === clientId)) {
        return session;
      }
    }
    return undefined;
  }

  private sendMessage(ws: WebSocket, type: string, payload: any): void {
    if (ws.readyState === WebSocket.OPEN) {
      ws.send(JSON.stringify({ type, payload }));
    }
  }
}
