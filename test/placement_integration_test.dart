import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';

import '../lib/modelos_jogo.dart';
import '../lib/placement_controller.dart';
import '../lib/placement_provider.dart';
import '../lib/placement_error_handler.dart';
import '../lib/game_socket_service.dart';
import '../lib/providers.dart';

/// Test implementation of GameSocketService that doesn't actually connect
class TestGameSocketService extends GameSocketService {
  final _estadoController = StreamController<EstadoJogo>.broadcast();
  final _erroController = StreamController<String>.broadcast();
  final _statusController = StreamController<StatusConexao>.broadcast();

  @override
  Stream<EstadoJogo> get streamDeEstados => _estadoController.stream;

  @override
  Stream<String> get streamDeErros => _erroController.stream;

  @override
  Stream<StatusConexao> get streamDeStatus => _statusController.stream;

  @override
  void connect(String url, {String? nomeUsuario}) {
    // Simulate successful connection
    _statusController.add(StatusConexao.conectado);
  }

  @override
  void enviarMovimento(String idPeca, PosicaoTabuleiro novaPosicao) {
    // Simulate sending movement - do nothing in test
  }

  @override
  void enviarNome(String nome) {
    // Simulate sending name - do nothing in test
  }

  @override
  void reconnect(String url, {String? nomeUsuario}) {
    // Simulate reconnection
    _statusController.add(StatusConexao.conectado);
  }

  @override
  Future<bool> reconnectDuringPlacement(
    String url, {
    String? nomeUsuario,
  }) async {
    // Simulate successful reconnection
    _statusController.add(StatusConexao.conectado);
    return true;
  }

  @override
  void enviarMensagemPlacement(Map<String, dynamic> message) {
    // Simulate sending placement message - do nothing in test
  }

  @override
  void dispose() {
    _estadoController.close();
    _erroController.close();
    _statusController.close();
    super.dispose();
  }

  // Test helper methods
  void simulateGameState(EstadoJogo estado) {
    _estadoController.add(estado);
  }

  void simulateError(String error) {
    _erroController.add(error);
  }

  void simulateStatusChange(StatusConexao status) {
    _statusController.add(status);
  }
}

/// Integration tests for the complete placement flow from client to server.
///
/// These tests simulate the full client-server communication during
/// the piece placement phase, ensuring proper synchronization and
/// state management between multiple players.
void main() {
  group('Placement Integration Tests', () {
    late ProviderContainer container;
    late PlacementController placementController;
    late TestGameSocketService testSocketService;

    setUp(() {
      // Create a test socket service that doesn't actually connect
      testSocketService = TestGameSocketService();

      container = ProviderContainer(
        overrides: [gameSocketProvider.overrideWithValue(testSocketService)],
      );
      placementController = container.read(placementControllerProvider);
    });

    tearDown(() {
      testSocketService.dispose();
      container.dispose();
    });

    group('Complete Placement Flow', () {
      test(
        'should complete full placement flow from start to game begin',
        () async {
          // Arrange: Setup initial game state
          final gameState = PlacementGameState(
            gameId: 'test-game-123',
            playerId: 'player1',
            availablePieces: PlacementGameState.createInitialInventory(),
            placedPieces: [],
            playerArea: [0, 1, 2, 3],
            localStatus: PlacementStatus.placing,
            opponentStatus: PlacementStatus.placing,
            gamePhase: GamePhase.piecePlacement,
          );

          // Initialize placement state
          container
              .read(placementStateProvider.notifier)
              .initializePlacement(gameState);

          // Act & Assert: Validate piece placement
          final validationResult = placementController.validatePiecePlacement(
            position: const PosicaoTabuleiro(linha: 0, coluna: 0),
            pieceType: Patente.soldado,
          );

          expect(validationResult.isSuccess, isTrue);

          // Verify initial state
          final currentState = container.read(placementStateProvider);
          expect(currentState.placementState?.totalPiecesRemaining, equals(40));
          expect(currentState.placementState?.allPiecesPlaced, isFalse);
        },
      );

      test('should handle placement confirmation correctly', () async {
        // Arrange: Setup game with all pieces placed
        final gameState = PlacementGameState(
          gameId: 'test-game-456',
          playerId: 'player1',
          availablePieces: {}, // Empty inventory (all pieces placed)
          placedPieces: _createFullPieceSet(Equipe.verde, [0, 1, 2, 3]),
          playerArea: [0, 1, 2, 3],
          localStatus: PlacementStatus.placing,
          opponentStatus: PlacementStatus.placing,
          gamePhase: GamePhase.piecePlacement,
        );

        container
            .read(placementStateProvider.notifier)
            .initializePlacement(gameState);

        // Act: Confirm placement
        final result = await placementController.confirmPlacement();

        // Assert: Confirmation successful
        expect(result.isSuccess, isTrue);

        final currentState = container.read(placementStateProvider);
        // When opponent is not ready, local status should be waiting
        expect(
          currentState.placementState?.localStatus,
          equals(PlacementStatus.waiting),
        );
      });

      test('should handle game start transition', () async {
        // Arrange: Setup game with both players ready
        final gameState = PlacementGameState(
          gameId: 'test-game-789',
          playerId: 'player1',
          availablePieces: {},
          placedPieces: _createFullPieceSet(Equipe.verde, [0, 1, 2, 3]),
          playerArea: [0, 1, 2, 3],
          localStatus: PlacementStatus.ready,
          opponentStatus: PlacementStatus.ready,
          gamePhase: GamePhase.piecePlacement,
        );

        container
            .read(placementStateProvider.notifier)
            .initializePlacement(gameState);

        // Wait for countdown to complete (simulated)
        await Future.delayed(const Duration(milliseconds: 100));

        // Assert: Game should be starting
        expect(placementController.isGameStarting, isTrue);
      });
    });

    group('Error Scenarios and Recovery', () {
      test('should handle invalid placement attempts', () async {
        // Arrange: Setup basic game state
        final gameState = PlacementGameState(
          gameId: 'test-game-invalid',
          playerId: 'player1',
          availablePieces: PlacementGameState.createInitialInventory(),
          placedPieces: [],
          playerArea: [0, 1, 2, 3],
          localStatus: PlacementStatus.placing,
          opponentStatus: PlacementStatus.placing,
          gamePhase: GamePhase.piecePlacement,
        );

        container
            .read(placementStateProvider.notifier)
            .initializePlacement(gameState);

        // Act & Assert: Try invalid placements

        // Try to place in opponent area (should fail)
        final invalidAreaResult = placementController.validatePiecePlacement(
          position: const PosicaoTabuleiro(
            linha: 6,
            coluna: 0,
          ), // Opponent area
          pieceType: Patente.soldado,
        );
        expect(invalidAreaResult.isFailure, isTrue);

        // Try to place in lake (should fail)
        final lakeResult = placementController.validatePiecePlacement(
          position: const PosicaoTabuleiro(
            linha: 4,
            coluna: 2,
          ), // Lake position
          pieceType: Patente.soldado,
        );
        expect(lakeResult.isFailure, isTrue);
      });

      test('should handle incomplete placement confirmation', () async {
        // Arrange: Setup game with pieces still in inventory
        final gameState = PlacementGameState(
          gameId: 'test-game-incomplete',
          playerId: 'player1',
          availablePieces: {'soldado': 5}, // Still has pieces to place
          placedPieces: [],
          playerArea: [0, 1, 2, 3],
          localStatus: PlacementStatus.placing,
          opponentStatus: PlacementStatus.placing,
          gamePhase: GamePhase.piecePlacement,
        );

        container
            .read(placementStateProvider.notifier)
            .initializePlacement(gameState);

        // Act: Try to confirm incomplete placement
        final result = await placementController.confirmPlacement();

        // Assert: Should fail
        expect(result.isFailure, isTrue);
        expect(
          placementController.lastError?.type,
          equals(PlacementErrorType.incompletePlacement),
        );
      });

      test('should handle state restoration', () async {
        // Arrange: Mock saved state
        final gameState = PlacementGameState(
          gameId: 'test-game-restore',
          playerId: 'player1',
          availablePieces: {'soldado': 7}, // One piece placed
          placedPieces: [
            PecaJogo(
              id: 'piece-1',
              patente: Patente.soldado,
              equipe: Equipe.verde,
              posicao: const PosicaoTabuleiro(linha: 0, coluna: 0),
              foiRevelada: false,
            ),
          ],
          playerArea: [0, 1, 2, 3],
          localStatus: PlacementStatus.placing,
          opponentStatus: PlacementStatus.placing,
          gamePhase: GamePhase.piecePlacement,
        );

        // Act: Initialize with restore
        await container
            .read(placementStateProvider.notifier)
            .initializePlacementWithRestore(gameState);

        // Assert: State should be initialized
        final currentState = container.read(placementStateProvider);
        expect(currentState.placementState, isNotNull);
        expect(currentState.isLoading, isFalse);
      });

      test('should handle disconnection and reconnection', () async {
        // Arrange: Setup placement in progress
        final gameState = PlacementGameState(
          gameId: 'test-game-disconnect',
          playerId: 'player1',
          availablePieces: {'soldado': 7},
          placedPieces: [
            PecaJogo(
              id: 'piece-1',
              patente: Patente.soldado,
              equipe: Equipe.verde,
              posicao: const PosicaoTabuleiro(linha: 0, coluna: 0),
              foiRevelada: false,
            ),
          ],
          playerArea: [0, 1, 2, 3],
          localStatus: PlacementStatus.placing,
          opponentStatus: PlacementStatus.placing,
          gamePhase: GamePhase.piecePlacement,
        );

        container
            .read(placementStateProvider.notifier)
            .initializePlacement(gameState);

        // Act: Simulate disconnection
        testSocketService.simulateStatusChange(StatusConexao.desconectado);

        // Wait for disconnection handling
        await Future.delayed(const Duration(milliseconds: 50));

        // Simulate reconnection
        final reconnectionSuccess = await placementController
            .attemptManualReconnection();

        // Assert: Reconnection should succeed
        expect(reconnectionSuccess, isTrue);
      });
    });

    group('Performance and Edge Cases', () {
      test('should handle rapid validation operations', () async {
        // Arrange: Setup game state
        final gameState = PlacementGameState(
          gameId: 'test-game-rapid',
          playerId: 'player1',
          availablePieces: PlacementGameState.createInitialInventory(),
          placedPieces: [],
          playerArea: [0, 1, 2, 3],
          localStatus: PlacementStatus.placing,
          opponentStatus: PlacementStatus.placing,
          gamePhase: GamePhase.piecePlacement,
        );

        container
            .read(placementStateProvider.notifier)
            .initializePlacement(gameState);

        // Act: Perform rapid validations
        final results = <PlacementResult<void>>[];
        for (int i = 0; i < 5; i++) {
          final result = placementController.validatePiecePlacement(
            position: PosicaoTabuleiro(linha: 0, coluna: i),
            pieceType: Patente.soldado,
          );
          results.add(result);
        }

        // Assert: All validations should succeed
        for (final result in results) {
          expect(result.isSuccess, isTrue);
        }
      });

      test('should handle state management consistency', () async {
        // Arrange: Setup initial state
        final gameState = PlacementGameState(
          gameId: 'test-game-consistency',
          playerId: 'player1',
          availablePieces: PlacementGameState.createInitialInventory(),
          placedPieces: [],
          playerArea: [0, 1, 2, 3],
          localStatus: PlacementStatus.placing,
          opponentStatus: PlacementStatus.placing,
          gamePhase: GamePhase.piecePlacement,
        );

        // Act: Simulate rapid state updates
        for (int i = 0; i < 10; i++) {
          final updatedState = PlacementGameState(
            gameId: gameState.gameId,
            playerId: gameState.playerId,
            availablePieces: gameState.availablePieces,
            placedPieces: [
              PecaJogo(
                id: 'piece-$i',
                patente: Patente.soldado,
                equipe: Equipe.verde,
                posicao: PosicaoTabuleiro(linha: 0, coluna: i % 10),
                foiRevelada: false,
              ),
            ],
            playerArea: gameState.playerArea,
            localStatus: gameState.localStatus,
            opponentStatus: gameState.opponentStatus,
            gamePhase: gameState.gamePhase,
          );

          container
              .read(placementStateProvider.notifier)
              .initializePlacement(updatedState);
        }

        // Assert: Final state is consistent
        final finalState = container.read(placementStateProvider);
        expect(finalState.placementState?.placedPieces.length, equals(1));
      });

      test('should handle error recovery mechanisms', () async {
        // Arrange: Setup game state
        final gameState = PlacementGameState(
          gameId: 'test-game-error',
          playerId: 'player1',
          availablePieces: PlacementGameState.createInitialInventory(),
          placedPieces: [],
          playerArea: [0, 1, 2, 3],
          localStatus: PlacementStatus.placing,
          opponentStatus: PlacementStatus.placing,
          gamePhase: GamePhase.piecePlacement,
        );

        container
            .read(placementStateProvider.notifier)
            .initializePlacement(gameState);

        // Act: Simulate network error
        testSocketService.simulateError('Network connection lost');

        // Wait for error handling
        await Future.delayed(const Duration(milliseconds: 50));

        // Clear error
        container.read(placementStateProvider.notifier).clearError();

        // Assert: Error should be cleared
        final currentState = container.read(placementStateProvider);
        expect(currentState.error, isNull);
      });
    });
  });
}

/// Helper function to create a full set of pieces for testing
List<PecaJogo> _createFullPieceSet(Equipe equipe, List<int> rows) {
  final pieces = <PecaJogo>[];
  final inventory = PlacementGameState.createInitialInventory();

  int row = rows.first;
  int col = 0;
  int pieceId = 0;

  for (final entry in inventory.entries) {
    final patente = Patente.values.firstWhere((p) => p.name == entry.key);
    final count = entry.value;

    for (int i = 0; i < count; i++) {
      pieces.add(
        PecaJogo(
          id: 'piece-${equipe.name}-${pieceId++}',
          patente: patente,
          equipe: equipe,
          posicao: PosicaoTabuleiro(linha: row, coluna: col),
          foiRevelada: false,
        ),
      );

      col++;
      if (col >= 10) {
        col = 0;
        row++;
        if (!rows.contains(row)) {
          row = rows.first; // Wrap around if needed
        }
      }
    }
  }

  return pieces;
}
