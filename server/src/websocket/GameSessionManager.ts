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
        nome: `Aguardando nome...`, // Nome será atualizado quando receber mensagem definirNome
        equipe: Equipe.Preta,
        ws,
      };

      this.sendMessage(ws, "mensagemServidor", "Aguardando outro jogador...");
    } else {
      this.createNewGame(clientId, ws);
    }

    this.setupWebSocketHandlers(ws, clientId);
  }

  /**
   * Handles reconnection attempt by a player
   */
  public handleReconnection(ws: WebSocket, playerId: string): boolean {
    console.log(`🔄 Tentativa de reconexão do jogador ${playerId}`);

    // Try to reconnect during placement phase
    const reconnected = this.messageHandler.handlePlayerReconnection(
      playerId,
      ws
    );

    if (reconnected) {
      // Setup handlers for the reconnected player
      this.setupWebSocketHandlers(ws, playerId);
      console.log(`✅ Jogador ${playerId} reconectado com sucesso`);
      return true;
    }

    // If not in placement, check if player is in an active game
    const session = this.findGameByPlayerId(playerId);
    if (session) {
      // Update WebSocket for the player
      const player = session.jogadores.find((j) => j.id === playerId);
      if (player) {
        player.ws = ws;
        this.setupWebSocketHandlers(ws, playerId);

        // Send current game state
        this.broadcastGameState(session);

        // Notify opponent of reconnection
        const opponent = session.jogadores.find((j) => j.id !== playerId);
        if (opponent) {
          this.sendMessage(
            opponent.ws,
            "mensagemServidor",
            "O oponente reconectou."
          );
        }

        console.log(`✅ Jogador ${playerId} reconectado ao jogo em andamento`);
        return true;
      }
    }

    console.log(
      `❌ Falha na reconexão do jogador ${playerId} - sessão não encontrada`
    );
    return false;
  }

  private createNewGame(clientId: string, ws: WebSocket): void {
    const player1 = this.pendingClient!;
    const player2 = {
      id: clientId,
      nome: `Aguardando nome...`, // Nome será atualizado quando receber mensagem definirNome
      equipe: Equipe.Verde,
      ws,
    };

    this.pendingClient = null;

    console.log(`Pareamento realizado entre ${player1.nome} e ${player2.nome}`);

    const gameId = uuidv4();

    // Create empty initial game state (pieces will be added after placement)
    const estadoInicial = GameStateManager.createEmptyGameState(
      gameId,
      { id: player1.id, nome: player1.nome, equipe: player1.equipe },
      { id: player2.id, nome: player2.nome, equipe: player2.equipe }
    );

    const session: GameSession = {
      id: gameId,
      jogadores: [player1, player2],
      estadoJogo: estadoInicial,
    };

    this.activeGames.set(gameId, session);

    // Initialize placement phase instead of starting game immediately
    this.messageHandler.initializePlacementPhase(session);

    console.log(`🎯 Fase de posicionamento iniciada para sessão ${gameId}`);
  }

  private setupWebSocketHandlers(ws: WebSocket, clientId: string): void {
    ws.on("message", (message: string) => {
      // Primeiro verifica se é uma mensagem de definir nome para jogador pendente
      try {
        const data = JSON.parse(message);
        if (
          data.type === "definirNome" &&
          this.pendingClient &&
          this.pendingClient.id === clientId
        ) {
          const { nome } = data.payload;
          if (nome && typeof nome === "string") {
            console.log(
              `Atualizando nome do jogador pendente: ${this.pendingClient.nome} -> ${nome}`
            );
            this.pendingClient.nome = nome;
          }
        }
      } catch (e) {
        // Ignora erros de parsing, deixa o handler principal processar
      }

      this.messageHandler.handleMessage(message, clientId, ws);
    });

    ws.on("close", () => {
      this.handleDisconnection(clientId);
    });
  }

  private handleDisconnection(clientId: string): void {
    console.log(`🔌 Cliente ${clientId} desconectado`);

    if (this.pendingClient && this.pendingClient.id === clientId) {
      this.pendingClient = null;
      return;
    }

    const session = this.findGameByPlayerId(clientId);
    if (session) {
      // Check if this is during placement phase
      const placementState = this.messageHandler.getPlacementState(
        session.id,
        clientId
      );

      if (placementState) {
        // Handle disconnection during placement
        console.log(
          `🎯 Desconexão durante posicionamento detectada para jogador ${clientId}`
        );
        this.messageHandler.handlePlayerDisconnection(clientId);
      } else {
        // Handle disconnection during regular game
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
