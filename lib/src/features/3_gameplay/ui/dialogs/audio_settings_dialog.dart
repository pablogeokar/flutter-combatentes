import 'package:flutter/material.dart';
import 'package:combatentes/src/common/services/audio_service.dart';

class AudioSettingsDialog extends StatefulWidget {
  const AudioSettingsDialog({super.key});

  @override
  State<AudioSettingsDialog> createState() => _AudioSettingsDialogState();
}

class _AudioSettingsDialogState extends State<AudioSettingsDialog> {
  final AudioService _audioService = AudioService();
  late bool _musicEnabled;
  late bool _soundEnabled;

  @override
  void initState() {
    super.initState();
    _musicEnabled = _audioService.isMusicEnabled;
    _soundEnabled = _audioService.isSoundEnabled;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.volume_up, color: Colors.blue),
          SizedBox(width: 8),
          Text('Configurações de Áudio'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Controle de música de fundo
          SwitchListTile(
            title: const Text('Música de Fundo'),
            subtitle: const Text('Trilha sonora do jogo'),
            value: _musicEnabled,
            onChanged: (value) {
              setState(() {
                _musicEnabled = value;
              });

              if (value) {
                _audioService.enableMusic();
              } else {
                _audioService.disableMusic();
              }
            },
            secondary: const Icon(Icons.music_note),
          ),

          const Divider(),

          // Controle de efeitos sonoros
          SwitchListTile(
            title: const Text('Efeitos Sonoros'),
            subtitle: const Text('Sons de combate, turno e explosões'),
            value: _soundEnabled,
            onChanged: (value) {
              setState(() {
                _soundEnabled = value;
              });

              if (value) {
                _audioService.enableSounds();
              } else {
                _audioService.disableSounds();
              }
            },
            secondary: const Icon(Icons.volume_up),
          ),

          const SizedBox(height: 16),

          // Botões de teste
          const Text(
            'Testar Sons:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          Wrap(
            spacing: 8,
            children: [
              ElevatedButton.icon(
                onPressed: _soundEnabled
                    ? () => _audioService.playTurnNotification()
                    : null,
                icon: const Icon(Icons.notifications, size: 16),
                label: const Text('Turno'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),

              ElevatedButton.icon(
                onPressed: _soundEnabled
                    ? () => _audioService.playCombatSound()
                    : null,
                icon: const Icon(Icons.gps_fixed, size: 16),
                label: const Text('Combate'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),

              ElevatedButton.icon(
                onPressed: _soundEnabled
                    ? () => _audioService.playExplosionSound()
                    : null,
                icon: const Icon(Icons.whatshot, size: 16),
                label: const Text('Explosão'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  foregroundColor: Colors.white,
                ),
              ),

              ElevatedButton.icon(
                onPressed: _soundEnabled
                    ? () => _audioService.playDisarmSound()
                    : null,
                icon: const Icon(Icons.build, size: 16),
                label: const Text('Desarme'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Fechar'),
        ),
      ],
    );
  }
}
