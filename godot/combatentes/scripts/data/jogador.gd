# jogador.gd
# Representa um jogador na partida.

extends Resource
class_name Jogador

const Enums = preload("res://scripts/data/enums.gd")

@export var id: String
@export var nome: String
@export var equipe: Enums.Equipe

func _init(p_id: String = "", p_nome: String = "", p_equipe: Enums.Equipe = Enums.Equipe.VERDE):
	id = p_id
	nome = p_nome
	equipe = p_equipe
