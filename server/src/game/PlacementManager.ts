import {
  PlacementGameState,
  PlacementStatus,
  PecaJogo,
  PosicaoTabuleiro,
  Equipe,
  INITIAL_PIECE_INVENTORY,
  Patentes,
} from "../types/game.types.js";
import {
  PlacementOperationResult,
  ValidationContext,
} from "../types/placement-errors.types.js";
import { PlacementErrorHandler } from "./PlacementErrorHandler.js";
import { v4 as uuidv4 } from "uuid";

export class PlacementManager {
  private errorHandler: PlacementErrorHandler;

  constructor() {
    this.errorHandler = new PlacementErrorHandler();
  }
  /**
   * Creates initial placement state for a player
   */
  public createInitialPlacementState(
    gameId: string,
    playerId: string,
    playerTeam: Equipe
  ): PlacementGameState {
    const playerArea =
      playerTeam === Equipe.Verde ? [0, 1, 2, 3] : [6, 7, 8, 9];

    return {
      gameId,
      playerId,
      availablePieces: { ...INITIAL_PIECE_INVENTORY },
      placedPieces: [],
      playerArea,
      localStatus: PlacementStatus.Placing,
      opponentStatus: PlacementStatus.Placing,
      selectedPieceType: null,
      gamePhase: "piecePlacement" as any,
    };
  }

  /**
   * Validates if a piece can be placed at the specified position
   */
  public validatePiecePlacement(
    placementState: PlacementGameState,
    patente: string,
    position: PosicaoTabuleiro,
    context?: ValidationContext
  ): PlacementOperationResult<void> {
    const validationContext: ValidationContext = context || {
      gameId: placementState.gameId,
      playerId: placementState.playerId,
      operationType: "PIECE_PLACEMENT_VALIDATION",
      timestamp: Date.now(),
    };

    const result = this.errorHandler.validatePiecePlacement(
      placementState,
      patente,
      position,
      validationContext
    );

    if (result.isValid) {
      return { success: true };
    } else {
      return { success: false, error: result.error };
    }
  }

  /**
   * Places a piece on the board
   */
  public placePiece(
    placementState: PlacementGameState,
    patente: string,
    position: PosicaoTabuleiro,
    context?: ValidationContext
  ): PlacementOperationResult<PlacementGameState> {
    const validationContext: ValidationContext = context || {
      gameId: placementState.gameId,
      playerId: placementState.playerId,
      operationType: "PIECE_PLACEMENT",
      timestamp: Date.now(),
    };

    // Validate the placement
    const validation = this.validatePiecePlacement(
      placementState,
      patente,
      position,
      validationContext
    );

    if (!validation.success) {
      return { success: false, error: validation.error };
    }

    try {
      // Create new piece
      const newPiece: PecaJogo = {
        id: uuidv4(),
        patente,
        equipe: placementState.playerId.includes("verde")
          ? Equipe.Verde
          : Equipe.Preta, // Simple team detection
        posicao: position,
        foiRevelada: false,
      };

      // Update inventory and placed pieces
      const newAvailablePieces = { ...placementState.availablePieces };
      newAvailablePieces[patente]--;

      const newPlacedPieces = [...placementState.placedPieces, newPiece];

      const newState: PlacementGameState = {
        ...placementState,
        availablePieces: newAvailablePieces,
        placedPieces: newPlacedPieces,
      };

      return { success: true, data: newState };
    } catch (error) {
      const errorDetails = this.errorHandler.createError(
        "INTERNAL_SERVER_ERROR" as any,
        `Failed to place piece: ${error}`,
        "Erro interno ao posicionar peça",
        validationContext,
        { patente, position, originalError: String(error) }
      );

      return { success: false, error: errorDetails };
    }
  }

  /**
   * Moves a piece to a new position (swap or reposition)
   */
  public movePiece(
    placementState: PlacementGameState,
    pieceId: string,
    newPosition: PosicaoTabuleiro,
    context?: ValidationContext
  ): PlacementOperationResult<PlacementGameState> {
    const validationContext: ValidationContext = context || {
      gameId: placementState.gameId,
      playerId: placementState.playerId,
      operationType: "PIECE_MOVEMENT",
      timestamp: Date.now(),
    };

    // Validate the movement
    const validation = this.errorHandler.validatePieceMovement(
      placementState,
      pieceId,
      newPosition,
      validationContext
    );

    if (!validation.isValid) {
      return { success: false, error: validation.error };
    }

    try {
      // Find the piece to move
      const pieceIndex = placementState.placedPieces.findIndex(
        (p) => p.id === pieceId
      );
      const piece = placementState.placedPieces[pieceIndex];

      let newPlacedPieces = [...placementState.placedPieces];

      // Check if there's a piece at the new position
      const existingPieceIndex = newPlacedPieces.findIndex(
        (p) =>
          p.posicao.linha === newPosition.linha &&
          p.posicao.coluna === newPosition.coluna
      );

      if (existingPieceIndex !== -1) {
        // Swap positions
        const existingPiece = newPlacedPieces[existingPieceIndex];
        newPlacedPieces[existingPieceIndex] = {
          ...existingPiece,
          posicao: piece.posicao,
        };
        newPlacedPieces[pieceIndex] = { ...piece, posicao: newPosition };
      } else {
        // Simple move
        newPlacedPieces[pieceIndex] = { ...piece, posicao: newPosition };
      }

      const newState: PlacementGameState = {
        ...placementState,
        placedPieces: newPlacedPieces,
      };

      return { success: true, data: newState };
    } catch (error) {
      const errorDetails = this.errorHandler.createError(
        "INTERNAL_SERVER_ERROR" as any,
        `Failed to move piece: ${error}`,
        "Erro interno ao mover peça",
        validationContext,
        { pieceId, newPosition, originalError: String(error) }
      );

      return { success: false, error: errorDetails };
    }
  }

  /**
   * Removes a piece from the board and returns it to inventory
   */
  public removePiece(
    placementState: PlacementGameState,
    pieceId: string,
    context?: ValidationContext
  ): PlacementOperationResult<PlacementGameState> {
    const validationContext: ValidationContext = context || {
      gameId: placementState.gameId,
      playerId: placementState.playerId,
      operationType: "PIECE_REMOVAL",
      timestamp: Date.now(),
    };

    try {
      const pieceIndex = placementState.placedPieces.findIndex(
        (p) => p.id === pieceId
      );

      if (pieceIndex === -1) {
        const errorDetails = this.errorHandler.createError(
          "INVALID_GAME_STATE" as any,
          `Piece not found: ${pieceId}`,
          "Peça não encontrada",
          validationContext,
          {
            pieceId,
            availablePieces: placementState.placedPieces.map((p) => p.id),
          }
        );
        return { success: false, error: errorDetails };
      }

      const piece = placementState.placedPieces[pieceIndex];

      // Remove piece from board
      const newPlacedPieces = placementState.placedPieces.filter(
        (p) => p.id !== pieceId
      );

      // Return piece to inventory
      const newAvailablePieces = { ...placementState.availablePieces };
      newAvailablePieces[piece.patente]++;

      const newState: PlacementGameState = {
        ...placementState,
        availablePieces: newAvailablePieces,
        placedPieces: newPlacedPieces,
      };

      return { success: true, data: newState };
    } catch (error) {
      const errorDetails = this.errorHandler.createError(
        "INTERNAL_SERVER_ERROR" as any,
        `Failed to remove piece: ${error}`,
        "Erro interno ao remover peça",
        validationContext,
        { pieceId, originalError: String(error) }
      );

      return { success: false, error: errorDetails };
    }
  }

  /**
   * Validates if all pieces are placed correctly for confirmation
   */
  public validatePlacementCompletion(
    placementState: PlacementGameState,
    context?: ValidationContext
  ): PlacementOperationResult<void> {
    const validationContext: ValidationContext = context || {
      gameId: placementState.gameId,
      playerId: placementState.playerId,
      operationType: "PLACEMENT_COMPLETION_VALIDATION",
      timestamp: Date.now(),
    };

    const result = this.errorHandler.validatePlacementCompletion(
      placementState,
      validationContext
    );

    if (result.isValid) {
      return { success: true };
    } else {
      return { success: false, error: result.error };
    }
  }

  /**
   * Confirms player's placement and updates status
   */
  public confirmPlacement(
    placementState: PlacementGameState,
    context?: ValidationContext
  ): PlacementOperationResult<PlacementGameState> {
    const validationContext: ValidationContext = context || {
      gameId: placementState.gameId,
      playerId: placementState.playerId,
      operationType: "PLACEMENT_CONFIRMATION",
      timestamp: Date.now(),
    };

    const validation = this.validatePlacementCompletion(
      placementState,
      validationContext
    );

    if (!validation.success) {
      return { success: false, error: validation.error };
    }

    try {
      const newState: PlacementGameState = {
        ...placementState,
        localStatus: PlacementStatus.Ready,
      };

      return { success: true, data: newState };
    } catch (error) {
      const errorDetails = this.errorHandler.createError(
        "INTERNAL_SERVER_ERROR" as any,
        `Failed to confirm placement: ${error}`,
        "Erro interno ao confirmar posicionamento",
        validationContext,
        { originalError: String(error) }
      );

      return { success: false, error: errorDetails };
    }
  }

  /**
   * Updates opponent status
   */
  public updateOpponentStatus(
    placementState: PlacementGameState,
    opponentStatus: PlacementStatus
  ): PlacementGameState {
    return {
      ...placementState,
      opponentStatus,
    };
  }

  /**
   * Checks if both players are ready to start the game
   */
  public areBothPlayersReady(
    player1State: PlacementGameState,
    player2State: PlacementGameState
  ): boolean {
    return (
      player1State.localStatus === PlacementStatus.Ready &&
      player2State.localStatus === PlacementStatus.Ready
    );
  }

  /**
   * Gets the total number of pieces remaining in inventory
   */
  public getRemainingPiecesCount(placementState: PlacementGameState): number {
    return Object.values(placementState.availablePieces).reduce(
      (sum, count) => sum + count,
      0
    );
  }

  /**
   * Gets pieces by type from inventory
   */
  public getAvailablePiecesByType(placementState: PlacementGameState): {
    [patente: string]: number;
  } {
    return { ...placementState.availablePieces };
  }

  /**
   * Validates game state and player authorization
   */
  public validateGameStateAndAuth(
    gameId: string,
    playerId: string,
    context?: ValidationContext
  ): PlacementOperationResult<void> {
    const validationContext: ValidationContext = context || {
      gameId,
      playerId,
      operationType: "AUTH_VALIDATION",
      timestamp: Date.now(),
    };

    const result = this.errorHandler.validateGameStateAndAuth(
      gameId,
      playerId,
      validationContext
    );

    if (result.isValid) {
      return { success: true };
    } else {
      return { success: false, error: result.error };
    }
  }

  /**
   * Gets error handler for debugging and monitoring
   */
  public getErrorHandler(): PlacementErrorHandler {
    return this.errorHandler;
  }

  /**
   * Gets recent error logs for debugging
   */
  public getRecentLogs(count: number = 50) {
    return this.errorHandler.getRecentLogs(count);
  }

  /**
   * Gets rate limiting statistics
   */
  public getRateLimitStats() {
    return this.errorHandler.getRateLimitStats();
  }

  /**
   * Clears rate limits (for testing or admin purposes)
   */
  public clearRateLimits(): void {
    this.errorHandler.clearRateLimits();
  }

  /**
   * Clears error logs (for testing or admin purposes)
   */
  public clearLogs(): void {
    this.errorHandler.clearLogs();
  }
}
