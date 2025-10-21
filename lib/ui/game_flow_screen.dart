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

    // Inicia o placement automaticamente se não há estado do jogo
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndStartPlacement();
    });
  }

  /// Verifica se deve iniciar o placement automaticamente
  void _checkAndStartPlacement() {
    final currentGameState = ref.read(gameStateProvider);

    // Se não há estado do jogo, cria um estado inicial para placement
    if (currentGameState.estadoJogo == null &&
        _currentPhase == GameFlowPhase.matchmaking) {
      debugPrint('🚀 Criando estado inicial para placement');
      _createInitialGameStateForPlacement();
    }
  }

  /// Cria um estado inicial do jogo para permitir o placement
  void _createInitialGameStateForPlacement() {
    final nomeUsuario =
        ref.read(gameStateProvider).nomeUsuario ?? 'Jogador Local';

    // Cria um estado inicial mínimo para permitir o placement
    final estadoInicial = EstadoJogo(
      idPartida: 'local-game-${DateTime.now().millisecondsSinceEpoch}',
      jogadores: [
        Jogador(
          id: 'local-player-id',
          nome: nomeUsuario,
          equipe: Equipe.verde, // Jogador local sempre verde
        ),
        // Adiciona um segundo jogador para evitar problemas de UI
        Jogador(
          id: 'opponent-player-id',
          nome: 'Oponente',
          equipe: Equipe.preta,
        ),
      ],
      pecas: [], // Vazio para iniciar placement
      idJogadorDaVez: 'local-player-id',
      jogoTerminou: false,
    );

    debugPrint('🚀 Estado inicial criado: $nomeUsuario vs Oponente');

    // Atualiza o estado do jogo
    ref.read(gameStateProvider.notifier).updateGameState(estadoInicial);
  }

  void _handleGameStateChange(TelaJogoState? previous, TelaJogoState current) {
    final estadoJogo = current.estadoJogo;

    debugPrint('🔄 GameFlowScreen: _handleGameStateChange chamado');
    debugPrint('🔄 Estado atual: ${estadoJogo?.pecas.length ?? 0} peças');
    debugPrint('🔄 Fase atual: $_currentPhase');

    // Se recebeu um estado de jogo válido e estamos em matchmaking
    if (estadoJogo != null && _currentPhase == GameFlowPhase.matchmaking) {
      debugPrint('🔄 Estado válido recebido durante matchmaking');

      // Verifica se deve iniciar placement
      if (_shouldStartPlacement(estadoJogo)) {
        debugPrint('🔄 Iniciando fase de placement');
        _startPlacementPhase(estadoJogo);
      } else if (_shouldStartGame(estadoJogo)) {
        debugPrint('🔄 Pulando placement - jogo já tem peças');
        // Se o jogo já está em progresso, pula placement
        _startGamePhase();
      } else {
        debugPrint('🔄 Nenhuma condição atendida para mudança de fase');
      }
    } else {
      debugPrint(
        '🔄 Condições não atendidas: estadoJogo=${estadoJogo != null}, fase=$_currentPhase',
      );
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
    // Inicia placement se:
    // 1. O jogo não tem peças (estado inicial)
    // 2. Há jogadores conectados
    // 3. O jogo não terminou
    final shouldStart =
        estadoJogo.pecas.isEmpty &&
        estadoJogo.jogadores.isNotEmpty &&
        !estadoJogo.jogoTerminou;

    debugPrint(
      '🔍 _shouldStartPlacement: peças=${estadoJogo.pecas.length}, jogadores=${estadoJogo.jogadores.length}, terminou=${estadoJogo.jogoTerminou} -> $shouldStart',
    );
    return shouldStart;
  }

  bool _shouldStartGame(EstadoJogo estadoJogo) {
    // Se o jogo já tem peças posicionadas, pula placement
    final shouldStart = estadoJogo.pecas.isNotEmpty;
    debugPrint(
      '🔍 _shouldStartGame: peças=${estadoJogo.pecas.length} -> $shouldStart',
    );
    return shouldStart;
  }

  void _startPlacementPhase(EstadoJogo estadoJogo) {
    // Evita iniciar placement múltiplas vezes
    if (_currentPhase != GameFlowPhase.matchmaking) {
      debugPrint('🔄 Placement já foi iniciado, ignorando');
      return;
    }

    debugPrint('🔄 Iniciando placement phase');

    // Determina a área do jogador baseado na equipe
    final nomeUsuario = ref.read(gameStateProvider).nomeUsuario;
    final jogadorLocal = _findLocalPlayer(estadoJogo, nomeUsuario);

    if (jogadorLocal == null) {
      debugPrint('❌ Jogador local não encontrado');
      return;
    }

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

    debugPrint('🔄 Placement phase iniciado com sucesso');
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

        // Cria peças do oponente automaticamente
        final opponentTeam = _determinePlayerTeam(placedPieces!) == Equipe.verde
            ? Equipe.preta
            : Equipe.verde;
        debugPrint(
          '🤖 Criando peças do oponente para equipe: ${opponentTeam.name}',
        );
        final opponentPieces = _createOpponentPieces(opponentTeam);
        debugPrint('🤖 Criadas ${opponentPieces.length} peças para o oponente');

        debugPrint('🔍 Peças do jogador: ${placedPieces!.length}');
        debugPrint('🔍 Peças do oponente: ${opponentPieces.length}');
        debugPrint(
          '🔍 Total de peças: ${placedPieces!.length + opponentPieces.length}',
        );

        gameState = EstadoJogo(
          idPartida: gameId,
          jogadores: [
            Jogador(
              id: playerId,
              nome: nomeUsuario,
              equipe: _determinePlayerTeam(placedPieces!),
            ),
            Jogador(id: 'opponent-id', nome: 'Oponente', equipe: opponentTeam),
          ],
          pecas: [...placedPieces!, ...opponentPieces],
          idJogadorDaVez: playerId, // Jogador local começa
          jogoTerminou: false,
        );

        debugPrint(
          '🎮 Estado criado com ${gameState.pecas.length} peças total',
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

  /// Cria as peças do oponente automaticamente para modo offline.
  List<PecaJogo> _createOpponentPieces(Equipe opponentTeam) {
    final pieces = <PecaJogo>[];
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    // Determina as linhas do oponente baseado na equipe
    final opponentRows = opponentTeam == Equipe.verde
        ? [0, 1, 2, 3]
        : [6, 7, 8, 9];

    // Composição do exército (40 peças)
    final composition = {
      Patente.marechal: 1,
      Patente.general: 1,
      Patente.coronel: 2,
      Patente.major: 3,
      Patente.capitao: 4,
      Patente.tenente: 4,
      Patente.sargento: 4,
      Patente.cabo: 5,
      Patente.soldado: 8,
      Patente.agenteSecreto: 1,
      Patente.prisioneiro: 1,
      Patente.minaTerrestre: 6,
    };

    int pieceIndex = 0;

    // Cria as peças e as posiciona aleatoriamente nas linhas do oponente
    for (final entry in composition.entries) {
      final patente = entry.key;
      final count = entry.value;

      for (int i = 0; i < count; i++) {
        // Calcula posição aleatória nas linhas do oponente
        final row = opponentRows[pieceIndex ~/ 10];
        final col = pieceIndex % 10;

        pieces.add(
          PecaJogo(
            id: 'opponent_piece_${timestamp}_$pieceIndex',
            patente: patente,
            equipe: opponentTeam,
            posicao: PosicaoTabuleiro(linha: row, coluna: col),
            foiRevelada: false,
          ),
        );

        pieceIndex++;
      }
    }

    debugPrint(
      '🤖 Criadas ${pieces.length} peças para o oponente (${opponentTeam.name})',
    );
    return pieces;
  }

  /// Determina a equipe do jogador baseado nas peças posicionadas.
  Equipe _determinePlayerTeam(List<PecaJogo> pieces) {
    if (pieces.isNotEmpty) {
      return pieces.first.equipe;
    }
    return Equipe.verde; // Fallback
  }

  Jogador? _findLocalPlayer(EstadoJogo estadoJogo, String? nomeUsuario) {
    if (nomeUsuario == null) {
      debugPrint('❌ nomeUsuario é null');
      return null;
    }

    final jogadorEncontrado = estadoJogo.jogadores.where((jogador) {
      final nomeJogador = jogador.nome.trim().toLowerCase();
      final nomeLocal = nomeUsuario.trim().toLowerCase();

      final match =
          nomeJogador == nomeLocal ||
          nomeJogador.contains(nomeLocal) ||
          nomeLocal.contains(nomeJogador);

      return match;
    }).firstOrNull;

    if (jogadorEncontrado != null) {
      debugPrint('✅ Jogador local encontrado: ${jogadorEncontrado.nome}');
    } else {
      debugPrint('❌ Jogador local não encontrado para "$nomeUsuario"');
    }

    return jogadorEncontrado;
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
