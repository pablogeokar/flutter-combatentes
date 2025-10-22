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
    ├── tela_nome_usuario.dart # User name input screen
    ├── victory_defeat_screens.dart # End-game celebration screens
    ├── animated_board_widget.dart # Advanced animation system
    ├── piece_movement_widget.dart # Individual piece animations
    ├── explosion_widget.dart      # Combat visual effects
    ├── audio_settings_dialog.dart # Audio configuration interface
    └── military_theme_widgets.dart # Military UI component library
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

### WebSocket Communication (`game_socket_service.dart`)

- `GameSocketService`: Comprehensive WebSocket client with advanced features
- **Connection Management**: Robust connection handling with automatic retry
- **Name Synchronization**: Multi-attempt name transmission with verification
- **Dynamic Timeout System**: Phase-aware heartbeat monitoring (5min placement, 1min gameplay)
- **Disconnection Detection**: Multiple strategies for opponent disconnection detection
- **Phase Tracking**: Automatic detection of placement vs active game phases
- **Heartbeat Monitoring**: Connection health tracking with intelligent timeout handling
- **Debug Capabilities**: Comprehensive logging and status reporting for troubleshooting

### State Management (`providers.dart`)

- `TelaJogoState`: UI state container
- `GameStateNotifier`: Riverpod state notifier with enhanced disconnection handling
- **Phase Control Integration**: Automatic phase management during state changes
- **Reconnection Logic**: Smart reconnection with proper state cleanup
- **Matchmaking Recovery**: Force return to matchmaking with complete state reset
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

- **`military_theme_widgets.dart`**: Comprehensive military UI component library

  - Textured background containers with camouflage pattern
  - Military-styled cards with proper borders and shadows
  - Themed buttons with consistent styling and loading states
  - Professional headers with logo integration
  - Military-themed dialogs with proper branding
  - Styled text fields with military color scheme
  - Status indicators and loading components
  - Large logo components for special screens
  - Reusable components for consistent visual design

- **`victory_defeat_screens.dart`**: End-game celebration and encouragement screens
  - Animated victory screen with custom illustration and celebratory effects
  - Motivational defeat screen with encouraging messaging
  - Smooth animation controllers with elastic and fade transitions
  - Audio integration for victory/defeat sound effects
  - Action buttons for game restart and menu navigation
  - Personalized messaging with player name integration
  - Professional military theme consistency

- **`game_flow_screen.dart`**: Enhanced game flow management with disconnection handling
  - **Disconnection Detection**: Real-time monitoring of opponent disconnections
  - **Smart Navigation**: Automatic return to matchmaking with proper state cleanup
  - **Military Dialogs**: Professional disconnection and connection loss dialogs
  - **Phase-Aware UI**: Loading screen with placement timeout information (5 minutes)
  - **Connection Recovery**: Comprehensive error handling and user feedback
  - **State Integration**: Seamless integration with GameStateNotifier for state management

- **`matchmaking_screen.dart`**: Robust matchmaking with enhanced connection monitoring
  - **Progress Detection**: Automatic detection of stalled matchmaking processes
  - **Name Resend Logic**: Force name retransmission when pairing fails
  - **Connection Monitoring**: Real-time status updates and timeout handling
  - **User Feedback**: Clear visual indicators of connection and pairing status

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
