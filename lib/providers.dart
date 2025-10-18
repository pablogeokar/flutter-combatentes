
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import './game_controller.dart';
import './modelos_jogo.dart';

/// Um estado imutável que representa tudo o que é necessário para a UI da tela do jogo.
class TelaJogoState {
  final EstadoJogo estadoJogo;
  final String? idPecaSelecionada;
  final String? erro;

  const TelaJogoState({
    required this.estadoJogo,
    this.idPecaSelecionada,
    this.erro,
  });

  TelaJogoState copyWith({
    EstadoJogo? estadoJogo,
    String? idPecaSelecionada,
    String? erro,
    bool limparSelecao = false,
    bool limparErro = false,
  }) {
    return TelaJogoState(
      estadoJogo: estadoJogo ?? this.estadoJogo,
      idPecaSelecionada: limparSelecao ? null : idPecaSelecionada ?? this.idPecaSelecionada,
      erro: limparErro ? null : erro ?? this.erro,
    );
  }
}


/// Provider que cria e expõe uma única instância do [GameController].
final gameControllerProvider = Provider<GameController>((ref) {
  return GameController();
});

/// Provider que gerencia o estado da tela do jogo ([TelaJogoState]).
final gameStateProvider = StateNotifierProvider<GameStateNotifier, TelaJogoState>((ref) {
  return GameStateNotifier(ref);
});

class GameStateNotifier extends StateNotifier<TelaJogoState> {
  final Ref _ref;

  GameStateNotifier(this._ref) : super(_getInitialState());

  static TelaJogoState _getInitialState() {
    final jogador1 = const Jogador(id: 'j1', nome: 'Jogador 1', equipe: Equipe.preta);
    final jogador2 = const Jogador(id: 'j2', nome: 'Jogador 2', equipe: Equipe.verde);
    return TelaJogoState(
      estadoJogo: EstadoJogo(
        idPartida: 'partida_unica',
        jogadores: [jogador1, jogador2],
        pecas: _criarPecasIniciais(),
        idJogadorDaVez: jogador1.id,
      ),
    );
  }

  /// Seleciona uma peça, se ela pertencer ao jogador da vez.
  void selecionarPeca(String idPeca) {
    final peca = state.estadoJogo.pecas.firstWhere((p) => p.id == idPeca);
    final jogadorDaVez = state.estadoJogo.jogadores.firstWhere((j) => j.id == state.estadoJogo.idJogadorDaVez);

    if (peca.equipe == jogadorDaVez.equipe) {
      state = state.copyWith(idPecaSelecionada: idPeca, limparErro: true);
    }
  }

  /// Tenta mover a peça selecionada para uma nova posição.
  void moverPeca(PosicaoTabuleiro novaPosicao) {
    if (state.idPecaSelecionada == null) return;

    final gameController = _ref.read(gameControllerProvider);

    final resultado = gameController.moverPeca(
      estadoAtual: state.estadoJogo,
      idPeca: state.idPecaSelecionada!,
      novaPosicao: novaPosicao,
    );

    if (resultado.sucesso) {
      state = state.copyWith(
        estadoJogo: resultado.estadoJogo,
        limparSelecao: true,
        limparErro: true,
      );
    } else {
      state = state.copyWith(
        erro: resultado.mensagemErro,
        limparSelecao: true,
      );
    }
  }

  /// Reinicia o jogo para o seu estado inicial.
  void reiniciarJogo() {
    state = _getInitialState();
  }

  /// Cria a lista inicial de peças para um novo jogo.
  static List<PecaJogo> _criarPecasIniciais() {
    final List<PecaJogo> pecas = [];
    final random = Random();

    final Map<Patente, int> contagemPecas = {
      Patente.general: 1,
      Patente.coronel: 1,
      Patente.major: 2,
      Patente.capitao: 3,
      Patente.tenente: 4,
      Patente.sargento: 4,
      Patente.cabo: 4,
      Patente.soldado: 5,
      Patente.agenteSecreto: 1,
      Patente.prisioneiro: 1,
      Patente.minaTerrestre: 6,
    };

    final List<PosicaoTabuleiro> posicoesPretas = [];
    for (int i = 0; i < 4; i++) {
      for (int j = 0; j < 10; j++) {
        posicoesPretas.add(PosicaoTabuleiro(linha: i, coluna: j));
      }
    }
    posicoesPretas.shuffle(random);

    int posIndexPreto = 0;
    contagemPecas.forEach((patente, quantidade) {
      for (int i = 0; i < quantidade; i++) {
        pecas.add(PecaJogo(
          id: 'preta_${patente.name}_$i',
          patente: patente,
          equipe: Equipe.preta,
          posicao: posicoesPretas[posIndexPreto++],
        ));
      }
    });

    final List<PosicaoTabuleiro> posicoesVerdes = [];
    for (int i = 6; i < 10; i++) {
      for (int j = 0; j < 10; j++) {
        posicoesVerdes.add(PosicaoTabuleiro(linha: i, coluna: j));
      }
    }
    posicoesVerdes.shuffle(random);

    int posIndexVerde = 0;
    contagemPecas.forEach((patente, quantidade) {
      for (int i = 0; i < quantidade; i++) {
        pecas.add(PecaJogo(
          id: 'verde_${patente.name}_$i',
          patente: patente,
          equipe: Equipe.verde,
          posicao: posicoesVerdes[posIndexVerde++],
        ));
      }
    });

    return pecas;
  }
}
