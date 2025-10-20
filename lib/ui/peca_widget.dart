import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import '../modelos_jogo.dart';
import 'custom_tooltip.dart';

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
    final double borderRadius = cellSize * 0.08;
    final double margin = cellSize * 0.02; // Reduzido para maximizar espaço
    final bool isDesktop =
        !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.macOS ||
            defaultTargetPlatform == TargetPlatform.linux);

    // Lógica para decidir o que renderizar dentro da peça - MÁXIMO ESPAÇO
    Widget conteudoPeca;
    if (ehDoJogadorAtual) {
      // Se a peça é do jogador atual, mostra a imagem ocupando 96% da área disponível
      conteudoPeca = Padding(
        padding: EdgeInsets.all(
          cellSize * 0.02,
        ), // Mínimo padding - máximo espaço
        child: ColorFiltered(
          colorFilter: ColorFilter.mode(
            Colors.white.withValues(alpha: 0.95),
            BlendMode.modulate,
          ),
          child: Image.asset(
            peca.patente.imagePath,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              // Fallback minimalista - apenas ícone
              return Icon(
                Icons.military_tech,
                color: Colors.white.withValues(alpha: 0.9),
                size: cellSize * 0.7,
              );
            },
          ),
        ),
      );
    } else {
      // Peça inimiga - ícone ocupando máximo espaço
      conteudoPeca = Padding(
        padding: EdgeInsets.all(cellSize * 0.05),
        child: Icon(
          Icons.military_tech,
          color: Colors.white.withValues(alpha: 0.9),
          size: cellSize * 0.7,
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

    // Widget base da peça
    Widget pieceWidget = GestureDetector(
      onTap: () {
        if (habilitarClique) {
          onPecaTap(peca.id);
        } else if (!isDesktop && ehDoJogadorAtual) {
          // Mobile: tap para mostrar info
          _showMobileTooltip(context);
        }
      },
      onLongPress: !isDesktop && ehDoJogadorAtual
          ? () => _showMobileTooltip(context)
          : null,
      child: MouseRegion(
        cursor: cursor,
        child: Container(
          width: cellSize,
          height: cellSize,
          margin: EdgeInsets.all(margin),
          decoration: BoxDecoration(
            color: ehMovimentoValido
                ? Colors.red.withValues(alpha: 0.3)
                : estaSelecionada
                ? Colors.yellow.withValues(alpha: 0.2)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(borderRadius),
            border: estaSelecionada
                ? Border.all(color: Colors.yellow[400]!, width: 3)
                : ehMovimentoValido
                ? Border.all(color: Colors.red[400]!, width: 2)
                : null,
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
                : null,
          ),
          child: Stack(
            children: [
              // Conteúdo da peça ocupando máximo espaço
              Positioned.fill(child: conteudoPeca),
              // Indicador de movimento válido - menor e mais discreto
              if (ehMovimentoValido)
                Positioned(
                  top: 1,
                  right: 1,
                  child: Container(
                    width: 6,
                    height: 6,
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

    // Tooltip customizado que funciona garantidamente
    return CustomTooltip(
      message: ehDoJogadorAtual
          ? '${peca.patente.nome}\nForça: ${peca.patente.forca}'
          : 'Peça Inimiga',
      waitDuration: const Duration(milliseconds: 300),
      showDuration: const Duration(seconds: 2),
      child: pieceWidget,
    );
  }

  /// Mostra tooltip para mobile (tap/long press)
  void _showMobileTooltip(BuildContext context) {
    if (!ehDoJogadorAtual) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 24,
              height: 24,
              padding: const EdgeInsets.all(2),
              child: Image.asset(
                peca.patente.imagePath,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.military_tech,
                    color: Colors.white,
                    size: 20,
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  peca.patente.nome,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  'Força: ${peca.patente.forca}',
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
          ],
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: peca.equipe == Equipe.preta
            ? Colors.grey[800]
            : Colors.green[700],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}
