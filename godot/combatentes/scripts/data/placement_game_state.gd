# placement_game_state.gd
extends Resource
class_name PlacementGameState

const Enums = preload("res://scripts/data/enums.gd")
const PecaJogo = preload("res://scripts/data/peca_jogo.gd")

@export var game_id: String
@export var player_id: String
@export var available_pieces: Dictionary # Patente (int) -> Quantidade (int)
@export var placed_pieces: Array[PecaJogo]
@export var player_area: Array[int] # Linhas válidas para posicionamento
@export var local_status: Enums.PlacementStatus
@export var opponent_status: Enums.PlacementStatus
@export var selected_piece_type: Enums.Patente = Enums.Patente.PRISIONEIRO # Pode ser null
@export var game_phase: Enums.GamePhase

func _init(
	p_game_id: String = "",
	p_player_id: String = "",
	p_available_pieces: Dictionary = {},
	p_placed_pieces: Array[PecaJogo] = [],
	p_player_area: Array[int] = [],
	p_local_status: Enums.PlacementStatus = Enums.PlacementStatus.PLACING,
	p_opponent_status: Enums.PlacementStatus = Enums.PlacementStatus.WAITING,
	p_selected_piece_type: Enums.Patente = Enums.Patente.PRISIONEIRO,
	p_game_phase: Enums.GamePhase = Enums.GamePhase.PIECE_PLACEMENT
):
	game_id = p_game_id
	player_id = p_player_id
	available_pieces = p_available_pieces
	placed_pieces = p_placed_pieces
	player_area = p_player_area
	local_status = p_local_status
	opponent_status = p_opponent_status
	selected_piece_type = p_selected_piece_type
	game_phase = p_game_phase

static func create_initial_inventory() -> Dictionary:
	return {
		Enums.Patente.MARECHAL: 1,
		Enums.Patente.GENERAL: 1,
		Enums.Patente.CORONEL: 2,
		Enums.Patente.MAJOR: 3,
		Enums.Patente.CAPITAO: 4,
		Enums.Patente.TENENTE: 4,
		Enums.Patente.SARGENTO: 4,
		Enums.Patente.CABO: 5,
		Enums.Patente.SOLDADO: 8,
		Enums.Patente.AGENTE_SECRETO: 1,
		Enums.Patente.PRISIONEIRO: 1,
		Enums.Patente.MINA_TERRESTRE: 6,
	}

func get_total_pieces_remaining() -> int:
	var total = 0
	for count in available_pieces.values():
		total += count
	return total

func get_all_pieces_placed() -> bool:
	return get_total_pieces_remaining() == 0

func can_confirm() -> bool:
	return get_all_pieces_placed() and local_status == Enums.PlacementStatus.PLACING
