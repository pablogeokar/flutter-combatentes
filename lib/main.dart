import 'package:combatentes/ui/tela_nome_usuario.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
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
      home: const TelaNomeUsuario(),
      debugShowCheckedModeBanner: false,
    );
  }
}
