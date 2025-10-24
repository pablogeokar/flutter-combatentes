import 'package:flutter/material.dart';
import 'package:combatentes/src/common/widgets/military_theme_widgets.dart';
import 'package:combatentes/src/common/services/audio_service.dart';

/// Tela de vitória
class VictoryScreen extends StatefulWidget {
  final String playerName;
  final VoidCallback onPlayAgain;
  final VoidCallback onMainMenu;

  const VictoryScreen({
    super.key,
    required this.playerName,
    required this.onPlayAgain,
    required this.onMainMenu,
  });

  @override
  State<VictoryScreen> createState() => _VictoryScreenState();
}

class _VictoryScreenState extends State<VictoryScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Configurar animações
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    // Iniciar animação
    _animationController.forward();

    // Tocar som de vitória
    AudioService().playVictorySound();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MilitaryThemeWidgets.militaryBackground(
        opacity: 0.2,
        child: SafeArea(
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Ilustração de vitória
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.green.withValues(alpha: 0.3),
                                  blurRadius: 30,
                                  offset: const Offset(0, 15),
                                ),
                              ],
                            ),
                            child: Image.asset(
                              'assets/images/vitoria.png',
                              height: 200,
                              fit: BoxFit.contain,
                            ),
                          ),

                          const SizedBox(height: 40),

                          // Título de vitória
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
                              ),
                              borderRadius: BorderRadius.circular(25),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.green.withValues(alpha: 0.4),
                                  blurRadius: 15,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: const Text(
                              '🎉 VITÓRIA! 🎉',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 2,
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Mensagem personalizada
                          MilitaryThemeWidgets.militaryCard(
                            child: Column(
                              children: [
                                Text(
                                  'Parabéns, ${widget.playerName}!',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: MilitaryThemeWidgets.primaryGreen,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'Você demonstrou excelente estratégia militar e conquistou a vitória nesta batalha épica!',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.black87,
                                    height: 1.5,
                                  ),
                                  textAlign: TextAlign.center,
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
                                  text: 'JOGAR NOVAMENTE',
                                  onPressed: widget.onPlayAgain,
                                  icon: Icons.refresh,
                                  backgroundColor: const Color(0xFF4CAF50),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: MilitaryThemeWidgets.militaryButton(
                                  text: 'MENU PRINCIPAL',
                                  onPressed: widget.onMainMenu,
                                  icon: Icons.home,
                                  backgroundColor:
                                      MilitaryThemeWidgets.primaryGreen,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // Logo do jogo
                          MilitaryThemeWidgets.militaryLargeLogo(
                            logoSize: 120,
                            textLogoSize: 40,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Tela de derrota
class DefeatScreen extends StatefulWidget {
  final String playerName;
  final VoidCallback onPlayAgain;
  final VoidCallback onMainMenu;

  const DefeatScreen({
    super.key,
    required this.playerName,
    required this.onPlayAgain,
    required this.onMainMenu,
  });

  @override
  State<DefeatScreen> createState() => _DefeatScreenState();
}

class _DefeatScreenState extends State<DefeatScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Configurar animações
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    // Iniciar animação
    _animationController.forward();

    // Tocar som de derrota
    AudioService().playDefeatSound();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MilitaryThemeWidgets.militaryBackground(
        opacity: 0.3,
        child: SafeArea(
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Ilustração de derrota
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.red.withValues(alpha: 0.3),
                                  blurRadius: 30,
                                  offset: const Offset(0, 15),
                                ),
                              ],
                            ),
                            child: Image.asset(
                              'assets/images/derrota.png',
                              height: 200,
                              fit: BoxFit.contain,
                            ),
                          ),

                          const SizedBox(height: 40),

                          // Título de derrota
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFD32F2F), Color(0xFF8B0000)],
                              ),
                              borderRadius: BorderRadius.circular(25),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.red.withValues(alpha: 0.4),
                                  blurRadius: 15,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: const Text(
                              '💥 DERROTA 💥',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 2,
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Mensagem de encorajamento
                          MilitaryThemeWidgets.militaryCard(
                            child: Column(
                              children: [
                                Text(
                                  'Não desista, ${widget.playerName}!',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFD32F2F),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'Toda derrota é uma oportunidade de aprender. Analise suas estratégias e volte mais forte para a próxima batalha!',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.black87,
                                    height: 1.5,
                                  ),
                                  textAlign: TextAlign.center,
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
                                  text: 'TENTAR NOVAMENTE',
                                  onPressed: widget.onPlayAgain,
                                  icon: Icons.refresh,
                                  backgroundColor: const Color(0xFFD32F2F),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: MilitaryThemeWidgets.militaryButton(
                                  text: 'MENU PRINCIPAL',
                                  onPressed: widget.onMainMenu,
                                  icon: Icons.home,
                                  backgroundColor:
                                      MilitaryThemeWidgets.primaryGreen,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // Logo do jogo
                          MilitaryThemeWidgets.militaryLargeLogo(
                            logoSize: 120,
                            textLogoSize: 40,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
