# Implementation Plan - Combatentes Godot Rebuild

## Fase 1: Configuração Inicial do Projeto

- [ ] 1.1 Criar novo projeto Godot 4
  - Abrir Godot Engine
  - Criar novo projeto chamado "combatentes-novo"
  - Configurar resolução base (1024x768 ou similar)
  - _Requirements: 1.1, 6.1_

- [ ] 1.2 Configurar estrutura de pastas
  - Criar pasta `scenes/` na raiz
  - Criar pasta `scenes/ui/`
  - Criar pasta `scenes/game/`
  - Criar pasta `scripts/`
  - Criar pasta `scripts/autoloads/`
  - Criar pasta `scripts/ui/`
  - Criar pasta `assets/`
  - _Requirements: 6.1_

- [ ] 1.3 Criar AutoLoads básicos
  - Criar `scripts/autoloads/global.gd` com variáveis básicas
  - Criar `scripts/autoloads/scene_manager.gd` com função change_scene
  - Configurar AutoLoads no Project Settings
  - _Requirements: 6.1, 6.2, 6.3_

## Fase 2: Cena Principal e Navegação

- [ ] 2.1 Criar cena principal
  - Criar `scenes/main.tscn` com Node2D root
  - Adicionar script `scripts/main.gd`
  - Configurar como Main Scene no projeto
  - _Requirements: 1.1_

- [ ] 2.2 Implementar sistema de debug
  - Adicionar controles de teclado no main.gd (_input)
  - Implementar teclas F1, 1, 2, 3, D, R
  - Adicionar logs de debug detalhados
  - _Requirements: 7.1, 7.3, 7.5_

- [ ] 2.3 Testar navegação básica
  - Criar cena de teste simples
  - Testar SceneManager.change_scene()
  - Verificar se logs aparecem no console
  - _Requirements: 1.2, 1.3_

## Fase 3: Tela de Entrada de Nome

- [ ] 3.1 Criar interface da tela de nome
  - Criar `scenes/ui/name_screen.tscn` com Control root
  - Adicionar VBoxContainer centralizado
  - Adicionar Label com título "COMBATENTES"
  - Adicionar Label com instrução "Digite seu nome:"
  - Adicionar LineEdit para entrada
  - Adicionar Button "Começar Jogo"
  - _Requirements: 2.1_

- [ ] 3.2 Implementar script da tela de nome
  - Criar `scripts/ui/name_screen.gd`
  - Implementar _ready() para encontrar nós
  - Implementar _on_button_pressed()
  - Adicionar validação de nome não vazio
  - Salvar nome no Global.player_name
  - _Requirements: 2.2, 2.3, 2.4_

- [ ] 3.3 Conectar navegação
  - Modificar main.gd para carregar name_screen
  - Implementar navegação para próxima tela após confirmação
  - Testar fluxo completo de entrada de nome
  - _Requirements: 2.5, 1.2_

## Fase 4: Sistema WebSocket Básico

- [ ] 4.1 Implementar WebSocket Service
  - Criar `scripts/autoloads/websocket_service.gd`
  - Implementar variáveis básicas (websocket, url, is_connected)
  - Implementar sinais (connected, disconnected, message_received)
  - Adicionar ao AutoLoad
  - _Requirements: 5.1_

- [ ] 4.2 Implementar conexão básica
  - Implementar connect_to_server() com URL principal
  - Implementar _process() para polling
  - Implementar detecção de mudanças de estado
  - Adicionar logs detalhados de conexão
  - _Requirements: 5.1, 5.5_

- [ ] 4.3 Implementar fallback e reconexão
  - Adicionar URL alternativa (ws:// se wss:// falhar)
  - Implementar tentativas automáticas de reconexão
  - Implementar timeout de conexão
  - _Requirements: 5.2, 5.4_

## Fase 5: Tela de Matchmaking

- [ ] 5.1 Criar interface de matchmaking
  - Criar `scenes/ui/matchmaking_screen.tscn`
  - Adicionar Label para status de conexão
  - Adicionar Button "Cancelar" (opcional)
  - Adicionar AnimationPlayer para loading (opcional)
  - _Requirements: 3.1_

- [ ] 5.2 Implementar script de matchmaking
  - Criar `scripts/ui/matchmaking_screen.gd`
  - Implementar _ready() para iniciar conexão
  - Conectar sinais do WebSocketService
  - Implementar handlers para connected/disconnected/message_received
  - _Requirements: 3.2, 3.3_

- [ ] 5.3 Implementar lógica de pareamento
  - Enviar nome do jogador quando conectado
  - Processar mensagens do servidor
  - Detectar quando oponente é encontrado
  - Navegar para tela de posicionamento
  - _Requirements: 3.4, 3.5_

## Fase 6: Enums e Estruturas de Dados

- [ ] 6.1 Criar arquivo de enums
  - Criar `scripts/enums.gd` com enums básicos
  - Definir enum Equipe (VERDE, PRETA)
  - Definir enum Patente (todas as patentes militares)
  - _Requirements: 4.1_

- [ ] 6.2 Criar classe de dados da peça
  - Criar `scripts/piece_data.gd` como Resource
  - Definir propriedades: id, patente, equipe, position
  - Implementar construtor básico
  - _Requirements: 4.1_

## Fase 7: Tabuleiro Básico

- [ ] 7.1 Criar cena do tabuleiro
  - Criar `scenes/game/board.tscn` com Node2D root
  - Adicionar background visual (opcional)
  - Configurar tamanho 10x10 células
  - _Requirements: 4.1_

- [ ] 7.2 Implementar script do tabuleiro
  - Criar `scripts/game/board.gd`
  - Definir constantes de tamanho (BOARD_SIZE, CELL_SIZE)
  - Implementar _draw() para desenhar grid
  - Implementar get_cell_at_position()
  - Implementar is_valid_position()
  - _Requirements: 4.1_

## Fase 8: Tela de Posicionamento

- [ ] 8.1 Criar interface de posicionamento
  - Criar `scenes/ui/placement_screen.tscn`
  - Adicionar HBoxContainer principal
  - Adicionar área do inventário (lado esquerdo)
  - Adicionar área do tabuleiro (lado direito)
  - Adicionar botão "Confirmar Posicionamento"
  - Adicionar Label de status
  - _Requirements: 4.1_

- [ ] 8.2 Implementar inventário de peças
  - Criar lista de peças disponíveis
  - Implementar seleção de peças
  - Adicionar feedback visual de seleção
  - _Requirements: 4.2_

- [ ] 8.3 Implementar posicionamento no tabuleiro
  - Implementar clique no tabuleiro
  - Validar área de posicionamento do jogador
  - Posicionar peça selecionada
  - Atualizar inventário após posicionamento
  - _Requirements: 4.3, 4.4_

- [ ] 8.4 Implementar confirmação
  - Verificar se todas as peças foram posicionadas
  - Habilitar botão de confirmação
  - Enviar dados para servidor (se conectado)
  - _Requirements: 4.5_

## Fase 9: Testes e Polimento

- [ ] 9.1 Implementar modo offline para testes
  - Adicionar simulação de oponente encontrado
  - Permitir teste de posicionamento sem servidor
  - Adicionar dados de teste automáticos
  - _Requirements: 7.4_

- [ ] 9.2 Melhorar feedback visual
  - Adicionar cores para validação de posicionamento
  - Implementar hover effects
  - Adicionar animações básicas (opcional)
  - _Requirements: 7.2_

- [ ] 9.3 Testes finais
  - Testar fluxo completo: nome → matchmaking → posicionamento
  - Testar todos os controles de debug
  - Verificar logs em todas as operações
  - Testar tratamento de erros
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5_

## Notas de Implementação

### Ordem de Prioridade
1. **Crítico:** Fases 1-3 (estrutura básica e navegação)
2. **Alto:** Fases 4-5 (WebSocket e matchmaking)  
3. **Médio:** Fases 6-8 (dados e posicionamento)
4. **Baixo:** Fase 9 (polimento)

### Pontos de Verificação
- Após cada fase, testar funcionalidade básica
- Usar controles de debug para navegação rápida
- Verificar logs no console do Godot
- Testar em modo offline quando possível

### Estratégia de Debug
- Implementar logs detalhados desde o início
- Usar print() liberalmente para rastreamento
- Implementar controles de teclado para testes rápidos
- Criar dados de teste para cada funcionalidade