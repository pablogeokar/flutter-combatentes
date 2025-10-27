# matchmaking_screen.gd
extends Control

@onready var animation_player = $AnimationPlayer
@onready var status_label = $VBoxContainer/StatusLabel

func _ready():
	# Inicia a animação de "loading"
	animation_player.play("loading")
	
	# Conecta aos sinais do WebSocketService
	WebSocketService.connect("connected", Callable(self, "_on_websocket_connected"))
	WebSocketService.connect("disconnected", Callable(self, "_on_websocket_disconnected"))
	WebSocketService.connect("message_received", Callable(self, "_on_websocket_message_received"))

	status_label.text = "Conectando ao servidor..."
	WebSocketService.connect_to_server()

func _on_websocket_connected():
	print("WebSocket conectado. Enviando nome do jogador.")
	status_label.text = "Conectado. Procurando oponente..."
	# Envia o nome do jogador para o servidor
	var message = {"type": "PLAYER_NAME", "name": Global.player_name}
	WebSocketService.send_message(message)

func _on_websocket_disconnected():
	print("WebSocket desconectado.")
	status_label.text = "Desconectado do servidor. Tentando reconectar..."
	# TODO: Implementar lógica de reconexão ou voltar para a tela inicial

func _on_websocket_message_received(message_data):
	print("Mensagem recebida no matchmaking: ", message_data)
	# Exemplo de como lidar com uma mensagem de "match_found"
	if message_data.has("type") and message_data.type == "MATCH_FOUND":
		print("Partida encontrada! Iniciando tela de posicionamento.")
		# Salvar dados da partida (game_id, player_id, player_area)
		Global.game_id = message_data.game_id
		Global.player_id = message_data.player_id
		Global.player_area = message_data.player_area
		SceneManager.change_scene("res://scenes/ui/piece_placement_screen.tscn")

func _on_cancel_button_pressed():
	print("Matchmaking cancelado pelo usuário.")
	WebSocketService.websocket_client.disconnect_from_host() # Desconecta do servidor
	SceneManager.change_scene("res://scenes/ui/name_input_screen.tscn")
