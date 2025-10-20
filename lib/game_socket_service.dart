import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import './modelos_jogo.dart';
import './providers.dart';

/// Encapsula a comunicação com o servidor WebSocket do jogo.
class GameSocketService {
  WebSocketChannel? _channel;
  final _estadoController = StreamController<EstadoJogo>.broadcast();
  final _erroController = StreamController<String>.broadcast();
  final _statusController = StreamController<StatusConexao>.broadcast();
  Timer? _connectionTimeout;
  bool _isConnecting = false;
  bool _isConnected = false;

  /// Stream que emite o [EstadoJogo] mais recente recebido do servidor.
  Stream<EstadoJogo> get streamDeEstados => _estadoController.stream;

  /// Stream que emite mensagens de erro recebidas do servidor.
  Stream<String> get streamDeErros => _erroController.stream;

  /// Stream que emite o status da conexão.
  Stream<StatusConexao> get streamDeStatus => _statusController.stream;

  /// Conecta-se ao servidor WebSocket e começa a ouvir por mensagens.
  void connect(String url, {String? nomeUsuario}) {
    if (_isConnecting) {
      return;
    }

    _isConnecting = true;
    _isConnected = false;

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
            }

            try {
              final data = jsonDecode(message);
              final type = data['type'];

              if (type == 'atualizacaoEstado') {
                final estado = EstadoJogo.fromJson(data['payload']);
                _estadoController.add(estado);
                // Quando recebe estado do jogo, significa que está jogando
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
              } else if (type == 'mensagemServidor') {
                final mensagem = data['payload'].toString();

                // Verifica se o oponente desconectou
                if (mensagem.contains('oponente desconectou') ||
                    mensagem.contains('O oponente desconectou')) {
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
          Future.delayed(const Duration(milliseconds: 150), () {
            _sendMessage({
              'type': 'definirNome',
              'payload': {'nome': nomeUsuario},
            });
          });
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
      if (_channel != null && _isConnected) {
        _channel!.sink.add(jsonEncode(message));
      }
    } catch (e) {
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
    _sendMessage({
      'type': 'definirNome',
      'payload': {'nome': nome},
    });
  }

  /// Reconecta ao servidor
  void reconnect(String url, {String? nomeUsuario}) {
    // Cancela timeout anterior
    _connectionTimeout?.cancel();
    _isConnecting = false;

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
    try {
      // Emite status de reconectando
      _statusController.add(StatusConexao.conectando);

      // Fecha conexão atual
      try {
        _channel?.sink.close();
      } catch (e) {
        // Ignora erros ao fechar conexão anterior
      }

      _channel = null;
      _isConnecting = false;
      _isConnected = false;

      // Aguarda um pouco antes de reconectar
      await Future.delayed(const Duration(milliseconds: 500));

      // Tenta reconectar
      connect(url, nomeUsuario: nomeUsuario);

      // Aguarda conexão ou timeout
      final completer = Completer<bool>();
      late StreamSubscription subscription;

      subscription = streamDeStatus.listen((status) {
        if (status == StatusConexao.conectado ||
            status == StatusConexao.jogando) {
          subscription.cancel();
          completer.complete(true);
        } else if (status == StatusConexao.erro) {
          subscription.cancel();
          completer.complete(false);
        }
      });

      // Timeout de 10 segundos para reconexão
      Timer(const Duration(seconds: 10), () {
        if (!completer.isCompleted) {
          subscription.cancel();
          completer.complete(false);
        }
      });

      return await completer.future;
    } catch (e) {
      _statusController.add(StatusConexao.erro);
      return false;
    }
  }

  /// Envia mensagem de posicionamento
  void enviarMensagemPlacement(Map<String, dynamic> message) {
    _sendMessage(message);
  }

  /// Fecha a conexão com o WebSocket.
  void dispose() {
    _connectionTimeout?.cancel();
    _isConnecting = false;

    try {
      _channel?.sink.close();
    } catch (e) {
      // Ignora erros ao fechar canal
    }

    _estadoController.close();
    _erroController.close();
    _statusController.close();
  }
}
