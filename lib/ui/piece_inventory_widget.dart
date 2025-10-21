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
    return LayoutBuilder(
      builder: (context, constraints) {
        // Ajusta padding baseado no espaço disponível
        final padding = constraints.maxWidth < 400 ? 12.0 : 16.0;
        final spacing = constraints.maxWidth < 400 ? 8.0 : 12.0;

        return MilitaryThemeWidgets.militaryCard(
          padding: EdgeInsets.all(padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(),
              SizedBox(height: spacing),
              _buildPieceGrid(),
              SizedBox(height: spacing),
              _buildSummary(),
            ],
          ),
        );
      },
    );
  }

  /// Constrói o cabeçalho do inventário.
  Widget _buildHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 400;

        return Row(
          children: [
            Container(
              padding: EdgeInsets.all(isCompact ? 6 : 8),
              decoration: BoxDecoration(
                color: MilitaryThemeWidgets.primaryGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.inventory_2,
                color: MilitaryThemeWidgets.primaryGreen,
                size: isCompact ? 20 : 24,
              ),
            ),
            SizedBox(width: isCompact ? 8 : 12),
            Expanded(
              child: Text(
                isCompact ? 'Inventário' : 'Inventário de Peças',
                style: TextStyle(
                  fontSize: isCompact ? 16 : 18,
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
      },
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

    return LayoutBuilder(
      builder: (context, constraints) {
        // Determina se deve usar layout compacto baseado na largura disponível
        final isCompact = constraints.maxWidth < 400;

        if (isCompact) {
          // Layout compacto: todas as peças em uma única grade
          final allPieces = [...officerPieces, ...fieldPieces, ...troopPieces];
          return _buildCompactGrid(allPieces);
        } else {
          // Layout normal com categorias
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
      },
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
        LayoutBuilder(
          builder: (context, constraints) {
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: pieces
                  .map(
                    (patente) => _buildPieceItem(patente, constraints.maxWidth),
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
  }

  /// Constrói uma grade compacta para telas pequenas.
  Widget _buildCompactGrid(List<Patente> pieces) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Wrap(
          spacing: 6,
          runSpacing: 6,
          children: pieces
              .map((patente) => _buildPieceItem(patente, constraints.maxWidth))
              .toList(),
        );
      },
    );
  }

  /// Constrói um item individual de peça no inventário.
  Widget _buildPieceItem(Patente patente, double availableWidth) {
    final count = inventory.getAvailableCount(patente);
    final isSelected = selectedPieceType == patente;
    final isAvailable = count > 0 && enabled;

    // Calcula tamanho responsivo baseado na largura disponível
    final itemsPerRow = (availableWidth / 90).floor().clamp(3, 6);
    final itemWidth = (availableWidth - (itemsPerRow - 1) * 8) / itemsPerRow;
    final itemHeight = itemWidth * 1.25; // Proporção 4:5
    final imageSize = (itemWidth * 0.5).clamp(24.0, 40.0);
    final fontSize = (itemWidth * 0.12).clamp(8.0, 10.0);

    return GestureDetector(
      onTap: isAvailable ? () => onPieceSelect(patente) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: itemWidth,
        height: itemHeight,
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
              width: imageSize,
              height: imageSize,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: isAvailable
                    ? Colors.white
                    : Colors.grey.withValues(alpha: 0.3),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.asset(
                  patente.imagePath,
                  fit: BoxFit.contain,
                  color: isAvailable ? null : Colors.grey,
                  colorBlendMode: isAvailable ? null : BlendMode.saturation,
                ),
              ),
            ),
            SizedBox(height: itemHeight * 0.04),

            // Nome da peça (abreviado)
            Flexible(
              child: Text(
                _getAbbreviatedName(patente),
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w600,
                  color: isAvailable
                      ? MilitaryThemeWidgets.primaryGreen
                      : Colors.grey,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            // Contador
            Container(
              margin: EdgeInsets.only(top: itemHeight * 0.02),
              padding: EdgeInsets.symmetric(
                horizontal: (itemWidth * 0.08).clamp(4.0, 6.0),
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: _getCounterBackgroundColor(count, isSelected),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  fontSize: (fontSize * 1.2).clamp(10.0, 12.0),
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 400;

        return Container(
          padding: EdgeInsets.all(isCompact ? 8 : 12),
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
                  isCompact,
                ),
              ),
              Container(
                width: 1,
                height: isCompact ? 25 : 30,
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
                  isCompact,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Constrói um item do resumo.
  Widget _buildSummaryItem(
    String label,
    String value,
    IconData icon,
    Color color,
    bool isCompact,
  ) {
    return Column(
      children: [
        Icon(icon, color: color, size: isCompact ? 16 : 20),
        SizedBox(height: isCompact ? 2 : 4),
        Text(
          value,
          style: TextStyle(
            fontSize: isCompact ? 16 : 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: isCompact ? 10 : 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
