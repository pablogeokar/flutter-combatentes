# Connection and Timeout Improvements

This document details the comprehensive improvements made to connection handling, timeout management, and disconnection detection in the Combatentes game.

## Dynamic Timeout System

### Problem Addressed
The original fixed 60-second timeout was causing false disconnections during the piece placement phase, where players need time to think strategically about their positioning.

### Solution Implementation

#### Phase-Based Timeout Management
- **Placement Phase**: 5 minutes (300 seconds) timeout
  - Allows strategic thinking and piece positioning
  - Accommodates slower players and complex strategies
  - Reduces false positive disconnections

- **Active Game Phase**: 60 seconds timeout
  - Maintains responsiveness during active gameplay
  - Quick detection of actual disconnections
  - Appropriate for turn-based gameplay

#### Automatic Phase Detection
```dart
// Server message analysis for phase detection
if (type == 'PLACEMENT_UPDATE' || type == 'PLACEMENT_OPPONENT_READY') {
  setPlacementPhase(true);  // Placement phase active
}

if (type == 'PLACEMENT_GAME_START' || type == 'atualizacaoEstado') {
  setPlacementPhase(false); // Game phase active
}
```

## Enhanced Disconnection Detection

### Multi-Layer Detection System

#### Layer 1: Explicit Server Messages
- `OPPONENT_DISCONNECTED`: Direct server notification
- `GAME_OPPONENT_DISCONNECTED`: Game-specific disconnection
- `GAME_ABANDONED`: Game abandonment notification
- **Response Time**: Immediate (0 seconds)

#### Layer 2: Message Content Analysis
- Analysis of `mensagemServidor` content for disconnection keywords
- Pattern matching for "oponente desconectou", "abandonou", "saiu da partida"
- **Response Time**: Immediate (0 seconds)

#### Layer 3: Heartbeat Timeout
- Dynamic timeout based on current game phase
- Placement: 300 seconds without messages
- Gameplay: 60 seconds without messages
- **Response Time**: Phase-dependent

### Connection Health Monitoring

#### Heartbeat System
```dart
void _startHeartbeatMonitoring() {
  _heartbeatTimer = Timer.periodic(Duration(seconds: 30), (timer) {
    final timeSinceLastMessage = DateTime.now().difference(_lastMessageReceived!);
    final timeoutSeconds = _getHeartbeatTimeout();
    
    if (timeSinceLastMessage.inSeconds > timeoutSeconds) {
      _handleConnectionError('Conexão perdida com o servidor');
    }
  });
}
```

#### Smart Logging
- Periodic heartbeat status without console pollution
- Phase-aware timeout information in logs
- Debug information includes current phase and limits

## User Experience Enhancements

### Visual Feedback Improvements

#### Loading Screen Information
- Clear indication of 5-minute placement time
- Strategic thinking encouragement
- Professional military-themed design

#### Disconnection Dialogs
- **Opponent Disconnection**: Immediate notification with "Find New Opponent" option
- **Connection Loss**: Server connection issues with "Try Reconnect" option
- **Military Styling**: Consistent with game theme using MilitaryThemeWidgets

#### Navigation Improvements
- `pushAndRemoveUntil` for clean navigation stack
- Automatic state cleanup before navigation
- Proper phase reset during reconnections

### State Management Integration

#### GameStateNotifier Enhancements
```dart
void voltarParaAguardandoOponente() {
  // Complete state cleanup
  state = state.copyWith(/* clean all game state */);
  
  // Force placement phase for new game
  socketService.forcePlacementPhase();
  
  // Reconnect with proper phase
  _reconnectAsync();
}
```

#### Automatic Phase Control
- Phase reset during reconnections
- Automatic phase detection from game state updates
- Integration with placement and game screens

## Technical Architecture

### GameSocketService Core Features

#### State Tracking
- `_isInPlacementPhase`: Current game phase
- `_lastMessageReceived`: Heartbeat timestamp
- `_nameConfirmed`: Name synchronization status
- `_pendingUserName`: Name awaiting confirmation

#### Phase Control Methods
- `setPlacementPhase(bool)`: Explicit phase control
- `forceGamePhase()`: Force switch to game phase
- `forcePlacementPhase()`: Force switch to placement phase
- `_getHeartbeatTimeout()`: Dynamic timeout calculation

#### Debug and Monitoring
- `printConnectionDebugInfo()`: Comprehensive status display
- `getConnectionStatus()`: Programmatic status access
- Enhanced logging with phase information

### Integration Points

#### Provider Integration
- Automatic phase control during state updates
- Phase reset during reconnections and matchmaking returns
- Seamless integration with UI state management

#### UI Integration
- GameFlowScreen disconnection monitoring
- MatchmakingScreen progress detection
- TelaJogo enhanced disconnection dialogs

## Performance Considerations

### Efficient Monitoring
- 30-second heartbeat check interval (not too frequent)
- Smart logging to avoid console pollution
- Automatic timer cleanup and resource management

### Memory Management
- Proper disposal of all timers
- Clean state reset during reconnections
- Efficient message processing without memory leaks

### Network Efficiency
- No unnecessary heartbeat messages sent to server
- Client-side timeout management
- Minimal bandwidth usage for monitoring

## Testing and Validation

### Test Scenarios
- [ ] Placement phase timeout (should allow 5 minutes)
- [ ] Game phase timeout (should trigger at 60 seconds)
- [ ] Server disconnection messages (immediate response)
- [ ] Phase transitions (automatic detection)
- [ ] Reconnection scenarios (proper phase reset)
- [ ] Multiple rapid disconnections (stable handling)

### Monitoring Metrics
- Connection establishment time
- Phase detection accuracy
- False positive disconnection rate
- User satisfaction with timeout periods
- Reconnection success rate

This comprehensive system ensures a smooth, professional gaming experience with appropriate timeouts for each phase of gameplay while maintaining quick response to actual disconnections.