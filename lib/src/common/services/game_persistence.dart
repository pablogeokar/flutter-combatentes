import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:combatentes/src/common/models/modelos_jogo.dart';

/// Serviço para persistir o estado do jogo durante desconexões.
/// Permite recuperar partidas interrompidas por problemas de conexão.
class GamePersistence {
  static const String _fileName = 'active_game_state.json';
  static const String _gameStateKey = 'game_state';
  static const String _playerNameKey = 'player_name';
  static const String _serverAddressKey = 'server_address';
  static const String _gameIdKey = 'game_id';
  static const String _timestampKey = 'saved_timestamp';
  static const String _versionKey = 'version';
  static const int _currentVersion = 1;

  /// Duração máxima para manter um estado salvo (2 horas).
  static const Duration _maxStateAge = Duration(hours: 2);

  /// Cache do estado atual para evitar leituras desnecessárias.
  static ActiveGameState? _cachedState;
  static DateTime? _cacheTimestamp;

  /// Obtém o arquivo de persistência no diretório atual.
  static File _getPersistenceFile() {
    return File(_fileName);
  }

  /// Salva o estado atual do jogo ativo.
  static Future<bool> saveActiveGameState({
    required EstadoJogo gameState,
    required String playerName,
    required String serverAddress,
    String? gameId,
  }) async {
    try {
      final file = _getPersistenceFile();
      final activeState = ActiveGameState(
        gameState: gameState,
        playerName: playerName,
        serverAddress: serverAddress,
        gameId: gameId,
        savedAt: DateTime.now(),
      );

      final data = {
        _versionKey: _currentVersion,
        _timestampKey: DateTime.now().toIso8601String(),
        _gameStateKey: gameState.toJson(),
        _playerNameKey: playerName,
        _serverAddressKey: serverAddress,
        if (gameId != null) _gameIdKey: gameId,
      };

      await file.writeAsString(jsonEncode(data));

      // Atualiza cache
      _cachedState = activeState;
      _cacheTimestamp = DateTime.now();

      debugPrint('✅ Estado do jogo salvo para recuperação');
      return true;
    } catch (e) {
      debugPrint('❌ Erro ao salvar estado do jogo: $e');
      return false;
    }
  }

  /// Recupera o estado salvo do jogo ativo.
  static Future<ActiveGameState?> loadActiveGameState() async {
    try {
      // Verifica cache primeiro
      if (_cachedState != null && _cacheTimestamp != null) {
        final cacheAge = DateTime.now().difference(_cacheTimestamp!);
        if (cacheAge < const Duration(minutes: 1)) {
          return _cachedState;
        }
      }

      final file = _getPersistenceFile();
      if (!await file.exists()) {
        return null;
      }

      final contents = await file.readAsString();
      final data = jsonDecode(contents) as Map<String, dynamic>;

      // Verifica versão
      final version = data[_versionKey] as int?;
      if (version != _currentVersion) {
        // Versão incompatível, remove arquivo
        await clearActiveGameState();
        return null;
      }

      // Verifica idade do estado
      final timestampStr = data[_timestampKey] as String?;
      if (timestampStr != null) {
        final timestamp = DateTime.parse(timestampStr);
        final age = DateTime.now().difference(timestamp);

        if (age > _maxStateAge) {
          // Estado muito antigo, remove
          await clearActiveGameState();
          return null;
        }
      }

      // Carrega estado
      final gameStateData = data[_gameStateKey] as Map<String, dynamic>?;
      final playerName = data[_playerNameKey] as String?;
      final serverAddress = data[_serverAddressKey] as String?;
      final gameId = data[_gameIdKey] as String?;

      if (gameStateData != null &&
          playerName != null &&
          serverAddress != null) {
        final gameState = EstadoJogo.fromJson(gameStateData);
        final activeState = ActiveGameState(
          gameState: gameState,
          playerName: playerName,
          serverAddress: serverAddress,
          gameId: gameId,
          savedAt: DateTime.parse(timestampStr!),
        );

        // Atualiza cache
        _cachedState = activeState;
        _cacheTimestamp = DateTime.now();

        debugPrint(
          '✅ Estado do jogo recuperado: ${gameState.pecas.length} peças',
        );
        return activeState;
      }

      return null;
    } catch (e) {
      debugPrint('❌ Erro ao carregar estado do jogo: $e');
      return null;
    }
  }

  /// Verifica se existe um estado de jogo salvo.
  static Future<bool> hasActiveGameState() async {
    final state = await loadActiveGameState();
    return state != null;
  }

  /// Remove o estado salvo do jogo.
  static Future<bool> clearActiveGameState() async {
    try {
      final file = _getPersistenceFile();
      if (await file.exists()) {
        await file.delete();
      }

      // Limpa cache
      _cachedState = null;
      _cacheTimestamp = null;

      debugPrint('✅ Estado do jogo removido');
      return true;
    } catch (e) {
      debugPrint('❌ Erro ao remover estado do jogo: $e');
      return false;
    }
  }

  /// Atualiza apenas o estado do jogo mantendo outras informações.
  static Future<bool> updateGameState(EstadoJogo newGameState) async {
    final currentState = await loadActiveGameState();
    if (currentState != null) {
      return await saveActiveGameState(
        gameState: newGameState,
        playerName: currentState.playerName,
        serverAddress: currentState.serverAddress,
        gameId: currentState.gameId,
      );
    }
    return false;
  }

  /// Obtém informações básicas do estado salvo sem carregar tudo.
  static Future<Map<String, dynamic>?> getActiveGameInfo() async {
    try {
      final file = _getPersistenceFile();
      if (!await file.exists()) {
        return null;
      }

      final contents = await file.readAsString();
      final data = jsonDecode(contents) as Map<String, dynamic>;

      final timestampStr = data[_timestampKey] as String?;
      final playerName = data[_playerNameKey] as String?;
      final serverAddress = data[_serverAddressKey] as String?;

      if (timestampStr != null && playerName != null && serverAddress != null) {
        final timestamp = DateTime.parse(timestampStr);
        final age = DateTime.now().difference(timestamp);

        return {
          'playerName': playerName,
          'serverAddress': serverAddress,
          'savedAt': timestamp,
          'ageInMinutes': age.inMinutes,
          'isExpired': age > _maxStateAge,
        };
      }

      return null;
    } catch (e) {
      debugPrint('❌ Erro ao obter informações do jogo: $e');
      return null;
    }
  }
}

/// Classe para representar o estado ativo do jogo salvo.
class ActiveGameState {
  final EstadoJogo gameState;
  final String playerName;
  final String serverAddress;
  final String? gameId;
  final DateTime savedAt;

  const ActiveGameState({
    required this.gameState,
    required this.playerName,
    required this.serverAddress,
    this.gameId,
    required this.savedAt,
  });

  /// Verifica se o estado ainda é válido (não expirou).
  bool get isValid {
    final age = DateTime.now().difference(savedAt);
    return age <= GamePersistence._maxStateAge;
  }

  /// Obtém a idade do estado em minutos.
  int get ageInMinutes {
    return DateTime.now().difference(savedAt).inMinutes;
  }
}
