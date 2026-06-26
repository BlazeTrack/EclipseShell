import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart' as ja;
import 'package:flutter/foundation.dart';

enum LoopModeState { off, once, all }

// Interfaz personalizada para asegurar que la UI y Provider vean los métodos del clon
abstract class AudioHandlerCustom extends BaseAudioHandler implements QueueHandler, PlaybackHandler {
  List<MediaItem> get filteredQueue;
  String get localSearchQuery;
  void setLocalSearchQuery(String query);
  void setLoopModeCustom(LoopModeState mode);
}

class AudioHandlerImpl extends BaseAudioHandler implements AudioHandlerCustom {
  final ja.AudioPlayer _player = ja.AudioPlayer();
  final List<MediaItem> _fullQueue = [];
  String _localSearchQuery = "";
  LoopModeState _currentLoopMode = LoopModeState.off;

  AudioHandlerImpl() {
    _init();
  }

  void _init() {
    // Escucha el cambio de estado para procesar el término de pista manualmente si es necesario
    _player.processingStateStream.listen((state) {
      if (state == ja.ProcessingState.completed) {
        if (_currentLoopMode == LoopModeState.once) {
          _player.seek(Duration.zero);
          _player.play();
        } else if (_currentLoopMode == LoopModeState.all) {
          _player.seek(Duration.zero);
          _player.play();
        }
      }
    });

    // Mapear el flujo de reproducción nativo al estado de audio_service
    _player.playbackEventStream.map(_transformEvent).pipe(playbackState);
  }

  @override
  List<MediaItem> get filteredQueue {
    if (_localSearchQuery.isEmpty) return _fullQueue;
    return _fullQueue.where((item) {
      final query = _localSearchQuery.toLowerCase();
      final titleMatch = item.title.toLowerCase().contains(query);
      final artistMatch = (item.artist ?? '').toLowerCase().contains(query);
      final albumMatch = (item.album ?? '').toLowerCase().contains(query);
      return titleMatch || artistMatch || albumMatch;
    }).toList();
  }

  @override
  String get localSearchQuery => _localSearchQuery;

  @override
  void setLocalSearchQuery(String query) {
    _localSearchQuery = query;
    notifyListeners(); // Notifica a Provider para reconstruir la UI de la lista en tiempo real
  }

  @override
  void setLoopModeCustom(LoopModeState mode) {
    _currentLoopMode = mode;
    if (mode == LoopModeState.all) {
      _player.setLoopMode(ja.LoopMode.all);
    } else {
      _player.setLoopMode(ja.LoopMode.off);
    }
    notifyListeners();
  }

  // Métodos obligatorios de control de reproducción
  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> stop() => _player.stop();

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
      androidCompactCapabilities: const [0, 1, 3],
      processingState: const {
        ja.ProcessingState.idle: AudioProcessingState.idle,
        ja.ProcessingState.loading: AudioProcessingState.loading,
        ja.ProcessingState.buffering: AudioProcessingState.buffering,
        ja.ProcessingState.ready: AudioProcessingState.ready,
        ja.ProcessingState.completed: AudioProcessingState.completed,
      }[_player.processingState]!,
      playing: _player.playing,
      updatePosition: _player.position,
      bufferedPosition: _player.bufferedPosition,
      speed: _player.speed,
      queueIndex: event.currentIndex,
    );
  }
}