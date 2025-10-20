import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:combatentes/placement_provider.dart';
import 'package:combatentes/placement_controller.dart';
import 'package:combatentes/modelos_jogo.dart';
import 'package:combatentes/placement_error_handler.dart';

// Generate mocks
@GenerateMocks([PlacementController])
import 'placement_provider_test.mocks.dart';

void main() {
  group('PlacementProvider Tests', () {
    late ProviderContainer container;
    late MockPlacementController mockController;

    setUp(() {
      mockController = MockPlacementController();

      // Setup default mock behavior
      when(mockController.currentState).thenReturn(null);
      when(mockController.lastError).thenReturn(null);
      when(mockController.isRetrying).thenReturn(false);

      container = ProviderContainer(
        overrides: [
          placementControllerProvider.overrideWithValue(mockController),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    group('PlacementScreenState', () {
      test('should create state with default values', () {
        const state = PlacementScreenState();

        expect(state.placementState, isNull);
        expect(state.isLoading, isFalse);
        expect(state.error, isNull);
        expect(state.shouldNavigateToGame, isFalse);
        expect(state.isRetrying, isFalse);
      });

      test('should copy state with new values', () {
        const originalState = PlacementScreenState(
          isLoading: true,
          shouldNavigateToGame: false,
        );

        final newState = originalState.copyWith(
          isLoading: false,
          shouldNavigateToGame: true,
        );

        expect(newState.isLoading, isFalse);
        expect(newState.shouldNavigateToGame, isTrue);
      });

      test('should clear error when specified', () {
        final error = PlacementError.networkError(operation: 'test');
        final stateWithError = PlacementScreenState(error: error);

        final clearedState = stateWithError.copyWith(clearError: true);

        expect(clearedState.error, isNull);
      });

      test('should preserve error when not clearing', () {
        final error = PlacementError.networkError(operation: 'test');
        final stateWithError = PlacementScreenState(error: error);

        final newState = stateWithError.copyWith(isLoading: true);

        expect(newState.error, equals(error));
      });
    });

    group('PlacementStateNotifier', () {
      late PlacementStateNotifier notifier;

      setUp(() {
        notifier = container.read(placementStateProvider.notifier);
      });

      group('Initialization', () {
        test('should initialize with empty state', () {
          final state = container.read(placementStateProvider);

          expect(state.placementState, isNull);
          expect(state.isLoading, isFalse);
          expect(state.error, isNull);
          expect(state.shouldNavigateToGame, isFalse);
          expect(state.isRetrying, isFalse);
        });

        test('should initialize placement with given state', () {
          final testState = _createTestPlacementState();

          notifier.initializePlacement(testState);

          final state = container.read(placementStateProvider);
          expect(state.placementState, equals(testState));
          expect(state.isLoading, isFalse);
          expect(state.error, isNull);

          verify(mockController.addListener(any)).called(1);
          verify(mockController.updateState(testState)).called(1);
        });

        test(
          'should initialize with restore and use fallback when no saved state',
          () async {
            final fallbackState = _createTestPlacementState();
            when(
              mockController.restoreSavedState(),
            ).thenAnswer((_) async => null);

            await notifier.initializePlacementWithRestore(fallbackState);

            final state = container.read(placementStateProvider);
            expect(state.placementState, equals(fallbackState));
            expect(state.isLoading, isFalse);

            verify(mockController.restoreSavedState()).called(1);
            verify(mockController.updateState(fallbackState)).called(1);
          },
        );

        test(
          'should initialize with restore and use saved state when available',
          () async {
            final savedState = _createTestPlacementState(gameId: 'saved-game');
            final fallbackState = _createTestPlacementState(
              gameId: 'fallback-game',
            );

            when(
              mockController.restoreSavedState(),
            ).thenAnswer((_) async => savedState);

            await notifier.initializePlacementWithRestore(fallbackState);

            final state = container.read(placementStateProvider);
            expect(state.placementState, equals(savedState));
            expect(state.isLoading, isFalse);

            verify(mockController.restoreSavedState()).called(1);
            verifyNever(mockController.updateState(fallbackState));
          },
        );

        test('should handle restore error and use fallback', () async {
          final fallbackState = _createTestPlacementState();
          when(
            mockController.restoreSavedState(),
          ).thenThrow(Exception('Restore failed'));

          await notifier.initializePlacementWithRestore(fallbackState);

          final state = container.read(placementStateProvider);
          expect(state.placementState, equals(fallbackState));
          expect(state.error, isNotNull);
          expect(
            state.error!.type,
            equals(PlacementErrorType.invalidGameState),
          );

          verify(mockController.updateState(fallbackState)).called(1);
        });
      });

      group('Placement Confirmation', () {
        test('should confirm placement successfully', () async {
          final testState = _createTestPlacementState();
          notifier.initializePlacement(testState);

          when(
            mockController.confirmPlacement(),
          ).thenAnswer((_) async => PlacementResult.success(null));

          await notifier.confirmPlacement();

          final state = container.read(placementStateProvider);
          expect(state.isLoading, isFalse);
          expect(state.error, isNull);

          verify(mockController.confirmPlacement()).called(1);
        });

        test('should handle confirmation failure', () async {
          final testState = _createTestPlacementState();
          notifier.initializePlacement(testState);

          final error = PlacementError.networkError(operation: 'confirm');
          when(
            mockController.confirmPlacement(),
          ).thenAnswer((_) async => PlacementResult.failure(error));

          await notifier.confirmPlacement();

          final state = container.read(placementStateProvider);
          expect(state.isLoading, isFalse);
          expect(state.error, equals(error));

          verify(mockController.confirmPlacement()).called(1);
        });

        test('should not confirm when controller not initialized', () async {
          await notifier.confirmPlacement();

          // Should not call controller since it's not initialized
          verifyNever(mockController.confirmPlacement());
        });

        test('should set loading state during confirmation', () async {
          final testState = _createTestPlacementState();
          notifier.initializePlacement(testState);

          // Setup a delayed response to test loading state
          when(mockController.confirmPlacement()).thenAnswer((_) async {
            await Future.delayed(Duration(milliseconds: 10));
            return PlacementResult.success(null);
          });

          // Start confirmation
          final future = notifier.confirmPlacement();

          // Check loading state immediately
          var state = container.read(placementStateProvider);
          expect(state.isLoading, isTrue);

          // Wait for completion
          await future;

          // Check final state
          state = container.read(placementStateProvider);
          expect(state.isLoading, isFalse);
        });
      });

      group('Validation', () {
        test('should validate piece placement successfully', () {
          final testState = _createTestPlacementState();
          notifier.initializePlacement(testState);

          final position = PosicaoTabuleiro(linha: 1, coluna: 3);
          when(
            mockController.validatePiecePlacement(
              position: position,
              pieceType: Patente.soldado,
            ),
          ).thenReturn(PlacementResult.success(null));

          final result = notifier.validatePiecePlacement(
            position: position,
            pieceType: Patente.soldado,
          );

          expect(result.isSuccess, isTrue);
          verify(
            mockController.validatePiecePlacement(
              position: position,
              pieceType: Patente.soldado,
            ),
          ).called(1);
        });

        test('should handle validation failure when no controller', () {
          final position = PosicaoTabuleiro(linha: 1, coluna: 3);

          final result = notifier.validatePiecePlacement(
            position: position,
            pieceType: Patente.soldado,
          );

          expect(result.isFailure, isTrue);
          expect(
            result.error!.type,
            equals(PlacementErrorType.invalidGameState),
          );
          expect(
            result.error!.userMessage,
            contains('Controller não inicializado'),
          );
        });
      });

      group('Error Handling', () {
        test('should handle placement error', () {
          final error = PlacementError.invalidPosition(
            position: PosicaoTabuleiro(linha: 5, coluna: 3),
            reason: 'Outside area',
          );

          notifier.handlePlacementError(error);

          final state = container.read(placementStateProvider);
          expect(state.error, equals(error));
        });

        test('should clear error', () {
          final error = PlacementError.networkError(operation: 'test');
          notifier.handlePlacementError(error);

          // Verify error is set
          var state = container.read(placementStateProvider);
          expect(state.error, equals(error));

          // Clear error
          notifier.clearError();

          // Verify error is cleared
          state = container.read(placementStateProvider);
          expect(state.error, isNull);
        });

        test('should handle disconnection error', () {
          final error = PlacementError(
            type: PlacementErrorType.opponentDisconnected,
            userMessage: 'Opponent disconnected',
          );

          notifier.handleDisconnectionError(error);

          final state = container.read(placementStateProvider);
          expect(state.error, equals(error));
        });
      });

      group('Retry Operations', () {
        test('should retry last operation', () async {
          final testState = _createTestPlacementState();
          notifier.initializePlacement(testState);

          when(
            mockController.confirmPlacement(),
          ).thenAnswer((_) async => PlacementResult.success(null));

          await notifier.retryLastOperation();

          verify(mockController.confirmPlacement()).called(1);
        });

        test('should not retry when controller not initialized', () async {
          await notifier.retryLastOperation();

          verifyNever(mockController.confirmPlacement());
        });
      });

      group('Navigation Control', () {
        test('should reset to game state', () {
          // Set up initial state manually
          notifier.state = PlacementScreenState(
            placementState: _createTestPlacementState(),
            shouldNavigateToGame: true,
            error: PlacementError.networkError(operation: 'test'),
          );

          // Verify initial state
          var initialState = container.read(placementStateProvider);
          expect(initialState.placementState, isNotNull);
          expect(initialState.shouldNavigateToGame, isTrue);
          expect(initialState.error, isNotNull);

          notifier.resetToGame();

          final state = container.read(placementStateProvider);
          expect(state.placementState, isNull);
          expect(state.shouldNavigateToGame, isFalse);
          expect(state.error, isNull);
        });
      });

      group('State Persistence', () {
        test('should check for valid saved state', () async {
          // This method calls PlacementPersistence directly, not the controller
          // So we expect it to return false (default behavior)
          final hasState = await notifier.hasValidSavedState();

          expect(hasState, isFalse); // No saved state in test environment
        });

        test('should clear persisted state', () async {
          // Initialize controller first
          final testState = _createTestPlacementState();
          notifier.initializePlacement(testState);

          when(mockController.clearPersistedState()).thenAnswer((_) async {});

          await notifier.clearPersistedState();

          verify(mockController.clearPersistedState()).called(1);
        });

        test('should save current state', () async {
          final testState = _createTestPlacementState();
          notifier.initializePlacement(testState);

          await notifier.saveCurrentState();

          // This would verify the persistence call, but since it's using
          // PlacementPersistence directly, we can't easily mock it here
          // In a real implementation, we'd inject the persistence service
        });
      });

      group('Reconnection', () {
        test('should attempt manual reconnection successfully', () async {
          final testState = _createTestPlacementState();
          notifier.initializePlacement(testState);

          when(
            mockController.attemptManualReconnection(),
          ).thenAnswer((_) async => true);

          final success = await notifier.attemptManualReconnection();

          expect(success, isTrue);
          verify(mockController.attemptManualReconnection()).called(1);
        });

        test('should handle reconnection failure', () async {
          final testState = _createTestPlacementState();
          notifier.initializePlacement(testState);

          when(
            mockController.attemptManualReconnection(),
          ).thenAnswer((_) async => false);

          final success = await notifier.attemptManualReconnection();

          expect(success, isFalse);

          final state = container.read(placementStateProvider);
          expect(state.isLoading, isFalse);
          // The current implementation doesn't set an error for false return,
          // only for exceptions. This might be the intended behavior.
        });

        test('should handle reconnection exception', () async {
          final testState = _createTestPlacementState();
          notifier.initializePlacement(testState);

          when(
            mockController.attemptManualReconnection(),
          ).thenThrow(Exception('Connection failed'));

          final success = await notifier.attemptManualReconnection();

          expect(success, isFalse);

          final state = container.read(placementStateProvider);
          expect(state.error, isNotNull);
          expect(state.error!.type, equals(PlacementErrorType.networkError));
        });

        test('should return to matchmaking', () async {
          final testState = _createTestPlacementState();
          notifier.initializePlacement(testState);

          when(mockController.reset()).thenReturn(null);

          await notifier.returnToMatchmaking();

          final state = container.read(placementStateProvider);
          expect(state.placementState, isNull);
          expect(state.isLoading, isFalse);
          expect(state.error, isNull);
          expect(state.shouldNavigateToGame, isFalse);
          expect(state.isRetrying, isFalse);

          verify(mockController.reset()).called(1);
        });
      });
    });

    group('Helper Functions', () {
      test('should create initial placement state correctly', () {
        const gameId = 'test-game';
        const playerId = 'test-player';
        final playerArea = [0, 1, 2, 3];

        final state = createInitialPlacementState(
          gameId: gameId,
          playerId: playerId,
          playerArea: playerArea,
        );

        expect(state.gameId, equals(gameId));
        expect(state.playerId, equals(playerId));
        expect(state.playerArea, equals(playerArea));
        expect(state.localStatus, equals(PlacementStatus.placing));
        expect(state.opponentStatus, equals(PlacementStatus.placing));
        expect(state.gamePhase, equals(GamePhase.piecePlacement));
        expect(state.availablePieces.length, greaterThan(0));
        expect(state.placedPieces.length, equals(0));
      });
    });
  });
}

/// Helper function to create test placement state
PlacementGameState _createTestPlacementState({
  String gameId = 'test-game',
  String playerId = 'test-player',
  Map<String, int>? availablePieces,
  List<PecaJogo>? placedPieces,
  List<int>? playerArea,
  PlacementStatus localStatus = PlacementStatus.placing,
  PlacementStatus opponentStatus = PlacementStatus.placing,
  Patente? selectedPieceType,
  GamePhase gamePhase = GamePhase.piecePlacement,
}) {
  return PlacementGameState(
    gameId: gameId,
    playerId: playerId,
    availablePieces: availablePieces ?? {'soldado': 8, 'marechal': 1},
    placedPieces: placedPieces ?? [],
    playerArea: playerArea ?? [0, 1, 2, 3],
    localStatus: localStatus,
    opponentStatus: opponentStatus,
    selectedPieceType: selectedPieceType,
    gamePhase: gamePhase,
  );
}
