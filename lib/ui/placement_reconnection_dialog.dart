import 'package:flutter/material.dart';
import '../placement_error_handler.dart';

/// Dialog para gerenciar reconexão durante a fase de posicionamento.
class PlacementReconnectionDialog extends StatefulWidget {
  /// Erro que causou a necessidade de reconexão.
  final PlacementError error;

  /// Callback para tentar reconectar.
  final Future<bool> Function() onReconnect;

  /// Callback para cancelar e retornar ao menu.
  final VoidCallback onCancel;

  /// Se deve mostrar opção de continuar offline.
  final bool showOfflineOption;

  const PlacementReconnectionDialog({
    super.key,
    required this.error,
    required this.onReconnect,
    required this.onCancel,
    this.showOfflineOption = false,
  });

  @override
  State<PlacementReconnectionDialog> createState() =>
      _PlacementReconnectionDialogState();
}

class _PlacementReconnectionDialogState
    extends State<PlacementReconnectionDialog> {
  bool _isReconnecting = false;
  int _attemptCount = 0;
  String _statusMessage = '';

  @override
  void initState() {
    super.initState();
    _statusMessage = widget.error.userMessage;
  }

  Future<void> _handleReconnect() async {
    if (_isReconnecting) return;

    setState(() {
      _isReconnecting = true;
      _attemptCount++;
      _statusMessage = 'Tentativa $_attemptCount: Reconectando...';
    });

    try {
      final success = await widget.onReconnect();

      if (mounted) {
        if (success) {
          // Reconexão bem-sucedida, fecha dialog
          Navigator.of(context).pop(true);
        } else {
          setState(() {
            _isReconnecting = false;
            _statusMessage = 'Falha na reconexão. Tente novamente.';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isReconnecting = false;
          _statusMessage = 'Erro na reconexão: ${e.toString()}';
        });
      }
    }
  }

  void _handleCancel() {
    widget.onCancel();
    Navigator.of(context).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isReconnecting,
      child: AlertDialog(
        title: Row(
          children: [
            Icon(_getErrorIcon(), color: _getErrorColor()),
            const SizedBox(width: 8),
            const Text('Problema de Conexão'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_statusMessage, style: Theme.of(context).textTheme.bodyMedium),
            if (_isReconnecting) ...[
              const SizedBox(height: 16),
              const LinearProgressIndicator(),
              const SizedBox(height: 8),
              Text('Aguarde...', style: Theme.of(context).textTheme.bodySmall),
            ],
            if (widget.error.type ==
                PlacementErrorType.opponentDisconnected) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Colors.orange[700],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'O oponente desconectou. Você pode aguardar a reconexão ou retornar ao menu.',
                        style: TextStyle(
                          color: Colors.orange[700],
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (!_isReconnecting) ...[
            TextButton(onPressed: _handleCancel, child: const Text('Cancelar')),
            if (widget.error.type != PlacementErrorType.opponentDisconnected)
              ElevatedButton(
                onPressed: _handleReconnect,
                child: Text(
                  _attemptCount == 0 ? 'Reconectar' : 'Tentar Novamente',
                ),
              ),
            if (widget.error.type == PlacementErrorType.opponentDisconnected)
              ElevatedButton(
                onPressed: _handleCancel,
                child: const Text('Voltar ao Menu'),
              ),
          ] else ...[
            ElevatedButton(
              onPressed: null,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).disabledColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text('Reconectando...'),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  IconData _getErrorIcon() {
    switch (widget.error.type) {
      case PlacementErrorType.networkError:
        return Icons.wifi_off;
      case PlacementErrorType.opponentDisconnected:
        return Icons.person_off;
      case PlacementErrorType.timeout:
        return Icons.access_time;
      default:
        return Icons.error_outline;
    }
  }

  Color _getErrorColor() {
    switch (widget.error.type) {
      case PlacementErrorType.networkError:
        return Colors.red;
      case PlacementErrorType.opponentDisconnected:
        return Colors.orange;
      case PlacementErrorType.timeout:
        return Colors.amber;
      default:
        return Colors.red;
    }
  }
}

/// Mostra dialog de reconexão e retorna resultado.
Future<bool?> showPlacementReconnectionDialog(
  BuildContext context, {
  required PlacementError error,
  required Future<bool> Function() onReconnect,
  required VoidCallback onCancel,
  bool showOfflineOption = false,
}) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => PlacementReconnectionDialog(
      error: error,
      onReconnect: onReconnect,
      onCancel: onCancel,
      showOfflineOption: showOfflineOption,
    ),
  );
}
