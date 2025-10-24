import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

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
  Timer? _showTimer;
  Timer? _hideTimer;

  @override
  Widget build(BuildContext context) {
    // Detecta se é desktop de forma mais robusta
    final bool isDesktop = _isDesktopPlatform();

    if (!isDesktop) {
      // Para mobile, usa o tooltip nativo do Flutter
      return Tooltip(
        message: widget.message,
        waitDuration: widget.waitDuration,
        showDuration: widget.showDuration,
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        child: widget.child,
      );
    }

    // Para desktop, usa implementação customizada com MouseRegion
    return MouseRegion(
      onEnter: (_) => _onHover(true),
      onExit: (_) => _onHover(false),
      child: widget.child,
    );
  }

  bool _isDesktopPlatform() {
    if (kIsWeb) return true; // Web também pode usar hover

    return defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux;
  }

  void _onHover(bool isHovering) {
    if (_isHovering == isHovering) return;

    _isHovering = isHovering;

    // Cancela timers existentes
    _showTimer?.cancel();
    _hideTimer?.cancel();

    if (isHovering) {
      // Aguarda um pouco antes de mostrar
      _showTimer = Timer(widget.waitDuration, () {
        if (_isHovering && mounted) {
          _showTooltip();
        }
      });
    } else {
      // Esconde imediatamente quando sai do hover
      _hideTooltip();
    }
  }

  void _showTooltip() {
    if (!mounted) return;

    _hideTooltip(); // Remove qualquer tooltip existente

    final overlay = Overlay.of(context);
    final renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final offset = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;
    final screenSize = MediaQuery.of(context).size;

    // Calcula dimensões do tooltip baseado no texto
    final textPainter = TextPainter(
      text: TextSpan(
        text: widget.message,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    final tooltipWidth = textPainter.width + 24; // padding horizontal
    final tooltipHeight = textPainter.height + 16; // padding vertical

    // Posiciona o tooltip
    double left = offset.dx + (size.width / 2) - (tooltipWidth / 2);
    double top = offset.dy - tooltipHeight - 8; // 8px de margem

    // Ajusta se sair da tela horizontalmente
    if (left < 8) {
      left = 8;
    } else if (left + tooltipWidth > screenSize.width - 8) {
      left = screenSize.width - tooltipWidth - 8;
    }

    // Ajusta se sair da tela verticalmente (mostra embaixo)
    if (top < 8) {
      top = offset.dy + size.height + 8;
    }

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: left,
        top: top,
        child: Material(
          color: Colors.transparent,
          child: Container(
            constraints: BoxConstraints(maxWidth: screenSize.width * 0.8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white24, width: 1),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 8,
                  offset: Offset(0, 4),
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

    // Auto-hide após o tempo especificado
    _hideTimer = Timer(widget.showDuration, () {
      if (mounted) {
        _hideTooltip();
      }
    });
  }

  void _hideTooltip() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _hideTimer?.cancel();
  }

  @override
  void dispose() {
    _showTimer?.cancel();
    _hideTimer?.cancel();
    _hideTooltip();
    super.dispose();
  }
}
