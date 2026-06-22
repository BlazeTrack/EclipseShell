import 'dart:math';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../audio/audio_handler.dart';
import 'starfield_painter.dart'; // Importación vital para el fondo animado

class EclipseShellApp extends StatefulWidget {
  const EclipseShellApp({Key? key}) : super(key: key);

  @override
  State<EclipseShellApp> createState() => _EclipseShellAppState();
}

class _EclipseShellAppState extends State<EclipseShellApp> {
  List<Offset>? _stars;
  Size? _lastSize;
  Offset? _eclipseCenter;
  double? _eclipseRadius;

  void _initializeStars(Size size) {
    if (_lastSize == size) return;
    _lastSize = size;
    final rng = Random(12345);
    _stars = List.generate(
      120,
      (_) => Offset(rng.nextDouble() * size.width, rng.nextDouble() * size.height),
    );
    _eclipseCenter = Offset(size.width * 0.8, size.height * 0.2);
    _eclipseRadius = size.width * 0.18;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF02030A),
      body: LayoutBuilder(
        builder: (context, constraints) {
          _initializeStars(constraints.biggest);
          return Stack(
            children: [
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF02030A), Color(0xFF050818), Color(0xFF11172F)],
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: CustomPaint(
                  painter: StarfieldPainter(
                    stars: _stars!,
                    eclipseCenter: _eclipseCenter!,
                    eclipseRadius: _eclipseRadius!,
                  ),
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Expanded(
                        child: _buildWindow(
                          title: 'ECLIPSESHELL FILE EXPLORER',
                          child: _buildFileExplorer(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 280,
                        child: _buildWindow(
                          title: 'PLAYCONTROL',
                          child: _buildPlayControl(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildWindow({required String title, required Widget child}) {
    return Card(
      color: Colors.black45,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: Color(0xFF3A4B7C), width: 2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            color: const Color(0xFF1A264F),
            width: double.infinity,
            padding: const EdgeInsets.all(6.0),
            child: Text(
              title,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _buildFileExplorer() {
    final audioHandler = Provider.of<AudioHandlerImpl>(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: audioHandler.queue.isEmpty
              ? Center(
                  child: Text(
                    'No hay pistas cargadas. Añade archivos para comenzar a reproducir.',
                    style: const TextStyle(color: Colors.white70),
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView.builder(
                  itemCount: audioHandler.queue.length,
                  itemBuilder: (context, index) {
                    final title = audioHandler.queue[index];
                    final isActive = audioHandler.currentTitle == title;
                    return ListTile(
                      title: Text(
                        title,
                        style: TextStyle(color: isActive ? Colors.cyanAccent : Colors.white70),
                      ),
                      onTap: () => audioHandler.playIndex(index),
                      leading: Icon(Icons.music_note, color: isActive ? Colors.cyanAccent : Colors.white70),
                      trailing: isActive ? const Icon(Icons.play_arrow, color: Colors.cyanAccent) : null,
                    );
                  },
                ),
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: () async {
            final typeGroup = XTypeGroup(
              label: 'audio',
              extensions: ['mp3', 'wav', 'm4a', 'aac', 'flac', 'ogg'],
            );
            final files = await openFiles(acceptedTypeGroups: [typeGroup]);
            if (files.isEmpty) return;
            final paths = files.map((file) => file.path).whereType<String>().toList();
            if (paths.isEmpty) return;
            await audioHandler.addFiles(paths);
          },
          icon: const Icon(Icons.folder_open),
          label: const Text('Agregar pistas'),
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A264F)),
        ),
      ],
    );
  }

  Widget _buildPlayControl() {
    final audioHandler = Provider.of<AudioHandlerImpl>(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Reproduciendo', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            audioHandler.currentTitle,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                onPressed: audioHandler.skipToPrevious,
                icon: const Icon(Icons.skip_previous, color: Colors.white),
              ),
              IconButton(
                onPressed: audioHandler.isPlaying ? audioHandler.pause : audioHandler.play,
                icon: Icon(
                  audioHandler.isPlaying ? Icons.pause_circle : Icons.play_circle,
                  color: Colors.white,
                  size: 42,
                ),
              ),
              IconButton(
                onPressed: audioHandler.skipToNext,
                icon: const Icon(Icons.skip_next, color: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: audioHandler.duration.inMilliseconds == 0
                ? 0
                : audioHandler.position.inMilliseconds / audioHandler.duration.inMilliseconds,
            color: Colors.cyanAccent,
            backgroundColor: Colors.white12,
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_formatDuration(audioHandler.position), style: const TextStyle(color: Colors.white70, fontSize: 12)),
              Text(_formatDuration(audioHandler.duration), style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
