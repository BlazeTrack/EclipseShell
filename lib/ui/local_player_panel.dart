import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_selector/file_selector.dart';
import 'package:provider/provider.dart';
import '../audio/audio_handler.dart';

class LocalPlayerPanel extends StatelessWidget {
  const LocalPlayerPanel({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final audioHandler = Provider.of<AudioHandlerImpl>(context);

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          // Barra de Búsqueda de Biblioteca Local
          TextField(
            readOnly: true, // Cambiar a false si vas a activar la búsqueda en local en el futuro
            decoration: InputDecoration(
              hintText: 'Buscar en biblioteca local...',
              hintStyle: const TextStyle(color: Colors.white54, fontSize: 13),
              prefixIcon: const Icon(Icons.search, color: Colors.white54, size: 18),
              filled: true,
              fillColor: const Color(0xFF0B1226),
              isDense: true,
              contentPadding: const EdgeInsets.all(10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFF3A4B7C))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFF3A4B7C))),
            ),
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 8),
          // Ventana del Explorador de Archivos Local
          Expanded(
            flex: 6,
            child: _buildWindowBox(
              title: 'ECLIPSESHELL FILE EXPLORER',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: audioHandler.queue.isEmpty
                        ? const Center(child: Text('No hay pistas cargadas. Añade archivos para comenzar.', style: TextStyle(color: Colors.white38, fontSize: 12), textAlign: TextAlign.center))
                        : ListView.builder(
                            itemCount: audioHandler.queue.length,
                            itemBuilder: (context, index) {
                              final path = audioHandler.queue[index];
                              final meta = audioHandler.metadataForPath(path) ?? {'title': path.split(Platform.pathSeparator).last};
                              final title = meta['title'] ?? path.split(Platform.pathSeparator).last;
                              final isActive = audioHandler.currentTitle == title;
                              return ListTile(
                                dense: true,
                                title: Text(title, style: TextStyle(color: isActive ? Colors.cyanAccent : Colors.white70, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                                subtitle: (meta['artist'] != null && (meta['artist'] as String).isNotEmpty) ? Text(meta['artist'], style: const TextStyle(color: Colors.white54, fontSize: 11)) : null,
                                onTap: () => audioHandler.playIndex(index),
                                leading: _trackArt(meta['artPath'] as String?, size: 32, iconColor: isActive ? Colors.cyanAccent : Colors.white70),
                                trailing: isActive ? const Icon(Icons.play_arrow, color: Colors.cyanAccent, size: 16) : null,
                              );
                            },
                          ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final typeGroup = XTypeGroup(label: 'audio', extensions: ['mp3', 'wav', 'm4a', 'aac', 'flac', 'ogg']);
                        final files = await openFiles(acceptedTypeGroups: [typeGroup]);
                        if (files.isEmpty) return;
                        final paths = files.map((file) => file.path).whereType<String>().toList();
                        if (paths.isEmpty) return;
                        await audioHandler.addFiles(paths);
                      },
                      icon: const Icon(Icons.folder_open, size: 14),
                      label: const Text('Agregar pistas', style: TextStyle(fontSize: 11)),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A264F)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          // Ventana de Reproducción Inferior
          Expanded(
            flex: 4,
            child: _buildWindowBox(
              title: 'PLAYCONTROL PANEL',
              child: Padding(
                padding: const EdgeInsets.all(6.0),
                child: ListView(
                  shrinkWrap: true,
                  physics: const ClampingScrollPhysics(),
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 44, height: 44,
                          margin: const EdgeInsets.only(right: 8),
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(4)),
                          child: _trackArt(audioHandler.currentMetadata['artPath'] as String?, size: 44),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(audioHandler.currentMetadata['title'] ?? 'Sin pista seleccionada', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                              Text('${audioHandler.currentMetadata['artist'] ?? ''} · ${audioHandler.currentMetadata['album'] ?? ''}', style: const TextStyle(color: Colors.white70, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(constraints: const BoxConstraints(), padding: const EdgeInsets.all(4), onPressed: audioHandler.skipToPrevious, icon: const Icon(Icons.skip_previous, color: Colors.white, size: 20)),
                        IconButton(constraints: const BoxConstraints(), padding: const EdgeInsets.all(4), onPressed: audioHandler.isPlaying ? audioHandler.pause : audioHandler.play, icon: Icon(audioHandler.isPlaying ? Icons.pause_circle : Icons.play_circle, color: Colors.white, size: 32)),
                        IconButton(constraints: const BoxConstraints(), padding: const EdgeInsets.all(4), onPressed: audioHandler.skipToNext, icon: const Icon(Icons.skip_next, color: Colors.white, size: 20)),
                        const Spacer(),
                        IconButton(constraints: const BoxConstraints(), padding: const EdgeInsets.all(4), onPressed: () async => await audioHandler.toggleShuffle(), icon: Icon(audioHandler.isShuffle ? Icons.shuffle_on : Icons.shuffle, color: Colors.white, size: 18)),
                      ],
                    ),
                    StreamBuilder<Duration>(
                      stream: audioHandler.positionStream,
                      builder: (context, snapshotPos) {
                        final pos = snapshotPos.data ?? Duration.zero;
                        final dur = audioHandler.duration;
                        final value = dur.inMilliseconds == 0 ? 0.0 : pos.inMilliseconds / dur.inMilliseconds;
                        return Column(
                          children: [
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(trackHeight: 2, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5)),
                              child: Slider(
                                value: value.clamp(0.0, 1.0),
                                onChanged: (v) {
                                  final target = Duration(milliseconds: (v * dur.inMilliseconds).round());
                                  audioHandler.seekTo(target);
                                },
                                activeColor: Colors.cyanAccent,
                                inactiveColor: Colors.white12,
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(_formatDuration(pos), style: const TextStyle(color: Colors.white70, fontSize: 11)),
                                Text(_formatDuration(dur), style: const TextStyle(color: Colors.white70, fontSize: 11)),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A264F), minimumSize: const Size(0, 26)), onPressed: () async { final root = await audioHandler.pickScanRoot(); if (root != null) await audioHandler.scanAndAddRoot(rootOverride: root); }, child: const Text('Asignar Carpeta', style: TextStyle(fontSize: 10)))),
                        const SizedBox(width: 4),
                        Expanded(child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A264F), minimumSize: const Size(0, 26)), onPressed: () async => await audioHandler.scanAndAddRoot(), child: const Text('Forzar Escaneo', style: TextStyle(fontSize: 10)))),
                      ],
                    )
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWindowBox({required String title, required Widget child}) {
    return Card(
      color: Colors.black45,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(side: const BorderSide(color: Color(0xFF3A4B7C), width: 2), borderRadius: BorderRadius.circular(4)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(color: const Color(0xFF1A264F), width: double.infinity, padding: const EdgeInsets.all(5.0), child: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 10, fontFamily: 'monospace'))),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _trackArt(String? artPath, {double size = 40, Color iconColor = Colors.white70}) {
    if (artPath != null && artPath.isNotEmpty && File(artPath).existsSync()) {
      return ClipRRect(borderRadius: BorderRadius.circular(4), child: Image.file(File(artPath), width: size, height: size, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Icon(Icons.music_note, color: iconColor, size: size * 0.5)));
    }
    return Icon(Icons.music_note, color: iconColor, size: size * 0.5);
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}