# piece_placement_screen.gd
extends Control

const PecaJogo = preload("res://scripts/data/peca_jogo.gd")
const Enums = preload("res://scripts/data/enums.gd")
const Patente = preload("res://scripts/data/enums.gd").Patente
const Equipe = preload("res://scripts/data/enums.gd").Equipe
const PlacementStatus = preload("res://scripts/data/enums.gd").PlacementStatus
const InventoryPieceWidgetScene = preload("res://scenes/ui/inventory_piece_widget.tscn")
const PieceScene = preload("res://scenes/piece.tscn")
const PlacementMessageClass = preload("res://scripts/data/placement_messages.gd")

@onready var pieces_grid = $HBoxContainer/InventoryContainer/PiecesGrid
@onready var confirm_button = $HBoxContainer/BoardContainer/ConfirmButton
@onready var status_label = $HBoxContainer/BoardContainer/StatusLabel
@onready var board_node = $HBoxContainer/BoardContainer/Board

var available_pieces = {}
var placed_pieces = []
var selected_piece_type: Patente = Patente.PRISIONEIRO # Default ou null

var dragging_piece_ghost: TextureRect = null
var is_dragging = false

var game_id: String
var player_id: String
var player_placement_area_rows: Array[int] # Linhas válidas para posicionamento

func _ready():
	print("🎯 PLACEMENT_SCREEN - Inicializando tela de posicionamento...")
	
	# Recupera informações da partida do Global
	game_id = Global.game_id
	player_id = Global.player_id
	player_placement_area_rows = Global.player_area
	
	print("🎯 PLACEMENT_SCREEN - Dados recuperados do Global:")
	print("  - game_id: ", game_id)
	print("  - player_id: ", player_id)
	print("  - player_area: ", player_placement_area_rows)

	print("🎯 PLACEMENT_SCREEN - Inicializando inventário...")
	_initialize_inventory()
	_update_inventory_display()
	confirm_button.disabled = true # Desabilita até todas as peças serem posicionadas

	print("🎯 PLACEMENT_SCREEN - Conectando aos sinais do WebSocket...")
	# Conecta aos sinais do WebSocketService para receber atualizações do oponente
	WebSocketService.connect("message_received", Callable(self, "_on_websocket_message_received"))
	
	print("✅ PLACEMENT_SCREEN - Inicialização concluída!")

func _initialize_inventory():
	# Lógica para criar o inventário inicial de peças (similar a createInitialInventory() do Flutter)
	available_pieces = {
		Patente.MARECHAL: 1,
		Patente.GENERAL: 1,
		Patente.CORONEL: 2,
		Patente.MAJOR: 3,
		Patente.CAPITAO: 4,
		Patente.TENENTE: 4,
		Patente.SARGENTO: 4,
		Patente.CABO: 5,
		Patente.SOLDADO: 8,
		Patente.AGENTE_SECRETO: 1,
		Patente.PRISIONEIRO: 1,
		Patente.MINA_TERRESTRE: 6,
	}

func _update_inventory_display():
	for child in pieces_grid.get_children():
		child.queue_free()
	
	for patente_enum in range(Patente.size()):
		var count = available_pieces.get(patente_enum, 0)
		if count > 0:
			var inventory_widget = InventoryPieceWidgetScene.instantiate()
			inventory_widget.setup(patente_enum, count)
			inventory_widget.connect("piece_selected", _on_inventory_piece_selected)
			pieces_grid.add_child(inventory_widget)

func _on_inventory_piece_selected(patente: Patente):
	# Desseleciona a peça anterior, se houver
	for child in pieces_grid.get_children():
		if child is PanelContainer and child.has_method("set_is_selected"):
			child.set_is_selected(false)

	selected_piece_type = patente
	print("Peça selecionada para posicionamento: ", Patente.keys()[patente])
	
	# Encontra o widget selecionado e o marca como selecionado
	for child in pieces_grid.get_children():
		if child is PanelContainer and child.has_method("get_current_patente") and child.get_current_patente() == patente:
			child.set_is_selected(true)
			break

	_start_drag_ghost()

func _start_drag_ghost():
	if selected_piece_type == null or available_pieces.get(selected_piece_type, 0) <= 0:
		return

	is_dragging = true

	if dragging_piece_ghost:
		dragging_piece_ghost.queue_free()

	dragging_piece_ghost = TextureRect.new()
	dragging_piece_ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE # Não interage com o mouse
	dragging_piece_ghost.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	dragging_piece_ghost.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	dragging_piece_ghost.custom_minimum_size = board_node.TAMANHO_CELULA

	var image_path = PecaJogo.INFO_PATENTES[selected_piece_type].imagem
	if image_path:
		dragging_piece_ghost.texture = load(image_path)

	add_child(dragging_piece_ghost)
	dragging_piece_ghost.global_position = get_global_mouse_position() - (board_node.TAMANHO_CELULA / 2)

func _input(event):
	if is_dragging:
		if event is InputEventMouseMotion:
			if dragging_piece_ghost:
				dragging_piece_ghost.global_position = get_global_mouse_position() - (board_node.TAMANHO_CELULA / 2)

			var mouse_pos = get_global_mouse_position()
			var board_local_pos = board_node.to_local(mouse_pos)
			var grid_pos = board_node.get_cell_at_position(board_local_pos)

			board_node.clear_highlights()
			if grid_pos != Vector2i(-1, -1):
				var is_valid_placement = _check_placement_validity(grid_pos)
				board_node.highlight_cell(grid_pos, is_valid_placement)

		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			_drop_piece()
			get_viewport().set_input_as_handled()

func _drop_piece():
	if not is_dragging:
		return

	is_dragging = false
	board_node.clear_highlights()

	if dragging_piece_ghost:
		dragging_piece_ghost.queue_free()
		dragging_piece_ghost = null

	var mouse_pos = get_global_mouse_position()
	var board_local_pos = board_node.to_local(mouse_pos)
	var grid_pos = board_node.get_cell_at_position(board_local_pos)

	if grid_pos != Vector2i(-1, -1): # Posição válida no tabuleiro
		_try_place_piece(grid_pos)

func _check_placement_validity(grid_pos: Vector2i) -> bool:
	# Validação da área de posicionamento
	if not player_placement_area_rows.has(grid_pos.y):
		return false

	# Validação se a célula já está ocupada
	if board_node.is_cell_occupied(grid_pos):
		return false

	# Validação de peças disponíveis
	if selected_piece_type == null or available_pieces.get(selected_piece_type, 0) <= 0:
		return false

	return true

func _try_place_piece(grid_pos: Vector2i):
	if not _check_placement_validity(grid_pos):
		print("Posicionamento inválido.")
		return

	# Se todas as validações passarem, posiciona a peça
	var new_piece_id = "piece_" + str(randi())
	var new_piece_data = PecaJogo.new(new_piece_id, selected_piece_type, Equipe.VERDE, grid_pos)
	
	board_node.place_piece_on_board(new_piece_data)
	placed_pieces.append(new_piece_data)
	available_pieces[selected_piece_type] -= 1
	_update_inventory_display()

	# Envia mensagem de atualização de posicionamento para o servidor
	var msg_data = PlacementMessageClass.PlacementMessageData.new(new_piece_id, selected_piece_type, grid_pos)
	var update_message = PlacementMessageClass.new("PLACEMENT_UPDATE", game_id, player_id, msg_data)
	WebSocketService.send_message(update_message.to_dict())

	# Verifica se todas as peças foram posicionadas para habilitar o botão de confirmar
	if _get_total_pieces_remaining() == 0:
		confirm_button.disabled = false
		status_label.text = "Todas as peças posicionadas!"
	else:
		confirm_button.disabled = true
		status_label.text = "Posicione as peças restantes."

	selected_piece_type = Patente.PRISIONEIRO # Reseta a seleção após posicionar

func _get_total_pieces_remaining() -> int:
	var total = 0
	for count in available_pieces.values():
		total += count
	return total

func _on_confirm_button_pressed():
	print("Confirmar posicionamento!")
	# Envia mensagem de confirmação de posicionamento para o servidor
	var msg_data = PlacementMessageClass.PlacementMessageData.new("", Patente.PRISIONEIRO, Vector2i.ZERO, PlacementStatus.READY, placed_pieces)
	var ready_message = PlacementMessageClass.new("PLACEMENT_READY", game_id, player_id, msg_data)
	WebSocketService.send_message(ready_message.to_dict())
	status_label.text = "Aguardando oponente confirmar..."
	confirm_button.disabled = true

func _on_websocket_message_received(message_data):
	# Lida com mensagens recebidas do servidor durante a fase de posicionamento
	print("Mensagem recebida na tela de posicionamento: ", message_data)
	if message_data.has("type"):
		match message_data.type:
			"PLACEMENT_STATUS_UPDATE":
				# Atualiza o status do oponente
				if message_data.data.status == PlacementStatus.READY:
					status_label.text = "Oponente pronto! Aguardando seu posicionamento."
			"GAME_START":
				print("Jogo vai começar!")
				SceneManager.change_scene("res://scenes/ui/game_screen.tscn")