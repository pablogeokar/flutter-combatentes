# test_navigation.gd
extends Node

func _ready():
	print("🧪 TEST_NAVIGATION - Iniciando teste de navegação...")
	
	# Aguarda 3 segundos e testa a navegação
	await get_tree().create_timer(3.0).timeout
	test_placement_navigation()

func test_placement_navigation():
	print("🧪 TEST_NAVIGATION - Testando navegação para posicionamento...")
	
	# Configura dados globais de teste
	Global.player_name = "TestPlayer"
	Global.game_id = "test_game_123"
	Global.player_id = "test_player_456"
	Global.player_area = [0, 1, 2, 3]
	
	print("🧪 TEST_NAVIGATION - Dados configurados:")
	print("  - player_name: ", Global.player_name)
	print("  - game_id: ", Global.game_id)
	print("  - player_id: ", Global.player_id)
	print("  - player_area: ", Global.player_area)
	
	# Tenta navegar para a tela de posicionamento
	print("🧪 TEST_NAVIGATION - Navegando para tela de posicionamento...")
	SceneManager.change_scene("res://scenes/ui/piece_placement_screen.tscn")