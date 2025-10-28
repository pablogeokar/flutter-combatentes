# audio_service.gd
extends Node

var background_music_player: AudioStreamPlayer
var sound_effects_player: AudioStreamPlayer

func _ready():
	# Cria players de áudio
	background_music_player = AudioStreamPlayer.new()
	sound_effects_player = AudioStreamPlayer.new()
	
	add_child(background_music_player)
	add_child(sound_effects_player)
	
	# Configura o player de música de fundo para loop
	background_music_player.finished.connect(_on_background_music_finished)

func play_sound(path: String):
	var sound = load(path)
	if sound != null and (sound is AudioStreamWAV or sound is AudioStreamMP3 or sound is AudioStreamOggVorbis):
		sound_effects_player.stream = sound
		sound_effects_player.play()
	else:
		print("ERRO: Formato de áudio não suportado ou arquivo não encontrado: ", path)

func play_background_music(path: String, loop: bool = true):
	var music = load(path)
	if music != null and (music is AudioStreamWAV or music is AudioStreamMP3 or music is AudioStreamOggVorbis):
		background_music_player.stream = music
		if music is AudioStreamWAV:
			music.loop_mode = AudioStreamWAV.LOOP_FORWARD if loop else AudioStreamWAV.LOOP_DISABLED
		elif music is AudioStreamMP3:
			music.loop = loop
		elif music is AudioStreamOggVorbis:
			music.loop = loop
		background_music_player.play()
	else:
		print("ERRO: Formato de música não suportado ou arquivo não encontrado: ", path)

func stop_background_music():
	background_music_player.stop()

func set_master_volume(volume: float):
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(volume))

func set_music_volume(volume: float):
	background_music_player.volume_db = linear_to_db(volume)

func set_sfx_volume(volume: float):
	sound_effects_player.volume_db = linear_to_db(volume)

func _on_background_music_finished():
	# Reinicia a música se estiver em loop
	if background_music_player.stream != null:
		background_music_player.play()
