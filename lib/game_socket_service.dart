import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import './modelos_jogo.dart';
import './providers.dart';

/// Encapsula a comunicação com o servidor WebSocket do jogo.
class GameSocketService {
  WebSocketChannel? _channel;
  final _estadoController = StreamController<EstadoJogo>.broadcast();
  final _erroController = StreamController<String>.broadcast();
  final _statusController = StreamController<StatusConexao>.broadcast();
  final _placementController =
      StreamController<Map<String, dynamic>>.broadcast();
  Timer? _connectionTimeout;
  Timer? _nameVerificationTimer;
  Timer? _heartbeatTimer;
  bool _isConnecting = false;
  bool _isConnected = false;
  bool _nameConfirmed = false;
  String? _pendingUserName;
  DateTime? _lastMessageReceived;
  bool _isInPlacementPhase = true; // Controla se está na fase de posicionamento

  /// Stream que emite o [EstadoJogo] mais recente recebido do servidor.
  Stream<EstadoJogo> get streamDeEstados => _estadoController.stream;

  /// Stream que emite mensagens de erro recebidas do servidor.
  Stream<String> get streamDeErros => _erroController.stream;

  /// Stream que emite o status da conexão.
  Stream<StatusConexao> get streamDeStatus => _statusController.stream;

  /// Stream que emite mensagens de placement recebidas do servidor.
  Stream<Map<String, dynamic>> get streamDePlacement =>
      _placementController.stream;

  /// Conecta-se ao servidor WebSocket e começa a ouvir por mensagens.
  void connect(String url, {String? nomeUsuario}) {
    if (_isConnecting) {
      return;
    }

    _isConnecting = true;
    _isConnected = false;
    _nameConfirmed = false;
    _pendingUserName = nomeUsuario;

    // Emite status de conectando
    _statusController.add(StatusConexao.conectando);

    // Conecta de forma assíncrona para não travar a UI
    _connectAsync(url, nomeUsuario);
  }

  /// Conecta de forma assíncrona com timeout e tratamento robusto de erros
  Future<void> _connectAsync(String url, String? nomeUsuario) async {
    // Cancela timeout anterior se existir
    _connectionTimeout?.cancel();

    // Define timeout de 10 segundos
    _connectionTimeout = Timer(const Duration(seconds: 10), () {
      if (_isConnecting) {
        _handleConnectionError(
          'Timeout: Servidor não responde. Verifique se o servidor está ativo.',
        );
      }
    });

    // Usa runZonedGuarded para capturar TODAS as exceções, incluindo as assíncronas
    runZonedGuarded(
      () {
        _channel = WebSocketChannel.connect(Uri.parse(url));

        // Configura listeners
        _channel!.stream.listen(
          (message) {
            // Conexão bem-sucedida, cancela timeout
            _connectionTimeout?.cancel();
            _isConnecting = false;

            // Marca como conectado na primeira mensagem recebida
            if (!_isConnected) {
              _isConnected = true;
              _statusController.add(StatusConexao.conectado);

              // Envia o nome imediatamente quando confirma conexão
              if (nomeUsuario != null) {
                debugPrint(
                  '🔄 Conexão confirmada, reenviando nome: $nomeUsuario',
                );
                _sendMessage({
                  'type': 'definirNome',
                  'payload': {'nome': nomeUsuario},
                });
              }

              // Inicia monitoramento de heartbeat
              _startHeartbeatMonitoring();
            }

            // Atualiza timestamp da última mensagem recebida
            _lastMessageReceived = DateTime.now();

            try {
              final data = jsonDecode(message);
              final type = data['type'];

              // Qualquer mensagem do servidor indica que a conexão está funcionando
              // Se recebemos mensagens estruturadas, o nome provavelmente foi aceito
              if (!_nameConfirmed &&
                  (type == 'atualizacaoEstado' ||
                      type.startsWith('PLACEMENT_') ||
                      type == 'mensagemServidor')) {
                debugPrint(
                  '✅ Nome implicitamente confirmado - servidor está respondendo',
                );
                _nameConfirmed = true;
                _nameVerificationTimer?.cancel();
              }

              debugPrint('📨 Mensagem recebida do servidor: $type');
              debugPrint('📨 Dados completos: $data');

              if (type == 'atualizacaoEstado') {
                final estado = EstadoJogo.fromJson(data['payload']);
                _estadoController.add(estado);
                // Quando recebe estado do jogo, significa que saiu do posicionamento
                if (_isInPlacementPhase) {
                  debugPrint(
                    '🎯 Detectada mudança para fase de jogo via atualizacaoEstado',
                  );
                  setPlacementPhase(false);
                }
                _statusController.add(StatusConexao.jogando);
              } else if (type == 'erroMovimento') {
                final erro =
                    data['payload']?['mensagem'] ??
                    'Erro desconhecido do servidor.';
                _erroController.add(erro);
              } else if (type == 'PLACEMENT_OPPONENT_DISCONNECTED') {
                _statusController.add(StatusConexao.oponenteDesconectado);
                final mensagem =
                    data['data']?['message'] ?? 'Oponente desconectou';
                _erroController.add(mensagem);
              } else if (type == 'PLACEMENT_OPPONENT_RECONNECTED') {
                _statusController.add(StatusConexao.conectado);
                final mensagem =
                    data['data']?['message'] ?? 'Oponente reconectou';
                _erroController.add(mensagem);
              } else if (type == 'PLACEMENT_OPPONENT_ABANDONED') {
                _statusController.add(StatusConexao.oponenteDesconectado);
                final mensagem =
                    data['data']?['message'] ?? 'Oponente abandonou o jogo';
                _erroController.add(mensagem);
              } else if (type == 'PLACEMENT_UPDATE' ||
                  type == 'PLACEMENT_OPPONENT_READY' ||
                  type == 'PLACEMENT_GAME_START') {
                // Processa mensagens de placement
                debugPrint('📨 Mensagem de placement recebida: $type');

                // Garante que está na fase de posicionamento
                if (!_isInPlacementPhase && type != 'PLACEMENT_GAME_START') {
                  debugPrint('🎯 Detectada volta para fase de posicionamento');
                  setPlacementPhase(true);
                }

                // PLACEMENT_GAME_START indica fim do posicionamento
                if (type == 'PLACEMENT_GAME_START') {
                  debugPrint(
                    '🎯 Detectado fim do posicionamento via PLACEMENT_GAME_START',
                  );
                  setPlacementPhase(false);
                }

                _placementController.add(data);
              } else if (type == 'nomeDefinido' || type == 'nomeAtualizado') {
                debugPrint('✅ Confirmação de nome recebida do servidor');
                _nameConfirmed = true;
                _nameVerificationTimer?.cancel();
                final nomeConfirmado =
                    data['payload']?['nome'] ?? data['data']?['nome'];
                if (nomeConfirmado != null) {
                  debugPrint(
                    '✅ Nome confirmado pelo servidor: $nomeConfirmado',
                  );
                }
              } else if (type == 'OPPONENT_DISCONNECTED' ||
                  type == 'GAME_OPPONENT_DISCONNECTED' ||
                  type == 'oponenteDesconectou') {
                debugPrint('🚨 Oponente desconectou durante o jogo');
                _statusController.add(StatusConexao.oponenteDesconectado);
                final mensagem =
                    data['data']?['message'] ??
                    data['payload']?['mensagem'] ??
                    'Seu oponente saiu da partida';
                _erroController.add(mensagem);
              } else if (type == 'GAME_ABANDONED' || type == 'jogoAbandonado') {
                debugPrint('🚨 Jogo foi abandonado pelo oponente');
                _statusController.add(StatusConexao.oponenteDesconectado);
                final mensagem =
                    data['data']?['message'] ??
                    data['payload']?['mensagem'] ??
                    'O jogo foi abandonado pelo oponente';
                _erroController.add(mensagem);
              } else if (type == 'mensagemServidor') {
                final mensagem = data['payload'].toString();
                debugPrint('📢 Mensagem do servidor: $mensagem');

                // Verifica se o oponente desconectou
                if (mensagem.contains('oponente desconectou') ||
                    mensagem.contains('O oponente desconectou') ||
                    mensagem.contains('opponent disconnected') ||
                    mensagem.contains('abandonou') ||
                    mensagem.contains('saiu da partida')) {
                  debugPrint(
                    '🚨 Desconexão detectada via mensagem do servidor',
                  );
                  _statusController.add(StatusConexao.oponenteDesconectado);
                  _erroController.add('O oponente saiu da partida.');
                }
                // Mantém status conectado quando recebe mensagens do servidor
                else if (_isConnected && mensagem.contains('Aguardando')) {
                  _statusController.add(StatusConexao.conectado);
                }
              }
            } catch (e) {
              _erroController.add('Erro ao ler dados do servidor.');
            }
          },
          onError: (error) {
            _handleConnectionError(_getErrorMessage(error));
          },
          onDone: () {
            _connectionTimeout?.cancel();
            _isConnecting = false;
            _isConnected = false;
            _statusController.add(StatusConexao.desconectado);
          },
        );

        // Envia o nome do usuário assim que conecta
        if (nomeUsuario != null) {
          debugPrint('🏷️ Enviando nome do usuário: $nomeUsuario');

          // Envia imediatamente após estabelecer conexão
          _sendMessage({
            'type': 'definirNome',
            'payload': {'nome': nomeUsuario},
          });
          debugPrint('✅ Mensagem definirNome enviada imediatamente');

          // Envia novamente após um pequeno delay para garantir (apenas uma vez)
          Future.delayed(const Duration(milliseconds: 500), () {
            if (_channel != null && !_nameConfirmed) {
              _sendMessage({
                'type': 'definirNome',
                'payload': {'nome': nomeUsuario},
              });
              debugPrint('✅ Mensagem definirNome reenviada (confirmação)');
            } else if (_nameConfirmed) {
              debugPrint('✅ Nome já confirmado, não reenviando');
            }
          });

          // Inicia timer para verificar se o nome foi confirmado
          _startNameVerificationTimer(nomeUsuario);
        } else {
          debugPrint('⚠️ Nome do usuário é null, não enviando');
        }
      },
      (error, stackTrace) {
        // Captura TODAS as exceções não tratadas
        _handleConnectionError(_getErrorMessage(error));
      },
    );
  }

  /// Trata erros de conexão de forma centralizada
  void _handleConnectionError(String mensagem) {
    _connectionTimeout?.cancel();
    _isConnecting = false;
    _isConnected = false;

    // Fecha canal se existir
    try {
      _channel?.sink.close();
    } catch (e) {
      // Ignora erros ao fechar canal
    }
    _channel = null;

    _statusController.add(StatusConexao.erro);
    _erroController.add(mensagem);
  }

  /// Converte erros em mensagens amigáveis
  String _getErrorMessage(dynamic error) {
    final errorStr = error.toString().toLowerCase();

    if (errorStr.contains('refused') || errorStr.contains('recusou')) {
      return 'Servidor indisponível. Verifique se o servidor está rodando.';
    } else if (errorStr.contains('timeout')) {
      return 'Timeout: Servidor não responde. Verifique se o servidor está ativo.';
    } else if (errorStr.contains('socket')) {
      return 'Erro de rede. Verifique sua conexão e se o servidor está ativo.';
    } else {
      return 'Não foi possível conectar ao servidor.';
    }
  }

  /// Envia uma mensagem de forma segura
  void _sendMessage(Map<String, dynamic> message) {
    try {
      if (_channel != null) {
        final messageJson = jsonEncode(message);
        debugPrint('📤 Enviando mensagem: $messageJson');
        _channel!.sink.add(messageJson);
        debugPrint('✅ Mensagem enviada com sucesso');
      } else {
        debugPrint(
          '❌ Canal WebSocket é null, não foi possível enviar mensagem',
        );
      }
    } catch (e) {
      debugPrint('❌ Erro ao enviar mensagem: $e');

      // Tenta reenviar após um delay se for uma mensagem crítica como definirNome
      if (message['type'] == 'definirNome') {
        debugPrint('🔄 Tentando reenviar nome após erro...');
        Future.delayed(const Duration(milliseconds: 1000), () {
          if (_channel != null) {
            try {
              final messageJson = jsonEncode(message);
              _channel!.sink.add(messageJson);
              debugPrint('✅ Nome reenviado com sucesso após erro');
            } catch (retryError) {
              debugPrint('❌ Falha ao reenviar nome: $retryError');
            }
          }
        });
      }

      _erroController.add('Erro ao enviar dados para o servidor.');
    }
  }

  /// Envia uma intenção de movimento para o servidor.
  void enviarMovimento(String idPeca, PosicaoTabuleiro novaPosicao) {
    _sendMessage({
      'type': 'moverPeca',
      'payload': {'idPeca': idPeca, 'novaPosicao': novaPosicao.toJson()},
    });
  }

  /// Envia o nome do usuário para o servidor
  void enviarNome(String nome) {
    debugPrint('🏷️ enviarNome chamado com: $nome');
    _enviarNomeComRetry(nome, 0);
  }

  /// Envia o nome com retry automático
  void _enviarNomeComRetry(String nome, int tentativa) {
    if (tentativa >= 5) {
      debugPrint('❌ Máximo de tentativas de envio de nome atingido');
      return;
    }

    try {
      if (_channel != null) {
        final message = {
          'type': 'definirNome',
          'payload': {'nome': nome},
        };
        final messageJson = jsonEncode(message);
        debugPrint(
          '📤 Enviando nome (tentativa ${tentativa + 1}): $messageJson',
        );
        _channel!.sink.add(messageJson);
        debugPrint('✅ Nome enviado com sucesso (tentativa ${tentativa + 1})');
      } else {
        debugPrint(
          '❌ Canal null na tentativa ${tentativa + 1}, reagendando...',
        );
        Future.delayed(Duration(milliseconds: 300 * (tentativa + 1)), () {
          _enviarNomeComRetry(nome, tentativa + 1);
        });
      }
    } catch (e) {
      debugPrint('❌ Erro ao enviar nome (tentativa ${tentativa + 1}): $e');
      Future.delayed(Duration(milliseconds: 500 * (tentativa + 1)), () {
        _enviarNomeComRetry(nome, tentativa + 1);
      });
    }
  }

  /// Reconecta ao servidor
  void reconnect(String url, {String? nomeUsuario}) {
    // Cancela timeouts anteriores
    _connectionTimeout?.cancel();
    _nameVerificationTimer?.cancel();
    _heartbeatTimer?.cancel();
    _isConnecting = false;

    // Reseta estado de confirmação
    resetNameConfirmation();
    _pendingUserName = nomeUsuario;

    // Fecha a conexão atual se existir
    try {
      _channel?.sink.close();
    } catch (e) {
      // Ignora erros ao fechar conexão anterior
    }

    _channel = null;

    // Aguarda um pouco antes de tentar reconectar
    Future.delayed(const Duration(milliseconds: 500), () {
      connect(url, nomeUsuario: nomeUsuario);
    });
  }

  /// Reconecta especificamente durante a fase de posicionamento
  Future<bool> reconnectDuringPlacement(
    String url, {
    String? nomeUsuario,
  }) async {
    debugPrint('🔄 Iniciando reconexão durante posicionamento...');

    try {
      // Emite status de reconectando
      _statusController.add(StatusConexao.conectando);

      // Limpa estado anterior mas preserva informações de posicionamento
      try {
        _channel?.sink.close();
      } catch (e) {
        // Ignora erros ao fechar conexão anterior
      }

      _channel = null;
      _isConnecting = false;
      _isConnected = false;
      _nameConfirmed = false;

      // Força fase de posicionamento para reconexão
      _isInPlacementPhase = true;
      debugPrint('🎯 Forçando fase de posicionamento para reconexão');

      // Aguarda um pouco antes de reconectar
      await Future.delayed(const Duration(milliseconds: 1000));

      // Tenta reconectar
      connect(url, nomeUsuario: nomeUsuario);

      // Aguarda conexão, nome confirmado ou timeout
      final completer = Completer<bool>();
      late StreamSubscription statusSubscription;
      late StreamSubscription placementSubscription;

      // Escuta mudanças de status
      statusSubscription = streamDeStatus.listen((status) {
        debugPrint('🔄 Status durante reconexão: $status');

        if (status == StatusConexao.conectado && _nameConfirmed) {
          debugPrint('✅ Reconexão bem-sucedida - conectado e nome confirmado');
          statusSubscription.cancel();
          placementSubscription.cancel();
          completer.complete(true);
        } else if (status == StatusConexao.erro) {
          debugPrint('❌ Erro durante reconexão');
          statusSubscription.cancel();
          placementSubscription.cancel();
          completer.complete(false);
        }
      });

      // Escuta mensagens de placement para confirmar reconexão à sessão
      placementSubscription = streamDePlacement.listen((data) {
        debugPrint(
          '📨 Mensagem de placement recebida durante reconexão: ${data['type']}',
        );

        // Se recebeu mensagem de placement, significa que reconectou à sessão
        if (data['type'] == 'PLACEMENT_UPDATE' ||
            data['type'] == 'PLACEMENT_OPPONENT_READY' ||
            data['type'] == 'PLACEMENT_GAME_START') {
          debugPrint('✅ Reconexão à sessão de posicionamento confirmada');
          statusSubscription.cancel();
          placementSubscription.cancel();
          completer.complete(true);
        }
      });

      // Timeout de 15 segundos para reconexão (mais tempo para posicionamento)
      Timer(const Duration(seconds: 15), () {
        if (!completer.isCompleted) {
          debugPrint('⏰ Timeout na reconexão durante posicionamento');
          statusSubscription.cancel();
          placementSubscription.cancel();
          completer.complete(false);
        }
      });

      final result = await completer.future;
      debugPrint('🔄 Resultado da reconexão: $result');
      return result;
    } catch (e) {
      debugPrint('❌ Erro na reconexão durante posicionamento: $e');
      _statusController.add(StatusConexao.erro);
      return false;
    }
  }

  /// Envia mensagem de posicionamento
  void enviarMensagemPlacement(Map<String, dynamic> message) {
    _sendMessage(message);
  }

  /// Força o reenvio do nome (usado quando o pareamento não progride)
  void forcarReenvioNome(String nome) {
    if (_nameConfirmed) {
      debugPrint('✅ Nome já confirmado, não é necessário reenviar');
      return;
    }

    debugPrint('🔄 Forçando reenvio do nome: $nome');
    _nameConfirmed = false;
    _pendingUserName = nome;
    _enviarNomeComRetry(nome, 0);
    _startNameVerificationTimer(nome);
  }

  /// Verifica se o nome foi confirmado pelo servidor
  bool get isNameConfirmed => _nameConfirmed;

  /// Obtém o nome pendente de confirmação
  String? get pendingUserName => _pendingUserName;

  /// Reseta o estado de confirmação do nome (usado em reconexões)
  void resetNameConfirmation() {
    debugPrint('🔄 Resetando estado de confirmação do nome');
    _nameConfirmed = false;
    _nameVerificationTimer?.cancel();
    // Volta para fase de posicionamento em reconexões
    _isInPlacementPhase = true;
  }

  /// Obtém informações completas sobre o status da conexão
  Map<String, dynamic> getConnectionStatus() {
    return {
      'isConnecting': _isConnecting,
      'isConnected': _isConnected,
      'nameConfirmed': _nameConfirmed,
      'pendingUserName': _pendingUserName,
      'hasChannel': _channel != null,
      'hasNameTimer':
          _nameVerificationTimer != null && _nameVerificationTimer!.isActive,
      'hasConnectionTimer':
          _connectionTimeout != null && _connectionTimeout!.isActive,
      'isInPlacementPhase': _isInPlacementPhase,
      'heartbeatTimeout': _getHeartbeatTimeout(),
    };
  }

  /// Inicia timer para verificar se o nome foi confirmado pelo servidor
  void _startNameVerificationTimer(String nomeUsuario) {
    _nameVerificationTimer?.cancel();

    // Timer menos agressivo - verifica a cada 5 segundos e para após 3 tentativas
    int tentativas = 0;
    const maxTentativas = 3;

    _nameVerificationTimer = Timer.periodic(const Duration(seconds: 5), (
      timer,
    ) {
      if (_nameConfirmed) {
        debugPrint('✅ Nome confirmado, parando timer de verificação');
        timer.cancel();
        return;
      }

      if (tentativas >= maxTentativas) {
        debugPrint(
          '⚠️ Máximo de tentativas de verificação atingido, parando timer',
        );
        timer.cancel();
        return;
      }

      if (_channel != null && _pendingUserName != null) {
        tentativas++;
        debugPrint(
          '🔄 Verificação $tentativas/$maxTentativas - Nome ainda não confirmado, reenviando: $_pendingUserName',
        );
        _sendMessage({
          'type': 'definirNome',
          'payload': {'nome': _pendingUserName},
        });
      } else {
        debugPrint('❌ Canal ou nome pendente é null, parando timer');
        timer.cancel();
      }
    });

    // Para o timer após 20 segundos para evitar loop infinito
    Timer(const Duration(seconds: 20), () {
      _nameVerificationTimer?.cancel();
      if (!_nameConfirmed) {
        debugPrint('⚠️ Timer de verificação de nome expirou após 20 segundos');
      }
    });
  }

  /// Inicia monitoramento de heartbeat para detectar desconexões silenciosas
  void _startHeartbeatMonitoring() {
    _heartbeatTimer?.cancel();

    // Verifica a cada 30 segundos se recebemos mensagens recentemente
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_lastMessageReceived != null) {
        final timeSinceLastMessage = DateTime.now().difference(
          _lastMessageReceived!,
        );

        // Timeout dinâmico baseado na fase do jogo
        final timeoutSeconds = _getHeartbeatTimeout();

        if (timeSinceLastMessage.inSeconds > timeoutSeconds) {
          final phase = _isInPlacementPhase ? 'posicionamento' : 'jogo';
          debugPrint(
            '💔 Heartbeat timeout ($phase) - sem mensagens por ${timeSinceLastMessage.inSeconds}s (limite: ${timeoutSeconds}s)',
          );
          _handleConnectionError('Conexão perdida com o servidor');
          timer.cancel();
        } else {
          // Log periódico para debug (apenas a cada 2 minutos para não poluir)
          if (timeSinceLastMessage.inSeconds % 120 == 0 &&
              timeSinceLastMessage.inSeconds > 0) {
            debugPrint(
              '💓 Heartbeat OK - última mensagem há ${timeSinceLastMessage.inSeconds}s (limite: ${timeoutSeconds}s)',
            );
          }
        }
      }
    });
  }

  /// Retorna o timeout apropriado baseado na fase do jogo
  int _getHeartbeatTimeout() {
    if (_isInPlacementPhase) {
      // 5 minutos durante posicionamento - jogadores precisam de tempo para estratégia
      return 300; // 5 * 60 segundos
    } else {
      // 60 segundos durante jogo ativo - mais responsivo
      return 60;
    }
  }

  /// Define se está na fase de posicionamento (timeout mais longo)
  void setPlacementPhase(bool isPlacement) {
    if (_isInPlacementPhase != isPlacement) {
      _isInPlacementPhase = isPlacement;
      final phase = isPlacement ? 'posicionamento' : 'jogo';
      final timeout = _getHeartbeatTimeout();
      debugPrint('🎯 Mudança de fase: $phase (timeout: ${timeout}s)');

      // Reinicia o heartbeat com o novo timeout
      if (_isConnected) {
        _startHeartbeatMonitoring();
      }
    }
  }

  /// Verifica se está na fase de posicionamento
  bool get isInPlacementPhase => _isInPlacementPhase;

  /// Força mudança para fase de jogo (usado quando detectamos início do jogo)
  void forceGamePhase() {
    debugPrint('🎯 Forçando mudança para fase de jogo');
    setPlacementPhase(false);
  }

  /// Força mudança para fase de posicionamento (usado em reconexões)
  void forcePlacementPhase() {
    debugPrint('🎯 Forçando mudança para fase de posicionamento');
    setPlacementPhase(true);
  }

  /// Imprime status detalhado da conexão para debug
  void printConnectionDebugInfo() {
    final status = getConnectionStatus();
    debugPrint('🔍 === STATUS DA CONEXÃO ===');
    debugPrint('🔍 Conectando: ${status['isConnecting']}');
    debugPrint('🔍 Conectado: ${status['isConnected']}');
    debugPrint('🔍 Nome confirmado: ${status['nameConfirmed']}');
    debugPrint('🔍 Nome pendente: ${status['pendingUserName']}');
    debugPrint('🔍 Tem canal: ${status['hasChannel']}');
    debugPrint('🔍 Timer de nome ativo: ${status['hasNameTimer']}');
    debugPrint('🔍 Timer de conexão ativo: ${status['hasConnectionTimer']}');
    debugPrint('🔍 Fase de posicionamento: ${status['isInPlacementPhase']}');
    debugPrint('🔍 Timeout heartbeat: ${status['heartbeatTimeout']}s');
    debugPrint(
      '🔍 Última mensagem: ${_lastMessageReceived?.toString() ?? 'Nunca'}',
    );
    debugPrint('🔍 ========================');
  }

  /// Fecha a conexão com o WebSocket.
  void dispose() {
    _connectionTimeout?.cancel();
    _nameVerificationTimer?.cancel();
    _heartbeatTimer?.cancel();
    _isConnecting = false;

    try {
      _channel?.sink.close();
    } catch (e) {
      // Ignora erros ao fechar canal
    }

    _estadoController.close();
    _erroController.close();
    _statusController.close();
    _placementController.close();
  }
}
