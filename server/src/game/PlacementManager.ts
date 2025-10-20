import {
  PlacementGameState,
  PlacementStatus,
  PecaJogo,
  PosicaoTabuleiro,
  Equipe,
  INITIAL_PIECE_INVENTORY,
  Patentes,
} from "../types/game.types.js";
import { v4 as uuidv4 } from "uuid";

export class PlacementManager {
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
    position: PosicaoTabuleiro
  ): { valid: boolean; error?: string } {
    // Check if piece type is available in inventory
    if (
      !placementState.availablePieces[patente] ||
      placementState.availablePieces[patente] <= 0
    ) {
      return { valid: false, error: "Peça não disponível no inventário" };
    }

    // Check if position is within player's area
    if (!placementState.playerArea.includes(position.linha)) {
      return { valid: false, error: "Posição fora da área do jogador" };
    }

    // Check if position is within board bounds
    if (
      position.linha < 0 ||
      position.linha > 9 ||
      position.coluna < 0 ||
      position.coluna > 9
    ) {
      return { valid: false, error: "Posição fora dos limites do tabuleiro" };
    }

    // Check if position is already occupied
    const existingPiece = placementState.placedPieces.find(
      (piece) =>
        piece.posicao.linha === position.linha &&
        piece.posicao.coluna === position.coluna
    );

    if (existingPiece) {
      return { valid: false, error: "Posição já ocupada" };
    }

    return { valid: true };
  }

  /**
   * Places a piece on the board
   */
  public placePiece(
    placementState: PlacementGameState,
    patente: string,
    position: PosicaoTabuleiro
  ): { success: boolean; newState?: PlacementGameState; error?: string } {
    const validation = this.validatePiecePlacement(
      placementState,
      patente,
      position
    );

    if (!validation.valid) {
      return { success: false, error: validation.error };
    }

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

    return { success: true, newState };
  }

  /**
   * Moves a piece to a new position (swap or reposition)
   */
  public movePiece(
    placementState: PlacementGameState,
    pieceId: string,
    newPosition: PosicaoTabuleiro
  ): { success: boolean; newState?: PlacementGameState; error?: string } {
    // Find the piece to move
    const pieceIndex = placementState.placedPieces.findIndex(
      (p) => p.id === pieceId
    );
    if (pieceIndex === -1) {
      return { success: false, error: "Peça não encontrada" };
    }

    const piece = placementState.placedPieces[pieceIndex];

    // Check if new position is within player's area
    if (!placementState.playerArea.includes(newPosition.linha)) {
      return { success: false, error: "Posição fora da área do jogador" };
    }

    // Check if position is within board bounds
    if (
      newPosition.linha < 0 ||
      newPosition.linha > 9 ||
      newPosition.coluna < 0 ||
      newPosition.coluna > 9
    ) {
      return { success: false, error: "Posição fora dos limites do tabuleiro" };
    }

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

    return { success: true, newState };
  }

  /**
   * Removes a piece from the board and returns it to inventory
   */
  public removePiece(
    placementState: PlacementGameState,
    pieceId: string
  ): { success: boolean; newState?: PlacementGameState; error?: string } {
    const pieceIndex = placementState.placedPieces.findIndex(
      (p) => p.id === pieceId
    );
    if (pieceIndex === -1) {
      return { success: false, error: "Peça não encontrada" };
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

    return { success: true, newState };
  }

  /**
   * Validates if all pieces are placed correctly for confirmation
   */
  public validatePlacementCompletion(placementState: PlacementGameState): {
    valid: boolean;
    error?: string;
  } {
    // Check if all pieces are placed (inventory should be empty)
    const totalPiecesInInventory = Object.values(
      placementState.availablePieces
    ).reduce((sum, count) => sum + count, 0);

    if (totalPiecesInInventory > 0) {
      return {
        valid: false,
        error: `${totalPiecesInInventory} peças ainda precisam ser posicionadas`,
      };
    }

    // Check if we have exactly 40 pieces placed
    if (placementState.placedPieces.length !== 40) {
      return {
        valid: false,
        error: `Número incorreto de peças: ${placementState.placedPieces.length}/40`,
      };
    }

    // Validate piece composition
    const pieceComposition: { [patente: string]: number } = {};
    placementState.placedPieces.forEach((piece) => {
      pieceComposition[piece.patente] =
        (pieceComposition[piece.patente] || 0) + 1;
    });

    // Check if composition matches the required inventory
    for (const [patente, requiredCount] of Object.entries(
      INITIAL_PIECE_INVENTORY
    )) {
      const actualCount = pieceComposition[patente] || 0;
      if (actualCount !== requiredCount) {
        return {
          valid: false,
          error: `Composição incorreta: ${
            Patentes[patente]?.nome || patente
          } - esperado ${requiredCount}, atual ${actualCount}`,
        };
      }
    }

    // Check if all pieces are in player's area
    const invalidPieces = placementState.placedPieces.filter(
      (piece) => !placementState.playerArea.includes(piece.posicao.linha)
    );

    if (invalidPieces.length > 0) {
      return {
        valid: false,
        error: "Algumas peças estão fora da área do jogador",
      };
    }

    return { valid: true };
  }

  /**
   * Confirms player's placement and updates status
   */
  public confirmPlacement(placementState: PlacementGameState): {
    success: boolean;
    newState?: PlacementGameState;
    error?: string;
  } {
    const validation = this.validatePlacementCompletion(placementState);

    if (!validation.valid) {
      return { success: false, error: validation.error };
    }

    const newState: PlacementGameState = {
      ...placementState,
      localStatus: PlacementStatus.Ready,
    };

    return { success: true, newState };
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
}
