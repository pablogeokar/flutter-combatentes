# Product Overview

**Combatentes** is a multiplayer strategy board game built with Flutter and Node.js. It's a digital implementation of the classic "Stratego" board game where two players command armies with different military ranks and special abilities.

## Core Gameplay

- Two-player turn-based strategy game on a 10x10 board
- Each player controls an army with pieces of different military ranks (from Prisoner to General)
- Players move pieces to attack opponents and capture the enemy flag (Prisoner piece)
- Special combat rules: Spy can defeat General, Engineer can defuse mines
- Victory conditions: capture enemy flag or eliminate all mobile enemy pieces

## Technical Architecture

- **Frontend**: Flutter mobile app with real-time multiplayer
- **Backend**: Node.js WebSocket server for game state management
- **Communication**: WebSocket-based real-time synchronization
- **State Management**: Riverpod for client-side state management

The game emphasizes strategic positioning, bluffing, and tactical combat in a classic military-themed setting.
