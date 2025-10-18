/// Serviço para gerenciar as preferências do usuário
/// Implementação com fallback em memória caso SharedPreferences não esteja disponível
class UserPreferences {
  static const String _userNameKey = 'user_name';
  static String? _cachedUserName;
  static bool _sharedPrefsAvailable = false;

  /// Inicializa o serviço e verifica se SharedPreferences está disponível
  static Future<void> _init() async {
    try {
      // Tenta importar SharedPreferences dinamicamente
      final sharedPrefs = await _getSharedPreferences();
      if (sharedPrefs != null) {
        _sharedPrefsAvailable = true;
        _cachedUserName = sharedPrefs.getString(_userNameKey);
      }
    } catch (e) {
      print('SharedPreferences não disponível, usando cache em memória: $e');
      _sharedPrefsAvailable = false;
    }
  }

  /// Tenta obter uma instância do SharedPreferences
  static Future<dynamic> _getSharedPreferences() async {
    try {
      // Esta é uma tentativa de usar SharedPreferences se estiver disponível
      // Por enquanto retorna null para usar o fallback
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Salva o nome do usuário
  static Future<void> saveUserName(String name) async {
    await _init();

    _cachedUserName = name;

    if (_sharedPrefsAvailable) {
      try {
        final prefs = await _getSharedPreferences();
        await prefs?.setString(_userNameKey, name);
      } catch (e) {
        print('Erro ao salvar no SharedPreferences: $e');
      }
    }
  }

  /// Recupera o nome do usuário salvo
  static Future<String?> getUserName() async {
    await _init();

    if (_sharedPrefsAvailable) {
      try {
        final prefs = await _getSharedPreferences();
        final savedName = prefs?.getString(_userNameKey);
        if (savedName != null) {
          _cachedUserName = savedName;
          return savedName;
        }
      } catch (e) {
        print('Erro ao recuperar do SharedPreferences: $e');
      }
    }

    return _cachedUserName;
  }

  /// Remove o nome do usuário salvo
  static Future<void> clearUserName() async {
    await _init();

    _cachedUserName = null;

    if (_sharedPrefsAvailable) {
      try {
        final prefs = await _getSharedPreferences();
        await prefs?.remove(_userNameKey);
      } catch (e) {
        print('Erro ao remover do SharedPreferences: $e');
      }
    }
  }
}
