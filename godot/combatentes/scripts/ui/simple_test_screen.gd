# simple_test_screen.gd
extends Control

func _ready():
	print("✅ SIMPLE_TEST_SCREEN - Carregado com sucesso!")
	
	# Cria uma interface simples programaticamente
	var vbox = VBoxContainer.new()
	vbox.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	add_child(vbox)
	
	var title = Label.new()
	title.text = "COMBATENTES - TESTE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	
	var instruction = Label.new()
	instruction.text = "Pressione ENTER para continuar"
	instruction.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(instruction)
	
	var line_edit = LineEdit.new()
	line_edit.placeholder_text = "Digite seu nome..."
	vbox.add_child(line_edit)
	
	var button = Button.new()
	button.text = "Começar"
	button.pressed.connect(_on_start_pressed.bind(line_edit))
	vbox.add_child(button)

func _on_start_pressed(line_edit: LineEdit):
	var player_name = line_edit.text
	if player_name.is_empty():
		player_name = "Jogador"
	
	print("✅ Nome definido: ", player_name)
	Global.player_name = player_name
	
	# Vai direto para o teste de posicionamento
	Global.game_id = "test_game"
	Global.player_id = "test_player"
	Global.player_area = [0, 1, 2, 3]
	
	print("✅ Navegando para posicionamento...")
	SceneManager.change_scene("res://scenes/ui/piece_placement_screen.tscn")

func _input(event):
	if event is InputEventKey and event.pressed and event.keycode == KEY_ENTER:
		_on_start_pressed(find_child("LineEdit", true, false))