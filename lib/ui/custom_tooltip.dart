import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

/// Tooltip customizado que funciona melhor em widgets complexos
class CustomTooltip extends StatefulWidget {
  final Widget child;
  final String message;
  final Duration waitDuration;
  final Duration showDuration;

  const CustomTooltip({
    super.key,
    required this.child,
    required this.message,
    this.waitDuration = const Duration(milliseconds: 500),
    this.showDuration = const Duration(seconds: 2),
  });

  @override
  State<CustomTooltip> createState() => _CustomTooltipState();
}

class _CustomTooltipState extends State<CustomTooltip> {
  OverlayEntry? _overlayEntry;
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final bool isDesktop =
        !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.macOS ||
            defaultTargetPlatform == TargetPlatform.linux);

    if (!isDesktop) {
      // Para mobile, usa o tooltip nativo
      return Tooltip(
        message: widget.message,
        waitDuration: widget.waitDuration,
        showDuration: widget.showDuration,
        child: widget.child,
      );
    }

    // Para desktop, usa implementação customizada
    return MouseRegion(
      onEnter: (_) => _onHover(true),
      onExit: (_) => _onHover(false),
      child: widget.child,
    );
  }

  void _onHover(bool isHovering) {
    if (_isHovering == isHovering) return;

    _isHovering = isHovering;

    if (isHovering) {
      _showTooltip();
    } else {
      _hideTooltip();
    }
  }

  void _showTooltip() {
    _hideTooltip(); // Remove qualquer tooltip existente

    final overlay = Overlay.of(context);
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final offset = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    // Calcula posição para centralizar o tooltip
    final tooltipWidth =
        widget.message.length * 8.0 + 24; // Estimativa da largura
    final screenWidth = MediaQuery.of(context).size.width;
    final left = (offset.dx + size.width / 2 - tooltipWidth / 2).clamp(
      8.0,
      screenWidth - tooltipWidth - 8,
    );

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: left,
        top: offset.dy - 50, // Posiciona acima da peça
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              widget.message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );

    overlay.insert(_overlayEntry!);
  }

  void _hideTooltip() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  void dispose() {
    _hideTooltip();
    super.dispose();
  }
}
