import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'modelos_jogo.dart';
import 'placement_controller.dart';
import 'providers.dart';

/// Estado da tela de posicionamento de peças.
class PlacementScreenState {
  /// Estado atual do posicionamento.
  final PlacementGameState? placementState;

  /// Se está carregando.
  final bool isLoading;

  /// Mensagem de erro, se houver.
  final String? error;

  /// Se deve navegar para o jogo.
  final bool shouldNavigateToGame;

  const PlacementScreenState({
    this.placementState,
    this.isLoading = false,
    this.error,
    this.shouldNavigateToGame = false,
  });

  PlacementScreenState copyWith({
    PlacementGameState? placementState,
    bool? isLoading,
    String? error,
    bool? shouldNavigateToGame,
    bool clearError = false,
  }) {
    return PlacementScreenState(
      placementState: placementState ?? this.placementState,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
      shouldNavigateToGame: shouldNavigateToGame ?? this.shouldNavigateToGame,
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

  /// Manipula mudanças no controller de posicionamento.
  void _onControllerChanged() {
    final controllerState = _controller?.currentState;

    if (controllerState != null) {
      // Verifica se deve navegar para o jogo
      final shouldNavigate =
          controllerState.gamePhase == GamePhase.gameInProgress;

      state = state.copyWith(
        placementState: controllerState,
        shouldNavigateToGame: shouldNavigate,
      );
    }
  }

  /// Confirma o posicionamento do jogador.
  Future<void> confirmPlacement() async {
    if (_controller == null) return;

    try {
      state = state.copyWith(isLoading: true, clearError: true);
      await _controller!.confirmPlacement();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erro ao confirmar posicionamento: $e',
      );
    }
  }

  /// Limpa o erro atual.
  void clearError() {
    state = state.copyWith(clearError: true);
  }

  /// Reseta o estado para voltar ao jogo normal.
  void resetToGame() {
    state = state.copyWith(
      placementState: null,
      shouldNavigateToGame: false,
      clearError: true,
    );
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
