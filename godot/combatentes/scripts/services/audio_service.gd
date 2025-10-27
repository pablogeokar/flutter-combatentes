# audio_service.gd
extends Node

func play_sound(path: String):
	var sound = load(path)
	if sound is AudioStreamWAV or sound is AudioStreamMP3:
		var audio_player = AudioStreamPlayer.new()
		audio_player.stream = sound
		add_child(audio_player)
		audio_player.play()
		audio_player.connect("finished", Callable(audio_player, "queue_free"))
	else:
		print_error("Formato de áudio não suportado ou arquivo não encontrado: ", path)
