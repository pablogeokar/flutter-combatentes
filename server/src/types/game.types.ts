import { WebSocket } from "ws";

export enum Equipe {
  Verde = "verde",
  Preta = "preta",
}

export interface Patente {
  forca: number;
  nome: string;
  id: string;
}

export const Patentes: { [key: string]: Patente } = {
  prisioneiro: { id: "prisioneiro", forca: 0, nome: "Prisioneiro" },
  agenteSecreto: { id: "agenteSecreto", forca: 1, nome: "Agente Secreto" },
  soldado: { id: "soldado", forca: 2, nome: "Soldado" },
  cabo: { id: "cabo", forca: 3, nome: "Cabo" },
  sargento: { id: "sargento", forca: 4, nome: "Sargento" },
  tenente: { id: "tenente", forca: 5, nome: "Tenente" },
  capitao: { id: "capitao", forca: 6, nome: "Capitão" },
  major: { id: "major", forca: 7, nome: "Major" },
  coronel: { id: "coronel", forca: 8, nome: "Coronel" },
  general: { id: "general", forca: 9, nome: "General" },
  marechal: { id: "marechal", forca: 10, nome: "Marechal" },
  minaTerrestre: { id: "minaTerrestre", forca: 11, nome: "Mina Terrestre" },
};

export interface PosicaoTabuleiro {
  linha: number;
  coluna: number;
}

export interface PecaJogo {
  id: string;
  patente: string; // Apenas o ID da patente para compatibilidade com Flutter
  equipe: Equipe;
  posicao: PosicaoTabuleiro;
  foiRevelada: boolean;
}

export interface Jogador {
  id: string;
  nome: string;
  equipe: Equipe;
  ws: WebSocket;
}

export interface EstadoJogo {
  idPartida: string;
  jogadores: Omit<Jogador, "ws">[]; // Não enviamos o objeto WebSocket para o cliente
  pecas: PecaJogo[];
  idJogadorDaVez: string;
  jogoTerminou: boolean;
  idVencedor?: string | null;
}

export interface GameSession {
  id: string;
  jogadores: [Jogador, Jogador];
  estadoJogo: EstadoJogo;
}

export interface ResultadoMovimento {
  novoEstado?: EstadoJogo;
  erro?: string;
}

export interface ResultadoCombate {
  vencedor: PecaJogo | null;
  perdedor: PecaJogo | null;
}

export enum GamePhase {
  WaitingForOpponent = "waitingForOpponent",
  PiecePlacement = "piecePlacement",
  WaitingForOpponentReady = "waitingForOpponentReady",
  GameStarting = "gameStarting",
  GameInProgress = "gameInProgress",
  GameFinished = "gameFinished",
}

export enum PlacementStatus {
  Placing = "placing",
  Ready = "ready",
  Waiting = "waiting",
}

export interface PlacementGameState {
  gameId: string;
  playerId: string;
  availablePieces: { [patente: string]: number };
  placedPieces: PecaJogo[];
  playerArea: number[];
  localStatus: PlacementStatus;
  opponentStatus: PlacementStatus;
  selectedPieceType?: string | null;
  gamePhase: GamePhase;
}

export interface PlacementMessageData {
  pieceId?: string;
  patente?: string;
  position?: PosicaoTabuleiro;
  status?: PlacementStatus;
  allPieces?: PecaJogo[];
}

export interface PlacementMessage {
  type:
    | "PLACEMENT_UPDATE"
    | "PLACEMENT_READY"
    | "PLACEMENT_STATUS"
    | "GAME_START";
  gameId: string;
  playerId: string;
  data?: PlacementMessageData;
}

export const INITIAL_PIECE_INVENTORY: { [patente: string]: number } = {
  marechal: 1,
  general: 1,
  coronel: 2,
  major: 3,
  capitao: 4,
  tenente: 4,
  sargento: 4,
  cabo: 5,
  soldado: 8,
  agenteSecreto: 1,
  prisioneiro: 1,
  minaTerrestre: 6,
};
