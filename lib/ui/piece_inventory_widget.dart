import 'package:flutter/material.dart';
import '../modelos_jogo.dart';
import '../piece_inventory.dart';
import 'military_theme_widgets.dart';

/// Widget que exibe o inventário de peças disponíveis para posicionamento.
/// Permite seleção de peças com feedback visual e mostra contadores.
class PieceInventoryWidget extends StatelessWidget {
  /// Inventário de peças atual.
  final PieceInventory inventory;

  /// Tipo de peça atualmente selecionado.
  final Patente? selectedPieceType;

  /// Callback chamado quando uma peça é selecionada.
  final void Function(Patente patente) onPieceSelect;

  /// Se o inventário está habilitado para interação.
  final bool enabled;

  const PieceInventoryWidget({
    super.key,
    required this.inventory,
    required this.onPieceSelect,
    this.selectedPieceType,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return MilitaryThemeWidgets.militaryCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          _buildPieceGrid(),
          const SizedBox(height: 12),
          _buildSummary(),
        ],
      ),
    );
  }

  /// Constrói o cabeçalho do inventário.
  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: MilitaryThemeWidgets.primaryGreen.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.inventory_2,
            color: MilitaryThemeWidgets.primaryGreen,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            'Inventário de Peças',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: MilitaryThemeWidgets.primaryGreen,
            ),
          ),
        ),
        MilitaryThemeWidgets.militaryStatusIndicator(
          status: '${inventory.totalPiecesRemaining}/40',
          icon: Icons.military_tech,
          color: inventory.isEmpty
              ? Colors.green
              : MilitaryThemeWidgets.primaryGreen,
        ),
      ],
    );
  }

  /// Constrói a grade de peças organizadas por hierarquia militar.
  Widget _buildPieceGrid() {
    // Organiza as peças por categoria hierárquica
    final officerPieces = [
      Patente.marechal,
      Patente.general,
      Patente.coronel,
      Patente.major,
    ];

    final fieldPieces = [
      Patente.capitao,
      Patente.tenente,
      Patente.sargento,
      Patente.cabo,
    ];

    final troopPieces = [
      Patente.soldado,
      Patente.agenteSecreto,
      Patente.prisioneiro,
      Patente.minaTerrestre,
    ];

    return Column(
      children: [
        _buildPieceCategory('Oficiais Superiores', officerPieces),
        const SizedBox(height: 12),
        _buildPieceCategory('Oficiais de Campo', fieldPieces),
        const SizedBox(height: 12),
        _buildPieceCategory('Tropas e Especiais', troopPieces),
      ],
    );
  }

  /// Constrói uma categoria de peças com título.
  Widget _buildPieceCategory(String title, List<Patente> pieces) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: pieces.map((patente) => _buildPieceItem(patente)).toList(),
        ),
      ],
    );
  }

  /// Constrói um item individual de peça no inventário.
  Widget _buildPieceItem(Patente patente) {
    final count = inventory.getAvailableCount(patente);
    final isSelected = selectedPieceType == patente;
    final isAvailable = count > 0 && enabled;

    return GestureDetector(
      onTap: isAvailable ? () => onPieceSelect(patente) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 80,
        height: 100,
        decoration: BoxDecoration(
          color: _getItemBackgroundColor(isSelected, isAvailable, count),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _getItemBorderColor(isSelected, isAvailable),
            width: isSelected ? 3 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: MilitaryThemeWidgets.primaryGreen.withValues(
                      alpha: 0.3,
                    ),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Imagem da peça
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: isAvailable
                    ? Colors.white
                    : Colors.grey.withValues(alpha: 0.3),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  patente.imagePath,
                  fit: BoxFit.contain,
                  color: isAvailable ? null : Colors.grey,
                  colorBlendMode: isAvailable ? null : BlendMode.saturation,
                ),
              ),
            ),
            const SizedBox(height: 4),

            // Nome da peça (abreviado)
            Text(
              _getAbbreviatedName(patente),
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isAvailable
                    ? MilitaryThemeWidgets.primaryGreen
                    : Colors.grey,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            // Contador
            Container(
              margin: const EdgeInsets.only(top: 2),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: _getCounterBackgroundColor(count, isSelected),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: _getCounterTextColor(count, isSelected),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Retorna a cor de fundo do item baseada no estado.
  Color _getItemBackgroundColor(bool isSelected, bool isAvailable, int count) {
    if (!isAvailable) {
      return Colors.grey.withValues(alpha: 0.1);
    }
    if (isSelected) {
      return MilitaryThemeWidgets.primaryGreen.withValues(alpha: 0.1);
    }
    return Colors.white;
  }

  /// Retorna a cor da borda do item baseada no estado.
  Color _getItemBorderColor(bool isSelected, bool isAvailable) {
    if (!isAvailable) {
      return Colors.grey.withValues(alpha: 0.3);
    }
    if (isSelected) {
      return MilitaryThemeWidgets.primaryGreen;
    }
    return Colors.grey.withValues(alpha: 0.3);
  }

  /// Retorna a cor de fundo do contador.
  Color _getCounterBackgroundColor(int count, bool isSelected) {
    if (count == 0) {
      return Colors.red.withValues(alpha: 0.2);
    }
    if (isSelected) {
      return MilitaryThemeWidgets.primaryGreen;
    }
    return MilitaryThemeWidgets.primaryGreen.withValues(alpha: 0.2);
  }

  /// Retorna a cor do texto do contador.
  Color _getCounterTextColor(int count, bool isSelected) {
    if (count == 0) {
      return Colors.red;
    }
    if (isSelected) {
      return Colors.white;
    }
    return MilitaryThemeWidgets.primaryGreen;
  }

  /// Retorna o nome abreviado da patente para exibição compacta.
  String _getAbbreviatedName(Patente patente) {
    switch (patente) {
      case Patente.marechal:
        return 'Marechal';
      case Patente.general:
        return 'General';
      case Patente.coronel:
        return 'Coronel';
      case Patente.major:
        return 'Major';
      case Patente.capitao:
        return 'Capitão';
      case Patente.tenente:
        return 'Tenente';
      case Patente.sargento:
        return 'Sargento';
      case Patente.cabo:
        return 'Cabo';
      case Patente.soldado:
        return 'Soldado';
      case Patente.agenteSecreto:
        return 'Agente';
      case Patente.prisioneiro:
        return 'Prisioneiro';
      case Patente.minaTerrestre:
        return 'Mina';
    }
  }

  /// Constrói o resumo do inventário.
  Widget _buildSummary() {
    final totalRemaining = inventory.totalPiecesRemaining;
    final totalPlaced = 40 - totalRemaining;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: MilitaryThemeWidgets.primaryGreen.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: MilitaryThemeWidgets.primaryGreen.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryItem(
              'Posicionadas',
              totalPlaced.toString(),
              Icons.place,
              Colors.green,
            ),
          ),
          Container(
            width: 1,
            height: 30,
            color: Colors.grey.withValues(alpha: 0.3),
          ),
          Expanded(
            child: _buildSummaryItem(
              'Restantes',
              totalRemaining.toString(),
              Icons.inventory,
              totalRemaining == 0
                  ? Colors.green
                  : MilitaryThemeWidgets.primaryGreen,
            ),
          ),
        ],
      ),
    );
  }

  /// Constrói um item do resumo.
  Widget _buildSummaryItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }
}
