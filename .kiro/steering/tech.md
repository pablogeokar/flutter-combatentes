# Technology Stack

## Frontend (Flutter)

- **Framework**: Flutter SDK ^3.9.2
- **Language**: Dart
- **State Management**: Riverpod (flutter_riverpod ^2.5.1)
- **WebSocket**: web_socket_channel ^2.4.0
- **JSON Serialization**: json_annotation ^4.9.0 + json_serializable ^6.8.0
- **Build Tool**: build_runner ^2.4.11 for code generation

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
