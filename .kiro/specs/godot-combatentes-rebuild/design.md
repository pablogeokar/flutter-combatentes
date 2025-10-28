# Design Document - Combatentes Godot Rebuild

## Overview

Este documento detalha o design técnico para a reconstrução do jogo Combatentes em Godot 4. O foco é criar uma arquitetura simples, robusta e fácil de implementar manualmente.

## Architecture

### Estrutura de Projeto Simplificada

```
combatentes-novo/
├── scenes/
│   ├── main.tscn                    # Cena principal
│   ├── ui/
│   │   ├── name_screen.tscn         # Tela de entrada de nome
│   │   ├── matchmaking_screen.tscn  # Tela de matchmaking
│   │   └── placement_screen.tscn    # Tela de posicionamento
│   └── game/
│       ├── board.tscn               # Tabuleiro do jogo
│       └── piece.tscn               # Peça individual
├── scripts/
│   ├── autoloads/
│   │   ├── global.gd                # Estado global
│   │   ├── scene_manager.gd         # Gerenciador de cenas
│   │   └── websocket_service.gd     # Serviço WebSocket
│   ├── ui/
│   │   ├── name_screen.gd
│   │   ├── matchmaking_screen.gd
│   │   └── placement_screen.gd
│   └── game/
│       ├── board.gd
│       └── piece.gd
└── assets/
    └── images/
        └── pieces/                  # Imagens das peças
```

## Components and Interfaces

### 1. Global Singleton (AutoLoad)

**Responsabilidade:** Manter estado global do jogo

```gdscript
# global.gd
extends Node

var player_name: String = ""
var game_id: String = ""
var player_id: String = ""
var player_area: Array[int] = []

func reset_game_data():
    game_id = ""
    player_id = ""
    player_area.clear()
```

### 2. Scene Manager (AutoLoad)

**Responsabilidade:** Gerenciar transições entre cenas

```gdscript
# scene_manager.gd
extends Node

func change_scene(scene_path: String):
    print("Mudando para cena: ", scene_path)
    get_tree().change_scene_to_file(scene_path)
```

### 3. WebSocket Service (AutoLoad)

**Responsabilidade:** Comunicação com servidor

```gdscript
# websocket_service.gd
extends Node

signal connected
signal disconnected  
signal message_received(data)

var websocket: WebSocketPeer
var is_connected: bool = false

func connect_to_server():
    # Implementação de conexão
    pass

func send_message(message: Dictionary):
    # Implementação de envio
    pass
```

### 4. Name Screen

**Responsabilidade:** Capturar nome do jogador

**Interface:**
- LineEdit para entrada de nome
- Button para confirmação
- Label para instruções

### 5. Matchmaking Screen

**Responsabilidade:** Conectar ao servidor e encontrar oponente

**Interface:**
- Label de status
- AnimationPlayer para loading (opcional)
- Button de cancelar

### 6. Placement Screen

**Responsabilidade:** Posicionamento de peças

**Interface:**
- Board (tabuleiro)
- Inventory (inventário de peças)
- Confirm Button
- Status Label

## Data Models

### Enums Básicos

```gdscript
# enums.gd
enum Equipe { VERDE, PRETA }
enum Patente {
    PRISIONEIRO,
    SOLDADO, 
    CABO,
    SARGENTO,
    TENENTE,
    CAPITAO,
    MAJOR,
    CORONEL,
    GENERAL,
    MARECHAL,
    AGENTE_SECRETO,
    MINA_TERRESTRE
}
```

### Piece Data

```gdscript
# piece_data.gd
class_name PieceData
extends Resource

var id: String
var patente: int  # Enum Patente
var equipe: int   # Enum Equipe
var position: Vector2i
```

## Error Handling

### Estratégia de Tratamento de Erros

1. **Logs Detalhados:** Todos os erros devem ser logados com contexto
2. **Fallbacks Graceful:** Sistema deve continuar funcionando mesmo com erros
3. **Feedback Visual:** Usuário deve ser informado de problemas
4. **Recovery Automático:** Tentativas automáticas de recuperação quando possível

### Padrões de Error Handling

```gdscript
func safe_scene_change(scene_path: String):
    if not ResourceLoader.exists(scene_path):
        print("ERRO: Cena não encontrada: ", scene_path)
        return false
    
    var result = get_tree().change_scene_to_file(scene_path)
    if result != OK:
        print("ERRO: Falha ao carregar cena: ", scene_path)
        return false
    
    return true
```

## Testing Strategy

### Testes Manuais por Fase

1. **Fase 1 - Navegação Básica**
   - Testar mudança entre cenas
   - Verificar se interfaces carregam corretamente
   - Testar controles de debug

2. **Fase 2 - Entrada de Nome**
   - Testar entrada de texto
   - Verificar validação de nome
   - Testar persistência do nome

3. **Fase 3 - Conexão WebSocket**
   - Testar conexão com servidor
   - Verificar reconexão automática
   - Testar modo offline

4. **Fase 4 - Posicionamento**
   - Testar seleção de peças
   - Verificar posicionamento no tabuleiro
   - Testar validação de posições

### Debug Controls

Implementar controles de debug para facilitar testes:

- **F1:** Toggle modo debug
- **1:** Ir para tela de nome
- **2:** Ir para matchmaking
- **3:** Ir para posicionamento (com dados de teste)
- **D:** Mostrar informações de debug
- **R:** Reset estado global

## Implementation Priority

### Fase 1: Estrutura Básica (Crítica)
1. Criar projeto Godot novo
2. Configurar AutoLoads
3. Criar cena principal simples
4. Implementar navegação básica

### Fase 2: Interface de Nome (Alta)
1. Criar tela de entrada de nome
2. Implementar validação
3. Conectar com estado global

### Fase 3: Matchmaking (Alta)  
1. Implementar WebSocket básico
2. Criar tela de matchmaking
3. Adicionar modo offline para testes

### Fase 4: Posicionamento (Média)
1. Criar tabuleiro básico
2. Implementar inventário de peças
3. Adicionar drag & drop

### Fase 5: Polimento (Baixa)
1. Melhorar visual
2. Adicionar animações
3. Otimizar performance