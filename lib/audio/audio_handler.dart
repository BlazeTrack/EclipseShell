import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart';

// 1. CORREGIDO: El Enum ahora está fuera de la clase (Top-level)
enum LoopMode { off, once, all }

class AudioHandlerImpl extends BaseAudioHandler with QueueHandler, SeekHandler {
  // 2. CORREGIDO: Tipos de just_audio reconocidos correctamente
  final AudioPlayer _player = AudioPlayer();
  final ConcatenatingAudioSource _playlist = ConcatenatingAudioSource(children: []);
  
  LoopMode _loopMode = LoopMode.off;
  LoopMode get loopMode => _loopMode;

  AudioHandlerImpl() {
    _init();
  }

  void _init() {
    // Escuchar cambios de estado u otras inicializaciones
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
  }

  // 3. CORREGIDO: Método toggleShuffle añadido para evitar el error en la UI
  Future<void> toggleShuffle() async {
    final bool shuffleOn = !_player.shuffleModeEnabled;
    await _player.setShuffleModeEnabled(shuffleOn);
  }

  // Ejemplo de cómo agregar tracks a la playlist de forma segura
  Future<void> addTrack(String path, MediaItem meta) async {
    await _playlist.add(AudioSource.uri(Uri.file(path), tag: meta));
  }

  // 4. CORREGIDO: Única declaración de _defaultScanRoot (Eliminado el duplicado)
  String? _defaultScanRoot() {
    // Tu lógica nativa para encontrar la ruta raíz de la música
    return null; 
  }

  // Implementaciones requeridas por BaseAudioHandler
  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() => _player.stop();
}