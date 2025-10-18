import 'package:flutter/material.dart';
import '../modelos_jogo.dart';
import './peca_widget.dart';

/// O widget que renderiza a grade do tabuleiro e as peças contidas nele.
class TabuleiroWidget extends StatelessWidget {
  /// O estado atual do jogo, contendo a lista de peças.
  final EstadoJogo estadoJogo;

  /// O ID da peça que está atualmente selecionada pelo jogador.
  final String? idPecaSelecionada;

  /// Lista de posições válidas para movimento da peça selecionada.
  final List<PosicaoTabuleiro> movimentosValidos;

  /// Callback para quando uma peça é tocada.
  final Function(String) onPecaTap;

  /// Callback para quando uma posição vazia no tabuleiro é tocada.
  final Function(PosicaoTabuleiro) onPosicaoTap;

  /// Nome do usuário local para identificar suas peças
  final String? nomeUsuarioLocal;

  const TabuleiroWidget({
    super.key,
    required this.estadoJogo,
    required this.idPecaSelecionada,
    required this.movimentosValidos,
    required this.onPecaTap,
    required this.onPosicaoTap,
    required this.nomeUsuarioLocal,
  });

  @override
  Widget build(BuildContext context) {
    // Cria um mapa de posições para peças para acesso rápido.
    final Map<String, PecaJogo> pecasPorPosicao = {
      for (var peca in estadoJogo.pecas)
        '${peca.posicao.linha}-${peca.posicao.coluna}': peca,
    };

    return LayoutBuilder(
      builder: (context, constraints) {
        // Calcula o tamanho de cada célula baseado no menor lado disponível
        final double availableSize =
            constraints.maxWidth < constraints.maxHeight
            ? constraints.maxWidth
            : constraints.maxHeight;
        final double cellSize =
            (availableSize - 16) / 10; // 16 para padding total

        return Container(
          width: availableSize,
          height: availableSize,
          padding: const EdgeInsets.all(8.0),
          child: Stack(
            children: [
              // Imagem de fundo do tabuleiro
              Positioned.fill(
                child: Image.asset(
                  'assets/images/board_background.png',
                  fit: BoxFit.contain,
                ),
              ),
              // Grid das células
              GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 10,
                  mainAxisSpacing: 0,
                  crossAxisSpacing: 0,
                  childAspectRatio: 1.0,
                ),
                itemCount: 100,
                itemBuilder: (context, index) {
                  final int linha = index ~/ 10;
                  final int coluna = index % 10;
                  final PosicaoTabuleiro posicaoAtual = PosicaoTabuleiro(
                    linha: linha,
                    coluna: coluna,
                  );
                  final String chavePosicao = '$linha-$coluna';
                  final PecaJogo? peca = pecasPorPosicao[chavePosicao];

                  return Container(
                    width: cellSize,
                    height: cellSize,
                    child: peca != null
                        ? _buildPecaCell(peca, cellSize, posicaoAtual)
                        : _buildEmptyCell(posicaoAtual, cellSize),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPecaCell(
    PecaJogo peca,
    double cellSize,
    PosicaoTabuleiro posicao,
  ) {
    // Identifica se a peça pertence ao jogador LOCAL
    final bool ehDoJogadorLocal = _isPecaDoJogadorLocal(peca);

    // Verifica se é a vez do jogador local
    final bool ehVezDoJogadorLocal = _isVezDoJogadorLocal();

    // Verifica se esta posição é um movimento válido
    final bool ehMovimentoValido = movimentosValidos.any(
      (pos) => pos.linha == posicao.linha && pos.coluna == posicao.coluna,
    );

    return PecaJogoWidget(
      peca: peca,
      estaSelecionada: idPecaSelecionada == peca.id,
      ehDoJogadorAtual: ehDoJogadorLocal,
      ehVezDoJogadorLocal: ehVezDoJogadorLocal,
      ehMovimentoValido: ehMovimentoValido,
      onPecaTap: (idPeca) {
        // Se é uma peça inimiga atacável, trata como movimento
        if (ehMovimentoValido && !ehDoJogadorLocal) {
          onPosicaoTap(posicao);
        } else {
          // Caso contrário, trata como seleção normal
          onPecaTap(idPeca);
        }
      },
      cellSize: cellSize,
    );
  }

  /// Verifica se a peça pertence ao jogador local (usuário deste dispositivo)
  bool _isPecaDoJogadorLocal(PecaJogo peca) {
    if (nomeUsuarioLocal == null) return false;

    // Busca o jogador local pelo nome
    final jogadorLocal = estadoJogo.jogadores.where((jogador) {
      final nomeJogador = jogador.nome.trim().toLowerCase();
      final nomeLocal = nomeUsuarioLocal!.trim().toLowerCase();

      // Busca exata
      if (nomeJogador == nomeLocal) return true;

      // Busca parcial (contém)
      if (nomeJogador.contains(nomeLocal) || nomeLocal.contains(nomeJogador)) {
        return true;
      }

      return false;
    }).toList();

    if (jogadorLocal.isNotEmpty) {
      return peca.equipe == jogadorLocal.first.equipe;
    }

    // Fallback: Se não encontrou por nome, tenta heurística
    // Se há apenas um jogador com nome real, assume que é o local
    final jogadoresComNomeReal = estadoJogo.jogadores
        .where(
          (j) =>
              !j.nome.contains("Aguardando") &&
              !j.nome.contains("Jogador") &&
              j.nome.trim().length > 2,
        )
        .toList();

    if (jogadoresComNomeReal.length == 1) {
      return peca.equipe == jogadoresComNomeReal.first.equipe;
    }

    // Se tudo falhar, retorna false (peça será tratada como do oponente)
    return false;
  }

  /// Verifica se é a vez do jogador local
  bool _isVezDoJogadorLocal() {
    if (nomeUsuarioLocal == null) return false;

    final jogadorDaVez = estadoJogo.jogadores.firstWhere(
      (j) => j.id == estadoJogo.idJogadorDaVez,
    );

    final nomeJogadorDaVez = jogadorDaVez.nome.trim().toLowerCase();
    final nomeLocal = nomeUsuarioLocal!.trim().toLowerCase();

    // Busca exata ou parcial
    return nomeJogadorDaVez == nomeLocal ||
        nomeJogadorDaVez.contains(nomeLocal) ||
        nomeLocal.contains(nomeJogadorDaVez);
  }

  Widget _buildEmptyCell(PosicaoTabuleiro posicao, double cellSize) {
    // Verifica se esta posição é um movimento válido
    final bool ehMovimentoValido = movimentosValidos.any(
      (pos) => pos.linha == posicao.linha && pos.coluna == posicao.coluna,
    );

    return MouseRegion(
      cursor: ehMovimentoValido
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: () => onPosicaoTap(posicao),
        child: Container(
          width: cellSize,
          height: cellSize,
          margin: const EdgeInsets.all(1.0),
          decoration: BoxDecoration(
            color: ehMovimentoValido
                ? Colors.green.withValues(alpha: 0.4)
                : Colors.transparent,
            border: ehMovimentoValido
                ? Border.all(color: Colors.green, width: 2)
                : null,
            borderRadius: BorderRadius.circular(4.0),
          ),
          child: ehMovimentoValido
              ? const Center(
                  child: Icon(Icons.circle, color: Colors.green, size: 12),
                )
              : null,
        ),
      ),
    );
  }
}
