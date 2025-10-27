# combat_animation.gd
extends Control

const PecaJogo = preload("res://scripts/data/peca_jogo.gd")

@onready var combat_label = $CenterContainer/VBoxContainer/CombatLabel
@onready var attacker_piece_texture = $CenterContainer/VBoxContainer/AttackerPiece
@onready var defender_piece_texture = $CenterContainer/VBoxContainer/DefenderPiece
@onready var vs_label = $CenterContainer/VBoxContainer/VsLabel
@onready var outcome_label = $CenterContainer/VBoxContainer/OutcomeLabel
@onready var timer = $Timer

func play_animation(combat_info: Dictionary):
	# Exemplo de combat_info:
	# {"attackingPiece": {id: "...", patente: "...", ...}, "defendingPiece": {...}, "winnerPieceId": "..."}

	combat_label.text = "COMBATE!"
	vs_label.text = "VS"
	outcome_label.text = ""

	# Carrega e exibe as imagens das peças envolvidas
	var attacker_patente = PecaJogo.INFO_PATENTES[combat_info.attackingPiece.patente]
	var defender_patente = PecaJogo.INFO_PATENTES[combat_info.defendingPiece.patente]

	attacker_piece_texture.texture = load(attacker_patente.imagem)
	defender_piece_texture.texture = load(defender_patente.imagem)

	# Toca o som de tiro
	AudioService.play_sound("res://assets/sounds/tiro.wav")

	# Inicia o timer para mostrar o resultado e depois se autodestruir
	timer.start()

func _on_timer_timeout():
	# Após o timer, mostra o resultado (simplificado por enquanto)
	outcome_label.text = "Peça " + str(combat_info.winnerPieceId) + " venceu!"
	# Toca som de explosão se uma mina foi atingida, ou outro som de vitória/derrota
	# AudioService.play_sound("res://assets/sounds/explosao.wav") # Exemplo

	# Um pequeno atraso antes de remover a animação
	get_tree().create_timer(1.0).connect("timeout", Callable(self, "queue_free"))
