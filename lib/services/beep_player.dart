import 'package:audioplayers/audioplayers.dart';

abstract interface class BeepPlayer {
  Future<void> play({required bool high});

  Future<void> dispose();
}

class AssetBeepPlayer implements BeepPlayer {
  final _player = AudioPlayer();

  @override
  Future<void> play({required bool high}) async {
    await _player.stop();
    await _player.play(AssetSource(high ? 'beep_high.mp3' : 'beep_low.mp3'));
  }

  @override
  Future<void> dispose() => _player.dispose();
}
