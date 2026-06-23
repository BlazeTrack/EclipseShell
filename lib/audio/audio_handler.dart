import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart';

// El enum se declara a nivel global fuera de la clase
enum LoopMode { off, once, all }

class AudioHandlerImpl extends BaseAudioHandler with QueueHandler, SeekHandler {
  final AudioPlayer _player = AudioPlayer();
  final ConcatenatingAudioSource _playlist = ConcatenatingAudioSource(children: []);
  
  LoopMode _loopMode = LoopMode.off;
  LoopMode get loopMode => _loopMode;

  AudioHandlerImpl() {
    _init();
  }

  void _init() {
    // Transmitir los estados de reproducción nativos hacia el sistema operativo
    _player.playbackEventStream.map(_transformEvent).pipe(playbackState);
    
    // Escuchar el cambio automático de pistas para actualizar el índice actual
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
        await _player.setLoopMode(com.justaudio.LoopMode.off);
        break;
      case LoopMode.once:
        await _player.setLoopMode(com.justaudio.LoopMode.one);
        break;
      case LoopMode.all:
        await _player.setLoopMode(com.justaudio.LoopMode.all);
        break;
    }
    // Forzar actualización en la UI notificando cambios
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
    final sources = items.map((item) => AudioSource.uri(Uri.parse(item.id), tag: item)).toList();
    _playlist.clear();
    await _playlist.addAll(sources);
    await _player.setAudioSource(_playlist);
  }

  String? _defaultScanRoot() {
    // Raíz de escaneo por defecto de archivos locales
    return '/storage/emulated/0/Music';
  }

  // Mapeos nativos obligatorios para el ciclo de vida de audio_service
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

  PlaybackState _transformEvent(PlaybackEvent event) {
    return PlaybackState(
      controls: [
        MediaControl.skipToPrevious,
        if (_player.playing) MediaControl.pause else MediaControl.play,
        MediaControl.stop,
        MediaControl.skipToNext,
      ],
      systemActions: const {
        MediaAction.seek,
        MediaAction.seekForward