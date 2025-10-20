import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../placement_provider.dart';
import '../placement_error_handler.dart';
import '../modelos_jogo.dart';
import 'placement_reconnection_dialog.dart';

/// Tela de posicionamento com suporte a reconexão.
class PlacementScreenWithReconnection extends ConsumerStatefulWidget {
  /// Estado inicial de posicionamento.
  final PlacementGameState initialState;

  const PlacementScreenWithReconnection({
    super.key,
    required this.initialState,
  });

  @override
  ConsumerState<PlacementScreenWithReconnection> createState() =>
      _PlacementScreenWithReconnectionState();
}

class _PlacementScreenWithReconnectionState
    extends ConsumerState<PlacementScreenWithReconnection> {
  bool _hasShownReconnectionDialog = false;

  @override
  void initState() {
    super.initState();

    // Inicializa posicionamento tentando restaurar estado salvo
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(placementStateProvider.notifier)
          .initializePlacementWithRestore(widget.initialState);
    });
  }

  @override
  Widget build(BuildContext context) {
    final placementState = ref.watch(placementStateProvider);

    // Monitora erros de conexão para mostrar dialog de reconexão
    ref.listen<PlacementScreenState>(placementStateProvider, (
      previous,
      current,
    ) {
      if (current.error != null && !_hasShownReconnectionDialog) {
        _handleConnectionError(current.error!);
      }
    });

    if (placementState.isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Carregando posicionamento...'),
            ],
          ),
        ),
      );
    }

    if (placementState.shouldNavigateToGame) {
      // Navegar para tela do jogo
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed('/game');
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Posicionamento de Peças'),
        actions: [
          if (placementState.placementState != null)
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () => _showPlacementInfo(context),
            ),
        ],
      ),
      body: placementState.placementState != null
          ? _buildPlacementContent(placementState.placementState!)
          : const Center(child: Text('Erro ao carregar posicionamento')),
    );
  }

  Widget _buildPlacementContent(PlacementGameState state) {
    return Column(
      children: [
        // Status do posicionamento
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Theme.of(context).primaryColor.withOpacity(0.1),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Peças restantes: ${state.totalPiecesRemaining}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                _getStatusMessage(state),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),

        // Conteúdo principal do posicionamento
        Expanded(
          child: Row(
            children: [
              // Inventário de peças (lado esquerdo)
              Expanded(flex: 1, child: _buildPieceInventory(state)),

              // Tabuleiro (lado direito)
              Expanded(flex: 2, child: _buildPlacementBoard(state)),
            ],
          ),
        ),

        // Botões de ação
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: state.canConfirm ? _confirmPlacement : null,
                  child: const Text('PRONTO'),
                ),
              ),
              const SizedBox(width: 16),
              OutlinedButton(
                onPressed: () => _showExitConfirmation(context),
                child: const Text('SAIR'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPieceInventory(PlacementGameState state) {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Inventário', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              itemCount: state.availablePieces.length,
              itemBuilder: (context, index) {
                final entry = state.availablePieces.entries.elementAt(index);
                final patente = entry.key;
                final count = entry.value;

                return ListTile(
                  title: Text(patente),
                  trailing: Text('$count'),
                  enabled: count > 0,
                  onTap: count > 0 ? () => _selectPiece(patente) : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlacementBoard(PlacementGameState state) {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tabuleiro', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Expanded(
            child: AspectRatio(
              aspectRatio: 1.0,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                ),
                child: const Center(
                  child: Text(
                    'Tabuleiro de Posicionamento\n(Implementação pendente)',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getStatusMessage(PlacementGameState state) {
    switch (state.localStatus) {
      case PlacementStatus.placing:
        return 'Posicione suas peças na área destacada';
      case PlacementStatus.ready:
        return 'Aguardando oponente...';
      case PlacementStatus.waiting:
        return 'Aguardando confirmação do oponente...';
    }
  }

  void _selectPiece(String patente) {
    // TODO: Implementar seleção de peça
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Peça selecionada: $patente')));
  }

  void _confirmPlacement() {
    ref.read(placementStateProvider.notifier).confirmPlacement();
  }

  void _handleConnectionError(PlacementError error) {
    if (_hasShownReconnectionDialog) return;

    _hasShownReconnectionDialog = true;

    showPlacementReconnectionDialog(
      context,
      error: error,
      onReconnect: () async {
        final success = await ref
            .read(placementStateProvider.notifier)
            .attemptManualReconnection();

        if (success) {
          _hasShownReconnectionDialog = false;
        }

        return success;
      },
      onCancel: () {
        ref.read(placementStateProvider.notifier).returnToMatchmaking();
        Navigator.of(context).pushReplacementNamed('/');
      },
    ).then((result) {
      _hasShownReconnectionDialog = false;

      if (result == false) {
        // Usuário cancelou, retorna ao menu
        Navigator.of(context).pushReplacementNamed('/');
      }
    });
  }

  void _showPlacementInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Informações do Posicionamento'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('• Posicione todas as 40 peças em sua área'),
            Text('• Sua área são as 4 linhas mais próximas a você'),
            Text('• Clique em uma peça do inventário e depois no tabuleiro'),
            Text('• Arraste peças já posicionadas para reposicioná-las'),
            Text('• Clique em "PRONTO" quando terminar'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showExitConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sair do Posicionamento'),
        content: const Text(
          'Tem certeza que deseja sair? Seu progresso será perdido.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(placementStateProvider.notifier).returnToMatchmaking();
              Navigator.of(context).pushReplacementNamed('/');
            },
            child: const Text('Sair'),
          ),
        ],
      ),
    );
  }
}
