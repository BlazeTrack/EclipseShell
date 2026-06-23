import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audio_service/audio_service.dart';
import '../audio/audio_handler.dart';

class EclipseShellApp extends StatelessWidget {
  const EclipseShellApp({super.key});

  @override
  Widget build(BuildContext context) {
    final audioHandler = Provider.of<AudioHandlerImpl>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF121212), // Estilo oscuro de alta fidelidad
      appBar: AppBar(
        title: const Text('Eclipse Shell Player', style: TextStyle(fontFamily: 'monospace')),
        backgroundColor: const Color(0xFF1E1E1E),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.folder_open, color: Colors.cyanAccent),
            onPressed: () {
              // Aquí puedes integrar tu file_selector más adelante
            },
          )
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Pantalla de Información del Track actual
            Expanded(
              flex: 4,
              child: StreamBuilder<MediaItem?>(
                stream: audioHandler.mediaItem,
                builder: (context, snapshot) {
                  final mediaItem = snapshot.data;
                  return Container(
                    margin: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A1A),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.cyanAccent.withOpacity(0.3)),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.music_note, size: 80, color: Colors.cyanAccent),
                          const SizedBox(height: 15),
                          Text(
                            mediaItem?.title ?? 'Ninguna pista en reproducción',
                            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            mediaItem?.artist ?? 'Desconocido',
                            style: const TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Controles de Reproducción y Modos (Sección corregida estructuralmente)
            Expanded(
              flex: 3,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                color: const Color(0xFF1E1E1E),
                child: Builder(
                  builder: (context) {
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Botones de control secuencial e interactivo
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            // Botón de Modo Aleatorio (Shuffle)
                            IconButton(
                              icon: const Icon(Icons.shuffle, color: Colors.grey),
                              onPressed: () async => await audioHandler.toggleShuffle(),
                            ),

                            // Pista Anterior
                            IconButton(
                              icon: const Icon(Icons.skip_previous, size: 36, color: Colors.white),
                              onPressed: () async => await audioHandler.skipToPrevious(),
                            ),

                            // Play / Pause central dinámico
                            StreamBuilder<PlaybackState>(
                              stream: audioHandler.playbackState,
                              builder: (context, snapshot) {
                                final playing = snapshot.data?.playing ?? false;
                                return CircleAvatar(
                                  radius: 30,
                                  backgroundColor: Colors.cyanAccent,
                                  child: IconButton(
                                    icon: Icon(playing ? Icons.pause : Icons.play_arrow),
                                    iconSize: 32,
                                    color: Colors.black,
                                    onPressed: playing ? audioHandler.pause : audioHandler.play,
                                  ),
                                );
                              },
                            ),

                            // Siguiente Pista
                            IconButton(
                              icon: const Icon(Icons.skip_next, size: 36, color: Colors.white),
                              onPressed: () async => await audioHandler.skipToNext(),
                            ),

                            // Menú desplegable para LoopMode limpio de errores sintácticos
                            PopupMenuButton<LoopMode>(
                              initialValue: audioHandler.loopMode,
                              onSelected: (LoopMode mode) async {
                                await audioHandler.setLoopMode(mode);
                              },
                              itemBuilder: (BuildContext context) => <PopupMenuEntry<LoopMode>>[
                                const PopupMenuItem<LoopMode>(
                                  value: LoopMode.off,
                                  child: Text('Repetir: Apagado'),
                                ),
                                const PopupMenuItem<LoopMode>(
                                  value: LoopMode.all,
                                  child: Text('Repetir: Todo'),
                                ),
                                const PopupMenuItem<LoopMode>(
                                  value: LoopMode.once,
                                  child: Text('Repetir: Una'),
                                ),
                              ],
                              child: Icon(
                                audioHandler.loopMode == LoopMode.all
                                    ? Icons.repeat
                                    : audioHandler.loopMode == LoopMode.once
                                        ? Icons.repeat_one
                                        : Icons.repeat_with_type,
                                color: audioHandler.loopMode != LoopMode.off ? Colors.cyanAccent : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}