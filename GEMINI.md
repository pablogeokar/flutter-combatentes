
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

## 4. Histórico de Decisões e Depuração

Esta seção documenta decisões arquiteturais e bugs importantes que foram encontrados e corrigidos.

- **Pivô do Servidor para JavaScript Puro:** A implementação inicial do servidor foi planejada em TypeScript (`server.ts`). No entanto, devido a erros de compilação persistentes e difíceis de diagnosticar relacionados à configuração de módulos do `ts-node` no ambiente, a abordagem foi alterada. Para garantir a estabilidade e funcionalidade, o servidor foi reescrito em JavaScript puro (`server.js`), eliminando a etapa de compilação e resolvendo os problemas.

- **Bug Crítico de Serialização de Dados:** O principal bug que impedia o cliente de sair da tela "Conectando..." era um erro de serialização silencioso. O servidor (`server.js`) enviava um JSON com uma estrutura incorreta:
  1.  O campo `patente` era enviado como um objeto (`{id, forca, nome}`) em vez de uma string simples (ex: `"soldado"`).
  2.  O campo `jogadores` continha o objeto circular e complexo da conexão WebSocket (`ws`).
  O cliente Dart (`EstadoJogo.fromJson`) não conseguia processar essa estrutura, causando uma falha que não era reportada. O arquivo `server.js` foi corrigido para garantir que a estrutura do JSON enviado corresponda exatamente ao que o cliente espera.

- **Melhora na Depuração do Cliente:** Para diagnosticar o bug acima, o arquivo `game_socket_service.dart` foi modificado para incluir um bloco `try-catch` robusto, capaz de capturar e imprimir no console qualquer erro que ocorra durante o processamento das mensagens recebidas do servidor.
