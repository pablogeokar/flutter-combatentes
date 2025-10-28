# debug_helper.gd
extends Node

# Script de debug para testar funcionalidades do jogo
# Para usar: adicione este script como autoload ou instancie em uma cena

func _ready():
	print("🔧 DEBUG_HELPER - Iniciado")
	
	# Testa todas as funcionalidades principais
	test_global_variables()
	test_websocket_service()
	test_scene_manager()
	test_enums()
	test_placement_messages()

func test_global_variables():
	print("\n🧪 TESTE - Variáveis Globais")
	print("  - player_name: ", Global.player_name)
	print("  - game_id: ", Global.game_id)
	print("  - player_id: ", Global.player_id)
	print("  - player_area: ", Global.player_area)

func test_websocket_service():
	print("\n🧪 TESTE - WebSocket Service")
	print("  - Estado da conexão: ", WebSocketService._state_to_string(WebSocketService.get_connection_state()))
	print("  - URL configurada: ", WebSocketService.url)
	print("  - URL alternativa: ", WebSocketService.fallback_url)

func test_scene_manager():
	print("\n🧪 TESTE - Scene Manager")
	if SceneManager.current_scene:
		print("  - Cena atual: ", SceneManager.current_scene.name)
	else:
		print("  - Nenhuma cena atual")

func test_enums():
	print("\n🧪 TESTE - Enums")
	const Enums = preload("res://scripts/data/enums.gd")
	print("  - Patentes disponíveis: ", Enums.Patente.keys())
	print("  - Equipes disponíveis: ", Enums.Equipe.keys())
	print("  - Status de placement: ", Enums.PlacementStatus.keys())

func test_placement_messages():
	print("\n🧪 TESTE - Placement Messages")
	const Enums = preload("res://scripts/data/enums.gd")
	
	# Testa criação de mensagem básica
	var test_message = PlacementMessage.new()
	test_message.type = "TEST"
	test_message.game_id = "test_game"
	test_message.player_id = "test_player"
	
	print("  - Mensagem básica criada: ", test_message.to_dict())
	print("  - Classe PlacementMessage carregada com sucesso")

func test_navigation():
	print("\n🧪 TESTE - Navegação")
	print("  - Testando navegação para tela de posicionamento...")
	
	# Configura dados de teste
	Global.player_name = "TestPlayer"
	Global.game_id = "test_game_123"
	Global.player_id = "test_player_456"
	Global.player_area = [0, 1, 2, 3]
	
	# Navega para tela de posicionamento
	SceneManager.change_scene("res://scenes/ui/piece_placement_screen.tscn")

# Função para testar conexão WebSocket
func test_websocket_connection():
	print("\n🧪 TESTE - Conexão WebSocket")
	WebSocketService.connect_to_server()

# Função para simular oponente encontrado
func simulate_opponent_found():
	print("\n🧪 SIMULAÇÃO - Oponente encontrado")
	
	# Configura dados globais
	Global.player_name = "TestPlayer"
	Global.game_id = "simulated_game_123"
	Global.player_id = "player_1"
	Global.player_area = [0, 1, 2, 3]
	
	# Navega para posicionamento
	SceneManager.change_scene("res://scenes/ui/piece_placement_screen.tscn")

# Função para imprimir informações do sistema
func print_system_info():
	print("\n🔧 INFORMAÇÕES DO SISTEMA")
	print("  - Versão do Godot: ", Engine.get_version_info())
	print("  - Plataforma: ", OS.get_name())
	print("  - Arquitetura: ", Engine.get_architecture_name())
	print("  - Debug build: ", OS.is_debug_build())