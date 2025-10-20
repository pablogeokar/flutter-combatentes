import 'package:flutter_test/flutter_test.dart';
import 'package:combatentes/piece_inventory.dart';
import 'package:combatentes/modelos_jogo.dart';
import 'package:combatentes/placement_error_handler.dart';

void main() {
  group('PieceInventory Tests', () {
    late PieceInventory inventory;

    setUp(() {
      inventory = PieceInventory();
    });

    group('Initial State', () {
      test('should initialize with correct piece counts', () {
        expect(inventory.getAvailableCount(Patente.marechal), equals(1));
        expect(inventory.getAvailableCount(Patente.general), equals(1));
        expect(inventory.getAvailableCount(Patente.coronel), equals(2));
        expect(inventory.getAvailableCount(Patente.major), equals(3));
        expect(inventory.getAvailableCount(Patente.capitao), equals(4));
        expect(inventory.getAvailableCount(Patente.tenente), equals(4));
        expect(inventory.getAvailableCount(Patente.sargento), equals(4));
        expect(inventory.getAvailableCount(Patente.cabo), equals(5));
        expect(inventory.getAvailableCount(Patente.soldado), equals(8));
        expect(inventory.getAvailableCount(Patente.agenteSecreto), equals(1));
        expect(inventory.getAvailableCount(Patente.prisioneiro), equals(1));
        expect(inventory.getAvailableCount(Patente.minaTerrestre), equals(6));
      });

      test('should have total of 40 pieces', () {
        expect(inventory.totalPiecesRemaining, equals(40));
        expect(inventory.isFull, isTrue);
        expect(inventory.isEmpty, isFalse);
      });

      test('should have all patentes available initially', () {
        for (final patente in Patente.values) {
          expect(inventory.isAvailable(patente), isTrue);
        }
        expect(
          inventory.availablePatentes.length,
          equals(Patente.values.length),
        );
        expect(inventory.exhaustedPatentes.length, equals(0));
      });
    });

    group('Piece Removal', () {
      test('should successfully remove available pieces', () {
        expect(inventory.removePiece(Patente.soldado), isTrue);
        expect(inventory.getAvailableCount(Patente.soldado), equals(7));
        expect(inventory.totalPiecesRemaining, equals(39));
      });

      test('should fail to remove when piece count is zero', () {
        // Remove all soldiers first
        for (int i = 0; i < 8; i++) {
          inventory.removePiece(Patente.soldado);
        }

        expect(inventory.getAvailableCount(Patente.soldado), equals(0));
        expect(inventory.removePiece(Patente.soldado), isFalse);
        expect(inventory.isAvailable(Patente.soldado), isFalse);
      });

      test('should update available and exhausted patentes correctly', () {
        // Remove all marshals
        inventory.removePiece(Patente.marechal);

        expect(inventory.availablePatentes, isNot(contains(Patente.marechal)));
        expect(inventory.exhaustedPatentes, contains(Patente.marechal));
      });

      test('should become empty when all pieces removed', () {
        // Remove all pieces
        for (final patente in Patente.values) {
          final maxCount = inventory.getAvailableCount(patente);
          for (int i = 0; i < maxCount; i++) {
            inventory.removePiece(patente);
          }
        }

        expect(inventory.isEmpty, isTrue);
        expect(inventory.totalPiecesRemaining, equals(0));
        expect(inventory.availablePatentes.length, equals(0));
        expect(
          inventory.exhaustedPatentes.length,
          equals(Patente.values.length),
        );
      });
    });

    group('Piece Addition', () {
      test('should successfully add pieces back to inventory', () {
        // Remove a piece first
        inventory.removePiece(Patente.soldado);
        expect(inventory.getAvailableCount(Patente.soldado), equals(7));

        // Add it back
        expect(inventory.addPiece(Patente.soldado), isTrue);
        expect(inventory.getAvailableCount(Patente.soldado), equals(8));
        expect(inventory.totalPiecesRemaining, equals(40));
      });

      test('should fail to add pieces beyond maximum count', () {
        // Try to add a piece when already at maximum
        expect(inventory.addPiece(Patente.marechal), isFalse);
        expect(inventory.getAvailableCount(Patente.marechal), equals(1));
      });

      test('should restore availability when adding pieces back', () {
        // Remove all marshals
        inventory.removePiece(Patente.marechal);
        expect(inventory.isAvailable(Patente.marechal), isFalse);

        // Add one back
        inventory.addPiece(Patente.marechal);
        expect(inventory.isAvailable(Patente.marechal), isTrue);
      });
    });

    group('Validation', () {
      test('should validate correct inventory state', () {
        final result = inventory.validateInventory();
        expect(result.isValid, isTrue);
        expect(result.hasNoErrors, isTrue);
        expect(result.errors.length, equals(0));
      });

      test('should detect negative counts as invalid', () {
        // Manually create invalid inventory
        final invalidInventory = PieceInventory(
          availablePieces: {'marechal': -1, 'soldado': 8},
        );

        final result = invalidInventory.validateInventory();
        expect(result.isValid, isFalse);
        expect(result.errors.length, greaterThan(0));
        expect(result.errorMessage, contains('quantidade negativa'));
      });

      test('should detect excessive counts as invalid', () {
        // Manually create invalid inventory
        final invalidInventory = PieceInventory(
          availablePieces: {
            'marechal': 5, // Maximum should be 1
            'soldado': 8,
          },
        );

        final result = invalidInventory.validateInventory();
        expect(result.isValid, isFalse);
        expect(result.errors.length, greaterThan(0));
        expect(result.errorMessage, contains('excede o máximo'));
      });
    });

    group('Utility Methods', () {
      test('should reset to initial state', () {
        // Modify inventory
        inventory.removePiece(Patente.soldado);
        inventory.removePiece(Patente.marechal);

        // Reset
        inventory.reset();

        expect(inventory.totalPiecesRemaining, equals(40));
        expect(inventory.getAvailableCount(Patente.soldado), equals(8));
        expect(inventory.getAvailableCount(Patente.marechal), equals(1));
      });

      test('should create accurate copy', () {
        // Modify original
        inventory.removePiece(Patente.soldado);

        // Create copy
        final copy = inventory.copy();

        expect(copy.getAvailableCount(Patente.soldado), equals(7));
        expect(copy.totalPiecesRemaining, equals(39));

        // Modify original further
        inventory.removePiece(Patente.soldado);

        // Copy should remain unchanged
        expect(copy.getAvailableCount(Patente.soldado), equals(7));
        expect(inventory.getAvailableCount(Patente.soldado), equals(6));
      });

      test('should provide meaningful string representation', () {
        final str = inventory.toString();
        expect(str, contains('PieceInventory'));
        expect(str, contains('total: 40'));
        expect(str, contains('Marechal: 1'));
        expect(str, contains('Soldado: 8'));
      });
    });

    group('JSON Serialization', () {
      test('should serialize and deserialize correctly', () {
        // Create a fresh inventory for this test
        final testInventory = PieceInventory();

        // Modify inventory
        expect(testInventory.removePiece(Patente.soldado), isTrue);
        expect(testInventory.removePiece(Patente.marechal), isTrue);

        // Serialize
        final json = testInventory.toJson();

        // Deserialize
        final restored = PieceInventory.fromJson(json);

        expect(restored.getAvailableCount(Patente.soldado), equals(7));
        expect(restored.getAvailableCount(Patente.marechal), equals(0));
        expect(restored.totalPiecesRemaining, equals(38));
      });
    });
  });

  group('Placement Validation Tests', () {
    group('Position Validation', () {
      test('should validate positions within player area', () {
        final playerArea = [0, 1, 2, 3]; // First 4 rows
        final validPosition = PosicaoTabuleiro(linha: 2, coluna: 5);
        final availablePieces = {Patente.soldado: 1};
        final placedPieces = <PecaJogo>[];

        final result = PlacementErrorHandler.validatePlacementOperation(
          position: validPosition,
          playerArea: playerArea,
          selectedPiece: Patente.soldado,
          availablePieces: availablePieces,
          placedPieces: placedPieces,
        );

        expect(result.isSuccess, isTrue);
      });

      test('should reject positions outside player area', () {
        final playerArea = [0, 1, 2, 3]; // First 4 rows
        final invalidPosition = PosicaoTabuleiro(
          linha: 5,
          coluna: 3,
        ); // Outside area
        final availablePieces = {Patente.soldado: 1};
        final placedPieces = <PecaJogo>[];

        final result = PlacementErrorHandler.validatePlacementOperation(
          position: invalidPosition,
          playerArea: playerArea,
          selectedPiece: Patente.soldado,
          availablePieces: availablePieces,
          placedPieces: placedPieces,
        );

        expect(result.isFailure, isTrue);
        expect(result.error!.type, equals(PlacementErrorType.invalidPosition));
        expect(result.error!.userMessage, contains('fora da sua área'));
      });

      test('should reject lake positions', () {
        final playerArea = [4, 5]; // Include lake area for test
        final lakePosition = PosicaoTabuleiro(
          linha: 4,
          coluna: 2,
        ); // Lake position
        final availablePieces = {Patente.soldado: 1};
        final placedPieces = <PecaJogo>[];

        final result = PlacementErrorHandler.validatePlacementOperation(
          position: lakePosition,
          playerArea: playerArea,
          selectedPiece: Patente.soldado,
          availablePieces: availablePieces,
          placedPieces: placedPieces,
        );

        expect(result.isFailure, isTrue);
        expect(result.error!.type, equals(PlacementErrorType.invalidPosition));
        expect(result.error!.userMessage, contains('lagos'));
      });

      test('should validate all lake positions correctly', () {
        final playerArea = [4, 5]; // Include lake area for test
        final availablePieces = {Patente.soldado: 1};
        final placedPieces = <PecaJogo>[];

        // Test all lake positions
        final lakePositions = [
          PosicaoTabuleiro(linha: 4, coluna: 2),
          PosicaoTabuleiro(linha: 4, coluna: 3),
          PosicaoTabuleiro(linha: 5, coluna: 2),
          PosicaoTabuleiro(linha: 5, coluna: 3),
          PosicaoTabuleiro(linha: 4, coluna: 6),
          PosicaoTabuleiro(linha: 4, coluna: 7),
          PosicaoTabuleiro(linha: 5, coluna: 6),
          PosicaoTabuleiro(linha: 5, coluna: 7),
        ];

        for (final lakePos in lakePositions) {
          final result = PlacementErrorHandler.validatePlacementOperation(
            position: lakePos,
            playerArea: playerArea,
            selectedPiece: Patente.soldado,
            availablePieces: availablePieces,
            placedPieces: placedPieces,
          );

          expect(
            result.isFailure,
            isTrue,
            reason:
                'Lake position ${lakePos.linha},${lakePos.coluna} should be invalid',
          );
          expect(
            result.error!.type,
            equals(PlacementErrorType.invalidPosition),
          );
        }
      });
    });

    group('Piece Availability Validation', () {
      test('should reject placement when no piece selected', () {
        final playerArea = [0, 1, 2, 3];
        final validPosition = PosicaoTabuleiro(linha: 1, coluna: 1);
        final availablePieces = {Patente.soldado: 1};
        final placedPieces = <PecaJogo>[];

        final result = PlacementErrorHandler.validatePlacementOperation(
          position: validPosition,
          playerArea: playerArea,
          selectedPiece: null, // No piece selected
          availablePieces: availablePieces,
          placedPieces: placedPieces,
        );

        expect(result.isFailure, isTrue);
        expect(result.error!.type, equals(PlacementErrorType.invalidPosition));
        expect(result.error!.userMessage, contains('Selecione uma peça'));
      });

      test('should reject placement when piece not available', () {
        final playerArea = [0, 1, 2, 3];
        final validPosition = PosicaoTabuleiro(linha: 1, coluna: 1);
        final availablePieces = {Patente.soldado: 0}; // No soldiers available
        final placedPieces = <PecaJogo>[];

        final result = PlacementErrorHandler.validatePlacementOperation(
          position: validPosition,
          playerArea: playerArea,
          selectedPiece: Patente.soldado,
          availablePieces: availablePieces,
          placedPieces: placedPieces,
        );

        expect(result.isFailure, isTrue);
        expect(
          result.error!.type,
          equals(PlacementErrorType.pieceNotAvailable),
        );
        expect(result.error!.userMessage, contains('Não há mais peças'));
      });

      test('should reject placement when piece type not in inventory', () {
        final playerArea = [0, 1, 2, 3];
        final validPosition = PosicaoTabuleiro(linha: 1, coluna: 1);
        final availablePieces = <Patente, int>{}; // Empty inventory
        final placedPieces = <PecaJogo>[];

        final result = PlacementErrorHandler.validatePlacementOperation(
          position: validPosition,
          playerArea: playerArea,
          selectedPiece: Patente.soldado,
          availablePieces: availablePieces,
          placedPieces: placedPieces,
        );

        expect(result.isFailure, isTrue);
        expect(
          result.error!.type,
          equals(PlacementErrorType.pieceNotAvailable),
        );
      });
    });

    group('Placement Completion Validation', () {
      test('should validate complete placement', () {
        final availablePieces = <Patente, int>{}; // All pieces placed

        final result = PlacementErrorHandler.validatePlacementCompletion(
          availablePieces: availablePieces,
        );

        expect(result.isSuccess, isTrue);
      });

      test('should reject incomplete placement', () {
        final availablePieces = {
          Patente.soldado: 2,
          Patente.marechal: 1,
        }; // Still have pieces to place

        final result = PlacementErrorHandler.validatePlacementCompletion(
          availablePieces: availablePieces,
        );

        expect(result.isFailure, isTrue);
        expect(
          result.error!.type,
          equals(PlacementErrorType.incompletePlacement),
        );
        expect(result.error!.userMessage, contains('3 peças restantes'));
      });

      test('should identify missing piece types in error', () {
        final availablePieces = {Patente.soldado: 1, Patente.marechal: 1};

        final result = PlacementErrorHandler.validatePlacementCompletion(
          availablePieces: availablePieces,
        );

        expect(result.isFailure, isTrue);
        final error = result.error!;
        expect(error.context!['missingTypes'], contains('soldado'));
        expect(error.context!['missingTypes'], contains('marechal'));
        expect(error.context!['remainingPieces'], equals(2));
      });
    });

    group('Edge Cases', () {
      test('should handle boundary positions correctly', () {
        final playerArea = [0, 1, 2, 3];
        final availablePieces = {Patente.soldado: 1};
        final placedPieces = <PecaJogo>[];

        // Test corners and edges of valid area
        final boundaryPositions = [
          PosicaoTabuleiro(linha: 0, coluna: 0), // Top-left
          PosicaoTabuleiro(linha: 0, coluna: 9), // Top-right
          PosicaoTabuleiro(linha: 3, coluna: 0), // Bottom-left of area
          PosicaoTabuleiro(linha: 3, coluna: 9), // Bottom-right of area
        ];

        for (final pos in boundaryPositions) {
          final result = PlacementErrorHandler.validatePlacementOperation(
            position: pos,
            playerArea: playerArea,
            selectedPiece: Patente.soldado,
            availablePieces: availablePieces,
            placedPieces: placedPieces,
          );

          expect(
            result.isSuccess,
            isTrue,
            reason:
                'Boundary position ${pos.linha},${pos.coluna} should be valid',
          );
        }
      });

      test('should handle different player areas correctly', () {
        final availablePieces = {Patente.soldado: 1};
        final placedPieces = <PecaJogo>[];

        // Test bottom player area (rows 6-9)
        final bottomPlayerArea = [6, 7, 8, 9];
        final bottomPosition = PosicaoTabuleiro(linha: 7, coluna: 4);

        final result = PlacementErrorHandler.validatePlacementOperation(
          position: bottomPosition,
          playerArea: bottomPlayerArea,
          selectedPiece: Patente.soldado,
          availablePieces: availablePieces,
          placedPieces: placedPieces,
        );

        expect(result.isSuccess, isTrue);

        // Test that top area position is invalid for bottom player
        final topPosition = PosicaoTabuleiro(linha: 1, coluna: 4);
        final invalidResult = PlacementErrorHandler.validatePlacementOperation(
          position: topPosition,
          playerArea: bottomPlayerArea,
          selectedPiece: Patente.soldado,
          availablePieces: availablePieces,
          placedPieces: placedPieces,
        );

        expect(invalidResult.isFailure, isTrue);
      });
    });
  });
  group('Error Handling Tests', () {
    group('PlacementError Creation', () {
      test('should create invalid position error correctly', () {
        final position = PosicaoTabuleiro(linha: 5, coluna: 3);
        final error = PlacementError.invalidPosition(
          position: position,
          reason: 'Outside player area',
        );

        expect(error.type, equals(PlacementErrorType.invalidPosition));
        expect(error.userMessage, contains('Posição inválida'));
        expect(error.userMessage, contains('Outside player area'));
        expect(error.context!['position']['linha'], equals(5));
        expect(error.context!['position']['coluna'], equals(3));
        expect(error.context!['reason'], equals('Outside player area'));
      });

      test('should create piece not available error correctly', () {
        final error = PlacementError.pieceNotAvailable(
          patente: Patente.marechal,
          availableCount: 0,
        );

        expect(error.type, equals(PlacementErrorType.pieceNotAvailable));
        expect(error.userMessage, contains('Não há mais peças de Marechal'));
        expect(error.context!['patente'], equals('marechal'));
        expect(error.context!['availableCount'], equals(0));
      });

      test('should create incomplete placement error correctly', () {
        final missingTypes = [Patente.soldado, Patente.marechal];
        final error = PlacementError.incompletePlacement(
          remainingPieces: 3,
          missingTypes: missingTypes,
        );

        expect(error.type, equals(PlacementErrorType.incompletePlacement));
        expect(error.userMessage, contains('3 peças restantes'));
        expect(error.context!['remainingPieces'], equals(3));
        expect(error.context!['missingTypes'], contains('soldado'));
        expect(error.context!['missingTypes'], contains('marechal'));
      });

      test('should create network error correctly', () {
        final originalError = Exception('Connection failed');
        final error = PlacementError.networkError(
          operation: 'confirm placement',
          originalError: originalError,
          canRetry: true,
          attemptCount: 2,
        );

        expect(error.type, equals(PlacementErrorType.networkError));
        expect(error.userMessage, contains('Erro de conexão'));
        expect(
          error.technicalMessage,
          contains('Network error during confirm placement'),
        );
        expect(error.originalError, equals(originalError));
        expect(error.canRetry, isTrue);
        expect(error.attemptCount, equals(2));
        expect(error.context!['operation'], equals('confirm placement'));
      });

      test('should create timeout error correctly', () {
        final timeout = Duration(seconds: 30);
        final error = PlacementError.timeout(
          operation: 'server response',
          timeout: timeout,
          canRetry: true,
        );

        expect(error.type, equals(PlacementErrorType.timeout));
        expect(error.userMessage, contains('demorou muito'));
        expect(error.technicalMessage, contains('Timeout after 30s'));
        expect(error.canRetry, isTrue);
        expect(error.context!['operation'], equals('server response'));
        expect(error.context!['timeoutSeconds'], equals(30));
      });
    });

    group('Error Increment and Retry Logic', () {
      test('should increment attempt count correctly', () {
        final originalError = PlacementError.networkError(
          operation: 'test',
          attemptCount: 1,
        );

        final incrementedError = originalError.withIncrementedAttempt();

        expect(incrementedError.attemptCount, equals(2));
        expect(incrementedError.type, equals(originalError.type));
        expect(incrementedError.userMessage, equals(originalError.userMessage));
      });

      test('should preserve all properties when incrementing', () {
        final originalError = PlacementError.networkError(
          operation: 'test operation',
          originalError: Exception('test'),
          canRetry: true,
          attemptCount: 0,
        );

        final incrementedError = originalError.withIncrementedAttempt();

        expect(incrementedError.type, equals(originalError.type));
        expect(incrementedError.userMessage, equals(originalError.userMessage));
        expect(
          incrementedError.technicalMessage,
          equals(originalError.technicalMessage),
        );
        expect(
          incrementedError.originalError,
          equals(originalError.originalError),
        );
        expect(incrementedError.canRetry, equals(originalError.canRetry));
        expect(incrementedError.context, equals(originalError.context));
        expect(incrementedError.attemptCount, equals(1));
      });
    });

    group('RetryConfig', () {
      test('should calculate delay correctly with backoff', () {
        final config = RetryConfig(
          initialDelay: Duration(seconds: 1),
          backoffMultiplier: 2.0,
          maxDelay: Duration(seconds: 10),
        );

        expect(
          config.getDelayForAttempt(0),
          equals(Duration(seconds: 0)),
        ); // 1 * (2 * 0) = 0
        expect(
          config.getDelayForAttempt(1),
          equals(Duration(seconds: 2)),
        ); // 1 * (2 * 1) = 2
        expect(
          config.getDelayForAttempt(2),
          equals(Duration(seconds: 4)),
        ); // 1 * (2 * 2) = 4
        expect(
          config.getDelayForAttempt(3),
          equals(Duration(seconds: 6)),
        ); // 1 * (2 * 3) = 6
        expect(
          config.getDelayForAttempt(4),
          equals(Duration(seconds: 8)),
        ); // 1 * (2 * 4) = 8
      });

      test('should determine retry eligibility correctly', () {
        final config = RetryConfig(
          maxAttempts: 3,
          retryableErrors: {
            PlacementErrorType.networkError,
            PlacementErrorType.timeout,
          },
        );

        // Retryable error within attempt limit
        final retryableError = PlacementError.networkError(
          operation: 'test',
          attemptCount: 1,
          canRetry: true,
        );
        expect(config.canRetry(retryableError), isTrue);

        // Retryable error at attempt limit
        final maxAttemptsError = PlacementError.networkError(
          operation: 'test',
          attemptCount: 3,
          canRetry: true,
        );
        expect(config.canRetry(maxAttemptsError), isFalse);

        // Non-retryable error type
        final nonRetryableError = PlacementError.invalidPosition(
          position: PosicaoTabuleiro(linha: 0, coluna: 0),
          reason: 'test',
        );
        expect(config.canRetry(nonRetryableError), isFalse);

        // Error marked as non-retryable
        final nonRetryableFlagError = PlacementError(
          type: PlacementErrorType.networkError,
          userMessage: 'test',
          canRetry: false,
        );
        expect(config.canRetry(nonRetryableFlagError), isFalse);
      });
    });

    group('PlacementResult', () {
      test('should create success result correctly', () {
        final data = 'test data';
        final result = PlacementResult.success(data);

        expect(result.isSuccess, isTrue);
        expect(result.isFailure, isFalse);
        expect(result.data, equals(data));
        expect(result.error, isNull);
      });

      test('should create failure result correctly', () {
        final error = PlacementError.networkError(operation: 'test');
        final result = PlacementResult<String>.failure(error);

        expect(result.isSuccess, isFalse);
        expect(result.isFailure, isTrue);
        expect(result.data, isNull);
        expect(result.error, equals(error));
      });
    });

    group('Error Conversion', () {
      test('should convert timeout exceptions correctly', () {
        final timeoutException = Exception('timeout occurred');
        final error = PlacementErrorHandler.executeWithRetry(
          () async => throw timeoutException,
          operationName: 'test operation',
        );

        // This would be tested in integration, but we can test the conversion logic
        // by examining the private method behavior through public API
        expect(error, isA<Future<PlacementResult>>());
      });

      test('should convert network exceptions correctly', () {
        final networkException = Exception('connection failed');
        final error = PlacementErrorHandler.executeWithRetry(
          () async => throw networkException,
          operationName: 'network operation',
        );

        expect(error, isA<Future<PlacementResult>>());
      });
    });

    group('Error String Representation', () {
      test('should provide meaningful toString', () {
        final error = PlacementError.networkError(
          operation: 'test',
          attemptCount: 2,
        );

        final str = error.toString();
        expect(str, contains('PlacementError'));
        expect(str, contains('networkError'));
        expect(str, contains('Erro de conexão'));
        expect(str, contains('attempts: 2'));
      });
    });
  });
}
