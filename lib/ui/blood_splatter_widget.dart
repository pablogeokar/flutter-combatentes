import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;

/// Widget que exibe uma animação de respingo de sangue na tela
class BloodSplatterWidget extends StatefulWidget {
  final VoidCallback? onComplete;
  final double intensity;

  const BloodSplatterWidget({super.key, this.onComplete, this.intensity = 1.0});

  @override
  State<BloodSplatterWidget> createState() => _BloodSplatterWidgetState();
}

class _BloodSplatterWidgetState extends State<BloodSplatterWidget>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _dripsController;
  late Animation<double> _splashAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _dripsAnimation;

  final List<BloodDrop> _bloodDrops = [];
  final math.Random _random = math.Random();

  @override
  void initState() {
    super.initState();

    // Controlador principal da animação
    _mainController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Controlador para os pingos que escorrem
    _dripsController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Animação do respingo inicial (expansão rápida)
    _splashAnimation =
        TweenSequence<double>([
          TweenSequenceItem(
            tween: Tween<double>(begin: 0.0, end: 1.0),
            weight: 30,
          ),
          TweenSequenceItem(
            tween: Tween<double>(begin: 1.0, end: 0.8),
            weight: 70,
          ),
        ]).animate(
          CurvedAnimation(parent: _mainController, curve: Curves.easeOutQuart),
        );

    // Animação de fade out
    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
      ),
    );

    // Animação dos pingos escorrendo
    _dripsAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _dripsController, curve: Curves.easeOut));

    // Feedback tátil forte
    HapticFeedback.heavyImpact();

    // Completa após todas as animações
    _mainController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (widget.onComplete != null && mounted) {
            widget.onComplete!();
          }
        });
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Gera gotas de sangue aleatórias (agora que MediaQuery está disponível)
    if (_bloodDrops.isEmpty) {
      _generateBloodDrops();

      // Inicia as animações
      _mainController.forward();
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          _dripsController.forward();
        }
      });
    }
  }

  void _generateBloodDrops() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Gera entre 15-25 gotas dependendo da intensidade
    final dropCount = (15 + (_random.nextInt(10) * widget.intensity)).round();

    for (int i = 0; i < dropCount; i++) {
      _bloodDrops.add(
        BloodDrop(
          startX: screenWidth * 0.3 + _random.nextDouble() * screenWidth * 0.4,
          startY:
              screenHeight * 0.2 + _random.nextDouble() * screenHeight * 0.3,
          endX: _random.nextDouble() * screenWidth,
          endY: screenHeight * 0.7 + _random.nextDouble() * screenHeight * 0.3,
          size: 8 + _random.nextDouble() * 20 * widget.intensity,
          delay: _random.nextDouble() * 0.5,
          speed: 0.5 + _random.nextDouble() * 1.0,
        ),
      );
    }
  }

  @override
  void dispose() {
    _mainController.dispose();
    _dripsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_mainController, _dripsController]),
      builder: (context, child) {
        return Positioned.fill(
          child: IgnorePointer(
            child: Container(
              color: Colors.transparent,
              child: CustomPaint(
                painter: BloodSplatterPainter(
                  splashProgress: _splashAnimation.value,
                  fadeOpacity: _fadeAnimation.value,
                  dripsProgress: _dripsAnimation.value,
                  bloodDrops: _bloodDrops,
                  intensity: widget.intensity,
                ),
                size: Size.infinite,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Classe que representa uma gota de sangue individual
class BloodDrop {
  final double startX;
  final double startY;
  final double endX;
  final double endY;
  final double size;
  final double delay;
  final double speed;

  BloodDrop({
    required this.startX,
    required this.startY,
    required this.endX,
    required this.endY,
    required this.size,
    required this.delay,
    required this.speed,
  });
}

/// Painter customizado para desenhar o efeito de sangue
class BloodSplatterPainter extends CustomPainter {
  final double splashProgress;
  final double fadeOpacity;
  final double dripsProgress;
  final List<BloodDrop> bloodDrops;
  final double intensity;

  BloodSplatterPainter({
    required this.splashProgress,
    required this.fadeOpacity,
    required this.dripsProgress,
    required this.bloodDrops,
    required this.intensity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Pinta o respingo principal
    _paintMainSplash(canvas, size);

    // Pinta as gotas escorrendo
    _paintDrippingDrops(canvas, size);

    // Pinta respingos menores
    _paintSmallSplatters(canvas, size);
  }

  void _paintMainSplash(Canvas canvas, Size size) {
    if (splashProgress <= 0) return;

    final paint = Paint()
      ..color = Color.lerp(
        const Color(0xFF8B0000), // Vermelho escuro
        const Color(0xFFDC143C), // Vermelho carmesim
        splashProgress,
      )!.withOpacity(fadeOpacity * 0.8)
      ..style = PaintingStyle.fill;

    // Respingo principal no centro-superior da tela
    final centerX = size.width * 0.5;
    final centerY = size.height * 0.3;
    final radius = 60 * splashProgress * intensity;

    // Desenha o respingo principal com forma irregular
    final path = Path();
    final points = 12;
    for (int i = 0; i < points; i++) {
      final angle = (i * 2 * math.pi) / points;
      final variation = 0.7 + (math.sin(angle * 3) * 0.3);
      final x = centerX + math.cos(angle) * radius * variation;
      final y = centerY + math.sin(angle) * radius * variation;

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    canvas.drawPath(path, paint);
  }

  void _paintDrippingDrops(Canvas canvas, Size size) {
    if (dripsProgress <= 0) return;

    final paint = Paint()
      ..color = const Color(0xFF8B0000).withOpacity(fadeOpacity * 0.9)
      ..style = PaintingStyle.fill;

    for (final drop in bloodDrops) {
      final adjustedProgress = ((dripsProgress - drop.delay) * drop.speed)
          .clamp(0.0, 1.0);
      if (adjustedProgress <= 0) continue;

      final currentX =
          drop.startX + (drop.endX - drop.startX) * adjustedProgress;
      final currentY =
          drop.startY + (drop.endY - drop.startY) * adjustedProgress;

      // Desenha a gota com cauda
      final dropPath = Path();
      dropPath.addOval(
        Rect.fromCircle(
          center: Offset(currentX, currentY),
          radius: drop.size * (1.0 - adjustedProgress * 0.3),
        ),
      );

      // Adiciona cauda da gota
      if (adjustedProgress > 0.2) {
        final tailLength = drop.size * 2 * adjustedProgress;
        dropPath.addOval(
          Rect.fromLTWH(currentX - 2, currentY - tailLength, 4, tailLength),
        );
      }

      canvas.drawPath(dropPath, paint);
    }
  }

  void _paintSmallSplatters(Canvas canvas, Size size) {
    if (splashProgress <= 0) return;

    final paint = Paint()
      ..color = const Color(0xFF8B0000).withOpacity(fadeOpacity * 0.6)
      ..style = PaintingStyle.fill;

    final random = math.Random(42); // Seed fixo para consistência

    // Pequenos respingos ao redor do principal
    for (int i = 0; i < (20 * intensity).round(); i++) {
      final angle = random.nextDouble() * 2 * math.pi;
      final distance = 100 + random.nextDouble() * 200;
      final x = size.width * 0.5 + math.cos(angle) * distance * splashProgress;
      final y = size.height * 0.3 + math.sin(angle) * distance * splashProgress;
      final radius = (3 + random.nextDouble() * 8) * splashProgress;

      canvas.drawCircle(Offset(x, y), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Widget overlay que mostra o sangue sobre toda a tela
class BloodSplatterOverlay extends StatelessWidget {
  final VoidCallback onComplete;
  final double intensity;

  const BloodSplatterOverlay({
    super.key,
    required this.onComplete,
    this.intensity = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return BloodSplatterWidget(onComplete: onComplete, intensity: intensity);
  }
}
