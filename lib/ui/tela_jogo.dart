import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../modelos_jogo.dart';
import '../providers.dart';
import './tabuleiro_widget.dart';

/// A tela principal do jogo, agora como um ConsumerWidget que reage às mudanças de estado do Riverpod.
class TelaJogo extends ConsumerWidget {
  const TelaJogo({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Assiste a mudanças no estado do jogo.
    final uiState = ref.watch(gameStateProvider);
    final estadoJogo = uiState.estadoJogo;

    // Escuta por mudanças de estado para mostrar dialogs ou snackbars, sem reconstruir o widget.
    ref.listen<TelaJogoState>(gameStateProvider, (previous, next) {
      // Mostra uma mensagem de erro se uma ocorrer.
      if (next.erro != null && (previous?.erro != next.erro)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(next.erro!), backgroundColor: Colors.red),
        );
      }
      // Mostra o diálogo de fim de jogo quando a partida termina.
      if (next.estadoJogo?.jogoTerminou == true &&
          previous?.estadoJogo?.jogoTerminou == false) {
        _mostrarDialogoFimDeJogo(context, next.estadoJogo!, ref);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Combate (Multiplayer)'),
        backgroundColor: Colors.grey[900],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/board_background.png',
              fit: BoxFit.cover,
            ),
          ),
          // Mostra um indicador de carregamento enquanto conecta ou o estado é nulo
          if (estadoJogo == null)
            const Center(
              child: Card(
                color: Colors.black54,
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text(
                        'Conectando ao servidor...',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            // Mostra o tabuleiro quando o estado estiver disponível
            Center(
              child: AspectRatio(
                aspectRatio: 1.0,
                child: TabuleiroWidget(
                  estadoJogo: estadoJogo,
                  idPecaSelecionada: uiState.idPecaSelecionada,
                  // Ao tocar numa peça, chama o método do notifier.
                  onPecaTap: (idPeca) => ref
                      .read(gameStateProvider.notifier)
                      .selecionarPeca(idPeca),
                  // Ao tocar numa posição, chama o método do notifier.
                  onPosicaoTap: (posicao) =>
                      ref.read(gameStateProvider.notifier).moverPeca(posicao),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Mostra um diálogo de fim de jogo.
  void _mostrarDialogoFimDeJogo(
    BuildContext context,
    EstadoJogo estadoFinal,
    WidgetRef ref,
  ) {
    final vencedor = estadoFinal.jogadores.firstWhere(
      (j) => j.id == estadoFinal.idVencedor,
    );
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("Fim de Jogo!"),
        content: Text(
          "O jogador ${vencedor.nome} (${vencedor.equipe.name}) venceu!",
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }
}
