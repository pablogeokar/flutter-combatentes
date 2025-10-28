# quick_test.gd
extends Node

# Script para teste rápido - adicione como filho de qualquer cena

func _ready():
	print("🚀 QUICK_TEST - Iniciando teste rápido...")
	
	# Aguarda 1 segundo e executa teste
	await get_tree().create_timer(1.0).timeout
	run_quick_test()

func run_quick_test():
	print("🚀 QUICK_TEST - Executando...")
	
	# Testa navegação direta para posicionamento
	Global.player_name = "TestPlayer"
	Global.game_id = "quick_test_game"
	Global.player_id = "quick_test_player"
	Global.player_area = [0, 1, 2, 3]
	
	print("🚀 QUICK_TEST - Dados configurados:")
	print("  - Nome: ", Global.player_name)
	print("  - Game ID: ", Global.game_id)
	print("  - Player ID: ", Global.player_id)
	print("  - Área: ", Global.player_area)
	
	print("🚀 QUICK_TEST - Navegando para posicionamento...")
	SceneManager.change_scene("res://scenes/ui/piece_placement_screen.tscn")

func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1:
				print("🧪 Teste 1 - Navegação para nome")
				SceneManager.change_scene("res://scenes/ui/name_input_screen.tscn")
			KEY_2:
				print("🧪 Teste 2 - Navegação para matchmaking")
				SceneManager.change_scene("res://scenes/ui/matchmaking_screen.tscn")
			KEY_3:
				print("🧪 Teste 3 - Navegação para posicionamento")
				run_quick_test()
			KEY_4:
				print("🧪 Teste 4 - Teste de WebSocket")
				WebSocketService.connect_to_server()
			KEY_D:
				print("🔧 Debug Info:")
				print("  - Cena atual: ", get_tree().current_scene.name if get_tree().current_scene else "Nenhuma")
				print("  - Global player_name: ", Global.player_name)
				print("  - WebSocket state: ", WebSocketService._state_to_string(WebSocketService.get_connection_state()))