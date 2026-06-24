import 'package:just_audio/just_audio.dart' as ja;
import 'package:audio_service/audio_service.dart';

enum LoopMode { off, once, all }

class AudioHandlerImpl extends BaseAudioHandler with QueueHandler, SeekHandler {
  final ja.AudioPlayer _player = ja.AudioPlayer();
  final ja.ConcatenatingAudioSource _playlist = ja.ConcatenatingAudioSource(children: []);
  
  LoopMode _loopMode = LoopMode.off;
  LoopMode get loopMode => _loopMode;

  AudioHandlerImpl() {
    _init();
  }

  void _init() {
    _player.playbackEventStream.map(_transformEvent).pipe(playbackState);
    
    _player.currentIndexStream.listen((index) {
      if (index != null && queue.value.isNotEmpty) {
        mediaItem.add(queue.value[index]);
      }
    });
  }

  Future<void> setLoopMode(LoopMode mode) async {
    _loopMode = mode;
    switch (mode) {
      case LoopMode.off:
        await _player.setLoopMode(ja.LoopMode.off);
        break;
      case LoopMode.once:
        await _player.setLoopMode(ja.LoopMode.one);
        break;
      case LoopMode.all:
        await _player.setLoopMode(ja.LoopMode.all);
        break;
    }
    playbackState.add(playbackState.value.copyWith());
  }

  Future<void> toggleShuffle() async {
    final bool shuffleOn = !_player.shuffleModeEnabled;
    await _player.setShuffleModeEnabled(shuffleOn);
    playbackState.add(playbackState.value.copyWith(
      shuffleMode: shuffleOn ? AudioServiceShuffleMode.all : AudioServiceShuffleMode.none,
    ));
  }

  Future<void> loadPlaylist(List<MediaItem> items) async {
    queue.add(items);
    final sources = items.map((item) => ja.AudioSource.uri(Uri.parse(item.id), tag: item)).toList();
    await _playlist.clear();
    await _playlist.addAll(sources);
    await _player.setAudioSource(_playlist);
  }

  String? _defaultScanRoot() {
    return '/storage/emulated/0/Music';
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> skipToNext() => _player.seekToNext();

  @override
  Future<void> skipToPrevious() => _player.seekToPrevious();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  PlaybackState _transformEvent(ja.PlaybackEvent event) {
    return PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        if (_player.playing) MediaControl.pause else MediaControl.play,
        MediaControl.stop,
        MediaControl.skipToNext,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      },
      androidCompactActionIndices: const [0, 1, 3],
      processingState: const {
        ja.ProcessingState.idle: AudioProcessingState.idle,
        ja.ProcessingState.loading: AudioProcessingState.loading,
        ja.ProcessingState.buffering: AudioProcessingState.buffering,
        ja.ProcessingState.ready: AudioProcessingState.ready,
        ja.ProcessingState.completed: AudioProcessingState.completed,
      }[_player.processingState]!,
      playing: _player.playing,
      updatePosition: event.updatePosition,
      bufferedPosition: event.bufferedPosition,
      speed: _player.speed,
      queueIndex: event.currentIndex,
    );
  }
}