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

*   **[EM ANDAMENTO]** Criação das cenas e scripts para a interface do jogo.
    *   **[CONCLUÍDO]** Criada a cena principal `main.tscn` e o script `main.gd`.
    *   **[CONCLUÍDO]** O projeto foi configurado para iniciar com a cena `main.tscn`.
    *   **[CONCLUÍDO]** Criada a cena do tabuleiro `board.tscn` e o script `board.gd`.
    *   **[CONCLUÍDO]** Criada a cena da peça `piece.tscn` e o script `piece.gd` para representar as peças individuais.
    *   **[CONCLUÍDO]** Criado um gerenciador de cenas (`SceneManager`) como um script autoload para lidar com as transições de tela.
    *   **[CONCLUÍDO]** Criada a tela de inserção de nome de usuário (`name_input_screen.tscn`) como a primeira tela do jogo.
    *   **[CONCLUÍDO]** Criada a tela de matchmaking (`matchmaking_screen.tscn`) com uma animação de espera.
