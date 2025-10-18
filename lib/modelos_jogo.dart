
import 'package:json_annotation/json_annotation.dart';

part 'modelos_jogo.g.dart';

/// Um enum para representar as duas equipes adversárias.
@JsonEnum()
enum Equipe {
  /// A equipe verde.
  verde,
  /// A equipe preta.
  preta,
}

/// Um enum para representar todas as patentes possíveis das peças.
@JsonEnum()
enum Patente {
  prisioneiro(forca: 0, nome: "Prisioneiro"),
  agenteSecreto(forca: 1, nome: "Agente Secreto"),
  soldado(forca: 2, nome: "Soldado"),
  cabo(forca: 3, nome: "Cabo"),
  sargento(forca: 4, nome: "Sargento"),
  tenente(forca: 5, nome: "Tenente"),
  capitao(forca: 6, nome: "Capitão"),
  major(forca: 7, nome: "Major"),
  coronel(forca: 8, nome: "Coronel"),
  general(forca: 10, nome: "General"),
  minaTerrestre(forca: 11, nome: "Mina Terrestre");

  /// A força da patente, usada para determinar o vencedor de um combate.
  final int forca;
  /// O nome da patente para exibição na interface do usuário.
  final String nome;

  const Patente({required this.forca, required this.nome});
}

/// Representa uma coordenada (linha e coluna) no tabuleiro.
@JsonSerializable()
class PosicaoTabuleiro {
  /// A linha no tabuleiro.
  final int linha;
  /// A coluna no tabuleiro.
  final int coluna;

  const PosicaoTabuleiro({required this.linha, required this.coluna});

  factory PosicaoTabuleiro.fromJson(Map<String, dynamic> json) => _$PosicaoTabuleiroFromJson(json);
  Map<String, dynamic> toJson() => _$PosicaoTabuleiroToJson(this);
}

/// O modelo principal que representa uma única peça no tabuleiro.
@JsonSerializable(explicitToJson: true)
class PecaJogo {
  /// Um identificador único para a peça (essencial para multiplayer).
  final String id;
  /// A patente da peça, vinda do enum `Patente`.
  final Patente patente;
  /// A equipe a qual esta peça pertence.
  final Equipe equipe;
  /// A posição atual da peça no tabuleiro.
  final PosicaoTabuleiro posicao;
  /// `false` por padrão. Torna-se `true` após o primeiro combate.
  final bool foiRevelada;

  const PecaJogo({
    required this.id,
    required this.patente,
    required this.equipe,
    required this.posicao,
    this.foiRevelada = false,
  });

  factory PecaJogo.fromJson(Map<String, dynamic> json) => _$PecaJogoFromJson(json);
  Map<String, dynamic> toJson() => _$PecaJogoToJson(this);
}

/// Representa um jogador na partida.
@JsonSerializable()
class Jogador {
  /// O ID de usuário único do jogador.
  final String id;
  /// O nome de exibição do jogador.
  final String nome;
  /// A equipe que o jogador está controlando.
  final Equipe equipe;

  const Jogador({
    required this.id,
    required this.nome,
    required this.equipe,
  });

  factory Jogador.fromJson(Map<String, dynamic> json) => _$JogadorFromJson(json);
  Map<String, dynamic> toJson() => _$JogadorToJson(this);
}

/// O modelo de nível superior que representa todo o estado de uma partida.
/// Este é o objeto principal que será enviado pela rede.
@JsonSerializable(explicitToJson: true)
class EstadoJogo {
  /// ID único para a partida.
  final String idPartida;
  /// Uma lista dos dois jogadores na partida.
  final List<Jogador> jogadores;
  /// Uma lista de todas as peças atualmente no tabuleiro.
  final List<PecaJogo> pecas;
  /// O ID do jogador que deve fazer a próxima jogada.
  final String idJogadorDaVez;
  /// `false` por padrão, `true` quando uma condição de vitória é atingida.
  final bool jogoTerminou;
  /// O ID do jogador vencedor, `null` até o jogo terminar.
  final String? idVencedor;

  const EstadoJogo({
    required this.idPartida,
    required this.jogadores,
    required this.pecas,
    required this.idJogadorDaVez,
    this.jogoTerminou = false,
    this.idVencedor,
  });

  factory EstadoJogo.fromJson(Map<String, dynamic> json) => _$EstadoJogoFromJson(json);
  Map<String, dynamic> toJson() => _$EstadoJogoToJson(this);
}
