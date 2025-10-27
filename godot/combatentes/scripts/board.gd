# board.gd
extends Node2D

# Define o tamanho do tabuleiro e das células
const TAMANHO_TABULEIRO = Vector2i(10, 10)
const TAMANHO_CELULA = Vector2(64, 64) # Ajuste conforme o tamanho das suas texturas

# Preload da cena da peça para instanciar
# (Será criada na próxima etapa)
var PecaScene = preload("res://scenes/piece.tscn")

var pecas_no_tabuleiro = {}

func _ready():
	print("Cena do tabuleiro carregada.")
	_desenhar_grid() # Desenha um grid visual para depuração

# Desenha as linhas do grid para visualização
func _draw():
	for i in range(TAMANHO_TABULEIRO.x + 1):
		var x = i * TAMANHO_CELULA.x
		draw_line(Vector2(x, 0), Vector2(x, TAMANHO_TABULEIRO.y * TAMANHO_CELULA.y), Color.WHITE, 1.0)
	for i in range(TAMANHO_TABULEIRO.y + 1):
		var y = i * TAMANHO_CELULA.y
		draw_line(Vector2(0, y), Vector2(TAMANHO_TABULEIRO.x * TAMANHO_CELULA.x, y), Color.WHITE, 1.0)


# Adiciona uma peça ao tabuleiro em uma determinada posição
func adicionar_peca(peca_data): # peca_data é um Resource PecaJogo
	# Instancia a cena da peça (a ser criada)
	# var peca_node = PecaScene.instantiate()
	# peca_node.setup(peca_data)
	# peca_node.position = peca_data.posicao * TAMANHO_CELULA
	# add_child(peca_node)
	# pecas_no_tabuleiro[peca_data.posicao] = peca_node
	pass

# Limpa todas as peças do tabuleiro
func limpar_tabuleiro():
	for peca_node in get_children():
		if peca_node is Sprite2D and peca_node.name != "Background":
			peca_node.queue_free()
	pecas_no_tabuleiro.clear()

# Função de depuração para desenhar um grid simples
func _desenhar_grid():
	# A função _draw() será chamada automaticamente para desenhar o grid
	queue_redraw()
