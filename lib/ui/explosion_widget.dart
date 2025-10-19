import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Widget que exibe uma animação de explosão simples
class ExplosionWidget extends StatefulWidget {
  final VoidCallback? onComplete;
  final double size;

  const ExplosionWidget({super.key, this.onComplete, this.size = 120.0});

  @override
  State<ExplosionWidget> createState() => _ExplosionWidgetState();
}

class _ExplosionWidgetState extends State<ExplosionWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 3.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutQuart));

    _opacityAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
      ),
    );

    // Adiciona feedback tátil (vibração)
    HapticFeedback.heavyImpact();

    _controller.forward().then((_) {
      if (widget.onComplete != null) {
        widget.onComplete!();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
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
                    Colors.yellow,
                    Colors.orange,
                    Colors.red,
                    Colors.red.withValues(alpha: 0.0),
                  ],
                  stops: const [0.0, 0.2, 0.4, 0.7, 1.0],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.orange.withValues(alpha: 0.8),
                    blurRadius: 30,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  '💥',
                  style: TextStyle(fontSize: widget.size * 0.4),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Widget overlay que mostra a explosão sobre o tabuleiro
class ExplosionOverlay extends StatelessWidget {
  final double left;
  final double top;
  final VoidCallback onComplete;

  const ExplosionOverlay({
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
      child: ExplosionWidget(size: 120, onComplete: onComplete),
    );
  }
}
