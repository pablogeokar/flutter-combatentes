import 'package:json_annotation/json_annotation.dart';
import 'modelos_jogo.dart';

part 'piece_inventory.g.dart';

/// Classe para gerenciar o inventário de peças durante o posicionamento.
/// Controla as peças disponíveis, remoção e adição de peças, e validação.
@JsonSerializable()
class PieceInventory {
  /// Mapa de peças disponíveis (patente -> quantidade).
  final Map<String, int> _availablePieces;

  /// Construtor que inicializa o inventário com as quantidades padrão.
  PieceInventory({Map<String, int>? initialPieces})
    : _availablePieces = Map<String, int>.from(
        initialPieces ?? _createDefaultInventory(),
      );

  /// Cria o inventário padrão com 40 peças total seguindo as regras do Stratego.
  static Map<String, int> _createDefaultInventory() {
    return {
      'marechal': 1, // Marshal (1)
      'general': 1, // General (1)
      'coronel': 2, // Colonel (2)
      'major': 3, // Major (3)
      'capitao': 4, // Captain (4)
      'tenente': 4, // Lieutenant (4)
      'sargento': 4, // Sergeant (4)
      'cabo': 5, // Corporal (5)
      'soldado': 8, // Soldier (8)
      'agenteSecreto': 1, // Spy (1)
      'prisioneiro': 1, // Flag/Prisoner (1)
      'minaTerrestre': 6, // Landmine (6)
    };
  }

  /// Retorna uma cópia do mapa de peças disponíveis.
  Map<String, int> get availablePieces =>
      Map<String, int>.from(_availablePieces);

  /// Retorna a quantidade disponível de uma patente específica.
  int getAvailableCount(Patente patente) {
    return _availablePieces[patente.name] ?? 0;
  }

  /// Verifica se uma patente específica está disponível para posicionamento.
  bool isAvailable(Patente patente) {
    return getAvailableCount(patente) > 0;
  }

  /// Remove uma peça do inventário quando ela é posicionada no tabuleiro.
  /// Retorna true se a remoção foi bem-sucedida, false caso contrário.
  bool removePiece(Patente patente) {
    final currentCount = getAvailableCount(patente);
    if (currentCount > 0) {
      _availablePieces[patente.name] = currentCount - 1;
      return true;
    }
    return false;
  }

  /// Adiciona uma peça de volta ao inventário quando ela é removida do tabuleiro.
  /// Retorna true se a adição foi bem-sucedida, false se exceder o limite máximo.
  bool addPiece(Patente patente) {
    final currentCount = getAvailableCount(patente);
    final maxCount = _getMaxCountForPatente(patente);

    if (currentCount < maxCount) {
      _availablePieces[patente.name] = currentCount + 1;
      return true;
    }
    return false;
  }

  /// Retorna a quantidade máxima permitida para uma patente específica.
  int _getMaxCountForPatente(Patente patente) {
    final defaultInventory = _createDefaultInventory();
    return defaultInventory[patente.name] ?? 0;
  }

  /// Retorna o número total de peças restantes no inventário.
  int get totalPiecesRemaining {
    return _availablePieces.values.fold(0, (sum, count) => sum + count);
  }

  /// Verifica se todas as peças foram posicionadas (inventário vazio).
  bool get isEmpty {
    return totalPiecesRemaining == 0;
  }

  /// Verifica se o inventário está completo (todas as 40 peças).
  bool get isFull {
    return totalPiecesRemaining == 40;
  }

  /// Retorna uma lista de patentes que ainda têm peças disponíveis.
  List<Patente> get availablePatentes {
    return Patente.values.where((patente) => isAvailable(patente)).toList();
  }

  /// Retorna uma lista de patentes que estão esgotadas (quantidade = 0).
  List<Patente> get exhaustedPatentes {
    return Patente.values.where((patente) => !isAvailable(patente)).toList();
  }

  /// Valida se o inventário está em um estado consistente.
  /// Verifica se as quantidades não excedem os limites máximos.
  ValidationResult validateInventory() {
    final errors = <String>[];
    final defaultInventory = _createDefaultInventory();

    for (final patente in Patente.values) {
      final currentCount = getAvailableCount(patente);
      final maxCount = defaultInventory[patente.name] ?? 0;

      if (currentCount < 0) {
        errors.add('${patente.nome}: quantidade negativa ($currentCount)');
      } else if (currentCount > maxCount) {
        errors.add(
          '${patente.nome}: quantidade excede o máximo ($currentCount > $maxCount)',
        );
      }
    }

    return ValidationResult(isValid: errors.isEmpty, errors: errors);
  }

  /// Reseta o inventário para o estado inicial com todas as 40 peças.
  void reset() {
    _availablePieces.clear();
    _availablePieces.addAll(_createDefaultInventory());
  }

  /// Cria uma cópia do inventário atual.
  PieceInventory copy() {
    return PieceInventory(initialPieces: _availablePieces);
  }

  /// Retorna uma representação em string do inventário para debug.
  @override
  String toString() {
    final buffer = StringBuffer(
      'PieceInventory(total: $totalPiecesRemaining):\n',
    );
    for (final patente in Patente.values) {
      final count = getAvailableCount(patente);
      buffer.writeln('  ${patente.nome}: $count');
    }
    return buffer.toString();
  }

  /// Serialização JSON
  factory PieceInventory.fromJson(Map<String, dynamic> json) =>
      _$PieceInventoryFromJson(json);
  Map<String, dynamic> toJson() => _$PieceInventoryToJson(this);
}

/// Resultado da validação do inventário.
class ValidationResult {
  /// Indica se o inventário é válido.
  final bool isValid;

  /// Lista de erros encontrados durante a validação.
  final List<String> errors;

  const ValidationResult({required this.isValid, required this.errors});

  /// Retorna true se não há erros.
  bool get hasNoErrors => errors.isEmpty;

  /// Retorna uma string com todos os erros concatenados.
  String get errorMessage => errors.join(', ');
}
