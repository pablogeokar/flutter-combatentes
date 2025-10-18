
# Contexto do Projeto: Jogo "Combate" Multiplayer

Este documento resume a arquitetura e o estado atual do projeto, um jogo de tabuleiro "Combate" multiplayer.

## 1. Arquitetura Geral

O projeto utiliza uma arquitetura Cliente-Servidor:

- **Servidor (Backend):** Uma aplicação Node.js que atua como a autoridade central do jogo. Ele gerencia o estado das partidas, valida as jogadas e comunica-se com os clientes.
- **Cliente (Frontend):** Uma aplicação Flutter que renderiza a interface do usuário (UI) e envia as ações do jogador para o servidor.

## 2. Detalhes do Servidor (Backend)

- **Linguagem:** JavaScript (CommonJS)
- **Arquivo Principal:** `server/server.js`
- **Dependências:** `express`, `ws`, `uuid`.
- **Funcionalidades:**
  - **Matchmaking:** Emparelha os dois primeiros clientes que se conectam em uma partida.
  - **Fonte da Verdade:** Mantém o `EstadoJogo` oficial para cada partida ativa.
  - **Lógica do Jogo:** Contém uma classe `GameControllerServer` que replica as regras do jogo para validar todas as jogadas.
  - **Comunicação:** Usa WebSockets para comunicação em tempo real.

### Protocolo de Comunicação (JSON):
- **Cliente -> Servidor:**
  - `{ "type": "moverPeca", "payload": { "idPeca": "...", "novaPosicao": {...} } }`
- **Servidor -> Cliente:**
  - `{ "type": "atualizacaoEstado", "payload": EstadoJogo }`: Envia o novo estado do jogo para ambos os jogadores.
  - `{ "type": "erroMovimento", "payload": { "mensagem": "..." } }`: Envia uma mensagem de erro apenas para o jogador que fez uma jogada inválida.
  - `{ "type": "mensagemServidor", "payload": "..." }`: Envia mensagens informativas (ex: aguardando jogador).

## 3. Detalhes do Cliente (Frontend - Flutter)

- **Linguagem:** Dart
- **Gerenciamento de Estado:** `flutter_riverpod`
- **Convenção:** Comentários de código e textos da UI estão em Português do Brasil (pt-BR).

### Estrutura e Arquivos Principais:

- **`main.dart`:** Ponto de entrada da aplicação. Configura o `ProviderScope` do Riverpod.

- **`modelos_jogo.dart`:** Contém todos os modelos de dados puros (`EstadoJogo`, `PecaJogo`, `Jogador`, etc.). As classes são imutáveis e preparadas para serialização JSON com `json_serializable`.

- **`game_socket_service.dart`:** Encapsula toda a lógica de comunicação com o WebSocket. Expõe `Streams` para receber atualizações de estado e erros do servidor.

- **`providers.dart`:** Arquivo central do Riverpod.
  - `gameSocketProvider`: Fornece a instância do `GameSocketService`.
  - `gameStateProvider`: Um `StateNotifierProvider` que gerencia o estado da UI (`TelaJogoState`).
    - O `GameStateNotifier` **não contém lógica de jogo**. Ele ouve o `streamDeEstados` do `GameSocketService` e atualiza seu estado quando o servidor envia uma atualização.
    - Ações do usuário (como `moverPeca`) apenas encaminham a intenção para o `GameSocketService`, que a envia para o servidor.

- **`lib/ui/`:** Contém os widgets da interface do usuário.
  - **`tela_jogo.dart`:** A tela principal. É um `ConsumerWidget` que reage às mudanças do `gameStateProvider`. Exibe um indicador de carregamento enquanto se conecta ao servidor.
  - **`tabuleiro_widget.dart`:** Renderiza o tabuleiro 10x10 e as peças com base no `EstadoJogo` atual.
  - **`peca_widget.dart`:** Renderiza uma única peça, com diferentes visuais para peça selecionada, oculta ou revelada.
