import { v4 as uuidv4 } from "uuid";
import {
  EstadoJogo,
  PecaJogo,
  PosicaoTabuleiro,
  Jogador,
  Equipe,
} from "../types/game.types.js";

export class GameStateManager {
  public static createInitialGameState(
    gameId: string,
    p1: Omit<Jogador, "ws">,
    p2: Omit<Jogador, "ws">
  ): EstadoJogo {
    const pecas = this.createInitialPieces();

    return {
      idPartida: gameId,
      jogadores: [p1, p2],
      pecas: pecas,
      idJogadorDaVez: p1.id,
      jogoTerminou: false,
      idVencedor: null,
    };
  }

  private static createInitialPieces(): PecaJogo[] {
    const pecas: PecaJogo[] = [];
    const contagemPecas: { [key: string]: number } = {
      general: 1,
      coronel: 1,
      major: 2,
      capitao: 3,
      tenente: 4,
      sargento: 4,
      cabo: 4,
      soldado: 5,
      agenteSecreto: 1,
      prisioneiro: 1,
      minaTerrestre: 6,
    };

    // Criar peças pretas (linhas 0-3)
    const posicoesPretas = this.generatePositions(0, 3);
    this.shuffleArray(posicoesPretas);

    let posIndexPreto = 0;
    for (const [patente, quantidade] of Object.entries(contagemPecas)) {
      for (let i = 0; i < quantidade; i++) {
        pecas.push({
          id: `preta_${patente}_${i}`,
          patente: patente,
          equipe: Equipe.Preta,
          posicao: posicoesPretas[posIndexPreto++]!,
          foiRevelada: false,
        });
      }
    }

    // Criar peças verdes (linhas 6-9)
    const posicoesVerdes = this.generatePositions(6, 9);
    this.shuffleArray(posicoesVerdes);

    let posIndexVerde = 0;
    for (const [patente, quantidade] of Object.entries(contagemPecas)) {
      for (let i = 0; i < quantidade; i++) {
        pecas.push({
          id: `verde_${patente}_${i}`,
          patente: patente,
          equipe: Equipe.Verde,
          posicao: posicoesVerdes[posIndexVerde++]!,
          foiRevelada: false,
        });
      }
    }

    return pecas;
  }

  private static generatePositions(
    startRow: number,
    endRow: number
  ): PosicaoTabuleiro[] {
    const positions: PosicaoTabuleiro[] = [];
    for (let i = startRow; i <= endRow; i++) {
      for (let j = 0; j < 10; j++) {
        positions.push({ linha: i, coluna: j });
      }
    }
    return positions;
  }

  private static shuffleArray<T>(array: T[]): void {
    for (let i = array.length - 1; i > 0; i--) {
      const j = Math.floor(Math.random() * (i + 1));
      [array[i], array[j]] = [array[j]!, array[i]!];
    }
  }
}
