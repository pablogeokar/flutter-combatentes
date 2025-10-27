# board.gd
extends Node2D

# Define o tamanho do tabuleiro e das células
const TAMANHO_TABULEIRO = Vector2i(10, 10)
const TAMANHO_CELULA = Vector2(64, 64) # Ajuste conforme o tamanho das suas texturas

# Preload da cena da peça para instanciar
var PecaScene = preload("res://scenes/piece.tscn")

var pecas_no_tabuleiro = {}
var highlighted_cells: Dictionary = {} # Armazena as células destacadas e sua validade

func _ready():
	print("Cena do tabuleiro carregada.")
	_desenhar_grid() # Desenha um grid visual para depuração

# Desenha as linhas do grid para visualização
func _draw():
	# Desenha o grid
	for i in range(TAMANHO_TABULEIRO.x + 1):
		var x = i * TAMANHO_CELULA.x
		draw_line(Vector2(x, 0), Vector2(x, TAMANHO_TABULEIRO.y * TAMANHO_CELULA.y), Color.WHITE, 1.0)
	for i in range(TAMANHO_TABULEIRO.y + 1):
		var y = i * TAMANHO_CELULA.y
		draw_line(Vector2(0, y), Vector2(TAMANHO_TABULEIRO.x * TAMANHO_CELULA.x, y), Color.WHITE, 1.0)

	# Desenha os destaques das células
	for grid_pos in highlighted_cells:
		var is_valid = highlighted_cells[grid_pos]
		var color = Color("00ff00", 0.3) if is_valid else Color("ff0000", 0.3) # Verde para válido, Vermelho para inválido
		var rect_pos = Vector2(grid_pos.x, grid_pos.y) * TAMANHO_CELULA
		draw_rect(Rect2(rect_pos, TAMANHO_CELULA), color)


# Adiciona uma peça ao tabuleiro em uma determinada posição
func place_piece_on_board(peca_data): # peca_data é um Resource PecaJogo
	# Instancia a cena da peça
	var peca_node = PecaScene.instantiate()
	peca_node.setup(peca_data)
	peca_node.position = Vector2(peca_data.posicao.x, peca_data.posicao.y) * TAMANHO_CELULA
	add_child(peca_node)
	pecas_no_tabuleiro[peca_data.posicao] = peca_node

# Limpa todas as peças do tabuleiro
func clear_board():
	for peca_node in get_children():
		if peca_node is Sprite2D and peca_node.name != "Background":
			peca_node.queue_free()
	pecas_no_tabuleiro.clear()

# Função de depuração para desenhar um grid simples
func _desenhar_grid():
	# A função _draw() será chamada automaticamente para desenhar o grid
	queue_redraw()

# Converte uma posição global do mouse para uma coordenada de célula do grid
func get_cell_at_position(local_position: Vector2) -> Vector2i:
	var grid_x = int(local_position.x / TAMANHO_CELULA.x)
	var grid_y = int(local_position.y / TAMANHO_CELULA.y)

	if grid_x >= 0 and grid_x < TAMANHO_TABULEIRO.x and \
	   grid_y >= 0 and grid_y < TAMANHO_TABULEIRO.y:
		return Vector2i(grid_x, grid_y)
	return Vector2i(-1, -1) # Posição inválida

# Verifica se uma célula está ocupada
func is_cell_occupied(grid_pos: Vector2i) -> bool:
	return pecas_no_tabuleiro.has(grid_pos)

# Retorna a peça em uma determinada célula, se houver
func get_piece_at_cell(grid_pos: Vector2i) -> PecaJogo:
	var piece_node = pecas_no_tabuleiro.get(grid_pos)
	if piece_node:
		return piece_node.peca_data
	return null

# Retorna o nó da peça em uma determinada célula, se houver
func get_piece_node_at_cell(grid_pos: Vector2i) -> Node:
	return pecas_no_tabuleiro.get(grid_pos)

# Destaca uma célula no tabuleiro
func highlight_cell(grid_pos: Vector2i, is_valid: bool):
	highlighted_cells[grid_pos] = is_valid
	queue_redraw() # Força o redesenho para mostrar o destaque

# Limpa todos os destaques do tabuleiro
func clear_highlights():
	highlighted_cells.clear()
	queue_redraw() # Força o redesenho para remover os destaques
