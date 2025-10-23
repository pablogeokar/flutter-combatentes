import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../modelos_jogo.dart';
import '../placement_controller.dart';
import '../placement_error_handler.dart';

import '../piece_inventory.dart';
import '../providers.dart';
import 'piece_inventory_widget.dart';
import 'placement_board_widget.dart';

import 'military_theme_widgets.dart';

/// Tela principal de posicionamento de peças.
/// Integra inventário, tabuleiro e status em um layout responsivo.
class PiecePlacementScreen extends ConsumerStatefulWidget {
  /// Estado inicial do posicionamento.
  final PlacementGameState initialState;

  /// Callback chamado quando o jogo deve iniciar.
  final VoidCallback? onGameStart;

  /// Callback chamado quando o usuário quer voltar.
  final VoidCallback? onBack;

  const PiecePlacementScreen({
    super.key,
    required this.initialState,
    this.onGameStart,
    this.onBack,
  });

  @override
  ConsumerState<PiecePlacementScreen> createState() =>
      _PiecePlacementScreenState();
}

class _PiecePlacementScreenState extends ConsumerState<PiecePlacementScreen>
    with TickerProviderStateMixin {
  late PlacementController _controller;
  late PieceInventory _inventory;
  Patente? _selectedPieceType;
  bool _showExitDialog = false;

  // Controllers para animações
  AnimationController? _fadeController;
  AnimationController? _slideController;
  Animation<double>? _fadeAnimation;
  Animation<Offset>? _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _initializeAnimations();
    _setupInitialState();
  }

  void _initializeControllers() {
    // Inicializa o controller de posicionamento
    // TODO: Integrar com GameSocketService quando disponível
    _controller = PlacementController(
      // Placeholder - será substituído pela integração real
      ref.read(gameSocketProvider),
      retryConfig: const RetryConfig(
        maxAttempts: 3,
        initialDelay: Duration(seconds: 1),
        backoffMultiplier: 2.0,
      ),
    );

    // Configura listener para mudanças de estado
    _controller.addListener(_onPlacementStateChanged);
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController!, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _slideController!,
            curve: Curves.easeOutCubic,
          ),
        );

    // Inicia as animações
    _fadeController!.forward();
    _slideController!.forward();
  }

  void _setupInitialState() {
    // Cria inventário baseado no estado inicial
    _inventory = PieceInventory();

    // Configura o estado inicial no controller
    _controller.updateState(widget.initialState);

    // Inicializa o coordenador de múltiplas instâncias
    _controller.initializeMultiInstanceCoordinator(widget.initialState);

    // Remove peças já posicionadas do inventário
    for (final peca in widget.initialState.placedPieces) {
      _inventory.removePiece(peca.patente);
    }
  }

  void _onPlacementStateChanged() {
    final state = _controller.currentState;
    final error = _controller.lastError;

    debugPrint(
      'PiecePlacementScreen: Estado mudou - Fase: ${state?.gamePhase}, Local: ${state?.localStatus}, Oponente: ${state?.opponentStatus}',
    );

    // Manipula erros se houver
    if (error != null && mounted) {
      PlacementErrorHandler.handlePlacementError(
        context,
        error,
        onRetry: _handleRetryOperation,
      );
    }

    if (state == null) return;

    // Verifica se o jogo deve iniciar
    if (state.gamePhase == GamePhase.gameInProgress) {
      debugPrint(
        'PiecePlacementScreen: Jogo deve iniciar! Chamando onGameStart callback',
      );

      // IMPORTANTE: Salva as peças ANTES de chamar onGameStart
      _savePlacedPiecesForTransfer();

      widget.onGameStart?.call();
    }

    // Atualiza o estado local se necessário
    setState(() {});
  }

  /// Manipula retry de operações falhadas.
  void _handleRetryOperation() {
    // Implementa retry baseado no último erro
    final error = _controller.lastError;
    if (error == null) return;

    switch (error.type) {
      case PlacementErrorType.networkError:
      case PlacementErrorType.timeout:
        // Retry da confirmação se foi isso que falhou
        _controller.retryOperation(() async {
          final result = await _controller.confirmPlacement();
          return result;
        });
        break;
      default:
        // Para outros erros, apenas limpa o erro
        _controller.clearError();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onPlacementStateChanged);
    _controller.dispose();
    _fadeController?.dispose();
    _slideController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _handleBackNavigation();
        }
      },
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: _buildHeader(),
        ),
        body: MilitaryThemeWidgets.militaryBackground(
          child: SafeArea(
            top: false, // AppBar já cuida do SafeArea no topo
            child: AnimatedBuilder(
              animation: _fadeAnimation!,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnimation!,
                  child: SlideTransition(
                    position: _slideAnimation!,
                    child: _buildContent(),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWideScreen = constraints.maxWidth > 800;
        final isTablet = constraints.maxWidth > 600;

        if (isWideScreen) {
          return _buildWideScreenLayout();
        } else if (isTablet) {
          return _buildTabletLayout();
        } else {
          return _buildMobileLayout();
        }
      },
    );
  }

  /// Layout para telas largas (desktop/landscape).
  Widget _buildWideScreenLayout() {
    final showInventory = _shouldShowInventory();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Inventário à esquerda - oculto quando jogador está pronto
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            transitionBuilder: (child, animation) {
              return SlideTransition(
                position:
                    Tween<Offset>(
                      begin: const Offset(-1.0, 0.0),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeInOut,
                      ),
                    ),
                child: FadeTransition(opacity: animation, child: child),
              );
            },
            child: showInventory
                ? Row(
                    key: const ValueKey('inventory'),
                    children: [
                      Expanded(
                        flex: 2,
                        child: SingleChildScrollView(
                          child: _buildInventorySection(),
                        ),
                      ),
                      const SizedBox(width: 16),
                    ],
                  )
                : const SizedBox.shrink(key: ValueKey('no-inventory')),
          ),

          // Tabuleiro no centro - ocupa mais espaço quando inventário está oculto
          Expanded(flex: showInventory ? 3 : 4, child: _buildBoardSection()),
          const SizedBox(width: 16),

          // Ações à direita
          Expanded(flex: 1, child: _buildActionSection()),
        ],
      ),
    );
  }

  /// Layout para tablets.
  Widget _buildTabletLayout() {
    final showInventory = _shouldShowInventory();

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: [
          // Ações no topo
          _buildActionSection(),
          const SizedBox(height: 12),

          // Tabuleiro e inventário lado a lado
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tabuleiro - ocupa mais espaço quando inventário está oculto
                Expanded(
                  flex: showInventory ? 3 : 1,
                  child: _buildBoardSection(),
                ),

                // Inventário à direita - oculto quando jogador está pronto
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  transitionBuilder: (child, animation) {
                    return SlideTransition(
                      position:
                          Tween<Offset>(
                            begin: const Offset(1.0, 0.0),
                            end: Offset.zero,
                          ).animate(
                            CurvedAnimation(
                              parent: animation,
                              curve: Curves.easeInOut,
                            ),
                          ),
                      child: FadeTransition(opacity: animation, child: child),
                    );
                  },
                  child: showInventory
                      ? Row(
                          key: const ValueKey('inventory'),
                          children: [
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: SingleChildScrollView(
                                child: _buildInventorySection(),
                              ),
                            ),
                          ],
                        )
                      : const SizedBox.shrink(key: ValueKey('no-inventory')),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Layout para dispositivos móveis.
  Widget _buildMobileLayout() {
    final showInventory = _shouldShowInventory();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          // Ações no topo
          _buildActionSection(),
          const SizedBox(height: 12),

          // Tabuleiro
          _buildBoardSection(),

          // Inventário na parte inferior - oculto quando jogador está pronto
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            transitionBuilder: (child, animation) {
              return SlideTransition(
                position:
                    Tween<Offset>(
                      begin: const Offset(0.0, 1.0),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeInOut,
                      ),
                    ),
                child: FadeTransition(opacity: animation, child: child),
              );
            },
            child: showInventory
                ? Column(
                    key: const ValueKey('inventory'),
                    children: [
                      const SizedBox(height: 12),
                      ConstrainedBox(
                        constraints: const BoxConstraints(
                          minHeight: 200,
                          maxHeight: 600,
                        ),
                        child: _buildInventorySection(),
                      ),
                    ],
                  )
                : const SizedBox.shrink(key: ValueKey('no-inventory')),
          ),

          // Espaço extra para garantir scroll
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  /// Constrói o cabeçalho da tela seguindo o padrão da tela do jogo.
  Widget _buildHeader() {
    return AppBar(
      title: Row(
        children: [
          // Logo de texto do jogo com fundo sutil (mesmo padrão da tela do jogo)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Image.asset(
              'assets/images/combatentes.png',
              height: 28,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.military_tech,
                  color: Colors.white,
                  size: 28,
                );
              },
            ),
          ),
          const SizedBox(width: 16),

          // Status compacto integrado à AppBar
          Expanded(child: _buildCompactPlacementStatus()),
        ],
      ),
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/bg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.7)),
        ),
      ),
      foregroundColor: Colors.white,
      elevation: 4,
      shadowColor: Colors.black.withValues(alpha: 0.3),
      automaticallyImplyLeading: false, // Remove botão de voltar
      actions: [
        // Indicador de fase compacto
        Container(
          margin: const EdgeInsets.only(right: 16),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_getPhaseIcon(), color: Colors.white, size: 16),
              const SizedBox(width: 6),
              Text(
                _getPhaseText(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Constrói o status compacto para a AppBar.
  Widget _buildCompactPlacementStatus() {
    final state = _controller.currentState ?? widget.initialState;

    return Row(
      children: [
        // Peças restantes
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.inventory_2,
                color: _inventory.isEmpty ? Colors.green : Colors.white,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                '${_inventory.totalPiecesRemaining}/40',
                style: TextStyle(
                  color: _inventory.isEmpty ? Colors.green : Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),

        // Status do oponente
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getOpponentStatusIcon(state.opponentStatus),
                color: _getOpponentStatusColor(state.opponentStatus),
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                _getOpponentStatusText(state.opponentStatus),
                style: TextStyle(
                  color: _getOpponentStatusColor(state.opponentStatus),
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),

        // Countdown se estiver iniciando
        if (_controller.isGameStarting) ...[
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.rocket_launch, color: Colors.orange, size: 16),
                const SizedBox(width: 4),
                Text(
                  '${_controller.countdownSeconds}s',
                  style: const TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  /// Constrói a seção do inventário.
  Widget _buildInventorySection() {
    return PieceInventoryWidget(
      inventory: _inventory,
      selectedPieceType: _selectedPieceType,
      onPieceSelect: _handlePieceSelect,
      enabled: _isInteractionEnabled(),
    );
  }

  /// Constrói a seção do tabuleiro.
  Widget _buildBoardSection() {
    final state = _controller.currentState ?? widget.initialState;

    return PlacementBoardWidget(
      placedPieces: state.placedPieces,
      playerArea: state.playerArea,
      selectedPieceType: _selectedPieceType,
      inventory: _inventory,
      playerTeam: _getPlayerTeam(),
      onPositionTap: _handlePositionTap,
      onPieceDrag: _handlePieceDrag,
      onPieceRemove: _handlePieceRemove,
      enabled: _isInteractionEnabled(),
    );
  }

  /// Constrói a seção de ações (botão de confirmação).
  Widget _buildActionSection() {
    final state = _controller.currentState ?? widget.initialState;
    final canConfirm =
        _inventory.isEmpty && state.localStatus == PlacementStatus.placing;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Botão principal de confirmação
        SizedBox(
          width: double.infinity,
          child: MilitaryThemeWidgets.militaryButton(
            text: _controller.isGameStarting
                ? 'Iniciando... ${_controller.countdownSeconds}s'
                : state.localStatus == PlacementStatus.ready
                ? 'Aguardando Oponente'
                : 'CONFIRMAR POSICIONAMENTO',
            onPressed: canConfirm && !_controller.isGameStarting
                ? _handleReadyPressed
                : null,
            icon: _controller.isGameStarting
                ? Icons.rocket_launch
                : state.localStatus == PlacementStatus.ready
                ? Icons.hourglass_empty
                : Icons.check_circle,
            isLoading: _controller.isGameStarting,
          ),
        ),

        // Informações adicionais baseadas no estado
        const SizedBox(height: 8),
        _buildStatusMessage(state),
      ],
    );
  }

  /// Manipula a seleção de uma peça do inventário.
  void _handlePieceSelect(Patente patente) {
    if (!_isInteractionEnabled()) return;

    // Atualiza atividade de rede para evitar timeout
    _controller.updateNetworkActivity();

    setState(() {
      _selectedPieceType = _selectedPieceType == patente ? null : patente;
    });
  }

  /// Manipula o tap em uma posição do tabuleiro.
  void _handlePositionTap(PosicaoTabuleiro position) {
    if (!_isInteractionEnabled() || _selectedPieceType == null) return;

    // Atualiza atividade de rede para evitar timeout
    _controller.updateNetworkActivity();

    // Valida a operação antes de executar
    final validation = _controller.validatePiecePlacement(
      position: position,
      pieceType: _selectedPieceType!,
    );

    if (validation.isFailure) {
      PlacementErrorHandler.handlePlacementError(context, validation.error!);
      return;
    }

    _placePieceAtPosition(_selectedPieceType!, position);
  }

  /// Manipula o drag de uma peça para nova posição.
  void _handlePieceDrag(String pieceId, PosicaoTabuleiro newPosition) {
    if (!_isInteractionEnabled()) return;

    // Atualiza atividade de rede para evitar timeout
    _controller.updateNetworkActivity();

    final state = _controller.currentState ?? widget.initialState;
    final piece = state.placedPieces.where((p) => p.id == pieceId).firstOrNull;

    if (piece != null) {
      // Remove a peça da posição atual
      _removePieceFromBoard(pieceId);

      // Posiciona na nova posição
      _placePieceAtPosition(piece.patente, newPosition);
    }
  }

  /// Manipula a remoção de uma peça do tabuleiro.
  void _handlePieceRemove(String pieceId) {
    if (!_isInteractionEnabled()) return;

    // Atualiza atividade de rede para evitar timeout
    _controller.updateNetworkActivity();

    _removePieceFromBoard(pieceId);
  }

  /// Manipula o pressionamento do botão "PRONTO".
  void _handleReadyPressed() {
    if (!_inventory.isEmpty) {
      final missingTypes = _inventory.availablePieces.entries
          .where((entry) => entry.value > 0)
          .map((entry) {
            // Converte string para Patente
            return Patente.values.firstWhere(
              (p) => p.name == entry.key,
              orElse: () => Patente.soldado, // fallback
            );
          })
          .toList();

      final error = PlacementError.incompletePlacement(
        remainingPieces: _inventory.totalPiecesRemaining,
        missingTypes: missingTypes,
      );
      PlacementErrorHandler.handlePlacementError(context, error);
      return;
    }

    _controller.confirmPlacement();
  }

  /// Manipula a navegação de volta.
  void _handleBackNavigation() {
    // Durante o posicionamento, não permite voltar para evitar quebrar o fluxo do jogo
    // O jogador deve completar o posicionamento ou aguardar timeout/desconexão
    _showCannotExitDialog();
  }

  /// Posiciona uma peça em uma posição específica.
  void _placePieceAtPosition(Patente patente, PosicaoTabuleiro position) {
    if (!_inventory.isAvailable(patente)) return;

    final state = _controller.currentState ?? widget.initialState;

    // Verifica se há peça na posição (para troca)
    final existingPiece = state.placedPieces
        .where(
          (p) =>
              p.posicao.linha == position.linha &&
              p.posicao.coluna == position.coluna,
        )
        .firstOrNull;

    if (existingPiece != null) {
      // Troca de posições - devolve a peça existente ao inventário
      _inventory.addPiece(existingPiece.patente);
    }

    // Remove a nova peça do inventário
    _inventory.removePiece(patente);

    // Cria nova peça
    final newPiece = PecaJogo(
      id: 'piece_${DateTime.now().millisecondsSinceEpoch}',
      patente: patente,
      posicao: position,
      equipe: _getPlayerTeam(),
      foiRevelada: false,
    );

    // Atualiza o estado
    final updatedPieces =
        state.placedPieces
            .where(
              (p) =>
                  !(p.posicao.linha == position.linha &&
                      p.posicao.coluna == position.coluna),
            )
            .toList()
          ..add(newPiece);

    final updatedState = PlacementGameState(
      gameId: state.gameId,
      playerId: state.playerId,
      availablePieces: _inventory.availablePieces,
      placedPieces: updatedPieces,
      playerArea: state.playerArea,
      localStatus: state.localStatus,
      opponentStatus: state.opponentStatus,
      selectedPieceType: _selectedPieceType,
      gamePhase: state.gamePhase,
    );

    _controller.updateState(updatedState);

    // Limpa seleção se não há mais peças deste tipo
    if (!_inventory.isAvailable(patente)) {
      setState(() {
        _selectedPieceType = null;
      });
    }

    setState(() {});
  }

  /// Remove uma peça do tabuleiro.
  void _removePieceFromBoard(String pieceId) {
    final state = _controller.currentState ?? widget.initialState;
    final piece = state.placedPieces.where((p) => p.id == pieceId).firstOrNull;

    if (piece == null) return;

    // Devolve a peça ao inventário
    _inventory.addPiece(piece.patente);

    // Remove do tabuleiro
    final updatedPieces = state.placedPieces
        .where((p) => p.id != pieceId)
        .toList();

    final updatedState = PlacementGameState(
      gameId: state.gameId,
      playerId: state.playerId,
      availablePieces: _inventory.availablePieces,
      placedPieces: updatedPieces,
      playerArea: state.playerArea,
      localStatus: state.localStatus,
      opponentStatus: state.opponentStatus,
      selectedPieceType: _selectedPieceType,
      gamePhase: state.gamePhase,
    );

    _controller.updateState(updatedState);
    setState(() {});
  }

  /// Verifica se a interação está habilitada.
  bool _isInteractionEnabled() {
    final state = _controller.currentState ?? widget.initialState;
    return state.localStatus == PlacementStatus.placing &&
        !_controller.isGameStarting;
  }

  /// Verifica se deve mostrar o inventário.
  /// O inventário é ocultado quando o jogador já confirmou o posicionamento.
  bool _shouldShowInventory() {
    final state = _controller.currentState ?? widget.initialState;
    return state.localStatus == PlacementStatus.placing;
  }

  /// Constrói a mensagem de status baseada no estado atual.
  Widget _buildStatusMessage(PlacementGameState state) {
    if (!_inventory.isEmpty) {
      // Ainda há peças para posicionar
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.info_outline, color: Colors.orange, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Posicione todas as ${_inventory.totalPiecesRemaining} peças restantes',
                style: const TextStyle(
                  color: Colors.orange,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    } else if (state.localStatus == PlacementStatus.ready) {
      // Jogador está pronto, aguardando oponente
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Posicionamento confirmado! Aguardando oponente finalizar...',
                style: const TextStyle(
                  color: Colors.green,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      // Estado padrão
      return const SizedBox.shrink();
    }
  }

  /// Retorna a equipe do jogador.
  Equipe _getPlayerTeam() {
    final state = _controller.currentState ?? widget.initialState;
    // Determina a equipe baseada na área do jogador
    return state.playerArea.contains(0) ? Equipe.verde : Equipe.preta;
  }

  /// Retorna o ícone da fase atual.
  IconData _getPhaseIcon() {
    final state = _controller.currentState ?? widget.initialState;

    if (_controller.isGameStarting) {
      return Icons.rocket_launch;
    }

    switch (state.gamePhase) {
      case GamePhase.piecePlacement:
        return Icons.place;
      case GamePhase.waitingForOpponentReady:
        return Icons.hourglass_empty;
      case GamePhase.gameStarting:
        return Icons.rocket_launch;
      default:
        return Icons.military_tech;
    }
  }

  /// Retorna o texto da fase atual.
  String _getPhaseText() {
    final state = _controller.currentState ?? widget.initialState;

    if (_controller.isGameStarting) {
      return 'Iniciando...';
    }

    switch (state.gamePhase) {
      case GamePhase.piecePlacement:
        return 'Posicionamento';
      case GamePhase.waitingForOpponentReady:
        return 'Aguardando';
      case GamePhase.gameStarting:
        return 'Iniciando...';
      default:
        return 'Preparação';
    }
  }

  /// Retorna o ícone do status do oponente.
  IconData _getOpponentStatusIcon(PlacementStatus status) {
    switch (status) {
      case PlacementStatus.placing:
        return Icons.build;
      case PlacementStatus.ready:
        return Icons.check_circle;
      case PlacementStatus.waiting:
        return Icons.hourglass_empty;
    }
  }

  /// Retorna a cor do status do oponente.
  Color _getOpponentStatusColor(PlacementStatus status) {
    switch (status) {
      case PlacementStatus.placing:
        return Colors.orange;
      case PlacementStatus.ready:
        return Colors.green;
      case PlacementStatus.waiting:
        return Colors.blue;
    }
  }

  /// Retorna o texto do status do oponente.
  String _getOpponentStatusText(PlacementStatus status) {
    switch (status) {
      case PlacementStatus.placing:
        return 'Posicionando';
      case PlacementStatus.ready:
        return 'Pronto';
      case PlacementStatus.waiting:
        return 'Aguardando';
    }
  }

  /// Mostra diálogo informando que não é possível sair durante o posicionamento.
  void _showCannotExitDialog() {
    if (_showExitDialog) return;

    setState(() {
      _showExitDialog = true;
    });

    MilitaryThemeWidgets.showMilitaryDialog<void>(
      context: context,
      barrierDismissible: true,
      title: 'Posicionamento em Andamento',
      titleIcon: Icons.info_outline,
      content: const Text(
        'Você deve completar o posicionamento das peças para continuar. '
        'Posicione todas as suas 40 peças e clique em "PRONTO" para iniciar a partida.',
        style: TextStyle(color: Colors.black87),
      ),
      actions: [
        MilitaryThemeWidgets.militaryButton(
          text: 'Entendi',
          onPressed: () {
            Navigator.of(context).pop();
            setState(() {
              _showExitDialog = false;
            });
          },
          icon: Icons.check,
        ),
      ],
    ).then((_) {
      setState(() {
        _showExitDialog = false;
      });
    });
  }

  /// Salva as peças posicionadas para transferência posterior.
  void _savePlacedPiecesForTransfer() {
    final currentState = _controller.currentState;
    if (currentState?.placedPieces.isNotEmpty == true) {
      debugPrint(
        '💾 Salvando ${currentState!.placedPieces.length} peças para transferência',
      );

      // Salva no SharedPreferences para transferência
      _savePiecesToStorage(
        currentState.placedPieces,
        currentState.gameId,
        currentState.playerId,
      );
    }
  }

  /// Salva as peças no armazenamento local para transferência.
  void _savePiecesToStorage(
    List<PecaJogo> pieces,
    String gameId,
    String playerId,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = {
        'gameId': gameId,
        'playerId': playerId,
        'pieces': pieces.map((p) => p.toJson()).toList(),
        'timestamp': DateTime.now().toIso8601String(),
      };

      await prefs.setString('placed_pieces_for_transfer', jsonEncode(data));
      debugPrint('💾 Peças salvas no armazenamento para transferência');
    } catch (e) {
      debugPrint('❌ Erro ao salvar peças: $e');
    }
  }
}
