# victory_screen.gd
extends Control

func _on_play_again_button_pressed():
	print("Jogar Novamente!")
	# TODO: Implementar lógica para iniciar nova partida
	SceneManager.change_scene("res://scenes/ui/matchmaking_screen.tscn")

func _on_main_menu_button_pressed():
	print("Voltar ao Menu Principal!")
	# TODO: Implementar lógica para voltar ao menu principal (se houver)
	SceneManager.change_scene("res://scenes/ui/name_input_screen.tscn")
