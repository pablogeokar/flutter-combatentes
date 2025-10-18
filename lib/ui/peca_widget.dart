import 'package:flutter/material.dart';
import '../modelos_jogo.dart';

/// Um widget que representa visualmente uma única peça do jogo no tabuleiro.
class PecaJogoWidget extends StatelessWidget {
  /// O modelo de dados da peça a ser renderizada.
  final PecaJogo peca;

  /// Flag para indicar se esta peça está atualmente selecionada pelo jogador.
  final bool estaSelecionada;

  /// Flag para indicar se a peça pertence ao jogador que está controlando o dispositivo.
  final bool ehDoJogadorAtual;

  /// Callback acionado quando o usuário toca na peça.
  final Function(String) onPecaTap;

  const PecaJogoWidget({
    super.key,
    required this.peca,
    required this.estaSelecionada,
    required this.ehDoJogadorAtual,
    required this.onPecaTap,
  });

  @override
  Widget build(BuildContext context) {
    // Determina a cor da peça com base na equipe.
    final Color corDaEquipe = peca.equipe == Equipe.preta
        ? Colors.grey[800]!
        : Colors.green[700]!;

    // Lógica para decidir o que renderizar dentro da peça.
    Widget conteudoPeca;
    if (ehDoJogadorAtual || peca.foiRevelada) {
      // Se a peça é do jogador atual ou já foi revelada, mostra a patente.
      conteudoPeca = Text(
        peca.patente.nome,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      );
    } else {
      // Caso contrário, mostra o "verso" da peça, apenas com a cor da equipe.
      conteudoPeca = Container(); // Vazio, apenas a cor de fundo será visível.
    }

    return GestureDetector(
      onTap: () => onPecaTap(peca.id),
      child: Container(
        margin: const EdgeInsets.all(2.0),
        decoration: BoxDecoration(
          color: corDaEquipe,
          borderRadius: BorderRadius.circular(8.0),
          border: estaSelecionada
              ? Border.all(
                  color: Colors.yellow[400]!,
                  width: 3,
                ) // Destaque se selecionada
              : Border.all(color: Colors.black.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              spreadRadius: 1,
              blurRadius: 3,
              offset: const Offset(2, 2),
            ),
          ],
        ),
        child: Center(child: conteudoPeca),
      ),
    );
  }
}
