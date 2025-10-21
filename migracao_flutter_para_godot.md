# Plano de Migração: Flutter "Combatentes" para Godot Engine

## 1. Análise da Arquitetura Atual

-   **Frontend (Cliente):** Aplicativo Flutter (`/lib`) responsável pela interface do usuário (UI), renderização do tabuleiro, interações do jogador e comunicação com o servidor.
-   **Backend (Servidor):** Aplicação Node.js/TypeScript (`/server`) que gerencia a lógica autoritativa do jogo, o estado das partidas e a comunicação entre os dois jogadores via WebSockets.
-   **Comunicação:** Um protocolo de mensagens JSON é usado sobre WebSockets para sincronizar as ações e o estado do jogo (ex: `moverPeca`, `atualizacaoEstado`).
-   **Ativos:** Imagens (`/assets/images`) e sons (`/assets/sounds`) são independentes do código e podem ser reutilizados diretamente.

## 2. Visão Geral da Migração

A migração não será uma "tradução" direta de código Dart para GDScript. Será uma **reimplementação** da camada de cliente (UI e interações) usando as ferramentas e paradigmas da Godot Engine, enquanto aproveitamos a lógica de jogo e os ativos existentes.

-   **O que será Reutilizado:**
    -   **Lógica do Servidor:** O servidor Node.js pode (e deve, inicialmente) ser mantido como está.
    -   **Ativos:** Todas as imagens e sons.
    -   **Conceitos da Lógica:** As regras em `game_controller.dart` e `GameController.ts` servirão como uma especificação precisa para a lógica na Godot.
-   **O que será Reconstruído:**
    -   **Toda a Interface do Usuário:** As telas, botões e widgets do Flutter serão recriados como Cenas e Nós de Controle (`Control Nodes`) da Godot.
    -   **Lógica de Cliente:** A interação do usuário, a seleção de peças e a comunicação com o WebSocket serão reescritas em GDScript.

## 3. Fases da Migração (Passo a Passo)

### Fase 1: Configuração do Projeto e Importação de Ativos

1.  **Criar Projeto Godot:** Crie um novo projeto na Godot.
2.  **Estrutura de Pastas:** Crie uma estrutura de pastas clara dentro do projeto Godot:
    -   `scenes/`: Para armazenar suas cenas (`.tscn`), como o tabuleiro, menu, peças.
    -   `scripts/`: Para armazenar seus scripts GDScript (`.gd`).
    -   `assets/`: Para os ativos do jogo.
3.  **Importar Ativos:** Copie as pastas `assets/images` and `assets/sounds` do seu projeto Flutter para a pasta `assets` do projeto Godot. A Godot irá importá-los automaticamente.

### Fase 2: Estrutura de Dados e Lógica Central (GDScript)

O primeiro passo de codificação é recriar seus modelos de dados de `modelos_jogo.dart` em GDScript. Isso é fundamental.

1.  **Criar Scripts de Dados:** Crie scripts GDScript para cada modelo. Use `class_name` para registrá-los como tipos globais, facilitando o uso em todo o projeto.

    *Exemplo: `scripts/PecaJogo.gd`*
    ```gdscript
    # scripts/PecaJogo.gd
    class_name PecaJogo
    extends Resource # Usar Resource permite salvar e carregar esses dados facilmente

    @export var id: String
    @export var patente: Enums.Patente
    @export var equipe: Enums.Equipe
    @export var posicao: Vector2i # Godot usa Vector2i para coordenadas de grid
    @export var foi_revelada: bool = false

    func _init(p_id := "", p_patente := Enums.Patente.SOLDADO, p_equipe := Enums.Equipe.VERDE, p_posicao := Vector2i.ZERO, p_revelada := false):
        id = p_id
        patente = p_patente
        equipe = p_equipe
        posicao = p_posicao
        foi_revelada = p_revelada
    ```

2.  **Criar Enums Globais:** Para `Patente`, `Equipe`, etc., crie um script de Autoload (Singleton) chamado `Enums.gd` para que fiquem acessíveis globalmente.

    *Exemplo: `scripts/Enums.gd`*
    ```gdscript
    # scripts/Enums.gd
    extends Node

    enum Equipe { VERDE, PRETA }
    enum Patente { PRISIONEIRO, AGENTE_SECRETO, SOLDADO, CABO, SARGENTO, TENENTE, CAPITAO, MAJOR, CORONEL, GENERAL, MARECHAL, MINA_TERRESTRE }
    # ... outros enums
    ```
    > Vá em `Project -> Project Settings -> Autoload` e adicione este script como um singleton global.

3.  **Gerenciador de Estado (Autoload):** Crie outro Autoload chamado `GameStateManager.gd`. Este script será responsável por manter o estado atual do jogo (lista de peças, jogador da vez, etc.), similar ao que o `gameStateProvider` faz no seu código Riverpod.

### Fase 3: Implementando a Rede no Cliente

Você irá recriar a funcionalidade de `game_socket_service.dart` usando a classe `WebSocketClient` da Godot.

1.  **Criar um Gerenciador de Rede:** Crie um novo Autoload chamado `NetworkManager.gd`.
2.  **Conectar ao Servidor:** Neste script, instancie e configure o `WebSocketClient` para se conectar ao seu servidor Node.js existente.

    *Exemplo em `scripts/NetworkManager.gd`*
    ```gdscript
    # scripts/NetworkManager.gd
    extends Node

    signal estado_jogo_recebido(estado_jogo: Dictionary)
    signal erro_movimento(mensagem: String)
    signal conectado_ao_servidor
    signal desconectado_do_servidor

    const SERVER_URL = "ws://localhost:8083"
    var _client := WebSocketClient.new()

    func _ready():
        # Conecta os sinais do WebSocket a funções neste script
        _client.connection_established.connect(_on_connected)
        _client.data_received.connect(_on_data_received)
        _client.connection_closed.connect(_on_closed)
        _client.connection_error.connect(_on_closed)

    func conectar(nome_usuario: String):
        print("Conectando ao servidor...")
        var err = _client.connect_to_url(SERVER_URL)
        if err != OK:
            print("Erro ao iniciar conexão.")
            return

        # A mensagem de 'definirNome' será enviada no _on_connected

    func _process(delta):
        _client.poll()

    func _on_connected(protocol: String):
        print("Conexão estabelecida!")
        emit_signal("conectado_ao_servidor")
        # Envia o nome do usuário (recriando a lógica de GameSocketService)
        enviar_mensagem("definirNome", {"nome": "MeuNomeDeUsuario"})

    func _on_data_received():
        var packet = _client.get_packet()
        var json_string = packet.get_string_from_utf8()
        var data = JSON.parse_string(json_string)

        if data and data.has("type"):
            match data["type"]:
                "atualizacaoEstado":
                    emit_signal("estado_jogo_recebido", data["payload"])
                "erroMovimento":
                    emit_signal("erro_movimento", data["payload"]["mensagem"])
                # ... outros tipos de mensagem

    func enviar_movimento(id_peca: String, nova_posicao: Vector2i):
        var payload = {
            "idPeca": id_peca,
            "novaPosicao": {"linha": nova_posicao.y, "coluna": nova_posicao.x}
        }
        enviar_mensagem("moverPeca", payload)

    func enviar_mensagem(type: String, payload: Dictionary):
        if _client.get_ready_state() == WebSocketClient.STATE_OPEN:
            var msg = {"type": type, "payload": payload}
            _client.send_text(JSON.stringify(msg))
    ```

### Fase 4: Construindo as Cenas e a Interface

Esta é a maior parte do trabalho: traduzir os widgets do Flutter para o sistema de Cenas e Nós da Godot.

1.  **Cena Principal (`TelaJogo` -> `Jogo.tscn`):**
    -   Crie uma cena principal `Jogo.tscn`.
    -   O `AnimatedBoardWidget` será uma cena própria (`Tabuleiro.tscn`) instanciada dentro de `Jogo.tscn`.
    -   O tabuleiro pode ser um `GridContainer` onde cada célula é uma outra cena (`Celula.tscn`) que pode exibir uma peça ou um destaque de movimento válido.

2.  **Cena da Peça (`PecaWidget` -> `Peca.tscn`):**
    -   Crie uma cena `Peca.tscn` com um `Node2D` como raiz.
    -   Adicione um nó `Sprite2D` para exibir a imagem da peça.
    -   Adicione um nó `Area2D` com um `CollisionShape2D` para detectar cliques e arrastos.
    -   Anexe um script `Peca.gd` que guardará os dados da peça (usando a classe `PecaJogo` que você criou) e lidará com os eventos de input.

3.  **Fase de Posicionamento (`PiecePlacementScreen`):**
    -   Crie uma cena separada `Posicionamento.tscn`.
    -   O `PieceInventoryWidget` pode ser um `GridContainer` ou `VBoxContainer` com nós de UI personalizados para cada tipo de peça a ser posicionada.
    -   O `PlacementBoardWidget` será uma versão do seu `Tabuleiro.tscn`, mas com a lógica específica para posicionar peças (validar área do jogador, etc.).
    -   A lógica do `PlacementController` será reimplementada em um script `Posicionamento.gd` anexado à cena principal de posicionamento.

4.  **HUD e UI:**
    -   Use os nós de `Control` da Godot. `Text` do Flutter vira `Label`, `ElevatedButton` vira `Button`, `Dialog` vira `Window` ou `PanelContainer`.
    -   O `VictoryDefeatScreen` será uma cena `FimDeJogo.tscn` que é mostrada sobre a cena principal quando o jogo termina.

### Fase 5: Conectando Tudo com Sinais

O sistema de Sinais da Godot é a cola que unirá tudo. Ele substitui o padrão de `Stream` e `Provider` que você usa com Riverpod.

-   **Fluxo de Dados:**
    1.  O `NetworkManager` recebe uma mensagem do WebSocket (ex: `atualizacaoEstado`).
    2.  Ele emite um sinal, como `estado_jogo_recebido(novo_estado)`.
    3.  O script do seu tabuleiro (`Tabuleiro.gd`) se conecta a este sinal.
    4.  Quando o sinal é emitido, a função conectada no `Tabuleiro.gd` é chamada. Ela limpa as peças antigas e renderiza as novas peças com base no `novo_estado` recebido.

-   **Fluxo de Input:**
    1.  O jogador clica em uma peça (`Peca.tscn`).
    2.  O script `Peca.gd` detecta o clique através da função `_input_event` do seu `Area2D`.
    3.  O `Peca.gd` emite um sinal, como `peca_selecionada(self)`.
    4.  O script principal do jogo (`Jogo.gd`) está conectado a este sinal e chama a lógica para calcular movimentos válidos.
    5.  Quando o jogador clica em uma posição válida, `Jogo.gd` chama `NetworkManager.enviar_movimento(...)`.

### Próximos Passos Recomendados

1.  **Comece Pequeno:** Crie o projeto Godot, importe os ativos e crie os scripts de dados (`PecaJogo.gd`, `Enums.gd`, etc.).
2.  **Cena do Tabuleiro Estático:** Crie a cena `Tabuleiro.tscn` e escreva um código para exibir um conjunto de peças fixo (hard-coded), sem rede ou lógica. Apenas para validar a renderização.
3.  **Implemente a Rede:** Crie o `NetworkManager.gd` e faça-o conectar-se com sucesso ao seu servidor Node.js. Use `print()` para ver as mensagens chegando.
4.  **Junte Tudo:** Conecte o `NetworkManager` à sua cena de tabuleiro usando sinais para que o tabuleiro se atualize com os dados vindos do servidor.
5.  **Implemente a Interação:** Adicione a lógica de clique nas peças e envio de movimentos.
