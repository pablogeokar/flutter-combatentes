# blood_splatter_effect.gd
extends TextureRect

@onready var tween = $Tween

func play_at_position(position: Vector2, duration: float = 1.0):
	global_position = position - (size / 2) # Centraliza o efeito na posição
	
	tween.tween_property(self, "modulate:a", 0.0, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_callback(Callable(self, "queue_free")).set_delay(duration)
	tween.play()
