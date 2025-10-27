# main.gd
extends Node2D

# Este script irá gerenciar a lógica principal do jogo, 
# como inicializar o tabuleiro, carregar as peças e controlar o fluxo das cenas.

func _ready():
	# A cena principal agora é responsável por decidir qual tela mostrar primeiro.
	# Por enquanto, vamos direto para a tela de nome.
	# No futuro, podemos verificar se um nome de usuário já existe.
	SceneManager.change_scene("res://scenes/ui/name_input_screen.tscn")


