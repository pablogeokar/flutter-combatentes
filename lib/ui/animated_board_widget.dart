import 'package:flutter/material.dart';
import 'dart:math' as math;

import '../modelos_jogo.dart';
import '../providers.dart';

/// Widget de tabuleiro com animações integradas
class AnimatedBoardWidget extends StatefulWidget {
  final EstadoJogo estadoJogo;
  final String? idPecaSelecionada;
  final List<PosicaoTabuleiro> movimentosValidos;
  final Function(String) onPecaTap;
  final Function(PosicaoTabuleiro) onPosicaoTap;
  final String? nomeUsuarioLocal;
  final InformacoesMovimento? movimentoPendente;
  final VoidCallback? onMovementComplete;

  const AnimatedBoardWidget({
    super.key,
    required this.estadoJogo,
    required this.idPecaSelecionada,
    required this.movimentosValidos,
    required this.onPecaTap,
    required this.onPosicaoTap,
    required this.nomeUsuarioLocal,
    this.movimentoPendente,
    this.onMovementComplete,
  });

  @override
  State<AnimatedBoardWidget> createState() => _AnimatedBoardWidgetState();
}

class _AnimatedBoardWidgetState extends State<AnimatedBoardWidget>
    with TickerProviderStateMixin {
  AnimationController? _moveController;
  Animation<double>? _moveAnimation;
  PecaJogo? _movingPiece;
  PosicaoTabuleiro? _fromPosition;
  PosicaoTabuleiro? _toPosition;
  final List<DustParticle> _dustParticles = [];
  AnimationController? _dustController;

  @override
  void initState() {
    super.initState();
    _checkForMovement();
  }

  @override
  void didUpdateWidget(AnimatedBoardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.movimentoPendente != oldWidget.movimentoPendente) {
      _checkForMovement();
    }
  }

  void _checkForMovement() {
    if (widget.movimentoPendente != null && _moveController == null) {
      _startMovementAnimation(widget.movimentoPendente!);
    }
  }

  void _startMovementAnimation(InformacoesMovimento movimento) {
    _movingPiece = movimento.peca;
    _fromPosition = movimento.posicaoInicial;
    _toPosition = movimento.posicaoFinal;

    _moveController = AnimationController(
      duration: const Duration(milliseconds: 800), // Mais lento
      vsync: this,
    );

    _dustController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _moveAnimation = CurvedAnimation(
      parent: _moveController!,
      curve: Curves.easeOutQuart, // Curva que simula arrasto natural
    );

    _createDustParticles();
    _dustController!.forward();

    _moveController!.forward().then((_) {
      if (widget.onMovementComplete != null) {
        widget.onMovementComplete!();
      }
      _resetAnimation();
    });

    setState(() {});
  }

  void _createDustParticles() {
    if (_fromPosition == null || _toPosition == null) return;

    final distance = math.sqrt(
      math.pow(_toPosition!.coluna - _fromPosition!.coluna, 2) +
          math.pow(_toPosition!.linha - _fromPosition!.linha, 2),
    );

    // Cria partículas mais sutis ao longo do caminho
    final numParticles = (distance * 3).round().clamp(2, 6);
    _dustParticles.clear();

    for (int i = 0; i < numParticles; i++) {
      final progress = i / (numParticles - 1);
      final cellX =
          _fromPosition!.coluna +
          (_toPosition!.coluna - _fromPosition!.coluna) * progress;
      final cellY =
          _fromPosition!.linha +
          (_toPosition!.linha - _fromPosition!.linha) * progress;

      final random = math.Random();
      final offsetX = (random.nextDouble() - 0.5) * 0.3;
      final offsetY = (random.nextDouble() - 0.5) * 0.3;

      _dustParticles.add(
        DustParticle(
          cellX: cellX + offsetX,
          cellY: cellY + offsetY,
          delay: Duration(
            milliseconds: (progress * 600).round(),
          ), // Mais espalhado no tempo
          size: 1.5 + random.nextDouble() * 2.0, // Partículas menores
        ),
      );
    }
  }

  void _resetAnimation() {
    _moveController?.dispose();
    _dustController?.dispose();
    _moveController = null;
    _dustController = null;
    _moveAnimation = null;
    _movingPiece = null;
    _fromPosition = null;
    _toPosition = null;
    _dustParticles.clear();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _moveController?.dispose();
    _dustController?.dispose();
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

              // Peças estáticas
              ..._buildStaticPieces(cellSize),

              // Peça em movimento
              if (_movingPiece != null && _moveAnimation != null)
                _buildMovingPiece(cellSize),

              // Partículas de poeira
              if (_dustController != null)
                ..._dustParticles.map(
                  (particle) => _buildDustParticle(particle, cellSize),
                ),

              // Overlay de movimentos válidos
              ..._buildValidMoves(cellSize),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBackground() {
    return Positioned.fill(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.asset(
          'assets/images/board_background.png',
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            // Fallback para cor sólida se a imagem não carregar
            return Container(color: Colors.brown[100]);
          },
        ),
      ),
    );
  }

  Widget _buildGrid(double cellSize) {
    return CustomPaint(
      size: Size(cellSize * 10, cellSize * 10),
      painter: BoardGridPainter(cellSize),
    );
  }

  List<Widget> _buildStaticPieces(double cellSize) {
    final pieces = <Widget>[];

    for (final peca in widget.estadoJogo.pecas) {
      // Não renderiza a peça que está se movendo
      if (_movingPiece != null && peca.id == _movingPiece!.id) {
        continue;
      }

      final left = peca.posicao.coluna * cellSize;
      final top = peca.posicao.linha * cellSize;

      pieces.add(
        Positioned(
          left: left,
          top: top,
          width: cellSize,
          height: cellSize,
          child: GestureDetector(
            onTap: () => widget.onPecaTap(peca.id),
            child: _buildPieceWidget(
              peca: peca,
              estaSelecionada: widget.idPecaSelecionada == peca.id,
            ),
          ),
        ),
      );
    }

    return pieces;
  }

  Widget _buildMovingPiece(double cellSize) {
    if (_fromPosition == null ||
        _toPosition == null ||
        _moveAnimation == null) {
      return const SizedBox.shrink();
    }

    final fromX = _fromPosition!.coluna * cellSize;
    final fromY = _fromPosition!.linha * cellSize;
    final toX = _toPosition!.coluna * cellSize;
    final toY = _toPosition!.linha * cellSize;

    final currentX = fromX + (toX - fromX) * _moveAnimation!.value;
    final currentY = fromY + (toY - fromY) * _moveAnimation!.value;

    return Positioned(
      left: currentX,
      top: currentY,
      width: cellSize,
      height: cellSize,
      child: Transform.scale(
        scale: 1.05, // Ligeiramente maior durante o movimento
        child: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.4),
                blurRadius: 12 + (_moveAnimation!.value * 8), // Sombra dinâmica
                spreadRadius: 3 + (_moveAnimation!.value * 2),
                offset: Offset(
                  0,
                  6 + (_moveAnimation!.value * 4),
                ), // Sombra que se move
              ),
            ],
          ),
          child: Transform.rotate(
            angle: (_moveAnimation!.value - 0.5) * 0.05, // Rotação mais sutil
            child: _buildPieceWidget(
              peca: _movingPiece!,
              estaSelecionada: false,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDustParticle(DustParticle particle, double cellSize) {
    if (_dustController == null) return const SizedBox.shrink();

    final delayProgress =
        (_dustController!.value * 1000 - particle.delay.inMilliseconds) / 600;
    if (delayProgress < 0) return const SizedBox.shrink();

    final opacity = (1.0 - delayProgress).clamp(0.0, 1.0);
    final scale = 0.3 + delayProgress * 0.7;

    final x = particle.cellX * cellSize;
    final y = particle.cellY * cellSize;

    return Positioned(
      left: x - particle.size / 2,
      top: y - particle.size / 2,
      child: Transform.scale(
        scale: scale,
        child: Container(
          width: particle.size,
          height: particle.size,
          decoration: BoxDecoration(
            gradient: RadialGradient(
              colors: [
                Colors.brown.withValues(alpha: opacity * 0.6),
                Colors.brown.withValues(alpha: opacity * 0.2),
                Colors.brown.withValues(alpha: 0.0),
              ],
            ),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  List<Widget> _buildValidMoves(double cellSize) {
    return widget.movimentosValidos.map((posicao) {
      final left = posicao.coluna * cellSize;
      final top = posicao.linha * cellSize;

      return Positioned(
        left: left,
        top: top,
        width: cellSize,
        height: cellSize,
        child: GestureDetector(
          onTap: () => widget.onPosicaoTap(posicao),
          child: Container(
            margin: EdgeInsets.all(cellSize * 0.2),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(cellSize * 0.1),
              border: Border.all(color: Colors.green, width: 2),
            ),
            child: Icon(
              Icons.circle,
              color: Colors.green,
              size: cellSize * 0.3,
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildPieceWidget({
    required PecaJogo peca,
    required bool estaSelecionada,
  }) {
    // Determina se deve mostrar informações da peça
    final bool mostrarInfo = _shouldShowPieceInfo(peca);

    return Container(
      margin: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: peca.equipe == Equipe.preta
            ? Colors.grey[800]
            : Colors.green[700],
        borderRadius: BorderRadius.circular(8),
        border: estaSelecionada
            ? Border.all(color: Colors.yellow, width: 3)
            : Border.all(color: Colors.black26, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(flex: 3, child: _buildPieceImage(peca, mostrarInfo)),
            if (mostrarInfo)
              Expanded(
                flex: 1,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    peca.patente.nome,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 8,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPieceImage(PecaJogo peca, bool mostrarInfo) {
    final bool ehPecaDoJogadorLocal = _isPieceFromLocalPlayer(peca);

    // Só mostra a imagem real para peças do jogador local
    // Peças do adversário sempre mostram silhueta (não revelação permanente)
    if (ehPecaDoJogadorLocal) {
      return ColorFiltered(
        colorFilter: ColorFilter.mode(
          Colors.white.withValues(alpha: 0.9),
          BlendMode.modulate,
        ),
        child: Image.asset(
          peca.patente.imagePath,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Icon(Icons.error, color: Colors.red, size: 20);
          },
        ),
      );
    } else {
      // Para peças do adversário, sempre mostra silhueta
      return Icon(
        Icons.help_outline,
        color: Colors.white.withValues(alpha: 0.7),
        size: 24,
      );
    }
  }

  bool _isPieceFromLocalPlayer(PecaJogo peca) {
    if (widget.nomeUsuarioLocal == null) return false;

    final jogadorLocal = widget.estadoJogo.jogadores.where((jogador) {
      final nomeJogador = jogador.nome.trim().toLowerCase();
      final nomeLocal = widget.nomeUsuarioLocal!.trim().toLowerCase();
      return nomeJogador == nomeLocal ||
          nomeJogador.contains(nomeLocal) ||
          nomeLocal.contains(nomeJogador);
    }).firstOrNull;

    if (jogadorLocal != null) {
      return peca.equipe == jogadorLocal.equipe;
    }

    return false;
  }

  bool _shouldShowPieceInfo(PecaJogo peca) {
    if (widget.nomeUsuarioLocal == null) return false;

    // Só mostra info para peças do jogador local
    return _isPieceFromLocalPlayer(peca);
  }
}

class BoardGridPainter extends CustomPainter {
  final double cellSize;

  BoardGridPainter(this.cellSize);

  @override
  void paint(Canvas canvas, Size size) {
    // Linhas do grid mais sutis sobre a imagem de fundo
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

    // Desenha lagos com transparência
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
