import 'package:audioplayers/audioplayers.dart';

class SoundService {
  static final SoundService _instance = SoundService._();
  factory SoundService() => _instance;
  SoundService._();

  AudioPlayer? _player;

  Future<void> _play(String assetPath) async {
    try {
      _player?.dispose();
      _player = AudioPlayer();
      await _player!.play(AssetSource(assetPath));
    } catch (_) {}
  }

  Future<void> success() => _play('sounds/success.wav');
  Future<void> error() => _play('sounds/error.wav');
}
