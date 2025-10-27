# explosion_effect.gd
extends TextureRect

@onready var timer = $Timer

func play_at_position(position: Vector2):
	global_position = position - (size / 2) # Centraliza o efeito na posição
	timer.start()

func _on_timer_timeout():
	queue_free() # Remove o efeito após o tempo
