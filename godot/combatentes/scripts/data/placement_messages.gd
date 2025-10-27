# placement_messages.gd
extends RefCounted
class_name PlacementMessage, PlacementMessageData

const Enums = preload("res://scripts/data/enums.gd")
const PecaJogo = preload("res://scripts/data/peca_jogo.gd")

# Classe interna para os dados da mensagem
class PlacementMessageData:
	var piece_id: String
	var patente: Enums.Patente
	var position: Vector2i
	var status: Enums.PlacementStatus
	var all_pieces: Array[PecaJogo]

	func _init(
		p_piece_id: String = "",
		p_patente: Enums.Patente = Enums.Patente.PRISIONEIRO,
		p_position: Vector2i = Vector2i.ZERO,
		p_status: Enums.PlacementStatus = Enums.PlacementStatus.PLACING,
		p_all_pieces: Array[PecaJogo] = []
	):
		piece_id = p_piece_id
		patente = p_patente
		position = p_position
		status = p_status
		all_pieces = p_all_pieces

	func to_dict() -> Dictionary:
		var dict = {}
		if piece_id != "": dict["pieceId"] = piece_id
		if patente != Enums.Patente.PRISIONEIRO: dict["patente"] = Enums.Patente.keys()[patente]
		if position != Vector2i.ZERO: dict["position"] = {"linha": position.y, "coluna": position.x}
		if status != Enums.PlacementStatus.PLACING: dict["status"] = Enums.PlacementStatus.keys()[status]
		if not all_pieces.is_empty():
			var pieces_array = []
			for piece in all_pieces:
				pieces_array.append(piece.to_dict()) # Assumindo que PecaJogo também terá to_dict()
			dict["allPieces"] = pieces_array
		return dict

# Classe principal da mensagem de posicionamento
class PlacementMessage:
	var type: String
	var game_id: String	
	var player_id: String
	var data: PlacementMessageData

	func _init(
		p_type: String = "",
		p_game_id: String = "",
		p_player_id: String = "",
		p_data: PlacementMessageData = null
	):
		type = p_type
		game_id = p_game_id
		player_id = p_player_id
		data = p_data

	func to_dict() -> Dictionary:
		var dict = {
			"type": type,
			"gameId": game_id,
			"playerId": player_id,
		}
		if data != null:
			dict["data"] = data.to_dict()
		return dict

	static func placement_update(game_id: String, player_id: String, piece_id: String, patente: Enums.Patente, position: Vector2i) -> PlacementMessage:
		var msg_data = PlacementMessageData.new(piece_id, patente, position)
		return PlacementMessage.new("PLACEMENT_UPDATE", game_id, player_id, msg_data)

	static func placement_ready(game_id: String, player_id: String, all_pieces: Array[PecaJogo]) -> PlacementMessage:
		var msg_data = PlacementMessageData.new("", Enums.Patente.PRISIONEIRO, Vector2i.ZERO, Enums.PlacementStatus.READY, all_pieces)
		return PlacementMessage.new("PLACEMENT_READY", game_id, player_id, msg_data)

	static func placement_status(game_id: String, player_id: String, status: Enums.PlacementStatus) -> PlacementMessage:
		var msg_data = PlacementMessageData.new("", Enums.Patente.PRISIONEIRO, Vector2i.ZERO, status)
		return PlacementMessage.new("PLACEMENT_STATUS", game_id, player_id, msg_data)

	static func game_start(game_id: String, player_id: String) -> PlacementMessage:
		return PlacementMessage.new("GAME_START", game_id, player_id)