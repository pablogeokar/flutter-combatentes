# Technology Stack

## Frontend (Flutter)

- **Framework**: Flutter SDK ^3.9.2
- **Language**: Dart
- **State Management**: Riverpod (flutter_riverpod ^2.5.1)
- **WebSocket**: web_socket_channel ^2.4.0
- **JSON Serialization**: json_annotation ^4.9.0 + json_serializable ^6.8.0
- **Build Tool**: build_runner ^2.4.11 for code generation
- **Audio**: audioplayers ^6.0.0 for comprehensive audio management

## Backend (Node.js)

- **Runtime**: Node.js with TypeScript
- **Framework**: Express ^5.1.0
- **WebSocket**: ws ^8.18.3
- **Package Manager**: pnpm
- **UUID Generation**: uuid ^13.0.0

## Development Commands

### Flutter Client

```bash
# Install dependencies
flutter pub get

# Generate JSON serialization code
flutter pub run build_runner build

# Run on device/emulator
flutter run

# Build for production
flutter build apk
flutter build windows
```

### Node.js Server

```bash
# Install dependencies
pnpm install

# Run development server (with hot reload)
pnpm run dev

# Build for production
pnpm run build

# Run production build
pnpm run start

# The server runs on port 8080 by default
```

## Code Generation

- Use `json_serializable` for automatic JSON serialization
- Run `flutter pub run build_runner build` after modifying model classes with `@JsonSerializable()`
- Generated files have `.g.dart` extension (e.g., `modelos_jogo.g.dart`)

## Architecture Patterns

- **Client**: Provider pattern with Riverpod for state management
- **Server**: Event-driven WebSocket architecture
- **Communication**: JSON message passing over WebSocket
- **Game Logic**: Shared business logic between client and server (duplicated for validation)

## WebSocket Communication System

### Enhanced Connection Management (October 2025)

- **Multi-Attempt Name Transmission**: Robust system ensuring player names reach the server
- **Connection State Tracking**: Comprehensive monitoring of connection, name confirmation, and game states
- **Automatic Retry Logic**: Progressive backoff retry system for critical messages
- **Timeout Management**: Multiple timeout systems preventing indefinite waits

### Message Reliability System

- **Critical Message Retry**: Automatic retry for essential messages like `definirNome`
- **Name Verification Timer**: Periodic verification ensuring server received player name
- **Message Logging**: Detailed logging for debugging connection and synchronization issues
- **Error Recovery**: Graceful handling of connection errors with automatic recovery attempts

### Matchmaking Improvements

- **Stall Detection**: Automatic detection when matchmaking process stalls
- **Force Resend Capability**: Manual and automatic name resend when synchronization fails
- **Progress Monitoring**: Real-time monitoring of matchmaking progress with corrective actions
- **State Synchronization**: Enhanced client-server state synchronization for reliable pairing

### Technical Implementation Details

```dart
// Key components for reliable WebSocket communication
class GameSocketService {
  Timer? _nameVerificationTimer;     // Periodic name confirmation check
  Timer? _heartbeatTimer;           // Connection health monitoring
  bool _nameConfirmed = false;       // Server name confirmation tracking
  String? _pendingUserName;          // Name awaiting confirmation
  bool _isInPlacementPhase = true;   // Game phase tracking for dynamic timeouts
  DateTime? _lastMessageReceived;    // Heartbeat timestamp tracking
  
  // Multi-attempt name sending with exponential backoff
  void _enviarNomeComRetry(String nome, int tentativa);
  
  // Force name resend for critical situations
  void forcarReenvioNome(String nome);
  
  // Periodic verification of name confirmation
  void _startNameVerificationTimer(String nomeUsuario);
  
  // Dynamic timeout based on game phase
  int _getHeartbeatTimeout() {
    return _isInPlacementPhase ? 300 : 60; // 5min vs 1min
  }
  
  // Phase control methods
  void setPlacementPhase(bool isPlacement);
  void forceGamePhase();
  void forcePlacementPhase();
}
```

### Dynamic Timeout System Architecture

- **Phase-Aware Heartbeat**: Different timeout values for placement (5min) vs gameplay (1min)
- **Automatic Phase Detection**: Server message analysis to determine current game phase
- **Intelligent Reconnection**: Proper phase restoration during connection recovery
- **Enhanced Debugging**: Comprehensive logging with phase and timeout information

## Animation System

### Flutter Animation Framework

- **AnimationController**: Core animation timing and lifecycle management
- **Tween**: Value interpolation for smooth transitions (position, rotation, opacity)
- **Curves**: easeOutQuart curve for natural movement feel
- **Duration**: 800ms standard for piece movement animations

### Visual Effects Implementation

- **Particle Systems**: Custom particle trail effects using positioned widgets
- **Dynamic Shadows**: Shadow positioning based on piece movement direction
- **Background Integration**: Asset-based board background with transparent overlays
- **Coordinate Transformation**: Unified coordinate system for animations and game logic
- **Blood Splatter System**: Multi-layered CustomPainter with realistic blood physics simulation
- **Combat Feedback**: Intensity-based visual effects that scale with piece importance

### Performance Optimization

- **Widget Recycling**: Reuse of animation widgets to minimize memory allocation
- **Selective Rebuilds**: Targeted widget updates to prevent unnecessary redraws
- **Asset Preloading**: Background images and particle textures loaded at startup
- **Animation Disposal**: Proper cleanup of animation controllers and timers

## Combat Detection System

### Multi-Strategy Detection

- **Primary Strategy**: Direct movement tracking via game state changes
- **Secondary Strategy**: Proximity-based detection using revealed piece positions
- **Tertiary Strategy**: Tie-breaking logic for simultaneous revelations
- **Specialized Detection**: Landmine encounter detection via piece revelation patterns

### State Management Integration

- **Real-time Updates**: WebSocket-driven state synchronization
- **Local Prediction**: Client-side movement validation for responsive UI
- **Server Authority**: Authoritative combat resolution on server side
- **Rollback Capability**: Client state correction when predictions are wrong

## Audio System Architecture

### AudioService Implementation

- **Singleton Pattern**: Single AudioService instance managing all audio operations
- **Dual Audio Players**: Separate players for background music (looped) and sound effects
- **State Management**: Persistent audio preferences with real-time control
- **Error Handling**: Graceful degradation when audio operations fail

### Audio Integration Points

- **Game State Listeners**: Audio triggers based on turn changes and combat detection
- **User Interface**: Menu integration with settings dialog and test functionality
- **Asset Management**: Organized audio assets in assets/sounds/ directory
- **Platform Compatibility**: Cross-platform audio support with proper initialization

### Audio Assets Structure

```
assets/sounds/
├── trilha_sonora.wav      # Background music (looped)
├── campainha.wav          # Turn notification sound
├── tiro.wav              # Combat sound effect
├── explosao.wav          # Mine explosion effect
├── desarme.wav           # Mine disarm effect (Engineer vs Mine)
├── comemoracao.mp3       # Victory celebration
└── derrota_fim.wav       # Defeat sound
```

## Visual Design System

### Military Theme Architecture

- **Component Library**: Centralized MilitaryThemeWidgets class for consistent UI elements
- **Asset Integration**: Strategic use of logo.png, combatentes.png, and bg.png across interfaces
- **Color Consistency**: Military green palette (#2E7D32, #4CAF50, #81C784) with proper contrast ratios
- **Responsive Layouts**: Adaptive design patterns that scale across different screen sizes
- **Complete Army**: 40 pieces per player with proper military hierarchy including Marshal rank

### Visual Asset Structure

```
assets/images/
├── logo.png              # Main game logo (used in headers and splash)
├── combatentes.png       # Text logo (used in AppBar and branding)
├── bg.png               # Camouflage texture background
├── board_background.png  # Game board texture
├── tela_inicial.png     # Legacy background (replaced by bg.png)
├── vitoria.png          # Victory celebration illustration
├── derrota.png          # Defeat encouragement illustration
└── pecas/               # Game piece images directory
```

### UI Component Standards

- **Military Cards**: Elevated containers with military green borders and proper shadows
- **Themed Buttons**: Consistent styling with loading states and icon integration
- **Professional Headers**: Logo integration with proper spacing and typography
- **Textured Backgrounds**: Camouflage pattern with opacity overlays for readability
- **Status Indicators**: Military-themed badges and progress indicators
