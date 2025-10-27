# websocket_service.gd
extends Node

# Sinal emitido quando a conexão WebSocket é aberta
signal connected
# Sinal emitido quando a conexão WebSocket é fechada
signal disconnected
# Sinal emitido quando uma mensagem é recebida
signal message_received(message_data)

var websocket_client: WebSocketClient
var url = "wss://combatentes.zionix.com.br" # URL do seu backend Node.js (alterado para o real)

func _ready():
	websocket_client = WebSocketClient.new()
	websocket_client.connect("connection_closed", Callable(self, "_on_connection_closed"))
	websocket_client.connect("connection_error", Callable(self, "_on_connection_error"))
	websocket_client.connect("connection_established", Callable(self, "_on_connection_established"))
	websocket_client.connect("data_received", Callable(self, "_on_data_received"))

func connect_to_server():
	print("Tentando conectar ao WebSocket: ", url)
	var err = websocket_client.connect_to_url(url)
	if err != OK:
		print_error("Erro ao tentar conectar ao WebSocket: ", err)

func send_message(message: Dictionary):
	if websocket_client.get_connection_status() == WebSocketClient.CONNECTION_STATUS_CONNECTED:
		var json_message = JSON.stringify(message)
		websocket_client.send_text(json_message)
		print("Mensagem enviada: ", json_message)
	else:
		print_error("Não conectado ao WebSocket. Não foi possível enviar a mensagem.")

func _on_connection_established(protocol: String):
	print("Conexão WebSocket estabelecida com protocolo: ", protocol)
	emit_signal("connected")

func _on_connection_closed(was_clean: bool):
	print("Conexão WebSocket fechada. Limpa: ", was_clean)
	emit_signal("disconnected")

func _on_connection_error():
	print_error("Erro na conexão WebSocket.")
	emit_signal("disconnected")

func _on_data_received():
	while websocket_client.get_available_packet_count() > 0:
		var data = websocket_client.get_packet().get_string_from_utf8()
		print("Mensagem recebida: ", data)
		var json_data = JSON.parse_string(data)
		if json_data:
			emit_signal("message_received", json_data)

func _process(delta):
	if websocket_client.get_connection_status() == WebSocketClient.CONNECTION_STATUS_CONNECTED:
		websocket_client.poll()
