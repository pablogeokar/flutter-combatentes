import 'package:combatentes/ui/tela_nome_usuario.dart';
import 'package:combatentes/ui/game_flow_screen.dart';
import 'package:combatentes/services/user_preferences.dart';
import 'package:combatentes/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar o serviço de áudio
  await AudioService().initialize();

  // Envolve o aplicativo com ProviderScope para que os providers do Riverpod fiquem disponíveis.
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Combatentes',
      theme: ThemeData(
        primarySwatch: Colors.green,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        useMaterial3: true,
      ),
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

/// Tela de splash que verifica se o usuário já tem nome salvo
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkUserName();
  }

  Future<void> _checkUserName() async {
    // Aguarda um pouco para mostrar o splash
    await Future.delayed(const Duration(milliseconds: 1500));

    final hasName = await UserPreferences.hasUserName();

    if (mounted) {
      if (hasName) {
        // Se já tem nome, vai para o fluxo do jogo (que inclui placement)
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const GameFlowScreen()),
        );
      } else {
        // Se não tem nome, vai para a tela de nome
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const TelaNomeUsuario()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/bg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          // Overlay escuro para melhor legibilidade
          decoration: BoxDecoration(color: Colors.black.withOpacity(0.4)),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo principal do jogo
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Image.asset(
                    'assets/images/logo.png',
                    height: 160,
                    fit: BoxFit.contain,
                  ),
                ),

                const SizedBox(height: 40),

                // Logo de texto
                Image.asset(
                  'assets/images/combatentes.png',
                  height: 70,
                  fit: BoxFit.contain,
                ),

                const SizedBox(height: 16),

                // Subtítulo
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Jogo de Estratégia Multiplayer',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1,
                    ),
                  ),
                ),

                const SizedBox(height: 50),

                // Indicador de carregamento
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(50),
                  ),
                  child: const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    strokeWidth: 3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
