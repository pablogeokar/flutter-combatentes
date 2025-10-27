# matchmaking_screen.gd
extends Control

@onready var animation_player = $AnimationPlayer

func _ready():
	# Inicia a animação de "loading"
	animation_player.play("loading")
	
	# Futuramente, aqui iniciaremos a conexão com o WebSocket para o matchmaking.
	print("Tela de matchmaking iniciada. Aguardando conexão com o servidor...")

func _on_cancel_button_pressed():
	print("Matchmaking cancelado pelo usuário.")
	# Volta para a tela de inserção de nome
	SceneManager.change_scene("res://scenes/ui/name_input_screen.tscn")
