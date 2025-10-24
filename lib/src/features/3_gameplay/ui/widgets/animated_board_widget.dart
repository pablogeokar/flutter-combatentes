import 'package:flutter/material.dart';
import 'dart:math' as math;

import 'package:combatentes/src/common/models/modelos_jogo.dart';
import 'package:combatentes/src/common/models/game_state_models.dart';

import 'peca_widget.dart';

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
          child: PecaJogoWidget(
            peca: peca,
            estaSelecionada: widget.idPecaSelecionada == peca.id,
            ehDoJogadorAtual: _isPieceFromLocalPlayer(peca),
            ehVezDoJogadorLocal: _isLocalPlayerTurn(),
            ehMovimentoValido: false, // Não é um movimento válido, é uma peça
            onPecaTap: widget.onPecaTap,
            cellSize: cellSize,
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
                color: Colors.black.withOpacity(0.4),
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
            child: PecaJogoWidget(
              peca: _movingPiece!,
              estaSelecionada: false,
              ehDoJogadorAtual: _isPieceFromLocalPlayer(_movingPiece!),
              ehVezDoJogadorLocal: _isLocalPlayerTurn(),
              ehMovimentoValido: false,
              onPecaTap: widget.onPecaTap,
              cellSize: cellSize,
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
                Colors.brown.withOpacity(opacity * 0.6),
                Colors.brown.withOpacity(opacity * 0.2),
                Colors.brown.withOpacity(0.0),
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
              color: Colors.green.withOpacity(0.3),
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

  bool _isLocalPlayerTurn() {
    if (widget.nomeUsuarioLocal == null) return false;

    final jogadorLocal = widget.estadoJogo.jogadores.where((jogador) {
      final nomeJogador = jogador.nome.trim().toLowerCase();
      final nomeLocal = widget.nomeUsuarioLocal!.trim().toLowerCase();
      return nomeJogador == nomeLocal ||
          nomeJogador.contains(nomeLocal) ||
          nomeLocal.contains(nomeJogador);
    }).firstOrNull;

    if (jogadorLocal != null) {
      return widget.estadoJogo.idJogadorDaVez == jogadorLocal.id;
    }

    return false;
  }
}

class BoardGridPainter extends CustomPainter {
  final double cellSize;

  BoardGridPainter(this.cellSize);

  @override
  void paint(Canvas canvas, Size size) {
    // Linhas do grid mais sutis sobre a imagem de fundo
    final gridPaint = Paint()
      ..color = Colors.black.withOpacity(0.2)
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
      ..color = Colors.blue.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    final lakeStrokePaint = Paint()
      ..color = Colors.blue.withOpacity(0.6)
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
