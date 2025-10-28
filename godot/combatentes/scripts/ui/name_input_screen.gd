# name_input_screen.gd
extends Control
class_name NameInputScreen

# Sinal emitido quando o nome é confirmado
signal name_confirmed(player_name)

var line_edit: LineEdit

func _ready():
	# Procura pelo LineEdit na árvore de nós (funciona com qualquer estrutura)
	line_edit = find_child("LineEdit", true, false)
	if line_edit == null:
		print("❌ ERRO: LineEdit não encontrado na cena")

func _on_button_pressed():
	if line_edit == null:
		print("❌ ERRO: LineEdit é null")
		return
		
	var player_name = line_edit.text
	if not player_name.is_empty():
		print("✅ Nome do jogador: ", player_name)
		# Salva o nome do jogador no Global
		Global.player_name = player_name
		
		# Muda para a tela de matchmaking
		SceneManager.change_scene("res://scenes/ui/matchmaking_screen.tscn")
	else:
		print("⚠️ O nome não pode estar vazio.")
