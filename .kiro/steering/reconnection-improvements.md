# Sistema de Reconexão Inteligente

Este documento descreve as melhorias implementadas para resolver problemas de conexão durante partidas online, especialmente quando a conexão cai no meio do jogo.

## Problemas Identificados

### 1. Perda de Estado Durante Desconexões
- Jogadores perdiam todo o progresso da partida quando a conexão caía
- Necessidade de reparear jogadores e começar nova partida
- Frustração dos usuários com perda de tempo investido

### 2. Reconexão Inadequada
- Sistema de reconexão básico não diferenciava entre fases do jogo
- Sem persistência de estado para recuperação
- Timeouts inadequados para diferentes situações

## Soluções Implementadas

### 1. Sistema de Persistência de Estado (`GamePersistence`)

**Funcionalidades**:
- Salva automaticamente o estado do jogo a cada atualização
- Armazena informações de conexão (servidor, nome do jogador)
- Expiração automática após 2 horas
- Cache em memória para performance

**Arquivos**:
- `lib/src/common/services/game_persistence.dart`
- Salva em `active_game_state.json` no diretório local

### 2. Reconexão Inteligente Durante Jogo Ativo

**Funcionalidades**:
- Detecta automaticamente desconexões durante partidas
- Tenta reconectar preservando o estado do jogo
- Solicita estado atualizado do servidor após reconexão
- Fallback para reconexão manual se automática falhar

**Métodos Principais**:
- `reconnectDuringActiveGame()` - Reconexão específica para jogos ativos
- `requestGameStateRecovery()` - Solicita estado do servidor
- `attemptManualReconnection()` - Reconexão manual pelo usuário

### 3. Interface de Reconexão (`GameReconnectionDialog`)

**Funcionalidades**:
- Dialogs específicos para diferentes situações
- Animações de feedback durante reconexão
- Opções claras: "Reconectar" vs "Voltar ao Menu"
- Indicadores de progresso durante tentativas

**Tipos de Dialog**:
- Reconexão durante jogo ativo
- Falha na reconexão
- Progresso de reconexão (com animação)

### 4. Monitoramento de Qualidade de Conexão (`ConnectionMonitor`)

**Funcionalidades**:
- Monitora latência e estabilidade da conexão
- Detecta conexões instáveis
- Ajusta timeouts baseado na qualidade
- Estatísticas de conexão para debug

**Métricas**:
- Latência média
- Taxa de sucesso
- Estabilidade da conexão
- Histórico de qualidade

### 5. Melhorias no GameStateProvider

**Funcionalidades**:
- Persistência automática do estado
- Detecção de perda de conexão
- Tentativas automáticas de reconexão
- Recuperação de jogos salvos na inicialização

**Novos Métodos**:
- `_saveGameStateForRecovery()` - Salva estado automaticamente
- `_attemptGameRecovery()` - Recupera jogos salvos
- `_handleConnectionLoss()` - Trata desconexões
- `attemptManualReconnection()` - Reconexão manual

### 6. Melhorias na Interface de Jogo

**Funcionalidades**:
- Botões de reconexão contextuais
- Feedback visual durante reconexão
- Limpeza automática de estado ao sair
- Dialogs informativos para o usuário

## Fluxo de Reconexão

### 1. Durante Jogo Ativo

```
Desconexão Detectada
        ↓
Salva Estado Atual
        ↓
Tentativa Automática (2s delay)
        ↓
Sucesso? → Continua Jogo
        ↓
Falha? → Dialog de Reconexão
        ↓
Usuário Escolhe:
├── Reconectar → Tentativa Manual
└── Menu → Limpa Estado
```

### 2. Na Inicialização

```
App Inicia
        ↓
Verifica Estado Salvo
        ↓
Estado Válido?
├── Sim → Tenta Recuperar
│        ├── Sucesso → Restaura Jogo
│        └── Falha → Conecta Normal
└── Não → Conecta Normal
```

## Configurações e Timeouts

### Timeouts Dinâmicos
- **Placement**: 5-15 minutos (baseado na estabilidade)
- **Jogo Ativo**: 1-2 minutos (baseado na estabilidade)
- **Reconexão**: 15-20 segundos

### Persistência
- **Duração**: 2 horas máximo
- **Limpeza**: Automática ao terminar jogo
- **Cache**: 1 minuto em memória

## Benefícios para o Usuário

### 1. Continuidade de Jogo
- Partidas não são perdidas por problemas de rede
- Reconexão automática transparente
- Estado preservado durante desconexões breves

### 2. Feedback Claro
- Indicadores visuais de status de conexão
- Opções claras durante problemas
- Progresso de reconexão visível

### 3. Robustez
- Múltiplas estratégias de recuperação
- Timeouts adaptativos
- Fallbacks para situações extremas

## Monitoramento e Debug

### Logs Importantes
- `🔄 Tentando recuperar jogo salvo há X minutos`
- `✅ Reconexão bem-sucedida, restaurando estado`
- `❌ Falha na recuperação, limpando estado salvo`
- `🚨 Perda de conexão detectada durante jogo ativo`

### Métricas de Conexão
- Latência média
- Taxa de sucesso de reconexão
- Frequência de desconexões
- Tempo de recuperação

## Testes Recomendados

### 1. Cenários de Desconexão
- [ ] Desconexão durante posicionamento
- [ ] Desconexão durante jogo ativo
- [ ] Desconexão durante combate
- [ ] Múltiplas desconexões rápidas

### 2. Recuperação de Estado
- [ ] Recuperação após 1 minuto
- [ ] Recuperação após 30 minutos
- [ ] Estado expirado (>2 horas)
- [ ] Múltiplas instâncias do app

### 3. Interface de Usuário
- [ ] Dialogs de reconexão
- [ ] Animações de progresso
- [ ] Botões de ação funcionais
- [ ] Feedback visual adequado

Este sistema robusto de reconexão deve resolver significativamente os problemas de conectividade relatados, proporcionando uma experiência muito mais estável para jogadores online.