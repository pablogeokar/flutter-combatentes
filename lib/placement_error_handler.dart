import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'modelos_jogo.dart';

/// Tipos de erro que podem ocorrer durante o posicionamento de peças.
enum PlacementErrorType {
  /// Posição inválida para posicionamento.
  invalidPosition,

  /// Peça não disponível no inventário.
  pieceNotAvailable,

  /// Posicionamento incompleto (nem todas as peças foram posicionadas).
  incompletePlacement,

  /// Erro de rede/comunicação.
  networkError,

  /// Erro de validação do servidor.
  serverValidationError,

  /// Timeout de operação.
  timeout,

  /// Estado de jogo inválido.
  invalidGameState,

  /// Jogador não autorizado para esta operação.
  unauthorized,

  /// Limite de tentativas excedido.
  rateLimitExceeded,

  /// Oponente desconectou permanentemente.
  opponentDisconnected,
}

/// Representa um erro específico de posicionamento com contexto detalhado.
class PlacementError {
  /// Tipo do erro.
  final PlacementErrorType type;

  /// Mensagem de erro amigável para o usuário.
  final String userMessage;

  /// Mensagem técnica para debugging.
  final String? technicalMessage;

  /// Contexto adicional do erro.
  final Map<String, dynamic>? context;

  /// Erro original que causou este erro.
  final Object? originalError;

  /// Se este erro permite retry automático.
  final bool canRetry;

  /// Número de tentativas já realizadas.
  final int attemptCount;

  const PlacementError({
    required this.type,
    required this.userMessage,
    this.technicalMessage,
    this.context,
    this.originalError,
    this.canRetry = false,
    this.attemptCount = 0,
  });

  /// Cria um erro de posição inválida.
  factory PlacementError.invalidPosition({
    required PosicaoTabuleiro position,
    required String reason,
  }) {
    return PlacementError(
      type: PlacementErrorType.invalidPosition,
      userMessage: 'Posição inválida: $reason',
      context: {
        'position': {'linha': position.linha, 'coluna': position.coluna},
        'reason': reason,
      },
    );
  }

  /// Cria um erro de peça não disponível.
  factory PlacementError.pieceNotAvailable({
    required Patente patente,
    required int availableCount,
  }) {
    return PlacementError(
      type: PlacementErrorType.pieceNotAvailable,
      userMessage: availableCount == 0
          ? 'Não há mais peças de ${patente.nome} disponíveis'
          : 'Peça ${patente.nome} não está disponível',
      context: {'patente': patente.name, 'availableCount': availableCount},
    );
  }

  /// Cria um erro de posicionamento incompleto.
  factory PlacementError.incompletePlacement({
    required int remainingPieces,
    required List<Patente> missingTypes,
  }) {
    return PlacementError(
      type: PlacementErrorType.incompletePlacement,
      userMessage:
          'Posicionamento incompleto: $remainingPieces peças restantes',
      context: {
        'remainingPieces': remainingPieces,
        'missingTypes': missingTypes.map((p) => p.name).toList(),
      },
    );
  }

  /// Cria um erro de rede.
  factory PlacementError.networkError({
    required String operation,
    Object? originalError,
    bool canRetry = true,
    int attemptCount = 0,
  }) {
    return PlacementError(
      type: PlacementErrorType.networkError,
      userMessage: 'Erro de conexão. Verifique sua internet e tente novamente.',
      technicalMessage: 'Network error during $operation',
      originalError: originalError,
      canRetry: canRetry,
      attemptCount: attemptCount,
      context: {
        'operation': operation,
        'canRetry': canRetry,
        'attemptCount': attemptCount,
      },
    );
  }

  /// Cria um erro de validação do servidor.
  factory PlacementError.serverValidation({
    required String message,
    Map<String, dynamic>? serverContext,
  }) {
    return PlacementError(
      type: PlacementErrorType.serverValidationError,
      userMessage: message,
      technicalMessage: 'Server validation failed',
      context: serverContext,
    );
  }

  /// Cria um erro de timeout.
  factory PlacementError.timeout({
    required String operation,
    required Duration timeout,
    bool canRetry = true,
  }) {
    return PlacementError(
      type: PlacementErrorType.timeout,
      userMessage: 'Operação demorou muito para responder. Tente novamente.',
      technicalMessage: 'Timeout after ${timeout.inSeconds}s during $operation',
      canRetry: canRetry,
      context: {'operation': operation, 'timeoutSeconds': timeout.inSeconds},
    );
  }

  /// Cria uma cópia do erro com tentativa incrementada.
  PlacementError withIncrementedAttempt() {
    return PlacementError(
      type: type,
      userMessage: userMessage,
      technicalMessage: technicalMessage,
      context: context,
      originalError: originalError,
      canRetry: canRetry,
      attemptCount: attemptCount + 1,
    );
  }

  @override
  String toString() {
    return 'PlacementError(type: $type, message: $userMessage, attempts: $attemptCount)';
  }
}

/// Resultado de uma operação de posicionamento.
class PlacementResult<T> {
  /// Se a operação foi bem-sucedida.
  final bool isSuccess;

  /// Dados da operação (se bem-sucedida).
  final T? data;

  /// Erro da operação (se falhou).
  final PlacementError? error;

  const PlacementResult._({required this.isSuccess, this.data, this.error});

  /// Cria um resultado de sucesso.
  factory PlacementResult.success(T data) {
    return PlacementResult._(isSuccess: true, data: data);
  }

  /// Cria um resultado de erro.
  factory PlacementResult.failure(PlacementError error) {
    return PlacementResult._(isSuccess: false, error: error);
  }

  /// Se a operação falhou.
  bool get isFailure => !isSuccess;
}

/// Configuração para retry automático.
class RetryConfig {
  /// Número máximo de tentativas.
  final int maxAttempts;

  /// Delay inicial entre tentativas.
  final Duration initialDelay;

  /// Multiplicador para backoff exponencial.
  final double backoffMultiplier;

  /// Delay máximo entre tentativas.
  final Duration maxDelay;

  /// Tipos de erro que permitem retry.
  final Set<PlacementErrorType> retryableErrors;

  const RetryConfig({
    this.maxAttempts = 3,
    this.initialDelay = const Duration(seconds: 1),
    this.backoffMultiplier = 2.0,
    this.maxDelay = const Duration(seconds: 10),
    this.retryableErrors = const {
      PlacementErrorType.networkError,
      PlacementErrorType.timeout,
    },
  });

  /// Calcula o delay para uma tentativa específica.
  Duration getDelayForAttempt(int attempt) {
    final delay = initialDelay * (backoffMultiplier * attempt);
    return delay > maxDelay ? maxDelay : delay;
  }

  /// Verifica se um erro pode ser retentado.
  bool canRetry(PlacementError error) {
    return error.attemptCount < maxAttempts &&
        retryableErrors.contains(error.type) &&
        error.canRetry;
  }
}

/// Manipulador principal de erros de posicionamento.
class PlacementErrorHandler {
  static const RetryConfig _defaultRetryConfig = RetryConfig();

  /// Manipula um erro de posicionamento com feedback visual apropriado.
  static void handlePlacementError(
    BuildContext context,
    PlacementError error, {
    VoidCallback? onRetry,
    RetryConfig retryConfig = _defaultRetryConfig,
  }) {
    // Log do erro para debugging
    debugPrint('PlacementError: ${error.toString()}');
    if (error.technicalMessage != null) {
      debugPrint('Technical details: ${error.technicalMessage}');
    }

    // Feedback háptico baseado na severidade
    _provideHapticFeedback(error.type);

    // Mostra feedback visual baseado no tipo de erro
    switch (error.type) {
      case PlacementErrorType.invalidPosition:
      case PlacementErrorType.pieceNotAvailable:
      case PlacementErrorType.incompletePlacement:
        _showSnackBarError(context, error);
        break;

      case PlacementErrorType.networkError:
      case PlacementErrorType.timeout:
        if (retryConfig.canRetry(error) && onRetry != null) {
          _showRetryDialog(context, error, onRetry, retryConfig);
        } else {
          _showErrorDialog(context, error);
        }
        break;

      case PlacementErrorType.opponentDisconnected:
        _showErrorDialog(context, error);
        break;

      case PlacementErrorType.serverValidationError:
      case PlacementErrorType.invalidGameState:
      case PlacementErrorType.unauthorized:
        _showErrorDialog(context, error);
        break;

      case PlacementErrorType.rateLimitExceeded:
        _showRateLimitDialog(context, error);
        break;
    }
  }

  /// Executa uma operação com retry automático.
  static Future<PlacementResult<T>> executeWithRetry<T>(
    Future<T> Function() operation, {
    RetryConfig retryConfig = _defaultRetryConfig,
    String operationName = 'operation',
  }) async {
    PlacementError? lastError;

    for (int attempt = 0; attempt < retryConfig.maxAttempts; attempt++) {
      try {
        final result = await operation();
        return PlacementResult.success(result);
      } catch (e) {
        // Converte exceção em PlacementError
        final error = _convertExceptionToError(e, operationName, attempt);
        lastError = error;

        // Verifica se pode tentar novamente
        if (!retryConfig.canRetry(error)) {
          break;
        }

        // Aguarda antes da próxima tentativa
        if (attempt < retryConfig.maxAttempts - 1) {
          final delay = retryConfig.getDelayForAttempt(attempt);
          await Future.delayed(delay);
        }
      }
    }

    return PlacementResult.failure(lastError!);
  }

  /// Valida uma operação de posicionamento antes da execução.
  static PlacementResult<void> validatePlacementOperation({
    required PosicaoTabuleiro position,
    required List<int> playerArea,
    required Patente? selectedPiece,
    required Map<Patente, int> availablePieces,
    required List<PecaJogo> placedPieces,
  }) {
    // Verifica se há peça selecionada
    if (selectedPiece == null) {
      return PlacementResult.failure(
        PlacementError(
          type: PlacementErrorType.invalidPosition,
          userMessage: 'Selecione uma peça primeiro',
        ),
      );
    }

    // Verifica se a posição está na área do jogador
    if (!playerArea.contains(position.linha)) {
      return PlacementResult.failure(
        PlacementError.invalidPosition(
          position: position,
          reason: 'Posição fora da sua área de posicionamento',
        ),
      );
    }

    // Verifica se há peças disponíveis
    final availableCount = availablePieces[selectedPiece] ?? 0;
    if (availableCount <= 0) {
      return PlacementResult.failure(
        PlacementError.pieceNotAvailable(
          patente: selectedPiece,
          availableCount: availableCount,
        ),
      );
    }

    // Verifica se a posição não é um lago
    if (_isLakePosition(position)) {
      return PlacementResult.failure(
        PlacementError.invalidPosition(
          position: position,
          reason: 'Não é possível posicionar peças em lagos',
        ),
      );
    }

    return PlacementResult.success(null);
  }

  /// Valida se o posicionamento está completo para confirmação.
  static PlacementResult<void> validatePlacementCompletion({
    required Map<Patente, int> availablePieces,
  }) {
    final remainingPieces = availablePieces.values.fold(
      0,
      (sum, count) => sum + count,
    );

    if (remainingPieces > 0) {
      final missingTypes = availablePieces.entries
          .where((entry) => entry.value > 0)
          .map((entry) => entry.key)
          .toList();

      return PlacementResult.failure(
        PlacementError.incompletePlacement(
          remainingPieces: remainingPieces,
          missingTypes: missingTypes,
        ),
      );
    }

    return PlacementResult.success(null);
  }

  /// Converte uma exceção genérica em PlacementError.
  static PlacementError _convertExceptionToError(
    Object exception,
    String operationName,
    int attemptCount,
  ) {
    if (exception is PlacementError) {
      return exception.withIncrementedAttempt();
    }

    // Detecta tipos específicos de erro
    final errorMessage = exception.toString().toLowerCase();

    if (errorMessage.contains('timeout') || errorMessage.contains('time out')) {
      return PlacementError.timeout(
        operation: operationName,
        timeout: const Duration(seconds: 30),
      );
    }

    if (errorMessage.contains('network') ||
        errorMessage.contains('connection') ||
        errorMessage.contains('socket')) {
      return PlacementError.networkError(
        operation: operationName,
        originalError: exception,
        attemptCount: attemptCount,
      );
    }

    // Erro genérico
    return PlacementError(
      type: PlacementErrorType.networkError,
      userMessage: 'Erro inesperado. Tente novamente.',
      technicalMessage: 'Unexpected error during $operationName',
      originalError: exception,
      canRetry: true,
      attemptCount: attemptCount,
    );
  }

  /// Fornece feedback háptico baseado no tipo de erro.
  static void _provideHapticFeedback(PlacementErrorType errorType) {
    switch (errorType) {
      case PlacementErrorType.invalidPosition:
      case PlacementErrorType.pieceNotAvailable:
        HapticFeedback.lightImpact();
        break;
      case PlacementErrorType.networkError:
      case PlacementErrorType.serverValidationError:
        HapticFeedback.mediumImpact();
        break;
      case PlacementErrorType.incompletePlacement:
      case PlacementErrorType.timeout:
      case PlacementErrorType.invalidGameState:
        HapticFeedback.heavyImpact();
        break;
      default:
        HapticFeedback.selectionClick();
    }
  }

  /// Mostra erro em SnackBar para erros menores.
  static void _showSnackBarError(BuildContext context, PlacementError error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(_getErrorIcon(error.type), color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(error.userMessage)),
          ],
        ),
        backgroundColor: _getErrorColor(error.type),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        action: error.canRetry
            ? SnackBarAction(
                label: 'Tentar Novamente',
                textColor: Colors.white,
                onPressed: () {
                  // Callback será implementado pelo componente que chama
                },
              )
            : null,
      ),
    );
  }

  /// Mostra diálogo de erro para erros mais sérios.
  static void _showErrorDialog(BuildContext context, PlacementError error) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(_getErrorIcon(error.type), color: _getErrorColor(error.type)),
            const SizedBox(width: 8),
            const Text('Erro'),
          ],
        ),
        content: Text(error.userMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Mostra diálogo com opção de retry.
  static void _showRetryDialog(
    BuildContext context,
    PlacementError error,
    VoidCallback onRetry,
    RetryConfig retryConfig,
  ) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(_getErrorIcon(error.type), color: _getErrorColor(error.type)),
            const SizedBox(width: 8),
            const Text('Erro de Conexão'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(error.userMessage),
            const SizedBox(height: 8),
            Text(
              'Tentativa ${error.attemptCount + 1} de ${retryConfig.maxAttempts}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              onRetry();
            },
            child: const Text('Tentar Novamente'),
          ),
        ],
      ),
    );
  }

  /// Mostra diálogo específico para rate limit.
  static void _showRateLimitDialog(BuildContext context, PlacementError error) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.speed, color: Colors.orange),
            SizedBox(width: 8),
            Text('Muitas Tentativas'),
          ],
        ),
        content: const Text(
          'Você está fazendo muitas operações muito rapidamente. '
          'Aguarde um momento antes de tentar novamente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Retorna o ícone apropriado para o tipo de erro.
  static IconData _getErrorIcon(PlacementErrorType errorType) {
    switch (errorType) {
      case PlacementErrorType.invalidPosition:
        return Icons.place_outlined;
      case PlacementErrorType.pieceNotAvailable:
        return Icons.inventory_2_outlined;
      case PlacementErrorType.incompletePlacement:
        return Icons.warning_outlined;
      case PlacementErrorType.networkError:
        return Icons.wifi_off_outlined;
      case PlacementErrorType.serverValidationError:
        return Icons.error_outline;
      case PlacementErrorType.timeout:
        return Icons.access_time_outlined;
      case PlacementErrorType.invalidGameState:
        return Icons.bug_report_outlined;
      case PlacementErrorType.unauthorized:
        return Icons.lock_outline;
      case PlacementErrorType.rateLimitExceeded:
        return Icons.speed;
      case PlacementErrorType.opponentDisconnected:
        return Icons.person_off_outlined;
    }
  }

  /// Retorna a cor apropriada para o tipo de erro.
  static Color _getErrorColor(PlacementErrorType errorType) {
    switch (errorType) {
      case PlacementErrorType.invalidPosition:
      case PlacementErrorType.pieceNotAvailable:
        return Colors.orange;
      case PlacementErrorType.incompletePlacement:
        return Colors.amber;
      case PlacementErrorType.networkError:
      case PlacementErrorType.timeout:
        return Colors.blue;
      case PlacementErrorType.serverValidationError:
      case PlacementErrorType.invalidGameState:
      case PlacementErrorType.unauthorized:
        return Colors.red;
      case PlacementErrorType.rateLimitExceeded:
        return Colors.deepOrange;
      case PlacementErrorType.opponentDisconnected:
        return Colors.orange;
    }
  }

  /// Verifica se uma posição é um lago.
  static bool _isLakePosition(PosicaoTabuleiro position) {
    const lakes = [
      PosicaoTabuleiro(linha: 4, coluna: 2),
      PosicaoTabuleiro(linha: 4, coluna: 3),
      PosicaoTabuleiro(linha: 5, coluna: 2),
      PosicaoTabuleiro(linha: 5, coluna: 3),
      PosicaoTabuleiro(linha: 4, coluna: 6),
      PosicaoTabuleiro(linha: 4, coluna: 7),
      PosicaoTabuleiro(linha: 5, coluna: 6),
      PosicaoTabuleiro(linha: 5, coluna: 7),
    ];

    return lakes.any(
      (lake) => lake.linha == position.linha && lake.coluna == position.coluna,
    );
  }
}
