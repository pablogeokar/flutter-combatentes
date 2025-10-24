import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:combatentes/src/common/models/modelos_jogo.dart';

/// Coordenador para comunicação entre múltiplas instâncias do jogo.
/// Permite que instâncias separadas se comuniquem durante o posicionamento.
class MultiInstanceCoordinator {
  static const String _keyPrefix = 'multi_instance_state_';
  static MultiInstanceCoordinator? _instance;
  static MultiInstanceCoordinator get instance =>
      _instance ??= MultiInstanceCoordinator._();

  MultiInstanceCoordinator._();

  Timer? _pollTimer;
  String? _currentGameId;
  Function(MultiInstanceGameState)? _onStateChanged;

  /// Inicia o monitoramento de mudanças de estado entre instâncias.
  void startMonitoring({
    required String gameId,
    required String playerId,
    required Function(MultiInstanceGameState) onStateChanged,
  }) {
    _currentGameId = gameId;
    _onStateChanged = onStateChanged;

    // Verifica mudanças a cada 500ms
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      _checkForUpdates();
    });

    debugPrint(
      'MultiInstanceCoordinator: Iniciando monitoramento para $gameId',
    );
  }

  /// Para o monitoramento.
  void stopMonitoring() {
    _pollTimer?.cancel();
    _pollTimer = null;
    _onStateChanged = null;
    debugPrint('MultiInstanceCoordinator: Parando monitoramento');
  }

  /// Atualiza o status do jogador atual.
  Future<void> updatePlayerStatus({
    required String gameId,
    required String playerId,
    required PlacementStatus status,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_keyPrefix$gameId';

      MultiInstanceGameState currentState;
      final existingData = prefs.getString(key);

      if (existingData != null) {
        currentState = MultiInstanceGameState.fromJson(
          jsonDecode(existingData),
        );
      } else {
        currentState = MultiInstanceGameState(
          gameId: gameId,
          players: {},
          lastUpdate: DateTime.now(),
        );
      }

      // Cria novo estado com as atualizações
      final updatedPlayers = Map<String, PlacementStatus>.from(
        currentState.players,
      );
      updatedPlayers[playerId] = status;

      final newState = MultiInstanceGameState(
        gameId: gameId,
        players: updatedPlayers,
        lastUpdate: DateTime.now(),
      );

      await prefs.setString(key, jsonEncode(newState.toJson()));
      debugPrint(
        'MultiInstanceCoordinator: Status atualizado - $playerId: $status',
      );
    } catch (e) {
      debugPrint('MultiInstanceCoordinator: Erro ao atualizar status: $e');
    }
  }

  /// Verifica por atualizações de outras instâncias.
  Future<void> _checkForUpdates() async {
    if (_onStateChanged == null || _currentGameId == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final key = '$_keyPrefix$_currentGameId';
      final data = prefs.getString(key);

      if (data == null) return;

      final state = MultiInstanceGameState.fromJson(jsonDecode(data));
      _onStateChanged!(state);
    } catch (e) {
      debugPrint(
        'MultiInstanceCoordinator: Erro ao verificar atualizações: $e',
      );
    }
  }

  /// Limpa o estado compartilhado.
  Future<void> clearState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => key.startsWith(_keyPrefix));

      for (final key in keys) {
        await prefs.remove(key);
      }

      debugPrint('MultiInstanceCoordinator: Estado limpo');
    } catch (e) {
      debugPrint('MultiInstanceCoordinator: Erro ao limpar estado: $e');
    }
  }
}

/// Estado compartilhado entre múltiplas instâncias.
class MultiInstanceGameState {
  final String gameId;
  final Map<String, PlacementStatus> players;
  final DateTime lastUpdate;

  MultiInstanceGameState({
    required this.gameId,
    required this.players,
    required this.lastUpdate,
  });

  factory MultiInstanceGameState.fromJson(Map<String, dynamic> json) {
    final playersMap = <String, PlacementStatus>{};
    final playersJson = json['players'] as Map<String, dynamic>? ?? {};

    playersJson.forEach((key, value) {
      final statusString = value as String;
      final status = PlacementStatus.values.firstWhere(
        (s) => s.name == statusString,
        orElse: () => PlacementStatus.placing,
      );
      playersMap[key] = status;
    });

    return MultiInstanceGameState(
      gameId: json['gameId'] as String,
      players: playersMap,
      lastUpdate: DateTime.parse(json['lastUpdate'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    final playersJson = <String, String>{};
    players.forEach((key, value) {
      playersJson[key] = value.name;
    });

    return {
      'gameId': gameId,
      'players': playersJson,
      'lastUpdate': lastUpdate.toIso8601String(),
    };
  }

  /// Verifica se todos os jogadores estão prontos.
  bool get allPlayersReady {
    return players.values.every((status) => status == PlacementStatus.ready);
  }

  /// Obtém o status de um jogador específico.
  PlacementStatus? getPlayerStatus(String playerId) {
    return players[playerId];
  }
}
