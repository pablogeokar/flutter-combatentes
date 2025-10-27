# peca_jogo.gd
# Representa uma única peça no tabuleiro.

extends Resource
class_name PecaJogo

# Importa os enums
const Enums = preload("res://scripts/data/enums.gd")

# Propriedades da peça
@export var id: String
@export var patente: Enums.Patente
@export var equipe: Enums.Equipe
@export var posicao: Vector2i # Usando Vector2i para linha e coluna
@export var foi_revelada: bool = false

# Informações estáticas da patente (força, nome, imagem)
const INFO_PATENTES = {
	[Enums.Patente.PRISIONEIRO]: {"forca": 0, "nome": "Prisioneiro", "imagem": "res://assets/images/pecas/prisioneiro.png"},
	[Enums.Patente.AGENTE_SECRETO]: {"forca": 1, "nome": "Agente Secreto", "imagem": "res://assets/images/pecas/agenteSecreto.png"},
	[Enums.Patente.SOLDADO]: {"forca": 2, "nome": "Soldado", "imagem": "res://assets/images/pecas/soldado.png"},
	[Enums.Patente.CABO]: {"forca": 3, "nome": "Cabo", "imagem": "res://assets/images/pecas/cabo.png"},
	[Enums.Patente.SARGENTO]: {"forca": 4, "nome": "Sargento", "imagem": "res://assets/images/pecas/sargento.png"},
	[Enums.Patente.TENENTE]: {"forca": 5, "nome": "Tenente", "imagem": "res://assets/images/pecas/tenente.png"},
	[Enums.Patente.CAPITAO]: {"forca": 6, "nome": "Capitão", "imagem": "res://assets/images/pecas/capitao.png"},
	[Enums.Patente.MAJOR]: {"forca": 7, "nome": "Major", "imagem": "res://assets/images/pecas/major.png"},
	[Enums.Patente.CORONEL]: {"forca": 8, "nome": "Coronel", "imagem": "res://assets/images/pecas/coronel.png"},
	[Enums.Patente.GENERAL]: {"forca": 9, "nome": "General", "imagem": "res://assets/images/pecas/general.png"},
	[Enums.Patente.MARECHAL]: {"forca": 10, "nome": "Marechal", "imagem": "res://assets/images/pecas/marechal.png"},
	[Enums.Patente.MINA_TERRESTRE]: {"forca": 11, "nome": "Mina Terrestre", "imagem": "res://assets/images/pecas/minaTerrestre.png"}
}

func _init(p_id: String = "", p_patente: Enums.Patente = Enums.Patente.SOLDADO, p_equipe: Enums.Equipe = Enums.Equipe.VERDE, p_posicao: Vector2i = Vector2i.ZERO):
	id = p_id
	patente = p_patente
	equipe = p_equipe
	posicao = p_posicao

# Funções para obter informações da patente
func get_forca() -> int:
	return INFO_PATENTES[patente].forca

func get_nome() -> String:
	return INFO_PATENTES[patente].nome

func get_imagem_path() -> String:
	return INFO_PATENTES[patente].imagem
