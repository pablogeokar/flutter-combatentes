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
├── audio_service.dart      # Comprehensive audio management system
└── ui/                     # UI components and screens
    ├── tela_jogo.dart      # Main game screen
    ├── animated_board_widget.dart # Advanced animation system
    ├── piece_movement_widget.dart # Individual piece animations
    ├── explosion_widget.dart      # Combat visual effects
    └── audio_settings_dialog.dart # Audio configuration interface
```

## Server Structure (`server/`)

```
server/
├── src/
│   ├── types/
│   │   └── game.types.ts          # Type definitions and interfaces
│   ├── game/
│   │   ├── GameController.ts      # Core game logic and rules
│   │   └── GameStateManager.ts    # Game state initialization
│   ├── websocket/
│   │   ├── GameSessionManager.ts  # Session and connection management
│   │   └── WebSocketMessageHandler.ts # Message processing
│   └── server.ts                  # Application entry point
├── dist/                          # Compiled JavaScript output
├── package.json                   # Node.js dependencies
├── pnpm-lock.yaml                 # Package lock file
├── tsconfig.json                  # TypeScript configuration
└── README.md                      # Server documentation
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

### UI Components (`ui/`)

- **`peca_widget.dart`**: Optimized game piece widget with tooltip system

  - Maximum space utilization (92% image coverage)
  - Cross-platform information display (tooltips + long-press)
  - Smart content based on piece ownership
  - Professional styling with shadows and animations

- **`tela_jogo.dart`**: Main game screen with enhanced combat dialogs

  - Improved combat visualization (25% larger piece display)
  - Comprehensive connection management UI
  - Real-time game state synchronization
  - Multi-platform user interaction handling

- **`animated_board_widget.dart`**: Advanced animation system for piece movement

  - Integrated animation controller with smooth transitions
  - Dust trail particle effects during movement
  - Dynamic shadow and rotation effects
  - Professional board background with grid overlay
  - Coordinated animation timing with game state updates

- **`piece_movement_widget.dart`**: Individual piece animation component

  - Smooth movement transitions with easeOutQuart curve
  - Particle trail system with configurable effects
  - Dynamic shadow positioning based on movement
  - Subtle rotation effects for realistic movement
  - Integration with board coordinate system

- **`explosion_widget.dart`**: Combat visual effects system

  - Animated explosion effects for combat resolution
  - Particle system for debris and smoke effects
  - Configurable animation duration and intensity
  - Integration with combat detection system

- **`audio_settings_dialog.dart`**: Audio configuration interface
  - Toggle controls for background music and sound effects
  - Test buttons for all audio types (turn, combat, explosion)
  - Real-time audio control without app restart
  - Professional UI with clear visual feedback

### Server (Modular Architecture)

- **Types (`game.types.ts`)**: Shared TypeScript interfaces and enums
- **GameController**: Pure game logic, movement validation, combat resolution
- **GameStateManager**: Initial game state creation and piece placement
- **GameSessionManager**: Player matchmaking, connection handling, session lifecycle
- **WebSocketMessageHandler**: Message parsing, routing, and error handling
- **Server Entry Point**: Express server setup, WebSocket configuration

## Naming Conventions

- **Portuguese**: Game domain terms (Equipe, Patente, Jogador)
- **Dart**: camelCase for variables, PascalCase for classes
- **TypeScript**: camelCase for variables, PascalCase for interfaces
- **Files**: snake_case for Dart files, kebab-case acceptable for config files
