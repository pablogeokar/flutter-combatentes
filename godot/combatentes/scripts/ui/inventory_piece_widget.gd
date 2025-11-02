# inventory_piece_widget.gd
extends PanelContainer

signal piece_selected(patente_enum)

const Patente = preload("res://scripts/data/enums.gd").Patente


@onready var piece_image = $VBoxContainer/PieceImage
@onready var piece_name_label = $VBoxContainer/PieceName
@onready var piece_count_label = $VBoxContainer/PieceCount

var current_patente: Patente
var is_selected: bool = false:
	set(value):
		is_selected = value
		_update_selection_visual()

func setup(patente_enum: Patente, count: int):
	current_patente = patente_enum
	
	# Carrega a imagem da peça usando o caminho do PecaJogo
	var image_path = PecaJogo.INFO_PATENTES[patente_enum].imagem
	if image_path:
		piece_image.texture = load(image_path)
	
	piece_name_label.text = PecaJogo.INFO_PATENTES[patente_enum].nome
	piece_count_label.text = "x" + str(count)
	_update_selection_visual()

func _gui_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		emit_signal("piece_selected", current_patente)
		grab_focus()

func _update_selection_visual():
	if is_selected:
		add_theme_color_override("panel_color", Color("ffff00")) # Amarelo para destaque
	else:
		remove_theme_color_override("panel_color")