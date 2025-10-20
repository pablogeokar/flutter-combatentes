import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'modelos_jogo.dart';
import 'placement_controller.dart';
import 'placement_error_handler.dart';
import 'providers.dart';
import 'services/placement_persistence.dart';

/// Estado da tela de posicionamento de peças.
class PlacementScreenState {
  /// Estado atual do posicionamento.
  final PlacementGameState? placementState;

  /// Se está carregando.
  final bool isLoading;

  /// Erro de posicionamento, se houver.
  final PlacementError? error;

  /// Se deve navegar para o jogo.
  final bool shouldNavigateToGame;

  /// Se está executando retry de operação.
  final bool isRetrying;

  const PlacementScreenState({
    this.placementState,
    this.isLoading = false,
    this.error,
    this.shouldNavigateToGame = false,
    this.isRetrying = false,
  });

  PlacementScreenState copyWith({
    PlacementGameState? placementState,
    bool? isLoading,
    PlacementError? error,
    bool? shouldNavigateToGame,
    bool? isRetrying,
    bool clearError = false,
    bool clearPlacementState = false,
  }) {
    return PlacementScreenState(
      placementState: clearPlacementState
          ? null
          : (placementState ?? this.placementState),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
      shouldNavigateToGame: shouldNavigateToGame ?? this.shouldNavigateToGame,
      isRetrying: isRetrying ?? this.isRetrying,
    );
  }
}

/// Provider para o controller de posicionamento.
final placementControllerProvider = Provider<PlacementController>((ref) {
  final socketService = ref.read(gameSocketProvider);
  final controller = PlacementController(socketService);
  ref.onDispose(() => controller.dispose());
  return controller;
});

/// Provider para o estado da tela de posicionamento.
final placementStateProvider =
    StateNotifierProvider<PlacementStateNotifier, PlacementScreenState>((ref) {
      return PlacementStateNotifier(ref);
    });

/// Notifier para gerenciar o estado da tela de posicionamento.
class PlacementStateNotifier extends StateNotifier<PlacementScreenState> {
  final Ref _ref;
  PlacementController? _controller;

  PlacementStateNotifier(this._ref) : super(const PlacementScreenState());

  /// Inicializa o posicionamento com um estado inicial.
  void initializePlacement(PlacementGameState initialState) {
    _controller = _ref.read(placementControllerProvider);

    // Configura listener para mudanças no controller
    _controller!.addListener(_onControllerChanged);

    // Define o estado inicial
    _controller!.updateState(initialState);

    state = state.copyWith(
      placementState: initialState,
      isLoading: false,
      clearError: true,
    );
  }

  /// Inicializa o posicionamento tentando restaurar estado salvo.
  Future<void> initializePlacementWithRestore(
    PlacementGameState fallbackState,
  ) async {
    _controller = _ref.read(placementControllerProvider);

    // Configura listener para mudanças no controller
    _controller!.addListener(_onControllerChanged);

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      // Tenta restaurar estado salvo
      final restoredState = await _controller!.restoreSavedState();

      if (restoredState != null) {
        // Estado restaurado com sucesso
        state = state.copyWith(
          placementState: restoredState,
          isLoading: false,
          clearError: true,
        );
      } else {
        // Usa estado fallback
        _controller!.updateState(fallbackState);
        state = state.copyWith(
          placementState: fallbackState,
          isLoading: false,
          clearError: true,
        );
      }
    } catch (e) {
      // Em caso de erro, usa estado fallback
      _controller!.updateState(fallbackState);
      state = state.copyWith(
        placementState: fallbackState,
        isLoading: false,
        error: PlacementError(
          type: PlacementErrorType.invalidGameState,
          userMessage: 'Erro ao restaurar posicionamento anterior',
        ),
      );
    }
  }

  /// Manipula mudanças no controller de posicionamento.
  void _onControllerChanged() {
    final controllerState = _controller?.currentState;
    final controllerError = _controller?.lastError;
    final isRetrying = _controller?.isRetrying ?? false;

    if (controllerState != null) {
      // Verifica se deve navegar para o jogo
      final shouldNavigate =
          controllerState.gamePhase == GamePhase.gameInProgress;

      state = state.copyWith(
        placementState: controllerState,
        shouldNavigateToGame: shouldNavigate,
        error: controllerError,
        isRetrying: isRetrying,
        clearError: controllerError == null,
      );
    } else if (controllerError != null) {
      // Atualiza apenas o erro se não há estado
      state = state.copyWith(error: controllerError, isRetrying: isRetrying);
    }
  }

  /// Confirma o posicionamento do jogador.
  Future<void> confirmPlacement() async {
    if (_controller == null) return;

    state = state.copyWith(isLoading: true, clearError: true);

    final result = await _controller!.confirmPlacement();

    state = state.copyWith(
      isLoading: false,
      error: result.isFailure ? result.error : null,
      clearError: result.isSuccess,
    );
  }

  /// Valida uma operação de posicionamento.
  PlacementResult<void> validatePiecePlacement({
    required PosicaoTabuleiro position,
    required Patente pieceType,
  }) {
    if (_controller == null) {
      return PlacementResult.failure(
        PlacementError(
          type: PlacementErrorType.invalidGameState,
          userMessage: 'Controller não inicializado',
        ),
      );
    }

    return _controller!.validatePiecePlacement(
      position: position,
      pieceType: pieceType,
    );
  }

  /// Executa retry de uma operação falhada.
  Future<void> retryLastOperation() async {
    if (_controller == null) return;

    // Por enquanto, apenas tenta confirmar novamente
    // Em implementações futuras, pode armazenar a última operação
    await confirmPlacement();
  }

  /// Limpa o erro atual.
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Manipula um erro de posicionamento com feedback visual.
  void handlePlacementError(PlacementError error) {
    state = state.copyWith(error: error);
  }

  /// Reseta o estado para voltar ao jogo normal.
  void resetToGame() {
    state = state.copyWith(
      clearPlacementState: true,
      shouldNavigateToGame: false,
      clearError: true,
    );
  }

  /// Verifica se há estado salvo válido.
  Future<bool> hasValidSavedState() async {
    return await PlacementPersistence.hasValidPlacementState();
  }

  /// Limpa estado persistido.
  Future<void> clearPersistedState() async {
    await PlacementPersistence.clearPlacementState();
    if (_controller != null) {
      await _controller!.clearPersistedState();
    }
  }

  /// Força salvamento do estado atual.
  Future<void> saveCurrentState() async {
    if (state.placementState != null) {
      await PlacementPersistence.savePlacementState(state.placementState!);
    }
  }

  /// Manipula erro de desconexão com opções de recuperação.
  void handleDisconnectionError(PlacementError error) {
    state = state.copyWith(error: error);

    // Se é desconexão do oponente, oferece opção de retornar ao matchmaking
    if (error.type == PlacementErrorType.opponentDisconnected) {
      // Limpa estado persistido já que o jogo foi abandonado
      clearPersistedState();
    }
  }

  /// Tenta reconectar manualmente.
  Future<bool> attemptManualReconnection() async {
    if (_controller == null) return false;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final success = await _controller!.attemptManualReconnection();

      state = state.copyWith(isLoading: false, clearError: success);

      return success;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: PlacementError(
          type: PlacementErrorType.networkError,
          userMessage: 'Erro na reconexão: ${e.toString()}',
        ),
      );

      return false;
    }
  }

  /// Retorna ao matchmaking (abandona posicionamento atual).
  Future<void> returnToMatchmaking() async {
    // Limpa estado persistido
    await clearPersistedState();

    // Reset do controller
    _controller?.reset();

    // Reset do estado
    state = const PlacementScreenState();
  }

  @override
  void dispose() {
    _controller?.removeListener(_onControllerChanged);
    super.dispose();
  }
}

/// Cria um estado inicial de posicionamento para testes.
PlacementGameState createInitialPlacementState({
  required String gameId,
  required String playerId,
  required List<int> playerArea,
}) {
  return PlacementGameState(
    gameId: gameId,
    playerId: playerId,
    availablePieces: PlacementGameState.createInitialInventory(),
    placedPieces: [],
    playerArea: playerArea,
    localStatus: PlacementStatus.placing,
    opponentStatus: PlacementStatus.placing,
    gamePhase: GamePhase.piecePlacement,
  );
}
