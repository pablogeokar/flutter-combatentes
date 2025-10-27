# enums.gd
# Este arquivo centraliza todos os enums do jogo, similar ao `modelos_jogo.dart`.

# Equivalente ao enum Equipe
enum Equipe { VERDE, PRETA }

# Equivalente ao enum GamePhase
enum GamePhase {
	WAITING_FOR_OPPONENT,
	PIECE_PLACEMENT,
	WAITING_FOR_OPPONENT_READY,
	GAME_STARTING,
	GAME_IN_PROGRESS,
	GAME_FINISHED
}

# Equivalente ao enum PlacementStatus
enum PlacementStatus {
	PLACING,
	READY,
	WAITING
}

# Equivalente ao enum Patente
enum Patente {
	PRISIONEIRO,
	AGENTE_SECRETO,
	SOLDADO,
	CABO,
	SARGENTO,
	TENENTE,
	CAPITAO,
	MAJOR,
	CORONEL,
	GENERAL,
	MARECHAL,
	MINA_TERRESTRE
}
