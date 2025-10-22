# Troubleshooting Guide

This document contains known issues, their root causes, and implemented solutions for the Combatentes game.

## Connection and Matchmaking Issues

### Issue: Players Stuck in Matchmaking (October 2025)

**Symptoms**:
- Players connect successfully but never advance to placement screen
- Server logs show pairing between "Aguardando nome..." players
- Client logs show "❌ Falha ao enviar nome após segunda tentativa"
- Players disconnect during placement phase

**Root Cause Analysis**:
- Client WebSocket connection established successfully
- Player name transmission to server was failing intermittently
- Server proceeded with matchmaking using default "Aguardando nome..." placeholder
- Synchronization failure between client name and server player records

**Technical Details**:
```
Client Log Pattern:
🔍 Nome obtido das preferências: Pablo
🔍 Endereço do servidor: wss://combatentes.zionix.com.br
✅ Conectando ao servidor com nome: Pablo
🏷️ Enviando nome do usuário: Pablo
❌ Conexão não estabelecida, tentando novamente...
❌ Falha ao enviar nome após segunda tentativa

Server Log Pattern:
Cliente conectado.
Pareamento realizado entre Aguardando nome... e Aguardando nome...
🎯 Fase de posicionamento iniciada para sessão [uuid]
⏰ Placement abandoned by player [uuid] in game [uuid]
🧹 Cleaned up abandoned game [uuid]
```

**Implemented Solution**:

1. **Enhanced Name Transmission System**:
   - Multiple immediate send attempts upon connection
   - Progressive retry with exponential backoff (up to 5 attempts)
   - Automatic retry for critical messages like `definirNome`

2. **Name Verification System**:
   - Periodic timer checking if name was confirmed by server
   - Automatic resend every 2 seconds if not confirmed
   - 30-second timeout to prevent infinite loops

3. **Matchmaking Monitoring**:
   - Detection when connected >5 seconds without game progress
   - Automatic force resend of player name
   - Enhanced logging for debugging synchronization issues

4. **Connection State Management**:
   - Tracking of connection, name confirmation, and game states
   - Proper cleanup and reset of state variables on reconnection
   - Improved error handling throughout the connection process

**Code Changes**:
- `GameSocketService`: Added `_nameConfirmed`, `_nameVerificationTimer`, `_pendingUserName`
- `MatchmakingScreen`: Added progress monitoring and corrective actions
- Enhanced message handling with detailed logging and retry logic

**Prevention Measures**:
- Comprehensive logging for future debugging
- Multiple fallback strategies for name transmission
- Automatic detection and correction of synchronization issues
- Robust error handling preventing app freezing

### Issue: Timeout Too Aggressive During Placement (October 2025)

**Symptoms**:
- Players getting disconnected during piece placement phase
- 60-second timeout too short for strategic thinking
- False positive disconnections during normal gameplay

**Root Cause Analysis**:
- Fixed 60-second heartbeat timeout was inappropriate for placement phase
- Players need more time to think about piece positioning strategy
- Different phases of the game require different timeout tolerances

**Implemented Solution**:

1. **Dynamic Timeout System**:
   - **Placement Phase**: 5 minutes timeout (300 seconds) for strategic thinking
   - **Active Game Phase**: 60 seconds timeout for responsive gameplay
   - Automatic phase detection based on server messages

2. **Intelligent Phase Detection**:
   - `PLACEMENT_*` messages indicate placement phase
   - `atualizacaoEstado` messages indicate active game phase
   - `PLACEMENT_GAME_START` specifically marks end of placement

3. **Manual Phase Control**:
   - `setPlacementPhase(bool)` for explicit phase changes
   - `forceGamePhase()` and `forcePlacementPhase()` for edge cases
   - Automatic phase reset during reconnections

4. **Enhanced User Feedback**:
   - Loading screen shows "5 minutes for placement" information
   - Debug logs include current phase and timeout values
   - Heartbeat logs show phase-appropriate timeout limits

**Technical Implementation**:
```dart
// Dynamic timeout based on game phase
int _getHeartbeatTimeout() {
  if (_isInPlacementPhase) {
    return 300; // 5 minutes for strategic thinking
  } else {
    return 60;  // 1 minute for active gameplay
  }
}

// Automatic phase detection
if (type == 'PLACEMENT_GAME_START') {
  setPlacementPhase(false); // Switch to game phase
}
```

**User Experience Improvements**:
- Players no longer get false disconnections during placement
- Clear indication of available time for positioning
- Immediate response to actual server-reported disconnections
- Appropriate timeouts for each phase of gameplay

### Issue: Placement Reconnection Failure (October 2025)

**Symptoms**:
- Player disconnects during piece placement phase
- Reconnection attempts fail to restore placement session
- Player forced back to matchmaking instead of continuing placement
- Loss of placement progress and opponent pairing

**Root Cause Analysis**:
- Generic reconnection logic not suitable for placement phase
- No session preservation during placement disconnections
- Lack of placement-specific reconnection handling
- Immediate return to matchmaking without reconnection attempt

**Implemented Solution**:

1. **Placement-Specific Reconnection Dialog**:
   - Different dialog for placement vs game disconnections
   - "Reconnect to Game" option to preserve session
   - "Find New Opponent" as fallback option
   - Clear messaging about placement session preservation

2. **Enhanced Reconnection Logic**:
   - `reconnectDuringPlacement()` method with placement-aware handling
   - Extended 15-second timeout for placement reconnections
   - Dual listener system (status + placement messages)
   - Automatic placement phase restoration

3. **Session Preservation**:
   - Maintains placement state during reconnection attempts
   - Preserves opponent pairing when possible
   - Automatic phase detection and restoration
   - Graceful fallback to matchmaking if reconnection fails

4. **Improved User Flow**:
   - Loading dialog during reconnection attempts
   - Clear feedback on reconnection success/failure
   - Automatic navigation based on reconnection result
   - Proper state cleanup on reconnection failure

**Technical Implementation**:
```dart
// Placement-specific reconnection with extended timeout
Future<bool> reconnectDuringPlacement(String url, {String? nomeUsuario}) async {
  // Force placement phase for reconnection
  _isInPlacementPhase = true;
  
  // Dual listener system for comprehensive detection
  statusSubscription = streamDeStatus.listen((status) { /* ... */ });
  placementSubscription = streamDePlacement.listen((data) { /* ... */ });
  
  // Extended timeout for placement complexity
  Timer(Duration(seconds: 15), () { /* ... */ });
}

// Smart dialog selection based on game phase
void _showConnectionLostAndReturn(BuildContext context) {
  if (_currentPhase == GameFlowPhase.placement) {
    _showPlacementReconnectionDialog(context);
  } else {
    _showGameDisconnectionDialog(context);
  }
}
```

**User Experience Improvements**:
- Players can attempt to reconnect to their placement session
- Clear options for reconnection vs finding new opponent
- Preserved placement progress when reconnection succeeds
- Graceful handling of reconnection failures with proper feedback

## Performance Issues

### Issue: App Freezing on Server Unavailable

**Solution**: Implemented 10-second connection timeout and null-safe WebSocket operations.

### Issue: Memory Leaks from Timers

**Solution**: Proper disposal of all timers and controllers in dispose methods.

## Game Logic Issues

### Issue: Piece Visibility Breaking Game Mechanics

**Solution**: Robust local player identification with multiple fallback strategies.

### Issue: Combat Detection Failures

**Solution**: Multi-strategy combat detection system with hierarchical fallbacks.

## Audio System Issues

### Issue: Audio Not Playing on Some Devices

**Solution**: Comprehensive AudioService with error handling and graceful degradation.

## Development Guidelines

### When Encountering New Issues

1. **Add Comprehensive Logging**: Include detailed debug prints for state tracking
2. **Implement Fallback Strategies**: Always have backup approaches for critical functionality
3. **Add Timeout Mechanisms**: Prevent indefinite waits with appropriate timeouts
4. **Test Edge Cases**: Verify behavior when servers are down, connections are slow, etc.
5. **Document Root Causes**: Update this guide with new issues and their solutions

### Testing Checklist for Connection Issues

- [ ] Server completely unavailable
- [ ] Slow network connections
- [ ] Intermittent connection drops
- [ ] Multiple rapid reconnection attempts
- [ ] Name synchronization with special characters
- [ ] Concurrent player connections
- [ ] Server restart during active connections

### Monitoring and Debugging

**Key Log Patterns to Watch**:
- Name transmission and confirmation logs
- Connection state transitions
- Timer creation and cancellation
- Message send/receive patterns
- Error recovery attempts

**Performance Metrics**:
- Connection establishment time
- Name confirmation time
- Matchmaking completion time
- Memory usage during extended sessions
- Timer and resource cleanup verification

This troubleshooting guide should be updated whenever new issues are discovered and resolved.