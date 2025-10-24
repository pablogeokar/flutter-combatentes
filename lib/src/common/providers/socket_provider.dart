import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:combatentes/src/common/services/game_socket_service.dart'; // Updated import

/// Provider que cria e gerencia a instância do [GameSocketService].
final gameSocketProvider = Provider<GameSocketService>((ref) {
  final service = GameSocketService();
  ref.onDispose(() => service.dispose());
  return service;
});
