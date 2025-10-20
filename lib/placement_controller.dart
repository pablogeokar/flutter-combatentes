import 'dart:async';
import 'package:flutter/foundation.dart';
import 'modelos_jogo.dart';
import 'game_socket_service.dart';

/// Controlador para gerenciar a lógica de posicionamento de peças.
class PlacementController extends ChangeNotifier {
  final GameSocketService _socketService;

  PlacementGameState? _currentState;
  Timer? _countdownTimer;
  int _countdownSeconds = 3;
  bool _isGameStarting = false;

  StreamSubscription? _messageSubscription;

  PlacementController(this._socketService) {
    // Escuta mensagens do socket service através do stream
    _messageSubscription = _socketService.streamDeEstados.listen((estado) {
      // Processa atualizações de estado do jogo
      _handleGameStateUpdate(estado);
    });
  }

  /// Manipula atualizações de estado do jogo.
  void _handleGameStateUpdate(EstadoJogo estado) {
    // Por enquanto, apenas log da atualização
    // TODO: Implementar lógica específica para placement quando o servidor suportar
    debugPrint('Recebida atualização de estado do jogo: ${estado.idPartida}');
  }

  /// Estado atual do posicionamento.
  PlacementGameState? get currentState => _currentState;

  /// Se está mostrando countdown para início do jogo.
  bool get isGameStarting => _isGameStarting;

  /// Segundos restantes do countdown.
  int get countdownSeconds => _countdownSeconds;

  /// Atualiza o estado do posicionamento.
  void updateState(PlacementGameState newState) {
    _currentState = newState;

    // Verifica se deve iniciar countdown
    if (newState.localStatus == PlacementStatus.ready &&
        newState.opponentStatus == PlacementStatus.ready &&
        !_isGameStarting) {
      _startGameCountdown();
    }

    notifyListeners();
  }

  /// Confirma o posicionamento do jogador local.
  Future<void> confirmPlacement() async {
    if (_currentState == null || !_currentState!.canConfirm) {
      return;
    }

    try {
      // Atualiza status local para ready
      final updatedState = PlacementGameState(
        gameId: _currentState!.gameId,
        playerId: _currentState!.playerId,
        availablePieces: _currentState!.availablePieces,
        placedPieces: _currentState!.placedPieces,
        playerArea: _currentState!.playerArea,
        localStatus: PlacementStatus.ready,
        opponentStatus: _currentState!.opponentStatus,
        selectedPieceType: _currentState!.selectedPieceType,
        gamePhase: _currentState!.gamePhase,
      );

      updateState(updatedState);

      // Envia confirmação para o servidor
      final message = PlacementMessage.placementReady(
        gameId: _currentState!.gameId,
        playerId: _currentState!.playerId,
        allPieces: _currentState!.placedPieces,
      );

      // Para agora, vamos usar um método temporário
      // TODO: Adicionar método público no GameSocketService para enviar mensagens de placement
      debugPrint('Enviando mensagem de placement: ${message.toJson()}');

      // Se oponente já está pronto, inicia countdown
      if (_currentState!.opponentStatus == PlacementStatus.ready) {
        _startGameCountdown();
      } else {
        // Atualiza para waiting se oponente não está pronto
        final waitingState = PlacementGameState(
          gameId: updatedState.gameId,
          playerId: updatedState.playerId,
          availablePieces: updatedState.availablePieces,
          placedPieces: updatedState.placedPieces,
          playerArea: updatedState.playerArea,
          localStatus: PlacementStatus.waiting,
          opponentStatus: updatedState.opponentStatus,
          selectedPieceType: updatedState.selectedPieceType,
          gamePhase: updatedState.gamePhase,
        );
        updateState(waitingState);
      }
    } catch (e) {
      debugPrint('Erro ao confirmar posicionamento: $e');
      // Reverte status em caso de erro
      if (_currentState != null) {
        final revertedState = PlacementGameState(
          gameId: _currentState!.gameId,
          playerId: _currentState!.playerId,
          availablePieces: _currentState!.availablePieces,
          placedPieces: _currentState!.placedPieces,
          playerArea: _currentState!.playerArea,
          localStatus: PlacementStatus.placing,
          opponentStatus: _currentState!.opponentStatus,
          selectedPieceType: _currentState!.selectedPieceType,
          gamePhase: _currentState!.gamePhase,
        );
        updateState(revertedState);
      }
    }
  }

  /// Inicia o countdown para início do jogo.
  void _startGameCountdown() {
    if (_isGameStarting) return;

    _isGameStarting = true;
    _countdownSeconds = 3;
    notifyListeners();

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _countdownSeconds--;
      notifyListeners();

      if (_countdownSeconds <= 0) {
        timer.cancel();
        _finishGameStart();
      }
    });
  }

  /// Finaliza o countdown e inicia o jogo.
  void _finishGameStart() {
    _isGameStarting = false;
    _countdownTimer?.cancel();

    if (_currentState != null) {
      // Atualiza fase do jogo para gameInProgress
      final gameStartState = PlacementGameState(
        gameId: _currentState!.gameId,
        playerId: _currentState!.playerId,
        availablePieces: _currentState!.availablePieces,
        placedPieces: _currentState!.placedPieces,
        playerArea: _currentState!.playerArea,
        localStatus: _currentState!.localStatus,
        opponentStatus: _currentState!.opponentStatus,
        selectedPieceType: _currentState!.selectedPieceType,
        gamePhase: GamePhase.gameInProgress,
      );

      updateState(gameStartState);

      // Envia mensagem de início do jogo
      final message = PlacementMessage.gameStart(
        gameId: _currentState!.gameId,
        playerId: _currentState!.playerId,
      );

      // TODO: Adicionar método público no GameSocketService para enviar mensagens de placement
      debugPrint('Enviando mensagem de início do jogo: ${message.toJson()}');
    }
  }

  /// Manipula mensagem de status do posicionamento.
  // TODO: Reativar quando o servidor suportar mensagens de placement
  // ignore: unused_element
  void _handlePlacementStatusMessage(Map<String, dynamic> message) {
    if (_currentState == null) return;

    final data = message['data'] as Map<String, dynamic>?;
    final statusString = data?['status'] as String?;

    if (statusString != null) {
      PlacementStatus? opponentStatus;
      switch (statusString) {
        case 'placing':
          opponentStatus = PlacementStatus.placing;
          break;
        case 'ready':
          opponentStatus = PlacementStatus.ready;
          break;
        case 'waiting':
          opponentStatus = PlacementStatus.waiting;
          break;
      }

      if (opponentStatus != null) {
        final updatedState = PlacementGameState(
          gameId: _currentState!.gameId,
          playerId: _currentState!.playerId,
          availablePieces: _currentState!.availablePieces,
          placedPieces: _currentState!.placedPieces,
          playerArea: _currentState!.playerArea,
          localStatus: _currentState!.localStatus,
          opponentStatus: opponentStatus,
          selectedPieceType: _currentState!.selectedPieceType,
          gamePhase: _currentState!.gamePhase,
        );

        updateState(updatedState);
      }
    }
  }

  /// Manipula mensagem de confirmação do oponente.
  // TODO: Reativar quando o servidor suportar mensagens de placement
  // ignore: unused_element
  void _handlePlacementReadyMessage(Map<String, dynamic> message) {
    if (_currentState == null) return;

    // Atualiza status do oponente para ready
    final updatedState = PlacementGameState(
      gameId: _currentState!.gameId,
      playerId: _currentState!.playerId,
      availablePieces: _currentState!.availablePieces,
      placedPieces: _currentState!.placedPieces,
      playerArea: _currentState!.playerArea,
      localStatus: _currentState!.localStatus,
      opponentStatus: PlacementStatus.ready,
      selectedPieceType: _currentState!.selectedPieceType,
      gamePhase: _currentState!.gamePhase,
    );

    updateState(updatedState);

    // Se jogador local também está pronto, inicia countdown
    if (_currentState!.localStatus == PlacementStatus.ready) {
      _startGameCountdown();
    }
  }

  /// Manipula mensagem de início do jogo.
  // TODO: Reativar quando o servidor suportar mensagens de placement
  // ignore: unused_element
  void _handleGameStartMessage(Map<String, dynamic> message) {
    if (_currentState == null) return;

    // Para o countdown se estiver rodando
    _countdownTimer?.cancel();
    _isGameStarting = false;

    // Atualiza fase do jogo
    final gameStartState = PlacementGameState(
      gameId: _currentState!.gameId,
      playerId: _currentState!.playerId,
      availablePieces: _currentState!.availablePieces,
      placedPieces: _currentState!.placedPieces,
      playerArea: _currentState!.playerArea,
      localStatus: _currentState!.localStatus,
      opponentStatus: _currentState!.opponentStatus,
      selectedPieceType: _currentState!.selectedPieceType,
      gamePhase: GamePhase.gameInProgress,
    );

    updateState(gameStartState);
  }

  /// Reseta o estado do posicionamento.
  void reset() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
    _isGameStarting = false;
    _countdownSeconds = 3;
    _currentState = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _messageSubscription?.cancel();
    super.dispose();
  }
}
