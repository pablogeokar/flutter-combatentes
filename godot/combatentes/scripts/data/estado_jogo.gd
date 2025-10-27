# estado_jogo.gd
extends Resource
class_name EstadoJogo

const Jogador = preload("res://scripts/data/jogador.gd")
const PecaJogo = preload("res://scripts/data/peca_jogo.gd")
const Enums = preload("res://scripts/data/enums.gd")

@export var id_partida: String
@export var jogadores: Array[Jogador]
@export var pecas: Array[PecaJogo]
@export var id_jogador_da_vez: String
@export var jogo_terminou: bool = false
@export var id_vencedor: String

func _init(
	p_id_partida: String = "",
	p_jogadores: Array[Jogador] = [],
	p_pecas: Array[PecaJogo] = [],
	p_id_jogador_da_vez: String = "",
	p_jogo_terminou: bool = false,
	p_id_vencedor: String = ""
):
	id_partida = p_id_partida
	jogadores = p_jogadores
	pecas = p_pecas
	id_jogador_da_vez = p_id_jogador_da_vez
	jogo_terminou = p_jogo_terminou
	id_vencedor = p_id_vencedor

func to_dict() -> Dictionary:
	var jogadores_dict_array = []
	for jogador in jogadores:
		jogadores_dict_array.append(jogador.to_dict())

	var pecas_dict_array = []
	for peca in pecas:
		pecas_dict_array.append(peca.to_dict())

	return {
		"idPartida": id_partida,
		"jogadores": jogadores_dict_array,
		"pecas": pecas_dict_array,
		"idJogadorDaVez": id_jogador_da_vez,
		"jogoTerminou": jogo_terminou,
		"idVencedor": id_vencedor
	}