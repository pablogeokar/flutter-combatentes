# main.gd
extends Node2D

var debug_mode = false

func _ready():
	print("🎮 MAIN - Iniciando jogo...")
	
	# Adiciona helper de debug
	var debug_helper = Node.new()
	debug_helper.set_script(load("res://scripts/debug_helper.gd"))
	add_child(debug_helper)
	
	# Adiciona teste rápido
	var quick_test = Node.new()
	quick_test.set_script(load("res://scripts/quick_test.gd"))
	add_child(quick_test)
	
	print("🎮 MAIN - Controles de debug disponíveis:")
	print("  - Pressione 1: Tela de nome")
	print("  - Pressione 2: Tela de matchmaking") 
	print("  - Pressione 3: Tela de posicionamento (direto)")
	print("  - Pressione 4: Testar WebSocket")
	print("  - Pressione D: Informações de debug")
	print("  - Pressione F1: Ativar/desativar modo debug")
	
	# Carrega a tela de entrada de nome como a primeira cena do jogo.
	SceneManager.change_scene("res://scenes/ui/name_input_screen.tscn")

func _input(event):
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_F1:
			debug_mode = !debug_mode
			print("🔧 Modo debug: ", "ATIVADO" if debug_mode else "DESATIVADO")
