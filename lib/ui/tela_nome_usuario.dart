import 'package:flutter/material.dart';
import '../services/user_preferences.dart';
import 'tela_jogo.dart';

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
          MaterialPageRoute(builder: (context) => const TelaJogo()),
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

  @override
  void dispose() {
    _nomeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF2E7D32), // Verde escuro
              Color(0xFF4CAF50), // Verde médio
              Color(0xFF81C784), // Verde claro
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Logo/Título
                        const Icon(
                          Icons.military_tech,
                          size: 64,
                          color: Color(0xFF2E7D32),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'COMBATENTES',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2E7D32),
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Jogo de Estratégia Multiplayer',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Campo de nome
                        TextFormField(
                          controller: _nomeController,
                          decoration: InputDecoration(
                            labelText: 'Seu Nome',
                            hintText: 'Digite seu nome de jogador',
                            prefixIcon: const Icon(Icons.person),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFF2E7D32),
                                width: 2,
                              ),
                            ),
                          ),
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
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _salvarEContinuar,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2E7D32),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 4,
                            ),
                            child: _isLoading
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
                                    'ENTRAR NO JOGO',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Informações adicionais
                        Text(
                          'Seu nome será usado para identificá-lo durante as partidas',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
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
