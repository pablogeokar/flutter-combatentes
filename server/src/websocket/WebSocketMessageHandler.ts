import { WebSocket } from "ws";
import {
  GameSession,
  PlacementMessage,
  PlacementGameState,
  PlacementStatus,
  GamePhase,
} from "../types/game.types.js";
import { GameController } from "../game/GameController.js";

export class WebSocketMessageHandler {
  private gameController: GameController;
  private activeGames: Map<string, GameSession>;
  private placementStates: Map<string, Map<string, PlacementGameState>>; // gameId -> playerId -> state

  constructor(activeGames: Map<string, GameSession>) {
    this.gameController = new GameController();
    this.activeGames = activeGames;
    this.placementStates = new Map();
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
        case "PLACEMENT_UPDATE":
          this.handlePlacementUpdate(data as PlacementMessage, clientId, ws);
          break;
        case "PLACEMENT_READY":
          this.handlePlacementReady(data as PlacementMessage, clientId, ws);
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

    console.log(
      `🎮 Movimento solicitado: Peça ${idPeca} para posição (${novaPosicao.linha}, ${novaPosicao.coluna})`
    );

    const pecasAntes = session.estadoJogo.pecas.length;

    const result = this.gameController.moverPeca(
      session.estadoJogo,
      idPeca,
      novaPosicao,
      clientId
    );

    if (result.novoEstado) {
      const pecasDepois = result.novoEstado.pecas.length;

      if (pecasAntes > pecasDepois) {
        console.log(
          `⚔️ COMBATE DETECTADO! Peças antes: ${pecasAntes}, depois: ${pecasDepois}`
        );
      }

      session.estadoJogo = result.novoEstado;
      this.broadcastGameState(session);
      console.log(`✅ Estado do jogo atualizado e enviado aos clientes`);
    } else if (result.erro) {
      console.log(`❌ Erro no movimento: ${result.erro}`);
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

  // ===== PLACEMENT MESSAGE HANDLERS =====

  /**
   * Handles piece placement updates during placement phase
   */
  private handlePlacementUpdate(
    message: PlacementMessage,
    clientId: string,
    ws: WebSocket
  ): void {
    try {
      const { gameId, data } = message;

      if (!data || !data.patente || !data.position) {
        this.sendPlacementError(ws, "Dados de posicionamento inválidos");
        return;
      }

      // Get or create placement state for this game and player
      let gameStates = this.placementStates.get(gameId);
      if (!gameStates) {
        gameStates = new Map();
        this.placementStates.set(gameId, gameStates);
      }

      let playerState = gameStates.get(clientId);
      if (!playerState) {
        // Create initial placement state
        const session = this.findGameByPlayerId(clientId);
        if (!session) {
          this.sendPlacementError(ws, "Sessão de jogo não encontrada");
          return;
        }

        const player = session.jogadores.find((j) => j.id === clientId);
        if (!player) {
          this.sendPlacementError(ws, "Jogador não encontrado na sessão");
          return;
        }

        playerState = this.gameController
          .getPlacementManager()
          .createInitialPlacementState(gameId, clientId, player.equipe);
        gameStates.set(clientId, playerState);
      }

      // Handle the placement update
      const placementManager = this.gameController.getPlacementManager();

      if (data.pieceId) {
        // Moving existing piece
        const result = placementManager.movePiece(
          playerState,
          data.pieceId,
          data.position
        );
        if (result.success && result.newState) {
          gameStates.set(clientId, result.newState);
          this.sendPlacementStatus(ws, result.newState);
          this.broadcastOpponentStatus(
            gameId,
            clientId,
            result.newState.localStatus
          );
        } else {
          this.sendPlacementError(ws, result.error || "Erro ao mover peça");
        }
      } else {
        // Placing new piece
        const result = placementManager.placePiece(
          playerState,
          data.patente,
          data.position
        );
        if (result.success && result.newState) {
          gameStates.set(clientId, result.newState);
          this.sendPlacementStatus(ws, result.newState);
          this.broadcastOpponentStatus(
            gameId,
            clientId,
            result.newState.localStatus
          );
        } else {
          this.sendPlacementError(
            ws,
            result.error || "Erro ao posicionar peça"
          );
        }
      }
    } catch (error) {
      console.error("Erro ao processar atualização de posicionamento:", error);
      this.sendPlacementError(ws, "Erro interno do servidor");
    }
  }

  /**
   * Handles player ready confirmation
   */
  private handlePlacementReady(
    message: PlacementMessage,
    clientId: string,
    ws: WebSocket
  ): void {
    try {
      const { gameId } = message;

      const gameStates = this.placementStates.get(gameId);
      if (!gameStates) {
        this.sendPlacementError(ws, "Estado de posicionamento não encontrado");
        return;
      }

      const playerState = gameStates.get(clientId);
      if (!playerState) {
        this.sendPlacementError(ws, "Estado do jogador não encontrado");
        return;
      }

      // Confirm placement
      const placementManager = this.gameController.getPlacementManager();
      const result = placementManager.confirmPlacement(playerState);

      if (!result.success || !result.newState) {
        this.sendPlacementError(
          ws,
          result.error || "Não é possível confirmar posicionamento"
        );
        return;
      }

      // Update player state
      gameStates.set(clientId, result.newState);
      this.sendPlacementStatus(ws, result.newState);
      this.broadcastOpponentStatus(gameId, clientId, PlacementStatus.Ready);

      // Check if both players are ready
      const allPlayerStates = Array.from(gameStates.values());
      if (allPlayerStates.length === 2) {
        const bothReady = placementManager.areBothPlayersReady(
          allPlayerStates[0],
          allPlayerStates[1]
        );

        if (bothReady) {
          // Start the game
          this.startGameFromPlacement(gameId, gameStates);
        }
      }
    } catch (error) {
      console.error("Erro ao processar confirmação de posicionamento:", error);
      this.sendPlacementError(ws, "Erro interno do servidor");
    }
  }

  /**
   * Starts the game after both players complete placement
   */
  private startGameFromPlacement(
    gameId: string,
    gameStates: Map<string, PlacementGameState>
  ): void {
    try {
      const session = this.activeGames.get(gameId);
      if (!session) {
        console.error(`Sessão não encontrada para gameId: ${gameId}`);
        return;
      }

      const playerStates = Array.from(gameStates.values());
      if (playerStates.length !== 2) {
        console.error(`Número incorreto de jogadores: ${playerStates.length}`);
        return;
      }

      // Collect all placed pieces
      const player1Pieces = playerStates[0].placedPieces;
      const player2Pieces = playerStates[1].placedPieces;

      // Transition to game start
      const result = this.gameController.transitionToGameStart(
        gameId,
        player1Pieces,
        player2Pieces,
        session.estadoJogo.jogadores
      );

      if (result.success && result.estadoJogo) {
        // Update game session
        session.estadoJogo = result.estadoJogo;

        // Broadcast game start
        this.broadcastGameStart(session);

        // Clean up placement states
        this.placementStates.delete(gameId);

        console.log(`🎮 Jogo iniciado para sessão ${gameId}`);
      } else {
        console.error(`Erro ao iniciar jogo: ${result.error}`);
        // Send error to both players
        session.jogadores.forEach((player) => {
          this.sendPlacementError(
            player.ws,
            result.error || "Erro ao iniciar jogo"
          );
        });
      }
    } catch (error) {
      console.error("Erro ao iniciar jogo a partir do posicionamento:", error);
    }
  }

  /**
   * Sends placement status to player
   */
  private sendPlacementStatus(
    ws: WebSocket,
    placementState: PlacementGameState
  ): void {
    if (ws.readyState === WebSocket.OPEN) {
      ws.send(
        JSON.stringify({
          type: "PLACEMENT_STATUS",
          gameId: placementState.gameId,
          playerId: placementState.playerId,
          data: {
            status: placementState.localStatus,
            allPieces: placementState.placedPieces,
          },
        })
      );
    }
  }

  /**
   * Broadcasts opponent status to other player
   */
  private broadcastOpponentStatus(
    gameId: string,
    senderId: string,
    status: PlacementStatus
  ): void {
    const session = this.activeGames.get(gameId);
    if (!session) return;

    const opponent = session.jogadores.find((j) => j.id !== senderId);
    if (opponent && opponent.ws.readyState === WebSocket.OPEN) {
      opponent.ws.send(
        JSON.stringify({
          type: "PLACEMENT_STATUS",
          gameId: gameId,
          playerId: opponent.id,
          data: {
            status: status,
          },
        })
      );
    }
  }

  /**
   * Broadcasts game start to both players
   */
  private broadcastGameStart(session: GameSession): void {
    const message = JSON.stringify({
      type: "GAME_START",
      gameId: session.id,
      data: {
        estadoJogo: session.estadoJogo,
      },
    });

    session.jogadores.forEach((player) => {
      if (player.ws.readyState === WebSocket.OPEN) {
        player.ws.send(message);
      }
    });
  }

  /**
   * Sends placement error to player
   */
  private sendPlacementError(ws: WebSocket, error: string): void {
    if (ws.readyState === WebSocket.OPEN) {
      ws.send(
        JSON.stringify({
          type: "PLACEMENT_ERROR",
          data: { error },
        })
      );
    }
  }

  /**
   * Initializes placement phase for a game session
   */
  public initializePlacementPhase(session: GameSession): void {
    const gameStates = new Map<string, PlacementGameState>();

    session.jogadores.forEach((player) => {
      const placementState = this.gameController
        .getPlacementManager()
        .createInitialPlacementState(session.id, player.id, player.equipe);
      gameStates.set(player.id, placementState);

      // Send initial placement state to player
      this.sendPlacementStatus(player.ws, placementState);
    });

    this.placementStates.set(session.id, gameStates);
    console.log(`🎯 Fase de posicionamento iniciada para sessão ${session.id}`);
  }
}
