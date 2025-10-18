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
    final nomeUsuario = uiState.nomeUsuario;

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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Combatentes',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (nomeUsuario != null)
              Text(
                'Jogador: $nomeUsuario',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.normal,
                ),
              ),
          ],
        ),
        backgroundColor: const Color(0xFF2E7D32),
        foregroundColor: Colors.white,
        actions: [
          if (estadoJogo != null)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Center(child: _buildGameStatus(estadoJogo, nomeUsuario)),
            ),
        ],
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
            Column(
              children: [
                // Informações da partida
                _buildGameInfo(estadoJogo, nomeUsuario),
                // Tabuleiro
                Expanded(
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: 1.0,
                      child: TabuleiroWidget(
                        estadoJogo: estadoJogo,
                        idPecaSelecionada: uiState.idPecaSelecionada,
                        onPecaTap: (idPeca) => ref
                            .read(gameStateProvider.notifier)
                            .selecionarPeca(idPeca),
                        onPosicaoTap: (posicao) => ref
                            .read(gameStateProvider.notifier)
                            .moverPeca(posicao),
                      ),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  /// Constrói o widget de status do jogo no AppBar
  Widget _buildGameStatus(EstadoJogo estado, String? nomeUsuario) {
    final jogadorDaVez = estado.jogadores.firstWhere(
      (j) => j.id == estado.idJogadorDaVez,
    );

    final bool ehMinhVez =
        nomeUsuario != null && jogadorDaVez.nome.contains(nomeUsuario);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: ehMinhVez ? Colors.green : Colors.orange,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        ehMinhVez ? 'Sua vez!' : 'Vez do oponente',
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  /// Constrói as informações da partida
  Widget _buildGameInfo(EstadoJogo estado, String? nomeUsuario) {
    return Container(
      margin: const EdgeInsets.all(8.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildPlayerInfo(estado.jogadores[0], estado, nomeUsuario),
          const Text(
            'VS',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          _buildPlayerInfo(estado.jogadores[1], estado, nomeUsuario),
        ],
      ),
    );
  }

  /// Constrói as informações de um jogador
  Widget _buildPlayerInfo(
    Jogador jogador,
    EstadoJogo estado,
    String? nomeUsuario,
  ) {
    final bool ehEuMesmo =
        nomeUsuario != null && jogador.nome.contains(nomeUsuario);
    final bool ehVez = jogador.id == estado.idJogadorDaVez;
    final int pecasRestantes = estado.pecas
        .where((p) => p.equipe == jogador.equipe)
        .length;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: ehVez ? Colors.green.withValues(alpha: 0.3) : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        border: ehEuMesmo ? Border.all(color: Colors.yellow, width: 2) : null,
      ),
      child: Column(
        children: [
          Text(
            jogador.nome,
            style: TextStyle(
              color: Colors.white,
              fontWeight: ehEuMesmo ? FontWeight.bold : FontWeight.normal,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: jogador.equipe == Equipe.preta
                      ? Colors.grey[800]
                      : Colors.green[700],
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '$pecasRestantes peças',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
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
