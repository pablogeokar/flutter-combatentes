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