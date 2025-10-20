import 'package:flutter/material.dart';
import '../modelos_jogo.dart';
import 'military_theme_widgets.dart';

/// Widget que exibe o status do posicionamento de peças e permite confirmação.
class PlacementStatusWidget extends StatelessWidget {
  /// Número de peças restantes para posicionar.
  final int localPiecesRemaining;

  /// Status do posicionamento do oponente.
  final PlacementStatus opponentStatus;

  /// Se o jogador local pode confirmar o posicionamento.
  final bool canConfirm;

  /// Status do jogador local.
  final PlacementStatus localStatus;

  /// Callback chamado quando o jogador clica no botão "PRONTO".
  final VoidCallback? onReadyPressed;

  /// Se está mostrando countdown para início do jogo.
  final bool isGameStarting;

  /// Tempo restante do countdown (em segundos).
  final int countdownSeconds;

  const PlacementStatusWidget({
    super.key,
    required this.localPiecesRemaining,
    required this.opponentStatus,
    required this.canConfirm,
    required this.localStatus,
    this.onReadyPressed,
    this.isGameStarting = false,
    this.countdownSeconds = 0,
  });

  @override
  Widget build(BuildContext context) {
    return MilitaryThemeWidgets.militaryCard(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Título
          Text(
            'Status do Posicionamento',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // Status das peças locais
          _buildLocalStatus(context),
          const SizedBox(height: 12),

          // Status do oponente
          _buildOpponentStatus(context),
          const SizedBox(height: 16),

          // Countdown ou botão de confirmação
          if (isGameStarting)
            _buildCountdown(context)
          else
            _buildReadyButton(context),
        ],
      ),
    );
  }

  /// Constrói a seção de status das peças locais.
  Widget _buildLocalStatus(BuildContext context) {
    final totalPieces = 40;
    final placedPieces = totalPieces - localPiecesRemaining;
    final progress = placedPieces / totalPieces;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.person, color: Colors.green[300], size: 20),
            const SizedBox(width: 8),
            Text(
              'Suas peças:',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Barra de progresso
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey[700],
          valueColor: AlwaysStoppedAnimation<Color>(
            localPiecesRemaining == 0 ? Colors.green : Colors.blue,
          ),
        ),
        const SizedBox(height: 4),

        // Texto de progresso
        Text(
          localPiecesRemaining == 0
              ? 'Todas as peças posicionadas!'
              : '$localPiecesRemaining peças restantes',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: localPiecesRemaining == 0
                ? Colors.green[300]
                : Colors.grey[300],
          ),
        ),
      ],
    );
  }

  /// Constrói a seção de status do oponente.
  Widget _buildOpponentStatus(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.person_outline, color: Colors.orange[300], size: 20),
            const SizedBox(width: 8),
            Text(
              'Oponente:',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),

        // Status do oponente com ícone
        Row(
          children: [
            _buildOpponentStatusIcon(),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _getOpponentStatusText(),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: _getOpponentStatusColor(),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Constrói o ícone de status do oponente.
  Widget _buildOpponentStatusIcon() {
    switch (opponentStatus) {
      case PlacementStatus.placing:
        return SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.orange[300]!),
          ),
        );
      case PlacementStatus.ready:
        return Icon(Icons.check_circle, color: Colors.green[300], size: 16);
      case PlacementStatus.waiting:
        return Icon(Icons.hourglass_empty, color: Colors.grey[400], size: 16);
    }
  }

  /// Retorna o texto de status do oponente.
  String _getOpponentStatusText() {
    switch (opponentStatus) {
      case PlacementStatus.placing:
        return 'Posicionando peças...';
      case PlacementStatus.ready:
        return 'Pronto! Aguardando você...';
      case PlacementStatus.waiting:
        return 'Aguardando...';
    }
  }

  /// Retorna a cor do texto de status do oponente.
  Color _getOpponentStatusColor() {
    switch (opponentStatus) {
      case PlacementStatus.placing:
        return Colors.orange[300]!;
      case PlacementStatus.ready:
        return Colors.green[300]!;
      case PlacementStatus.waiting:
        return Colors.grey[400]!;
    }
  }

  /// Constrói o botão de confirmação.
  Widget _buildReadyButton(BuildContext context) {
    final isLocalReady = localStatus == PlacementStatus.ready;
    final isWaiting = localStatus == PlacementStatus.waiting;

    if (isLocalReady || isWaiting) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green[800]?.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green[600]!),
        ),
        child: Column(
          children: [
            Icon(Icons.check_circle, color: Colors.green[300], size: 32),
            const SizedBox(height: 8),
            Text(
              isWaiting
                  ? 'Aguardando oponente...'
                  : 'Posicionamento confirmado!',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.green[300],
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return MilitaryThemeWidgets.militaryButton(
      text: 'PRONTO',
      onPressed: canConfirm ? onReadyPressed : null,
      isLoading: false,
      icon: Icons.check,
    );
  }

  /// Constrói o widget de countdown.
  Widget _buildCountdown(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue[800]?.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[600]!),
      ),
      child: Column(
        children: [
          Icon(Icons.rocket_launch, color: Colors.blue[300], size: 40),
          const SizedBox(height: 12),
          Text(
            'Iniciando partida...',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.blue[300],
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            '$countdownSeconds',
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
