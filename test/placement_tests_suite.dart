/// Comprehensive test suite for the placement system
///
/// This file imports and runs all placement-related tests to ensure
/// the entire placement system works correctly.
///
/// Test Coverage:
/// - Piece inventory management and validation
/// - Placement validation rules and edge cases
/// - State transitions and synchronization logic
/// - Error handling and recovery mechanisms
/// - Controller logic and state management
/// - Provider state management and UI integration
/// - Game state model serialization and validation

import 'placement_logic_test.dart' as placement_logic;
import 'placement_controller_test.dart' as placement_controller;
import 'placement_provider_test.dart' as placement_provider;
import 'placement_game_state_test.dart' as placement_game_state;

void main() {
  // Run all placement-related test suites
  placement_logic.main();
  placement_controller.main();
  placement_provider.main();
  placement_game_state.main();
}
