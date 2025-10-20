# Design Document

## Overview

O sistema de posicionamento manual de peças introduz uma nova fase no fluxo do jogo, entre o pareamento de jogadores e o início da partida. Esta fase permite que cada jogador posicione estrategicamente suas 40 peças em sua área do tabuleiro (4 linhas) antes de confirmar que está pronto para jogar.

## Architecture

### State Management

```
GamePhase enum:
- WAITING_FOR_OPPONENT (aguardando pareamento)
- PIECE_PLACEMENT (posicionando peças)
- WAITING_FOR_OPPONENT_READY (aguardando oponente confirmar)
- GAME_STARTING (iniciando partida)
- GAME_IN_PROGRESS (jogo em andamento)
```

### Client-Server Communication

```
WebSocket Messages:
- PLACEMENT_UPDATE: Atualiza posição de uma peça
- PLACEMENT_READY: Jogador confirma posicionamento
- PLACEMENT_STATUS: Status do oponente
- GAME_START: Ambos prontos, inicia partida
```

## Components and Interfaces

### 1. PiecePlacementScreen

**Responsabilidade:** Tela principal de posicionamento de peças

**Props:**

- `availablePieces: Map<Patente, int>` - Inventário de peças disponíveis
- `placedPieces: List<PecaJogo>` - Peças já posicionadas no tabuleiro
- `playerArea: List<int>` - Linhas válidas para posicionamento (0-3 ou 6-9)
- `opponentStatus: PlacementStatus` - Status do oponente
- `isReady: bool` - Se o jogador local confirmou

**Methods:**

- `onPieceSelect(Patente patente)` - Seleciona tipo de peça do inventário
- `onBoardTap(PosicaoTabuleiro posicao)` - Tenta posicionar peça selecionada
- `onPieceDrag(String pieceId, PosicaoTabuleiro newPosition)` - Move peça existente
- `onReadyPressed()` - Confirma posicionamento completo

### 2. PieceInventoryWidget

**Responsabilidade:** Exibe inventário de peças disponíveis para posicionamento

**Props:**

- `availablePieces: Map<Patente, int>` - Peças disponíveis por tipo
- `selectedPiece: Patente?` - Tipo de peça atualmente selecionado
- `onPieceSelect: Function(Patente)` - Callback para seleção de peça

**Layout:**

```
┌─────────────────────────────────────┐
│ Inventário de Peças                 │
├─────────────────────────────────────┤
│ [🎖️] Marechal (1)     [👨‍✈️] General (1)  │
│ [👨‍💼] Coronel (2)     [🎯] Major (3)     │
│ [⭐] Capitão (4)     [📊] Tenente (4)   │
│ [🔰] Sargento (4)    [🎖️] Cabo (5)      │
│ [👨‍🎤] Soldado (8)     [🕵️] Agente (1)    │
│ [🏴] Prisioneiro (1) [💣] Mina (6)      │
└─────────────────────────────────────┘
```

### 3. PlacementBoardWidget

**Responsabilidade:** Tabuleiro interativo para posicionamento de peças

**Props:**

- `placedPieces: List<PecaJogo>` - Peças já posicionadas
- `playerArea: List<int>` - Linhas válidas para o jogador
- `selectedPieceType: Patente?` - Tipo de peça selecionado para posicionar
- `onPositionTap: Function(PosicaoTabuleiro)` - Callback para tap em posição
- `onPieceDrag: Function(String, PosicaoTabuleiro)` - Callback para drag de peça

**Visual States:**

- **Valid Drop Zone:** Verde claro quando peça selecionada
- **Invalid Area:** Vermelho claro para área do oponente
- **Occupied Position:** Peça existente com borda destacada
- **Empty Position:** Grid normal com hover effect

### 4. PlacementStatusWidget

**Responsabilidade:** Mostra status do posicionamento e do oponente

**Props:**

- `localPiecesRemaining: int` - Peças restantes para posicionar
- `opponentStatus: PlacementStatus` - Status do oponente
- `canConfirm: bool` - Se pode confirmar (todas peças posicionadas)

**Layout:**

```
┌─────────────────────────────────────┐
│ Status do Posicionamento            │
├─────────────────────────────────────┤
│ Suas peças: 5 restantes             │
│ Oponente: Posicionando peças...     │
│                                     │
│ [PRONTO] (desabilitado se restantes)│
└─────────────────────────────────────┘
```

## Data Models

### PlacementGameState

```dart
class PlacementGameState {
  final String gameId;
  final String playerId;
  final Map<Patente, int> availablePieces;
  final List<PecaJogo> placedPieces;
  final List<int> playerArea; // [0,1,2,3] ou [6,7,8,9]
  final PlacementStatus localStatus;
  final PlacementStatus opponentStatus;
  final Patente? selectedPieceType;
}

enum PlacementStatus {
  PLACING,     // Posicionando peças
  READY,       // Confirmou posicionamento
  WAITING      // Aguardando oponente
}
```

### PlacementMessage (WebSocket)

```typescript
interface PlacementMessage {
  type:
    | "PLACEMENT_UPDATE"
    | "PLACEMENT_READY"
    | "PLACEMENT_STATUS"
    | "GAME_START";
  gameId: string;
  playerId: string;
  data: {
    pieceId?: string;
    patente?: string;
    position?: PosicaoTabuleiro;
    status?: PlacementStatus;
    allPieces?: PecaJogo[];
  };
}
```

## Error Handling

### Client-Side Validation

1. **Invalid Position:** Peça fora da área do jogador
2. **Inventory Empty:** Tentativa de posicionar peça não disponível
3. **Incomplete Placement:** Tentativa de confirmar com peças restantes
4. **Network Error:** Falha na comunicação com servidor

### Server-Side Validation

1. **Position Validation:** Verifica se posição está na área correta do jogador
2. **Piece Count:** Valida que jogador tem exatamente 40 peças
3. **Duplicate Pieces:** Verifica composição correta do exército
4. **Game State:** Confirma que jogo está na fase de posicionamento

### Error Recovery

```dart
class PlacementErrorHandler {
  static void handlePlacementError(PlacementError error) {
    switch (error.type) {
      case PlacementErrorType.INVALID_POSITION:
        showSnackBar("Posição inválida! Use apenas sua área.");
        break;
      case PlacementErrorType.PIECE_NOT_AVAILABLE:
        showSnackBar("Peça não disponível no inventário.");
        break;
      case PlacementErrorType.NETWORK_ERROR:
        showRetryDialog("Erro de conexão. Tentar novamente?");
        break;
    }
  }
}
```

## Testing Strategy

### Unit Tests

1. **PlacementGameState:** Validação de estado e transições
2. **Piece Validation:** Verificação de posicionamento válido
3. **Inventory Management:** Adição/remoção de peças do inventário
4. **Message Serialization:** Conversão de mensagens WebSocket

### Integration Tests

1. **Client-Server Communication:** Fluxo completo de posicionamento
2. **Multi-Player Sync:** Sincronização entre dois jogadores
3. **Error Scenarios:** Desconexões e reconexões durante posicionamento
4. **Game Transition:** Transição do posicionamento para o jogo

### UI Tests

1. **Drag & Drop:** Interação de arrastar e soltar peças
2. **Inventory Selection:** Seleção e uso de peças do inventário
3. **Visual Feedback:** Indicadores visuais de estado e erros
4. **Responsive Layout:** Adaptação a diferentes tamanhos de tela

## Performance Considerations

### Client Optimization

- **Lazy Loading:** Carregar imagens de peças sob demanda
- **State Batching:** Agrupar atualizações de estado para reduzir rebuilds
- **Animation Throttling:** Limitar animações durante drag operations
- **Memory Management:** Limpar recursos quando sair da tela

### Server Optimization

- **Message Batching:** Agrupar múltiplas atualizações de posição
- **State Compression:** Comprimir estado do jogo para transmissão
- **Connection Pooling:** Reutilizar conexões WebSocket
- **Timeout Management:** Limpar jogos abandonados automaticamente

## Security Considerations

### Input Validation

- Validar todas as posições recebidas do cliente
- Verificar se jogador pode modificar apenas suas próprias peças
- Limitar taxa de mensagens para prevenir spam
- Validar integridade da composição do exército

### State Protection

- Servidor mantém estado autoritativo
- Cliente não pode modificar peças do oponente
- Validação dupla: cliente (UX) + servidor (segurança)
- Logs de auditoria para debugging
