import {
  PlacementErrorType,
  PlacementErrorDetails,
  PlacementValidationResult,
  PlacementOperationResult,
  ValidationContext,
  RateLimitInfo,
  RateLimitConfig,
  DEFAULT_RATE_LIMITS,
  PLACEMENT_ERROR_CODES,
  LogLevel,
  PlacementLogEntry,
} from "../types/placement-errors.types.js";
import {
  PlacementGameState,
  PosicaoTabuleiro,
  Patentes,
  INITIAL_PIECE_INVENTORY,
} from "../types/game.types.js";

/**
 * Comprehensive error handling and validation for placement operations
 */
export class PlacementErrorHandler {
  private rateLimitStore: Map<string, RateLimitInfo> = new Map();
  private logEntries: PlacementLogEntry[] = [];
  private readonly maxLogEntries = 1000;

  /**
   * Creates a standardized error details object
   */
  public createError(
    type: PlacementErrorType,
    message: string,
    userMessage: string,
    context?: ValidationContext,
    additionalContext?: Record<string, any>
  ): PlacementErrorDetails {
    const errorCode = this.getErrorCode(type);
    const requestId = context?.requestId || this.generateRequestId();

    const error: PlacementErrorDetails = {
      type,
      message,
      userMessage,
      code: errorCode,
      context: {
        ...additionalContext,
        gameId: context?.gameId,
        playerId: context?.playerId,
        operationType: context?.operationType,
      },
      timestamp: new Date().toISOString(),
      requestId,
    };

    // Log the error
    this.logError(error, context);

    return error;
  }

  /**
   * Validates piece placement operation comprehensively
   */
  public validatePiecePlacement(
    placementState: PlacementGameState,
    patente: string,
    position: PosicaoTabuleiro,
    context: ValidationContext
  ): PlacementValidationResult {
    const startTime = Date.now();

    try {
      // Rate limiting check
      const rateLimitResult = this.checkRateLimit(
        context.playerId,
        "PIECE_PLACEMENT",
        DEFAULT_RATE_LIMITS.PIECE_PLACEMENT
      );

      if (!rateLimitResult.allowed) {
        return {
          isValid: false,
          error: this.createError(
            PlacementErrorType.RATE_LIMIT_EXCEEDED,
            `Rate limit exceeded for piece placement`,
            `Muitas tentativas de posicionamento. Aguarde ${Math.ceil(
              rateLimitResult.resetTimeMs! / 1000
            )} segundos.`,
            context,
            { rateLimitInfo: rateLimitResult.info }
          ),
        };
      }

      // Validate piece type
      if (!Patentes[patente]) {
        return {
          isValid: false,
          error: this.createError(
            PlacementErrorType.PIECE_NOT_AVAILABLE,
            `Invalid piece type: ${patente}`,
            `Tipo de peça inválido: ${patente}`,
            context,
            { patente, availableTypes: Object.keys(Patentes) }
          ),
        };
      }

      // Check if piece is available in inventory
      if (
        !placementState.availablePieces[patente] ||
        placementState.availablePieces[patente] <= 0
      ) {
        return {
          isValid: false,
          error: this.createError(
            PlacementErrorType.PIECE_NOT_AVAILABLE,
            `Piece not available in inventory: ${patente}`,
            `Peça ${Patentes[patente].nome} não disponível no inventário`,
            context,
            {
              patente,
              availableCount: placementState.availablePieces[patente] || 0,
              inventory: placementState.availablePieces,
            }
          ),
        };
      }

      // Validate position bounds
      if (
        position.linha < 0 ||
        position.linha > 9 ||
        position.coluna < 0 ||
        position.coluna > 9
      ) {
        return {
          isValid: false,
          error: this.createError(
            PlacementErrorType.INVALID_POSITION,
            `Position out of bounds: (${position.linha}, ${position.coluna})`,
            `Posição fora dos limites do tabuleiro`,
            context,
            { position, bounds: { minRow: 0, maxRow: 9, minCol: 0, maxCol: 9 } }
          ),
        };
      }

      // Check if position is within player's area
      if (!placementState.playerArea.includes(position.linha)) {
        return {
          isValid: false,
          error: this.createError(
            PlacementErrorType.INVALID_POSITION,
            `Position outside player area: row ${position.linha}`,
            `Posição fora da sua área de posicionamento`,
            context,
            { position, playerArea: placementState.playerArea }
          ),
        };
      }

      // Check if position is a lake (not allowed for piece placement)
      if (this.isLakePosition(position)) {
        return {
          isValid: false,
          error: this.createError(
            PlacementErrorType.INVALID_POSITION,
            `Cannot place pieces on lake positions`,
            `Não é possível posicionar peças em lagos`,
            context,
            { position, lakePositions: this.getLakePositions() }
          ),
        };
      }

      // Check if position is already occupied
      const existingPiece = placementState.placedPieces.find(
        (piece) =>
          piece.posicao.linha === position.linha &&
          piece.posicao.coluna === position.coluna
      );

      if (existingPiece) {
        return {
          isValid: false,
          error: this.createError(
            PlacementErrorType.INVALID_POSITION,
            `Position already occupied by piece ${existingPiece.id}`,
            `Posição já ocupada por outra peça`,
            context,
            {
              position,
              existingPiece: {
                id: existingPiece.id,
                patente: existingPiece.patente,
              },
            }
          ),
        };
      }

      // Log successful validation
      this.logOperation(
        LogLevel.DEBUG,
        `Piece placement validation successful`,
        context,
        Date.now() - startTime
      );

      return { isValid: true };
    } catch (error) {
      return {
        isValid: false,
        error: this.createError(
          PlacementErrorType.INTERNAL_SERVER_ERROR,
          `Validation error: ${error}`,
          `Erro interno durante validação`,
          context,
          { originalError: String(error) }
        ),
      };
    }
  }

  /**
   * Validates piece movement operation
   */
  public validatePieceMovement(
    placementState: PlacementGameState,
    pieceId: string,
    newPosition: PosicaoTabuleiro,
    context: ValidationContext
  ): PlacementValidationResult {
    const startTime = Date.now();

    try {
      // Rate limiting check
      const rateLimitResult = this.checkRateLimit(
        context.playerId,
        "PIECE_MOVEMENT",
        DEFAULT_RATE_LIMITS.PIECE_MOVEMENT
      );

      if (!rateLimitResult.allowed) {
        return {
          isValid: false,
          error: this.createError(
            PlacementErrorType.RATE_LIMIT_EXCEEDED,
            `Rate limit exceeded for piece movement`,
            `Muitas tentativas de movimento. Aguarde ${Math.ceil(
              rateLimitResult.resetTimeMs! / 1000
            )} segundos.`,
            context,
            { rateLimitInfo: rateLimitResult.info }
          ),
        };
      }

      // Find the piece to move
      const piece = placementState.placedPieces.find((p) => p.id === pieceId);
      if (!piece) {
        return {
          isValid: false,
          error: this.createError(
            PlacementErrorType.INVALID_GAME_STATE,
            `Piece not found: ${pieceId}`,
            `Peça não encontrada`,
            context,
            {
              pieceId,
              availablePieces: placementState.placedPieces.map((p) => p.id),
            }
          ),
        };
      }

      // Validate new position bounds
      if (
        newPosition.linha < 0 ||
        newPosition.linha > 9 ||
        newPosition.coluna < 0 ||
        newPosition.coluna > 9
      ) {
        return {
          isValid: false,
          error: this.createError(
            PlacementErrorType.INVALID_POSITION,
            `New position out of bounds: (${newPosition.linha}, ${newPosition.coluna})`,
            `Nova posição fora dos limites do tabuleiro`,
            context,
            {
              newPosition,
              bounds: { minRow: 0, maxRow: 9, minCol: 0, maxCol: 9 },
            }
          ),
        };
      }

      // Check if new position is within player's area
      if (!placementState.playerArea.includes(newPosition.linha)) {
        return {
          isValid: false,
          error: this.createError(
            PlacementErrorType.INVALID_POSITION,
            `New position outside player area: row ${newPosition.linha}`,
            `Nova posição fora da sua área de posicionamento`,
            context,
            { newPosition, playerArea: placementState.playerArea }
          ),
        };
      }

      // Check if new position is a lake
      if (this.isLakePosition(newPosition)) {
        return {
          isValid: false,
          error: this.createError(
            PlacementErrorType.INVALID_POSITION,
            `Cannot move pieces to lake positions`,
            `Não é possível mover peças para lagos`,
            context,
            { newPosition, lakePositions: this.getLakePositions() }
          ),
        };
      }

      this.logOperation(
        LogLevel.DEBUG,
        `Piece movement validation successful`,
        context,
        Date.now() - startTime
      );

      return { isValid: true };
    } catch (error) {
      return {
        isValid: false,
        error: this.createError(
          PlacementErrorType.INTERNAL_SERVER_ERROR,
          `Movement validation error: ${error}`,
          `Erro interno durante validação de movimento`,
          context,
          { originalError: String(error) }
        ),
      };
    }
  }

  /**
   * Validates placement completion for confirmation
   */
  public validatePlacementCompletion(
    placementState: PlacementGameState,
    context: ValidationContext
  ): PlacementValidationResult {
    const startTime = Date.now();

    try {
      // Rate limiting check
      const rateLimitResult = this.checkRateLimit(
        context.playerId,
        "PLACEMENT_CONFIRMATION",
        DEFAULT_RATE_LIMITS.PLACEMENT_CONFIRMATION
      );

      if (!rateLimitResult.allowed) {
        return {
          isValid: false,
          error: this.createError(
            PlacementErrorType.RATE_LIMIT_EXCEEDED,
            `Rate limit exceeded for placement confirmation`,
            `Muitas tentativas de confirmação. Aguarde ${Math.ceil(
              rateLimitResult.resetTimeMs! / 1000
            )} segundos.`,
            context,
            { rateLimitInfo: rateLimitResult.info }
          ),
        };
      }

      // Check if all pieces are placed (inventory should be empty)
      const totalPiecesInInventory = Object.values(
        placementState.availablePieces
      ).reduce((sum, count) => sum + count, 0);

      if (totalPiecesInInventory > 0) {
        const missingPieces = Object.entries(placementState.availablePieces)
          .filter(([_, count]) => count > 0)
          .map(([patente, count]) => ({
            patente: Patentes[patente]?.nome || patente,
            count,
          }));

        return {
          isValid: false,
          error: this.createError(
            PlacementErrorType.INCOMPLETE_PLACEMENT,
            `${totalPiecesInInventory} pieces still need to be placed`,
            `${totalPiecesInInventory} peças ainda precisam ser posicionadas`,
            context,
            { remainingPieces: totalPiecesInInventory, missingPieces }
          ),
        };
      }

      // Check if we have exactly 40 pieces placed
      if (placementState.placedPieces.length !== 40) {
        return {
          isValid: false,
          error: this.createError(
            PlacementErrorType.INVALID_PIECE_COMPOSITION,
            `Incorrect number of pieces: ${placementState.placedPieces.length}/40`,
            `Número incorreto de peças: ${placementState.placedPieces.length}/40`,
            context,
            {
              actualCount: placementState.placedPieces.length,
              expectedCount: 40,
            }
          ),
        };
      }

      // Validate piece composition
      const pieceComposition: { [patente: string]: number } = {};
      placementState.placedPieces.forEach((piece) => {
        pieceComposition[piece.patente] =
          (pieceComposition[piece.patente] || 0) + 1;
      });

      const compositionErrors: string[] = [];
      for (const [patente, requiredCount] of Object.entries(
        INITIAL_PIECE_INVENTORY
      )) {
        const actualCount = pieceComposition[patente] || 0;
        if (actualCount !== requiredCount) {
          compositionErrors.push(
            `${
              Patentes[patente]?.nome || patente
            }: esperado ${requiredCount}, atual ${actualCount}`
          );
        }
      }

      if (compositionErrors.length > 0) {
        return {
          isValid: false,
          error: this.createError(
            PlacementErrorType.INVALID_PIECE_COMPOSITION,
            `Invalid piece composition: ${compositionErrors.join(", ")}`,
            `Composição de peças incorreta: ${compositionErrors.join(", ")}`,
            context,
            {
              compositionErrors,
              actualComposition: pieceComposition,
              expectedComposition: INITIAL_PIECE_INVENTORY,
            }
          ),
        };
      }

      // Check if all pieces are in player's area
      const invalidPieces = placementState.placedPieces.filter(
        (piece) => !placementState.playerArea.includes(piece.posicao.linha)
      );

      if (invalidPieces.length > 0) {
        return {
          isValid: false,
          error: this.createError(
            PlacementErrorType.INVALID_POSITION,
            `${invalidPieces.length} pieces are outside player area`,
            `${invalidPieces.length} peças estão fora da área do jogador`,
            context,
            {
              invalidPieces: invalidPieces.map((p) => ({
                id: p.id,
                position: p.posicao,
              })),
              playerArea: placementState.playerArea,
            }
          ),
        };
      }

      this.logOperation(
        LogLevel.INFO,
        `Placement completion validation successful`,
        context,
        Date.now() - startTime
      );

      return { isValid: true };
    } catch (error) {
      return {
        isValid: false,
        error: this.createError(
          PlacementErrorType.INTERNAL_SERVER_ERROR,
          `Completion validation error: ${error}`,
          `Erro interno durante validação de conclusão`,
          context,
          { originalError: String(error) }
        ),
      };
    }
  }

  /**
   * Validates game state and player authorization
   */
  public validateGameStateAndAuth(
    gameId: string,
    playerId: string,
    context: ValidationContext
  ): PlacementValidationResult {
    // This would integrate with your game session manager
    // For now, basic validation
    if (!gameId || !playerId) {
      return {
        isValid: false,
        error: this.createError(
          PlacementErrorType.INVALID_GAME_STATE,
          `Missing gameId or playerId`,
          `Identificadores de jogo inválidos`,
          context,
          { gameId, playerId }
        ),
      };
    }

    return { isValid: true };
  }

  /**
   * Rate limiting implementation
   */
  private checkRateLimit(
    playerId: string,
    operationType: string,
    config: RateLimitConfig
  ): { allowed: boolean; info?: RateLimitInfo; resetTimeMs?: number } {
    const key = `${playerId}:${operationType}`;
    const now = Date.now();
    const existing = this.rateLimitStore.get(key);

    if (!existing) {
      // First request in window
      const info: RateLimitInfo = {
        playerId,
        operationType,
        count: 1,
        windowStart: now,
        limit: config.maxRequestsPerWindow,
        windowDuration: config.windowDurationMs,
      };
      this.rateLimitStore.set(key, info);
      return { allowed: true, info };
    }

    // Check if window has expired
    if (now - existing.windowStart >= config.windowDurationMs) {
      // Reset window
      const info: RateLimitInfo = {
        ...existing,
        count: 1,
        windowStart: now,
      };
      this.rateLimitStore.set(key, info);
      return { allowed: true, info };
    }

    // Check if limit exceeded
    if (existing.count >= config.maxRequestsPerWindow) {
      const resetTimeMs =
        config.windowDurationMs - (now - existing.windowStart);
      return { allowed: false, info: existing, resetTimeMs };
    }

    // Increment counter
    existing.count++;
    this.rateLimitStore.set(key, existing);
    return { allowed: true, info: existing };
  }

  /**
   * Logging operations
   */
  private logOperation(
    level: LogLevel,
    message: string,
    context: ValidationContext,
    duration?: number
  ): void {
    const logEntry: PlacementLogEntry = {
      level,
      message,
      context,
      timestamp: new Date().toISOString(),
      duration,
    };

    this.logEntries.push(logEntry);

    // Keep only recent entries
    if (this.logEntries.length > this.maxLogEntries) {
      this.logEntries = this.logEntries.slice(-this.maxLogEntries);
    }

    // Console logging based on level
    if (level === LogLevel.ERROR || level === LogLevel.CRITICAL) {
      console.error(`[${level}] ${message}`, { context, duration });
    } else if (level === LogLevel.WARN) {
      console.warn(`[${level}] ${message}`, { context, duration });
    } else if (level === LogLevel.INFO) {
      console.info(`[${level}] ${message}`, { context, duration });
    } else {
      console.debug(`[${level}] ${message}`, { context, duration });
    }
  }

  private logError(
    error: PlacementErrorDetails,
    context?: ValidationContext
  ): void {
    const logEntry: PlacementLogEntry = {
      level: LogLevel.ERROR,
      message: error.message,
      context: context || {
        gameId: error.context?.gameId || "unknown",
        playerId: error.context?.playerId || "unknown",
        operationType: error.context?.operationType || "unknown",
        timestamp: Date.now(),
      },
      error,
      timestamp: error.timestamp,
    };

    this.logEntries.push(logEntry);
    console.error(`[ERROR] ${error.message}`, { error, context });
  }

  /**
   * Utility methods
   */
  private isLakePosition(position: PosicaoTabuleiro): boolean {
    const lakePositions = this.getLakePositions();
    return lakePositions.some(
      (lake) => lake.linha === position.linha && lake.coluna === position.coluna
    );
  }

  private getLakePositions(): PosicaoTabuleiro[] {
    return [
      { linha: 4, coluna: 2 },
      { linha: 4, coluna: 3 },
      { linha: 5, coluna: 2 },
      { linha: 5, coluna: 3 },
      { linha: 4, coluna: 6 },
      { linha: 4, coluna: 7 },
      { linha: 5, coluna: 6 },
      { linha: 5, coluna: 7 },
    ];
  }

  private getErrorCode(type: PlacementErrorType): string {
    switch (type) {
      case PlacementErrorType.INVALID_POSITION:
        return PLACEMENT_ERROR_CODES.INVALID_POSITION;
      case PlacementErrorType.PIECE_NOT_AVAILABLE:
        return PLACEMENT_ERROR_CODES.PIECE_NOT_AVAILABLE;
      case PlacementErrorType.INCOMPLETE_PLACEMENT:
        return PLACEMENT_ERROR_CODES.INCOMPLETE_PLACEMENT;
      case PlacementErrorType.INVALID_PIECE_COMPOSITION:
        return PLACEMENT_ERROR_CODES.INVALID_PIECE_COMPOSITION;
      case PlacementErrorType.INVALID_GAME_STATE:
        return PLACEMENT_ERROR_CODES.INVALID_GAME_STATE;
      case PlacementErrorType.PLAYER_NOT_FOUND:
        return PLACEMENT_ERROR_CODES.PLAYER_NOT_FOUND;
      case PlacementErrorType.GAME_NOT_FOUND:
        return PLACEMENT_ERROR_CODES.GAME_NOT_FOUND;
      case PlacementErrorType.WRONG_GAME_PHASE:
        return PLACEMENT_ERROR_CODES.WRONG_GAME_PHASE;
      case PlacementErrorType.UNAUTHORIZED_OPERATION:
        return PLACEMENT_ERROR_CODES.UNAUTHORIZED_OPERATION;
      case PlacementErrorType.PLAYER_NOT_IN_GAME:
        return PLACEMENT_ERROR_CODES.PLAYER_NOT_IN_GAME;
      case PlacementErrorType.RATE_LIMIT_EXCEEDED:
        return PLACEMENT_ERROR_CODES.RATE_LIMIT_EXCEEDED;
      case PlacementErrorType.TOO_MANY_REQUESTS:
        return PLACEMENT_ERROR_CODES.TOO_MANY_REQUESTS;
      case PlacementErrorType.INTERNAL_SERVER_ERROR:
        return PLACEMENT_ERROR_CODES.INTERNAL_SERVER_ERROR;
      case PlacementErrorType.DATABASE_ERROR:
        return PLACEMENT_ERROR_CODES.DATABASE_ERROR;
      case PlacementErrorType.NETWORK_ERROR:
        return PLACEMENT_ERROR_CODES.NETWORK_ERROR;
      default:
        return PLACEMENT_ERROR_CODES.INTERNAL_SERVER_ERROR;
    }
  }

  private generateRequestId(): string {
    return `req_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
  }

  /**
   * Public methods for accessing logs and stats
   */
  public getRecentLogs(count: number = 50): PlacementLogEntry[] {
    return this.logEntries.slice(-count);
  }

  public getRateLimitStats(): Map<string, RateLimitInfo> {
    return new Map(this.rateLimitStore);
  }

  public clearRateLimits(): void {
    this.rateLimitStore.clear();
  }

  public clearLogs(): void {
    this.logEntries = [];
  }
}
