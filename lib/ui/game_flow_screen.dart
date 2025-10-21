import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  List<PecaJogo>? _savedPlacedPieces; // Backup das peças posicionadas

  @override
  void initState() {
    super.initState();
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
    // IMPORTANTE: Transfere as peças ANTES de limpar o estado
    _transferPlacedPiecesToGame();

    setState(() {
      _currentPhase = GameFlowPhase.game;
    });

    // Limpa o estado de placement DEPOIS da transferência
    ref.read(placementStateProvider.notifier).resetToGame();
  }

  /// Transfere as peças posicionadas do placement para o estado do jogo principal.
  Future<void> _transferPlacedPiecesToGame() async {
    debugPrint('🔄 Iniciando transferência de peças...');

    final placementState = ref.read(placementStateProvider);
    final currentGameState = ref.read(gameStateProvider);

    debugPrint('🔍 PlacementState: ${placementState.placementState != null}');
    debugPrint(
      '🔍 Peças posicionadas: ${placementState.placementState?.placedPieces.length ?? 0}',
    );
    debugPrint('🔍 _placementState disponível: ${_placementState != null}');
    debugPrint(
      '🔍 Peças em _placementState: ${_placementState?.placedPieces.length ?? 0}',
    );

    // Tenta obter as peças do provider primeiro, depois do _placementState
    List<PecaJogo>? placedPieces;
    String? gameId;
    String? playerId;

    if (placementState.placementState?.placedPieces.isNotEmpty == true) {
      placedPieces = placementState.placementState!.placedPieces;
      gameId = placementState.placementState!.gameId;
      playerId = placementState.placementState!.playerId;
      debugPrint('🔍 Usando peças do placementState provider');
    } else {
      // Tenta carregar do armazenamento local
      final storedData = await _loadPiecesFromStorage();
      if (storedData != null) {
        placedPieces = storedData['pieces'] as List<PecaJogo>?;
        gameId = storedData['gameId'] as String?;
        playerId = storedData['playerId'] as String?;
        debugPrint(
          '🔍 Usando peças do armazenamento: ${placedPieces?.length ?? 0}',
        );
      } else if (_savedPlacedPieces?.isNotEmpty == true) {
        placedPieces = _savedPlacedPieces!;
        gameId = _placementState?.gameId ?? 'default-game-id';
        playerId = _placementState?.playerId ?? 'default-player-id';
        debugPrint('🔍 Usando peças salvas: ${_savedPlacedPieces!.length}');
      } else if (_placementState?.placedPieces.isNotEmpty == true) {
        placedPieces = _placementState!.placedPieces;
        gameId = _placementState!.gameId;
        playerId = _placementState!.playerId;
        debugPrint('🔍 Usando peças do _placementState backup');
      }
    }

    if (placedPieces?.isNotEmpty == true &&
        gameId != null &&
        playerId != null) {
      // Cria ou atualiza o estado do jogo
      EstadoJogo gameState;

      if (currentGameState.estadoJogo != null) {
        // Atualiza estado existente
        gameState = EstadoJogo(
          idPartida: currentGameState.estadoJogo!.idPartida,
          jogadores: currentGameState.estadoJogo!.jogadores,
          pecas: [...currentGameState.estadoJogo!.pecas, ...placedPieces!],
          idJogadorDaVez: currentGameState.estadoJogo!.idJogadorDaVez,
          jogoTerminou: currentGameState.estadoJogo!.jogoTerminou,
          idVencedor: currentGameState.estadoJogo!.idVencedor,
        );
      } else {
        // Cria estado inicial do jogo
        final nomeUsuario = currentGameState.nomeUsuario ?? 'Jogador Local';

        gameState = EstadoJogo(
          idPartida: gameId,
          jogadores: [
            Jogador(
              id: playerId,
              nome: nomeUsuario,
              equipe: _determinePlayerTeam(placedPieces!),
            ),
            Jogador(
              id: 'opponent-id',
              nome: 'Oponente',
              equipe: _determinePlayerTeam(placedPieces!) == Equipe.verde
                  ? Equipe.preta
                  : Equipe.verde,
            ),
          ],
          pecas: placedPieces!,
          idJogadorDaVez: playerId, // Jogador local começa
          jogoTerminou: false,
        );
      }

      // Atualiza o estado do jogo principal
      ref.read(gameStateProvider.notifier).updateGameState(gameState);

      debugPrint(
        '🎮 Peças transferidas para o jogo: ${placedPieces?.length ?? 0} peças',
      );
      debugPrint('🎮 Estado do jogo criado com ID: ${gameState.idPartida}');
    }
  }

  /// Carrega as peças do armazenamento local.
  Future<Map<String, dynamic>?> _loadPiecesFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString('placed_pieces_for_transfer');

      if (data != null) {
        final decoded = jsonDecode(data) as Map<String, dynamic>;
        final piecesJson = decoded['pieces'] as List<dynamic>;
        final pieces = piecesJson
            .map((p) => PecaJogo.fromJson(p as Map<String, dynamic>))
            .toList();

        return {
          'gameId': decoded['gameId'],
          'playerId': decoded['playerId'],
          'pieces': pieces,
        };
      }
    } catch (e) {
      debugPrint('❌ Erro ao carregar peças do armazenamento: $e');
    }
    return null;
  }

  /// Determina a equipe do jogador baseado nas peças posicionadas.
  Equipe _determinePlayerTeam(List<PecaJogo> pieces) {
    if (pieces.isNotEmpty) {
      return pieces.first.equipe;
    }
    return Equipe.verde; // Fallback
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
    // IMPORTANTE: Salva as peças ANTES de qualquer transição
    _savePlacedPieces();

    // Transição do placement para o jogo
    _startGamePhase();
  }

  /// Salva as peças posicionadas antes da transição para evitar perda de dados.
  void _savePlacedPieces() {
    final placementState = ref.read(placementStateProvider);
    if (placementState.placementState?.placedPieces.isNotEmpty == true) {
      _savedPlacedPieces = List<PecaJogo>.from(
        placementState.placementState!.placedPieces,
      );
      debugPrint(
        '💾 Peças salvas para transferência: ${_savedPlacedPieces?.length ?? 0}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
