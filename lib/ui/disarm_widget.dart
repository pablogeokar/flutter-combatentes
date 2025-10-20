import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

/// Widget que exibe uma animação de desarme de mina
class DisarmWidget extends StatefulWidget {
  final VoidCallback? onComplete;
  final double size;

  const DisarmWidget({super.key, this.onComplete, this.size = 120.0});

  @override
  State<DisarmWidget> createState() => _DisarmWidgetState();
}

class _DisarmWidgetState extends State<DisarmWidget>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _toolController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _toolAnimation;

  @override
  void initState() {
    super.initState();

    // Controlador principal da animação
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Controlador para a ferramenta de desarme
    _toolController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Animação de escala (cresce e depois diminui)
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.3, end: 1.2), weight: 30),
      TweenSequenceItem(tween: Tween<double>(begin: 1.2, end: 1.0), weight: 40),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 0.0), weight: 30),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    // Animação de opacidade
    _opacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.7, 1.0, curve: Curves.easeOut),
      ),
    );

    // Animação de rotação para a ferramenta
    _rotationAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _toolController, curve: Curves.easeInOut),
    );

    // Animação da ferramenta (movimento de desarme)
    _toolAnimation =
        TweenSequence<double>([
          TweenSequenceItem(
            tween: Tween<double>(begin: 0.0, end: 1.0),
            weight: 50,
          ),
          TweenSequenceItem(
            tween: Tween<double>(begin: 1.0, end: 0.8),
            weight: 50,
          ),
        ]).animate(
          CurvedAnimation(parent: _toolController, curve: Curves.easeInOut),
        );

    // Adiciona feedback tátil mais suave
    HapticFeedback.mediumImpact();

    // Inicia as animações
    _toolController.forward();
    _controller.forward().then((_) {
      if (widget.onComplete != null) {
        widget.onComplete!();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _toolController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_controller, _toolController]),
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Opacity(
            opacity: _opacityAnimation.value,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white,
                    Colors.lightBlue,
                    Colors.blue,
                    Colors.green,
                    Colors.green.withOpacity(0.0),
                  ],
                  stops: const [0.0, 0.2, 0.4, 0.7, 1.0],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.6),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Ícone da mina sendo desarmada
                  Transform.scale(
                    scale: 0.8 + (_toolAnimation.value * 0.2),
                    child: Text(
                      '💣',
                      style: TextStyle(fontSize: widget.size * 0.3),
                    ),
                  ),

                  // Ferramenta de desarme (chave de fenda)
                  Transform.rotate(
                    angle: _rotationAnimation.value * 6.28, // 2π radianos
                    child: Transform.translate(
                      offset: Offset(
                        widget.size * 0.2 * _toolAnimation.value,
                        -widget.size * 0.1 * _toolAnimation.value,
                      ),
                      child: Text(
                        '🔧',
                        style: TextStyle(fontSize: widget.size * 0.2),
                      ),
                    ),
                  ),

                  // Partículas de sucesso
                  if (_controller.value > 0.5)
                    ...List.generate(6, (index) {
                      final angle = (index * 60) * (3.14159 / 180);
                      final distance =
                          widget.size * 0.4 * (_controller.value - 0.5) * 2;
                      return Transform.translate(
                        offset: Offset(
                          distance * math.cos(angle),
                          distance * math.sin(angle),
                        ),
                        child: Transform.scale(
                          scale: 1.0 - (_controller.value - 0.5) * 2,
                          child: Text(
                            '✨',
                            style: TextStyle(fontSize: widget.size * 0.1),
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Widget overlay que mostra o desarme sobre o tabuleiro
class DisarmOverlay extends StatelessWidget {
  final double left;
  final double top;
  final VoidCallback onComplete;

  const DisarmOverlay({
    super.key,
    required this.left,
    required this.top,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      top: top,
      child: DisarmWidget(size: 120, onComplete: onComplete),
    );
  }
}
