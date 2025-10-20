import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

class AudioService {
  static final AudioService _instance = AudioService._internal();
  factory AudioService() => _instance;
  AudioService._internal();

  final AudioPlayer _backgroundPlayer = AudioPlayer();
  final AudioPlayer _effectsPlayer = AudioPlayer();

  bool _isMusicEnabled = true;
  bool _isSoundEnabled = true;
  bool _isBackgroundMusicPlaying = false;

  // Getters para verificar estado
  bool get isMusicEnabled => _isMusicEnabled;
  bool get isSoundEnabled => _isSoundEnabled;
  bool get isBackgroundMusicPlaying => _isBackgroundMusicPlaying;

  // Inicializar o serviço de áudio
  Future<void> initialize() async {
    try {
      // Configurar o player de música de fundo para loop
      await _backgroundPlayer.setReleaseMode(ReleaseMode.loop);

      // Configurar volume inicial
      await _backgroundPlayer.setVolume(0.3); // Música de fundo mais baixa
      await _effectsPlayer.setVolume(0.7); // Efeitos sonoros mais altos

      if (kDebugMode) {
        print('AudioService inicializado com sucesso');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao inicializar AudioService: $e');
      }
    }
  }

  // Controlar música de fundo
  Future<void> playBackgroundMusic() async {
    if (!_isMusicEnabled || _isBackgroundMusicPlaying) return;

    try {
      await _backgroundPlayer.play(AssetSource('sounds/trilha_sonora.wav'));
      _isBackgroundMusicPlaying = true;

      if (kDebugMode) {
        print('Música de fundo iniciada');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao tocar música de fundo: $e');
      }
    }
  }

  Future<void> stopBackgroundMusic() async {
    try {
      await _backgroundPlayer.stop();
      _isBackgroundMusicPlaying = false;

      if (kDebugMode) {
        print('Música de fundo parada');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao parar música de fundo: $e');
      }
    }
  }

  Future<void> pauseBackgroundMusic() async {
    try {
      await _backgroundPlayer.pause();
      _isBackgroundMusicPlaying = false;

      if (kDebugMode) {
        print('Música de fundo pausada');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao pausar música de fundo: $e');
      }
    }
  }

  Future<void> resumeBackgroundMusic() async {
    if (!_isMusicEnabled) return;

    try {
      await _backgroundPlayer.resume();
      _isBackgroundMusicPlaying = true;

      if (kDebugMode) {
        print('Música de fundo retomada');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao retomar música de fundo: $e');
      }
    }
  }

  // Efeitos sonoros específicos
  Future<void> playTurnNotification() async {
    if (!_isSoundEnabled) return;

    try {
      await _effectsPlayer.play(AssetSource('sounds/campainha.wav'));

      if (kDebugMode) {
        print('Som de turno tocado');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao tocar som de turno: $e');
      }
    }
  }

  Future<void> playExplosionSound() async {
    if (!_isSoundEnabled) return;

    try {
      await _effectsPlayer.play(AssetSource('sounds/explosao.wav'));

      if (kDebugMode) {
        print('Som de explosão tocado');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao tocar som de explosão: $e');
      }
    }
  }

  Future<void> playDisarmSound() async {
    if (!_isSoundEnabled) return;

    try {
      await _effectsPlayer.play(AssetSource('sounds/desarme.wav'));

      if (kDebugMode) {
        print('Som de desarme tocado');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao tocar som de desarme: $e');
      }
    }
  }

  Future<void> playCombatSound() async {
    if (!_isSoundEnabled) return;

    try {
      await _effectsPlayer.play(AssetSource('sounds/tiro.wav'));

      if (kDebugMode) {
        print('Som de combate tocado');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao tocar som de combate: $e');
      }
    }
  }

  Future<void> playVictorySound() async {
    if (!_isSoundEnabled) return;

    try {
      await _effectsPlayer.play(AssetSource('sounds/comemoracao.mp3'));

      if (kDebugMode) {
        print('Som de vitória tocado');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao tocar som de vitória: $e');
      }
    }
  }

  Future<void> playDefeatSound() async {
    if (!_isSoundEnabled) return;

    try {
      await _effectsPlayer.play(AssetSource('sounds/derrota_fim.wav'));

      if (kDebugMode) {
        print('Som de derrota tocado');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao tocar som de derrota: $e');
      }
    }
  }

  // Controles de configuração
  void enableMusic() {
    _isMusicEnabled = true;
    if (!_isBackgroundMusicPlaying) {
      playBackgroundMusic();
    }
  }

  void disableMusic() {
    _isMusicEnabled = false;
    if (_isBackgroundMusicPlaying) {
      stopBackgroundMusic();
    }
  }

  void enableSounds() {
    _isSoundEnabled = true;
  }

  void disableSounds() {
    _isSoundEnabled = false;
  }

  void toggleMusic() {
    if (_isMusicEnabled) {
      disableMusic();
    } else {
      enableMusic();
    }
  }

  void toggleSounds() {
    if (_isSoundEnabled) {
      disableSounds();
    } else {
      enableSounds();
    }
  }

  // Ajustar volumes
  Future<void> setMusicVolume(double volume) async {
    try {
      await _backgroundPlayer.setVolume(volume.clamp(0.0, 1.0));
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao ajustar volume da música: $e');
      }
    }
  }

  Future<void> setSoundVolume(double volume) async {
    try {
      await _effectsPlayer.setVolume(volume.clamp(0.0, 1.0));
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao ajustar volume dos efeitos: $e');
      }
    }
  }

  // Limpeza de recursos
  Future<void> dispose() async {
    try {
      await _backgroundPlayer.dispose();
      await _effectsPlayer.dispose();

      if (kDebugMode) {
        print('AudioService finalizado');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao finalizar AudioService: $e');
      }
    }
  }
}
