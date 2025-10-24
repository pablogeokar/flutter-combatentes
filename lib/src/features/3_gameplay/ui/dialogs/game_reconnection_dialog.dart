import 'package:flutter/material.dart';

/// Dialog para reconexão durante partidas ativas.
/// Oferece opções para tentar reconectar ou voltar ao menu.
class GameReconnectionDialog extends StatefulWidget {
  final String title;
  final String message;
  final VoidCallback? onReconnect;
  final VoidCallback? onBackToMenu;
  final bool showReconnectOption;
  final bool isReconnecting;

  const GameReconnectionDialog({
    super.key,
    required this.title,
    required this.message,
    this.onReconnect,
    this.onBackToMenu,
    this.showReconnectOption = true,
    this.isReconnecting = false,
  });

  @override
  State<GameReconnectionDialog> createState() => _GameReconnectionDialogState();
}

class _GameReconnectionDialogState extends State<GameReconnectionDialog>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (widget.isReconnecting) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(GameReconnectionDialog oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isReconnecting && !oldWidget.isReconnecting) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.isReconnecting && oldWidget.isReconnecting) {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => !widget.isReconnecting,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: const Color(0xFF2E7D32),
        title: Text(
          widget.title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Ícone de status
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: widget.isReconnecting ? _pulseAnimation.value : 1.0,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: widget.isReconnecting
                          ? Colors.orange.withOpacity(0.2)
                          : Colors.red.withOpacity(0.2),
                      border: Border.all(
                        color: widget.isReconnecting
                            ? Colors.orange
                            : Colors.red,
                        width: 3,
                      ),
                    ),
                    child: Icon(
                      widget.isReconnecting
                          ? Icons.wifi_protected_setup
                          : Icons.wifi_off,
                      size: 40,
                      color: widget.isReconnecting ? Colors.orange : Colors.red,
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            // Mensagem
            Text(
              widget.message,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),

            if (widget.isReconnecting) ...[
              const SizedBox(height: 20),
              const LinearProgressIndicator(
                backgroundColor: Colors.white24,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
              ),
              const SizedBox(height: 10),
              const Text(
                'Tentando reconectar...',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.orange,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
        actions: widget.isReconnecting
            ? [] // Sem ações durante reconexão
            : [
                // Botão Voltar ao Menu
                if (widget.onBackToMenu != null)
                  TextButton.icon(
                    onPressed: widget.onBackToMenu!,
                    icon: const Icon(Icons.home, color: Colors.white),
                    label: const Text(
                      'Voltar ao Menu',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.grey[700],
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                  ),

                // Botão Tentar Reconectar
                if (widget.showReconnectOption && widget.onReconnect != null)
                  TextButton.icon(
                    onPressed: widget.onReconnect!,
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    label: const Text(
                      'Tentar Reconectar',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.green[700],
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                  ),
              ],
      ),
    );
  }
}

/// Mostra dialog de reconexão com opções personalizadas.
Future<GameReconnectionResult?> showGameReconnectionDialog({
  required BuildContext context,
  required String title,
  required String message,
  bool showReconnectOption = true,
  bool barrierDismissible = false,
}) async {
  return await showDialog<GameReconnectionResult>(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (context) => GameReconnectionDialog(
      title: title,
      message: message,
      showReconnectOption: showReconnectOption,
      onReconnect: () {
        Navigator.of(context).pop(GameReconnectionResult.reconnect);
      },
      onBackToMenu: () {
        Navigator.of(context).pop(GameReconnectionResult.backToMenu);
      },
    ),
  );
}

/// Mostra dialog de reconexão em progresso.
void showReconnectingDialog({
  required BuildContext context,
  required String message,
}) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => GameReconnectionDialog(
      title: 'Reconectando',
      message: message,
      isReconnecting: true,
      showReconnectOption: false,
    ),
  );
}

/// Resultado da ação do usuário no dialog de reconexão.
enum GameReconnectionResult { reconnect, backToMenu }
