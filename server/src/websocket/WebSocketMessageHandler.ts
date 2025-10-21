import { WebSocket } from "ws";
import {
  GameSession,
  PlacementMessage,
  PlacementGameState,
  PlacementStatus,
  GamePhase,
} from "../types/game.types.js";
import {
  PlacementErrorDetails,
  ValidationContext,
  PlacementErrorType,
} from "../types/placement-errors.types.js";
import { GameController } from "../game/GameController.js";

export class WebSocketMessageHandler {
  private gameController: GameController;
  private activeGames: Map<string, GameSession>;
  private placementStates: Map<string, Map<string, PlacementGameState>>; // gameId -> playerId -> state
  private disconnectedPlayers: Map<
    string,
    { gameId: string; timestamp: number }
  >; // playerId -> disconnect info
  private placementTimeouts: Map<string, NodeJS.Timeout>; // gameId -> timeout

  constructor(activeGames: Map<string, GameSession>) {
    this.gameController = new GameController();
    this.activeGames = activeGames;
    this.placementStates = new Map();
    this.disconnectedPlayers = new Map();
    this.placementTimeouts = new Map();
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
    const context: ValidationContext = {
      gameId: message.gameId,
      playerId: clientId,
      operationType: "PLACEMENT_UPDATE",
      timestamp: Date.now(),
      requestId: `req_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
    };

    try {
      const { gameId, data } = message;

      // Validate basic message structure
      if (!data || !data.position) {
        this.sendPlacementErrorDetails(ws, {
          type: PlacementErrorType.INVALID_POSITION,
          message: "Invalid placement data structure",
          userMessage: "Dados de posicionamento inválidos",
          code: "P4001",
          context: { gameId, playerId: clientId },
          timestamp: new Date().toISOString(),
          requestId: context.requestId,
        });
        return;
      }

      // Validate game state and authorization
      const placementManager = this.gameController.getPlacementManager();
      const authResult = placementManager.validateGameStateAndAuth(
        gameId,
        clientId,
        context
      );

      if (!authResult.success) {
        this.sendPlacementErrorDetails(ws, authResult.error!);
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
          this.sendPlacementErrorDetails(ws, {
            type: PlacementErrorType.GAME_NOT_FOUND,
            message: `Game session not found for player ${clientId}`,
            userMessage: "Sessão de jogo não encontrada",
            code: "P4103",
            context: { gameId, playerId: clientId },
            timestamp: new Date().toISOString(),
            requestId: context.requestId,
          });
          return;
        }

        const player = session.jogadores.find((j) => j.id === clientId);
        if (!player) {
          this.sendPlacementErrorDetails(ws, {
            type: PlacementErrorType.PLAYER_NOT_FOUND,
            message: `Player not found in game session`,
            userMessage: "Jogador não encontrado na sessão",
            code: "P4102",
            context: { gameId, playerId: clientId },
            timestamp: new Date().toISOString(),
            requestId: context.requestId,
          });
          return;
        }

        playerState = placementManager.createInitialPlacementState(
          gameId,
          clientId,
          player.equipe
        );
        gameStates.set(clientId, playerState);
      }

      // Handle the placement update with comprehensive validation
      if (data.pieceId) {
        // Moving existing piece
        const result = placementManager.movePiece(
          playerState,
          data.pieceId,
          data.position,
          context
        );

        if (result.success && result.data) {
          gameStates.set(clientId, result.data);
          this.sendPlacementStatus(ws, result.data);
          this.broadcastOpponentStatus(
            gameId,
            clientId,
            result.data.localStatus
          );
        } else {
          this.sendPlacementErrorDetails(ws, result.error!);
        }
      } else if (data.patente) {
        // Placing new piece
        const result = placementManager.placePiece(
          playerState,
          data.patente,
          data.position,
          context
        );

        if (result.success && result.data) {
          gameStates.set(clientId, result.data);
          this.sendPlacementStatus(ws, result.data);
          this.broadcastOpponentStatus(
            gameId,
            clientId,
            result.data.localStatus
          );
        } else {
          this.sendPlacementErrorDetails(ws, result.error!);
        }
      } else {
        this.sendPlacementErrorDetails(ws, {
          type: PlacementErrorType.PIECE_NOT_AVAILABLE,
          message: "Missing piece type or piece ID",
          userMessage: "Tipo de peça ou ID da peça não especificado",
          code: "P4002",
          context: { gameId, playerId: clientId, data },
          timestamp: new Date().toISOString(),
          requestId: context.requestId,
        });
      }
    } catch (error) {
      console.error("Erro ao processar atualização de posicionamento:", error);
      this.sendPlacementErrorDetails(ws, {
        type: PlacementErrorType.INTERNAL_SERVER_ERROR,
        message: `Internal server error: ${error}`,
        userMessage: "Erro interno do servidor",
        code: "P5001",
        context: {
          gameId: message.gameId,
          playerId: clientId,
          originalError: String(error),
        },
        timestamp: new Date().toISOString(),
        requestId: context.requestId,
      });
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
    const context: ValidationContext = {
      gameId: message.gameId,
      playerId: clientId,
      operationType: "PLACEMENT_CONFIRMATION",
      timestamp: Date.now(),
      requestId: `req_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
    };

    try {
      const { gameId } = message;

      // Validate game state and authorization
      const placementManager = this.gameController.getPlacementManager();
      const authResult = placementManager.validateGameStateAndAuth(
        gameId,
        clientId,
        context
      );

      if (!authResult.success) {
        this.sendPlacementErrorDetails(ws, authResult.error!);
        return;
      }

      const gameStates = this.placementStates.get(gameId);
      if (!gameStates) {
        this.sendPlacementErrorDetails(ws, {
          type: PlacementErrorType.INVALID_GAME_STATE,
          message: "Placement state not found for game",
          userMessage: "Estado de posicionamento não encontrado",
          code: "P4101",
          context: { gameId, playerId: clientId },
          timestamp: new Date().toISOString(),
          requestId: context.requestId,
        });
        return;
      }

      const playerState = gameStates.get(clientId);
      if (!playerState) {
        this.sendPlacementErrorDetails(ws, {
          type: PlacementErrorType.PLAYER_NOT_FOUND,
          message: "Player state not found",
          userMessage: "Estado do jogador não encontrado",
          code: "P4102",
          context: { gameId, playerId: clientId },
          timestamp: new Date().toISOString(),
          requestId: context.requestId,
        });
        return;
      }

      // Update player state with pieces from message if provided
      let updatedPlayerState = playerState;
      if (message.data?.allPieces && message.data.allPieces.length > 0) {
        console.log(`🎯 Atualizando estado com ${message.data.allPieces.length} peças recebidas`);
        updatedPlayerState = {
          ...playerState,
          placedPieces: message.data.allPieces,
        };
        // Update the stored state
        gameStates.set(clientId, updatedPlayerState);
        console.log(`✅ Estado atualizado - placedPieces.length: ${updatedPlayerState.placedPieces.length}`);
      } else {
        console.log(`⚠️ Nenhuma peça recebida na mensagem ou array vazio`);
        console.log(`📊 Estado atual - placedPieces.length: ${playerState.placedPieces.length}`);
      }

      // Confirm placement with comprehensive validation
      const result = placementManager.confirmPlacement(updatedPlayerState, context);

      if (!result.success || !result.data) {
        this.sendPlacementErrorDetails(ws, result.error!);
        return;
      }

      // Update player state
      gameStates.set(clientId, result.data);
      this.sendPlacementStatus(ws, result.data);
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
      this.sendPlacementErrorDetails(ws, {
        type: PlacementErrorType.INTERNAL_SERVER_ERROR,
        message: `Internal server error during placement confirmation: ${error}`,
        userMessage: "Erro interno do servidor",
        code: "P5001",
        context: {
          gameId: message.gameId,
          playerId: clientId,
          originalError: String(error),
        },
        timestamp: new Date().toISOString(),
        requestId: context.requestId,
      });
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
   * Sends placement error to player (legacy method)
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
   * Sends detailed placement error to player
   */
  private sendPlacementErrorDetails(
    ws: WebSocket,
    error: PlacementErrorDetails
  ): void {
    if (ws.readyState === WebSocket.OPEN) {
      ws.send(
        JSON.stringify({
          type: "PLACEMENT_ERROR_DETAILS",
          error: {
            type: error.type,
            message: error.userMessage, // Send user-friendly message
            code: error.code,
            context: {
              gameId: error.context?.gameId,
              timestamp: error.timestamp,
              requestId: error.requestId,
            },
          },
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

  /**
   * Gets error statistics for monitoring and debugging
   */
  public getErrorStatistics() {
    const placementManager = this.gameController.getPlacementManager();
    return {
      recentLogs: placementManager.getRecentLogs(100),
      rateLimitStats: placementManager.getRateLimitStats(),
      activePlacementGames: this.placementStates.size,
      totalActiveGames: this.activeGames.size,
    };
  }

  /**
   * Clears error logs and rate limits (for admin/testing purposes)
   */
  public clearErrorData(): void {
    const placementManager = this.gameController.getPlacementManager();
    placementManager.clearLogs();
    placementManager.clearRateLimits();
    console.log("Error data cleared");
  }

  /**
   * Gets placement state for debugging
   */
  public getPlacementState(gameId: string, playerId?: string) {
    const gameStates = this.placementStates.get(gameId);
    if (!gameStates) return null;

    if (playerId) {
      return gameStates.get(playerId) || null;
    }

    return Object.fromEntries(gameStates.entries());
  }

  // ===== DISCONNECTION HANDLING METHODS =====

  /**
   * Handles player disconnection during placement phase
   */
  public handlePlayerDisconnection(playerId: string): void {
    console.log(`🔌 Player ${playerId} disconnected during placement`);

    // Find the game this player was in
    const gameId = this.findGameIdByPlayerId(playerId);
    if (!gameId) {
      console.log(`No active game found for disconnected player ${playerId}`);
      return;
    }

    // Record disconnection
    this.disconnectedPlayers.set(playerId, {
      gameId,
      timestamp: Date.now(),
    });

    // Notify opponent about disconnection
    this.notifyOpponentOfDisconnection(gameId, playerId);

    // Set timeout for abandoned placement (5 minutes)
    const timeoutId = setTimeout(() => {
      this.handleAbandonedPlacement(gameId, playerId);
    }, 5 * 60 * 1000); // 5 minutes

    this.placementTimeouts.set(`${gameId}_${playerId}`, timeoutId);

    console.log(
      `⏰ Placement abandonment timeout set for player ${playerId} in game ${gameId}`
    );
  }

  /**
   * Handles player reconnection during placement phase
   */
  public handlePlayerReconnection(playerId: string, ws: WebSocket): boolean {
    const disconnectionInfo = this.disconnectedPlayers.get(playerId);
    if (!disconnectionInfo) {
      return false; // Player wasn't disconnected during placement
    }

    const { gameId } = disconnectionInfo;
    console.log(
      `🔄 Player ${playerId} reconnecting to placement in game ${gameId}`
    );

    // Clear disconnection record
    this.disconnectedPlayers.delete(playerId);

    // Clear abandonment timeout
    const timeoutKey = `${gameId}_${playerId}`;
    const timeoutId = this.placementTimeouts.get(timeoutKey);
    if (timeoutId) {
      clearTimeout(timeoutId);
      this.placementTimeouts.delete(timeoutKey);
    }

    // Update player's WebSocket in the game session
    const session = this.activeGames.get(gameId);
    if (session) {
      const player = session.jogadores.find((j) => j.id === playerId);
      if (player) {
        player.ws = ws;
      }
    }

    // Restore placement state
    const gameStates = this.placementStates.get(gameId);
    if (gameStates) {
      const playerState = gameStates.get(playerId);
      if (playerState) {
        // Send current placement state to reconnected player
        this.sendPlacementStatus(ws, playerState);

        // Notify opponent of reconnection
        this.notifyOpponentOfReconnection(gameId, playerId);

        console.log(
          `✅ Player ${playerId} successfully reconnected to placement`
        );
        return true;
      }
    }

    console.log(`❌ Failed to restore placement state for player ${playerId}`);
    return false;
  }

  /**
   * Handles abandoned placement (player didn't reconnect in time)
   */
  private handleAbandonedPlacement(gameId: string, playerId: string): void {
    console.log(
      `⏰ Placement abandoned by player ${playerId} in game ${gameId}`
    );

    // Clean up disconnection record
    this.disconnectedPlayers.delete(playerId);

    // Clean up timeout
    const timeoutKey = `${gameId}_${playerId}`;
    this.placementTimeouts.delete(timeoutKey);

    // Notify opponent and return them to matchmaking
    this.notifyOpponentOfAbandonment(gameId, playerId);

    // Clean up game state
    this.cleanupAbandonedGame(gameId);
  }

  /**
   * Notifies opponent about player disconnection
   */
  private notifyOpponentOfDisconnection(
    gameId: string,
    disconnectedPlayerId: string
  ): void {
    const session = this.activeGames.get(gameId);
    if (!session) return;

    const opponent = session.jogadores.find(
      (j) => j.id !== disconnectedPlayerId
    );
    if (opponent && opponent.ws.readyState === WebSocket.OPEN) {
      opponent.ws.send(
        JSON.stringify({
          type: "PLACEMENT_OPPONENT_DISCONNECTED",
          gameId: gameId,
          data: {
            message: "Oponente desconectou. Aguardando reconexão...",
            disconnectedPlayerId,
            timestamp: Date.now(),
          },
        })
      );
    }
  }

  /**
   * Notifies opponent about player reconnection
   */
  private notifyOpponentOfReconnection(
    gameId: string,
    reconnectedPlayerId: string
  ): void {
    const session = this.activeGames.get(gameId);
    if (!session) return;

    const opponent = session.jogadores.find(
      (j) => j.id !== reconnectedPlayerId
    );
    if (opponent && opponent.ws.readyState === WebSocket.OPEN) {
      opponent.ws.send(
        JSON.stringify({
          type: "PLACEMENT_OPPONENT_RECONNECTED",
          gameId: gameId,
          data: {
            message: "Oponente reconectou. Continuando posicionamento...",
            reconnectedPlayerId,
            timestamp: Date.now(),
          },
        })
      );
    }
  }

  /**
   * Notifies opponent about placement abandonment
   */
  private notifyOpponentOfAbandonment(
    gameId: string,
    abandonedPlayerId: string
  ): void {
    const session = this.activeGames.get(gameId);
    if (!session) return;

    const opponent = session.jogadores.find((j) => j.id !== abandonedPlayerId);
    if (opponent && opponent.ws.readyState === WebSocket.OPEN) {
      opponent.ws.send(
        JSON.stringify({
          type: "PLACEMENT_OPPONENT_ABANDONED",
          gameId: gameId,
          data: {
            message:
              "Oponente abandonou o jogo. Retornando para busca de oponente...",
            abandonedPlayerId,
            timestamp: Date.now(),
          },
        })
      );
    }
  }

  /**
   * Cleans up abandoned game resources
   */
  private cleanupAbandonedGame(gameId: string): void {
    // Remove placement states
    this.placementStates.delete(gameId);

    // Remove game session
    this.activeGames.delete(gameId);

    // Clean up any remaining timeouts for this game
    for (const [key, timeoutId] of this.placementTimeouts.entries()) {
      if (key.startsWith(gameId)) {
        clearTimeout(timeoutId);
        this.placementTimeouts.delete(key);
      }
    }

    console.log(`🧹 Cleaned up abandoned game ${gameId}`);
  }

  /**
   * Finds game ID by player ID
   */
  private findGameIdByPlayerId(playerId: string): string | null {
    for (const [gameId, gameStates] of this.placementStates.entries()) {
      if (gameStates.has(playerId)) {
        return gameId;
      }
    }

    // Also check active games
    for (const [gameId, session] of this.activeGames.entries()) {
      if (session.jogadores.some((j) => j.id === playerId)) {
        return gameId;
      }
    }

    return null;
  }

  /**
   * Gets disconnection statistics for monitoring
   */
  public getDisconnectionStats() {
    return {
      disconnectedPlayers: this.disconnectedPlayers.size,
      activeTimeouts: this.placementTimeouts.size,
      disconnectedPlayersList: Array.from(
        this.disconnectedPlayers.entries()
      ).map(([playerId, info]) => ({
        playerId,
        gameId: info.gameId,
        disconnectedAt: new Date(info.timestamp).toISOString(),
        disconnectedFor: Date.now() - info.timestamp,
      })),
    };
  }

  /**
   * Cleans up disconnection data (for testing/admin purposes)
   */
  public clearDisconnectionData(): void {
    // Clear all timeouts
    for (const timeoutId of this.placementTimeouts.values()) {
      clearTimeout(timeoutId);
    }

    this.disconnectedPlayers.clear();
    this.placementTimeouts.clear();
    console.log("Disconnection data cleared");
  }
}
