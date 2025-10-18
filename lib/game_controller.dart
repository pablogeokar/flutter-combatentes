import './modelos_jogo.dart';

/// Contém o resultado de uma tentativa de movimento.
///
/// Encapsula o novo estado do jogo em caso de sucesso, ou uma
/// mensagem de erro em caso de falha.
class ResultadoMovimento {
  /// `true` se o movimento foi válido e o estado do jogo foi alterado.
  final bool sucesso;

  /// O estado do jogo. Se [sucesso] for `true`, este é o novo estado
  /// após o movimento. Se for `false`, é o estado original, sem modificações.
  final EstadoJogo estadoJogo;

  /// Uma mensagem explicativa em caso de falha no movimento.
  /// Será `null` se o movimento for bem-sucedido.
  final String? mensagemErro;

  ResultadoMovimento({
    required this.sucesso,
    required this.estadoJogo,
    this.mensagemErro,
  });
}

/// O motor de regras do jogo "Combate".
///
/// Esta classe é responsável por processar as ações dos jogadores,
/// validar movimentos, resolver combates e determinar as condições de vitória.
/// É uma classe pura de Dart, sem dependências do Flutter, para garantir
/// a separação de responsabilidades e facilitar os testes.
class GameController {
  // As posições no tabuleiro que são consideradas "lagos" e não podem ser ocupadas.
  // Tabuleiro 10x10, indexado de 0 a 9.
  static final Set<PosicaoTabuleiro> _lagos = {
    const PosicaoTabuleiro(linha: 4, coluna: 2),
    const PosicaoTabuleiro(linha: 4, coluna: 3),
    const PosicaoTabuleiro(linha: 5, coluna: 2),
    const PosicaoTabuleiro(linha: 5, coluna: 3),
    const PosicaoTabuleiro(linha: 4, coluna: 6),
    const PosicaoTabuleiro(linha: 4, coluna: 7),
    const PosicaoTabuleiro(linha: 5, coluna: 6),
    const PosicaoTabuleiro(linha: 5, coluna: 7),
  };

  /// Calcula todas as posições válidas para onde uma peça pode se mover.
  ///
  /// Retorna uma lista de [PosicaoTabuleiro] representando todas as casas
  /// válidas para onde a peça pode se mover no estado atual do jogo.
  List<PosicaoTabuleiro> calcularMovimentosValidos({
    required EstadoJogo estadoAtual,
    required String idPeca,
  }) {
    final List<PosicaoTabuleiro> movimentosValidos = [];

    // Encontrar a peça
    final PecaJogo? peca = estadoAtual.pecas.cast<PecaJogo?>().firstWhere(
      (p) => p?.id == idPeca,
      orElse: () => null,
    );

    if (peca == null) return movimentosValidos;

    // Peças que não podem se mover
    if (peca.patente == Patente.minaTerrestre ||
        peca.patente == Patente.prisioneiro) {
      return movimentosValidos;
    }

    final posAtual = peca.posicao;

    // Para soldados, verificar movimentos em linha reta
    if (peca.patente == Patente.soldado) {
      // Movimento horizontal (direita)
      for (int c = posAtual.coluna + 1; c < 10; c++) {
        final novaPosicao = PosicaoTabuleiro(linha: posAtual.linha, coluna: c);
        if (_isMovimentoValido(peca, novaPosicao, estadoAtual.pecas)) {
          movimentosValidos.add(novaPosicao);
          // Se há uma peça inimiga, pode atacar mas não passar por ela
          final pecaNoDestino = estadoAtual.pecas.cast<PecaJogo?>().firstWhere(
            (p) =>
                p?.posicao.linha == novaPosicao.linha &&
                p?.posicao.coluna == novaPosicao.coluna,
            orElse: () => null,
          );
          if (pecaNoDestino != null) break;
        } else {
          break; // Caminho bloqueado
        }
      }

      // Movimento horizontal (esquerda)
      for (int c = posAtual.coluna - 1; c >= 0; c--) {
        final novaPosicao = PosicaoTabuleiro(linha: posAtual.linha, coluna: c);
        if (_isMovimentoValido(peca, novaPosicao, estadoAtual.pecas)) {
          movimentosValidos.add(novaPosicao);
          final pecaNoDestino = estadoAtual.pecas.cast<PecaJogo?>().firstWhere(
            (p) =>
                p?.posicao.linha == novaPosicao.linha &&
                p?.posicao.coluna == novaPosicao.coluna,
            orElse: () => null,
          );
          if (pecaNoDestino != null) break;
        } else {
          break;
        }
      }

      // Movimento vertical (baixo)
      for (int l = posAtual.linha + 1; l < 10; l++) {
        final novaPosicao = PosicaoTabuleiro(linha: l, coluna: posAtual.coluna);
        if (_isMovimentoValido(peca, novaPosicao, estadoAtual.pecas)) {
          movimentosValidos.add(novaPosicao);
          final pecaNoDestino = estadoAtual.pecas.cast<PecaJogo?>().firstWhere(
            (p) =>
                p?.posicao.linha == novaPosicao.linha &&
                p?.posicao.coluna == novaPosicao.coluna,
            orElse: () => null,
          );
          if (pecaNoDestino != null) break;
        } else {
          break;
        }
      }

      // Movimento vertical (cima)
      for (int l = posAtual.linha - 1; l >= 0; l--) {
        final novaPosicao = PosicaoTabuleiro(linha: l, coluna: posAtual.coluna);
        if (_isMovimentoValido(peca, novaPosicao, estadoAtual.pecas)) {
          movimentosValidos.add(novaPosicao);
          final pecaNoDestino = estadoAtual.pecas.cast<PecaJogo?>().firstWhere(
            (p) =>
                p?.posicao.linha == novaPosicao.linha &&
                p?.posicao.coluna == novaPosicao.coluna,
            orElse: () => null,
          );
          if (pecaNoDestino != null) break;
        } else {
          break;
        }
      }
    } else {
      // Para outras peças, verificar apenas casas adjacentes
      final List<PosicaoTabuleiro> posicoesAdjacentes = [
        PosicaoTabuleiro(
          linha: posAtual.linha - 1,
          coluna: posAtual.coluna,
        ), // Cima
        PosicaoTabuleiro(
          linha: posAtual.linha + 1,
          coluna: posAtual.coluna,
        ), // Baixo
        PosicaoTabuleiro(
          linha: posAtual.linha,
          coluna: posAtual.coluna - 1,
        ), // Esquerda
        PosicaoTabuleiro(
          linha: posAtual.linha,
          coluna: posAtual.coluna + 1,
        ), // Direita
      ];

      for (final novaPosicao in posicoesAdjacentes) {
        // Verificar se está dentro do tabuleiro
        if (novaPosicao.linha >= 0 &&
            novaPosicao.linha < 10 &&
            novaPosicao.coluna >= 0 &&
            novaPosicao.coluna < 10) {
          if (_isMovimentoValido(peca, novaPosicao, estadoAtual.pecas)) {
            movimentosValidos.add(novaPosicao);
          }
        }
      }
    }

    return movimentosValidos;
  }

  /// Verifica se um movimento específico é válido (versão simplificada para cálculo de movimentos)
  bool _isMovimentoValido(
    PecaJogo peca,
    PosicaoTabuleiro novaPosicao,
    List<PecaJogo> pecas,
  ) {
    // Verifica se a nova posição é um lago
    if (_lagos.any(
      (l) => l.linha == novaPosicao.linha && l.coluna == novaPosicao.coluna,
    )) {
      return false;
    }

    // Verifica se há uma peça da mesma equipe no destino
    final pecaNoDestino = pecas.cast<PecaJogo?>().firstWhere(
      (p) =>
          p?.posicao.linha == novaPosicao.linha &&
          p?.posicao.coluna == novaPosicao.coluna,
      orElse: () => null,
    );

    if (pecaNoDestino != null && pecaNoDestino.equipe == peca.equipe) {
      return false;
    }

    return true;
  }

  /// O método principal para processar a jogada de um jogador.
  ///
  /// Recebe o estado atual do jogo, o ID da peça a ser movida e a posição
  /// de destino. Retorna um [ResultadoMovimento] com o novo estado do jogo
  /// ou uma mensagem de erro.
  ResultadoMovimento moverPeca({
    required EstadoJogo estadoAtual,
    required String idPeca,
    required PosicaoTabuleiro novaPosicao,
  }) {
    // 1. Encontrar a peça e o jogador.
    final PecaJogo? pecaAMover = estadoAtual.pecas.cast<PecaJogo?>().firstWhere(
      (p) => p?.id == idPeca,
      orElse: () => null,
    );

    if (pecaAMover == null) {
      return ResultadoMovimento(
        sucesso: false,
        estadoJogo: estadoAtual,
        mensagemErro: "Peça não encontrada.",
      );
    }

    final Jogador jogadorAtual = estadoAtual.jogadores.firstWhere(
      (j) => j.equipe == pecaAMover.equipe,
    );

    // 2. Validar se é o turno do jogador.
    final turnoValido = _validarTurno(
      idJogadorDaVez: estadoAtual.idJogadorDaVez,
      jogador: jogadorAtual,
    );
    if (!turnoValido) {
      return ResultadoMovimento(
        sucesso: false,
        estadoJogo: estadoAtual,
        mensagemErro: "Não é o seu turno.",
      );
    }

    // 3. Validar se o movimento é legal.
    final erroMovimento = _validarMovimento(
      peca: pecaAMover,
      novaPosicao: novaPosicao,
      pecas: estadoAtual.pecas,
    );
    if (erroMovimento != null) {
      return ResultadoMovimento(
        sucesso: false,
        estadoJogo: estadoAtual,
        mensagemErro: erroMovimento,
      );
    }

    List<PecaJogo> pecasAtualizadas = List.from(estadoAtual.pecas);
    PecaJogo pecaMovida = pecaAMover;

    // 4. Verificar se há combate.
    final PecaJogo? pecaDefensora = pecasAtualizadas
        .cast<PecaJogo?>()
        .firstWhere(
          (p) =>
              p?.posicao.linha == novaPosicao.linha &&
              p?.posicao.coluna == novaPosicao.coluna,
          orElse: () => null,
        );

    if (pecaDefensora != null) {
      // Se a peça no destino for da mesma equipe, o movimento é inválido (já verificado em _validarMovimento).
      // Portanto, aqui só pode ser um combate.
      final resultadoCombate = _resolverCombate(
        atacante: pecaAMover,
        defendida: pecaDefensora,
      );

      // Ambas as peças se tornam reveladas após o combate.
      final pecaAtacanteRevelada = PecaJogo(
        id: pecaAMover.id,
        patente: pecaAMover.patente,
        equipe: pecaAMover.equipe,
        posicao: pecaAMover.posicao,
        foiRevelada: true,
      );

      final pecaDefensoraRevelada = PecaJogo(
        id: pecaDefensora.id,
        patente: pecaDefensora.patente,
        equipe: pecaDefensora.equipe,
        posicao: pecaDefensora.posicao,
        foiRevelada: true,
      );

      pecasAtualizadas.removeWhere(
        (p) => p.id == pecaAMover.id || p.id == pecaDefensora.id,
      );
      pecasAtualizadas.add(pecaAtacanteRevelada);
      pecasAtualizadas.add(pecaDefensoraRevelada);

      if (resultadoCombate.vencedor == null) {
        // Empate
        pecasAtualizadas.removeWhere(
          (p) => p.id == pecaAMover.id || p.id == pecaDefensora.id,
        );
      } else if (resultadoCombate.vencedor!.id == pecaAMover.id) {
        // Atacante vence
        pecasAtualizadas.removeWhere((p) => p.id == pecaDefensora.id);
        pecaMovida = PecaJogo(
          id: pecaAtacanteRevelada.id,
          patente: pecaAtacanteRevelada.patente,
          equipe: pecaAtacanteRevelada.equipe,
          posicao: novaPosicao, // Move para a posição da peça derrotada
          foiRevelada: true,
        );
        pecasAtualizadas.removeWhere((p) => p.id == pecaAMover.id);
        pecasAtualizadas.add(pecaMovida);
      } else {
        // Defensor vence
        pecasAtualizadas.removeWhere((p) => p.id == pecaAMover.id);
        // A peça defensora não se move, apenas permanece revelada.
      }
    } else {
      // 5. Se não houver combate, apenas mover a peça.
      pecaMovida = PecaJogo(
        id: pecaAMover.id,
        patente: pecaAMover.patente,
        equipe: pecaAMover.equipe,
        posicao: novaPosicao,
        foiRevelada: pecaAMover.foiRevelada,
      );
      pecasAtualizadas.removeWhere((p) => p.id == pecaAMover.id);
      pecasAtualizadas.add(pecaMovida);
    }

    // 6. Criar o novo estado do jogo com o turno trocado.
    final proximoJogador = estadoAtual.jogadores.firstWhere(
      (j) => j.id != estadoAtual.idJogadorDaVez,
    );

    EstadoJogo estadoIntermediario = EstadoJogo(
      idPartida: estadoAtual.idPartida,
      jogadores: estadoAtual.jogadores,
      pecas: pecasAtualizadas,
      idJogadorDaVez: proximoJogador.id,
      jogoTerminou: estadoAtual.jogoTerminou,
      idVencedor: estadoAtual.idVencedor,
    );

    // 7. Verificar se o movimento resultou em vitória.
    final estadoFinal = _verificarVitoria(estadoIntermediario, jogadorAtual);

    return ResultadoMovimento(sucesso: true, estadoJogo: estadoFinal);
  }

  /// Verifica se o jogador que está tentando mover a peça é o jogador da vez.
  bool _validarTurno({
    required String idJogadorDaVez,
    required Jogador jogador,
  }) {
    return idJogadorDaVez == jogador.id;
  }

  /// Valida as regras de movimento para uma determinada peça.
  /// Retorna uma string de erro se o movimento for inválido, ou `null` se for válido.
  String? _validarMovimento({
    required PecaJogo peca,
    required PosicaoTabuleiro novaPosicao,
    required List<PecaJogo> pecas,
  }) {
    // Peças que não podem se mover.
    if (peca.patente == Patente.minaTerrestre ||
        peca.patente == Patente.prisioneiro) {
      return "Esta peça não pode se mover.";
    }

    final posAtual = peca.posicao;

    // Movimento para a mesma casa.
    if (posAtual.linha == novaPosicao.linha &&
        posAtual.coluna == novaPosicao.coluna) {
      return "Movimento inválido.";
    }

    // Movimento na diagonal não é permitido.
    if (posAtual.linha != novaPosicao.linha &&
        posAtual.coluna != novaPosicao.coluna) {
      return "Movimentos na diagonal não são permitidos.";
    }

    // Verifica se a nova posição é um lago.
    if (_lagos.any(
      (l) => l.linha == novaPosicao.linha && l.coluna == novaPosicao.coluna,
    )) {
      return "Não é possível mover para um lago.";
    }

    // Verifica se a nova posição está ocupada por uma peça da mesma equipe.
    final pecaNoDestino = pecas.cast<PecaJogo?>().firstWhere(
      (p) =>
          p?.posicao.linha == novaPosicao.linha &&
          p?.posicao.coluna == novaPosicao.coluna,
      orElse: () => null,
    );
    if (pecaNoDestino != null && pecaNoDestino.equipe == peca.equipe) {
      return "Não é possível mover para uma casa ocupada por uma peça aliada.";
    }

    // Regra especial para o Soldado.
    if (peca.patente == Patente.soldado) {
      // O soldado pode se mover qualquer número de casas em linha reta.
      // A verificação de caminho livre é necessária.
      if (posAtual.linha == novaPosicao.linha) {
        // Movimento horizontal
        final direcao = novaPosicao.coluna > posAtual.coluna ? 1 : -1;
        for (
          int c = posAtual.coluna + direcao;
          c != novaPosicao.coluna;
          c += direcao
        ) {
          if (pecas.any(
            (p) => p.posicao.linha == posAtual.linha && p.posicao.coluna == c,
          )) {
            return "O caminho do soldado está bloqueado.";
          }
        }
      } else {
        // Movimento vertical
        final direcao = novaPosicao.linha > posAtual.linha ? 1 : -1;
        for (
          int l = posAtual.linha + direcao;
          l != novaPosicao.linha;
          l += direcao
        ) {
          if (pecas.any(
            (p) => p.posicao.linha == l && p.posicao.coluna == posAtual.coluna,
          )) {
            return "O caminho do soldado está bloqueado.";
          }
        }
      }
      return null; // Movimento de soldado é válido
    }

    // Regra padrão para outras peças (movimento de 1 casa).
    final distancia =
        (posAtual.linha - novaPosicao.linha).abs() +
        (posAtual.coluna - novaPosicao.coluna).abs();
    if (distancia > 1) {
      return "Esta peça só pode se mover uma casa por vez.";
    }

    return null; // Movimento válido.
  }

  /// Resolve um combate entre duas peças.
  _ResultadoCombate _resolverCombate({
    required PecaJogo atacante,
    required PecaJogo defendida,
  }) {
    final forcaAtacante = atacante.patente.forca;
    final forcaDefendida = defendida.patente.forca;

    // Regra especial: Agente Secreto vs General
    if (atacante.patente == Patente.agenteSecreto &&
        defendida.patente == Patente.general) {
      return _ResultadoCombate(vencedor: atacante, perdedor: defendida);
    }

    // Regra especial: Mina Terrestre
    if (defendida.patente == Patente.minaTerrestre) {
      if (atacante.patente == Patente.cabo) {
        // Cabo desativa a mina
        return _ResultadoCombate(vencedor: atacante, perdedor: defendida);
      } else {
        // Qualquer outra peça é derrotada pela mina
        return _ResultadoCombate(vencedor: defendida, perdedor: atacante);
      }
    }

    // Combate padrão por força
    if (forcaAtacante > forcaDefendida) {
      return _ResultadoCombate(vencedor: atacante, perdedor: defendida);
    } else if (forcaDefendida > forcaAtacante) {
      return _ResultadoCombate(vencedor: defendida, perdedor: atacante);
    } else {
      // Empate: ambas as peças são removidas
      return _ResultadoCombate(vencedor: null, perdedor: null);
    }
  }

  /// Verifica se uma condição de vitória foi atingida após um movimento.
  /// Retorna um novo [EstadoJogo] com o status de fim de jogo atualizado se a partida terminou.
  EstadoJogo _verificarVitoria(EstadoJogo estado, Jogador jogadorVencedor) {
    final equipeAdversaria = jogadorVencedor.equipe == Equipe.preta
        ? Equipe.verde
        : Equipe.preta;

    // 1. Vitória por capturar o prisioneiro (bandeira) adversário.
    final prisioneiroAdversario = estado.pecas.cast<PecaJogo?>().firstWhere(
      (p) => p?.patente == Patente.prisioneiro && p?.equipe == equipeAdversaria,
      orElse: () => null,
    );

    if (prisioneiroAdversario == null) {
      return EstadoJogo(
        idPartida: estado.idPartida,
        jogadores: estado.jogadores,
        pecas: estado.pecas,
        idJogadorDaVez: estado.idJogadorDaVez,
        jogoTerminou: true,
        idVencedor: jogadorVencedor.id,
      );
    }

    // 2. Vitória por deixar o adversário sem peças móveis.
    final pecasMoveisAdversarias = estado.pecas.where(
      (p) =>
          p.equipe == equipeAdversaria &&
          p.patente != Patente.minaTerrestre &&
          p.patente != Patente.prisioneiro,
    );

    if (pecasMoveisAdversarias.isEmpty) {
      return EstadoJogo(
        idPartida: estado.idPartida,
        jogadores: estado.jogadores,
        pecas: estado.pecas,
        idJogadorDaVez: estado.idJogadorDaVez,
        jogoTerminou: true,
        idVencedor: jogadorVencedor.id,
      );
    }

    // Se nenhuma condição de vitória foi atingida, retorna o estado como está.
    return estado;
  }
}

/// Classe auxiliar para encapsular o resultado de um combate.
class _ResultadoCombate {
  final PecaJogo? vencedor;
  final PecaJogo? perdedor;

  _ResultadoCombate({this.vencedor, this.perdedor});
}
