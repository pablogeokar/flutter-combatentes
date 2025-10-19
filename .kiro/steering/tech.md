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
├── comemoracao.mp3       # Victory celebration
└── derrota_fim.wav       # Defeat sound
```

## Visual Design System

### Military Theme Architecture

- **Component Library**: Centralized MilitaryThemeWidgets class for consistent UI elements
- **Asset Integration**: Strategic use of logo.png, combatentes.png, and bg.png across interfaces
- **Color Consistency**: Military green palette (#2E7D32, #4CAF50, #81C784) with proper contrast ratios
- **Responsive Layouts**: Adaptive design patterns that scale across different screen sizes

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
