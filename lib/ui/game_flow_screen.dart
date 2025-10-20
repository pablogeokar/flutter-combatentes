import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../modelos_jogo.dart';
import '../providers.dart';
import '../placement_provider.dart';
import 'tela_jogo.dart';
import 'piece_placement_screen.dart';
import 'military_theme_widgets.dart';

/// Tela que gerencia o fluxo completo do jogo, incluindo matchmaking, placement e jogo.
class GameFlowScreen extends ConsumerStatefulWidget {
  const GameFlowScreen({super.key});

  @override
  ConsumerState<GameFlowScreen> createState() => _GameFlowScreenState();
}

class _GameFlowScreenState extends ConsumerState<GameFlowScreen> {
  GameFlowPhase _currentPhase = GameFlowPhase.matchmaking;
  PlacementGameState? _placementState;

  @override
  void initState() {
    super.initState();
    // Inicia observando o estado do jogo para detectar quando placement deve começar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startListeningToGameState();
    });
  }

  void _startListeningToGameState() {
    // Observa mudanças no estado do jogo para detectar transições de fase
    ref.listen<TelaJogoState>(gameStateProvider, (previous, current) {
      _handleGameStateChange(previous, current);
    });

    // Observa mudanças no estado de placement
    ref.listen<PlacementScreenState>(placementStateProvider, (
      previous,
      current,
    ) {
      _handlePlacementStateChange(previous, current);
    });
  }

  void _handleGameStateChange(TelaJogoState? previous, TelaJogoState current) {
    final estadoJogo = current.estadoJogo;

    // Se recebeu um estado de jogo válido e estamos em matchmaking
    if (estadoJogo != null && _currentPhase == GameFlowPhase.matchmaking) {
      // Verifica se deve iniciar placement
      if (_shouldStartPlacement(estadoJogo)) {
        _startPlacementPhase(estadoJogo);
      } else if (_shouldStartGame(estadoJogo)) {
        // Se o jogo já está em progresso, pula placement
        _startGamePhase();
      }
    }
  }

  void _handlePlacementStateChange(
    PlacementScreenState? previous,
    PlacementScreenState current,
  ) {
    // Se placement indica que deve navegar para o jogo
    if (current.shouldNavigateToGame &&
        _currentPhase == GameFlowPhase.placement) {
      _startGamePhase();
    }
  }

  bool _shouldStartPlacement(EstadoJogo estadoJogo) {
    // TODO: Implementar lógica para detectar quando placement deve iniciar
    // Por enquanto, sempre inicia placement quando recebe um estado de jogo
    // Na implementação real, o servidor enviaria uma indicação específica
    return true;
  }

  bool _shouldStartGame(EstadoJogo estadoJogo) {
    // Se o jogo já tem peças posicionadas, pula placement
    return estadoJogo.pecas.isNotEmpty;
  }

  void _startPlacementPhase(EstadoJogo estadoJogo) {
    // Determina a área do jogador baseado na equipe
    final nomeUsuario = ref.read(gameStateProvider).nomeUsuario;
    final jogadorLocal = _findLocalPlayer(estadoJogo, nomeUsuario);

    if (jogadorLocal == null) return;

    // Área do jogador baseada na equipe (Verde: linhas 0-3, Preta: linhas 6-9)
    final playerArea = jogadorLocal.equipe == Equipe.verde
        ? [0, 1, 2, 3]
        : [6, 7, 8, 9];

    // Cria estado inicial de placement
    _placementState = createInitialPlacementState(
      gameId: estadoJogo.idPartida,
      playerId: jogadorLocal.id,
      playerArea: playerArea,
    );

    // Inicializa o provider de placement
    ref
        .read(placementStateProvider.notifier)
        .initializePlacement(_placementState!);

    setState(() {
      _currentPhase = GameFlowPhase.placement;
    });
  }

  void _startGamePhase() {
    // Limpa o estado de placement
    ref.read(placementStateProvider.notifier).resetToGame();

    setState(() {
      _currentPhase = GameFlowPhase.game;
    });
  }

  Jogador? _findLocalPlayer(EstadoJogo estadoJogo, String? nomeUsuario) {
    if (nomeUsuario == null) return null;

    return estadoJogo.jogadores.where((jogador) {
      final nomeJogador = jogador.nome.trim().toLowerCase();
      final nomeLocal = nomeUsuario.trim().toLowerCase();
      return nomeJogador == nomeLocal ||
          nomeJogador.contains(nomeLocal) ||
          nomeLocal.contains(nomeJogador);
    }).firstOrNull;
  }

  void _handleBackFromPlacement() {
    // Volta para matchmaking
    setState(() {
      _currentPhase = GameFlowPhase.matchmaking;
    });
  }

  void _handleGameStart() {
    // Transição do placement para o jogo
    _startGamePhase();
  }

  @override
  Widget build(BuildContext context) {
    switch (_currentPhase) {
      case GameFlowPhase.matchmaking:
        return const TelaJogo(); // Tela de jogo atual que faz matchmaking

      case GameFlowPhase.placement:
        if (_placementState == null) {
          return _buildLoadingScreen();
        }
        return PiecePlacementScreen(
          initialState: _placementState!,
          onGameStart: _handleGameStart,
          onBack: _handleBackFromPlacement,
        );

      case GameFlowPhase.game:
        return const TelaJogo(); // Tela de jogo atual
    }
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      body: MilitaryThemeWidgets.militaryBackground(
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  MilitaryThemeWidgets.primaryGreen,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Preparando posicionamento...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Fases do fluxo do jogo.
enum GameFlowPhase {
  /// Aguardando matchmaking.
  matchmaking,

  /// Fase de posicionamento de peças.
  placement,

  /// Jogo em andamento.
  game,
}
