# estado_jogo.gd
# O modelo de nível superior que representa todo o estado de uma partida.

extends Resource
class_name EstadoJogo

const Jogador = preload("res://scripts/data/jogador.gd")
const PecaJogo = preload("res://scripts/data/peca_jogo.gd")

@export var id_partida: String
@export var jogadores: Array[Jogador]
@export var pecas: Array[PecaJogo]
@export var id_jogador_da_vez: String
@export var jogo_terminou: bool = false
@export var id_vencedor: String
