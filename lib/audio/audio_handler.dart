import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

class AudioHandlerImpl extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();
  final ConcatenatingAudioSource _playlist = ConcatenatingAudioSource(children: []);
  final List<String> _titles = [];

  AudioHandlerImpl() {
    _initialize();
  }

  Future<void> _initialize() async {
    _player.playerStateStream.listen((_) => notifyListeners());
    _player.currentIndexStream.listen((_) => notifyListeners());
    _player.positionStream.listen((_) => notifyListeners());
    await _player.setAudioSource(_playlist);
  }

  List<String> get queue => List.unmodifiable(_titles);

  bool get isPlaying => _player.playing;

  String get currentTitle {
    final index = _player.currentIndex;
    if (index == null || index < 0 || index >= _titles.length) {
      return 'Sin pista seleccionada';
    }
    return _titles[index];
  }

  Duration get position => _player.position;

  Duration get duration => _player.duration ?? Duration.zero;

  Future<void> addFiles(List<String> paths) async {
    for (final path in paths) {
      if (path.isEmpty) continue;
      final fileName = path.split(Platform.pathSeparator).last;
      _titles.add(fileName);
      await _playlist.add(AudioSource.uri(Uri.file(path), tag: fileName));
    }
    notifyListeners();
    if (!_player.playing && _titles.isNotEmpty) {
      await playIndex(_titles.length - 1);
    }
  }

  Future<void> play() async {
    await _player.play();
    notifyListeners();
  }

  Future<void> pause() async {
    await _player.pause();
    notifyListeners();
  }

  Future<void> stop() async {
    await _player.stop();
    notifyListeners();
  }

  Future<void> seekTo(Duration position) async {
    await _player.seek(position);
    notifyListeners();
  }

  Future<void> playIndex(int index) async {
    if (index < 0 || index >= _titles.length) return;
    await _player.seek(Duration.zero, index: index);
    await play();
    notifyListeners();
  }

  Future<void> skipToNext() async {
    await _player.seekToNext();
    notifyListeners();
  }

  Future<void> skipToPrevious() async {
    await _player.seekToPrevious();
    notifyListeners();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
