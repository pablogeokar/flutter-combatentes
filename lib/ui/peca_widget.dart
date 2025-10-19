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
    if (ehDoJogadorAtual) {
      // Se a peça é do jogador atual, mostra a imagem ocupando quase toda a área.
      conteudoPeca = Padding(
        padding: EdgeInsets.all(cellSize * 0.04), // Reduzido de 0.08 para 0.04
        child: ColorFiltered(
          colorFilter: ColorFilter.mode(
            Colors.white.withValues(alpha: 0.9),
            BlendMode.modulate,
          ),
          child: Image.asset(
            peca.patente.imagePath,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              // Fallback para texto se a imagem falhar
              return FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  peca.patente.nome,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: fontSize,
                  ),
                  textAlign: TextAlign.center,
                ),
              );
            },
          ),
        ),
      );
    } else {
      // Caso contrário, mostra o "verso" da peça com design militar.
      conteudoPeca = Padding(
        padding: EdgeInsets.all(cellSize * 0.1),
        child: Icon(
          Icons.military_tech,
          color: Colors.white.withValues(alpha: 0.9),
          size: cellSize * 0.6,
        ),
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

    return Tooltip(
      message: ehDoJogadorAtual
          ? '${peca.patente.nome} (Força: ${peca.patente.forca})'
          : 'Peça Inimiga',
      waitDuration: const Duration(milliseconds: 500),
      showDuration: const Duration(seconds: 2),
      textStyle: const TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: MouseRegion(
        cursor: cursor,
        child: GestureDetector(
          onTap: habilitarClique ? () => onPecaTap(peca.id) : null,
          onLongPress: ehDoJogadorAtual
              ? () {
                  // Mostra informações detalhadas em dispositivos móveis
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${peca.patente.nome} - Força: ${peca.patente.forca}',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      duration: const Duration(seconds: 2),
                      backgroundColor: peca.equipe == Equipe.preta
                          ? Colors.grey[800]
                          : Colors.green[700],
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  );
                }
              : null,
          child: Container(
            width: cellSize,
            height: cellSize,
            margin: EdgeInsets.all(margin),
            decoration: BoxDecoration(
              gradient: ehMovimentoValido
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.red.withValues(alpha: 0.9),
                        Colors.red.withValues(alpha: 0.7),
                      ],
                    )
                  : estaSelecionada
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        corDaEquipe.withValues(alpha: 1.0),
                        corDaEquipe.withValues(alpha: 0.8),
                      ],
                    )
                  : LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        habilitarClique
                            ? corDaEquipe
                            : corDaEquipe.withValues(alpha: 0.6),
                        habilitarClique
                            ? corDaEquipe.withValues(alpha: 0.8)
                            : corDaEquipe.withValues(alpha: 0.4),
                      ],
                    ),
              borderRadius: BorderRadius.circular(borderRadius),
              border: estaSelecionada
                  ? Border.all(color: Colors.yellow[400]!, width: 3)
                  : ehMovimentoValido
                  ? Border.all(color: Colors.red[300]!, width: 2)
                  : Border.all(
                      color: Colors.black.withValues(alpha: 0.3),
                      width: 1,
                    ),
              boxShadow: estaSelecionada
                  ? [
                      BoxShadow(
                        color: Colors.yellow.withValues(alpha: 0.5),
                        spreadRadius: 2,
                        blurRadius: 4,
                        offset: const Offset(0, 0),
                      ),
                    ]
                  : ehMovimentoValido
                  ? [
                      BoxShadow(
                        color: Colors.red.withValues(alpha: 0.4),
                        spreadRadius: 1,
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ]
                  : habilitarClique
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
                    ],
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
      ),
    );
  }
}
