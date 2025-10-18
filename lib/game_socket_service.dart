import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

import './modelos_jogo.dart';

/// Encapsula a comunicação com o servidor WebSocket do jogo.
class GameSocketService {
  late final WebSocketChannel _channel;
  final _estadoController = StreamController<EstadoJogo>.broadcast();
  final _erroController = StreamController<String>.broadcast();

  /// Stream que emite o [EstadoJogo] mais recente recebido do servidor.
  Stream<EstadoJogo> get streamDeEstados => _estadoController.stream;

  /// Stream que emite mensagens de erro recebidas do servidor.
  Stream<String> get streamDeErros => _erroController.stream;

  /// Conecta-se ao servidor WebSocket e começa a ouvir por mensagens.
  void connect(String url, {String? nomeUsuario}) {
    try {
      _channel = WebSocketChannel.connect(Uri.parse(url));

      // Envia o nome do usuário assim que conecta
      if (nomeUsuario != null) {
        Future.delayed(const Duration(milliseconds: 100), () {
          _channel.sink.add(
            jsonEncode({
              'type': 'definirNome',
              'payload': {'nome': nomeUsuario},
            }),
          );
        });
      }

      _channel.stream.listen(
        (message) {
          try {
            final data = jsonDecode(message);
            final type = data['type'];

            if (type == 'atualizacaoEstado') {
              print('DEBUG: Recebido estado do servidor.');
              final estado = EstadoJogo.fromJson(data['payload']);
              _estadoController.add(estado);
            } else if (type == 'erroMovimento') {
              final erro =
                  data['payload']?['mensagem'] ??
                  'Erro desconhecido do servidor.';
              _erroController.add(erro);
            } else if (type == 'mensagemServidor') {
              print('Mensagem do Servidor: ${data['payload']}');
            }
          } catch (e, s) {
            print('!!!!!! ERRO AO PROCESSAR MENSAGEM DO SERVIDOR !!!!!!');
            print('DADOS BRUTOS: $message');
            print('ERRO: $e');
            print('STACK TRACE: $s');
            _erroController.add('Erro ao ler dados do servidor.');
          }
        },
        onError: (error) {
          print('WebSocket Error: $error');
          _erroController.add('Erro de conexão com o servidor.');
        },
        onDone: () {
          print('WebSocket connection closed');
        },
      );
    } catch (e) {
      print('Could not connect to WebSocket: $e');
      _erroController.add('Não foi possível conectar ao servidor.');
    }
  }

  /// Envia uma intenção de movimento para o servidor.
  void enviarMovimento(String idPeca, PosicaoTabuleiro novaPosicao) {
    final message = jsonEncode({
      'type': 'moverPeca',
      'payload': {'idPeca': idPeca, 'novaPosicao': novaPosicao.toJson()},
    });
    _channel.sink.add(message);
  }

  /// Envia o nome do usuário para o servidor
  void enviarNome(String nome) {
    final message = jsonEncode({
      'type': 'definirNome',
      'payload': {'nome': nome},
    });
    _channel.sink.add(message);
  }

  /// Reconecta ao servidor
  void reconnect(String url, {String? nomeUsuario}) {
    try {
      // Fecha a conexão atual se existir
      _channel.sink.close();
    } catch (e) {
      // Ignora erros ao fechar conexão anterior
    }

    // Limpa os controllers
    if (!_estadoController.isClosed) {
      // Não fecha os controllers, apenas limpa os erros
    }
    if (!_erroController.isClosed) {
      // Não fecha os controllers, apenas limpa os erros
    }

    // Tenta nova conexão
    connect(url, nomeUsuario: nomeUsuario);
  }

  /// Fecha a conexão com o WebSocket.
  void dispose() {
    _channel.sink.close();
    _estadoController.close();
    _erroController.close();
  }
}
