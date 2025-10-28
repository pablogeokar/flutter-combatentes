# main.gd
extends Node2D

func _ready():
	print("🎮 MAIN - Iniciando jogo...")
	
	# Adiciona um label de debug na tela
	var debug_label = Label.new()
	debug_label.text = "COMBATENTES - Pressione 1 para começar"
	debug_label.position = Vector2(100, 100)
	debug_label.add_theme_font_size_override("font_size", 24)
	add_child(debug_label)
	
	print("🎮 MAIN - Controles disponíveis:")
	print("  - Pressione 1: Tela de nome")
	print("  - Pressione 2: Matchmaking")
	print("  - Pressione 3: Posicionamento")
	
	# Aguarda um pouco e carrega a primeira tela
	await get_tree().create_timer(1.0).timeout
	print("🎮 MAIN - Carregando tela de teste...")
	SceneManager.change_scene("res://scenes/ui/simple_test_screen.tscn")

func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1:
				print("🧪 Navegando para tela de teste")
				SceneManager.change_scene("res://scenes/ui/simple_test_screen.tscn")
			KEY_2:
				print("🧪 Navegando para matchmaking")
				SceneManager.change_scene("res://scenes/ui/matchmaking_screen.tscn")
			KEY_3:
				print("🧪 Navegando para posicionamento")
				Global.player_name = "TestPlayer"
				Global.game_id = "test_game"
				Global.player_id = "test_player"
				Global.player_area = [0, 1, 2, 3]
				print("🧪 Dados configurados, navegando...")
				SceneManager.change_scene("res://scenes/ui/piece_placement_screen.tscn")
			KEY_D:
				print("🔧 DEBUG INFO:")
				print("  - Cena atual: ", get_tree().current_scene.name if get_tree().current_scene else "Nenhuma")
				print("  - Global player_name: ", Global.player_name)
				print("  - Arquivos de cena existem: ")
				print("    - simple_name_screen.tscn: ", ResourceLoader.exists("res://scenes/ui/simple_name_screen.tscn"))
				print("    - matchmaking_screen.tscn: ", ResourceLoader.exists("res://scenes/ui/matchmaking_screen.tscn"))
				print("    - piece_placement_screen.tscn: ", ResourceLoader.exists("res://scenes/ui/piece_placement_screen.tscn"))
