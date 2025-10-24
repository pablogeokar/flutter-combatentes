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

/// Um enum para representar as diferentes fases do jogo.
@JsonEnum()
enum GamePhase {
  /// Aguardando pareamento com oponente.
  waitingForOpponent,

  /// Fase de posicionamento manual de peças.
  piecePlacement,

  /// Aguardando oponente confirmar posicionamento.
  waitingForOpponentReady,

  /// Iniciando a partida (countdown).
  gameStarting,

  /// Jogo em andamento.
  gameInProgress,

  /// Jogo terminado.
  gameFinished,
}

/// Um enum para representar o status do posicionamento de peças.
@JsonEnum()
enum PlacementStatus {
  /// Jogador está posicionando peças.
  placing,

  /// Jogador confirmou posicionamento e está pronto.
  ready,

  /// Jogador está aguardando o oponente.
  waiting,
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
  general(forca: 9, nome: "General"),
  marechal(forca: 10, nome: "Marechal"),
  minaTerrestre(forca: 11, nome: "Mina Terrestre");

  /// A força da patente, usada para determinar o vencedor de um combate.
  final int forca;

  /// O nome da patente para exibição na interface do usuário.
  final String nome;

  const Patente({required this.forca, required this.nome});

  /// Retorna o caminho da imagem correspondente à patente.
  String get imagePath {
    switch (this) {
      case Patente.prisioneiro:
        return 'assets/images/pecas/prisioneiro.png';
      case Patente.agenteSecreto:
        return 'assets/images/pecas/agenteSecreto.png';
      case Patente.soldado:
        return 'assets/images/pecas/soldado.png';
      case Patente.cabo:
        return 'assets/images/pecas/cabo.png';
      case Patente.sargento:
        return 'assets/images/pecas/sargento.png';
      case Patente.tenente:
        return 'assets/images/pecas/tenente.png';
      case Patente.capitao:
        return 'assets/images/pecas/capitao.png';
      case Patente.major:
        return 'assets/images/pecas/major.png';
      case Patente.coronel:
        return 'assets/images/pecas/coronel.png';
      case Patente.general:
        return 'assets/images/pecas/general.png';
      case Patente.marechal:
        return 'assets/images/pecas/marechal.png';
      case Patente.minaTerrestre:
        return 'assets/images/pecas/minaTerrestre.png';
    }
  }
}

/// Representa uma coordenada (linha e coluna) no tabuleiro.
@JsonSerializable()
class PosicaoTabuleiro {
  /// A linha no tabuleiro.
  final int linha;

  /// A coluna no tabuleiro.
  final int coluna;

  const PosicaoTabuleiro({required this.linha, required this.coluna});

  factory PosicaoTabuleiro.fromJson(Map<String, dynamic> json) =>
      _$PosicaoTabuleiroFromJson(json);
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

  factory PecaJogo.fromJson(Map<String, dynamic> json) =>
      _$PecaJogoFromJson(json);
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

  const Jogador({required this.id, required this.nome, required this.equipe});

  factory Jogador.fromJson(Map<String, dynamic> json) =>
      _$JogadorFromJson(json);
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

  factory EstadoJogo.fromJson(Map<String, dynamic> json) =>
      _$EstadoJogoFromJson(json);
  Map<String, dynamic> toJson() => _$EstadoJogoToJson(this);
}

/// Representa o estado do jogo durante a fase de posicionamento de peças.
@JsonSerializable(explicitToJson: true)
class PlacementGameState {
  /// ID único para a partida.
  final String gameId;

  /// ID do jogador local.
  final String playerId;

  /// Inventário de peças disponíveis para posicionamento (patente -> quantidade).
  final Map<String, int> availablePieces;

  /// Lista de peças já posicionadas no tabuleiro.
  final List<PecaJogo> placedPieces;

  /// Linhas válidas para posicionamento do jogador (ex: [0,1,2,3] ou [6,7,8,9]).
  final List<int> playerArea;

  /// Status do posicionamento do jogador local.
  final PlacementStatus localStatus;

  /// Status do posicionamento do oponente.
  final PlacementStatus opponentStatus;

  /// Tipo de peça atualmente selecionado para posicionamento.
  final Patente? selectedPieceType;

  /// Fase atual do jogo.
  final GamePhase gamePhase;

  const PlacementGameState({
    required this.gameId,
    required this.playerId,
    required this.availablePieces,
    required this.placedPieces,
    required this.playerArea,
    required this.localStatus,
    required this.opponentStatus,
    this.selectedPieceType,
    required this.gamePhase,
  });

  factory PlacementGameState.fromJson(Map<String, dynamic> json) =>
      _$PlacementGameStateFromJson(json);
  Map<String, dynamic> toJson() => _$PlacementGameStateToJson(this);

  /// Cria o inventário inicial de peças para um jogador (40 peças total).
  static Map<String, int> createInitialInventory() {
    return {
      'marechal': 1,
      'general': 1,
      'coronel': 2,
      'major': 3,
      'capitao': 4,
      'tenente': 4,
      'sargento': 4,
      'cabo': 5,
      'soldado': 8,
      'agenteSecreto': 1,
      'prisioneiro': 1,
      'minaTerrestre': 6,
    };
  }

  /// Retorna o número total de peças restantes no inventário.
  int get totalPiecesRemaining {
    return availablePieces.values.fold(0, (sum, count) => sum + count);
  }

  /// Verifica se todas as peças foram posicionadas.
  bool get allPiecesPlaced {
    return totalPiecesRemaining == 0;
  }

  /// Verifica se o jogador pode confirmar o posicionamento.
  bool get canConfirm {
    return allPiecesPlaced && localStatus == PlacementStatus.placing;
  }
}

/// Representa uma mensagem WebSocket para comunicação durante o posicionamento.
@JsonSerializable(explicitToJson: true)
class PlacementMessage {
  /// Tipo da mensagem.
  final String type;

  /// ID da partida.
  final String gameId;

  /// ID do jogador que enviou a mensagem.
  final String playerId;

  /// Dados específicos da mensagem.
  final PlacementMessageData? data;

  const PlacementMessage({
    required this.type,
    required this.gameId,
    required this.playerId,
    this.data,
  });

  factory PlacementMessage.fromJson(Map<String, dynamic> json) =>
      _$PlacementMessageFromJson(json);
  Map<String, dynamic> toJson() => _$PlacementMessageToJson(this);

  /// Cria uma mensagem de atualização de posicionamento.
  factory PlacementMessage.placementUpdate({
    required String gameId,
    required String playerId,
    required String pieceId,
    required Patente patente,
    required PosicaoTabuleiro position,
  }) {
    return PlacementMessage(
      type: 'PLACEMENT_UPDATE',
      gameId: gameId,
      playerId: playerId,
      data: PlacementMessageData(
        pieceId: pieceId,
        patente: patente,
        position: position,
      ),
    );
  }

  /// Cria uma mensagem de confirmação de posicionamento.
  factory PlacementMessage.placementReady({
    required String gameId,
    required String playerId,
    required List<PecaJogo> allPieces,
  }) {
    return PlacementMessage(
      type: 'PLACEMENT_READY',
      gameId: gameId,
      playerId: playerId,
      data: PlacementMessageData(allPieces: allPieces),
    );
  }

  /// Cria uma mensagem de status do posicionamento.
  factory PlacementMessage.placementStatus({
    required String gameId,
    required String playerId,
    required PlacementStatus status,
  }) {
    return PlacementMessage(
      type: 'PLACEMENT_STATUS',
      gameId: gameId,
      playerId: playerId,
      data: PlacementMessageData(status: status),
    );
  }

  /// Cria uma mensagem de início do jogo.
  factory PlacementMessage.gameStart({
    required String gameId,
    required String playerId,
  }) {
    return PlacementMessage(
      type: 'GAME_START',
      gameId: gameId,
      playerId: playerId,
    );
  }
}

/// Dados específicos de uma mensagem de posicionamento.
@JsonSerializable(explicitToJson: true)
class PlacementMessageData {
  /// ID da peça (para atualizações de posição).
  final String? pieceId;

  /// Patente da peça (para atualizações de posição).
  final Patente? patente;

  /// Nova posição da peça.
  final PosicaoTabuleiro? position;

  /// Status do posicionamento.
  final PlacementStatus? status;

  /// Lista completa de peças (para confirmação).
  final List<PecaJogo>? allPieces;

  const PlacementMessageData({
    this.pieceId,
    this.patente,
    this.position,
    this.status,
    this.allPieces,
  });

  factory PlacementMessageData.fromJson(Map<String, dynamic> json) =>
      _$PlacementMessageDataFromJson(json);
  Map<String, dynamic> toJson() => _$PlacementMessageDataToJson(this);
}
