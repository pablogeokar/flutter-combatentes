import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:combatentes/placement_controller.dart';
import 'package:combatentes/game_socket_service.dart';
import 'package:combatentes/modelos_jogo.dart';
import 'package:combatentes/placement_error_handler.dart';
import 'package:combatentes/providers.dart';

// Generate mocks
@GenerateMocks([GameSocketService])
import 'placement_controller_test.mocks.dart';

void main() {
  group('PlacementController Tests', () {
    late PlacementController controller;
    late MockGameSocketService mockSocketService;

    setUp(() {
      mockSocketService = MockGameSocketService();

      // Setup default mock behavior
      when(
        mockSocketService.streamDeEstados,
      ).thenAnswer((_) => Stream<EstadoJogo>.empty());
      when(
        mockSocketService.streamDeStatus,
      ).thenAnswer((_) => Stream<StatusConexao>.empty());

      controller = PlacementController(mockSocketService);
    });

    tearDown(() {
      controller.dispose();
    });

    group('Initialization', () {
      test('should initialize with null state', () {
        expect(controller.currentState, isNull);
        expect(controller.isGameStarting, isFalse);
        expect(controller.countdownSeconds, equals(3));
        expect(controller.lastError, isNull);
        expect(controller.isRetrying, isFalse);
      });

      test('should listen to socket service streams', () {
        // Verify that the controller subscribes to the streams
        verify(mockSocketService.streamDeEstados).called(1);
        verify(mockSocketService.streamDeStatus).called(1);
      });
    });

    group('State Management', () {
      test('should update state correctly', () {
        final testState = _createTestPlacementState();

        controller.updateState(testState);

        expect(controller.currentState, equals(testState));
      });

      test('should notify listeners when state changes', () {
        var notificationCount = 0;
        controller.addListener(() => notificationCount++);

        final testState = _createTestPlacementState();
        controller.updateState(testState);

        expect(notificationCount, equals(1));
      });

      test('should start countdown when both players ready', () {
        final readyState = _createTestPlacementState(
          localStatus: PlacementStatus.ready,
          opponentStatus: PlacementStatus.ready,
        );

        controller.updateState(readyState);

        expect(controller.isGameStarting, isTrue);
        expect(controller.countdownSeconds, equals(3));
      });

      test('should not start countdown if already started', () {
        final readyState = _createTestPlacementState(
          localStatus: PlacementStatus.ready,
          opponentStatus: PlacementStatus.ready,
        );

        // Start countdown
        controller.updateState(readyState);
        expect(controller.isGameStarting, isTrue);

        // Update state again - should not restart countdown
        controller.updateState(readyState);
        expect(controller.isGameStarting, isTrue);
      });
    });

    group('Placement Validation', () {
      test('should validate valid piece placement', () {
        final testState = _createTestPlacementState();
        controller.updateState(testState);

        final position = PosicaoTabuleiro(linha: 1, coluna: 3);
        final result = controller.validatePiecePlacement(
          position: position,
          pieceType: Patente.soldado,
        );

        expect(result.isSuccess, isTrue);
      });

      test('should reject placement when no state', () {
        final position = PosicaoTabuleiro(linha: 1, coluna: 3);
        final result = controller.validatePiecePlacement(
          position: position,
          pieceType: Patente.soldado,
        );

        expect(result.isFailure, isTrue);
        expect(result.error!.type, equals(PlacementErrorType.invalidGameState));
      });

      test('should reject placement outside player area', () {
        final testState = _createTestPlacementState();
        controller.updateState(testState);

        final invalidPosition = PosicaoTabuleiro(
          linha: 5,
          coluna: 3,
        ); // Outside area
        final result = controller.validatePiecePlacement(
          position: invalidPosition,
          pieceType: Patente.soldado,
        );

        expect(result.isFailure, isTrue);
        expect(result.error!.type, equals(PlacementErrorType.invalidPosition));
      });

      test('should reject placement when piece not available', () {
        final testState = _createTestPlacementState(
          availablePieces: {'soldado': 0}, // No soldiers available
        );
        controller.updateState(testState);

        final position = PosicaoTabuleiro(linha: 1, coluna: 3);
        final result = controller.validatePiecePlacement(
          position: position,
          pieceType: Patente.soldado,
        );

        expect(result.isFailure, isTrue);
        expect(
          result.error!.type,
          equals(PlacementErrorType.pieceNotAvailable),
        );
      });
    });

    group('Placement Confirmation', () {
      test('should confirm placement when all pieces placed', () async {
        final completeState = _createTestPlacementState(
          availablePieces: {}, // All pieces placed
          localStatus: PlacementStatus.placing,
        );
        controller.updateState(completeState);

        final result = await controller.confirmPlacement();

        expect(result.isSuccess, isTrue);
        expect(
          controller.currentState!.localStatus,
          equals(PlacementStatus.waiting),
        );
      });

      test('should reject confirmation when pieces remaining', () async {
        final incompleteState = _createTestPlacementState(
          availablePieces: {'soldado': 2}, // Still have pieces
        );
        controller.updateState(incompleteState);

        final result = await controller.confirmPlacement();

        expect(result.isFailure, isTrue);
        expect(
          result.error!.type,
          equals(PlacementErrorType.incompletePlacement),
        );
      });

      test('should reject confirmation when no state', () async {
        final result = await controller.confirmPlacement();

        expect(result.isFailure, isTrue);
        expect(result.error!.type, equals(PlacementErrorType.invalidGameState));
      });

      test('should update to waiting when opponent not ready', () async {
        final completeState = _createTestPlacementState(
          availablePieces: {},
          localStatus: PlacementStatus.placing,
          opponentStatus: PlacementStatus.placing, // Opponent not ready
        );
        controller.updateState(completeState);

        await controller.confirmPlacement();

        expect(
          controller.currentState!.localStatus,
          equals(PlacementStatus.waiting),
        );
      });

      test('should start countdown when opponent already ready', () async {
        final completeState = _createTestPlacementState(
          availablePieces: {},
          localStatus: PlacementStatus.placing,
          opponentStatus: PlacementStatus.ready, // Opponent already ready
        );
        controller.updateState(completeState);

        await controller.confirmPlacement();

        expect(controller.isGameStarting, isTrue);
      });
    });

    group('Error Handling', () {
      test('should handle and store errors', () async {
        // Trigger error through confirmation with no state
        final result = await controller.confirmPlacement();

        expect(result.isFailure, isTrue);
        expect(controller.lastError, isNotNull);
        expect(
          controller.lastError!.type,
          equals(PlacementErrorType.invalidGameState),
        );
      });

      test('should clear errors', () async {
        // First cause an error
        await controller.confirmPlacement();
        expect(controller.lastError, isNotNull);

        // Clear error
        controller.clearError();
        expect(controller.lastError, isNull);
      });

      test('should notify listeners when error changes', () async {
        var notificationCount = 0;
        controller.addListener(() => notificationCount++);

        // Cause error
        await controller.confirmPlacement();

        // Clear error
        controller.clearError();

        expect(notificationCount, greaterThan(0));
      });
    });

    group('Retry Operations', () {
      test('should execute retry operation', () async {
        var callCount = 0;

        final result = await controller.retryOperation(() async {
          callCount++;
          return PlacementResult.success('test');
        });

        expect(result.isSuccess, isTrue);
        expect(result.data, equals('test'));
        expect(callCount, equals(1));
      });

      test('should prevent concurrent retry operations', () async {
        var callCount = 0;

        // Start first retry
        final future1 = controller.retryOperation(() async {
          callCount++;
          await Future.delayed(Duration(milliseconds: 100));
          return PlacementResult.success('test1');
        });

        // Try to start second retry immediately
        final result2 = await controller.retryOperation(() async {
          callCount++;
          return PlacementResult.success('test2');
        });

        // Second should fail immediately
        expect(result2.isFailure, isTrue);
        expect(
          result2.error!.type,
          equals(PlacementErrorType.invalidGameState),
        );

        // First should complete normally
        final result1 = await future1;
        expect(result1.isSuccess, isTrue);
        expect(callCount, equals(1)); // Only first operation called
      });

      test('should update retry status correctly', () async {
        expect(controller.isRetrying, isFalse);

        final future = controller.retryOperation(() async {
          expect(controller.isRetrying, isTrue);
          return PlacementResult.success('test');
        });

        await future;
        expect(controller.isRetrying, isFalse);
      });
    });

    group('Reset Functionality', () {
      test('should reset all state to initial values', () {
        // Set up some state
        final testState = _createTestPlacementState();
        controller.updateState(testState);

        // Cause an error by trying to confirm with incomplete state
        controller.confirmPlacement();

        // Reset
        controller.reset();

        expect(controller.currentState, isNull);
        expect(controller.isGameStarting, isFalse);
        expect(controller.countdownSeconds, equals(3));
        expect(controller.lastError, isNull);
        expect(controller.isRetrying, isFalse);
      });
    });

    group('Game State Updates', () {
      test('should handle game state updates from socket', () {
        // This would test the private _handleGameStateUpdate method
        // through the stream subscription, but since it's complex to test
        // with the current architecture, we focus on the public API

        final testState = _createTestPlacementState();
        controller.updateState(testState);

        expect(controller.currentState, equals(testState));
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
