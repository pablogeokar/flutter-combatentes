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
