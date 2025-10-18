import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../modelos_jogo.dart';

/// Um widget que representa visualmente uma única peça do jogo no tabuleiro.
class PecaJogoWidget extends StatelessWidget {
  /// O modelo de dados da peça a ser renderizada.
  final PecaJogo peca;

  /// Flag para indicar se esta peça está atualmente selecionada pelo jogador.
  final bool estaSelecionada;

  /// Flag para indicar se a peça pertence ao jogador que está controlando o dispositivo.
  final bool ehDoJogadorAtual;

  /// Flag para indicar se é a vez do jogador local.
  final bool ehVezDoJogadorLocal;

  /// Flag para indicar se esta posição é um movimento válido.
  final bool ehMovimentoValido;

  /// Callback acionado quando o usuário toca na peça.
  final Function(String) onPecaTap;

  /// Tamanho da célula para dimensionar a peça corretamente.
  final double cellSize;

  const PecaJogoWidget({
    super.key,
    required this.peca,
    required this.estaSelecionada,
    required this.ehDoJogadorAtual,
    required this.ehVezDoJogadorLocal,
    required this.ehMovimentoValido,
    required this.onPecaTap,
    required this.cellSize,
  });

  @override
  Widget build(BuildContext context) {
    // Determina a cor da peça com base na equipe.
    final Color corDaEquipe = peca.equipe == Equipe.preta
        ? Colors.grey[800]!
        : Colors.green[700]!;

    // Calcula o tamanho da fonte baseado no tamanho da célula
    final double fontSize = (cellSize * 0.12).clamp(8.0, 14.0);
    final double borderRadius = cellSize * 0.1;
    final double margin = cellSize * 0.05;

    // Lógica para decidir o que renderizar dentro da peça.
    Widget conteudoPeca;
    if (ehDoJogadorAtual || peca.foiRevelada) {
      // Se a peça é do jogador atual ou já foi revelada, mostra a patente.
      conteudoPeca = Padding(
        padding: EdgeInsets.all(cellSize * 0.08),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            peca.patente.nome,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: fontSize,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );
    } else {
      // Caso contrário, mostra o "verso" da peça com ícone da equipe.
      conteudoPeca = Icon(
        Icons.military_tech,
        color: Colors.white.withValues(alpha: 0.8),
        size: cellSize * 0.4,
      );
    }

    // Determina se a peça pode ser clicada
    final bool podeSerClicada = ehDoJogadorAtual && ehVezDoJogadorLocal;
    final bool podeSerAtacada = ehMovimentoValido && !ehDoJogadorAtual;
    final bool habilitarClique = podeSerClicada || podeSerAtacada;

    // Determina o cursor baseado nas condições
    final SystemMouseCursor cursor = habilitarClique
        ? SystemMouseCursors.click
        : SystemMouseCursors.basic;

    return MouseRegion(
      cursor: cursor,
      child: GestureDetector(
        onTap: habilitarClique ? () => onPecaTap(peca.id) : null,
        child: Container(
          width: cellSize,
          height: cellSize,
          margin: EdgeInsets.all(margin),
          decoration: BoxDecoration(
            color: ehMovimentoValido
                ? Colors.red.withValues(
                    alpha: 0.8,
                  ) // Peça inimiga que pode ser atacada
                : habilitarClique
                ? corDaEquipe
                : corDaEquipe.withValues(
                    alpha: 0.6,
                  ), // Peça desabilitada mais transparente
            borderRadius: BorderRadius.circular(borderRadius),
            border: estaSelecionada
                ? Border.all(color: Colors.yellow[400]!, width: 2)
                : ehMovimentoValido
                ? Border.all(color: Colors.red, width: 2)
                : Border.all(
                    color: Colors.black.withValues(alpha: 0.5),
                    width: 1,
                  ),
            boxShadow: habilitarClique
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      spreadRadius: 1,
                      blurRadius: 2,
                      offset: const Offset(1, 1),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      spreadRadius: 0,
                      blurRadius: 1,
                      offset: const Offset(0, 0),
                    ),
                  ], // Sombra mais sutil para peças desabilitadas
          ),
          child: Stack(
            children: [
              Center(
                child: Opacity(
                  opacity: habilitarClique
                      ? 1.0
                      : 0.5, // Reduz opacidade quando desabilitada
                  child: conteudoPeca,
                ),
              ),
              if (ehMovimentoValido)
                Positioned(
                  top: 2,
                  right: 2,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
