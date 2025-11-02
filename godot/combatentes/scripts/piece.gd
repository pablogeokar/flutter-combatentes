# piece.gd
extends Sprite2D



var peca_data: PecaJogo
var is_selected: bool = false:
	set(value):
		is_selected = value
		_update_selection_visual()

# Configura a peça com base nos dados do Resource PecaJogo
func setup(data: PecaJogo):
	peca_data = data
	
	# Carrega a textura da peça
	self.texture = load(peca_data.get_imagem_path())
	
	# Se a peça não for do jogador local, mostra o verso
	# (a lógica de equipe será adicionada depois)
	# if peca_data.equipe != jogador_local.equipe:
	# 	self.texture = load("res://assets/images/pecas/verso.png") # Exemplo
	_update_selection_visual()

func _ready():
	pass

func _update_selection_visual():
	if is_selected:
		modulate = Color("ffff00") # Amarelo para destaque
	else:
		modulate = Color("ffffff") # Cor normal