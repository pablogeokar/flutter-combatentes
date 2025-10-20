# Implementation Plan

- [x] 1. Extend game state models to support piece placement phase

  - Add PlacementGameState class with inventory and placement tracking
  - Extend GamePhase enum with PIECE_PLACEMENT and related states
  - Create PlacementStatus enum for tracking player readiness
  - Add PlacementMessage interface for WebSocket communication
  - _Requirements: 1.1, 2.6, 3.2_

- [x] 2. Implement server-side placement logic and validation

  - [x] 2.1 Create PlacementManager class for server-side placement logic

    - Implement piece inventory management per player
    - Add validation for piece positioning within player area
    - Create methods for handling placement updates and confirmations
    - _Requirements: 7.1, 7.2, 6.5_

  - [x] 2.2 Extend GameController to handle placement phase

    - Add placement validation methods (area, piece count, composition)
    - Implement state transitions from placement to game start
    - Add methods to check if both players are ready
    - _Requirements: 7.3, 7.4, 3.4_

  - [x] 2.3 Update WebSocket message handling for placement

    - Add PLACEMENT_UPDATE message handler for piece positioning
    - Add PLACEMENT_READY message handler for player confirmation
    - Implement PLACEMENT_STATUS broadcasting to keep players synchronized
    - Add GAME_START message when both players confirm
    - _Requirements: 3.2, 4.1, 4.2_

- [x] 3. Create piece inventory management system

  - [x] 3.1 Implement PieceInventory class for tracking available pieces

    - Create inventory with correct piece counts (40 total per player)
    - Add methods to remove pieces when placed and return when removed
    - Implement validation to ensure inventory consistency
    - _Requirements: 1.3, 2.5, 7.2_

  - [x] 3.2 Build PieceInventoryWidget for UI display

    - Create grid layout showing all piece types with counts
    - Implement piece selection with visual highlighting
    - Add piece images and names for easy identification
    - Show remaining count for each piece type
    - _Requirements: 5.1, 5.2, 1.3_

- [x] 4. Develop interactive placement board widget

  - [x] 4.1 Create PlacementBoardWidget with drag and drop support

    - Implement board grid with player area highlighting (4 rows)
    - Add drag and drop functionality for piece positioning
    - Show visual feedback for valid/invalid drop zones
    - Handle piece swapping when dropping on occupied positions
    - _Requirements: 1.4, 2.1, 2.4, 5.5_

  - [x] 4.2 Implement placement validation and visual feedback

    - Add real-time validation for piece positioning attempts
    - Show error states for invalid placements with clear messaging
    - Implement hover effects and drop zone indicators
    - Add smooth animations for piece movements
    - _Requirements: 2.3, 5.3, 5.4, 7.1_

- [x] 5. Build placement status and confirmation system

  - [x] 5.1 Create PlacementStatusWidget for progress tracking

    - Display remaining pieces count and completion progress
    - Show opponent status (placing, ready, waiting)
    - Implement ready button that enables only when all pieces placed
    - Add visual indicators for different placement states
    - _Requirements: 2.6, 4.1, 4.2, 5.6_

  - [x] 5.2 Implement confirmation and synchronization logic

    - Add ready confirmation that locks player's placement
    - Implement waiting state when local player ready but opponent not
    - Handle game start transition when both players confirm
    - Add countdown timer for game start (3 seconds)
    - _Requirements: 3.1, 3.3, 3.4, 4.3_

- [x] 6. Create main placement screen and navigation

  - [x] 6.1 Build PiecePlacementScreen as main container

    - Integrate inventory, board, and status widgets
    - Implement responsive layout for different screen sizes
    - Add proper navigation from matchmaking to placement
    - Handle back navigation and confirmation dialogs
    - _Requirements: 1.1, 1.2, 5.6_

  - [x] 6.2 Update game flow to include placement phase

    - Modify matchmaking success to navigate to placement instead of game
    - Update game state provider to handle placement states
    - Add proper state transitions between phases
    - Implement navigation to game screen after both players ready
    - _Requirements: 1.1, 3.5, 4.4_

- [x] 7. Implement error handling and recovery mechanisms

  - [x] 7.1 Add client-side error handling for placement operations

    - Handle invalid placement attempts with user-friendly messages
    - Implement retry mechanisms for network failures
    - Add validation feedback for incomplete placements
    - Create error recovery flows for common issues
    - _Requirements: 2.3, 6.5, 7.3_

  - [x] 7.2 Implement server-side validation and error responses

    - Add comprehensive validation for all placement operations
    - Implement proper error responses with descriptive messages
    - Add logging for debugging placement issues
    - Create safeguards against invalid game states
    - _Requirements: 7.1, 7.4, 6.6_

- [x] 8. Add disconnection handling and state persistence

  - [x] 8.1 Implement placement state persistence during disconnections

    - Save current placement state when player disconnects
    - Restore placement state when player reconnects
    - Handle opponent disconnection with appropriate notifications
    - Add timeout mechanisms for abandoned placements
    - _Requirements: 6.1, 6.2, 6.3_

  - [x] 8.2 Create reconnection flow for placement phase

    - Detect disconnections during placement and attempt reconnection
    - Restore UI state after successful reconnection
    - Handle cases where opponent disconnects permanently
    - Implement fallback to matchmaking if placement fails
    - _Requirements: 6.4, 4.5, 6.5_

- [x] 9. Add comprehensive testing for placement system

  - [x] 9.1 Write unit tests for placement logic and validation

    - Test piece inventory management and validation
    - Test placement validation rules and edge cases
    - Test state transitions and synchronization logic
    - Test error handling and recovery mechanisms
    - _Requirements: 7.1, 7.2, 6.5_

  - [ ]\* 9.2 Create integration tests for client-server placement flow
    - Test complete placement flow from start to game begin
    - Test multi-player synchronization and ready states
    - Test disconnection and reconnection scenarios
    - Test error scenarios and recovery flows
    - _Requirements: 3.4, 4.3, 6.1, 6.4_

- [ ] 10. Optimize performance and add polish features

  - [ ] 10.1 Implement performance optimizations for placement UI

    - Add efficient rendering for large piece inventories
    - Optimize drag and drop operations for smooth experience
    - Implement proper memory management for placement assets
    - Add loading states and progress indicators
    - _Requirements: 5.3, 5.6_

  - [ ] 10.2 Add visual polish and user experience improvements
    - Implement smooth animations for piece placement and removal
    - Add sound effects for placement actions and confirmations
    - Create tutorial or help system for first-time users
    - Add accessibility features for placement interface
    - _Requirements: 5.3, 5.4, 5.6_
