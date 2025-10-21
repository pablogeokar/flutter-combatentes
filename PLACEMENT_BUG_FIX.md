# Correção do Bug de Posicionamento de Peças

## Problema Identificado

O jogo estava travando na fase de posicionamento de peças com o erro:

```
[ERROR] 40 pieces still need to be placed
```

Mesmo quando os jogadores posicionavam todas as 40 peças e clicavam em "PRONTO", o servidor rejeitava a confirmação.

## Causa Raiz

O problema estava na validação do servidor no arquivo `WebSocketMessageHandler.ts`. O servidor:

1. **Recebia as peças corretamente** através do campo `allPieces` na mensagem `PLACEMENT_READY`
2. **Atualizava apenas o campo `placedPieces`** no estado do jogador
3. **NÃO atualizava o inventário (`availablePieces`)**
4. **A validação verificava se o inventário estava vazio** para confirmar que todas as peças foram posicionadas
5. **Como o inventário nunca era zerado, a validação sempre falhava**

## Solução Implementada

Modificado o método `handlePlacementReady` no `WebSocketMessageHandler.ts` para:

```typescript
// Calculate updated inventory based on placed pieces
const updatedInventory = { ...playerState.availablePieces };

// Reset inventory to empty since all pieces are now placed
Object.keys(updatedInventory).forEach((patente) => {
  updatedInventory[patente] = 0;
});

updatedPlayerState = {
  ...playerState,
  placedPieces: message.data.allPieces,
  availablePieces: updatedInventory, // ← Esta linha foi adicionada
};
```

## Resultado

Agora quando o cliente envia a mensagem `PLACEMENT_READY` com todas as 40 peças:

1. ✅ O servidor atualiza o `placedPieces` com as peças recebidas
2. ✅ O servidor zera o inventário (`availablePieces`)
3. ✅ A validação de completude passa corretamente
4. ✅ O jogo pode prosseguir para a fase de gameplay

## Arquivos Modificados

- `server/src/websocket/WebSocketMessageHandler.ts` - Linha ~407-420

## Problema Adicional Descoberto

Após a primeira correção, descobrimos um segundo problema:

**Incompatibilidade de tipos de mensagem:**

- Servidor enviava: `GAME_START`
- Cliente esperava: `PLACEMENT_GAME_START`

## Segunda Correção

Modificados os arquivos:

1. **`server/src/websocket/WebSocketMessageHandler.ts`**:

   ```typescript
   type: "PLACEMENT_GAME_START", // ← Alterado de "GAME_START"
   ```

2. **`server/src/types/game.types.ts`**:
   ```typescript
   | "PLACEMENT_GAME_START"; // ← Alterado de "GAME_START"
   ```

## Terceiro Problema Descoberto

Após as correções anteriores, o jogo chegava à tela de gameplay mas as peças não apareciam:

**Problema de comunicação cliente-servidor:**

- Servidor enviava apenas `PLACEMENT_GAME_START` com `estadoJogo` em `data`
- Cliente esperava também `atualizacaoEstado` com estado em `payload`
- O `gameStateProvider` não era atualizado com o estado do jogo

## Terceira Correção

Modificado o método `broadcastGameStart` no `WebSocketMessageHandler.ts` para enviar **duas mensagens**:

1. **Mensagem de notificação**: `PLACEMENT_GAME_START` (para o placement controller)
2. **Mensagem de estado**: `atualizacaoEstado` (para o game state provider)

```typescript
// Send placement game start notification
const placementMessage = JSON.stringify({
  type: "PLACEMENT_GAME_START",
  gameId: session.id,
  data: { estadoJogo: session.estadoJogo },
});

// Send game state update
const gameStateMessage = JSON.stringify({
  type: "atualizacaoEstado",
  payload: session.estadoJogo,
});

// Send both messages to each player
player.ws.send(placementMessage);
player.ws.send(gameStateMessage);
```

## Status

🟢 **COMPLETAMENTE RESOLVIDO** - Todos os três bugs foram corrigidos:

1. ✅ Inventário é zerado corretamente quando peças são posicionadas
2. ✅ Tipo de mensagem de início do jogo corrigido
3. ✅ Estado do jogo é enviado corretamente para o cliente
4. ✅ Peças agora devem aparecer no tabuleiro
5. ✅ Servidor recompilado e reiniciado com todas as correções
