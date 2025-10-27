# name_input_screen.gd
extends Control

# Sinal emitido quando o nome é confirmado
signal name_confirmed(player_name)

@onready var line_edit = $VBoxContainer/LineEdit

func _on_button_pressed():
	var player_name = line_edit.text
	if not player_name.is_empty():
		print("Nome do jogador: ", player_name)
		# Salva o nome do jogador (a ser implementado)
		# Global.player_name = player_name
		
		# Muda para a tela de matchmaking
		SceneManager.change_scene("res://scenes/ui/matchmaking_screen.tscn")
	else:
		print("O nome não pode estar vazio.")
