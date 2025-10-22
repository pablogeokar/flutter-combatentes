import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../modelos_jogo.dart';
import '../providers.dart';
import '../placement_provider.dart';
import '../services/user_preferences.dart';
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

      // Detecta desconexões do oponente
      if (current.statusConexao == StatusConexao.oponenteDesconectado &&
          previous?.statusConexao != StatusConexao.oponenteDesconectado) {
        debugPrint(
          '🚨 GameFlowScreen: Oponente desconectou, voltando para matchmaking',
        );
        _showOpponentDisconnectedAndReturn(context);
      }

      // Detecta perda de conexão com servidor
      if ((current.statusConexao == StatusConexao.desconectado ||
              current.statusConexao == StatusConexao.erro) &&
          previous?.statusConexao == StatusConexao.jogando) {
        debugPrint(
          '🚨 GameFlowScreen: Conexão perdida, voltando para matchmaking',
        );
        _showConnectionLostAndReturn(context);
      }
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
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  MilitaryThemeWidgets.primaryGreen,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Preparando posicionamento...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),
              // Informação sobre timeout durante posicionamento
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.symmetric(horizontal: 32),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: MilitaryThemeWidgets.primaryGreen.withValues(
                      alpha: 0.3,
                    ),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: MilitaryThemeWidgets.primaryGreen,
                      size: 20,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tempo para Posicionamento',
                      style: TextStyle(
                        color: MilitaryThemeWidgets.primaryGreen,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Você tem até 5 minutos para posicionar suas peças.\nPense bem na sua estratégia!',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Mostra diálogo quando o oponente desconecta e retorna para matchmaking
  void _showOpponentDisconnectedAndReturn(BuildContext context) {
    MilitaryThemeWidgets.showMilitaryDialog(
      context: context,
      title: 'Oponente Desconectou',
      titleIcon: Icons.person_off,
      barrierDismissible: false,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Seu oponente saiu da partida.', style: TextStyle(fontSize: 16)),
          SizedBox(height: 16),
          Text(
            'Você será redirecionado para procurar um novo oponente.',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
      actions: [
        MilitaryThemeWidgets.militaryButton(
          text: 'Procurar Novo Oponente',
          icon: Icons.refresh,
          onPressed: () {
            Navigator.of(context).pop();
            // Força volta para matchmaking
            ref.read(gameStateProvider.notifier).forcarVoltaParaMatchmaking();
            // Navega para matchmaking
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (context) => const MatchmakingScreen(),
              ),
              (route) => false,
            );
          },
        ),
      ],
    );
  }

  /// Mostra diálogo quando perde conexão com servidor durante posicionamento
  void _showConnectionLostAndReturn(BuildContext context) {
    // Durante posicionamento, oferece reconexão para a mesma sessão
    if (_currentPhase == GameFlowPhase.placement) {
      _showPlacementReconnectionDialog(context);
    } else {
      // Durante jogo, volta para matchmaking
      _showGameDisconnectionDialog(context);
    }
  }

  /// Diálogo específico para reconexão durante posicionamento
  void _showPlacementReconnectionDialog(BuildContext context) {
    MilitaryThemeWidgets.showMilitaryDialog(
      context: context,
      title: 'Conexão Perdida Durante Posicionamento',
      titleIcon: Icons.wifi_off,
      barrierDismissible: false,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'A conexão foi perdida durante o posicionamento das peças.',
            style: TextStyle(fontSize: 16),
          ),
          SizedBox(height: 16),
          Text(
            'Você pode tentar reconectar para continuar na mesma partida ou procurar um novo oponente.',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
      actions: [
        MilitaryThemeWidgets.militaryButton(
          text: 'Reconectar à Partida',
          icon: Icons.refresh,
          onPressed: () {
            Navigator.of(context).pop();
            _attemptPlacementReconnection();
          },
        ),
        SizedBox(height: 8),
        MilitaryThemeWidgets.militaryButton(
          text: 'Procurar Novo Oponente',
          icon: Icons.person_search,
          onPressed: () {
            Navigator.of(context).pop();
            _returnToMatchmaking();
          },
        ),
      ],
    );
  }

  /// Diálogo para desconexão durante jogo ativo
  void _showGameDisconnectionDialog(BuildContext context) {
    MilitaryThemeWidgets.showMilitaryDialog(
      context: context,
      title: 'Conexão Perdida',
      titleIcon: Icons.wifi_off,
      barrierDismissible: false,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'A conexão com o servidor foi perdida.',
            style: TextStyle(fontSize: 16),
          ),
          SizedBox(height: 16),
          Text(
            'Você será redirecionado para procurar um novo oponente.',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
      actions: [
        MilitaryThemeWidgets.militaryButton(
          text: 'Procurar Novo Oponente',
          icon: Icons.refresh,
          onPressed: () {
            Navigator.of(context).pop();
            _returnToMatchmaking();
          },
        ),
      ],
    );
  }

  /// Tenta reconectar especificamente durante a fase de posicionamento
  Future<void> _attemptPlacementReconnection() async {
    debugPrint('🔄 Tentando reconexão durante posicionamento...');

    try {
      // Mostra loading durante reconexão
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => MilitaryThemeWidgets.militaryCard(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    MilitaryThemeWidgets.primaryGreen,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Reconectando à partida...',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ),
      );

      // Tenta reconectar usando o método específico para posicionamento
      final socketService = ref.read(gameSocketProvider);
      final nomeUsuario = await UserPreferences.getUserName();
      final serverAddress = await UserPreferences.getServerAddress();

      final success = await socketService.reconnectDuringPlacement(
        serverAddress,
        nomeUsuario: nomeUsuario,
      );

      // Remove o loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      if (success) {
        debugPrint('✅ Reconexão durante posicionamento bem-sucedida');
        // Força volta para fase de posicionamento
        socketService.forcePlacementPhase();
      } else {
        debugPrint('❌ Falha na reconexão, voltando para matchmaking');
        _showReconnectionFailedDialog();
      }
    } catch (e) {
      debugPrint('❌ Erro durante reconexão: $e');
      if (mounted) {
        Navigator.of(context).pop(); // Remove loading dialog
        _showReconnectionFailedDialog();
      }
    }
  }

  /// Mostra diálogo quando a reconexão falha
  void _showReconnectionFailedDialog() {
    MilitaryThemeWidgets.showMilitaryDialog(
      context: context,
      title: 'Reconexão Falhou',
      titleIcon: Icons.error_outline,
      barrierDismissible: false,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Não foi possível reconectar à partida anterior.',
            style: TextStyle(fontSize: 16),
          ),
          SizedBox(height: 16),
          Text(
            'Você será redirecionado para procurar um novo oponente.',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
      actions: [
        MilitaryThemeWidgets.militaryButton(
          text: 'Procurar Novo Oponente',
          icon: Icons.person_search,
          onPressed: () {
            Navigator.of(context).pop();
            _returnToMatchmaking();
          },
        ),
      ],
    );
  }
}

enum GameFlowPhase { placement, game }
