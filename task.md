# Task: Resolver Problema de Transferência de Peças do Placement para o Jogo Principal

## 🎯 **PROBLEMA PRINCIPAL**

O jogo **Combatentes** (Flutter + Dart) tem um sistema de posicionamento de peças que funciona corretamente, mas quando o jogo inicia após o countdown, **o tabuleiro aparece vazio** sem as peças posicionadas pelos jogadores.

## 📋 **CONTEXTO DO PROJETO**

### Arquitetura do Jogo

- **Frontend**: Flutter com Riverpod para gerenciamento de estado
- **Jogo**: Estratégia militar similar ao Stratego (10x10, 40 peças por jogador)
- **Fluxo**: Posicionamento → Countdown → Jogo Principal

### Estrutura de Arquivos Relevantes

```
lib/
├── ui/
│   ├── game_flow_screen.dart      # Gerencia transição placement → jogo
│   ├── piece_placement_screen.dart # Tela de posicionamento
│   └── tela_jogo.dart             # Tela principal do jogo
├── placement_controller.dart       # Controla lógica de posicionamento
├── providers.dart                 # Estado global (Riverpod)
└── modelos_jogo.dart              # Modelos de dados
```

## 🔍 **ANÁLISE DO PROBLEMA**

### O que FUNCIONA ✅

1. **Posicionamento**: Jogador posiciona 40 peças corretamente
2. **Salvamento**: Peças são salvas no SharedPreferences
3. **Transferência**: Logs mostram "40 peças transferidas"
4. **Estado**: `EstadoJogo` é criado com as peças

### O que NÃO FUNCIONA ❌

1. **Countdown**: Não inicia quando ambos jogadores clicam "PRONTO", foi colocado na tela um botão para Simular que o jogador adversário clicou em "PRONTO" para forçar o início do Countdown
1. **Visualização**: Tabuleiro aparece apenas com as peças do jogador da instância em execução, faltando aparecer as peças do adversário
1. **Jogabilidade**: Não é possível jogar (sem peças visíveis)
1. **Peças do Oponente**: Faltam as 40 peças do oponente (deveria ter 80 total)

## 🔧 **LOGS DE DEBUG ATUAIS**

```
💾 Salvando 40 peças para transferência
💾 Peças salvas no armazenamento para transferência
🔍 Usando peças do armazenamento: 40
🎮 Peças transferidas para o jogo: 40 peças
🎮 Estado do jogo criado com ID: [game-id]
```

## 🎯 **TAREFAS ESPECÍFICAS**

### 1. **Investigar Transferência de Peças**

- Verificar se `ref.read(gameStateProvider.notifier).updateGameState(gameState)` está funcionando
- Confirmar se o `TelaJogo` está recebendo o estado atualizado
- Verificar se há problemas na renderização das peças no tabuleiro

### 2. **Implementar Peças do Oponente**

- A função `_createOpponentPieces()` existe mas não está sendo chamada
- Verificar logs: deveria aparecer `🤖 Criadas 40 peças para o oponente`
- Garantir que o jogo inicie com 80 peças (40 + 40)

### 3. **Verificar Renderização do Tabuleiro**

- Confirmar se `AnimatedBoardWidget` está recebendo as peças
- Verificar se há problemas de coordenadas ou equipes
- Testar se peças aparecem nas posições corretas

## 📁 **ARQUIVOS PARA INVESTIGAR**

### `lib/ui/game_flow_screen.dart`

```dart
// Linha ~175: Função _createOpponentPieces não está sendo chamada
🤖 Criando peças do oponente para equipe: ${opponentTeam.name}  // ← Este log não aparece
final opponentPieces = _createOpponentPieces(opponentTeam);

// Linha ~188: updateGameState deveria transferir peças
ref.read(gameStateProvider.notifier).updateGameState(gameState);
```

### `lib/providers.dart`

```dart
// Verificar se updateGameState está funcionando corretamente
void updateGameState(EstadoJogo novoEstado) {
  state = state.copyWith(
    estadoJogo: novoEstado,  // ← As peças estão aqui?
    conectando: false,
    statusConexao: StatusConexao.jogando,
  );
}
```

### `lib/ui/tela_jogo.dart`

```dart
// Verificar se está recebendo as peças do estado
final uiState = ref.watch(gameStateProvider);
final estadoJogo = uiState.estadoJogo;  // ← Tem as 80 peças?
```

## 🔍 **DEBUGGING SUGERIDO**

### 1. Adicionar Logs Detalhados

```dart
// Em game_flow_screen.dart
debugPrint('🔍 Estado antes: ${currentGameState.estadoJogo?.pecas.length ?? 0} peças');
debugPrint('🔍 Peças do jogador: ${placedPieces?.length ?? 0}');
debugPrint('🔍 Peças do oponente: ${opponentPieces.length}');
debugPrint('🔍 Total no estado final: ${gameState.pecas.length}');

// Em providers.dart
debugPrint('🎮 updateGameState chamado com ${novoEstado.pecas.length} peças');

// Em tela_jogo.dart
debugPrint('🎯 TelaJogo recebeu ${estadoJogo?.pecas.length ?? 0} peças');
```

### 2. Verificar Coordenadas das Peças

```dart
// Verificar se as posições estão corretas
for (final peca in estadoJogo.pecas) {
  debugPrint('Peça ${peca.patente.nome} em (${peca.posicao.linha}, ${peca.posicao.coluna})');
}
```

## 🎯 **RESULTADO ESPERADO**

### Logs de Sucesso

```
🤖 Criando peças do oponente para equipe: verde
🤖 Criadas 40 peças para o oponente (verde)
🎮 Estado do jogo criado com 80 peças total
🎯 TelaJogo recebeu 80 peças
```

### Comportamento Visual

1. **Tabuleiro com peças**: 40 peças do jogador visíveis nas linhas 6-9 (ou 0-3)
2. **Peças do oponente**: 40 peças do oponente como silhuetas nas linhas opostas
3. **Jogabilidade**: Possível clicar e mover peças do jogador
4. **Total**: 80 peças no tabuleiro (40 + 40)

## 🚨 **PONTOS CRÍTICOS**

1. **Não quebrar o fluxo atual**: O countdown e transferência básica funcionam
2. **Manter compatibilidade**: Não alterar a estrutura de dados existente
3. **Performance**: Evitar recriações desnecessárias do estado
4. **Logs**: Manter logs de debug para rastreamento

## 📝 **CRITÉRIOS DE SUCESSO**

- [ ] Tabuleiro mostra 40 peças do jogador nas posições corretas
- [ ] Tabuleiro mostra 40 peças do oponente (silhuetas)
- [ ] Total de 80 peças no estado do jogo
- [ ] Possível clicar e interagir com peças do jogador
- [ ] Logs confirmam transferência completa

## 🔧 **FERRAMENTAS DISPONÍVEIS**

- **Flutter DevTools**: Para inspecionar estado do Riverpod
- **Debug Logs**: Sistema de logs já implementado
- **Hot Reload**: Para testes rápidos
- **Simulação**: Botão para simular segundo jogador

---

**IMPORTANTE**: O problema está na transferência/renderização das peças, NÃO no sistema de posicionamento que já funciona perfeitamente.
