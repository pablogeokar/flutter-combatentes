

import 'package:combatentes/src/common/models/modelos_jogo.dart'; // Updated import

/// Estados possíveis da conexão
enum StatusConexao {
  conectando('Conectando ao servidor...'),
  conectado('Conectado ao servidor. Aguardando oponente...'),
  jogando('Partida em andamento'),
  oponenteDesconectado('Oponente desconectou'),
  desconectado('Desconectado do servidor'),
  erro('Erro de conexão');

  const StatusConexao(this.mensagem);
  final String mensagem;
}

/// Informações sobre um combate que ocorreu
class InformacoesCombate {
  final PecaJogo atacante;
  final PecaJogo defensor;
  final PecaJogo? vencedor;
  final bool foiEmpate;
  final PosicaoTabuleiro posicaoCombate;

  const InformacoesCombate({
    required this.atacante,
    required this.defensor,
    this.vencedor,
    required this.foiEmpate,
    required this.posicaoCombate,
  });
}

/// Informações sobre um movimento de peça
class InformacoesMovimento {
  final PecaJogo peca;
  final PosicaoTabuleiro posicaoInicial;
  final PosicaoTabuleiro posicaoFinal;
  final bool temCombate;

  const InformacoesMovimento({
    required this.peca,
    required this.posicaoInicial,
    required this.posicaoFinal,
    this.temCombate = false,
  });
}

/// Um estado imutável que representa tudo o que é necessário para a UI da tela do jogo.
class TelaJogoState {
  /// O estado do jogo pode ser nulo durante a conexão inicial.
  final EstadoJogo? estadoJogo;
  final String? idPecaSelecionada;
  final List<PosicaoTabuleiro> movimentosValidos;
  final InformacoesCombate? ultimoCombate;
  final InformacoesMovimento? ultimoMovimento;
  final String? erro;
  final bool conectando;
  final String? nomeUsuario;
  final StatusConexao statusConexao;

  const TelaJogoState({
    this.estadoJogo,
    this.idPecaSelecionada,
    this.movimentosValidos = const [],
    this.ultimoCombate,
    this.ultimoMovimento,
    this.erro,
    this.conectando = true,
    this.nomeUsuario,
    this.statusConexao = StatusConexao.conectando,
  });

  TelaJogoState copyWith({
    EstadoJogo? estadoJogo,
    String? idPecaSelecionada,
    List<PosicaoTabuleiro>? movimentosValidos,
    InformacoesCombate? ultimoCombate,
    InformacoesMovimento? ultimoMovimento,
    String? erro,
    bool? conectando,
    String? nomeUsuario,
    StatusConexao? statusConexao,
    bool limparSelecao = false,
    bool limparErro = false,
    bool limparCombate = false,
    bool limparMovimento = false,
  }) {
    return TelaJogoState(
      estadoJogo: estadoJogo ?? this.estadoJogo,
      idPecaSelecionada: limparSelecao
          ? null
          : idPecaSelecionada ?? this.idPecaSelecionada,
      movimentosValidos: limparSelecao
          ? const []
          : movimentosValidos ?? this.movimentosValidos,
      ultimoCombate: limparCombate ? null : ultimoCombate ?? this.ultimoCombate,
      ultimoMovimento: limparMovimento
          ? null
          : ultimoMovimento ?? this.ultimoMovimento,
      erro: limparErro ? null : erro ?? this.erro,
      conectando: conectando ?? this.conectando,
      nomeUsuario: nomeUsuario ?? this.nomeUsuario,
      statusConexao: statusConexao ?? this.statusConexao,
    );
  }
}
