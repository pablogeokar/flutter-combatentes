# matchmaking_screen.gd
extends Control

var animation_player: AnimationPlayer
var status_label: Label

var connection_timeout: float = 10.0
var connection_timer: float = 0.0
var is_connecting: bool = false

func _ready():
	# Procura pelos nós na árvore
	animation_player = find_child("AnimationPlayer", true, false)
	status_label = find_child("StatusLabel", true, false)
	
	print("🔍 MATCHMAKING - Nós encontrados:")
	print("  - AnimationPlayer: ", animation_player != null)
	print("  - StatusLabel: ", status_label != null)
	
	# Inicia a animação de "loading"
	if animation_player:
		animation_player.play("loading")
	
	# Conecta aos sinais do WebSocketService
	WebSocketService.connected.connect(_on_websocket_connected)
	WebSocketService.disconnected.connect(_on_websocket_disconnected)
	WebSocketService.message_received.connect(_on_websocket_message_received)

	_start_connection()

func _start_connection():
	status_label.text = "Conectando ao servidor..."
	is_connecting = true
	connection_timer = 0.0
	WebSocketService.connect_to_server()

func _process(delta):
	if is_connecting:
		connection_timer += delta
		if connection_timer > connection_timeout:
			_on_connection_timeout()

func _on_connection_timeout():
	is_connecting = false
	status_label.text = "Timeout na conexão. Simulando modo offline..."
	print("ERRO: Timeout na conexão WebSocket")
	
	# MODO OFFLINE: Simula encontrar oponente após timeout
	await get_tree().create_timer(2.0).timeout
	if is_inside_tree():
		print("🧪 MODO OFFLINE - Simulando encontro de oponente...")
		_simulate_opponent_found()

func _on_websocket_connected():
	print("✅ MATCHMAKING - WebSocket conectado!")
	print("✅ MATCHMAKING - Nome do jogador: ", Global.player_name)
	is_connecting = false
	status_label.text = "Conectado. Procurando oponente..."
	
	# Envia o nome do jogador usando o tipo correto que o servidor espera
	var message = {
		"type": "definirNome",
		"payload": {"nome": Global.player_name}
	}
	print("✅ MATCHMAKING - Enviando mensagem definirNome: ", message)
	WebSocketService.send_message(message)
	
	# TESTE: Simula encontrar oponente após 3 segundos
	await get_tree().create_timer(3.0).timeout
	if is_inside_tree():
		print("🧪 TESTE - Simulando encontro de oponente...")
		_simulate_opponent_found()

func _on_websocket_disconnected():
	print("WebSocket desconectado.")
	is_connecting = false
	
	# Se ainda não tentou a URL alternativa, tenta
	if WebSocketService.connection_attempts == 1:
		status_label.text = "Tentando URL alternativa..."
		await get_tree().create_timer(2.0).timeout
		if is_inside_tree():
			_start_connection()
	else:
		status_label.text = "Desconectado do servidor. Modo offline ativado."
		# Ativa modo offline após tentar ambas as URLs
		await get_tree().create_timer(2.0).timeout
		if is_inside_tree():
			print("🧪 MODO OFFLINE - Ambas URLs falharam, simulando oponente...")
			_simulate_opponent_found()

func _on_websocket_message_received(message_data):
	print("🔍 MATCHMAKING - Mensagem recebida: ", message_data)
	print("🔍 MATCHMAKING - Tipo da mensagem: ", message_data.get("type", "SEM_TIPO"))
	
	# Verifica diferentes tipos de mensagem do servidor
	if message_data.has("type"):
		var message_type = message_data.type
		print("🔍 MATCHMAKING - Processando tipo: ", message_type)
		
		match message_type:
			"mensagemServidor":
				var msg = str(message_data.payload)
				status_label.text = msg
				print("📨 Mensagem do servidor: ", msg)
			
			"PLACEMENT_STATUS":
				print("🎯 PLACEMENT_STATUS recebido - navegando para posicionamento")
				print("🎯 Dados do PLACEMENT_STATUS: ", message_data)
				_navigate_to_placement(message_data)
			
			"atualizacaoEstado":
				print("🎮 atualizacaoEstado recebido")
				print("🎮 Payload completo: ", message_data.payload)
				var payload = message_data.payload
				if payload.has("jogadores") and payload.jogadores.size() >= 2:
					print("🎮 Dois jogadores detectados - navegando para posicionamento")
					_navigate_to_placement(message_data)
				else:
					print("🎮 Condições não atendidas para navegação")
					if payload.has("jogadores"):
						print("🎮 Número de jogadores: ", payload.jogadores.size())
					else:
						print("🎮 Campo 'jogadores' não encontrado no payload")
			
			_:
				print("❓ Tipo de mensagem não reconhecido: ", message_type)
				# Verifica se é algum tipo de mensagem de placement
				if "PLACEMENT" in message_type:
					print("🎯 Mensagem de PLACEMENT detectada: ", message_type)
					print("🎯 Tentando navegar para posicionamento...")
					_navigate_to_placement(message_data)
	else:
		print("❌ Mensagem sem campo 'type': ", message_data)

func _navigate_to_placement(message_data):
	print("🚀 NAVEGAÇÃO - Iniciando navegação para tela de posicionamento...")
	print("🚀 NAVEGAÇÃO - Dados recebidos: ", message_data)
	
	# Salva informações do jogo no Global
	var game_id_found = false
	if message_data.has("gameId"):
		Global.game_id = message_data.gameId
		game_id_found = true
		print("🚀 NAVEGAÇÃO - Game ID definido: ", Global.game_id)
	elif message_data.has("payload") and message_data.payload.has("idPartida"):
		Global.game_id = message_data.payload.idPartida
		game_id_found = true
		print("🚀 NAVEGAÇÃO - Game ID definido (payload): ", Global.game_id)
	
	if not game_id_found:
		print("❌ NAVEGAÇÃO - Game ID não encontrado na mensagem!")
		print("❌ NAVEGAÇÃO - Estrutura da mensagem: ", message_data.keys())
		# Para mensagens PLACEMENT_STATUS, vamos usar um ID temporário
		if message_data.has("type") and "PLACEMENT" in str(message_data.type):
			Global.game_id = "temp_game_" + str(randi())
			game_id_found = true
			print("🚀 NAVEGAÇÃO - Game ID temporário criado: ", Global.game_id)
	
	# Determina a área do jogador baseada na equipe
	var player_configured = false
	if message_data.has("payload") and message_data.payload.has("jogadores"):
		var jogadores = message_data.payload.jogadores
		print("🚀 NAVEGAÇÃO - Processando ", jogadores.size(), " jogadores")
		for jogador in jogadores:
			print("🚀 NAVEGAÇÃO - Jogador: ", jogador.nome, " vs Player: ", Global.player_name)
			if jogador.nome == Global.player_name:
				Global.player_id = jogador.id
				# Define área baseada na equipe
				if jogador.equipe == "verde":
					Global.player_area = [0, 1, 2, 3]  # Linhas 0-3 para verde
				else:
					Global.player_area = [6, 7, 8, 9]  # Linhas 6-9 para preta
				player_configured = true
				print("🚀 NAVEGAÇÃO - Player configurado: ID=", Global.player_id, " Equipe=", jogador.equipe)
				break
	
	if not player_configured:
		print("❌ NAVEGAÇÃO - Configuração do player falhou!")
		print("❌ NAVEGAÇÃO - Player name: ", Global.player_name)
		if message_data.has("payload") and message_data.payload.has("jogadores"):
			print("❌ NAVEGAÇÃO - Jogadores disponíveis:")
			for jogador in message_data.payload.jogadores:
				print("  - ", jogador.nome)
		else:
			# Para mensagens PLACEMENT_STATUS, vamos usar configuração padrão
			if message_data.has("type") and "PLACEMENT" in str(message_data.type):
				Global.player_id = "temp_player_" + str(randi())
				Global.player_area = [0, 1, 2, 3]  # Área padrão (verde)
				player_configured = true
				print("🚀 NAVEGAÇÃO - Configuração temporária do player criada")
	
	print("🚀 NAVEGAÇÃO - Estado Global antes da navegação:")
	print("  - game_id: ", Global.game_id)
	print("  - player_id: ", Global.player_id)
	print("  - player_name: ", Global.player_name)
	print("  - player_area: ", Global.player_area)
	
	print("🚀 NAVEGAÇÃO - Chamando SceneManager.change_scene...")
	SceneManager.change_scene("res://scenes/ui/piece_placement_screen.tscn")
	print("🚀 NAVEGAÇÃO - Comando de mudança de cena executado!")

func _on_cancel_button_pressed():
	print("Matchmaking cancelado pelo usuário.")
	WebSocketService.disconnect_from_server()
	SceneManager.change_scene("res://scenes/ui/name_input_screen.tscn")

# Função de teste para simular navegação para posicionamento
func _test_navigate_to_placement():
	print("🧪 TESTE - Simulando navegação para posicionamento...")
	var test_message = {
		"type": "PLACEMENT_STATUS",
		"gameId": "test_game_123",
		"data": {
			"status": "PLACING"
		}
	}
	_navigate_to_placement(test_message)

# Adiciona input para teste (pressionar T ou SPACE)
func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_T:
			print("🧪 Tecla T pressionada - testando navegação...")
			_test_navigate_to_placement()
		elif event.keycode == KEY_SPACE:
			print("🧪 Tecla SPACE pressionada - simulando oponente encontrado...")
			_simulate_opponent_found()

# Simula o recebimento de uma mensagem PLACEMENT_STATUS
func _simulate_placement_message():
	print("🧪 SIMULAÇÃO - Simulando recebimento de PLACEMENT_STATUS...")
	var simulated_message = {
		"type": "PLACEMENT_STATUS",
		"gameId": "simulated_game_123",
		"playerId": "simulated_player_456",
		"data": {
			"status": "PLACING",
			"allPieces": []
		}
	}
	
	print("🧪 SIMULAÇÃO - Chamando _on_websocket_message_received...")
	_on_websocket_message_received(simulated_message)

# Simula que um oponente foi encontrado
func _simulate_opponent_found():
	print("🧪 SIMULAÇÃO - Simulando oponente encontrado...")
	status_label.text = "Oponente encontrado! Iniciando posicionamento..."
	
	# Simula mensagem atualizacaoEstado com dois jogadores
	var simulated_game_state = {
		"type": "atualizacaoEstado",
		"payload": {
			"idPartida": "simulated_game_123",
			"jogadores": [
				{
					"id": "player_1",
					"nome": Global.player_name,
					"equipe": "verde"
				},
				{
					"id": "player_2", 
					"nome": "Oponente Simulado",
					"equipe": "preta"
				}
			],
			"pecas": [],
			"idJogadorDaVez": "player_1",
			"jogoTerminou": false,
			"idVencedor": null
		}
	}
	
	print("🧪 SIMULAÇÃO - Enviando estado do jogo simulado...")
	_on_websocket_message_received(simulated_game_state)
