import 'package:flutter_riverpod/flutter_riverpod.dart';
import './game_socket_service.dart';
import './modelos_jogo.dart';
import './services/user_preferences.dart';

/// Um estado imutável que representa tudo o que é necessário para a UI da tela do jogo.
class TelaJogoState {
  /// O estado do jogo pode ser nulo durante a conexão inicial.
  final EstadoJogo? estadoJogo;
  final String? idPecaSelecionada;
  final String? erro;
  final bool conectando;
  final String? nomeUsuario;

  const TelaJogoState({
    this.estadoJogo,
    this.idPecaSelecionada,
    this.erro,
    this.conectando = true,
    this.nomeUsuario,
  });

  TelaJogoState copyWith({
    EstadoJogo? estadoJogo,
    String? idPecaSelecionada,
    String? erro,
    bool? conectando,
    String? nomeUsuario,
    bool limparSelecao = false,
    bool limparErro = false,
  }) {
    return TelaJogoState(
      estadoJogo: estadoJogo ?? this.estadoJogo,
      idPecaSelecionada: limparSelecao
          ? null
          : idPecaSelecionada ?? this.idPecaSelecionada,
      erro: limparErro ? null : erro ?? this.erro,
      conectando: conectando ?? this.conectando,
      nomeUsuario: nomeUsuario ?? this.nomeUsuario,
    );
  }
}

/// Provider que cria e gerencia a instância do [GameSocketService].
final gameSocketProvider = Provider<GameSocketService>((ref) {
  final service = GameSocketService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// Provider que gerencia o estado da tela do jogo, agora orientado pela rede.
final gameStateProvider =
    StateNotifierProvider<GameStateNotifier, TelaJogoState>((ref) {
      return GameStateNotifier(ref);
    });

class GameStateNotifier extends StateNotifier<TelaJogoState> {
  final Ref _ref;

  GameStateNotifier(this._ref) : super(const TelaJogoState()) {
    _init();
  }

  void _init() async {
    // Carrega o nome do usuário
    final nomeUsuario = await UserPreferences.getUserName();
    state = state.copyWith(nomeUsuario: nomeUsuario);

    final socketService = _ref.read(gameSocketProvider);
    // Conecta ao servidor. Troque 'localhost' pelo IP da sua máquina se estiver testando em um dispositivo físico.
    socketService.connect('ws://localhost:8080', nomeUsuario: nomeUsuario);

    // Ouve por atualizações de estado vindas do servidor.
    socketService.streamDeEstados.listen((novoEstado) {
      state = state.copyWith(
        estadoJogo: novoEstado,
        conectando: false,
        limparErro: true,
      );
    });

    // Ouve por mensagens de erro vindas do servidor.
    socketService.streamDeErros.listen((mensagemErro) {
      state = state.copyWith(erro: mensagemErro);
    });
  }

  /// Apenas armazena a peça selecionada localmente na UI.
  void selecionarPeca(String idPeca) {
    if (state.estadoJogo == null) return;

    final peca = state.estadoJogo!.pecas.firstWhere((p) => p.id == idPeca);
    final jogadorDaVez = state.estadoJogo!.jogadores.firstWhere(
      (j) => j.id == state.estadoJogo!.idJogadorDaVez,
    );

    // A lógica de quem pode selecionar o quê permanece no cliente para feedback visual rápido.
    if (peca.equipe == jogadorDaVez.equipe) {
      state = state.copyWith(idPecaSelecionada: idPeca, limparErro: true);
    }
  }

  /// Envia a intenção de movimento para o servidor.
  void moverPeca(PosicaoTabuleiro novaPosicao) {
    if (state.idPecaSelecionada == null) return;

    // A responsabilidade agora é apenas notificar o servidor.
    _ref
        .read(gameSocketProvider)
        .enviarMovimento(state.idPecaSelecionada!, novaPosicao);

    // A UI é limpa imediatamente para dar feedback, mas o estado autoritativo virá do servidor.
    state = state.copyWith(limparSelecao: true);
  }
}
