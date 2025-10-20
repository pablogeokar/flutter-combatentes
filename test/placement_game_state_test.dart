import 'package:flutter_test/flutter_test.dart';
import 'package:combatentes/modelos_jogo.dart';

void main() {
  group('PlacementGameState Tests', () {
    group('State Transitions', () {
      test('should create initial placement state correctly', () {
        final state = PlacementGameState(
          gameId: 'test-game',
          playerId: 'player-1',
          availablePieces: PlacementGameState.createInitialInventory(),
          placedPieces: [],
          playerArea: [0, 1, 2, 3],
          localStatus: PlacementStatus.placing,
          opponentStatus: PlacementStatus.placing,
          gamePhase: GamePhase.piecePlacement,
        );

        expect(state.gameId, equals('test-game'));
        expect(state.playerId, equals('player-1'));
        expect(state.playerArea, equals([0, 1, 2, 3]));
        expect(state.localStatus, equals(PlacementStatus.placing));
        expect(state.opponentStatus, equals(PlacementStatus.placing));
        expect(state.gamePhase, equals(GamePhase.piecePlacement));
        expect(state.selectedPieceType, isNull);
      });

      test('should transition from placing to ready correctly', () {
        final initialState = PlacementGameState(
          gameId: 'test-game',
          playerId: 'player-1',
          availablePieces: {},
          placedPieces: _createFullPieceSet(),
          playerArea: [0, 1, 2, 3],
          localStatus: PlacementStatus.placing,
          opponentStatus: PlacementStatus.placing,
          gamePhase: GamePhase.piecePlacement,
        );

        expect(initialState.allPiecesPlaced, isTrue);
        expect(initialState.canConfirm, isTrue);
      });

      test('should not allow confirmation when pieces remaining', () {
        final stateWithPieces = PlacementGameState(
          gameId: 'test-game',
          playerId: 'player-1',
          availablePieces: {'soldado': 2},
          placedPieces: [],
          playerArea: [0, 1, 2, 3],
          localStatus: PlacementStatus.placing,
          opponentStatus: PlacementStatus.placing,
          gamePhase: GamePhase.piecePlacement,
        );

        expect(stateWithPieces.allPiecesPlaced, isFalse);
        expect(stateWithPieces.canConfirm, isFalse);
        expect(stateWithPieces.totalPiecesRemaining, equals(2));
      });

      test('should not allow confirmation when already ready', () {
        final readyState = PlacementGameState(
          gameId: 'test-game',
          playerId: 'player-1',
          availablePieces: {},
          placedPieces: _createFullPieceSet(),
          playerArea: [0, 1, 2, 3],
          localStatus: PlacementStatus.ready,
          opponentStatus: PlacementStatus.placing,
          gamePhase: GamePhase.piecePlacement,
        );

        expect(readyState.allPiecesPlaced, isTrue);
        expect(readyState.canConfirm, isFalse); // Already ready
      });

      test('should transition to game phase when both ready', () {
        final gameStartState = PlacementGameState(
          gameId: 'test-game',
          playerId: 'player-1',
          availablePieces: {},
          placedPieces: _createFullPieceSet(),
          playerArea: [0, 1, 2, 3],
          localStatus: PlacementStatus.ready,
          opponentStatus: PlacementStatus.ready,
          gamePhase: GamePhase.gameInProgress,
        );

        expect(gameStartState.localStatus, equals(PlacementStatus.ready));
        expect(gameStartState.opponentStatus, equals(PlacementStatus.ready));
        expect(gameStartState.gamePhase, equals(GamePhase.gameInProgress));
      });
    });

    group('Initial Inventory', () {
      test('should create correct initial inventory', () {
        final inventory = PlacementGameState.createInitialInventory();

        expect(inventory['marechal'], equals(1));
        expect(inventory['general'], equals(1));
        expect(inventory['coronel'], equals(2));
        expect(inventory['major'], equals(3));
        expect(inventory['capitao'], equals(4));
        expect(inventory['tenente'], equals(4));
        expect(inventory['sargento'], equals(4));
        expect(inventory['cabo'], equals(5));
        expect(inventory['soldado'], equals(8));
        expect(inventory['agenteSecreto'], equals(1));
        expect(inventory['prisioneiro'], equals(1));
        expect(inventory['minaTerrestre'], equals(6));

        // Total should be 40 pieces
        final total = inventory.values.fold(0, (sum, count) => sum + count);
        expect(total, equals(40));
      });

      test('should have all required piece types', () {
        final inventory = PlacementGameState.createInitialInventory();
        final expectedTypes = [
          'marechal',
          'general',
          'coronel',
          'major',
          'capitao',
          'tenente',
          'sargento',
          'cabo',
          'soldado',
          'agenteSecreto',
          'prisioneiro',
          'minaTerrestre',
        ];

        for (final type in expectedTypes) {
          expect(
            inventory.containsKey(type),
            isTrue,
            reason: 'Inventory should contain $type',
          );
          expect(
            inventory[type]! > 0,
            isTrue,
            reason: '$type should have positive count',
          );
        }
      });
    });

    group('Piece Count Calculations', () {
      test('should calculate total pieces remaining correctly', () {
        final state = PlacementGameState(
          gameId: 'test-game',
          playerId: 'player-1',
          availablePieces: {'soldado': 5, 'marechal': 1, 'cabo': 2},
          placedPieces: [],
          playerArea: [0, 1, 2, 3],
          localStatus: PlacementStatus.placing,
          opponentStatus: PlacementStatus.placing,
          gamePhase: GamePhase.piecePlacement,
        );

        expect(state.totalPiecesRemaining, equals(8));
      });

      test('should detect when all pieces are placed', () {
        final emptyInventoryState = PlacementGameState(
          gameId: 'test-game',
          playerId: 'player-1',
          availablePieces: {},
          placedPieces: _createFullPieceSet(),
          playerArea: [0, 1, 2, 3],
          localStatus: PlacementStatus.placing,
          opponentStatus: PlacementStatus.placing,
          gamePhase: GamePhase.piecePlacement,
        );

        expect(emptyInventoryState.allPiecesPlaced, isTrue);
        expect(emptyInventoryState.totalPiecesRemaining, equals(0));
      });

      test('should detect when pieces are still available', () {
        final partialState = PlacementGameState(
          gameId: 'test-game',
          playerId: 'player-1',
          availablePieces: {'soldado': 3},
          placedPieces: [],
          playerArea: [0, 1, 2, 3],
          localStatus: PlacementStatus.placing,
          opponentStatus: PlacementStatus.placing,
          gamePhase: GamePhase.piecePlacement,
        );

        expect(partialState.allPiecesPlaced, isFalse);
        expect(partialState.totalPiecesRemaining, equals(3));
      });
    });

    group('Confirmation Logic', () {
      test(
        'should allow confirmation when all pieces placed and status is placing',
        () {
          final readyToConfirmState = PlacementGameState(
            gameId: 'test-game',
            playerId: 'player-1',
            availablePieces: {},
            placedPieces: _createFullPieceSet(),
            playerArea: [0, 1, 2, 3],
            localStatus: PlacementStatus.placing,
            opponentStatus: PlacementStatus.placing,
            gamePhase: GamePhase.piecePlacement,
          );

          expect(readyToConfirmState.canConfirm, isTrue);
        },
      );

      test('should not allow confirmation when pieces remaining', () {
        final incompleteState = PlacementGameState(
          gameId: 'test-game',
          playerId: 'player-1',
          availablePieces: {'soldado': 1},
          placedPieces: [],
          playerArea: [0, 1, 2, 3],
          localStatus: PlacementStatus.placing,
          opponentStatus: PlacementStatus.placing,
          gamePhase: GamePhase.piecePlacement,
        );

        expect(incompleteState.canConfirm, isFalse);
      });

      test('should not allow confirmation when already confirmed', () {
        final alreadyReadyState = PlacementGameState(
          gameId: 'test-game',
          playerId: 'player-1',
          availablePieces: {},
          placedPieces: _createFullPieceSet(),
          playerArea: [0, 1, 2, 3],
          localStatus: PlacementStatus.ready,
          opponentStatus: PlacementStatus.placing,
          gamePhase: GamePhase.piecePlacement,
        );

        expect(alreadyReadyState.canConfirm, isFalse);
      });

      test('should not allow confirmation when waiting', () {
        final waitingState = PlacementGameState(
          gameId: 'test-game',
          playerId: 'player-1',
          availablePieces: {},
          placedPieces: _createFullPieceSet(),
          playerArea: [0, 1, 2, 3],
          localStatus: PlacementStatus.waiting,
          opponentStatus: PlacementStatus.placing,
          gamePhase: GamePhase.piecePlacement,
        );

        expect(waitingState.canConfirm, isFalse);
      });
    });

    group('JSON Serialization', () {
      test('should serialize and deserialize correctly', () {
        final originalState = PlacementGameState(
          gameId: 'test-game',
          playerId: 'player-1',
          availablePieces: {'soldado': 5, 'marechal': 1},
          placedPieces: [
            PecaJogo(
              id: 'piece-1',
              patente: Patente.soldado,
              equipe: Equipe.verde,
              posicao: PosicaoTabuleiro(linha: 1, coluna: 2),
            ),
          ],
          playerArea: [0, 1, 2, 3],
          localStatus: PlacementStatus.placing,
          opponentStatus: PlacementStatus.ready,
          selectedPieceType: Patente.soldado,
          gamePhase: GamePhase.piecePlacement,
        );

        // Serialize
        final json = originalState.toJson();

        // Deserialize
        final restoredState = PlacementGameState.fromJson(json);

        // Verify all fields
        expect(restoredState.gameId, equals(originalState.gameId));
        expect(restoredState.playerId, equals(originalState.playerId));
        expect(
          restoredState.availablePieces,
          equals(originalState.availablePieces),
        );
        expect(
          restoredState.placedPieces.length,
          equals(originalState.placedPieces.length),
        );
        expect(restoredState.playerArea, equals(originalState.playerArea));
        expect(restoredState.localStatus, equals(originalState.localStatus));
        expect(
          restoredState.opponentStatus,
          equals(originalState.opponentStatus),
        );
        expect(
          restoredState.selectedPieceType,
          equals(originalState.selectedPieceType),
        );
        expect(restoredState.gamePhase, equals(originalState.gamePhase));

        // Verify piece details
        final originalPiece = originalState.placedPieces.first;
        final restoredPiece = restoredState.placedPieces.first;
        expect(restoredPiece.id, equals(originalPiece.id));
        expect(restoredPiece.patente, equals(originalPiece.patente));
        expect(restoredPiece.equipe, equals(originalPiece.equipe));
        expect(
          restoredPiece.posicao.linha,
          equals(originalPiece.posicao.linha),
        );
        expect(
          restoredPiece.posicao.coluna,
          equals(originalPiece.posicao.coluna),
        );
      });

      test('should handle null optional fields in serialization', () {
        final stateWithNulls = PlacementGameState(
          gameId: 'test-game',
          playerId: 'player-1',
          availablePieces: {},
          placedPieces: [],
          playerArea: [0, 1, 2, 3],
          localStatus: PlacementStatus.placing,
          opponentStatus: PlacementStatus.placing,
          selectedPieceType: null, // Null optional field
          gamePhase: GamePhase.piecePlacement,
        );

        final json = stateWithNulls.toJson();
        final restored = PlacementGameState.fromJson(json);

        expect(restored.selectedPieceType, isNull);
        expect(restored.gameId, equals(stateWithNulls.gameId));
      });
    });

    group('Edge Cases', () {
      test('should handle empty available pieces map', () {
        final emptyState = PlacementGameState(
          gameId: 'test-game',
          playerId: 'player-1',
          availablePieces: {},
          placedPieces: [],
          playerArea: [0, 1, 2, 3],
          localStatus: PlacementStatus.placing,
          opponentStatus: PlacementStatus.placing,
          gamePhase: GamePhase.piecePlacement,
        );

        expect(emptyState.totalPiecesRemaining, equals(0));
        expect(emptyState.allPiecesPlaced, isTrue);
      });

      test('should handle different player areas', () {
        // Bottom player area
        final bottomPlayerState = PlacementGameState(
          gameId: 'test-game',
          playerId: 'player-2',
          availablePieces: {'soldado': 1},
          placedPieces: [],
          playerArea: [6, 7, 8, 9],
          localStatus: PlacementStatus.placing,
          opponentStatus: PlacementStatus.placing,
          gamePhase: GamePhase.piecePlacement,
        );

        expect(bottomPlayerState.playerArea, equals([6, 7, 8, 9]));
        expect(bottomPlayerState.playerId, equals('player-2'));
      });

      test('should handle large piece collections', () {
        final largePieceList = <PecaJogo>[];
        for (int i = 0; i < 40; i++) {
          largePieceList.add(
            PecaJogo(
              id: 'piece-$i',
              patente: Patente.soldado,
              equipe: Equipe.verde,
              posicao: PosicaoTabuleiro(linha: i ~/ 10, coluna: i % 10),
            ),
          );
        }

        final stateWithManyPieces = PlacementGameState(
          gameId: 'test-game',
          playerId: 'player-1',
          availablePieces: {},
          placedPieces: largePieceList,
          playerArea: [0, 1, 2, 3],
          localStatus: PlacementStatus.placing,
          opponentStatus: PlacementStatus.placing,
          gamePhase: GamePhase.piecePlacement,
        );

        expect(stateWithManyPieces.placedPieces.length, equals(40));
        expect(stateWithManyPieces.allPiecesPlaced, isTrue);
      });
    });
  });
}

/// Helper function to create a full set of 40 pieces for testing
List<PecaJogo> _createFullPieceSet() {
  final pieces = <PecaJogo>[];
  var pieceId = 0;

  // Create pieces according to standard army composition
  final composition = PlacementGameState.createInitialInventory();

  composition.forEach((patenteString, count) {
    final patente = Patente.values.firstWhere((p) => p.name == patenteString);

    for (int i = 0; i < count; i++) {
      pieces.add(
        PecaJogo(
          id: 'piece-${pieceId++}',
          patente: patente,
          equipe: Equipe.verde,
          posicao: PosicaoTabuleiro(linha: pieceId ~/ 10, coluna: pieceId % 10),
        ),
      );
    }
  });

  return pieces;
}
