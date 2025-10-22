# Contexto do Projeto: Combatentes

Este documento fornece um resumo abrangente do jogo "Combatentes", sua arquitetura, fluxo de jogo e principais características técnicas para auxiliar no desenvolvimento e manutenção.

## 1. Visão Geral do Produto

**Combatentes** é um jogo de tabuleiro de estratégia multijogador, uma implementação digital do clássico "Stratego". Desenvolvido com Flutter (frontend) e Node.js (backend), o jogo coloca dois jogadores no comando de exércitos com patentes militares distintas.

### Conceito Principal
- Jogo de estratégia em turnos para dois jogadores em um tabuleiro 10x10.
- Cada jogador controla 40 peças com patentes que vão de Marechal a Soldado, além de peças especiais.
- O objetivo é capturar a bandeira inimiga (a peça "Prisioneiro") ou eliminar todas as peças móveis do oponente.
- A identidade das peças do oponente é oculta, exigindo estratégia, blefe e dedução.

### Composição do Exército (40 peças por jogador)
- **Oficiais de Alto Escalão:** Marechal (1), General (1), Coronel (2), Major (3)
- **Oficiais de Baixo Escalão:** Capitão (4), Tenente (4), Sargento (4)
- **Tropa:** Cabo (5), Soldado (8)
- **Peças Especiais:** Agente Secreto (1, derrota o Marechal), Mineiro (derrota Minas Terrestres), Mina Terrestre (6, imóvel), Prisioneiro (1, a bandeira).

## 2. Arquitetura Técnica

- **Frontend (Flutter):**
    - **Linguagem:** Dart
    - **Gerenciamento de Estado:** Riverpod
    - **Comunicação:** `web_socket_channel` para conexão WebSocket.
    - **Serialização:** `json_serializable`
    - **Áudio:** `audioplayers`

- **Backend (Node.js):**
    - **Linguagem:** TypeScript
    - **Framework:** Express com o pacote `ws` para WebSockets.
    - **Gerenciador de Pacotes:** pnpm

- **Comunicação:** A comunicação cliente-servidor é em tempo real, baseada na troca de mensagens JSON via WebSocket. O servidor é a autoridade final sobre o estado do jogo.

## 3. Fluxo do Jogo e Experiência do Usuário

O fluxo do jogo é dividido em fases distintas, cada uma com lógicas e timeouts específicos.

### Fase 1: Inicialização e Definição do Nome
1.  **Splash Screen:** Ao iniciar, o app verifica se há um nome de usuário salvo localmente.
2.  **Tela de Nome:** Se nenhum nome for encontrado, o usuário é direcionado para a `tela_nome_usuario.dart` para inserir seu nome.
3.  **Persistência:** O nome é salvo localmente para sessões futuras.

### Fase 2: Matchmaking e Conexão
1.  **Conexão:** O cliente tenta se conectar ao servidor WebSocket (`wss://combatentes.zionix.com.br`).
2.  **Sincronização de Nome:** Este é um passo crítico. O cliente envia o nome do usuário para o servidor. Um sistema robusto com múltiplas tentativas e verificação periódica (`_enviarNomeComRetry`, `_nameVerificationTimer`) garante que o servidor receba o nome e não inicie um pareamento com o placeholder "Aguardando nome...".
3.  **Tela de Matchmaking:** O usuário aguarda na `matchmaking_screen.dart` enquanto o servidor encontra um oponente. A tela monitora o progresso e pode forçar o reenvio do nome se o processo estagnar.
4.  **Pareamento:** O servidor pareia dois jogadores e inicia uma sessão de jogo.

### Fase 3: Posicionamento das Peças (`piece_placement_screen.dart`)
1.  **Início da Fase:** O servidor envia uma mensagem (`PLACEMENT_UPDATE`) que inicia a fase de posicionamento.
2.  **Timeout Estendido:** O sistema de timeout dinâmico entra em ação. O cliente ajusta o timeout de inatividade para **5 minutos (300 segundos)**, dando tempo suficiente para o jogador posicionar suas 40 peças estrategicamente no tabuleiro.
3.  **Interface:** O jogador arrasta suas peças do inventário (`piece_inventory_widget.dart`) para o tabuleiro (`placement_board_widget.dart`).
4.  **Confirmação:** Após posicionar todas as peças, o jogador confirma e o servidor é notificado.
5.  **Reconexão:** Se a conexão cair durante esta fase, uma lógica especial (`reconnectDuringPlacement`) tenta restaurar a sessão de posicionamento, preservando o progresso.

### Fase 4: Jogo Ativo (`tela_jogo.dart`)
1.  **Início do Jogo:** Quando ambos os jogadores estão prontos, o servidor envia `PLACEMENT_GAME_START`.
2.  **Timeout Padrão:** O timeout de inatividade é reduzido para **60 segundos** para manter o ritmo do jogo.
3.  **Turnos:** O servidor controla os turnos. A interface indica claramente de quem é a vez de jogar (com feedback visual e sonoro - `campainha.wav`).
4.  **Movimentação:** O jogador toca em uma peça e depois em uma casa válida. O movimento é enviado ao servidor para validação.
5.  **Animações:** Movimentos são acompanhados por animações suaves (`AnimatedBoardWidget`), com efeitos de rastro de poeira e rotação.

### Fase 5: Combate
1.  **Detecção:** O combate ocorre quando uma peça se move para uma casa ocupada por um oponente.
2.  **Resolução:** O servidor resolve o combate com base na hierarquia das patentes.
3.  **Feedback Visual e Sonoro:**
    - Um diálogo de combate mostra as peças envolvidas.
    - O som de tiro (`tiro.wav`) é tocado.
    - Se uma mina explode, um efeito visual (`ExplosionWidget`) e sonoro (`explosao.wav`) é ativado.
    - Se o jogador local perde uma peça, um efeito de "respingo de sangue" (`BloodSplatterWidget`) é exibido na tela, com intensidade variável de acordo com a patente da peça perdida.
4.  **Visibilidade:** As peças do oponente permanecem ocultas, exceto brevemente durante o diálogo de combate, para manter o elemento de blefe.

### Fase 6: Fim de Jogo (`victory_defeat_screens.dart`)
1.  **Condições de Vitória:**
    - Capturar a bandeira (peça "Prisioneiro") do inimigo.
    - Eliminar todas as peças móveis do oponente.
2.  **Telas de Resultado:** Telas personalizadas com ilustrações (`vitoria.png`, `derrota.png`) e sons (`comemoracao.mp3`, `derrota_fim.wav`) são exibidas.
3.  **Opções:** O jogador pode escolher "Jogar Novamente" ou voltar ao "Menu Principal".

## 4. Módulos e Lógicas Principais

- **`lib/game_socket_service.dart`:** O cérebro da comunicação. Gerencia a conexão WebSocket, a robusta sincronização de nomes, o sistema de timeout dinâmico, a detecção de desconexão e o monitoramento de saúde da conexão (heartbeat).

- **`lib/game_controller.dart`:** Um motor de regras de jogo em Dart puro. Valida movimentos e resolve combates, garantindo que as regras do jogo sejam cumpridas.

- **`lib/providers.dart`:** Utiliza o Riverpod para gerenciar o estado da UI (`TelaJogoState`) e do jogo (`GameStateNotifier`), integrando-se ao `GameSocketService` para atualizações em tempo real.

- **`lib/ui/`:** Contém todos os widgets da interface, com destaque para:
    - **`military_theme_widgets.dart`:** Uma biblioteca de componentes reutilizáveis que garante a consistência visual do tema militar.
    - **`animated_board_widget.dart`:** O sistema de animação avançado para o tabuleiro.
    - **`peca_widget.dart`:** Widget otimizado para as peças, com sistema de tooltip/long-press para exibir informações.

- **`server/src/`:** O código do backend, organizado em módulos:
    - **`game/`:** Contém a lógica central do jogo (`GameController.ts`).
    - **`websocket/`:** Gerencia as sessões de jogo e o tratamento de mensagens (`GameSessionManager.ts`).

## 5. Recursos Notáveis

- **Sistema de Timeout Dinâmico:** Adapta o tempo de tolerância à inatividade com base na fase do jogo (5 min para posicionamento, 1 min para jogo ativo), evitando desconexões falsas.

- **Gerenciamento de Conexão Robusto:** Múltiplas camadas de detecção de desconexão e um sistema complexo para garantir a sincronização do nome do jogador, resolvendo um bug crítico que travava o matchmaking.

- **Feedback Visual e Sonoro Imersivo:** O jogo utiliza um sistema de áudio completo (`AudioService`) e efeitos visuais avançados (animações de movimento, explosões, respingos de sangue) para criar uma experiência envolvente.

- **Tema Visual Coeso:** Uma biblioteca de widgets (`MilitaryThemeWidgets`) e um conjunto de ativos gráficos (imagens, ícones) garantem uma identidade visual militar profissional e consistente em toda a aplicação.
