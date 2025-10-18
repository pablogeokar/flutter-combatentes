import 'dart:io';
import 'dart:convert';

/// Serviço para gerenciar as preferências do usuário
/// Implementação simples usando arquivo local
class UserPreferences {
  static const String _fileName = 'combatentes_user.json';
  static const String _userNameKey = 'user_name';
  static String? _cachedUserName;

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
        return data;
      }
    } catch (e) {
      print('Erro ao ler preferências: $e');
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
      print('Erro ao escrever preferências: $e');
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

  /// Remove o nome do usuário salvo
  static Future<void> clearUserName() async {
    _cachedUserName = null;
    try {
      final file = _getPreferencesFile();
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      print('Erro ao limpar preferências: $e');
    }
  }

  /// Verifica se existe um nome salvo
  static Future<bool> hasUserName() async {
    final name = await getUserName();
    return name != null && name.isNotEmpty;
  }
}
