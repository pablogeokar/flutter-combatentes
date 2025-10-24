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

## Flutter App Structure (`lib/`) - REFACTORED ARCHITECTURE

The Flutter app has been completely refactored into a feature-based architecture with clear separation of concerns:

```
lib/
├── main.dart               # App entry point with enhanced SplashScreen
└── src/                    # Source code organized by features and common components
    ├── common/             # Shared components across features
    │   ├── models/         # Core data models and generated code
    │   ├── providers/      # Riverpod providers
    │   ├── services/       # Business logic services
    │   └── widgets/        # Reusable UI components
    ├── features/           # Feature-based organization (numbered by game flow)
    │   ├── 1_initial_setup/    # User setup and matchmaking
    │   ├── 2_piece_placement/  # Piece positioning phase
    │   ├── 3_gameplay/         # Active game phase
    │   └── 4_game_results/     # Victory/defeat screens
    └── utils/              # Utility functions (currently empty)
```

### Common Components (`lib/src/common/`)

#### Models (`lib/src/common/models/`)
```
models/
├── modelos_jogo.dart           # Core game data models with enhanced enums
├── modelos_jogo.g.dart         # Generated JSON serialization code
├── game_state_models.dart      # NEW: Game state management models
├── piece_inventory.dart        # NEW: Piece inventory management
└── piece_inventory.g.dart      # Generated code for piece inventory
```

#### Services (`lib/src/common/services/`)
```
services/
├── game_socket_service.dart        # Enhanced WebSocket client service
├── audio_service.dart              # Comprehensive audio management system
├── user_preferences.dart           # NEW: User preferences management
├── placement_persistence.dart      # NEW: Placement state persistence
└── multi_instance_coordinator.dart # NEW: Multi-instance communication
```

#### Providers (`lib/src/common/providers/`)
```
providers/
└── socket_provider.dart        # Riverpod socket service provider
```

#### Widgets (`lib/src/common/widgets/`)
```
widgets/
├── military_theme_widgets.dart # Military UI component library
└── custom_tooltip.dart         # NEW: Custom tooltip implementation
```

### Feature-Based Architecture (`lib/src/features/`)

#### 1. Initial Setup (`lib/src/features/1_initial_setup/`)
```
1_initial_setup/
├── logic/                  # Business logic (currently empty)
└── ui/
    ├── dialogs/
    │   └── server_config_dialog.dart   # NEW: Server configuration
    └── screens/
        ├── username_screen.dart        # User name input (formerly tela_nome_usuario.dart)
        └── matchmaking_screen.dart     # Enhanced matchmaking with monitoring
```

#### 2. Piece Placement (`lib/src/features/2_piece_placement/`)
```
2_piece_placement/
├── logic/
│   ├── controllers/
│   │   └── placement_controller.dart       # Placement business logic
│   ├── providers/
│   │   └── placement_provider.dart         # Placement state management
│   └── placement_error_handler.dart       # Error handling for placement
└── ui/
    ├── dialogs/
    │   └── placement_reconnection_dialog.dart  # Reconnection during placement
    ├── screens/
    │   ├── piece_placement_screen.dart         # Main placement interface
    │   └── placement_screen_with_reconnection.dart # Enhanced placement with reconnection
    └── widgets/
        ├── piece_inventory_widget.dart         # Piece selection inventory
        ├── placement_board_widget.dart         # Board for piece placement
        └── placement_status_widget.dart        # Placement progress status
```

#### 3. Gameplay (`lib/src/features/3_gameplay/`)
```
3_gameplay/
├── logic/
│   ├── controllers/
│   │   └── game_controller.dart        # Game logic and rules engine
│   └── providers/
│       └── game_state_provider.dart    # Game state management
└── ui/
    ├── dialogs/
    │   └── audio_settings_dialog.dart  # Audio configuration interface
    ├── effects/                        # Visual effects separated into own directory
    │   ├── blood_splatter_widget.dart  # Combat blood effects
    │   ├── disarm_widget.dart          # Mine disarm effects
    │   ├── explosion_widget.dart       # Combat explosion effects
    │   └── piece_movement_widget.dart  # Individual piece animations
    ├── screens/
    │   ├── game_screen.dart            # Main game screen (formerly tela_jogo.dart)
    │   └── game_flow_screen.dart       # Game flow management
    └── widgets/
        ├── animated_board_widget.dart  # Advanced animation system
        └── peca_widget.dart            # Individual piece widget
```

#### 4. Game Results (`lib/src/features/4_game_results/`)
```
4_game_results/
└── ui/
    └── screens/
        └── victory_defeat_screen.dart  # End-game celebration screens
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

### Enhanced Core Models (`lib/src/common/models/`)

#### `modelos_jogo.dart` - Core Game Models
- `Equipe`: Team enumeration (Verde/Preta)
- `Patente`: Military rank enumeration with combat strength
- `PosicaoTabuleiro`: Board coordinate representation
- `PecaJogo`: Individual game piece model
- `Jogador`: Player information
- `EstadoJogo`: Complete game state container
- **NEW**: `GamePhase`: Game phase enumeration (waitingForOpponent, piecePlacement, etc.)
- **NEW**: `PlacementStatus`: Placement status enumeration (placing, ready, waiting)

#### `game_state_models.dart` - NEW: Advanced State Management
- `StatusConexao`: Connection status enumeration
- `GameFlowPhase`: Game flow phase management
- `PlacementGameState`: Placement-specific state container
- `MultiInstanceGameState`: Multi-instance coordination state

#### `piece_inventory.dart` - NEW: Piece Management System
- `PieceInventory`: Manages available pieces during placement
- Default army composition (40 pieces total)
- Piece validation and inventory management
- JSON serialization for persistence

### Game Logic (`lib/src/features/3_gameplay/logic/controllers/game_controller.dart`)

- `GameController`: Pure Dart game rules engine
- Movement validation and combat resolution
- Victory condition checking
- Board constraint enforcement (lakes, boundaries)
- **MOVED**: From root lib/ to feature-specific location

### WebSocket Communication (`lib/src/common/services/game_socket_service.dart`)

- `GameSocketService`: Comprehensive WebSocket client with advanced features
- **Connection Management**: Robust connection handling with automatic retry
- **Name Synchronization**: Multi-attempt name transmission with verification
- **Dynamic Timeout System**: Phase-aware heartbeat monitoring (5min placement, 1min gameplay)
- **Disconnection Detection**: Multiple strategies for opponent disconnection detection
- **Phase Tracking**: Automatic detection of placement vs active game phases
- **Heartbeat Monitoring**: Connection health tracking with intelligent timeout handling
- **Debug Capabilities**: Comprehensive logging and status reporting for troubleshooting
- **MOVED**: From root lib/ to common services with enhanced functionality

### State Management (Feature-Specific Providers)

#### Socket Provider (`lib/src/common/providers/socket_provider.dart`)
- `gameSocketProvider`: Riverpod provider for GameSocketService
- **REFACTORED**: Simplified from complex providers.dart to focused socket management

#### Placement Provider (`lib/src/features/2_piece_placement/logic/providers/placement_provider.dart`)
- Placement-specific state management
- **NEW**: Dedicated provider for placement phase

#### Game State Provider (`lib/src/features/3_gameplay/logic/providers/game_state_provider.dart`)
- `GameStateNotifier`: Riverpod state notifier with enhanced disconnection handling
- **Phase Control Integration**: Automatic phase management during state changes
- **Reconnection Logic**: Smart reconnection with proper state cleanup
- **Matchmaking Recovery**: Force return to matchmaking with complete state reset
- WebSocket integration for real-time updates
- **MOVED**: From root providers.dart to feature-specific location

### NEW Services (`lib/src/common/services/`)

#### `user_preferences.dart` - NEW: User Preferences Management
- Persistent user name storage
- Preference validation and retrieval
- File-based storage system

#### `placement_persistence.dart` - NEW: Placement State Persistence
- Saves placement state during disconnections
- 30-minute state expiration
- JSON-based persistence with versioning
- Cache management for performance

#### `multi_instance_coordinator.dart` - NEW: Multi-Instance Communication
- Coordinates between multiple game instances
- Shared state management via SharedPreferences
- Real-time state synchronization
- Polling-based communication system

### UI Components (Feature-Organized)

#### Common Widgets (`lib/src/common/widgets/`)

- **`military_theme_widgets.dart`**: Military UI component library (MOVED from ui/)
- **`custom_tooltip.dart`**: NEW - Custom tooltip implementation

#### Gameplay Widgets (`lib/src/features/3_gameplay/ui/widgets/`)

- **`peca_widget.dart`**: Optimized game piece widget with tooltip system (MOVED from ui/)
  - Maximum space utilization (92% image coverage)
  - Cross-platform information display (tooltips + long-press)
  - Smart content based on piece ownership
  - Professional styling with shadows and animations

- **`animated_board_widget.dart`**: Advanced animation system (MOVED from ui/)

#### Gameplay Screens (`lib/src/features/3_gameplay/ui/screens/`)

- **`game_screen.dart`**: Main game screen with enhanced combat dialogs (RENAMED from tela_jogo.dart)
  - Improved combat visualization (25% larger piece display)
  - Comprehensive connection management UI
  - Real-time game state synchronization
  - Multi-platform user interaction handling

- **`game_flow_screen.dart`**: Enhanced game flow management (MOVED from ui/)

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
