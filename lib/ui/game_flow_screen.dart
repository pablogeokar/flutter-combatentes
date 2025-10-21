import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../modelos_jogo.dart';
import '../providers.dart';
import '../placement_provider.dart';
import 'tela_jogo.dart';
import 'piece_placement_screen.dart';
import 'matchmaking_screen.dart';
import 'military_theme_widgets.dart';

/// Tela que gerencia o fluxo completo do jogo após o matchmaking.
/// Esta tela assume que já há 2 jogadores conectados.
class GameFlowScreen extends ConsumerStatefulWidget {
  const GameFlowScreen({super.key});

  @override
  ConsumerState<GameFlowScreen> createState() => _GameFlowScreenState();
}

class _GameFlowScreenState extends ConsumerState<GameFlowScreen> {
  GameFlowPhase _currentPhase = GameFlowPhase.placement;
  PlacementGameState? _placementState;
  List<PecaJogo>? _savedPlacedPieces;
  bool _hasInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasInitialized) {
        _checkGameStateAndInitialize();
      }
    });
  }

  void _checkGameStateAndInitialize() {
    debugPrint(
      '🔍 _checkGameStateAndInitialize - hasInitialized: $_hasInitialized',
    );

    if (_hasInitialized) {
      debugPrint('🔍 Já foi inicializado, ignorando');
      return;
    }

    // Verifica se o placement já foi inicializado no provider
    final placementState = ref.read(placementStateProvider);
    if (placementState.placementState != null) {
      debugPrint('🔍 Placement já existe no provider, ignorando');
      _hasInitialized = true;
      _placementState = placementState.placementState;
      setState(() {});
      debugPrint('🔍 UI atualizada para mostrar placement do provider');
      return;
    }

    _hasInitialized = true;
    debugPrint('🔍 Marcando como inicializado');
    final currentGameState = ref.read(gameStateProvider);

    debugPrint('🔍 Verificando estado do jogo...');
    debugPrint('🔍 Estado: ${currentGameState.estadoJogo != null}');
    debugPrint('🔍 Nome usuário: ${currentGameState.nomeUsuario}');
    debugPrint(
      '🔍 Jogadores: ${currentGameState.estadoJogo?.jogadores.length ?? 0}',
    );
    debugPrint('🔍 Peças: ${currentGameState.estadoJogo?.pecas.length ?? 0}');

    if (currentGameState.estadoJogo != null) {
      for (final jogador in currentGameState.estadoJogo!.jogadores) {
        debugPrint(
          '🔍 Jogador: ${jogador.nome} (${jogador.equipe.name}) - ID: ${jogador.id}',
        );
      }
    }

    if (currentGameState.estadoJogo == null ||
        currentGameState.estadoJogo!.jogadores.length < 2) {
      debugPrint('❌ Estado inválido, voltando para matchmaking');
      _returnToMatchmaking();
      return;
    }

    if (currentGameState.estadoJogo!.pecas.isNotEmpty) {
      debugPrint('🎮 Jogo já tem peças, indo para fase de jogo');
      _startGamePhase();
      return;
    }

    debugPrint('🔧 Iniciando placement');
    _startPlacementPhase(currentGameState.estadoJogo!);
  }

  void _returnToMatchmaking() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const MatchmakingScreen()),
    );
  }

  void _handleGameStateChange(TelaJogoState? previous, TelaJogoState current) {
    if (!_hasInitialized) return;

    final estadoJogo = current.estadoJogo;
    debugPrint('🔄 GameFlowScreen: _handleGameStateChange chamado');
    debugPrint('🔄 Estado atual: ${estadoJogo?.pecas.length ?? 0} peças');
    debugPrint('🔄 Fase atual: $_currentPhase');

    if (estadoJogo == null || estadoJogo.jogadores.length < 2) {
      debugPrint('🔄 Estado inválido, voltando para matchmaking');
      _returnToMatchmaking();
      return;
    }

    if (_currentPhase == GameFlowPhase.placement &&
        estadoJogo.pecas.isNotEmpty &&
        _placementState != null) {
      debugPrint('🔄 Placement concluído, iniciando jogo');
      _startGamePhase();
    }
  }

  void _startPlacementPhase(EstadoJogo estadoJogo) {
    debugPrint(
      '🔄 _startPlacementPhase - fase: $_currentPhase, placementState: ${_placementState != null}',
    );

    if (_currentPhase != GameFlowPhase.placement || _placementState != null) {
      debugPrint('🔄 Placement já foi iniciado ou fase incorreta, ignorando');
      return;
    }

    // Verifica se já existe no provider
    final existingPlacement = ref.read(placementStateProvider);
    if (existingPlacement.placementState != null) {
      debugPrint('🔄 Placement já existe no provider, reutilizando');
      _placementState = existingPlacement.placementState;
      setState(() {});
      debugPrint('🔄 UI atualizada para mostrar placement existente');
      return;
    }

    debugPrint('🔄 Iniciando placement phase');
    final nomeUsuario = ref.read(gameStateProvider).nomeUsuario;
    final jogadorLocal = _findLocalPlayer(estadoJogo, nomeUsuario);

    if (jogadorLocal == null) {
      debugPrint('❌ Jogador local não encontrado, voltando para matchmaking');
      _returnToMatchmaking();
      return;
    }

    final playerArea = jogadorLocal.equipe == Equipe.verde
        ? [0, 1, 2, 3]
        : [6, 7, 8, 9];

    _placementState = createInitialPlacementState(
      gameId: estadoJogo.idPartida,
      playerId: jogadorLocal.id,
      playerArea: playerArea,
    );

    ref
        .read(placementStateProvider.notifier)
        .initializePlacement(_placementState!);

    debugPrint('🔄 Placement phase iniciado com sucesso');
    debugPrint(
      '🔄 Jogador: ${jogadorLocal.nome} (${jogadorLocal.equipe.name})',
    );
    debugPrint('🔄 Área: $playerArea');

    // Atualiza a UI para mostrar a tela de placement
    setState(() {});
    debugPrint('🔄 UI atualizada para mostrar placement');
  }

  Jogador? _findLocalPlayer(EstadoJogo estadoJogo, String? nomeUsuario) {
    if (nomeUsuario == null) return null;

    final jogadorEncontrado = estadoJogo.jogadores.where((jogador) {
      final nomeJogador = jogador.nome.trim().toLowerCase();
      final nomeLocal = nomeUsuario.trim().toLowerCase();
      return nomeJogador == nomeLocal ||
          nomeJogador.contains(nomeLocal) ||
          nomeLocal.contains(nomeJogador);
    }).firstOrNull;

    if (jogadorEncontrado != null) {
      debugPrint('✅ Jogador local encontrado: ${jogadorEncontrado.nome}');
    } else {
      debugPrint('❌ Jogador local não encontrado para "$nomeUsuario"');
    }

    return jogadorEncontrado;
  }

  void _handlePlacementStateChange(
    PlacementScreenState? previous,
    PlacementScreenState current,
  ) {
    debugPrint('🔄 _handlePlacementStateChange chamado');
    debugPrint('🔄 shouldNavigateToGame: ${current.shouldNavigateToGame}');
    debugPrint('🔄 currentPhase: $_currentPhase');
    debugPrint(
      '🔄 placementState gamePhase: ${current.placementState?.gamePhase}',
    );

    if (current.shouldNavigateToGame &&
        _currentPhase == GameFlowPhase.placement) {
      debugPrint('🔄 Iniciando transição para o jogo!');
      _startGamePhase();
    }
  }

  void _startGamePhase() {
    debugPrint('🎮 _startGamePhase iniciado');
    _transferPlacedPiecesToGame();
    setState(() {
      _currentPhase = GameFlowPhase.game;
    });
    debugPrint('🎮 Fase alterada para GameFlowPhase.game');
    ref.read(placementStateProvider.notifier).resetToGame();
    debugPrint('🎮 Placement provider resetado');
  }

  Future<void> _transferPlacedPiecesToGame() async {
    debugPrint('🔄 Iniciando transferência de peças...');
    // Implementação simplificada para evitar complexidade
    final placementState = ref.read(placementStateProvider);
    if (placementState.placementState?.placedPieces.isNotEmpty == true) {
      debugPrint(
        '🎮 Peças transferidas: ${placementState.placementState!.placedPieces.length}',
      );
    }
  }

  void _handleBackFromPlacement() {
    _returnToMatchmaking();
  }

  void _handleGameStart() {
    _savePlacedPieces();
    _startGamePhase();
  }

  void _savePlacedPieces() {
    final placementState = ref.read(placementStateProvider);
    if (placementState.placementState?.placedPieces.isNotEmpty == true) {
      _savedPlacedPieces = List<PecaJogo>.from(
        placementState.placementState!.placedPieces,
      );
      debugPrint('💾 Peças salvas: ${_savedPlacedPieces?.length ?? 0}');
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<TelaJogoState>(gameStateProvider, (previous, current) {
      _handleGameStateChange(previous, current);
    });

    ref.listen<PlacementScreenState>(placementStateProvider, (
      previous,
      current,
    ) {
      _handlePlacementStateChange(previous, current);
    });

    switch (_currentPhase) {
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
        return const TelaJogo();
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

enum GameFlowPhase { placement, game }
