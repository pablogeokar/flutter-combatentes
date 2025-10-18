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
