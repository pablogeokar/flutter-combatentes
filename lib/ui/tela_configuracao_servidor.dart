import 'package:flutter/material.dart';
import '../services/user_preferences.dart';
import 'military_theme_widgets.dart';

class TelaConfiguracaoServidor extends StatefulWidget {
  const TelaConfiguracaoServidor({super.key});

  @override
  State<TelaConfiguracaoServidor> createState() =>
      _TelaConfiguracaoServidorState();
}

class _TelaConfiguracaoServidorState extends State<TelaConfiguracaoServidor> {
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuração do Servidor'),
        backgroundColor: MilitaryThemeWidgets.primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: MilitaryThemeWidgets.militaryBackground(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Explicação
                      MilitaryThemeWidgets.militaryCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: Colors.blue[700],
                                  size: 24,
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Configuração do Servidor',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Digite o endereço do servidor WebSocket para conectar ao jogo. '
                              'O endereço deve começar com ws:// (não seguro) ou wss:// (seguro).',
                              style: TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Campo de endereço do servidor
                      MilitaryThemeWidgets.militaryTextField(
                        controller: _serverController,
                        labelText: 'Endereço do Servidor',
                        hintText: 'ws://localhost:8083',
                        prefixIcon: Icons.dns,
                        validator: _validateServerAddress,
                      ),

                      const SizedBox(height: 16),

                      // Botão para resetar para padrão
                      TextButton.icon(
                        onPressed: _resetToDefault,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Usar Padrão (localhost:8083)'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.grey[600],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Exemplos
                      MilitaryThemeWidgets.militaryCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.lightbulb_outline,
                                  color: Colors.amber[700],
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  'Exemplos:',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            const Text('• ws://localhost:8083 (local)'),
                            const Text(
                              '• ws://192.168.1.100:8083 (rede local)',
                            ),
                            const Text(
                              '• wss://meuservidor.com:8083 (internet)',
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Botões de ação
                      Row(
                        children: [
                          Expanded(
                            child: MilitaryThemeWidgets.militaryButton(
                              onPressed: () => Navigator.of(context).pop(),
                              text: 'Cancelar',
                              backgroundColor: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: MilitaryThemeWidgets.militaryButton(
                              onPressed: _isSaving ? null : _saveServer,
                              text: 'Salvar',
                              isLoading: _isSaving,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
