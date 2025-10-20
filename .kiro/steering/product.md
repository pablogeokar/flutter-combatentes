# Product Overview

**Combatentes** is a multiplayer strategy board game built with Flutter and Node.js. It's a digital implementation of the classic "Stratego" board game where two players command armies with different military ranks and special abilities.

## Core Gameplay

- Two-player turn-based strategy game on a 10x10 board
- Each player controls an army of 40 pieces with different military ranks (from Prisoner to Marshal)
- Players move pieces to attack opponents and capture the enemy flag (Prisoner piece)
- Special combat rules: Spy can defeat Marshal, Engineer can defuse mines
- Victory conditions: capture enemy flag or eliminate all mobile enemy pieces

## Army Composition (40 pieces per player)

- **Marshal** (1): Highest ranking officer (Strength 10)
- **General** (1): Second highest rank (Strength 9)
- **Colonel** (2): Senior officers (Strength 8)
- **Major** (3): Field officers (Strength 7)
- **Captain** (4): Company commanders (Strength 6)
- **Lieutenant** (4): Platoon leaders (Strength 5)
- **Sergeant** (4): Squad leaders (Strength 4)
- **Corporal** (5): Team leaders (Strength 3)
- **Soldier** (8): Basic infantry (Strength 2)
- **Spy** (1): Special operative (Strength 1, defeats Marshal)
- **Prisoner** (1): The flag to capture (Strength 0)
- **Landmine** (6): Immobile traps (Strength 11, defeated only by Engineer)

## Technical Architecture

- **Frontend**: Flutter mobile app with real-time multiplayer
- **Backend**: Node.js WebSocket server for game state management
- **Communication**: WebSocket-based real-time synchronization
- **State Management**: Riverpod for client-side state management

The game emphasizes strategic positioning, bluffing, and tactical combat in a classic military-themed setting.

## Key Features

### User Management

- **Player Name Input**: Dedicated screen for entering player names
- **Name Persistence**: Names saved locally using file-based storage
- **User Menu**: Options to change name, clear data, or disconnect
- **Splash Screen**: Automatic name detection and smart navigation

### Enhanced Gameplay

- **Piece Visibility**: Players see only their own pieces and revealed opponent pieces
- **Local Player Identification**: Robust system to identify device owner
- **Combat Revelation**: Strategic information revealed only after combat
- **Turn Indicators**: Clear visual feedback for whose turn it is

### Connection Management

- **Progressive Status**: "Connecting..." → "Connected. Waiting for opponent..." → "Game in progress"
- **Automatic Reconnection**: System attempts reconnection when connection lost
- **Manual Retry**: "Try New Connection" button when server unavailable
- **Connection Timeout**: 10-second timeout prevents freezing
- **Robust Error Handling**: App remains responsive even when server down

### Technical Excellence

- **Modular Architecture**: Server organized into specialized modules
- **Type Safety**: Full TypeScript with strict typing
- **Null Safety**: Robust null-safe implementations
- **Responsive Design**: UI adapts to different screen sizes
- **Professional UX**: Polished interface with proper feedback
