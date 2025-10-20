import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

import '../modelos_jogo.dart';
import '../piece_inventory.dart';
import '../placement_error_handler.dart';
import 'military_theme_widgets.dart';
import 'peca_widget.dart';

/// Widget de tabuleiro interativo para posicionamento de peças com drag and drop.
/// Permite posicionar peças na área do jogador com validação visual em tempo real.
class PlacementBoardWidget extends StatefulWidget {
  /// Lista de peças já posicionadas no tabuleiro.
  final List<PecaJogo> placedPieces;

  /// Linhas válidas para posicionamento do jogador (ex: [0,1,2,3] ou [6,7,8,9]).
  final List<int> playerArea;

  /// Tipo de peça atualmente selecionado para posicionamento.
  final Patente? selectedPieceType;

  /// Inventário de peças disponíveis.
  final PieceInventory inventory;

  /// Equipe do jogador local.
  final Equipe playerTeam;

  /// Callback chamado quando uma posição no tabuleiro é tocada.
  final void Function(PosicaoTabuleiro position) onPositionTap;

  /// Callback chamado quando uma peça é arrastada para nova posição.
  final void Function(String pieceId, PosicaoTabuleiro newPosition) onPieceDrag;

  /// Callback chamado quando uma peça posicionada é removida.
  final void Function(String pieceId) onPieceRemove;

  /// Se o tabuleiro está habilitado para interação.
  final bool enabled;

  const PlacementBoardWidget({
    super.key,
    required this.placedPieces,
    required this.playerArea,
    required this.inventory,
    required this.playerTeam,
    required this.onPositionTap,
    required this.onPieceDrag,
    required this.onPieceRemove,
    this.selectedPieceType,
    this.enabled = true,
  });

  @override
  State<PlacementBoardWidget> createState() => _PlacementBoardWidgetState();
}

class _PlacementBoardWidgetState extends State<PlacementBoardWidget>
    with TickerProviderStateMixin {
  /// Posição sendo destacada durante hover/drag.
  PosicaoTabuleiro? _highlightedPosition;

  /// Peça sendo arrastada atualmente.
  String? _draggingPieceId;

  /// Controller para animações de feedback visual.
  AnimationController? _feedbackController;

  /// Animation para pulso de erro.
  Animation<double>? _errorPulseAnimation;

  /// Controller para animações de hover.
  AnimationController? _hoverController;

  /// Animation para efeito de hover.
  Animation<double>? _hoverAnimation;

  /// Posição com erro de validação.
  PosicaoTabuleiro? _errorPosition;

  /// Mensagem de erro atual.
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _feedbackController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _errorPulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _feedbackController!, curve: Curves.elasticOut),
    );

    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _hoverAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _hoverController!, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _feedbackController?.dispose();
    _hoverController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = math.min(constraints.maxWidth, constraints.maxHeight);
        final cellSize = size / 10;

        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Colors.brown[100],
            border: Border.all(color: Colors.brown[800]!, width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Stack(
            children: [
              // Background do tabuleiro
              _buildBackground(),

              // Grid do tabuleiro
              _buildGrid(cellSize),

              // Área do jogador destacada
              _buildPlayerAreaHighlight(cellSize),

              // Zonas de drop válidas
              if (widget.selectedPieceType != null && widget.enabled)
                ..._buildDropZones(cellSize),

              // Peças posicionadas
              ..._buildPlacedPieces(cellSize),

              // Feedback visual para posição destacada
              if (_highlightedPosition != null)
                _buildPositionHighlight(cellSize),

              // Overlay de erro
              if (_errorPosition != null && _errorMessage != null)
                _buildErrorOverlay(cellSize),
            ],
          ),
        );
      },
    );
  }

  /// Constrói o background do tabuleiro.
  Widget _buildBackground() {
    return Positioned.fill(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.asset(
          'assets/images/board_background.png',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(color: Colors.brown[100]);
          },
        ),
      ),
    );
  }

  /// Constrói o grid do tabuleiro.
  Widget _buildGrid(double cellSize) {
    return CustomPaint(
      size: Size(cellSize * 10, cellSize * 10),
      painter: PlacementBoardGridPainter(cellSize),
    );
  }

  /// Constrói o destaque da área do jogador.
  Widget _buildPlayerAreaHighlight(double cellSize) {
    return CustomPaint(
      size: Size(cellSize * 10, cellSize * 10),
      painter: PlayerAreaHighlightPainter(
        cellSize: cellSize,
        playerArea: widget.playerArea,
        enabled: widget.enabled,
      ),
    );
  }

  /// Constrói as zonas de drop válidas quando uma peça está selecionada.
  List<Widget> _buildDropZones(double cellSize) {
    final dropZones = <Widget>[];

    for (int row = 0; row < 10; row++) {
      for (int col = 0; col < 10; col++) {
        final position = PosicaoTabuleiro(linha: row, coluna: col);
        final validationResult = _validateDropPosition(position);

        // Mostra zona de drop para posições válidas
        if (validationResult.isValid) {
          dropZones.add(_buildDropZone(position, cellSize, true));
        }
        // Mostra feedback visual para posições inválidas na área do jogador
        else if (widget.playerArea.contains(position.linha)) {
          dropZones.add(_buildDropZone(position, cellSize, false));
        }
      }
    }

    return dropZones;
  }

  /// Constrói uma zona de drop individual.
  Widget _buildDropZone(
    PosicaoTabuleiro position,
    double cellSize,
    bool isValid,
  ) {
    final left = position.coluna * cellSize;
    final top = position.linha * cellSize;
    final isHighlighted = _highlightedPosition == position;
    final isError = _errorPosition == position;

    return Positioned(
      left: left,
      top: top,
      width: cellSize,
      height: cellSize,
      child: DragTarget<String>(
        onWillAcceptWithDetails: (details) {
          final validation = _validateDropPosition(position);
          setState(() {
            _highlightedPosition = position;
            if (!validation.isValid) {
              _errorPosition = position;
              _errorMessage = validation.errorMessage;
            } else {
              _errorPosition = null;
              _errorMessage = null;
            }
          });
          return validation.isValid;
        },
        onLeave: (details) {
          setState(() {
            _highlightedPosition = null;
            _errorPosition = null;
            _errorMessage = null;
          });
        },
        onAcceptWithDetails: (details) {
          _handlePieceDrop(details.data, position);
          setState(() {
            _highlightedPosition = null;
            _errorPosition = null;
            _errorMessage = null;
          });
        },
        builder: (context, candidateData, rejectedData) {
          return MouseRegion(
            onEnter: (_) => _startHoverAnimation(),
            onExit: (_) => _stopHoverAnimation(),
            child: GestureDetector(
              onTap: () => _handlePositionTap(position),
              child: AnimatedBuilder(
                animation: _hoverAnimation!,
                builder: (context, child) {
                  return Transform.scale(
                    scale: isHighlighted ? _hoverAnimation!.value : 1.0,
                    child: Container(
                      margin: EdgeInsets.all(cellSize * 0.1),
                      decoration: BoxDecoration(
                        color: _getDropZoneColor(
                          isValid,
                          isHighlighted,
                          isError,
                        ),
                        borderRadius: BorderRadius.circular(cellSize * 0.1),
                        border: Border.all(
                          color: _getDropZoneBorderColor(
                            isValid,
                            isHighlighted,
                            isError,
                          ),
                          width: isHighlighted || isError ? 3 : 2,
                        ),
                      ),
                      child: Icon(
                        _getDropZoneIcon(isValid, isError),
                        color: _getDropZoneIconColor(isValid, isError),
                        size: cellSize * 0.4,
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  /// Constrói as peças já posicionadas no tabuleiro.
  List<Widget> _buildPlacedPieces(double cellSize) {
    final pieces = <Widget>[];

    for (final peca in widget.placedPieces) {
      // Só mostra peças da equipe do jogador local
      if (peca.equipe != widget.playerTeam) continue;

      final left = peca.posicao.coluna * cellSize;
      final top = peca.posicao.linha * cellSize;
      final isDragging = _draggingPieceId == peca.id;

      if (!isDragging) {
        pieces.add(_buildPlacedPiece(peca, left, top, cellSize));
      }
    }

    return pieces;
  }

  /// Constrói uma peça posicionada individual.
  Widget _buildPlacedPiece(
    PecaJogo peca,
    double left,
    double top,
    double cellSize,
  ) {
    return Positioned(
      left: left,
      top: top,
      width: cellSize,
      height: cellSize,
      child: Draggable<String>(
        data: peca.id,
        feedback: _buildDragFeedback(peca, cellSize),
        childWhenDragging: _buildDragPlaceholder(cellSize),
        onDragStarted: () {
          setState(() {
            _draggingPieceId = peca.id;
          });
        },
        onDragEnd: (details) {
          setState(() {
            _draggingPieceId = null;
            _highlightedPosition = null;
          });
        },
        child: GestureDetector(
          onTap: () => _handlePieceTap(peca),
          onLongPress: () => _handlePieceRemove(peca),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(cellSize * 0.1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: PecaJogoWidget(
              peca: peca,
              estaSelecionada: false,
              ehDoJogadorAtual: true,
              ehVezDoJogadorLocal: true,
              ehMovimentoValido: false,
              onPecaTap: (_) => _handlePieceTap(peca),
              cellSize: cellSize,
            ),
          ),
        ),
      ),
    );
  }

  /// Constrói o feedback visual durante o drag.
  Widget _buildDragFeedback(PecaJogo peca, double cellSize) {
    return Transform.scale(
      scale: 1.2,
      child: Container(
        width: cellSize,
        height: cellSize,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(cellSize * 0.1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: PecaJogoWidget(
          peca: peca,
          estaSelecionada: false,
          ehDoJogadorAtual: true,
          ehVezDoJogadorLocal: true,
          ehMovimentoValido: false,
          onPecaTap: (_) {},
          cellSize: cellSize,
        ),
      ),
    );
  }

  /// Constrói o placeholder quando a peça está sendo arrastada.
  Widget _buildDragPlaceholder(double cellSize) {
    return Container(
      margin: EdgeInsets.all(cellSize * 0.1),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(cellSize * 0.1),
        border: Border.all(
          color: Colors.grey.withValues(alpha: 0.5),
          width: 2,
          style: BorderStyle.solid,
        ),
      ),
      child: Icon(
        Icons.drag_indicator,
        color: Colors.grey.withValues(alpha: 0.7),
        size: cellSize * 0.4,
      ),
    );
  }

  /// Constrói o destaque da posição durante hover.
  Widget _buildPositionHighlight(double cellSize) {
    final position = _highlightedPosition!;
    final left = position.coluna * cellSize;
    final top = position.linha * cellSize;

    return Positioned(
      left: left,
      top: top,
      width: cellSize,
      height: cellSize,
      child: AnimatedBuilder(
        animation: _hoverAnimation!,
        builder: (context, child) {
          return Transform.scale(
            scale: _hoverAnimation!.value,
            child: Container(
              margin: EdgeInsets.all(cellSize * 0.05),
              decoration: BoxDecoration(
                color: MilitaryThemeWidgets.primaryGreen.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(cellSize * 0.1),
                border: Border.all(
                  color: MilitaryThemeWidgets.primaryGreen,
                  width: 3,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Constrói o overlay de erro com animação.
  Widget _buildErrorOverlay(double cellSize) {
    final position = _errorPosition!;
    final left = position.coluna * cellSize;
    final top = position.linha * cellSize;

    return Positioned(
      left: left,
      top: top,
      width: cellSize,
      height: cellSize,
      child: AnimatedBuilder(
        animation: _errorPulseAnimation!,
        builder: (context, child) {
          return Transform.scale(
            scale: _errorPulseAnimation!.value,
            child: Container(
              margin: EdgeInsets.all(cellSize * 0.05),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(cellSize * 0.1),
                border: Border.all(color: Colors.red, width: 3),
              ),
              child: Icon(
                Icons.error_outline,
                color: Colors.red,
                size: cellSize * 0.5,
              ),
            ),
          );
        },
      ),
    );
  }

  /// Valida uma posição para drop com mensagem de erro detalhada.
  ValidationResult _validateDropPosition(PosicaoTabuleiro position) {
    // Converte Map<String, int> para Map<Patente, int>
    final availablePiecesEnum = <Patente, int>{};
    widget.inventory.availablePieces.forEach((key, value) {
      final patente = Patente.values.firstWhere(
        (p) => p.name == key,
        orElse: () => Patente.soldado, // fallback
      );
      availablePiecesEnum[patente] = value;
    });

    // Usa o sistema de validação centralizado
    final result = PlacementErrorHandler.validatePlacementOperation(
      position: position,
      playerArea: widget.playerArea,
      selectedPiece: widget.selectedPieceType,
      availablePieces: availablePiecesEnum,
      placedPieces: widget.placedPieces,
    );

    if (result.isSuccess) {
      return ValidationResult(isValid: true);
    } else {
      return ValidationResult(
        isValid: false,
        errorMessage: result.error!.userMessage,
      );
    }
  }

  /// Manipula o tap em uma posição do tabuleiro.
  void _handlePositionTap(PosicaoTabuleiro position) {
    if (!widget.enabled) return;

    final validation = _validateDropPosition(position);
    if (validation.isValid) {
      widget.onPositionTap(position);
    } else {
      _showInvalidPositionFeedback(validation.errorMessage);
    }
  }

  /// Manipula o drop de uma peça.
  void _handlePieceDrop(String pieceId, PosicaoTabuleiro position) {
    if (!widget.enabled) return;

    final validation = _validateDropPosition(position);
    if (validation.isValid) {
      widget.onPieceDrag(pieceId, position);
    } else {
      _showInvalidPositionFeedback(validation.errorMessage);
    }
  }

  /// Manipula o tap em uma peça posicionada.
  void _handlePieceTap(PecaJogo peca) {
    if (!widget.enabled) return;

    // Implementar lógica de seleção/movimento de peça se necessário
    // Por enquanto, permite remoção via long press
  }

  /// Manipula a remoção de uma peça.
  void _handlePieceRemove(PecaJogo peca) {
    if (!widget.enabled) return;

    widget.onPieceRemove(peca.id);
  }

  /// Mostra feedback visual para posição inválida.
  void _showInvalidPositionFeedback([String? message]) {
    _feedbackController?.forward().then((_) {
      _feedbackController?.reverse();
    });

    // Mostra mensagem de erro
    final errorMsg = message ?? _errorMessage ?? 'Posição inválida';
    _showErrorSnackBar(errorMsg);

    // Feedback háptico para posição inválida
    HapticFeedback.lightImpact();
  }

  /// Inicia animação de hover.
  void _startHoverAnimation() {
    _hoverController?.forward();
  }

  /// Para animação de hover.
  void _stopHoverAnimation() {
    _hoverController?.reverse();
  }

  /// Retorna a cor da zona de drop baseada no estado.
  Color _getDropZoneColor(bool isValid, bool isHighlighted, bool isError) {
    if (isError) {
      return Colors.red.withValues(alpha: 0.3);
    }
    if (!isValid) {
      return Colors.orange.withValues(alpha: 0.2);
    }
    if (isHighlighted) {
      return MilitaryThemeWidgets.primaryGreen.withValues(alpha: 0.4);
    }
    return MilitaryThemeWidgets.primaryGreen.withValues(alpha: 0.2);
  }

  /// Retorna a cor da borda da zona de drop.
  Color _getDropZoneBorderColor(
    bool isValid,
    bool isHighlighted,
    bool isError,
  ) {
    if (isError) {
      return Colors.red;
    }
    if (!isValid) {
      return Colors.orange;
    }
    return MilitaryThemeWidgets.primaryGreen;
  }

  /// Retorna o ícone da zona de drop.
  IconData _getDropZoneIcon(bool isValid, bool isError) {
    if (isError) {
      return Icons.error_outline;
    }
    if (!isValid) {
      return Icons.warning_outlined;
    }
    return Icons.add_circle_outline;
  }

  /// Retorna a cor do ícone da zona de drop.
  Color _getDropZoneIconColor(bool isValid, bool isError) {
    if (isError) {
      return Colors.red;
    }
    if (!isValid) {
      return Colors.orange;
    }
    return MilitaryThemeWidgets.primaryGreen;
  }

  /// Mostra uma snackbar com mensagem de erro.
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

/// Painter para o grid do tabuleiro de posicionamento.
class PlacementBoardGridPainter extends CustomPainter {
  final double cellSize;

  PlacementBoardGridPainter(this.cellSize);

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.2)
      ..strokeWidth = 0.5;

    // Desenha linhas verticais
    for (int i = 0; i <= 10; i++) {
      final x = i * cellSize;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    // Desenha linhas horizontais
    for (int i = 0; i <= 10; i++) {
      final y = i * cellSize;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Desenha lagos
    final lakePaint = Paint()
      ..color = Colors.blue.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    final lakeStrokePaint = Paint()
      ..color = Colors.blue.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final lakes = [
      const PosicaoTabuleiro(linha: 4, coluna: 2),
      const PosicaoTabuleiro(linha: 4, coluna: 3),
      const PosicaoTabuleiro(linha: 5, coluna: 2),
      const PosicaoTabuleiro(linha: 5, coluna: 3),
      const PosicaoTabuleiro(linha: 4, coluna: 6),
      const PosicaoTabuleiro(linha: 4, coluna: 7),
      const PosicaoTabuleiro(linha: 5, coluna: 6),
      const PosicaoTabuleiro(linha: 5, coluna: 7),
    ];

    for (final lake in lakes) {
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          lake.coluna * cellSize + 2,
          lake.linha * cellSize + 2,
          cellSize - 4,
          cellSize - 4,
        ),
        const Radius.circular(4),
      );
      canvas.drawRRect(rect, lakePaint);
      canvas.drawRRect(rect, lakeStrokePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Painter para destacar a área do jogador.
class PlayerAreaHighlightPainter extends CustomPainter {
  final double cellSize;
  final List<int> playerArea;
  final bool enabled;

  PlayerAreaHighlightPainter({
    required this.cellSize,
    required this.playerArea,
    required this.enabled,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!enabled) return;

    final highlightPaint = Paint()
      ..color = MilitaryThemeWidgets.primaryGreen.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = MilitaryThemeWidgets.primaryGreen.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (final row in playerArea) {
      final rect = Rect.fromLTWH(0, row * cellSize, size.width, cellSize);

      canvas.drawRect(rect, highlightPaint);
      canvas.drawRect(rect, borderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Resultado da validação de posicionamento.
class ValidationResult {
  /// Se a posição é válida.
  final bool isValid;

  /// Mensagem de erro se a posição não for válida.
  final String? errorMessage;

  const ValidationResult({required this.isValid, this.errorMessage});
}
