# Project Structure

## Root Directory Layout

```
combatentes/
├── lib/                    # Flutter application source
├── server/                 # Node.js WebSocket server
├── assets/                 # Flutter assets (images, etc.)
├── test/                   # Flutter tests
├── windows/                # Windows platform-specific files
├── .dart_tool/             # Dart build artifacts
├── build/                  # Flutter build outputs
└── pubspec.yaml            # Flutter dependencies
```

## Flutter App Structure (`lib/`)

```
lib/
├── main.dart               # App entry point and MaterialApp setup
├── modelos_jogo.dart       # Core game data models
├── modelos_jogo.g.dart     # Generated JSON serialization code
├── game_controller.dart    # Game logic and rules engine
├── game_socket_service.dart # WebSocket client service
├── providers.dart          # Riverpod state management
└── ui/                     # UI components and screens
    └── tela_jogo.dart      # Main game screen
```

## Server Structure (`server/`)

```
server/
├── server.ts               # Main WebSocket server implementation
├── server.js               # Compiled JavaScript (if present)
├── package.json            # Node.js dependencies
├── pnpm-lock.yaml          # Package lock file
└── tsconfig.json           # TypeScript configuration
```

## Key File Responsibilities

### Core Models (`modelos_jogo.dart`)

- `Equipe`: Team enumeration (Verde/Preta)
- `Patente`: Military rank enumeration with combat strength
- `PosicaoTabuleiro`: Board coordinate representation
- `PecaJogo`: Individual game piece model
- `Jogador`: Player information
- `EstadoJogo`: Complete game state container

### Game Logic (`game_controller.dart`)

- `GameController`: Pure Dart game rules engine
- Movement validation and combat resolution
- Victory condition checking
- Board constraint enforcement (lakes, boundaries)

### State Management (`providers.dart`)

- `TelaJogoState`: UI state container
- `GameStateNotifier`: Riverpod state notifier
- WebSocket integration for real-time updates

### Server (`server.ts`)

- Authoritative game state management
- Player matchmaking and session handling
- Real-time message broadcasting
- Duplicate game logic for server-side validation

## Naming Conventions

- **Portuguese**: Game domain terms (Equipe, Patente, Jogador)
- **Dart**: camelCase for variables, PascalCase for classes
- **TypeScript**: camelCase for variables, PascalCase for interfaces
- **Files**: snake_case for Dart files, kebab-case acceptable for config files
