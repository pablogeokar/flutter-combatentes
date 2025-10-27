# main.gd
extends Node2D

func _ready():
	# Carrega a tela de entrada de nome como a primeira cena do jogo.
	SceneManager.change_scene("res://scenes/ui/name_input_screen.tscn")
