# piece.gd
extends Sprite2D

const PecaJogo = preload("res://scripts/data/peca_jogo.gd")

var peca_data: PecaJogo

# Configura a peça com base nos dados do Resource PecaJogo
func setup(data: PecaJogo):
	peca_data = data
	
	# Carrega a textura da peça
	self.texture = load(peca_data.get_imagem_path())
	
	# Se a peça não for do jogador local, mostra o verso
	# (a lógica de equipe será adicionada depois)
	# if peca_data.equipe != jogador_local.equipe:
	# 	self.texture = load("res://assets/images/pecas/verso.png") # Exemplo

func _ready():
	pass
