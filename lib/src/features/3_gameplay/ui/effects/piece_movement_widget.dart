import 'package:flutter/material.dart';
import 'dart:math' as math;

import 'package:combatentes/src/common/models/modelos_jogo.dart';

/// Widget que anima o movimento de uma peça no tabuleiro
class PieceMovementWidget extends StatefulWidget {
  final PecaJogo peca;
  final PosicaoTabuleiro posicaoInicial;
  final PosicaoTabuleiro posicaoFinal;
  final double cellSize;
  final double boardSize;
  final VoidCallback? onComplete;
  final Duration duration;

  const PieceMovementWidget({
    super.key,
    required this.peca,
    required this.posicaoInicial,
    required this.posicaoFinal,
    required this.cellSize,
    required this.boardSize,
    this.onComplete,
    this.duration = const Duration(milliseconds: 800),
  });

  @override
  State<PieceMovementWidget> createState() => _PieceMovementWidgetState();
}

class _PieceMovementWidgetState extends State<PieceMovementWidget>
    with TickerProviderStateMixin {
  late AnimationController _moveController;
  late AnimationController _dustController;
  late Animation<double> _moveAnimation;
  late Animation<double> _dustAnimation;

  final List<DustParticle> _dustParticles = [];

  @override
  void initState() {
    super.initState();

    _moveController = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _dustController = AnimationController(
      duration: Duration(milliseconds: widget.duration.inMilliseconds + 500),
      vsync: this,
    );

    _moveAnimation = CurvedAnimation(
      parent: _moveController,
      curve: Curves.easeInOutBack,
    );

    _dustAnimation = CurvedAnimation(
      parent: _dustController,
      curve: Curves.easeOut,
    );

    // Inicia as animações
    _moveController.forward().then((_) {
      if (widget.onComplete != null) {
        widget.onComplete!();
      }
    });

    _dustController.forward();

    // Cria partículas de poeira ao longo do caminho
    _createDustParticles();
  }

  void _createDustParticles() {
    // Calcula a distância em células do tabuleiro
    final distanceCells = math.sqrt(
      math.pow(widget.posicaoFinal.coluna - widget.posicaoInicial.coluna, 2) +
          math.pow(widget.posicaoFinal.linha - widget.posicaoInicial.linha, 2),
    );

    // Cria partículas ao longo do caminho
    final numParticles = (distanceCells * 3).round().clamp(3, 10);

    for (int i = 0; i < numParticles; i++) {
      final progress = i / (numParticles - 1);

      // Posição relativa no caminho (em coordenadas de célula)
      final cellX =
          widget.posicaoInicial.coluna +
          (widget.posicaoFinal.coluna - widget.posicaoInicial.coluna) *
              progress;
      final cellY =
          widget.posicaoInicial.linha +
          (widget.posicaoFinal.linha - widget.posicaoInicial.linha) * progress;

      // Adiciona variação aleatória
      final random = math.Random();
      final offsetX = (random.nextDouble() - 0.5) * 0.3; // Offset em células
      final offsetY = (random.nextDouble() - 0.5) * 0.3;

      _dustParticles.add(
        DustParticle(
          cellX: cellX + offsetX,
          cellY: cellY + offsetY,
          delay: Duration(
            milliseconds: (progress * widget.duration.inMilliseconds * 0.8)
                .round(),
          ),
          size: 3.0 + random.nextDouble() * 4.0,
        ),
      );
    }
  }

  @override
  void dispose() {
    _moveController.dispose();
    _dustController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_moveAnimation, _dustAnimation]),
      builder: (context, child) {
        // Usa o mesmo sistema de coordenadas das explosões
        final screenSize = MediaQuery.of(context).size;
        final availableHeight =
            screenSize.height -
            kToolbarHeight -
            MediaQuery.of(context).padding.top;
        final centerX = screenSize.width / 2;
        final centerY =
            kToolbarHeight +
            MediaQuery.of(context).padding.top +
            availableHeight / 2;

        // Calcula posições inicial e final baseadas no centro do tabuleiro
        final startOffsetX =
            (widget.posicaoInicial.coluna - 4.5) * widget.cellSize;
        final startOffsetY =
            (widget.posicaoInicial.linha - 4.5) * widget.cellSize;
        final endOffsetX = (widget.posicaoFinal.coluna - 4.5) * widget.cellSize;
        final endOffsetY = (widget.posicaoFinal.linha - 4.5) * widget.cellSize;

        final startX = centerX + startOffsetX - widget.cellSize / 2;
        final startY = centerY + startOffsetY - widget.cellSize / 2;
        final endX = centerX + endOffsetX - widget.cellSize / 2;
        final endY = centerY + endOffsetY - widget.cellSize / 2;

        final currentX = startX + (endX - startX) * _moveAnimation.value;
        final currentY = startY + (endY - startY) * _moveAnimation.value;

        return Stack(
          children: [
            // Rastro de poeira
            ..._dustParticles.map(
              (particle) => _buildDustParticle(
                particle,
                centerX,
                centerY,
                widget.cellSize,
              ),
            ),

            // Peça em movimento
            Positioned(
              left: currentX,
              top: currentY,
              child: Container(
                width: widget.cellSize,
                height: widget.cellSize,
                decoration: BoxDecoration(
                  color: widget.peca.equipe == Equipe.preta
                      ? Colors.grey[800]
                      : Colors.green[700],
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      spreadRadius: 2,
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: EdgeInsets.all(widget.cellSize * 0.08),
                  child: ColorFiltered(
                    colorFilter: ColorFilter.mode(
                      Colors.white.withValues(alpha: 0.9),
                      BlendMode.modulate,
                    ),
                    child: Image.asset(
                      widget.peca.patente.imagePath,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.error,
                          color: Colors.red,
                          size: widget.cellSize * 0.5,
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDustParticle(
    DustParticle particle,
    double centerX,
    double centerY,
    double cellSize,
  ) {
    final delayProgress =
        (_dustController.value * _dustController.duration!.inMilliseconds -
            particle.delay.inMilliseconds) /
        (_dustController.duration!.inMilliseconds -
            particle.delay.inMilliseconds);

    if (delayProgress < 0) return const SizedBox.shrink();

    final opacity = (1.0 - delayProgress).clamp(0.0, 1.0);
    final scale = 0.5 + delayProgress * 0.5;

    // Converte coordenadas de célula para coordenadas de tela
    final offsetX = (particle.cellX - 4.5) * cellSize;
    final offsetY = (particle.cellY - 4.5) * cellSize;
    final screenX = centerX + offsetX;
    final screenY = centerY + offsetY;

    return Positioned(
      left: screenX - particle.size / 2,
      top: screenY - particle.size / 2,
      child: Transform.scale(
        scale: scale,
        child: Container(
          width: particle.size,
          height: particle.size,
          decoration: BoxDecoration(
            gradient: RadialGradient(
              colors: [
                Colors.brown.withValues(alpha: opacity * 0.8),
                Colors.brown.withValues(alpha: opacity * 0.3),
                Colors.brown.withValues(alpha: 0.0),
              ],
              stops: const [0.0, 0.7, 1.0],
            ),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

/// Representa uma partícula de poeira
class DustParticle {
  final double cellX;
  final double cellY;
  final Duration delay;
  final double size;

  DustParticle({
    required this.cellX,
    required this.cellY,
    required this.delay,
    required this.size,
  });
}

/// Widget overlay que mostra o movimento da peça sobre o tabuleiro
class PieceMovementOverlay extends StatelessWidget {
  final PecaJogo peca;
  final PosicaoTabuleiro posicaoInicial;
  final PosicaoTabuleiro posicaoFinal;
  final double boardSize;
  final VoidCallback onComplete;

  const PieceMovementOverlay({
    super.key,
    required this.peca,
    required this.posicaoInicial,
    required this.posicaoFinal,
    required this.boardSize,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    final cellSize = boardSize / 10;

    return Positioned.fill(
      child: PieceMovementWidget(
        peca: peca,
        posicaoInicial: posicaoInicial,
        posicaoFinal: posicaoFinal,
        cellSize: cellSize,
        boardSize: boardSize,
        onComplete: onComplete,
      ),
    );
  }
}
