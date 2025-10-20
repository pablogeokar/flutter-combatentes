import {
  EstadoJogo,
  PecaJogo,
  PosicaoTabuleiro,
  Jogador,
  Equipe,
  Patentes,
  ResultadoMovimento,
  ResultadoCombate,
  PlacementGameState,
  PlacementStatus,
  GamePhase,
  INITIAL_PIECE_INVENTORY,
} from "../types/game.types.js";
import { PlacementManager } from "./PlacementManager.js";

export class GameController {
  private static readonly lagos: Set<string> = new Set([
    "4-2",
    "4-3",
    "5-2",
    "5-3",
    "4-6",
    "4-7",
    "5-6",
    "5-7",
  ]);

  private placementManager: PlacementManager;

  constructor() {
    this.placementManager = new PlacementManager();
  }

  public moverPeca(
    estadoAtual: EstadoJogo,
    idPeca: string,
    novaPosicao: PosicaoTabuleiro,
    idJogadorQueSolicitou: string
  ): ResultadoMovimento {
    const pecaAMover = estadoAtual.pecas.find((p) => p.id === idPeca);
    if (!pecaAMover) return { erro: "Peça não encontrada." };

    const jogadorAtual = estadoAtual.jogadores.find(
      (j) => j.id === idJogadorQueSolicitou
    );
    if (!jogadorAtual || jogadorAtual.equipe !== pecaAMover.equipe) {
      return { erro: "Peça não pertence ao jogador." };
    }

    if (estadoAtual.idJogadorDaVez !== idJogadorQueSolicitou) {
      return { erro: "Não é o seu turno." };
    }

    const erroMovimento = this.validarMovimento(
      pecaAMover,
      novaPosicao,
      estadoAtual.pecas
    );
    if (erroMovimento) return { erro: erroMovimento };

    let pecasAtualizadas = [...estadoAtual.pecas];
    const pecaDefensora = pecasAtualizadas.find(
      (p) =>
        p.posicao.linha === novaPosicao.linha &&
        p.posicao.coluna === novaPosicao.coluna
    );

    console.log(
      `🔍 Verificando combate na posição (${novaPosicao.linha}, ${novaPosicao.coluna})`
    );
    console.log(
      `👤 Peça atacante: ${pecaAMover.patente} (${pecaAMover.equipe})`
    );

    if (pecaDefensora) {
      console.log(
        `🛡️ Peça defensora encontrada: ${pecaDefensora.patente} (${pecaDefensora.equipe})`
      );
      console.log(
        `⚔️ INICIANDO COMBATE: ${pecaAMover.patente} vs ${pecaDefensora.patente}`
      );

      const resultadoCombate = this.resolverCombate(pecaAMover, pecaDefensora);
      console.log(
        `🏆 Resultado do combate: ${
          resultadoCombate.vencedor
            ? resultadoCombate.vencedor.patente
            : "EMPATE"
        }`
      );

      pecasAtualizadas = this.processarCombate(
        pecasAtualizadas,
        pecaAMover,
        pecaDefensora,
        novaPosicao,
        resultadoCombate
      );
    } else {
      console.log(`🚶 Movimento simples - nenhuma peça na posição de destino`);
      const indicePeca = pecasAtualizadas.findIndex((p) => p.id === idPeca);
      pecasAtualizadas[indicePeca] = { ...pecaAMover, posicao: novaPosicao };
    }

    const proximoJogador = estadoAtual.jogadores.find(
      (j) => j.id !== estadoAtual.idJogadorDaVez
    )!;

    const estadoIntermediario: EstadoJogo = {
      ...estadoAtual,
      pecas: pecasAtualizadas,
      idJogadorDaVez: proximoJogador.id,
    };

    const estadoFinal = this.verificarVitoria(
      estadoIntermediario,
      jogadorAtual
    );
    return { novoEstado: estadoFinal };
  }

  private validarMovimento(
    peca: PecaJogo,
    novaPosicao: PosicaoTabuleiro,
    pecas: PecaJogo[]
  ): string | null {
    if (peca.patente === "minaTerrestre" || peca.patente === "prisioneiro")
      return "Esta peça não pode se mover.";

    if (
      peca.posicao.linha === novaPosicao.linha &&
      peca.posicao.coluna === novaPosicao.coluna
    )
      return "Movimento inválido.";

    if (
      peca.posicao.linha !== novaPosicao.linha &&
      peca.posicao.coluna !== novaPosicao.coluna
    )
      return "Movimentos na diagonal não são permitidos.";

    if (GameController.lagos.has(`${novaPosicao.linha}-${novaPosicao.coluna}`))
      return "Não é possível mover para um lago.";

    const pecaNoDestino = pecas.find(
      (p) =>
        p.posicao.linha === novaPosicao.linha &&
        p.posicao.coluna === novaPosicao.coluna
    );
    if (pecaNoDestino && pecaNoDestino.equipe === peca.equipe)
      return "Não é possível mover para uma casa ocupada por uma peça aliada.";

    const distancia =
      Math.abs(peca.posicao.linha - novaPosicao.linha) +
      Math.abs(peca.posicao.coluna - novaPosicao.coluna);

    if (peca.patente !== "soldado" && distancia > 1)
      return "Esta peça só pode se mover uma casa por vez.";

    // Validação de caminho livre para o soldado
    if (peca.patente === "soldado" && distancia > 1) {
      return this.validarCaminhoSoldado(peca.posicao, novaPosicao, pecas);
    }

    return null;
  }

  private validarCaminhoSoldado(
    posicaoAtual: PosicaoTabuleiro,
    novaPosicao: PosicaoTabuleiro,
    pecas: PecaJogo[]
  ): string | null {
    if (posicaoAtual.linha === novaPosicao.linha) {
      // Movimento horizontal
      const direcao = novaPosicao.coluna > posicaoAtual.coluna ? 1 : -1;
      for (
        let c = posicaoAtual.coluna + direcao;
        c !== novaPosicao.coluna;
        c += direcao
      ) {
        if (
          pecas.some(
            (p) =>
              p.posicao.linha === posicaoAtual.linha && p.posicao.coluna === c
          )
        ) {
          return "O caminho do soldado está bloqueado.";
        }
      }
    } else {
      // Movimento vertical
      const direcao = novaPosicao.linha > posicaoAtual.linha ? 1 : -1;
      for (
        let l = posicaoAtual.linha + direcao;
        l !== novaPosicao.linha;
        l += direcao
      ) {
        if (
          pecas.some(
            (p) =>
              p.posicao.linha === l && p.posicao.coluna === posicaoAtual.coluna
          )
        ) {
          return "O caminho do soldado está bloqueado.";
        }
      }
    }
    return null;
  }

  private resolverCombate(
    atacante: PecaJogo,
    defendida: PecaJogo
  ): ResultadoCombate {
    // Regra especial: Agente Secreto vs Marechal
    if (
      atacante.patente === "agenteSecreto" &&
      defendida.patente === "marechal"
    )
      return { vencedor: atacante, perdedor: defendida };

    // Regra especial: Mina Terrestre
    if (defendida.patente === "minaTerrestre") {
      return atacante.patente === "cabo"
        ? { vencedor: atacante, perdedor: defendida }
        : { vencedor: defendida, perdedor: atacante };
    }

    // Combate padrão por força
    const forcaAtacante = Patentes[atacante.patente]?.forca || 0;
    const forcaDefendida = Patentes[defendida.patente]?.forca || 0;

    if (forcaAtacante > forcaDefendida)
      return { vencedor: atacante, perdedor: defendida };
    if (forcaDefendida > forcaAtacante)
      return { vencedor: defendida, perdedor: atacante };
    return { vencedor: null, perdedor: null }; // Empate
  }

  private processarCombate(
    pecasAtualizadas: PecaJogo[],
    atacante: PecaJogo,
    defensora: PecaJogo,
    novaPosicao: PosicaoTabuleiro,
    resultado: ResultadoCombate
  ): PecaJogo[] {
    // Remove as peças do combate
    pecasAtualizadas = pecasAtualizadas.filter(
      (p) => p.id !== atacante.id && p.id !== defensora.id
    );

    if (resultado.vencedor) {
      if (resultado.vencedor.id === atacante.id) {
        // Atacante venceu - move para nova posição e revela
        pecasAtualizadas.push({
          ...atacante,
          posicao: novaPosicao,
          foiRevelada: true,
        });
      } else {
        // Defensor venceu - permanece na posição e revela
        pecasAtualizadas.push({
          ...defensora,
          foiRevelada: true,
        });
      }
    }
    // Em caso de empate, ambas as peças são removidas (já filtradas acima)

    return pecasAtualizadas;
  }

  private verificarVitoria(
    estado: EstadoJogo,
    jogadorQueMoveu: Omit<Jogador, "ws">
  ): EstadoJogo {
    const equipeAdversaria =
      jogadorQueMoveu.equipe === Equipe.Preta ? Equipe.Verde : Equipe.Preta;

    // Vitória por capturar o prisioneiro (bandeira) adversário
    const prisioneiroAdversario = estado.pecas.find(
      (p) => p.patente === "prisioneiro" && p.equipe === equipeAdversaria
    );

    if (!prisioneiroAdversario) {
      return { ...estado, jogoTerminou: true, idVencedor: jogadorQueMoveu.id };
    }

    // Vitória por deixar o adversário sem peças móveis
    const pecasMoveisAdversarias = estado.pecas.some(
      (p) =>
        p.equipe === equipeAdversaria &&
        p.patente !== "minaTerrestre" &&
        p.patente !== "prisioneiro"
    );

    if (!pecasMoveisAdversarias) {
      return { ...estado, jogoTerminou: true, idVencedor: jogadorQueMoveu.id };
    }

    return estado;
  }

  // ===== PLACEMENT PHASE METHODS =====

  /**
   * Validates piece placement area (must be within player's 4 rows)
   */
  public validatePlacementArea(
    position: PosicaoTabuleiro,
    playerTeam: Equipe
  ): { valid: boolean; error?: string } {
    const playerArea =
      playerTeam === Equipe.Verde ? [0, 1, 2, 3] : [6, 7, 8, 9];

    if (!playerArea.includes(position.linha)) {
      return {
        valid: false,
        error: `Posição (${position.linha}, ${position.coluna}) fora da área do jogador ${playerTeam}`,
      };
    }

    // Check board bounds
    if (
      position.linha < 0 ||
      position.linha > 9 ||
      position.coluna < 0 ||
      position.coluna > 9
    ) {
      return { valid: false, error: "Posição fora dos limites do tabuleiro" };
    }

    return { valid: true };
  }

  /**
   * Validates piece count and composition for a player's army
   */
  public validatePieceComposition(pieces: PecaJogo[]): {
    valid: boolean;
    error?: string;
  } {
    if (pieces.length !== 40) {
      return {
        valid: false,
        error: `Número incorreto de peças: ${pieces.length}/40`,
      };
    }

    // Count pieces by type
    const pieceComposition: { [patente: string]: number } = {};
    pieces.forEach((piece) => {
      pieceComposition[piece.patente] =
        (pieceComposition[piece.patente] || 0) + 1;
    });

    // Validate against required composition
    for (const [patente, requiredCount] of Object.entries(
      INITIAL_PIECE_INVENTORY
    )) {
      const actualCount = pieceComposition[patente] || 0;
      if (actualCount !== requiredCount) {
        const patenteNome = Patentes[patente]?.nome || patente;
        return {
          valid: false,
          error: `Composição incorreta: ${patenteNome} - esperado ${requiredCount}, atual ${actualCount}`,
        };
      }
    }

    return { valid: true };
  }

  /**
   * Validates complete placement for a player
   */
  public validateCompletePlacement(
    pieces: PecaJogo[],
    playerTeam: Equipe
  ): { valid: boolean; error?: string } {
    // Validate piece count and composition
    const compositionValidation = this.validatePieceComposition(pieces);
    if (!compositionValidation.valid) {
      return compositionValidation;
    }

    // Validate all pieces are in correct area
    const playerArea =
      playerTeam === Equipe.Verde ? [0, 1, 2, 3] : [6, 7, 8, 9];
    const invalidPieces = pieces.filter(
      (piece) => !playerArea.includes(piece.posicao.linha)
    );

    if (invalidPieces.length > 0) {
      return {
        valid: false,
        error: `${invalidPieces.length} peças estão fora da área do jogador`,
      };
    }

    // Check for overlapping pieces
    const positionSet = new Set<string>();
    for (const piece of pieces) {
      const posKey = `${piece.posicao.linha}-${piece.posicao.coluna}`;
      if (positionSet.has(posKey)) {
        return {
          valid: false,
          error: `Peças sobrepostas na posição (${piece.posicao.linha}, ${piece.posicao.coluna})`,
        };
      }
      positionSet.add(posKey);
    }

    return { valid: true };
  }

  /**
   * Checks if both players are ready to start the game
   */
  public areBothPlayersReady(
    player1Status: PlacementStatus,
    player2Status: PlacementStatus
  ): boolean {
    return (
      player1Status === PlacementStatus.Ready &&
      player2Status === PlacementStatus.Ready
    );
  }

  /**
   * Transitions from placement phase to game start
   */
  public transitionToGameStart(
    gameId: string,
    player1Pieces: PecaJogo[],
    player2Pieces: PecaJogo[],
    jogadores: Omit<Jogador, "ws">[]
  ): { success: boolean; estadoJogo?: EstadoJogo; error?: string } {
    // Validate both players' placements
    const player1Team = jogadores[0].equipe;
    const player2Team = jogadores[1].equipe;

    const player1Validation = this.validateCompletePlacement(
      player1Pieces,
      player1Team
    );
    if (!player1Validation.valid) {
      return { success: false, error: `Jogador 1: ${player1Validation.error}` };
    }

    const player2Validation = this.validateCompletePlacement(
      player2Pieces,
      player2Team
    );
    if (!player2Validation.valid) {
      return { success: false, error: `Jogador 2: ${player2Validation.error}` };
    }

    // Combine all pieces
    const allPieces = [...player1Pieces, ...player2Pieces];

    // Create initial game state
    const estadoJogo: EstadoJogo = {
      idPartida: gameId,
      jogadores: jogadores,
      pecas: allPieces,
      idJogadorDaVez: jogadores[0].id, // First player starts
      jogoTerminou: false,
      idVencedor: null,
    };

    return { success: true, estadoJogo };
  }

  /**
   * Gets the placement manager instance
   */
  public getPlacementManager(): PlacementManager {
    return this.placementManager;
  }
}
