import 'dart:io';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:combatentes/src/common/models/modelos_jogo.dart';

/// Serviço para persistir o estado de posicionamento de peças durante desconexões.
class PlacementPersistence {
  static const String _fileName = 'placement_state.json';
  static const String _gameStateKey = 'placement_game_state';
  static const String _timestampKey = 'saved_timestamp';
  static const String _versionKey = 'version';
  static const int _currentVersion = 1;

  /// Duração máxima para manter um estado salvo (30 minutos).
  static const Duration _maxStateAge = Duration(minutes: 30);

  /// Cache do estado atual para evitar leituras desnecessárias.
  static PlacementGameState? _cachedState;
  static DateTime? _cacheTimestamp;

  /// Último estado salvo para evitar salvamentos duplicados
  static String? _lastSavedStateHash;
  static DateTime? _lastSaveTime;

  /// Obtém o arquivo de persistência no diretório atual.
  static File _getPersistenceFile() {
    return File(_fileName);
  }

  /// Salva o estado atual de posicionamento.
  static Future<bool> savePlacementState(PlacementGameState state) async {
    try {
      // Cria hash do estado para evitar salvamentos duplicados
      final stateJson = jsonEncode(state.toJson());
      final stateHash = stateJson.hashCode.toString();

      // Verifica se é o mesmo estado e se foi salvo recentemente
      final now = DateTime.now();
      if (_lastSavedStateHash == stateHash && _lastSaveTime != null) {
        final timeSinceLastSave = now.difference(_lastSaveTime!);
        if (timeSinceLastSave.inSeconds < 5) {
          // Mesmo estado salvo há menos de 5 segundos, ignora
          return true;
        }
      }

      final file = _getPersistenceFile();
      final data = {
        _versionKey: _currentVersion,
        _timestampKey: now.toIso8601String(),
        _gameStateKey: state.toJson(),
      };

      await file.writeAsString(jsonEncode(data));

      // Atualiza cache e controle de duplicação
      _cachedState = state;
      _cacheTimestamp = now;
      _lastSavedStateHash = stateHash;
      _lastSaveTime = now;

      return true;
    } catch (e) {
      // Log do erro mas não falha a operação
      debugPrint('Erro ao salvar estado de posicionamento: $e');
      return false;
    }
  }

  /// Recupera o estado salvo de posicionamento.
  static Future<PlacementGameState?> loadPlacementState() async {
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
        await clearPlacementState();
        return null;
      }

      // Verifica idade do estado
      final timestampStr = data[_timestampKey] as String?;
      if (timestampStr != null) {
        final timestamp = DateTime.parse(timestampStr);
        final age = DateTime.now().difference(timestamp);

        if (age > _maxStateAge) {
          // Estado muito antigo, remove
          await clearPlacementState();
          return null;
        }
      }

      // Carrega estado
      final stateData = data[_gameStateKey] as Map<String, dynamic>?;
      if (stateData != null) {
        final state = PlacementGameState.fromJson(stateData);

        // Atualiza cache
        _cachedState = state;
        _cacheTimestamp = DateTime.now();

        return state;
      }

      return null;
    } catch (e) {
      // Em caso de erro, remove arquivo corrompido
      debugPrint('Erro ao carregar estado de posicionamento: $e');
      await clearPlacementState();
      return null;
    }
  }

  /// Remove o estado salvo de posicionamento.
  static Future<bool> clearPlacementState() async {
    try {
      final file = _getPersistenceFile();
      if (await file.exists()) {
        await file.delete();
      }

      // Limpa cache
      _cachedState = null;
      _cacheTimestamp = null;

      return true;
    } catch (e) {
      debugPrint('Erro ao limpar estado de posicionamento: $e');
      return false;
    }
  }

  /// Verifica se existe um estado salvo válido.
  static Future<bool> hasValidPlacementState() async {
    final state = await loadPlacementState();
    return state != null;
  }

  /// Atualiza apenas uma parte do estado (para operações incrementais).
  static Future<bool> updatePlacementState({
    Map<String, int>? availablePieces,
    List<PecaJogo>? placedPieces,
    PlacementStatus? localStatus,
    PlacementStatus? opponentStatus,
    Patente? selectedPieceType,
  }) async {
    try {
      final currentState = await loadPlacementState();
      if (currentState == null) {
        return false;
      }

      final updatedState = PlacementGameState(
        gameId: currentState.gameId,
        playerId: currentState.playerId,
        availablePieces: availablePieces ?? currentState.availablePieces,
        placedPieces: placedPieces ?? currentState.placedPieces,
        playerArea: currentState.playerArea,
        localStatus: localStatus ?? currentState.localStatus,
        opponentStatus: opponentStatus ?? currentState.opponentStatus,
        selectedPieceType: selectedPieceType ?? currentState.selectedPieceType,
        gamePhase: currentState.gamePhase,
      );

      return await savePlacementState(updatedState);
    } catch (e) {
      debugPrint('Erro ao atualizar estado de posicionamento: $e');
      return false;
    }
  }

  /// Obtém informações sobre o estado salvo sem carregá-lo completamente.
  static Future<Map<String, dynamic>?> getPlacementStateInfo() async {
    try {
      final file = _getPersistenceFile();
      if (!await file.exists()) {
        return null;
      }

      final contents = await file.readAsString();
      final data = jsonDecode(contents) as Map<String, dynamic>;

      final timestampStr = data[_timestampKey] as String?;
      final version = data[_versionKey] as int?;

      DateTime? timestamp;
      if (timestampStr != null) {
        timestamp = DateTime.parse(timestampStr);
      }

      return {
        'version': version,
        'timestamp': timestamp,
        'age': timestamp != null
            ? DateTime.now().difference(timestamp).inMinutes
            : null,
        'isValid':
            version == _currentVersion &&
            timestamp != null &&
            DateTime.now().difference(timestamp) <= _maxStateAge,
      };
    } catch (e) {
      return null;
    }
  }

  /// Limpa cache interno (útil para testes).
  static void clearCache() {
    _cachedState = null;
    _cacheTimestamp = null;
  }
}
