# websocket_service.gd
extends Node

# Sinais emitidos para comunicação com outras partes do jogo
signal connected
signal disconnected
signal message_received(message_data)

var websocket: WebSocketPeer
var url = "wss://combatentes.zionix.com.br"
var fallback_url = "ws://combatentes.zionix.com.br"
var connection_attempts = 0

func _ready():
	websocket = WebSocketPeer.new()

func connect_to_server():
	connection_attempts += 1
	var current_url = url if connection_attempts == 1 else fallback_url
	
	print("🔗 WEBSOCKET - Tentativa ", connection_attempts, " - Conectando ao: ", current_url)
	print("🔗 WEBSOCKET - Estado inicial: ", _state_to_string(websocket.get_ready_state()))
	
	var err = websocket.connect_to_url(current_url)
	print("🔗 WEBSOCKET - Resultado da conexão: ", err)
	
	if err != OK:
		print("❌ WEBSOCKET - ERRO: Falha ao conectar ao WebSocket. Código de erro: ", err)
		print("❌ WEBSOCKET - URL testada: ", current_url)
		print("❌ WEBSOCKET - Possíveis causas:")
		print("  - Servidor indisponível")
		print("  - Problemas de rede/firewall")
		print("  - URL incorreta")
		print("  - Problemas de SSL/certificado")
	else:
		print("✅ WEBSOCKET - Comando de conexão enviado com sucesso para: ", current_url)

func send_message(message: Dictionary):
	print("📤 WEBSOCKET - Tentando enviar mensagem: ", message)
	print("📤 WEBSOCKET - Estado da conexão: ", _state_to_string(websocket.get_ready_state()))
	
	if websocket.get_ready_state() == WebSocketPeer.STATE_OPEN:
		var json_message = JSON.stringify(message)
		websocket.send_text(json_message)
		print("✅ WEBSOCKET - Mensagem enviada com sucesso: ", json_message)
	else:
		print("❌ WEBSOCKET - ERRO: WebSocket não conectado. Estado: ", _state_to_string(websocket.get_ready_state()))
		print("❌ WEBSOCKET - Não foi possível enviar mensagem: ", message)

var last_state = WebSocketPeer.STATE_CLOSED
var connection_established = false

func _process(delta):
	websocket.poll()
	
	var state = websocket.get_ready_state()
	
	# Detecta mudança de estado para emitir sinais apropriados
	if state != last_state:
		print("WebSocket mudou de estado: ", _state_to_string(last_state), " -> ", _state_to_string(state))
		last_state = state
		
		if state == WebSocketPeer.STATE_OPEN and not connection_established:
			connection_established = true
			print("✅ Conexão WebSocket estabelecida")
			emit_signal("connected")
		elif state == WebSocketPeer.STATE_CLOSED and connection_established:
			connection_established = false
			var code = websocket.get_close_code()
			var reason = websocket.get_close_reason()
			print("❌ WebSocket fechado com código: ", code, " razão: ", reason)
			print("❌ Detalhes do fechamento:")
			_print_close_code_details(code)
			emit_signal("disconnected")
		elif state == WebSocketPeer.STATE_CLOSED and not connection_established:
			# Conexão falhou antes de ser estabelecida
			var code = websocket.get_close_code()
			var reason = websocket.get_close_reason()
			print("❌ Falha na conexão WebSocket - código: ", code, " razão: ", reason)
			_print_close_code_details(code)
	
	if state == WebSocketPeer.STATE_OPEN:
		while websocket.get_available_packet_count() > 0:
			var packet = websocket.get_packet()
			var data = packet.get_string_from_utf8()
			print("📨 WEBSOCKET - Mensagem bruta recebida: ", data)
			
			var json = JSON.new()
			var parse_result = json.parse(data)
			if parse_result == OK:
				var json_data = json.data
				print("📨 WEBSOCKET - JSON parseado: ", json_data)
				print("📨 WEBSOCKET - Tipo da mensagem: ", json_data.get("type", "SEM_TIPO"))
				emit_signal("message_received", json_data)
			else:
				print("❌ WEBSOCKET - ERRO: Falha ao fazer parse do JSON: ", data)

func _state_to_string(state: int) -> String:
	match state:
		WebSocketPeer.STATE_CONNECTING:
			return "CONNECTING"
		WebSocketPeer.STATE_OPEN:
			return "OPEN"
		WebSocketPeer.STATE_CLOSING:
			return "CLOSING"
		WebSocketPeer.STATE_CLOSED:
			return "CLOSED"
		_:
			return "UNKNOWN"

func get_connection_state() -> int:
	return websocket.get_ready_state()

func is_websocket_connected() -> bool:
	return websocket.get_ready_state() == WebSocketPeer.STATE_OPEN

func disconnect_from_server():
	if websocket.get_ready_state() == WebSocketPeer.STATE_OPEN:
		websocket.close()

func _print_close_code_details(code: int):
	match code:
		1000:
			print("  - Código 1000: Fechamento normal")
		1001:
			print("  - Código 1001: Endpoint indo embora (página fechando)")
		1002:
			print("  - Código 1002: Erro de protocolo")
		1003:
			print("  - Código 1003: Tipo de dados não suportado")
		1006:
			print("  - Código 1006: Conexão fechada anormalmente (sem handshake)")
		1007:
			print("  - Código 1007: Dados inválidos recebidos")
		1008:
			print("  - Código 1008: Violação de política")
		1009:
			print("  - Código 1009: Mensagem muito grande")
		1010:
			print("  - Código 1010: Extensão obrigatória ausente")
		1011:
			print("  - Código 1011: Erro interno do servidor")
		1015:
			print("  - Código 1015: Falha na verificação TLS")
		_:
			print("  - Código ", code, ": Código de fechamento desconhecido")

func _exit_tree():
	disconnect_from_server()
