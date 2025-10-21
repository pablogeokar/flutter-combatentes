import 'dart:io';
import 'dart:convert';

/// Serviço para gerenciar as preferências do usuário
/// Implementação simples usando arquivo local
class UserPreferences {
  static const String _fileName = 'combatentes_user.json';
  static const String _userNameKey = 'user_name';
  static const String _serverAddressKey = 'server_address';
  static const String _defaultServerAddress =
      'wss://flutter-combatentes.onrender.com';

  static String? _cachedUserName;
  static String? _cachedServerAddress;

  /// Obtém o arquivo de preferências no diretório atual
  static File _getPreferencesFile() {
    return File(_fileName);
  }

  /// Lê as preferências do arquivo
  static Future<Map<String, dynamic>> _readPreferences() async {
    try {
      final file = _getPreferencesFile();
      if (await file.exists()) {
        final contents = await file.readAsString();
        final data = jsonDecode(contents) as Map<String, dynamic>;
        _cachedUserName = data[_userNameKey] as String?;
        _cachedServerAddress = data[_serverAddressKey] as String?;
        return data;
      }
    } catch (e) {
      // Ignora erros de leitura
    }
    return {};
  }

  /// Escreve as preferências no arquivo
  static Future<void> _writePreferences(
    Map<String, dynamic> preferences,
  ) async {
    try {
      final file = _getPreferencesFile();
      await file.writeAsString(jsonEncode(preferences));
    } catch (e) {
      // Ignora erros de escrita
    }
  }

  /// Salva o nome do usuário
  static Future<void> saveUserName(String name) async {
    _cachedUserName = name;
    final preferences = await _readPreferences();
    preferences[_userNameKey] = name;
    await _writePreferences(preferences);
  }

  /// Recupera o nome do usuário salvo
  static Future<String?> getUserName() async {
    if (_cachedUserName != null) {
      return _cachedUserName;
    }

    final preferences = await _readPreferences();
    final name = preferences[_userNameKey] as String?;
    _cachedUserName = name;
    return name;
  }

  /// Salva o endereço do servidor
  static Future<void> saveServerAddress(String address) async {
    _cachedServerAddress = address;
    final preferences = await _readPreferences();
    preferences[_serverAddressKey] = address;
    await _writePreferences(preferences);
  }

  /// Recupera o endereço do servidor salvo
  static Future<String> getServerAddress() async {
    if (_cachedServerAddress != null) {
      return _cachedServerAddress!;
    }

    final preferences = await _readPreferences();
    final address = preferences[_serverAddressKey] as String?;
    _cachedServerAddress = address ?? _defaultServerAddress;
    return _cachedServerAddress!;
  }

  /// Remove o nome do usuário salvo
  static Future<void> clearUserName() async {
    _cachedUserName = null;
    try {
      final file = _getPreferencesFile();
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      // Ignora erros ao limpar
    }
  }

  /// Remove todas as preferências salvas
  static Future<void> clearAllPreferences() async {
    _cachedUserName = null;
    _cachedServerAddress = null;
    try {
      final file = _getPreferencesFile();
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      // Ignora erros ao limpar
    }
  }

  /// Verifica se existe um nome salvo
  static Future<bool> hasUserName() async {
    final name = await getUserName();
    return name != null && name.isNotEmpty;
  }
}
