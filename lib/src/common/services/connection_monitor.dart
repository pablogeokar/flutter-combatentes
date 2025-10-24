import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// Serviço para monitorar a qualidade da conexão de rede.
/// Detecta problemas de conectividade e instabilidade do servidor.
class ConnectionMonitor {
  static ConnectionMonitor? _instance;
  static ConnectionMonitor get instance => _instance ??= ConnectionMonitor._();

  ConnectionMonitor._();

  Timer? _monitorTimer;
  final List<ConnectionQuality> _qualityHistory = [];
  final int _maxHistorySize = 10;

  /// Stream que emite mudanças na qualidade da conexão
  final _qualityController = StreamController<ConnectionQuality>.broadcast();
  Stream<ConnectionQuality> get qualityStream => _qualityController.stream;

  /// Inicia o monitoramento da conexão
  void startMonitoring({
    required String serverHost,
    Duration interval = const Duration(seconds: 30),
  }) {
    stopMonitoring();

    debugPrint('🔍 Iniciando monitoramento de conexão para $serverHost');

    _monitorTimer = Timer.periodic(interval, (timer) async {
      final quality = await _checkConnectionQuality(serverHost);
      _addQualityMeasurement(quality);
      _qualityController.add(quality);
    });
  }

  /// Para o monitoramento da conexão
  void stopMonitoring() {
    _monitorTimer?.cancel();
    _monitorTimer = null;
    debugPrint('🔍 Monitoramento de conexão parado');
  }

  /// Verifica a qualidade da conexão com o servidor
  Future<ConnectionQuality> _checkConnectionQuality(String serverHost) async {
    try {
      final stopwatch = Stopwatch()..start();

      // Remove protocolo se presente
      final host = serverHost
          .replaceAll('wss://', '')
          .replaceAll('ws://', '')
          .replaceAll('https://', '')
          .replaceAll('http://', '')
          .split(':')[0]; // Remove porta se presente

      // Tenta conectar ao host
      final socket = await Socket.connect(
        host,
        80, // Porta HTTP padrão para teste básico
        timeout: const Duration(seconds: 5),
      );

      await socket.close();
      stopwatch.stop();

      final latency = stopwatch.elapsedMilliseconds;

      // Classifica a qualidade baseada na latência
      ConnectionQualityLevel level;
      if (latency < 100) {
        level = ConnectionQualityLevel.excellent;
      } else if (latency < 300) {
        level = ConnectionQualityLevel.good;
      } else if (latency < 1000) {
        level = ConnectionQualityLevel.fair;
      } else {
        level = ConnectionQualityLevel.poor;
      }

      debugPrint('🔍 Qualidade da conexão: $level (${latency}ms)');

      return ConnectionQuality(
        level: level,
        latency: latency,
        timestamp: DateTime.now(),
        isConnected: true,
      );
    } catch (e) {
      debugPrint('🔍 Erro na verificação de conexão: $e');

      return ConnectionQuality(
        level: ConnectionQualityLevel.disconnected,
        latency: -1,
        timestamp: DateTime.now(),
        isConnected: false,
        error: e.toString(),
      );
    }
  }

  /// Adiciona uma medição de qualidade ao histórico
  void _addQualityMeasurement(ConnectionQuality quality) {
    _qualityHistory.add(quality);

    // Mantém apenas as últimas medições
    if (_qualityHistory.length > _maxHistorySize) {
      _qualityHistory.removeAt(0);
    }
  }

  /// Obtém a qualidade média da conexão baseada no histórico
  ConnectionQualityLevel get averageQuality {
    if (_qualityHistory.isEmpty) {
      return ConnectionQualityLevel.unknown;
    }

    final connectedMeasurements = _qualityHistory
        .where((q) => q.isConnected)
        .toList();

    if (connectedMeasurements.isEmpty) {
      return ConnectionQualityLevel.disconnected;
    }

    final averageLatency =
        connectedMeasurements.map((q) => q.latency).reduce((a, b) => a + b) /
        connectedMeasurements.length;

    if (averageLatency < 100) {
      return ConnectionQualityLevel.excellent;
    } else if (averageLatency < 300) {
      return ConnectionQualityLevel.good;
    } else if (averageLatency < 1000) {
      return ConnectionQualityLevel.fair;
    } else {
      return ConnectionQualityLevel.poor;
    }
  }

  /// Verifica se a conexão está instável baseada no histórico
  bool get isConnectionUnstable {
    if (_qualityHistory.length < 3) {
      return false;
    }

    // Conta quantas medições recentes falharam
    final recentMeasurements = _qualityHistory.take(5).toList();
    final failedCount = recentMeasurements
        .where((q) => !q.isConnected || q.level == ConnectionQualityLevel.poor)
        .length;

    // Considera instável se mais de 40% das medições recentes falharam
    return failedCount / recentMeasurements.length > 0.4;
  }

  /// Obtém estatísticas da conexão
  ConnectionStats get stats {
    if (_qualityHistory.isEmpty) {
      return ConnectionStats(
        totalMeasurements: 0,
        successfulMeasurements: 0,
        averageLatency: 0,
        successRate: 0,
        isStable: true,
      );
    }

    final successful = _qualityHistory.where((q) => q.isConnected).length;
    final totalLatency = _qualityHistory
        .where((q) => q.isConnected)
        .map((q) => q.latency)
        .fold(0, (a, b) => a + b);

    final avgLatency = successful > 0 ? totalLatency / successful : 0;
    final successRate = successful / _qualityHistory.length;

    return ConnectionStats(
      totalMeasurements: _qualityHistory.length,
      successfulMeasurements: successful,
      averageLatency: avgLatency.round(),
      successRate: successRate,
      isStable: !isConnectionUnstable,
    );
  }

  /// Limpa o histórico de qualidade
  void clearHistory() {
    _qualityHistory.clear();
    debugPrint('🔍 Histórico de qualidade limpo');
  }

  /// Libera recursos
  void dispose() {
    stopMonitoring();
    _qualityController.close();
  }
}

/// Representa a qualidade de uma medição de conexão
class ConnectionQuality {
  final ConnectionQualityLevel level;
  final int latency; // em millisegundos, -1 se desconectado
  final DateTime timestamp;
  final bool isConnected;
  final String? error;

  const ConnectionQuality({
    required this.level,
    required this.latency,
    required this.timestamp,
    required this.isConnected,
    this.error,
  });

  @override
  String toString() {
    return 'ConnectionQuality(level: $level, latency: ${latency}ms, connected: $isConnected)';
  }
}

/// Níveis de qualidade da conexão
enum ConnectionQualityLevel {
  excellent, // < 100ms
  good, // 100-300ms
  fair, // 300-1000ms
  poor, // > 1000ms
  disconnected, // Sem conexão
  unknown, // Não medido ainda
}

/// Estatísticas da conexão
class ConnectionStats {
  final int totalMeasurements;
  final int successfulMeasurements;
  final int averageLatency;
  final double successRate;
  final bool isStable;

  const ConnectionStats({
    required this.totalMeasurements,
    required this.successfulMeasurements,
    required this.averageLatency,
    required this.successRate,
    required this.isStable,
  });

  @override
  String toString() {
    return 'ConnectionStats(measurements: $totalMeasurements, success: ${(successRate * 100).toStringAsFixed(1)}%, latency: ${averageLatency}ms, stable: $isStable)';
  }
}
