import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:combatentes/src/common/models/game_state_models.dart'; // Updated import
import 'package:combatentes/src/common/models/modelos_jogo.dart'; // Updated import
import 'package:combatentes/src/common/services/user_preferences.dart'; // Updated import
import 'package:combatentes/src/common/services/game_persistence.dart'; // NEW import
import 'package:combatentes/src/features/3_gameplay/logic/controllers/game_controller.dart'; // Updated import
import 'package:combatentes/src/common/providers/socket_provider.dart'; // Updated import

/// Provider que gerencia o estado da tela do jogo, agora orientado pela rede.
final gameStateProvider =
    StateNotifierProvider<GameStateNotifier, TelaJogoState>((ref) {
      return GameStateNotifier(ref);
    });

class GameStateNotifier extends StateNotifier<TelaJogoState> {
  final Ref _ref;
  final GameController _gameController = GameController();
  bool _hasActiveReconnection = false;
  String? _currentServerAddress;

  GameStateNotifier(this._ref) : super(const TelaJogoState()) {
    _init();
  }

  void _init() {
    _initAsync();
  }

  Future<void> _initAsync() async {
    try {
      // Carrega o nome do usuário
      final nomeUsuario = await UserPreferences.getUserName();
      state = state.copyWith(nomeUsuario: nomeUsuario);

      final socketService = _ref.read(gameSocketProvider);

      // Configura os listeners antes de conectar
      socketService.streamDeEstados.listen((novoEstado) {
        // Detecta combates e movimentos comparando estados
        final combate = _detectarCombate(state.estadoJogo, novoEstado);
        final movimento = _detectarMovimento(state.estadoJogo, novoEstado);

        // Detecta mudança de turno
        final mudouTurno = _detectarMudancaTurno(state.estadoJogo, novoEstado);

        if (combate != null) {
          debugPrint(
            '🎯 COMBATE DETECTADO NO PROVIDER: ${combate.atacante.patente.nome} vs ${combate.defensor.patente.nome}',
          );
        } else if (movimento != null) {
          debugPrint(
            '🏃 MOVIMENTO DETECTADO NO PROVIDER: ${movimento.peca.patente.nome} de (${movimento.posicaoInicial.linha}, ${movimento.posicaoInicial.coluna}) para (${movimento.posicaoFinal.linha}, ${movimento.posicaoFinal.coluna})',
          );
        } else {
          debugPrint(
            '🔍 Nenhum combate ou movimento detectado nesta atualização',
          );
        }

        if (mudouTurno) {
          debugPrint('🔔 MUDANÇA DE TURNO DETECTADA');
        }

        state = state.copyWith(
          estadoJogo: novoEstado,
          ultimoCombate: combate,
          ultimoMovimento: movimento,
          conectando: false,
          statusConexao: StatusConexao.jogando,
          limparErro: true,
        );

        // Salva automaticamente o estado do jogo para recuperação
        _saveGameStateForRecovery(novoEstado);
      });

      socketService.streamDeErros.listen((mensagemErro) {
        state = state.copyWith(erro: mensagemErro, conectando: false);
      });

      socketService.streamDeStatus.listen((novoStatus) {
        state = state.copyWith(
          statusConexao: novoStatus,
          conectando: novoStatus == StatusConexao.conectando,
        );

        // Se o oponente desconectou, limpa o estado do jogo
        if (novoStatus == StatusConexao.oponenteDesconectado) {
          state = state.copyWith(estadoJogo: null, limparSelecao: true);
        }

        // Se houve erro de conexão durante jogo ativo, tenta reconectar
        if (novoStatus == StatusConexao.erro ||
            novoStatus == StatusConexao.desconectado) {
          _handleConnectionLoss();
        }

        // Se houve erro, para de conectar
        if (novoStatus == StatusConexao.erro) {
          state = state.copyWith(conectando: false);
        }
      });

      // Conecta ao servidor de forma assíncrona (não bloqueia a UI)
      Future.microtask(() async {
        try {
          final serverAddress = await UserPreferences.getServerAddress();
          _currentServerAddress = serverAddress;

          // Verifica se há um jogo ativo salvo para recuperar (apenas se muito recente)
          final activeGame = await GamePersistence.loadActiveGameState();
          if (activeGame != null &&
              activeGame.isValid &&
              activeGame.ageInMinutes < 5) {
            debugPrint(
              '🔄 Jogo ativo recente encontrado (${activeGame.ageInMinutes}min), tentando recuperar...',
            );
            await _attemptGameRecovery(activeGame);
          } else {
            if (activeGame != null) {
              debugPrint(
                '🗑️ Jogo salvo muito antigo (${activeGame.ageInMinutes}min), limpando...',
              );
              await GamePersistence.clearActiveGameState();
            }
            socketService.connect(serverAddress, nomeUsuario: nomeUsuario);
          }
        } catch (e) {
          state = state.copyWith(
            conectando: false,
            statusConexao: StatusConexao.erro,
            erro: 'Erro ao conectar: $e',
          );
        }
      });
    } catch (e) {
      state = state.copyWith(
        conectando: false,
        statusConexao: StatusConexao.erro,
        erro: 'Erro ao inicializar: $e',
      );
    }
  }

  /// Apenas armazena a peça selecionada localmente na UI e calcula movimentos válidos.
  void selecionarPeca(String idPeca) {
    if (state.estadoJogo == null || state.nomeUsuario == null) return;

    final peca = state.estadoJogo!.pecas.firstWhere((p) => p.id == idPeca);
    final jogadorDaVez = state.estadoJogo!.jogadores.firstWhere(
      (j) => j.id == state.estadoJogo!.idJogadorDaVez,
    );

    // Verifica se é a vez do jogador local
    final bool ehVezDoJogadorLocal = _isVezDoJogadorLocal(jogadorDaVez);

    // Verifica se a peça pertence ao jogador local
    final bool ehPecaDoJogadorLocal = _isPecaDoJogadorLocal(peca);

    // Só permite seleção se for a vez do jogador local E a peça for dele
    if (ehVezDoJogadorLocal &&
        ehPecaDoJogadorLocal &&
        peca.equipe == jogadorDaVez.equipe) {
      // Calcula os movimentos válidos para a peça selecionada
      final movimentosValidos = _gameController.calcularMovimentosValidos(
        estadoAtual: state.estadoJogo!,
        idPeca: idPeca,
      );

      state = state.copyWith(
        idPecaSelecionada: idPeca,
        movimentosValidos: movimentosValidos,
        limparErro: true,
      );
    }
  }

  /// Verifica se é a vez do jogador local
  bool _isVezDoJogadorLocal(Jogador jogadorDaVez) {
    if (state.nomeUsuario == null) return false;

    final nomeJogadorDaVez = jogadorDaVez.nome.trim().toLowerCase();
    final nomeLocal = state.nomeUsuario!.trim().toLowerCase();

    // Busca exata ou parcial
    return nomeJogadorDaVez == nomeLocal ||
        nomeJogadorDaVez.contains(nomeLocal) ||
        nomeLocal.contains(nomeJogadorDaVez);
  }

  /// Verifica se a peça pertence ao jogador local
  bool _isPecaDoJogadorLocal(PecaJogo peca) {
    if (state.estadoJogo == null || state.nomeUsuario == null) return false;

    // Busca o jogador local pelo nome
    final jogadorLocal = state.estadoJogo!.jogadores.where((jogador) {
      final nomeJogador = jogador.nome.trim().toLowerCase();
      final nomeLocal = state.nomeUsuario!.trim().toLowerCase();

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
    final jogadoresComNomeReal = state.estadoJogo!.jogadores
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

    return false;
  }

  /// Envia a intenção de movimento para o servidor.
  void moverPeca(PosicaoTabuleiro novaPosicao) {
    if (state.idPecaSelecionada == null) {
      return;
    }

    // A responsabilidade agora é apenas notificar o servidor.
    _ref
        .read(gameSocketProvider)
        .enviarMovimento(state.idPecaSelecionada!, novaPosicao);

    // A UI é limpa imediatamente para dar feedback, mas o estado autoritativo virá do servidor.
    state = state.copyWith(limparSelecao: true);
  }

  /// Atualiza o nome do usuário no estado
  void updateUserName(String novoNome) {
    state = state.copyWith(nomeUsuario: novoNome);

    // Envia o novo nome para o servidor
    final socketService = _ref.read(gameSocketProvider);
    socketService.enviarNome(novoNome);
  }

  /// Limpa o erro atual
  void clearError() {
    state = state.copyWith(limparErro: true);
  }

  /// Atualiza o estado do jogo (usado para transferir peças do placement)
  void updateGameState(EstadoJogo novoEstado) {
    debugPrint(
      '🎮 updateGameState chamado com ${novoEstado.pecas.length} peças',
    );
    debugPrint(
      '🎮 Jogadores: ${novoEstado.jogadores.map((j) => '${j.nome} (${j.equipe.name})').join(', ')}',
    );

    state = state.copyWith(
      estadoJogo: novoEstado,
      conectando: false,
      statusConexao: StatusConexao.jogando,
      limparErro: true,
    );

    // Quando recebe estado do jogo, significa que saiu do posicionamento
    final socketService = _ref.read(gameSocketProvider);
    socketService.forceGamePhase();

    debugPrint(
      '🎮 Estado atualizado - Total de peças no estado: ${state.estadoJogo?.pecas.length ?? 0}',
    );
  }

  /// Conecta ao servidor com endereço e nome específicos
  void conectarAoServidor(String serverAddress, String nomeUsuario) {
    state = state.copyWith(
      conectando: true,
      nomeUsuario: nomeUsuario,
      limparErro: true,
    );

    try {
      final socketService = _ref.read(gameSocketProvider);
      socketService.connect(serverAddress, nomeUsuario: nomeUsuario);
    } catch (e) {
      state = state.copyWith(
        conectando: false,
        statusConexao: StatusConexao.erro,
        erro: 'Erro ao conectar: $e',
      );
    }
  }

  /// Tenta reconectar ao servidor
  void reconnect() {
    _reconnectAsync();
  }

  /// Detecta se houve um combate comparando dois estados do jogo
  InformacoesCombate? _detectarCombate(
    EstadoJogo? estadoAnterior,
    EstadoJogo novoEstado,
  ) {
    if (estadoAnterior == null) {
      debugPrint('🔍 Estado anterior é null, não há combate para detectar');
      return null;
    }

    debugPrint(
      '🔍 Detectando combate: ${estadoAnterior.pecas.length} -> ${novoEstado.pecas.length} peças',
    );

    // Detectar peças que foram removidas
    final pecasRemovidas = estadoAnterior.pecas
        .where(
          (pecaAnterior) => !novoEstado.pecas.any(
            (pecaNova) => pecaNova.id == pecaAnterior.id,
          ),
        )
        .toList();

    // Detectar peças que se moveram OU foram reveladas
    final pecasMovidas = <Map<String, PecaJogo>>[];
    final pecasReveladas = <Map<String, PecaJogo>>[];

    for (final pecaNova in novoEstado.pecas) {
      final pecaAnterior = estadoAnterior.pecas
          .where((p) => p.id == pecaNova.id)
          .firstOrNull;

      if (pecaAnterior != null) {
        // Detecta movimento
        if (pecaAnterior.posicao.linha != pecaNova.posicao.linha ||
            pecaAnterior.posicao.coluna != pecaNova.posicao.coluna) {
          pecasMovidas.add({'anterior': pecaAnterior, 'nova': pecaNova});
        }

        // Detecta revelação (indica combate)
        if (!pecaAnterior.foiRevelada && pecaNova.foiRevelada) {
          pecasReveladas.add({'anterior': pecaAnterior, 'nova': pecaNova});
          debugPrint(
            '🔍 Peça revelada: ${pecaNova.patente.nome} na posição (${pecaNova.posicao.linha}, ${pecaNova.posicao.coluna})',
          );
        }
      }
    }

    debugPrint('🗑️ Peças removidas: ${pecasRemovidas.length}');
    debugPrint('🏃 Peças movidas: ${pecasMovidas.length}');
    debugPrint('👁️ Peças reveladas: ${pecasReveladas.length}');

    // ESTRATÉGIA PRINCIPAL: Identificar combate através de peças movidas
    for (final movimento in pecasMovidas) {
      final pecaAnterior = movimento['anterior']!;
      final pecaNova = movimento['nova']!;

      debugPrint(
        '🔍 Analisando movimento: ${pecaAnterior.patente.nome} (${pecaAnterior.equipe.name}) de (${pecaAnterior.posicao.linha}, ${pecaAnterior.posicao.coluna}) para (${pecaNova.posicao.linha}, ${pecaNova.posicao.coluna})',
      );

      // Verifica se havia uma peça inimiga na posição de destino
      final defensorNaPosicao = estadoAnterior.pecas
          .where(
            (p) =>
                p.posicao.linha == pecaNova.posicao.linha &&
                p.posicao.coluna == pecaNova.posicao.coluna &&
                p.id != pecaAnterior.id &&
                p.equipe != pecaAnterior.equipe,
          )
          .firstOrNull;

      debugPrint(
        '🔍 Procurando defensor na posição (${pecaNova.posicao.linha}, ${pecaNova.posicao.coluna})',
      );
      if (defensorNaPosicao != null) {
        debugPrint(
          '🛡️ Defensor encontrado: ${defensorNaPosicao.patente.nome} (${defensorNaPosicao.equipe.name})',
        );
      } else {
        debugPrint('❌ Nenhum defensor encontrado na posição de destino');
      }

      if (defensorNaPosicao != null) {
        debugPrint(
          '🎯 COMBATE IDENTIFICADO: ${pecaAnterior.patente.nome} atacou ${defensorNaPosicao.patente.nome}',
        );

        // Determina o vencedor baseado em quem ainda existe
        PecaJogo? vencedor;
        bool foiEmpate = false;

        final atacanteAindaExiste = novoEstado.pecas.any(
          (p) => p.id == pecaAnterior.id,
        );
        final defensorAindaExiste = novoEstado.pecas.any(
          (p) => p.id == defensorNaPosicao.id,
        );

        if (atacanteAindaExiste && !defensorAindaExiste) {
          vencedor = pecaAnterior;
          debugPrint('🏆 Atacante venceu');
        } else if (!atacanteAindaExiste && defensorAindaExiste) {
          vencedor = defensorNaPosicao;
          debugPrint('🛡️ Defensor venceu');
        } else if (!atacanteAindaExiste && !defensorAindaExiste) {
          foiEmpate = true;
          debugPrint('⚖️ Empate - ambos removidos');
        }

        return InformacoesCombate(
          atacante: pecaAnterior,
          defensor: defensorNaPosicao,
          vencedor: vencedor,
          foiEmpate: foiEmpate,
          posicaoCombate: defensorNaPosicao.posicao,
        );
      }
    }

    // ESTRATÉGIA ALTERNATIVA: Combate através de peças reveladas
    if (pecasReveladas.isNotEmpty) {
      debugPrint('🔍 Tentando identificar combate através de peças reveladas');

      for (final revelacao in pecasReveladas) {
        final pecaRevelada = revelacao['nova']!;

        // CASO ESPECIAL: Mina terrestre revelada = foi atacada
        if (pecaRevelada.patente == Patente.minaTerrestre &&
            pecasRemovidas.isNotEmpty) {
          debugPrint('💣 MINA TERRESTRE REVELADA - foi atacada!');

          // Procura o atacante removido
          final atacanteRemovido = pecasRemovidas.firstOrNull;
          if (atacanteRemovido != null) {
            debugPrint(
              '🎯 COMBATE IDENTIFICADO: ${atacanteRemovido.patente.nome} atacou Mina Terrestre',
            );

            // Verifica se foi cabo (desativa mina) ou outra peça (explode)
            final caboDesativou = atacanteRemovido.patente == Patente.cabo;

            return InformacoesCombate(
              atacante: atacanteRemovido,
              defensor: pecaRevelada,
              vencedor: caboDesativou ? atacanteRemovido : pecaRevelada,
              foiEmpate: false,
              posicaoCombate: pecaRevelada.posicao,
            );
          }
        }

        // Procura por uma peça removida na mesma posição ou próxima
        if (pecasRemovidas.isNotEmpty) {
          for (final pecaRemovida in pecasRemovidas) {
            final distancia =
                (pecaRevelada.posicao.linha - pecaRemovida.posicao.linha)
                    .abs() +
                (pecaRevelada.posicao.coluna - pecaRemovida.posicao.coluna)
                    .abs();

            debugPrint(
              '📏 Distância entre ${pecaRevelada.patente.nome} revelada e ${pecaRemovida.patente.nome} removida: $distancia',
            );

            if (distancia <= 1) {
              debugPrint(
                '🎯 COMBATE IDENTIFICADO via revelação: ${pecaRevelada.patente.nome} vs ${pecaRemovida.patente.nome}',
              );

              // A peça revelada ainda existe, então ela venceu
              return InformacoesCombate(
                atacante: pecaRemovida, // A removida foi o atacante
                defensor: pecaRevelada, // A revelada foi o defensor que venceu
                vencedor: pecaRevelada,
                foiEmpate: false,
                posicaoCombate: pecaRevelada.posicao,
              );
            }
          }
        }
      }

      // ESTRATÉGIA ADICIONAL: Peça revelada sem peça removida próxima
      // Isso pode indicar que o defensor venceu e foi revelado
      if (pecasRemovidas.isNotEmpty) {
        debugPrint(
          '🔍 Verificando se peça revelada pode ser defensor que venceu',
        );

        for (final revelacao in pecasReveladas) {
          final pecaRevelada = revelacao['nova']!;

          debugPrint(
            '🔍 Peça revelada: ${pecaRevelada.patente.nome} na posição (${pecaRevelada.posicao.linha}, ${pecaRevelada.posicao.coluna})',
          );

          // Se há uma peça removida e uma revelada, pode ser combate
          // onde o defensor (revelado) venceu o atacante (removido)
          final atacanteRemovido = pecasRemovidas.firstOrNull;
          if (atacanteRemovido != null) {
            debugPrint(
              '🎯 POSSÍVEL COMBATE: ${atacanteRemovido.patente.nome} (removido) vs ${pecaRevelada.patente.nome} (revelado)',
            );

            return InformacoesCombate(
              atacante: atacanteRemovido,
              defensor: pecaRevelada,
              vencedor: pecaRevelada, // Defensor venceu
              foiEmpate: false,
              posicaoCombate: pecaRevelada.posicao,
            );
          }
        }
      }
    }

    // ESTRATÉGIA SECUNDÁRIA: Empates (múltiplas peças removidas)
    if (pecasRemovidas.length >= 2) {
      debugPrint(
        '⚖️ Empate detectado - ${pecasRemovidas.length} peças removidas',
      );

      // Tenta identificar atacante e defensor
      PecaJogo? atacante;
      PecaJogo? defensor;

      // Se há peças movidas, a primeira pode ser o atacante
      if (pecasMovidas.isNotEmpty) {
        final movimentoRecente = pecasMovidas.first;
        final pecaQueSeMoveu = movimentoRecente['anterior']!;

        // Verifica se a peça que se moveu foi removida (indicando combate)
        if (pecasRemovidas.any((p) => p.id == pecaQueSeMoveu.id)) {
          atacante = pecaQueSeMoveu;
          // O defensor seria outra peça removida
          defensor = pecasRemovidas
              .where((p) => p.id != atacante!.id)
              .firstOrNull;
        }
      }

      // Se não conseguiu identificar, usa as duas primeiras removidas
      if (atacante == null || defensor == null) {
        atacante = pecasRemovidas[0];
        defensor = pecasRemovidas[1];
      }

      return InformacoesCombate(
        atacante: atacante,
        defensor: defensor,
        vencedor: null,
        foiEmpate: true,
        posicaoCombate: defensor.posicao,
      );
    }

    // ESTRATÉGIA TERCIÁRIA: Uma peça removida com atacante na posição
    if (pecasRemovidas.length == 1) {
      final pecaRemovida = pecasRemovidas[0];
      debugPrint(
        '🎯 1 peça removida: ${pecaRemovida.patente.nome} na posição (${pecaRemovida.posicao.linha}, ${pecaRemovida.posicao.coluna})',
      );

      // Procura por uma peça que agora está na posição da peça removida
      final atacanteNaPosicao = novoEstado.pecas
          .where(
            (p) =>
                p.posicao.linha == pecaRemovida.posicao.linha &&
                p.posicao.coluna == pecaRemovida.posicao.coluna,
          )
          .firstOrNull;

      debugPrint(
        '🔍 Procurando atacante na posição da peça removida (${pecaRemovida.posicao.linha}, ${pecaRemovida.posicao.coluna})',
      );

      if (atacanteNaPosicao != null) {
        debugPrint(
          '🎯 Atacante encontrado na posição: ${atacanteNaPosicao.patente.nome}',
        );
        return InformacoesCombate(
          atacante: atacanteNaPosicao,
          defensor: pecaRemovida,
          vencedor: atacanteNaPosicao,
          foiEmpate: false,
          posicaoCombate: pecaRemovida.posicao,
        );
      } else {
        debugPrint('❌ Nenhuma peça encontrada na posição da peça removida');

        // Tenta encontrar uma peça que se moveu para uma posição próxima
        debugPrint(
          '🔍 Procurando peças que se moveram para posições próximas...',
        );
        for (final movimento in pecasMovidas) {
          final pecaAnterior = movimento['anterior']!;
          final pecaNova = movimento['nova']!;

          debugPrint(
            '📍 Movimento: ${pecaAnterior.patente.nome} de (${pecaAnterior.posicao.linha}, ${pecaAnterior.posicao.coluna}) para (${pecaNova.posicao.linha}, ${pecaNova.posicao.coluna})',
          );

          // Verifica se a peça se moveu para a posição exata da peça removida
          if (pecaNova.posicao.linha == pecaRemovida.posicao.linha &&
              pecaNova.posicao.coluna == pecaRemovida.posicao.coluna) {
            debugPrint(
              '🎯 Encontrou peça que se moveu para a posição da removida!',
            );

            // Mas a peça não está mais lá, então o defensor venceu
            return InformacoesCombate(
              atacante: pecaAnterior,
              defensor: pecaRemovida,
              vencedor: pecaRemovida, // Defensor venceu
              foiEmpate: false,
              posicaoCombate: pecaRemovida.posicao,
            );
          }

          // Verifica se a peça estava na posição da peça removida antes
          if (pecaAnterior.posicao.linha == pecaRemovida.posicao.linha &&
              pecaAnterior.posicao.coluna == pecaRemovida.posicao.coluna) {
            debugPrint('🎯 Encontrou peça que estava na posição da removida!');

            return InformacoesCombate(
              atacante: pecaRemovida, // A removida atacou
              defensor: pecaAnterior,
              vencedor: pecaAnterior, // A que se moveu venceu
              foiEmpate: false,
              posicaoCombate: pecaRemovida.posicao,
            );
          }
        }
      }

      // ÚLTIMA TENTATIVA: Para minas terrestres, tenta encontrar atacante próximo
      if (pecaRemovida.patente == Patente.minaTerrestre &&
          pecasMovidas.isNotEmpty) {
        debugPrint('💣 Mina terrestre removida - procurando atacante próximo');

        for (final movimento in pecasMovidas) {
          final pecaAnterior = movimento['anterior']!;
          final pecaNova = movimento['nova']!;

          debugPrint(
            '🔍 Analisando movimento: ${pecaAnterior.patente.nome} de (${pecaAnterior.posicao.linha}, ${pecaAnterior.posicao.coluna}) para (${pecaNova.posicao.linha}, ${pecaNova.posicao.coluna})',
          );

          // Verifica se a peça se moveu para uma posição adjacente à mina
          final distancia =
              (pecaNova.posicao.linha - pecaRemovida.posicao.linha).abs() +
              (pecaNova.posicao.coluna - pecaRemovida.posicao.coluna).abs();

          debugPrint('📏 Distância da peça movida para a mina: $distancia');

          if (distancia <= 1) {
            debugPrint(
              '💥 Atacante da mina identificado: ${pecaAnterior.patente.nome}',
            );

            // Verifica se o atacante também foi removido (mina explodiu)
            final atacanteRemovido = pecasRemovidas.any(
              (p) => p.id == pecaAnterior.id,
            );
            debugPrint('⚔️ Atacante também removido? $atacanteRemovido');

            return InformacoesCombate(
              atacante: pecaAnterior,
              defensor: pecaRemovida,
              vencedor: atacanteRemovido ? null : pecaAnterior,
              foiEmpate: atacanteRemovido,
              posicaoCombate: pecaRemovida.posicao,
            );
          }
        }

        debugPrint('❌ Nenhum atacante próximo encontrado para a mina');
      }
    }

    debugPrint('❌ Nenhum combate identificado - retornando null');
    return null;
  }

  /// Detecta se houve um movimento simples (sem combate)
  InformacoesMovimento? _detectarMovimento(
    EstadoJogo? estadoAnterior,
    EstadoJogo novoEstado,
  ) {
    if (estadoAnterior == null) return null;

    // Procura por peças que se moveram
    for (final pecaNova in novoEstado.pecas) {
      final pecaAnterior = estadoAnterior.pecas
          .where((p) => p.id == pecaNova.id)
          .firstOrNull;

      if (pecaAnterior != null &&
          (pecaAnterior.posicao.linha != pecaNova.posicao.linha ||
              pecaAnterior.posicao.coluna != pecaNova.posicao.coluna)) {
        // Verifica se não havia peça inimiga na posição de destino (movimento simples)
        final pecaNoDestino = estadoAnterior.pecas
            .where(
              (p) =>
                  p.posicao.linha == pecaNova.posicao.linha &&
                  p.posicao.coluna == pecaNova.posicao.coluna &&
                  p.id != pecaAnterior.id,
            )
            .firstOrNull;

        if (pecaNoDestino == null) {
          // Movimento simples sem combate
          return InformacoesMovimento(
            peca: pecaAnterior,
            posicaoInicial: pecaAnterior.posicao,
            posicaoFinal: pecaNova.posicao,
            temCombate: false,
          );
        }
      }
    }

    return null;
  }

  /// Detecta se houve mudança de turno entre dois estados
  bool _detectarMudancaTurno(
    EstadoJogo? estadoAnterior,
    EstadoJogo novoEstado,
  ) {
    if (estadoAnterior == null) return false;

    // Verifica se o ID do jogador da vez mudou
    return estadoAnterior.idJogadorDaVez != novoEstado.idJogadorDaVez;
  }

  /// Limpa as informações do último combate
  void limparCombate() {
    state = state.copyWith(limparCombate: true);
  }

  /// Limpa as informações do último movimento
  void limparMovimento() {
    state = state.copyWith(limparMovimento: true);
  }

  /// Volta para o estado de aguardando oponente após desconexão
  void voltarParaAguardandoOponente() {
    debugPrint('🔄 Voltando para aguardando oponente...');

    // Limpa completamente o estado do jogo
    state = state.copyWith(
      estadoJogo: null,
      limparSelecao: true,
      limparErro: true,
      limparCombate: true,
      limparMovimento: true,
      conectando: true,
      statusConexao: StatusConexao.conectando,
    );

    // Força reset do socket service e volta para fase de posicionamento
    final socketService = _ref.read(gameSocketProvider);
    socketService.resetNameConfirmation();
    socketService.forcePlacementPhase();

    // Reconecta ao servidor
    _reconnectAsync();
  }

  /// Força navegação de volta para matchmaking (usado em casos críticos)
  void forcarVoltaParaMatchmaking() {
    debugPrint('🚨 Forçando volta para matchmaking...');

    // Limpa completamente o estado
    state = state.copyWith(
      estadoJogo: null,
      limparSelecao: true,
      limparErro: true,
      limparCombate: true,
      limparMovimento: true,
      conectando: false,
      statusConexao: StatusConexao.desconectado,
    );

    // Força volta para fase de posicionamento
    final socketService = _ref.read(gameSocketProvider);
    socketService.forcePlacementPhase();
  }

  Future<void> _reconnectAsync() async {
    try {
      // Reseta o estado para conectando
      state = state.copyWith(
        conectando: true,
        estadoJogo: null,
        limparErro: true,
        limparSelecao: true,
      );

      // Obtém o nome do usuário atual
      final nomeUsuario =
          state.nomeUsuario ?? await UserPreferences.getUserName();

      // Tenta reconectar
      final socketService = _ref.read(gameSocketProvider);
      final serverAddress = await UserPreferences.getServerAddress();
      socketService.reconnect(serverAddress, nomeUsuario: nomeUsuario);
    } catch (e) {
      state = state.copyWith(conectando: false, erro: 'Erro ao reconectar: $e');
    }
  }

  /// Salva automaticamente o estado do jogo para recuperação em caso de desconexão
  Future<void> _saveGameStateForRecovery(EstadoJogo gameState) async {
    try {
      if (state.nomeUsuario != null && _currentServerAddress != null) {
        await GamePersistence.saveActiveGameState(
          gameState: gameState,
          playerName: state.nomeUsuario!,
          serverAddress: _currentServerAddress!,
        );
      }
    } catch (e) {
      debugPrint('❌ Erro ao salvar estado para recuperação: $e');
    }
  }

  /// Tenta recuperar um jogo ativo salvo
  Future<void> _attemptGameRecovery(ActiveGameState activeGame) async {
    try {
      debugPrint(
        '🔄 Tentando recuperar jogo salvo há ${activeGame.ageInMinutes} minutos',
      );

      state = state.copyWith(
        conectando: true,
        nomeUsuario: activeGame.playerName,
        statusConexao: StatusConexao.conectando,
      );

      final socketService = _ref.read(gameSocketProvider);

      // Tenta reconectar ao servidor
      final success = await socketService.reconnectDuringActiveGame(
        activeGame.serverAddress,
        nomeUsuario: activeGame.playerName,
        gameId: activeGame.gameId,
      );

      if (success) {
        debugPrint('✅ Reconexão bem-sucedida, restaurando estado do jogo');

        // Restaura o estado do jogo
        state = state.copyWith(
          estadoJogo: activeGame.gameState,
          conectando: false,
          statusConexao: StatusConexao.jogando,
          limparErro: true,
        );

        // Estado será enviado automaticamente pelo servidor após reconexão
        debugPrint('✅ Aguardando estado do servidor após reconexão');
      } else {
        debugPrint('❌ Falha na recuperação, limpando estado salvo');
        await GamePersistence.clearActiveGameState();

        // Conecta normalmente
        socketService.connect(
          activeGame.serverAddress,
          nomeUsuario: activeGame.playerName,
        );
      }
    } catch (e) {
      debugPrint('❌ Erro na recuperação do jogo: $e');
      await GamePersistence.clearActiveGameState();

      state = state.copyWith(
        conectando: false,
        statusConexao: StatusConexao.erro,
        erro: 'Erro ao recuperar jogo: $e',
      );
    }
  }

  /// Trata perda de conexão durante jogo ativo
  Future<void> _handleConnectionLoss() async {
    // Evita múltiplas tentativas simultâneas
    if (_hasActiveReconnection) {
      debugPrint('🔄 Reconexão já em andamento, ignorando');
      return;
    }

    // Só tenta reconectar se havia um jogo ativo
    if (state.estadoJogo == null || state.estadoJogo!.pecas.isEmpty) {
      debugPrint('🔄 Sem jogo ativo, não tentando reconectar');
      return;
    }

    _hasActiveReconnection = true;
    debugPrint('🚨 Perda de conexão detectada durante jogo ativo');

    try {
      // Salva o estado atual antes de tentar reconectar
      await _saveGameStateForRecovery(state.estadoJogo!);

      // Aguarda um pouco antes de tentar reconectar
      await Future.delayed(const Duration(seconds: 2));

      if (_currentServerAddress != null && state.nomeUsuario != null) {
        final socketService = _ref.read(gameSocketProvider);

        // Tenta reconectar durante jogo ativo
        final success = await socketService.reconnectDuringActiveGame(
          _currentServerAddress!,
          nomeUsuario: state.nomeUsuario!,
        );

        if (success) {
          debugPrint('✅ Reconexão automática bem-sucedida');

          // Estado será enviado automaticamente pelo servidor
          debugPrint('✅ Aguardando estado atualizado do servidor');

          state = state.copyWith(
            conectando: false,
            statusConexao: StatusConexao.jogando,
            limparErro: true,
          );
        } else {
          debugPrint('❌ Reconexão automática falhou');

          state = state.copyWith(
            conectando: false,
            statusConexao: StatusConexao.erro,
            erro: 'Conexão perdida. Tente reconectar manualmente.',
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Erro ao tratar perda de conexão: $e');

      state = state.copyWith(
        conectando: false,
        statusConexao: StatusConexao.erro,
        erro: 'Erro de conexão: $e',
      );
    } finally {
      _hasActiveReconnection = false;
    }
  }

  /// Tenta reconectar manualmente durante jogo ativo
  Future<bool> attemptManualReconnection() async {
    if (_hasActiveReconnection) {
      debugPrint('🔄 Reconexão já em andamento');
      return false;
    }

    if (_currentServerAddress == null || state.nomeUsuario == null) {
      debugPrint('❌ Informações de conexão não disponíveis');
      return false;
    }

    _hasActiveReconnection = true;

    try {
      state = state.copyWith(
        conectando: true,
        statusConexao: StatusConexao.conectando,
        limparErro: true,
      );

      final socketService = _ref.read(gameSocketProvider);

      final success = await socketService.reconnectDuringActiveGame(
        _currentServerAddress!,
        nomeUsuario: state.nomeUsuario!,
      );

      if (success) {
        debugPrint('✅ Reconexão manual bem-sucedida');

        // Estado será enviado automaticamente pelo servidor
        debugPrint('✅ Aguardando estado atualizado do servidor');

        state = state.copyWith(
          conectando: false,
          statusConexao: StatusConexao.jogando,
          limparErro: true,
        );

        return true;
      } else {
        debugPrint('❌ Reconexão manual falhou');

        state = state.copyWith(
          conectando: false,
          statusConexao: StatusConexao.erro,
          erro: 'Falha na reconexão. Servidor pode estar indisponível.',
        );

        return false;
      }
    } catch (e) {
      debugPrint('❌ Erro na reconexão manual: $e');

      state = state.copyWith(
        conectando: false,
        statusConexao: StatusConexao.erro,
        erro: 'Erro na reconexão: $e',
      );

      return false;
    } finally {
      _hasActiveReconnection = false;
    }
  }

  /// Limpa o estado salvo do jogo (chamado quando jogo termina normalmente)
  Future<void> clearSavedGameState() async {
    try {
      await GamePersistence.clearActiveGameState();
      debugPrint('✅ Estado salvo do jogo limpo');
    } catch (e) {
      debugPrint('❌ Erro ao limpar estado salvo: $e');
    }
  }
}
