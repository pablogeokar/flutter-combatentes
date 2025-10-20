import 'package:flutter/material.dart';
import '../services/user_preferences.dart';
import 'military_theme_widgets.dart';

class ServerConfigDialog extends StatefulWidget {
  const ServerConfigDialog({super.key});

  @override
  State<ServerConfigDialog> createState() => _ServerConfigDialogState();
}

class _ServerConfigDialogState extends State<ServerConfigDialog> {
  final _formKey = GlobalKey<FormState>();
  final _serverController = TextEditingController();
  bool _isLoading = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentServer();
  }

  Future<void> _loadCurrentServer() async {
    setState(() => _isLoading = true);
    try {
      final currentServer = await UserPreferences.getServerAddress();
      _serverController.text = currentServer;
    } catch (e) {
      _serverController.text = 'ws://localhost:8083';
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveServer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      await UserPreferences.saveServerAddress(_serverController.text.trim());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Endereço do servidor salvo com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true); // Retorna true indicando que salvou
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  String? _validateServerAddress(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Por favor, digite o endereço do servidor';
    }

    final trimmed = value.trim();

    // Verifica se começa com ws:// ou wss://
    if (!trimmed.startsWith('ws://') && !trimmed.startsWith('wss://')) {
      return 'Endereço deve começar com ws:// ou wss://';
    }

    // Verifica se tem pelo menos um domínio/IP após o protocolo
    final withoutProtocol = trimmed.replaceFirst(RegExp(r'^wss?://'), '');
    if (withoutProtocol.isEmpty) {
      return 'Endereço inválido';
    }

    return null;
  }

  void _resetToDefault() {
    _serverController.text = 'ws://localhost:8083';
  }

  @override
  void dispose() {
    _serverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.dns, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'Configuração do Servidor',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 20,
                      ),
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: _isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Explicação
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.blue[200]!),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    color: Colors.blue[700],
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Text(
                                      'Digite o endereço do servidor WebSocket para conectar ao jogo. '
                                      'O endereço deve começar com ws:// (não seguro) ou wss:// (seguro).',
                                      style: TextStyle(fontSize: 14),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Campo de endereço do servidor com melhor contraste
                            TextFormField(
                              controller: _serverController,
                              validator: _validateServerAddress,
                              style: const TextStyle(
                                color: Colors.black87,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                              decoration: InputDecoration(
                                labelText: 'Endereço do Servidor',
                                hintText: 'ws://localhost:8083',
                                prefixIcon: Icon(
                                  Icons.dns,
                                  color: MilitaryThemeWidgets.primaryGreen,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: Colors.grey[400]!,
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: Colors.grey[400]!,
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(
                                    color: MilitaryThemeWidgets.primaryGreen,
                                    width: 2,
                                  ),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                    color: Colors.red,
                                    width: 2,
                                  ),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: const BorderSide(
                                    color: Colors.red,
                                    width: 2,
                                  ),
                                ),
                                filled: true,
                                fillColor: Colors.white,
                                labelStyle: TextStyle(color: Colors.grey[700]),
                                hintStyle: TextStyle(color: Colors.grey[500]),
                              ),
                            ),

                            const SizedBox(height: 12),

                            // Botão para resetar para padrão
                            TextButton.icon(
                              onPressed: _resetToDefault,
                              icon: const Icon(Icons.refresh, size: 18),
                              label: const Text('Usar Padrão (localhost:8083)'),
                              style: TextButton.styleFrom(
                                foregroundColor:
                                    MilitaryThemeWidgets.primaryGreen,
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Exemplos
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.amber[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.amber[200]!),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.lightbulb_outline,
                                        color: Colors.amber[700],
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'Exemplos:',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    '• ws://localhost:8083 (local)\n'
                                    '• ws://192.168.1.100:8083 (rede local)\n'
                                    '• wss://meuservidor.com:8083 (internet)',
                                    style: TextStyle(fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),

            // Footer com botões
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.05),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
                border: Border(
                  top: BorderSide(
                    color: Colors.grey.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: Colors.grey[400]!),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _saveServer,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black.withValues(alpha: 0.8),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 2,
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text(
                              'Salvar',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
