import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../audio/audio_handler.dart';
import 'downloads_panel.dart';

class EclipseShellApp extends StatelessWidget {
  const EclipseShellApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final audioHandler = context.watch<AudioHandlerCustom>();

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Row(
          children: [
            // Panel Izquierdo: Reproductor Local y Búsqueda
            Expanded(
              flex: 2,
              child: Container(
                decoration: BoxDecoration(
                  border: Border(right: BorderSide(color: Colors.grey.shade900, width: 2)),
                ),
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Cabecera Estilo Ventana Retro
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      color: Colors.indigo.shade900,
                      width: double.infinity,
                      child: const Text(
                        "ECLIPSESHELL - LOCAL PLAYER",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Barra de Búsqueda Conectada
                    TextField(
                      onChanged: (value) {
                        audioHandler.setLocalSearchQuery(value);
                      },
                      style: const TextStyle(color: Colors.white, fontFamily: 'monospace'),
                      decoration: InputDecoration(
                        hintText: "Buscar track, artista o álbum...",
                        hintStyle: const TextStyle(color: Colors.grey),
                        prefixIcon: const Icon(Icons.search, color: Colors.grey),
                        filled: true,
                        fillColor: Colors.grey.shade950,
                        enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade800)),
                        focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.indigo)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Lista de Canciones Filtrada en Tiempo Real
                    Expanded(
                      child: audioHandler.filteredQueue.isEmpty
                          ? const Center(
                              child: Text(
                                "[No se encontraron pistas]",
                                style: TextStyle(color: Colors.grey, fontFamily: 'monospace'),
                              ),
                            )
                          : ListView.builder(
                              itemCount: audioHandler.filteredQueue.length,
                              itemBuilder: (context, index) {
                                final item = audioHandler.filteredQueue[index];
                                return ListTile(
                                  dense: true,
                                  title: Text(item.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                  subtitle: Text(item.artist ?? "Artista Desconocido", style: TextStyle(color: Colors.grey.shade400)),
                                  leading: const Icon(Icons.music_note, color: Colors.indigo_accent),
                                  onTap: () {
                                    audioHandler.playMediaItem(item);
                                  },
                                );
                              },
                            ),
                    ),
                    // Panel de Controles Inferior (PLAYCONTROL)
                    Container(
                      color: Colors.grey.shade950,
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.play_arrow, color: Colors.white),
                            onPressed: () => audioHandler.play(),
                          ),
                          IconButton(
                            icon: const Icon(Icons.pause, color: Colors.white),
                            onPressed: () => audioHandler.pause(),
                          ),
                          // Selector de Loop Corregido
                          PopupMenuButton<LoopModeState>(
                            icon: const Icon(Icons.repeat, color: Colors.white),
                            tooltip: "Modo de Repetición",
                            onSelected: (LoopModeState mode) {
                              audioHandler.setLoopModeCustom(mode);
                            },
                            itemBuilder: (BuildContext context) => <PopupMenuEntry<LoopModeState>>[
                              const PopupMenuItem<LoopModeState>(
                                value: LoopModeState.off,
                                child: Text('Una vez (Off)'),
                              ),
                              const PopupMenuItem<LoopModeState>(
                                value: LoopModeState.all,
                                child: Text('Loop todo'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
            // Panel Derecho: Pestaña Estática de Descargas UI
            const Expanded(
              flex: 1,
              child: DownloadsPanel(),
            ),
          ],
        ),
      ),
    );
  }
}