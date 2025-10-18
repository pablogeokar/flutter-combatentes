# Debugging & Architectural Decisions

## Critical Issues & Solutions

### JSON Serialization Compatibility

**Problem**: The most critical bug preventing the client from connecting was a silent serialization error between server and client.

**Root Cause**:

- Server was sending `patente` field as complex object `{id, forca, nome}` instead of simple string
- Server was including circular WebSocket objects in `jogadores` field
- Flutter client's `EstadoJogo.fromJson()` couldn't process this structure, causing silent failures

**Solution**:

- Modified server to send only patente ID strings (e.g., `"soldado"` instead of object)
- Cleaned up JSON payload to exclude WebSocket references
- Added robust error handling in `game_socket_service.dart` with try-catch blocks

### Server Technology Decision

**Decision**: Switched from TypeScript (`server.ts`) to JavaScript (`server.js`)

**Reasoning**:

- Persistent TypeScript compilation issues with `ts-node` module configuration
- JavaScript eliminates compilation step and ensures stability
- Faster development iteration without build step complications

## Debugging Best Practices

### Client-Side Debugging

- Always wrap WebSocket message processing in try-catch blocks
- Log raw message data when errors occur for inspection
- Use detailed error messages that include both error and stack trace
- Print connection status changes for visibility

### Server-Side Debugging

- Validate JSON structure before sending to clients
- Avoid sending circular references or complex objects
- Use simple data types that match client expectations
- Log player connections/disconnections for session tracking

### Common Pitfalls

1. **Enum Serialization**: Flutter enums expect string values, not objects
2. **WebSocket References**: Never include WebSocket objects in JSON payloads
3. **Silent Failures**: Always implement comprehensive error handling
4. **Type Mismatches**: Ensure server and client data models are perfectly aligned

## Development Workflow

1. Test server JSON output manually before client integration
2. Use browser dev tools or Postman to validate WebSocket messages
3. Implement client-side error logging before testing multiplayer features
4. Keep server and client model definitions synchronized
