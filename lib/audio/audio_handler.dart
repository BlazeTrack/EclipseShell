import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart';

class AudioHandlerImpl extends BaseAudioHandler with QueueHandler, SeekHandler {
  final AudioPlayer _player;
  final _playlist = ConcatenatingAudioSource(children: []);

  AudioHandlerImpl(this._player) {
    _inicializarPasos();
  }

  void _inicializarPasos() {
    _player.setAudioSource(_playlist);
  }

  static Future<AudioHandlerImpl> init() async {
    // Inicialización limpia directa para evitar el fallo de compilación
    final player = AudioPlayer();
    return AudioHandlerImpl(player);
  }

  Future<void> addFile(dynamic entity) async {
    // Lógica para añadir pistas a la cola gapless
    await _playlist.add(AudioSource.file(entity.path));
  }
}