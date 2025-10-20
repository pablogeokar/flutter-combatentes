// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'modelos_jogo.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PosicaoTabuleiro _$PosicaoTabuleiroFromJson(Map<String, dynamic> json) =>
    PosicaoTabuleiro(
      linha: (json['linha'] as num).toInt(),
      coluna: (json['coluna'] as num).toInt(),
    );

Map<String, dynamic> _$PosicaoTabuleiroToJson(PosicaoTabuleiro instance) =>
    <String, dynamic>{'linha': instance.linha, 'coluna': instance.coluna};

PecaJogo _$PecaJogoFromJson(Map<String, dynamic> json) => PecaJogo(
  id: json['id'] as String,
  patente: $enumDecode(_$PatenteEnumMap, json['patente']),
  equipe: $enumDecode(_$EquipeEnumMap, json['equipe']),
  posicao: PosicaoTabuleiro.fromJson(json['posicao'] as Map<String, dynamic>),
  foiRevelada: json['foiRevelada'] as bool? ?? false,
);

Map<String, dynamic> _$PecaJogoToJson(PecaJogo instance) => <String, dynamic>{
  'id': instance.id,
  'patente': _$PatenteEnumMap[instance.patente]!,
  'equipe': _$EquipeEnumMap[instance.equipe]!,
  'posicao': instance.posicao.toJson(),
  'foiRevelada': instance.foiRevelada,
};

const _$PatenteEnumMap = {
  Patente.prisioneiro: 'prisioneiro',
  Patente.agenteSecreto: 'agenteSecreto',
  Patente.soldado: 'soldado',
  Patente.cabo: 'cabo',
  Patente.sargento: 'sargento',
  Patente.tenente: 'tenente',
  Patente.capitao: 'capitao',
  Patente.major: 'major',
  Patente.coronel: 'coronel',
  Patente.general: 'general',
  Patente.marechal: 'marechal',
  Patente.minaTerrestre: 'minaTerrestre',
};

const _$EquipeEnumMap = {Equipe.verde: 'verde', Equipe.preta: 'preta'};

Jogador _$JogadorFromJson(Map<String, dynamic> json) => Jogador(
  id: json['id'] as String,
  nome: json['nome'] as String,
  equipe: $enumDecode(_$EquipeEnumMap, json['equipe']),
);

Map<String, dynamic> _$JogadorToJson(Jogador instance) => <String, dynamic>{
  'id': instance.id,
  'nome': instance.nome,
  'equipe': _$EquipeEnumMap[instance.equipe]!,
};

EstadoJogo _$EstadoJogoFromJson(Map<String, dynamic> json) => EstadoJogo(
  idPartida: json['idPartida'] as String,
  jogadores: (json['jogadores'] as List<dynamic>)
      .map((e) => Jogador.fromJson(e as Map<String, dynamic>))
      .toList(),
  pecas: (json['pecas'] as List<dynamic>)
      .map((e) => PecaJogo.fromJson(e as Map<String, dynamic>))
      .toList(),
  idJogadorDaVez: json['idJogadorDaVez'] as String,
  jogoTerminou: json['jogoTerminou'] as bool? ?? false,
  idVencedor: json['idVencedor'] as String?,
);

Map<String, dynamic> _$EstadoJogoToJson(EstadoJogo instance) =>
    <String, dynamic>{
      'idPartida': instance.idPartida,
      'jogadores': instance.jogadores.map((e) => e.toJson()).toList(),
      'pecas': instance.pecas.map((e) => e.toJson()).toList(),
      'idJogadorDaVez': instance.idJogadorDaVez,
      'jogoTerminou': instance.jogoTerminou,
      'idVencedor': instance.idVencedor,
    };

PlacementGameState _$PlacementGameStateFromJson(Map<String, dynamic> json) =>
    PlacementGameState(
      gameId: json['gameId'] as String,
      playerId: json['playerId'] as String,
      availablePieces: Map<String, int>.from(json['availablePieces'] as Map),
      placedPieces: (json['placedPieces'] as List<dynamic>)
          .map((e) => PecaJogo.fromJson(e as Map<String, dynamic>))
          .toList(),
      playerArea: (json['playerArea'] as List<dynamic>)
          .map((e) => (e as num).toInt())
          .toList(),
      localStatus: $enumDecode(_$PlacementStatusEnumMap, json['localStatus']),
      opponentStatus: $enumDecode(
        _$PlacementStatusEnumMap,
        json['opponentStatus'],
      ),
      selectedPieceType: $enumDecodeNullable(
        _$PatenteEnumMap,
        json['selectedPieceType'],
      ),
      gamePhase: $enumDecode(_$GamePhaseEnumMap, json['gamePhase']),
    );

Map<String, dynamic> _$PlacementGameStateToJson(PlacementGameState instance) =>
    <String, dynamic>{
      'gameId': instance.gameId,
      'playerId': instance.playerId,
      'availablePieces': instance.availablePieces,
      'placedPieces': instance.placedPieces.map((e) => e.toJson()).toList(),
      'playerArea': instance.playerArea,
      'localStatus': _$PlacementStatusEnumMap[instance.localStatus]!,
      'opponentStatus': _$PlacementStatusEnumMap[instance.opponentStatus]!,
      'selectedPieceType': _$PatenteEnumMap[instance.selectedPieceType],
      'gamePhase': _$GamePhaseEnumMap[instance.gamePhase]!,
    };

const _$PlacementStatusEnumMap = {
  PlacementStatus.placing: 'placing',
  PlacementStatus.ready: 'ready',
  PlacementStatus.waiting: 'waiting',
};

const _$GamePhaseEnumMap = {
  GamePhase.waitingForOpponent: 'waitingForOpponent',
  GamePhase.piecePlacement: 'piecePlacement',
  GamePhase.waitingForOpponentReady: 'waitingForOpponentReady',
  GamePhase.gameStarting: 'gameStarting',
  GamePhase.gameInProgress: 'gameInProgress',
  GamePhase.gameFinished: 'gameFinished',
};

PlacementMessage _$PlacementMessageFromJson(Map<String, dynamic> json) =>
    PlacementMessage(
      type: json['type'] as String,
      gameId: json['gameId'] as String,
      playerId: json['playerId'] as String,
      data: json['data'] == null
          ? null
          : PlacementMessageData.fromJson(json['data'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PlacementMessageToJson(PlacementMessage instance) =>
    <String, dynamic>{
      'type': instance.type,
      'gameId': instance.gameId,
      'playerId': instance.playerId,
      'data': instance.data?.toJson(),
    };

PlacementMessageData _$PlacementMessageDataFromJson(
  Map<String, dynamic> json,
) => PlacementMessageData(
  pieceId: json['pieceId'] as String?,
  patente: $enumDecodeNullable(_$PatenteEnumMap, json['patente']),
  position: json['position'] == null
      ? null
      : PosicaoTabuleiro.fromJson(json['position'] as Map<String, dynamic>),
  status: $enumDecodeNullable(_$PlacementStatusEnumMap, json['status']),
  allPieces: (json['allPieces'] as List<dynamic>?)
      ?.map((e) => PecaJogo.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$PlacementMessageDataToJson(
  PlacementMessageData instance,
) => <String, dynamic>{
  'pieceId': instance.pieceId,
  'patente': _$PatenteEnumMap[instance.patente],
  'position': instance.position?.toJson(),
  'status': _$PlacementStatusEnumMap[instance.status],
  'allPieces': instance.allPieces?.map((e) => e.toJson()).toList(),
};
