import 'package:audioplayers/audioplayers.dart';

class ModulePlacementSoundPlayer {
  ModulePlacementSoundPlayer() : _player = AudioPlayer();

  final AudioPlayer _player;
  bool _disposed = false;

  Future<void> playLock() async {
    if (_disposed) return;
    try {
      await _player.stop();
      if (_disposed) return;
      await _player.play(
        AssetSource('sounds/module_lock.wav'),
        volume: 0.56,
      );
    } on Object {
      // A short interface sound must never block drag/drop interaction.
    }
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    try {
      await _player.dispose();
    } on Object {
      // Disposal is best-effort on browsers while a sound is starting.
    }
  }
}
