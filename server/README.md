# Combatentes Server

Servidor WebSocket para o jogo multiplayer Combatentes, refatorado em uma arquitetura modular.

## Estrutura do Projeto

```
server/
├── src/
│   ├── types/
│   │   └── game.types.ts          # Definições de tipos e interfaces
│   ├── game/
│   │   ├── GameController.ts      # Lógica principal do jogo
│   │   └── GameStateManager.ts    # Gerenciamento de estado inicial
│   ├── websocket/
│   │   ├── GameSessionManager.ts  # Gerenciamento de sessões e conexões
│   │   └── WebSocketMessageHandler.ts # Processamento de mensagens
│   └── server.ts                  # Ponto de entrada da aplicação
├── dist/                          # Arquivos compilados (gerados)
├── package.json
├── tsconfig.json
└── README.md
```

## Arquitetura

### Separação de Responsabilidades

1. **Types (`types/game.types.ts`)**

   - Definições de tipos TypeScript
   - Enums e interfaces compartilhadas
   - Constantes do jogo (Patentes, etc.)

2. **Game Logic (`game/`)**

   - `GameController.ts`: Regras do jogo, validação de movimentos, combate
   - `GameStateManager.ts`: Criação e inicialização do estado do jogo

3. **WebSocket Management (`websocket/`)**

   - `GameSessionManager.ts`: Matchmaking, gerenciamento de sessões
   - `WebSocketMessageHandler.ts`: Processamento de mensagens dos clientes

4. **Server (`server.ts`)**
   - Configuração do servidor Express e WebSocket
   - Ponto de entrada da aplicação

### Benefícios da Refatoração

- **Modularidade**: Cada classe tem uma responsabilidade específica
- **Testabilidade**: Componentes isolados são mais fáceis de testar
- **Manutenibilidade**: Código organizado e fácil de navegar
- **Escalabilidade**: Estrutura preparada para crescimento futuro
- **Type Safety**: TypeScript com configuração rigorosa

## Comandos

```bash
# Desenvolvimento (com hot reload)
pnpm run dev

# Build para produção
pnpm run build

# Executar versão compilada
pnpm run start
```

## Fluxo de Dados

1. Cliente conecta → `GameSessionManager.handleNewConnection()`
2. Matchmaking → `GameSessionManager.createNewGame()`
3. Estado inicial → `GameStateManager.createInitialGameState()`
4. Mensagem do cliente → `WebSocketMessageHandler.handleMessage()`
5. Processamento → `GameController.moverPeca()`
6. Broadcast → `GameSessionManager.broadcastGameState()`

## Próximos Passos

- [ ] Adicionar testes unitários
- [ ] Implementar logging estruturado
- [ ] Adicionar métricas e monitoramento
- [ ] Implementar reconexão automática
- [ ] Adicionar persistência de estado (Redis/Database)
