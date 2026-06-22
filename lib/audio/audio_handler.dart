import 'dart:async';
import 'dart:io';
import 'package:audio_session/audio_session.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

class AudioHandlerImpl extends ChangeNotifier {
  final AudioPlayer _player;
  final ConcatenatingAudioSource _playlist;
  bool _isLooping = false;
  double _volume = 1.0;

  AudioHandlerImpl._(this._player, this._playlist) {
    _player.playerStateStream.listen((state) {
      notifyListeners();
    });
    _player.playbackEventStream.listen((event) {
      notifyListeners();
    });
  }

  static Future<AudioHandlerImpl> init() async {
    final player = AudioPlayer(
      audioPipeline: AudioPipelineConfiguration(
        androidAudioTrackBufferSize: 8192,
        iosAudioBufferDuration: const Duration(milliseconds: 20),
      ),
    );

    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());

    final playlist = ConcatenatingAudioSource(children: []);
    await player.setAudioSource(playlist, preload: true);
    player.setVolume(1.0);
    player.setShuffleModeEnabled(false);

    return AudioHandlerImpl._(player, playlist);
  }

  Stream<Duration> get positionStream => _player.positionStream;
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<SequenceState?> get sequenceStateStream => _player.sequenceStateStream;

  List<MediaItem> get mediaItems => _playlist.children
      .whereType<UriAudioSource>()
      .map((source) => source.tag as MediaItem)
      .toList();

  int? get currentIndex => _player.sequenceState?.currentIndex;

  MediaItem? get currentMedia {
    final index = currentIndex;
    if (index == null || index < 0 || index >= mediaItems.length) {
      return null;
    }
    return mediaItems[index];
  }

  bool get isPlaying => _player.playing;
  Duration get duration => _player.duration ?? Duration.zero;
  Duration get position => _player.position;
  bool get isLooping => _isLooping;
  double get volume => _volume;

  Future<void> setVolume(double value) async {
    _volume = value;
    await _player.setVolume(value);
    notifyListeners();
  }

  Future<void> toggleLoop() async {
    _isLooping = !_isLooping;
    await _player.setLoopMode(_isLooping ? LoopMode.all : LoopMode.off);
    notifyListeners();
  }

  Future<void> addFile(File file) async {
    final source = AudioSource.uri(
      Uri.file(file.path),
      tag: MediaItem(
        id: file.path,
        album: 'EclipseShell',
        title: file.uri.pathSegments.last,
        artist: 'Local Library',
        extras: {'bytes': file.lengthSync().toString()},
      ),
    );
    await _playlist.add(source);
    notifyListeners();
  }

  Future<void> addFiles(List<File> files) async {
    final sources = files.map((file) {
      return AudioSource.uri(
        Uri.file(file.path),
        tag: MediaItem(
          id: file.path,
          album: 'EclipseShell',
          title: file.uri.pathSegments.last,
          artist: 'Local Library',
          extras: {'bytes': file.lengthSync().toString()},
        ),
      );
    }).toList();
    await _playlist.addAll(sources);
    notifyListeners();
  }

  Future<void> play() async {
    await _player.play();
  }

  Future<void> pause() async {
    await _player.pause();
  }

  Future<void> stop() async {
    await _player.stop();
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  Future<void> skipToNext() async {
    await _player.seekToNext();
  }

  Future<void> skipToPrevious() async {
    await _player.seekToPrevious();
  }

  Future<Directory> getLocalMusicRoot() async {
    if (Platform.isAndroid) {
      final dir = await getExternalStorageDirectory();
      return dir ?? await getApplicationDocumentsDirectory();
    }
    return await getApplicationDocumentsDirectory();
  }

  Future<List<FileSystemEntity>> listDirectory(Directory dir) async {
    return dir.list().toList();
  }
}
