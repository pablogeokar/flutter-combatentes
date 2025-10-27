# test_runner.gd
extends Node

const Patente = preload("res://scripts/data/enums.gd").Patente
const Equipe = preload("res://scripts/data/enums.gd").Equipe

func _ready():
	print("Test Runner iniciado.")
	# Inicia o fluxo de teste após um pequeno atraso
	get_tree().create_timer(1.0).connect("timeout", Callable(self, "_run_tests"))

func _run_tests():
	print("Executando testes...")
	
	# Teste 1: Simular entrada de nome e matchmaking
	_test_name_input_and_matchmaking()

func _test_name_input_and_matchmaking():
	print("--- Teste: Entrada de Nome e Matchmaking ---")
	Global.player_name = "TestPlayer"
	SceneManager.change_scene("res://scenes/ui/matchmaking_screen.tscn")
	
	# Simular conexão WebSocket e mensagem de MATCH_FOUND
	get_tree().create_timer(2.0).connect("timeout", Callable(self, "_simulate_match_found"))

func _simulate_match_found():
	print("Simulando MATCH_FOUND...")
	var mock_match_found_message = {
		"type": "MATCH_FOUND",
		"game_id": "game_123",
		"player_id": "player_abc",
		"player_area": [6, 7, 8, 9] # Exemplo para o segundo jogador
	}
	WebSocketService._send_mock_message(mock_match_found_message)
	
	# Teste 2: Simular posicionamento de peças
	get_tree().create_timer(2.0).connect("timeout", Callable(self, "_test_piece_placement"))

func _test_piece_placement():
	print("--- Teste: Posicionamento de Peças ---")
	# A tela de posicionamento deve estar ativa agora.
	# Para simular o posicionamento, precisaria interagir com a UI, o que é complexo via script.
	# Por enquanto, vamos simular o envio de um PLACEMENT_READY e GAME_START.
	
	# Simular PLACEMENT_READY
	var mock_placed_pieces = [
		PecaJogo.new("p1", Patente.MARECHAL, Equipe.VERDE, Vector2i(0, 6)),
		PecaJogo.new("p2", Patente.SOLDADO, Equipe.VERDE, Vector2i(1, 6)),
	]
	var mock_placement_ready_message = {
		"type": "PLACEMENT_READY",
		"gameId": Global.game_id,
		"playerId": Global.player_id,
		"data": {"allPieces": mock_placed_pieces.map(func(p): return p.to_dict())}
	}
	WebSocketService._send_mock_message(mock_placement_ready_message)
	
	# Simular GAME_START
	get_tree().create_timer(2.0).connect("timeout", Callable(self, "_simulate_game_start"))

func _simulate_game_start():
	print("Simulando GAME_START...")
	var mock_game_start_message = {
		"type": "GAME_START",
		"gameId": Global.game_id,
		"playerId": Global.player_id,
	}
	WebSocketService._send_mock_message(mock_game_start_message)
	
	# Teste 3: Simular atualização do estado do jogo e combate
	get_tree().create_timer(2.0).connect("timeout", Callable(self, "_test_game_play"))

func _test_game_play():
	print("--- Teste: Jogabilidade ---")
	# Simular GAME_STATE_UPDATE
	var mock_game_state = {
		"gameId": Global.game_id,
		"jogadores": [
			{"id": Global.player_id, "nome": Global.player_name, "equipe": "VERDE"},
			{"id": "opponent_xyz", "nome": "Opponent", "equipe": "PRETA"}
		],
		"pecas": [
			{"id": "p1", "patente": "MARECHAL", "equipe": "VERDE", "posicao": {"linha": 6, "coluna": 0}, "foiRevelada": false},
			{"id": "p2", "patente": "SOLDADO", "equipe": "VERDE", "posicao": {"linha": 6, "coluna": 1}, "foiRevelada": false},
			{"id": "op1", "patente": "SOLDADO", "equipe": "PRETA", "posicao": {"linha": 3, "coluna": 0}, "foiRevelada": false}
		],
		"idJogadorDaVez": Global.player_id,
		"jogoTerminou": false,
		"idVencedor": null
	}
	var mock_game_state_update_message = {"type": "GAME_STATE_UPDATE", "game_state": mock_game_state}
	WebSocketService._send_mock_message(mock_game_state_update_message)
	
	# Simular COMBAT_RESULT
	get_tree().create_timer(3.0).connect("timeout", Callable(self, "_simulate_combat_result"))

func _simulate_combat_result():
	print("Simulando COMBAT_RESULT...")
	var mock_combat_info = {
		"attackingPiece": {"id": "p1", "patente": "MARECHAL", "equipe": "VERDE", "posicao": {"linha": 6, "coluna": 0}},
		"defendingPiece": {"id": "op1", "patente": "SOLDADO", "equipe": "PRETA", "posicao": {"linha": 3, "coluna": 0}},
		"winnerPieceId": "p1"
	}
	var mock_combat_result_message = {"type": "COMBAT_RESULT", "combat_info": mock_combat_info}
	WebSocketService._send_mock_message(mock_combat_result_message)
	
	# Simular GAME_OVER
	get_tree().create_timer(4.0).connect("timeout", Callable(self, "_simulate_game_over"))

func _simulate_game_over():
	print("Simulando GAME_OVER...")
	var mock_game_over_message = {"type": "GAME_OVER", "winner_id": Global.player_id}
	WebSocketService._send_mock_message(mock_game_over_message)

	# Teste 4: Simular reinício do jogo
	get_tree().create_timer(3.0).connect("timeout", Callable(self, "_test_restart_game"))

func _test_restart_game():
	print("--- Teste: Reinício do Jogo ---")
	# Simular clique em "Jogar Novamente" na tela de vitória/derrota
	SceneManager.change_scene("res://scenes/ui/matchmaking_screen.tscn")
	print("Testes concluídos. Verifique o console e as transições de tela.")
