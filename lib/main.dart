import 'package:combatentes/ui/tela_nome_usuario.dart';
import 'package:combatentes/ui/tela_jogo.dart';
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
        // Se já tem nome, vai direto para o jogo
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const TelaJogo()),
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
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.military_tech, size: 80, color: Colors.white),
              SizedBox(height: 24),
              Text(
                'COMBATENTES',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 3,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Jogo de Estratégia Multiplayer',
                style: TextStyle(fontSize: 16, color: Colors.white70),
              ),
              SizedBox(height: 40),
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
