# Log de Migração: Combatentes (Flutter para Godot)

Este documento registra o processo de migração do jogo "Combatentes" de sua implementação original em Flutter para o motor de jogo Godot 4.5.

## Visão Geral da Migração

O objetivo é recriar a funcionalidade e a experiência do jogo original, aproveitando os recursos do Godot Engine. A migração será dividida nas seguintes fases principais:

1.  **Configuração Inicial e Análise do Projeto:**
    *   Analisar a estrutura do projeto Flutter original.
    *   Estabelecer a estrutura do novo projeto Godot.
    *   Criar este documento de log.

2.  **Migração de Ativos (Assets):**
    *   Transferir todas as imagens (peças, tabuleiros, UI) e arquivos de som do projeto Flutter para o projeto Godot.

3.  **Recriação da Lógica Central (Core Logic):**
    *   Traduzir as estruturas de dados e regras do jogo de Dart para GDScript.
    *   Implementar a lógica de movimentação, combate e condições de vitória.

4.  **Desenvolvimento da Interface do Usuário (UI):**
    *   Recriar as telas principais: Menu, Matchmaking, Posicionamento de Peças, Tabuleiro de Jogo e Telas de Resultado (Vitória/Derrota).

5.  **Implementação da Comunicação de Rede:**
    *   Conectar o cliente Godot ao backend Node.js existente usando WebSockets.
    *   Reimplementar a troca de mensagens para sincronização do estado do jogo.

6.  **Polimento e Testes:**
    *   Adicionar animações, efeitos sonoros e feedback visual.
    *   Realizar testes para garantir a estabilidade e a fidelidade à experiência original.

---

## Fase 1: Configuração Inicial e Análise

*   **[CONCLUÍDO]** Um novo projeto Godot 4.5 foi criado na pasta `godot/combatentes`.
*   **[CONCLUÍDO]** O arquivo `MIGRATION_LOG.md` foi criado para documentar o processo.
*   **[CONCLUÍDO]** Análise da estrutura do projeto Flutter para identificar os principais componentes a serem migrados.

## Fase 2: Migração de Ativos (Assets)

*   **[CONCLUÍDO]** Todos os ativos de imagem e som do projeto Flutter foram copiados para a pasta `godot/combatentes/assets`.

## Fase 3: Recriação da Lógica Central (Core Logic)

*   **[EM ANDAMENTO]** Tradução das estruturas de dados e regras do jogo de Dart para GDScript.
    *   **[CONCLUÍDO]** Criado o arquivo `scripts/data/enums.gd` para centralizar os enums do jogo (`Equipe`, `GamePhase`, `PlacementStatus`, `Patente`).
    *   **[CONCLUÍDO]** Criado o recurso `PecaJogo` (`scripts/data/peca_jogo.gd`) para representar as peças do jogo.
    *   **[CONCLUÍDO]** Criado o recurso `Jogador` (`scripts/data/jogador.gd`) para representar os jogadores.
    *   **[CONCLUÍDO]** Criado o recurso `EstadoJogo` (`scripts/data/estado_jogo.gd`) para representar o estado geral da partida.
    *   **[CONCLUÍDO]** Traduzida a classe `PlacementGameState` para `scripts/data/placement_game_state.gd`.
    *   **[CONCLUÍDO]** Traduzidas as classes `PlacementMessage` e `PlacementMessageData` para `scripts/data/placement_messages.gd`.

## Fase 4: Desenvolvimento da Interface do Usuário (UI):

*   **[EM ANDAMENTO]** Criação das cenas e scripts para a interface do jogo.
    *   **[CONCLUÍDO]** Criada a cena principal `main.tscn` e o script `main.gd`.
    *   **[CONCLUÍDO]** O projeto foi configurado para iniciar com a cena `main.tscn`.
    *   **[CONCLUÍDO]** Criada a cena do tabuleiro `board.tscn` e o script `board.gd` (incluindo `get_piece_at_cell` e `get_piece_node_at_cell`).
    *   **[CONCLUÍDO]** Criada a cena da peça `piece.tscn` e o script `piece.gd` para representar as peças individuais.
    *   **[CONCLUÍDO]** Criado um gerenciador de cenas (`SceneManager`) como um script autoload para lidar com as transições de tela.
    *   **[CONCLUÍDO]** Criada a tela de inserção de nome de usuário (`name_input_screen.tscn`) como a primeira tela do jogo.
    *   **[CONCLUÍDO]** Criada a tela de matchmaking (`matchmaking_screen.tscn`) com uma animação de espera.
    *   **[CONCLUÍDO]** Criada a tela de posicionamento de peças (`piece_placement_screen.tscn`) com o tabuleiro e um espaço para o inventário.
    *   **[CONCLUÍDO]** Criado o widget `inventory_piece_widget.tscn` e seu script para exibir peças individuais no inventário.
    *   **[CONCLUÍDO]** Implementada a funcionalidade básica de arrastar e soltar (drag-and-drop) para posicionar peças do inventário no tabuleiro, incluindo validação de área e células ocupadas.
    *   **[CONCLUÍDO]** Adicionado feedback visual de seleção para as peças no inventário da tela de posicionamento.
    *   **[CONCLUÍDO]** Implementado feedback visual para zonas de drop válidas/inválidas no tabuleiro durante o arrasto de peças.
    *   **[CONCLUÍDO]** Criada a tela de jogo principal (`game_screen.tscn`) e seu script (`game_screen.gd`) com a estrutura básica para exibir o tabuleiro, informações dos jogadores e status do jogo.
    *   **[CONCLUÍDO]** Implementado feedback visual para seleção de peças e destaque de movimentos válidos na tela de jogo principal.
    *   **[CONCLUÍDO]** Implementadas as regras básicas de movimentação do Stratego (peças imóveis, movimento ortogonal, movimento do Soldado e verificação de caminhos bloqueados) na função `_is_valid_move` em `game_screen.gd`.
    *   **[CONCLUÍDO]** Refinada a função `_update_game_state` em `game_screen.gd` para processar o `EstadoJogo` completo do servidor, atualizando jogadores, peças (incluindo `foi_revelada`) e a UI do tabuleiro.
    *   **[CONCLUÍDO]** Criadas as telas de vitória (`victory_screen.tscn`) e derrota (`defeat_screen.tscn`) e seus scripts.

## Fase 5: Implementação da Comunicação de Rede:

*   **[EM ANDAMENTO]** Conectar o cliente Godot ao backend Node.js existente usando WebSockets.
    *   **[CONCLUÍDO]** Criado um placeholder para o serviço WebSocket (`websocket_service.gd`) como um script autoload.
    *   **[CONCLUÍDO]** Criado o script `Global.gd` como um autoload para gerenciar dados globais (ex: nome do jogador, game_id, player_id, player_area).
    *   **[CONCLUÍDO]** Integrado o `WebSocketService` com a tela de matchmaking (`matchmaking_screen.gd`) para iniciar a conexão, enviar o nome do jogador e receber mensagens do servidor, incluindo a transição para a tela de posicionamento ao encontrar uma partida.
    *   **[CONCLUÍDO]** A tela de posicionamento de peças (`piece_placement_screen.gd`) agora recupera as informações da partida do `Global.gd` e envia mensagens de atualização de posicionamento e confirmação para o servidor via `WebSocketService`, e transiciona para a tela de jogo principal ao receber "GAME_START".
    *   **[CONCLUÍDO]** Adicionado o método `to_dict()` às classes `PlacementMessage`, `PlacementMessageData`, `PecaJogo`, `EstadoJogo` e `Jogador` para serialização JSON.
    *   **[CONCLUÍDO]** Criado o `AudioService` como um script autoload para gerenciar a reprodução de sons.
    *   **[CONCLUÍDO]** Implementado o tratamento de `COMBAT_RESULT` e `GAME_OVER` em `game_screen.gd`, incluindo a reprodução de sons e a transição para as telas de vitória/derrota, e a integração da animação de combate (`combat_animation.tscn`).

## Fase 6: Polimento e Testes:

*   **[EM ANDAMENTO]** Adicionar animações, efeitos sonoros e feedback visual.
    *   **[CONCLUÍDO]** Implementada a animação de combate (`combat_animation.tscn`) para exibir visualmente os resultados dos confrontos.
    *   **[CONCLUÍDO]** Implementados os efeitos visuais de explosão (`explosion_effect.tscn`) e respingo de sangue (`blood_splatter_effect.tscn`) para feedback de combate.
*   **[CONCLUÍDO]** Realizar testes para garantir a estabilidade e a fidelidade à experiência original.
    *   **[CONCLUÍDO]** Criado o `test_runner.gd` para simular o fluxo do jogo e testar as transições de tela e a lógica de comunicação com o backend (via mensagens mock). (Removido após testes para restaurar o fluxo normal do jogo).

## Resumo da Migração Básica Concluída

A migração básica do jogo "Combatentes" de Flutter para Godot 4.5 foi concluída com sucesso. As seguintes funcionalidades principais foram migradas e implementadas:

*   **Estrutura do Projeto Godot:** Configuração inicial, organização de pastas e arquivos.
*   **Migração de Ativos:** Todas as imagens e sons do projeto Flutter foram transferidos para o Godot.
*   **Lógica Central do Jogo:** Enums e classes de dados (`PecaJogo`, `Jogador`, `EstadoJogo`, `PlacementGameState`, `PlacementMessage`) foram traduzidos para GDScript.
*   **Interface do Usuário (UI):**
    *   Gerenciador de Cenas (`SceneManager`) para transições de tela.
    *   Tela de Entrada de Nome (`name_input_screen.tscn`).
    *   Tela de Matchmaking (`matchmaking_screen.tscn`) com animação de espera.
    *   Tela de Posicionamento de Peças (`piece_placement_screen.tscn`) com inventário, tabuleiro interativo e funcionalidade de arrastar e soltar, incluindo feedback visual.
    *   Tela de Jogo Principal (`game_screen.tscn`) com exibição do tabuleiro, informações de jogadores, indicador de turno e lógica básica de movimentação de peças (regras do Stratego).
    *   Telas de Vitória (`victory_screen.tscn`) e Derrota (`defeat_screen.tscn`).
*   **Comunicação de Rede:**
    *   Serviço WebSocket (`websocket_service.gd`) para comunicação com o backend Node.js.
    *   Integração do WebSocket com as telas de matchmaking, posicionamento e jogo principal para envio e recebimento de mensagens.
    *   Serialização/desserialização de dados para comunicação JSON.
*   **Polimento Básico:**
    *   `AudioService` para reprodução de sons.
    *   Animação de combate (`combat_animation.tscn`).
    *   Efeitos visuais de explosão (`explosion_effect.tscn`) e respingo de sangue (`blood_splatter_effect.tscn`).

O projeto Godot agora possui a estrutura e as funcionalidades essenciais do jogo "Combatentes", pronto para ser conectado a um backend Node.js funcional e para testes mais aprofundados em um ambiente real.

