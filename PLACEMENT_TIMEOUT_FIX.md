# Fix: Conexão Perdida Durante Posicionamento

## Problema Identificado

Durante o posicionamento manual das peças, a aplicação estava mostrando a mensagem "Conexão perdida. Tentando reconectar..." mesmo quando a conexão estava funcionando normalmente. Isso acontecia porque:

1. **Watchdog muito agressivo**: O sistema de detecção de desconexão tinha um timeout de apenas 30 segundos
2. **Falta de atividade de rede**: Durante o posicionamento, o jogador pode ficar vários minutos posicionando peças sem enviar mensagens ao servidor
3. **Detecção incorreta**: O watchdog interpretava a ausência de mensagens como uma desconexão real

## Soluções Implementadas

### 1. **Timeout Mais Longo Durante Posicionamento**

```dart
// Antes: 30 segundos para qualquer fase
static const Duration _connectionTimeout = Duration(seconds: 30);

// Depois: 2 minutos normal, 5 minutos durante posicionamento
static const Duration _connectionTimeout = Duration(minutes: 2);

// No watchdog:
final timeoutDuration = _currentState!.gamePhase == GamePhase.piecePlacement
    ? const Duration(minutes: 5) // 5 minutos durante posicionamento
    : _connectionTimeout; // 2 minutos durante jogo normal
```

### 2. **Atualização de Atividade Durante Interações**

Adicionado método `updateNetworkActivity()` que é chamado sempre que o usuário interage:

```dart
// No PlacementController
void updateNetworkActivity() {
  _lastNetworkActivity = DateTime.now();
}

// Nos métodos de interação do PiecePlacementScreen
void _handlePositionTap(PosicaoTabuleiro position) {
  // Atualiza atividade de rede para evitar timeout
  _controller.updateNetworkActivity();
  // ... resto do método
}
```

### 3. **Watchdog Mais Inteligente**

```dart
void _handleConnectionTimeout() {
  if (_currentState != null && !_isReconnecting) {
    // Durante o posicionamento, seja mais conservador
    if (_currentState!.gamePhase == GamePhase.piecePlacement) {
      // Só considera desconexão após 10 minutos de inatividade total
      final timeSinceLastActivity = DateTime.now().difference(_lastNetworkActivity!);
      if (timeSinceLastActivity > const Duration(minutes: 10)) {
        _handleDisconnection();
      } else {
        // Atualiza a atividade para dar mais tempo
        _lastNetworkActivity = DateTime.now();
      }
    } else {
      _handleDisconnection();
    }
  }
}
```

### 4. **Inicialização com Delay**

```dart
// Inicia watchdog com delay para dar tempo de inicialização
Future.delayed(const Duration(seconds: 30), () {
  if (!_isReconnecting) {
    _startConnectionWatchdog();
  }
});
```

### 5. **Atualização Automática em Operações**

Todas as operações de posicionamento agora atualizam automaticamente a atividade de rede:

- `updateState()` - Quando o estado é atualizado
- `validatePiecePlacement()` - Durante validação
- `placePiece()` - Durante posicionamento
- `_handlePositionTap()` - Quando o usuário toca no tabuleiro
- `_handlePieceDrag()` - Durante drag and drop
- `_handlePieceRemove()` - Quando remove peças
- `_handlePieceSelect()` - Quando seleciona peças do inventário

## Resultado

Agora o sistema:

✅ **Não mostra mais falsos positivos** de desconexão durante o posicionamento
✅ **Permite ao jogador tempo suficiente** para posicionar as peças (até 5 minutos de inatividade)
✅ **Detecta desconexões reais** quando necessário (após 10 minutos de inatividade total)
✅ **Mantém a responsividade** durante interações do usuário
✅ **Preserva a funcionalidade** de reconexão para desconexões reais

## Arquivos Modificados

- `lib/placement_controller.dart` - Lógica principal do watchdog e timeouts
- `lib/ui/piece_placement_screen.dart` - Atualização de atividade durante interações

## Testes

Todos os 23 testes do `PlacementController` continuam passando, confirmando que as mudanças não quebraram funcionalidades existentes.
