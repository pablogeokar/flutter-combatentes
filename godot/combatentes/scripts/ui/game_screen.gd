# game_screen.gd
extends Control

const EstadoJogo = preload("res://scripts/data/estado_jogo.gd")
const PecaJogo = preload("res://scripts/data/peca_jogo.gd")
const Enums = preload("res://scripts/data/enums.gd")
const CombatAnimationScene = preload("res://scenes/effects/combat_animation.tscn")
const ExplosionEffectScene = preload("res://scenes/effects/explosion_effect.tscn")
const BloodSplatterEffectScene = preload("res://scenes/effects/blood_splatter_effect.tscn")

@onready var board_node = $VBoxContainer/BoardContainer/Board
@onready var player1_name_label = $VBoxContainer/TopInfoContainer/Player1Name
@onready var player2_name_label = $VBoxContainer/TopInfoContainer/Player2Name
@onready var turn_indicator_label = $VBoxContainer/TopInfoContainer/TurnIndicator
@onready var game_status_label = $VBoxContainer/GameStatusLabel

var current_game_state: EstadoJogo
var selected_piece_node: Node = null # Referência ao Node da peça selecionada

func _ready():
	print("Tela de jogo principal carregada.")
	# Conecta aos sinais do WebSocketService para receber atualizações do estado do jogo
	WebSocketService.connect("message_received", Callable(self, "_on_websocket_message_received"))

	# Solicita o estado inicial do jogo ao servidor (se necessário, ou aguarda a primeira atualização)
	# WebSocketService.send_message({"type": "REQUEST_GAME_STATE", "gameId": Global.game_id})

func _on_websocket_message_received(message_data):
	# Lida com mensagens recebidas do servidor durante o jogo ativo
	if message_data.has("type"):
		match message_data.type:
			"GAME_STATE_UPDATE":
				_update_game_state(message_data.game_state)
			"COMBAT_RESULT":
				_handle_combat_result(message_data.combat_info)
			"GAME_OVER":
				_handle_game_over(message_data.winner_id)

func _update_game_state(new_state_data: Dictionary):
	# Converte o dicionário recebido em um objeto EstadoJogo
	current_game_state = EstadoJogo.new(
		new_state_data.gameId,
		[], # Jogadores (a ser populado)
		[], # Peças (a ser populado)
		new_state_data.idJogadorDaVez,
		new_state_data.jogoTerminou,
		new_state_data.idVencedor
	)

	# Popula jogadores
	for player_data in new_state_data.jogadores:
		var equipe_enum = Enums.Equipe.values().find(player_data.equipe)
		if equipe_enum == -1: equipe_enum = Enums.Equipe.VERDE # Default
		current_game_state.jogadores.append(Jogador.new(player_data.id, player_data.nome, equipe_enum))

	# Popula peças
	board_node.clear_board()
	for piece_data in new_state_data.pecas:
		var patente_enum = Enums.Patente.values().find(piece_data.patente)
		if patente_enum == -1: patente_enum = Enums.Patente.PRISIONEIRO # Default
		var equipe_enum = Enums.Equipe.values().find(piece_data.equipe)
		if equipe_enum == -1: equipe_enum = Enums.Equipe.VERDE # Default

		var piece = PecaJogo.new(
			piece_data.id,
			patente_enum,
			equipe_enum,
			Vector2i(piece_data.posicao.coluna, piece_data.posicao.linha)
		)
		piece.foi_revelada = piece_data.get("foiRevelada", false)
		current_game_state.pecas.append(piece)
		board_node.place_piece_on_board(piece)

	_update_ui_from_game_state()

func _update_ui_from_game_state():
	# Atualiza nomes dos jogadores
	for player in current_game_state.jogadores:
		if player.equipe == Enums.Equipe.VERDE:
			player1_name_label.text = "Jogador 1: " + player.nome
		else:
			player2_name_label.text = "Jogador 2: " + player.nome

	# Atualiza indicador de turno
	if current_game_state.id_jogador_da_vez == Global.player_id:
		turn_indicator_label.text = "Sua Vez!"
	else:
		turn_indicator_label.text = "Vez do Oponente"

	# Atualiza status do jogo
	if current_game_state.jogo_terminou:
		game_status_label.text = "Fim de Jogo! Vencedor: " + current_game_state.id_vencedor
		# TODO: Transicionar para tela de vitória/derrota
	else:
		game_status_label.text = ""

func _handle_combat_result(combat_info: Dictionary):
	print("Resultado de combate: ", combat_info)
	var combat_animation = CombatAnimationScene.instantiate()
	add_child(combat_animation)
	combat_animation.play_animation(combat_info)

	# Efeitos visuais adicionais
	var target_pos = Vector2(combat_info.defendingPiece.posicao.coluna, combat_info.defendingPiece.posicao.linha) * board_node.TAMANHO_CELULA

	# Se a peça defensora era uma mina, toca som de explosão e efeito visual
	if combat_info.defendingPiece.patente == Enums.Patente.MINA_TERRESTRE:
		AudioService.play_sound("res://assets/sounds/explosao.wav")
		var explosion = ExplosionEffectScene.instantiate()
		add_child(explosion)
		explosion.play_at_position(target_pos)
	else:
		AudioService.play_sound("res://assets/sounds/tiro.wav")

	# Se uma peça foi perdida, toca som de derrota e efeito de respingo de sangue
	if combat_info.winnerPieceId != combat_info.attackingPiece.id or combat_info.winnerPieceId != combat_info.defendingPiece.id: # Se alguma peça foi removida
		AudioService.play_sound("res://assets/sounds/derrota_fim.wav") # Som de peça perdida
		var blood_splatter = BloodSplatterEffectScene.instantiate()
		add_child(blood_splatter)
		blood_splatter.play_at_position(target_pos)

func _handle_game_over(winner_id: String):
	print("Fim de jogo! Vencedor: ", winner_id)
	AudioService.play_sound("res://assets/sounds/comemoracao.mp3") # Som de vitória/derrota
	
	if winner_id == Global.player_id:
		SceneManager.change_scene("res://scenes/ui/victory_screen.tscn")
	else:
		SceneManager.change_scene("res://scenes/ui/defeat_screen.tscn")

func _input(event):
	# Lógica de seleção e movimentação de peças durante o jogo ativo
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var mouse_pos = get_global_mouse_position()
		var board_local_pos = board_node.to_local(mouse_pos)
		var grid_pos = board_node.get_cell_at_position(board_local_pos)

		if grid_pos != Vector2i(-1, -1):
			_handle_board_click(grid_pos)

func _handle_board_click(grid_pos: Vector2i):
	var piece_on_cell_data = board_node.get_piece_at_cell(grid_pos) # Retorna PecaJogo Resource
	var piece_on_cell_node = board_node.get_piece_node_at_cell(grid_pos) # Referência ao Node da peça

	if selected_piece_node == null: # Nenhuma peça selecionada, tenta selecionar uma
		if piece_on_cell_data and piece_on_cell_data.equipe == Enums.Equipe.VERDE: # Apenas peças do jogador local
			# Verifica se é a sua vez antes de selecionar
			if current_game_state and current_game_state.id_jogador_da_vez == Global.player_id:
				selected_piece_node = piece_on_cell_node
				selected_piece_node.is_selected = true
				print("Peça selecionada: ", selected_piece_node.peca_data.get_nome())
				_highlight_valid_moves(selected_piece_node.peca_data)
			else:
				print("Não é a sua vez de jogar.")
	else: # Já tem uma peça selecionada, tenta mover ou atacar
		board_node.clear_highlights()
		if piece_on_cell_node == selected_piece_node: # Clicou na mesma peça, desseleciona
			selected_piece_node.is_selected = false
			selected_piece_node = null
			print("Peça desselecionada.")
		elif _is_valid_move(selected_piece_node.peca_data, grid_pos): # Tenta mover/atacar
			_send_move_action(selected_piece_node.peca_data, grid_pos)
			selected_piece_node.is_selected = false
			selected_piece_node = null # Reseta a seleção após a ação
		else:
			print("Movimento inválido.")

func _is_valid_move(piece: PecaJogo, target_pos: Vector2i) -> bool:
	# Regras Gerais de Movimento
	# Peças Imóveis
	if piece.patente == Enums.Patente.MINA_TERRESTRE or piece.patente == Enums.Patente.PRISIONEIRO:
		return false

	var current_pos = piece.posicao
	var dx = abs(current_pos.x - target_pos.x)
	var dy = abs(current_pos.y - target_pos.y)

	# Movimento Ortogonal
	if not ((dx == 0 and dy > 0) or (dy == 0 and dx > 0)):
		return false

	# Movimento do Soldado (Scout)
	if piece.patente == Enums.Patente.SOLDADO:
		# O Soldado pode se mover por qualquer número de casas vazias
		if dx > 0 and dy == 0: # Horizontal
			var step = 1 if (target_pos.x - current_pos.x) > 0 else -1
			for x in range(current_pos.x + step, target_pos.x, step):
				if board_node.is_cell_occupied(Vector2i(x, current_pos.y)):
					return false # Caminho bloqueado
		elif dy > 0 and dx == 0: # Vertical
			var step = 1 if (target_pos.y - current_pos.y) > 0 else -1
			for y in range(current_pos.y + step, target_pos.y, step):
				if board_node.is_cell_occupied(Vector2i(current_pos.x, y)):
					return false # Caminho bloqueado
	else:
		# Outras peças movem apenas 1 casa
		if not (dx == 1 or dy == 1):
			return false

	# Alvo do Movimento
	var target_piece_data = board_node.get_piece_at_cell(target_pos)
	if target_piece_data:
		# Não pode mover para uma célula ocupada por uma peça amiga
		if target_piece_data.equipe == piece.equipe:
			return false
		# Pode mover para uma célula ocupada por uma peça inimiga (combate)
		return true
	else:
		# Pode mover para uma célula vazia
		return true

func _highlight_valid_moves(piece: PecaJogo):
	board_node.clear_highlights()
	for x in range(board_node.TAMANHO_TABULEIRO.x):
		for y in range(board_node.TAMANHO_TABULEIRO.y):
			var target_pos = Vector2i(x, y)
			if _is_valid_move(piece, target_pos):
				board_node.highlight_cell(target_pos, true)

func _send_move_action(piece: PecaJogo, target_pos: Vector2i):
	print("Enviando movimento: ", piece.get_nome(), " de ", piece.posicao, " para ", target_pos)
	var move_message = {
		"type": "MOVE_PIECE",
		"gameId": Global.game_id,
		"playerId": Global.player_id,
		"data": {
			"pieceId": piece.id,
			"fromPosition": {"linha": piece.posicao.y, "coluna": piece.posicao.x},
			"toPosition": {"linha": target_pos.y, "coluna": target_pos.x}
		}
	}
	WebSocketService.send_message(move_message)
