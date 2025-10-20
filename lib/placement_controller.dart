import 'dart:async';
import 'package:flutter/foundation.dart';
import 'modelos_jogo.dart';
import 'game_socket_service.dart';
import 'placement_error_handler.dart';
import 'services/placement_persistence.dart';
import 'services/multi_instance_coordinator.dart';
import 'providers.dart';

/// Controlador para gerenciar a lógica de posicionamento de peças.
class PlacementController extends ChangeNotifier {
  final GameSocketService _socketService;

  PlacementGameState? _currentState;
  Timer? _countdownTimer;
  int _countdownSeconds = 3;
  bool _isGameStarting = false;

  /// Configuração para retry de operações.
  final RetryConfig _retryConfig;

  /// Último erro ocorrido.
  PlacementError? _lastError;

  /// Se está executando uma operação de retry.
  bool _isRetrying = false;

  StreamSubscription? _messageSubscription;

  /// Timer para detectar desconexões durante posicionamento.
  Timer? _connectionWatchdog;

  /// Se está tentando reconectar.
  bool _isReconnecting = false;

  /// Timestamp da última atividade de rede.
  DateTime? _lastNetworkActivity;

  /// Timeout para considerar desconexão (2 minutos durante posicionamento).
  static const Duration _connectionTimeout = Duration(minutes: 2);

  /// Timeout para aguardar reconexão do oponente (60 segundos).
  static const Duration _opponentReconnectionTimeout = Duration(seconds: 60);

  /// Timer para timeout de reconexão do oponente.
  Timer? _opponentReconnectionTimer;

  PlacementController(this._socketService, {RetryConfig? retryConfig})
    : _retryConfig = retryConfig ?? const RetryConfig() {
    // Escuta mensagens do socket service através do stream
    _messageSubscription = _socketService.streamDeEstados.listen(
      (estado) {
        // Processa atualizações de estado do jogo
        _handleGameStateUpdate(estado);
      },
      onError: (error) {
        // Manipula erros do stream
        _handleStreamError(error);
      },
    );

    // Escuta status de conexão para detectar desconexões
    _socketService.streamDeStatus.listen(
      (status) {
        _handleConnectionStatusChange(status);
      },
      onError: (error) {
        debugPrint('Erro no stream de status: $error');
      },
    );

    // Inicia watchdog de conexão com delay para dar tempo de inicialização
    Future.delayed(const Duration(seconds: 30), () {
      if (!_isReconnecting) {
        _startConnectionWatchdog();
      }
    });
  }

  /// Manipula atualizações de estado do jogo.
  void _handleGameStateUpdate(EstadoJogo estado) {
    try {
      // Limpa erro anterior se recebeu atualização com sucesso
      _clearError();
      _lastNetworkActivity = DateTime.now();

      // Por enquanto, apenas log da atualização
      // TODO: Implementar lógica específica para placement quando o servidor suportar
      debugPrint('Recebida atualização de estado do jogo: ${estado.idPartida}');
    } catch (e) {
      _handleError(
        PlacementError.networkError(
          operation: 'game state update',
          originalError: e,
        ),
      );
    }
  }

  /// Manipula erros do stream de mensagens.
  void _handleStreamError(Object error) {
    final placementError = PlacementError.networkError(
      operation: 'message stream',
      originalError: error,
    );
    _handleError(placementError);
  }

  /// Manipula um erro de posicionamento.
  void _handleError(PlacementError error) {
    _lastError = error;
    debugPrint('PlacementController error: $error');
    notifyListeners();
  }

  /// Limpa o último erro.
  void _clearError() {
    if (_lastError != null) {
      _lastError = null;
      notifyListeners();
    }
  }

  /// Limpa o último erro (método público).
  void clearError() {
    _clearError();
  }

  /// Estado atual do posicionamento.
  PlacementGameState? get currentState => _currentState;

  /// Se está mostrando countdown para início do jogo.
  bool get isGameStarting => _isGameStarting;

  /// Segundos restantes do countdown.
  int get countdownSeconds => _countdownSeconds;

  /// Último erro ocorrido.
  PlacementError? get lastError => _lastError;

  /// Se está executando uma operação de retry.
  bool get isRetrying => _isRetrying;

  /// Inicializa o coordenador de múltiplas instâncias.
  void initializeMultiInstanceCoordinator(PlacementGameState initialState) {
    try {
      MultiInstanceCoordinator.instance.startMonitoring(
        gameId: initialState.gameId,
        playerId: initialState.playerId,
        onStateChanged: _handleMultiInstanceStateChange,
      );

      debugPrint(
        'PlacementController: Coordenador de múltiplas instâncias iniciado',
      );
    } catch (e) {
      debugPrint('MultiInstanceCoordinator não disponível: $e');
    }
  }

  /// Manipula mudanças de estado de outras instâncias.
  void _handleMultiInstanceStateChange(MultiInstanceGameState multiState) {
    if (_currentState == null) return;

    // Verifica se há mudanças no status do oponente
    final otherPlayers = multiState.players.keys
        .where((playerId) => playerId != _currentState!.playerId)
        .toList();

    if (otherPlayers.isNotEmpty) {
      final opponentId = otherPlayers.first;
      final opponentStatus = multiState.getPlayerStatus(opponentId);

      if (opponentStatus != null &&
          opponentStatus != _currentState!.opponentStatus) {
        debugPrint(
          'PlacementController: Status do oponente mudou para $opponentStatus',
        );

        // Atualiza o estado local com o status do oponente
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

  /// Atualiza o estado do posicionamento.
  void updateState(PlacementGameState newState) {
    _currentState = newState;

    // Atualiza atividade de rede para evitar timeout falso
    _lastNetworkActivity = DateTime.now();

    // Salva estado automaticamente
    _saveCurrentState();

    // Atualiza o coordenador de múltiplas instâncias (se disponível)
    try {
      MultiInstanceCoordinator.instance.updatePlayerStatus(
        gameId: newState.gameId,
        playerId: newState.playerId,
        status: newState.localStatus,
      );
    } catch (e) {
      // Ignora erros do coordenador durante testes
      debugPrint('MultiInstanceCoordinator não disponível: $e');
    }

    // Verifica se deve iniciar countdown
    debugPrint(
      'PlacementController: Estado atualizado - Local: ${newState.localStatus}, Oponente: ${newState.opponentStatus}, GameStarting: $_isGameStarting',
    );

    if (newState.localStatus == PlacementStatus.ready &&
        newState.opponentStatus == PlacementStatus.ready &&
        !_isGameStarting) {
      debugPrint(
        'PlacementController: Iniciando countdown - ambos jogadores prontos!',
      );
      _startGameCountdown();
    } else if (newState.localStatus == PlacementStatus.ready &&
        newState.opponentStatus != PlacementStatus.ready) {
      debugPrint(
        'PlacementController: Jogador local pronto, aguardando oponente...',
      );
    }

    notifyListeners();
  }

  /// Confirma o posicionamento do jogador local.
  Future<PlacementResult<void>> confirmPlacement() async {
    if (_currentState == null) {
      final error = PlacementError(
        type: PlacementErrorType.invalidGameState,
        userMessage: 'Estado do jogo inválido',
      );
      _handleError(error);
      return PlacementResult.failure(error);
    }

    // Valida se o posicionamento está completo
    // Convert String keys to Patente enum for validation
    final availablePiecesEnum = <Patente, int>{};
    _currentState!.availablePieces.forEach((key, value) {
      final patente = Patente.values.firstWhere(
        (p) => p.name == key,
        orElse: () => throw ArgumentError('Invalid patente: $key'),
      );
      availablePiecesEnum[patente] = value;
    });

    final validationResult = PlacementErrorHandler.validatePlacementCompletion(
      availablePieces: availablePiecesEnum,
    );

    if (validationResult.isFailure) {
      _handleError(validationResult.error!);
      return validationResult;
    }

    if (!_currentState!.canConfirm) {
      // Convert String keys to Patente enum for error reporting
      final missingTypes = <Patente>[];
      _currentState!.availablePieces.entries
          .where((entry) => entry.value > 0)
          .forEach((entry) {
            final patente = Patente.values.firstWhere(
              (p) => p.name == entry.key,
              orElse: () =>
                  throw ArgumentError('Invalid patente: ${entry.key}'),
            );
            missingTypes.add(patente);
          });

      final error = PlacementError.incompletePlacement(
        remainingPieces: _currentState!.availablePieces.values.fold(
          0,
          (sum, count) => sum + count,
        ),
        missingTypes: missingTypes,
      );
      _handleError(error);
      return PlacementResult.failure(error);
    }

    // Executa confirmação com retry automático
    return await PlacementErrorHandler.executeWithRetry(
      () => _executeConfirmPlacement(),
      retryConfig: _retryConfig,
      operationName: 'confirm placement',
    );
  }

  /// Executa a confirmação do posicionamento.
  Future<void> _executeConfirmPlacement() async {
    if (_currentState == null) {
      throw PlacementError(
        type: PlacementErrorType.invalidGameState,
        userMessage: 'Estado do jogo inválido',
      );
    }

    try {
      _clearError();

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

      // Simula envio para o servidor com timeout
      await _sendMessageWithTimeout(message);

      // Se oponente já está pronto, inicia countdown
      if (_currentState!.opponentStatus == PlacementStatus.ready) {
        debugPrint(
          'PlacementController: Oponente já estava pronto, iniciando countdown',
        );
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

        // O coordenador de múltiplas instâncias cuidará da sincronização
        debugPrint(
          'PlacementController: Aguardando oponente via coordenador de múltiplas instâncias...',
        );

        // SIMULAÇÃO DE OPONENTE PARA TESTE (remove quando tiver servidor real)
        _simulateOpponentAfterDelay();
      }
    } catch (e) {
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

      // Re-lança o erro para ser capturado pelo retry handler
      rethrow;
    }
  }

  /// Envia mensagem para o servidor com timeout.
  Future<void> _sendMessageWithTimeout(PlacementMessage message) async {
    // TODO: Implementar envio real quando GameSocketService suportar
    // Por enquanto, simula envio com possível timeout

    debugPrint('Enviando mensagem de placement: ${message.toJson()}');

    // Simula delay de rede
    await Future.delayed(const Duration(milliseconds: 500));

    // Simula possível timeout (para teste)
    // if (Random().nextBool()) {
    //   throw TimeoutException('Server timeout', const Duration(seconds: 30));
    // }
  }

  /// Inicia o countdown para início do jogo.
  void _startGameCountdown() {
    if (_isGameStarting) {
      debugPrint('PlacementController: Countdown já está em andamento');
      return;
    }

    debugPrint('PlacementController: Iniciando countdown de 3 segundos');
    _isGameStarting = true;
    _countdownSeconds = 3;
    notifyListeners();

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _countdownSeconds--;
      debugPrint('PlacementController: Countdown: $_countdownSeconds');
      notifyListeners();

      if (_countdownSeconds <= 0) {
        timer.cancel();
        debugPrint('PlacementController: Countdown finalizado, iniciando jogo');
        _finishGameStart();
      }
    });
  }

  /// Finaliza o countdown e inicia o jogo.
  void _finishGameStart() {
    debugPrint('PlacementController: Finalizando countdown e iniciando jogo');
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

      debugPrint('PlacementController: Atualizando estado para gameInProgress');
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

  /// Valida uma operação de posicionamento de peça.
  PlacementResult<void> validatePiecePlacement({
    required PosicaoTabuleiro position,
    required Patente pieceType,
  }) {
    if (_currentState == null) {
      return PlacementResult.failure(
        PlacementError(
          type: PlacementErrorType.invalidGameState,
          userMessage: 'Estado do jogo inválido',
        ),
      );
    }

    // Atualiza atividade de rede para mostrar que o usuário está ativo
    _lastNetworkActivity = DateTime.now();

    // Convert String keys to Patente enum for validation
    final availablePiecesEnum = <Patente, int>{};
    _currentState!.availablePieces.forEach((key, value) {
      final patente = Patente.values.firstWhere(
        (p) => p.name == key,
        orElse: () => throw ArgumentError('Invalid patente: $key'),
      );
      availablePiecesEnum[patente] = value;
    });

    return PlacementErrorHandler.validatePlacementOperation(
      position: position,
      playerArea: _currentState!.playerArea,
      selectedPiece: pieceType,
      availablePieces: availablePiecesEnum,
      placedPieces: _currentState!.placedPieces,
    );
  }

  /// Executa posicionamento de peça com validação.
  PlacementResult<void> placePiece({
    required PosicaoTabuleiro position,
    required Patente pieceType,
  }) {
    // Atualiza atividade de rede para mostrar que o usuário está ativo
    _lastNetworkActivity = DateTime.now();

    // Valida a operação
    final validation = validatePiecePlacement(
      position: position,
      pieceType: pieceType,
    );

    if (validation.isFailure) {
      _handleError(validation.error!);
      return validation;
    }

    try {
      _clearError();

      // Executa o posicionamento
      // Esta lógica será implementada pela UI que chama este método
      // O controller apenas valida e reporta erros

      return PlacementResult.success(null);
    } catch (e) {
      final error = PlacementError.networkError(
        operation: 'place piece',
        originalError: e,
      );
      _handleError(error);
      return PlacementResult.failure(error);
    }
  }

  /// Executa retry de uma operação falhada.
  Future<PlacementResult<T>> retryOperation<T>(
    Future<PlacementResult<T>> Function() operation,
  ) async {
    if (_isRetrying) {
      return PlacementResult.failure(
        PlacementError(
          type: PlacementErrorType.invalidGameState,
          userMessage: 'Operação de retry já em andamento',
        ),
      );
    }

    _isRetrying = true;
    notifyListeners();

    try {
      final result = await operation();
      return result;
    } finally {
      _isRetrying = false;
      notifyListeners();
    }
  }

  /// Reseta o estado do posicionamento.
  void reset() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
    _isGameStarting = false;
    _countdownSeconds = 3;
    _currentState = null;
    _lastError = null;
    _isRetrying = false;
    notifyListeners();
  }

  // ===== DISCONNECTION HANDLING METHODS =====

  /// Inicia o watchdog de conexão para detectar desconexões.
  void _startConnectionWatchdog() {
    _connectionWatchdog?.cancel();
    _lastNetworkActivity = DateTime.now();

    _connectionWatchdog = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (_currentState != null && _lastNetworkActivity != null) {
        final timeSinceLastActivity = DateTime.now().difference(
          _lastNetworkActivity!,
        );

        // Durante o posicionamento, usa timeout mais longo
        final timeoutDuration =
            _currentState!.gamePhase == GamePhase.piecePlacement
            ? const Duration(minutes: 5) // 5 minutos durante posicionamento
            : _connectionTimeout; // 2 minutos durante jogo normal

        if (timeSinceLastActivity > timeoutDuration) {
          _handleConnectionTimeout();
        }
      }
    });
  }

  /// Manipula mudanças no status de conexão.
  void _handleConnectionStatusChange(StatusConexao status) {
    _lastNetworkActivity = DateTime.now();

    switch (status) {
      case StatusConexao.desconectado:
      case StatusConexao.erro:
        _handleDisconnection();
        break;
      case StatusConexao.conectado:
      case StatusConexao.jogando:
        if (_isReconnecting) {
          _handleReconnectionSuccess();
        }
        break;
      case StatusConexao.oponenteDesconectado:
        _handleOpponentDisconnection();
        break;
      default:
        break;
    }
  }

  /// Manipula timeout de conexão.
  void _handleConnectionTimeout() {
    if (_currentState != null && !_isReconnecting) {
      // Durante o posicionamento, seja mais conservador com timeouts
      if (_currentState!.gamePhase == GamePhase.piecePlacement) {
        debugPrint(
          'Timeout de conexão detectado durante posicionamento - verificando se é necessário reconectar',
        );

        // Só considera desconexão se realmente passou muito tempo sem atividade
        final timeSinceLastActivity = DateTime.now().difference(
          _lastNetworkActivity!,
        );
        if (timeSinceLastActivity > const Duration(minutes: 10)) {
          debugPrint('Timeout confirmado - iniciando processo de reconexão');
          _handleDisconnection();
        } else {
          debugPrint(
            'Timeout ignorado - usuário ainda pode estar posicionando peças',
          );
          // Atualiza a atividade para dar mais tempo
          _lastNetworkActivity = DateTime.now();
        }
      } else {
        debugPrint('Timeout de conexão detectado durante jogo');
        _handleDisconnection();
      }
    }
  }

  /// Manipula desconexão durante posicionamento.
  void _handleDisconnection() {
    if (_currentState == null || _isReconnecting) return;

    debugPrint('Desconexão detectada durante posicionamento');
    _isReconnecting = true;

    // Salva estado atual
    _saveCurrentState();

    // Notifica sobre desconexão
    final error = PlacementError(
      type: PlacementErrorType.networkError,
      userMessage: 'Conexão perdida. Tentando reconectar...',
    );
    _handleError(error);

    // Inicia tentativas de reconexão
    _startReconnectionAttempts();

    notifyListeners();
  }

  /// Salva o estado atual para recuperação após reconexão.
  Future<void> _saveCurrentState() async {
    if (_currentState != null) {
      final success = await PlacementPersistence.savePlacementState(
        _currentState!,
      );
      if (success) {
        debugPrint('Estado de posicionamento salvo com sucesso');
      } else {
        debugPrint('Falha ao salvar estado de posicionamento');
      }
    }
  }

  /// Inicia tentativas de reconexão.
  void _startReconnectionAttempts() {
    // Implementa tentativas de reconexão com backoff exponencial
    _attemptReconnection(1);
  }

  /// Tenta reconectar com backoff exponencial.
  void _attemptReconnection(int attempt) async {
    if (!_isReconnecting || attempt > 5) {
      // Máximo de 5 tentativas
      if (_isReconnecting) {
        _handleReconnectionFailure();
      }
      return;
    }

    debugPrint('Tentativa de reconexão $attempt/5');

    try {
      // TODO: Obter URL do servidor de configuração
      const serverUrl = 'ws://localhost:8083'; // Placeholder

      // TODO: Obter nome do usuário de UserPreferences
      // final userName = await UserPreferences.getUserName();

      final success = await _socketService.reconnectDuringPlacement(
        serverUrl,
        // nomeUsuario: userName,
      );

      if (success && _isReconnecting) {
        _handleReconnectionSuccess();
      } else if (_isReconnecting) {
        // Aguarda antes da próxima tentativa (backoff exponencial)
        final delay = Duration(seconds: (attempt * 2).clamp(2, 30));
        Timer(delay, () => _attemptReconnection(attempt + 1));
      }
    } catch (e) {
      debugPrint('Erro na tentativa de reconexão: $e');

      if (_isReconnecting) {
        // Aguarda antes da próxima tentativa
        final delay = Duration(seconds: (attempt * 2).clamp(2, 30));
        Timer(delay, () => _attemptReconnection(attempt + 1));
      }
    }
  }

  /// Manipula falha completa na reconexão.
  void _handleReconnectionFailure() {
    debugPrint('Falha completa na reconexão após múltiplas tentativas');

    _isReconnecting = false;

    final error = PlacementError(
      type: PlacementErrorType.networkError,
      userMessage:
          'Não foi possível reconectar. Verifique sua conexão e tente novamente.',
    );
    _handleError(error);

    notifyListeners();
  }

  /// Manipula sucesso na reconexão.
  void _handleReconnectionSuccess() {
    if (!_isReconnecting) return;

    debugPrint('Reconexão bem-sucedida');
    _isReconnecting = false;
    _clearError();

    // Restaura estado salvo
    _restoreStateAfterReconnection();

    notifyListeners();
  }

  /// Restaura estado após reconexão bem-sucedida.
  Future<void> _restoreStateAfterReconnection() async {
    try {
      final savedState = await PlacementPersistence.loadPlacementState();

      if (savedState != null) {
        debugPrint('Estado de posicionamento restaurado após reconexão');
        updateState(savedState);

        // Sincroniza com servidor
        await _syncStateWithServer(savedState);
      } else {
        debugPrint('Nenhum estado salvo encontrado após reconexão');
      }
    } catch (e) {
      debugPrint('Erro ao restaurar estado após reconexão: $e');

      final error = PlacementError(
        type: PlacementErrorType.invalidGameState,
        userMessage: 'Erro ao restaurar posicionamento. Reinicie o jogo.',
      );
      _handleError(error);
    }
  }

  /// Sincroniza estado local com servidor após reconexão.
  Future<void> _syncStateWithServer(PlacementGameState state) async {
    try {
      // TODO: Implementar sincronização real quando servidor suportar
      // Por enquanto, apenas simula sincronização

      debugPrint('Sincronizando estado com servidor...');

      // Simula delay de sincronização
      await Future.delayed(const Duration(milliseconds: 500));

      debugPrint('Estado sincronizado com servidor');
    } catch (e) {
      debugPrint('Erro ao sincronizar com servidor: $e');

      final error = PlacementError.networkError(
        operation: 'sync state',
        originalError: e,
      );
      _handleError(error);
    }
  }

  /// Manipula desconexão do oponente.
  void _handleOpponentDisconnection() {
    if (_currentState == null) return;

    debugPrint('Oponente desconectou durante posicionamento');

    // Atualiza status do oponente
    final updatedState = PlacementGameState(
      gameId: _currentState!.gameId,
      playerId: _currentState!.playerId,
      availablePieces: _currentState!.availablePieces,
      placedPieces: _currentState!.placedPieces,
      playerArea: _currentState!.playerArea,
      localStatus: _currentState!.localStatus,
      opponentStatus: PlacementStatus.placing, // Reset para placing
      selectedPieceType: _currentState!.selectedPieceType,
      gamePhase: _currentState!.gamePhase,
    );

    updateState(updatedState);

    // Inicia timer para aguardar reconexão do oponente
    _startOpponentReconnectionTimer();

    // Notifica usuário
    final error = PlacementError(
      type: PlacementErrorType.networkError,
      userMessage: 'Oponente desconectou. Aguardando reconexão...',
    );
    _handleError(error);
  }

  /// Inicia timer para aguardar reconexão do oponente.
  void _startOpponentReconnectionTimer() {
    _opponentReconnectionTimer?.cancel();

    _opponentReconnectionTimer = Timer(_opponentReconnectionTimeout, () {
      _handleOpponentReconnectionTimeout();
    });
  }

  /// Manipula timeout de reconexão do oponente.
  void _handleOpponentReconnectionTimeout() {
    debugPrint('Timeout de reconexão do oponente');

    // Limpa estado salvo
    PlacementPersistence.clearPlacementState();

    // Notifica que deve retornar para matchmaking
    final error = PlacementError(
      type: PlacementErrorType.opponentDisconnected,
      userMessage:
          'Oponente não reconectou. Retornando para busca de oponente.',
    );
    _handleError(error);

    // Reset do estado
    reset();
  }

  /// Restaura estado salvo ao inicializar.
  Future<PlacementGameState?> restoreSavedState() async {
    try {
      final savedState = await PlacementPersistence.loadPlacementState();

      if (savedState != null) {
        debugPrint('Estado de posicionamento restaurado da persistência');
        updateState(savedState);
        return savedState;
      }

      return null;
    } catch (e) {
      debugPrint('Erro ao restaurar estado salvo: $e');
      return null;
    }
  }

  /// Limpa estado persistido.
  Future<void> clearPersistedState() async {
    await PlacementPersistence.clearPlacementState();
  }

  /// Verifica se há estado salvo válido.
  Future<bool> hasValidSavedState() async {
    return await PlacementPersistence.hasValidPlacementState();
  }

  /// Se está tentando reconectar.
  bool get isReconnecting => _isReconnecting;

  /// Atualiza a atividade de rede para evitar timeout durante interação do usuário.
  void updateNetworkActivity() {
    _lastNetworkActivity = DateTime.now();
  }

  /// Simula o oponente ficando pronto (para teste/desenvolvimento).
  /// TODO: Remover quando integração real com servidor estiver funcionando.
  void simulateOpponentReady() {
    if (_currentState == null) return;

    debugPrint('PlacementController: Simulando oponente ficando pronto...');

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
  }

  /// Força uma tentativa manual de reconexão.
  Future<bool> attemptManualReconnection() async {
    if (_isReconnecting) {
      return false; // Já está tentando reconectar
    }

    debugPrint('Iniciando reconexão manual');

    _isReconnecting = true;
    _clearError();
    notifyListeners();

    try {
      // TODO: Obter URL do servidor de configuração
      const serverUrl = 'ws://localhost:8083'; // Placeholder

      // TODO: Obter nome do usuário de UserPreferences
      // final userName = await UserPreferences.getUserName();

      final success = await _socketService.reconnectDuringPlacement(
        serverUrl,
        // nomeUsuario: userName,
      );

      if (success) {
        _handleReconnectionSuccess();
        return true;
      } else {
        _isReconnecting = false;

        final error = PlacementError(
          type: PlacementErrorType.networkError,
          userMessage: 'Falha na reconexão. Verifique sua conexão.',
        );
        _handleError(error);

        notifyListeners();
        return false;
      }
    } catch (e) {
      _isReconnecting = false;

      final error = PlacementError.networkError(
        operation: 'manual reconnection',
        originalError: e,
      );
      _handleError(error);

      notifyListeners();
      return false;
    }
  }

  /// Simula um oponente ficando pronto após um delay (para testes).
  /// REMOVER quando tiver servidor real.
  void _simulateOpponentAfterDelay() {
    Timer(const Duration(seconds: 3), () {
      if (_currentState != null &&
          _currentState!.localStatus == PlacementStatus.waiting &&
          _currentState!.opponentStatus != PlacementStatus.ready) {
        debugPrint('🤖 SIMULAÇÃO: Oponente ficou pronto!');

        // Simula oponente ficando pronto
        final simulatedState = PlacementGameState(
          gameId: _currentState!.gameId,
          playerId: _currentState!.playerId,
          availablePieces: _currentState!.availablePieces,
          placedPieces: _currentState!.placedPieces,
          playerArea: _currentState!.playerArea,
          localStatus: PlacementStatus.ready,
          opponentStatus: PlacementStatus.ready,
          selectedPieceType: _currentState!.selectedPieceType,
          gamePhase: _currentState!.gamePhase,
        );

        updateState(simulatedState);
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _messageSubscription?.cancel();
    _connectionWatchdog?.cancel();
    _opponentReconnectionTimer?.cancel();

    try {
      MultiInstanceCoordinator.instance.stopMonitoring();
    } catch (e) {
      debugPrint('Erro ao parar MultiInstanceCoordinator: $e');
    }

    super.dispose();
  }
}
