import 'package:flutter/material.dart';
import '../modelos_jogo.dart';
import './peca_widget.dart';

/// O widget que renderiza a grade do tabuleiro e as peças contidas nele.
class TabuleiroWidget extends StatelessWidget {
  /// O estado atual do jogo, contendo a lista de peças.
  final EstadoJogo estadoJogo;

  /// O ID da peça que está atualmente selecionada pelo jogador.
  final String? idPecaSelecionada;

  /// Callback para quando uma peça é tocada.
  final Function(String) onPecaTap;

  /// Callback para quando uma posição vazia no tabuleiro é tocada.
  final Function(PosicaoTabuleiro) onPosicaoTap;

  const TabuleiroWidget({
    super.key,
    required this.estadoJogo,
    required this.idPecaSelecionada,
    required this.onPecaTap,
    required this.onPosicaoTap,
  });

  @override
  Widget build(BuildContext context) {
    // Cria um mapa de posições para peças para acesso rápido.
    final Map<String, PecaJogo> pecasPorPosicao = {
      for (var peca in estadoJogo.pecas)
        '${peca.posicao.linha}-${peca.posicao.coluna}': peca,
    };

    return GridView.builder(
      padding: const EdgeInsets.all(8.0),
      physics:
          const NeverScrollableScrollPhysics(), // O tabuleiro em si não deve rolar.
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 10, // O tabuleiro de Combate tem 10 colunas.
      ),
      itemCount: 100, // E 100 células (10x10).
      itemBuilder: (context, index) {
        final int linha = index ~/ 10;
        final int coluna = index % 10;
        final PosicaoTabuleiro posicaoAtual = PosicaoTabuleiro(
          linha: linha,
          coluna: coluna,
        );
        final String chavePosicao = '$linha-$coluna';

        final PecaJogo? peca = pecasPorPosicao[chavePosicao];

        if (peca != null) {
          // Se existe uma peça nesta posição, renderiza o PecaJogoWidget.
          final bool ehDoJogadorAtual =
              estadoJogo.jogadores
                  .firstWhere((j) => j.id == estadoJogo.idJogadorDaVez)
                  .equipe ==
              peca.equipe;

          return PecaJogoWidget(
            peca: peca,
            estaSelecionada: idPecaSelecionada == peca.id,
            ehDoJogadorAtual: ehDoJogadorAtual,
            onPecaTap: onPecaTap,
          );
        } else {
          // Se não há peça, renderiza uma célula vazia que pode ser tocada.
          return GestureDetector(
            onTap: () => onPosicaoTap(posicaoAtual),
            child: Container(
              margin: const EdgeInsets.all(2.0),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
          );
        }
      },
    );
  }
}
