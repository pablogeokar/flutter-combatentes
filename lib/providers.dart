import 'package:flutter_riverpod/flutter_riverpod.dart';
import './game_socket_service.dart';
import './modelos_jogo.dart';
import './services/user_preferences.dart';
import './game_controller.dart';

/// Estados possíveis da conexão
enum StatusConexao {
  conectando('Conectando ao servidor...'),
  conectado('Conectado ao servidor. Aguardando oponente...'),
  jogando('Partida em andamento'),
  desconectado('Desconectado do servidor'),
  erro('Erro de conexão');

  const StatusConexao(this.mensagem);
  final String mensagem;
}

/// Um estado imutável que representa tudo o que é necessário para a UI da tela do jogo.
class TelaJogoState {
  /// O estado do jogo pode ser nulo durante a conexão inicial.
  final EstadoJogo? estadoJogo;
  final String? idPecaSelecionada;
  final List<PosicaoTabuleiro> movimentosValidos;
  final String? erro;
  final bool conectando;
  final String? nomeUsuario;
  final StatusConexao statusConexao;

  const TelaJogoState({
    this.estadoJogo,
    this.idPecaSelecionada,
    this.movimentosValidos = const [],
    this.erro,
    this.conectando = true,
    this.nomeUsuario,
    this.statusConexao = StatusConexao.conectando,
  });

  TelaJogoState copyWith({
    EstadoJogo? estadoJogo,
    String? idPecaSelecionada,
    List<PosicaoTabuleiro>? movimentosValidos,
    String? erro,
    bool? conectando,
    String? nomeUsuario,
    StatusConexao? statusConexao,
    bool limparSelecao = false,
    bool limparErro = false,
  }) {
    return TelaJogoState(
      estadoJogo: estadoJogo ?? this.estadoJogo,
      idPecaSelecionada: limparSelecao
          ? null
          : idPecaSelecionada ?? this.idPecaSelecionada,
      movimentosValidos: limparSelecao
          ? const []
          : movimentosValidos ?? this.movimentosValidos,
      erro: limparErro ? null : erro ?? this.erro,
      conectando: conectando ?? this.conectando,
      nomeUsuario: nomeUsuario ?? this.nomeUsuario,
      statusConexao: statusConexao ?? this.statusConexao,
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
  final GameController _gameController = GameController();

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
        state = state.copyWith(
          estadoJogo: novoEstado,
          conectando: false,
          statusConexao: StatusConexao.jogando,
          limparErro: true,
        );
      });

      socketService.streamDeErros.listen((mensagemErro) {
        state = state.copyWith(erro: mensagemErro);
      });

      socketService.streamDeStatus.listen((novoStatus) {
        state = state.copyWith(
          statusConexao: novoStatus,
          conectando: novoStatus == StatusConexao.conectando,
        );
      });

      // Conecta ao servidor
      socketService.connect('ws://localhost:8083', nomeUsuario: nomeUsuario);
    } catch (e) {
      print('Erro na inicialização: $e');
      state = state.copyWith(
        conectando: false,
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
    if (state.idPecaSelecionada == null) return;

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

  /// Tenta reconectar ao servidor
  void reconnect() {
    _reconnectAsync();
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
      socketService.reconnect('ws://localhost:8083', nomeUsuario: nomeUsuario);
    } catch (e) {
      print('Erro na reconexão: $e');
      state = state.copyWith(conectando: false, erro: 'Erro ao reconectar: $e');
    }
  }
}
