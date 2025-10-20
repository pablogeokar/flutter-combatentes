import 'package:flutter/material.dart';
import '../services/user_preferences.dart';
import 'game_flow_screen.dart';
import 'military_theme_widgets.dart';
import 'server_config_dialog.dart';

/// Tela para o usuário inserir seu nome
class TelaNomeUsuario extends StatefulWidget {
  const TelaNomeUsuario({super.key});

  @override
  State<TelaNomeUsuario> createState() => _TelaNomeUsuarioState();
}

class _TelaNomeUsuarioState extends State<TelaNomeUsuario> {
  final TextEditingController _nomeController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _carregarNomeSalvo();
  }

  Future<void> _carregarNomeSalvo() async {
    final nomeSalvo = await UserPreferences.getUserName();
    if (nomeSalvo != null && nomeSalvo.isNotEmpty) {
      _nomeController.text = nomeSalvo;
    }
  }

  Future<void> _salvarEContinuar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await UserPreferences.saveUserName(_nomeController.text.trim());

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const GameFlowScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar nome: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _showServerConfig() async {
    await showDialog(
      context: context,
      builder: (context) => const ServerConfigDialog(),
    );
  }

  @override
  void dispose() {
    _nomeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MilitaryThemeWidgets.militaryBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: MilitaryThemeWidgets.militaryCard(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header militar com logos
                      MilitaryThemeWidgets.militaryHeader(
                        subtitle: 'Jogo de Estratégia Multiplayer',
                      ),
                      const SizedBox(height: 32),

                      // Campo de nome
                      MilitaryThemeWidgets.militaryTextField(
                        controller: _nomeController,
                        labelText: 'Seu Nome',
                        hintText: 'Digite seu nome de jogador',
                        prefixIcon: Icons.person,
                        textCapitalization: TextCapitalization.words,
                        maxLength: 20,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Por favor, digite seu nome';
                          }
                          if (value.trim().length < 2) {
                            return 'Nome deve ter pelo menos 2 caracteres';
                          }
                          return null;
                        },
                        onFieldSubmitted: (_) => _salvarEContinuar(),
                      ),
                      const SizedBox(height: 24),

                      // Botão de continuar
                      MilitaryThemeWidgets.militaryButton(
                        text: 'ENTRAR NO JOGO',
                        onPressed: _salvarEContinuar,
                        icon: Icons.play_arrow,
                        isLoading: _isLoading,
                        width: double.infinity,
                      ),
                      const SizedBox(height: 12),

                      // Botão de configuração do servidor
                      TextButton.icon(
                        onPressed: _isLoading ? null : _showServerConfig,
                        icon: const Icon(Icons.dns, size: 18),
                        label: const Text('Configurar Servidor'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Informações adicionais
                      Text(
                        'Seu nome será usado para identificá-lo durante as partidas',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
