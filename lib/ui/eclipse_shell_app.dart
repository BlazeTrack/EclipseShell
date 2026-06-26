import 'dart:io';
import 'dart:math';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../audio/audio_handler.dart';
import 'starfield_painter.dart';

class EclipseShellApp extends StatefulWidget {
  const EclipseShellApp({Key? key}) : super(key: key);

  @override
  State<EclipseShellApp> createState() => _EclipseShellAppState();
}

class _EclipseShellAppState extends State<EclipseShellApp> with WidgetsBindingObserver {
  List<Offset>? _stars;
  Size? _lastSize;
  Offset? _eclipseCenter;
  double? _eclipseRadius;

  // --- NUEVAS VARIABLES PARA EL APARTADO DE DESCARGAS ---
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'Canciones'; // Opciones: Canciones, Álbumes, Playlists
  bool _isSearching = false;
  
  // Configuración de descargas en paralelo (Se podrá usar en settings en el futuro)
  final int _maxParallelDownloads = 3; 

  // Simulación de estructura de resultados de búsqueda para la UI interactiva
  List<Map<String, dynamic>> _searchResults = [];
  Map<String, dynamic>? _selectedDownloadItem; // Item seleccionado para ver detalles abajo

  // Control de progreso de descargas (ID del video/elemento -> porcentaje 0.0 a 1.0)
  final Map<String, double> _downloadProgress = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    }
  }

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

  // Simulación del motor dinámico de extracción (Simula yt-dlp auto-parcheable)
  Future<void> _executeYoutubeSearch(String query) async {
    if (query.trim().isEmpty) return;
    setState(() {
      _isSearching = true;
      _searchResults.clear();
    });

    // Simulando delay de red y parseo dinámico de firmas de YT
    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _isSearching = false;
      if (_selectedCategory == 'Canciones') {
        _searchResults = [
          {'id': 'yt_1', 'title': '$query (Audio Oficial)', 'author': 'Artista Alpha', 'duration': '03:45', 'type': 'track'},
          {'id': 'yt_2', 'title': '$query (Remix HQ)', 'author': 'DJ Eclipse', 'duration': '04:12', 'type': 'track'},
        ];
      } else if (_selectedCategory == 'Álbumes') {
        _searchResults = [
          {
            'id': 'alb_1', 
            'title': 'The $query Album', 
            'author': 'Mega Band', 
            'type': 'album',
            'tracks': [
              {'id': 'alb_t1', 'title': 'Intro - Welcome to $query', 'duration': '01:30'},
              {'id': 'alb_t2', 'title': 'Main Theme ($query)', 'duration': '05:10'},
              {'id': 'alb_t3', 'title': 'Outro - Eclipse Solitude', 'duration': '03:20'},
            ]
          },
        ];
      } else {
        _searchResults = [
          {
            'id': 'plist_1', 
            'title': 'Best of $query Playlist', 
            'author': 'Comunidad User', 
            'type': 'playlist',
            'tracks': [
              {'id': 'pl_t1', 'title': 'Track Inspirado en $query 1', 'duration': '02:50'},
              {'id': 'pl_t2', 'title': 'Track Inspirado en $query 2', 'duration': '03:15'},
            ]
          },
        ];
      }
    });
  }

  // Lógica de descarga veloz (Maneja subcarpetas si es album/playlist)
  Future<void> _downloadElement(Map<String, dynamic> item, {String? subFolder}) async {
    final id = item['id'] as String;
    
    // Evitar descargas duplicadas simultáneas
    if (_downloadProgress.containsKey(id) && _downloadProgress[id]! < 1.0) return;

    setState(() {
      _downloadProgress[id] = 0.0;
    });

    // Simulación de descarga por chunks de alta velocidad en paralelo
    for (int i = 1; i <= 10; i++) {
      await Future.delayed(const Duration(milliseconds: 150));
      setState(() {
        _downloadProgress[id] = i / 10.0;
      });
    }

    // Al finalizar, se simula el guardado con metadatos incrustados e inyección automática en el reproductor
    final audioHandler = Provider.of<AudioHandlerImpl>(context, listen: false);
    final String folderPath = subFolder != null 
        ? '${audioHandler.scanRoot ?? "/storage/emulated/0/Download/EclipseMusic"}/$subFolder'
        : '${audioHandler.scanRoot ?? "/storage/emulated/0/Download/EclipseMusic"}';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Descargado en Alta Calidad: ${item['title']} -> Guardado en $folderPath')),
    );
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
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    children: [
                      const SizedBox(height: 4),
                      // --- BARRA SUPERIOR DE BÚSQUEDA DEL SISTEMA ---
                      Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 520),
                          child: TextField(
                            readOnly: true,
                            decoration: InputDecoration(
                              hintText: 'Buscar en biblioteca local...',
                              hintStyle: const TextStyle(color: Colors.white54),
                              prefixIcon: const Icon(Icons.search, color: Colors.white54),
                              filled: true,
                              fillColor: const Color(0xFF0B1226),
                              contentPadding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 12.0),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0),
                                borderSide: const BorderSide(color: Color(0xFF3A4B7C)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0),
                                borderSide: const BorderSide(color: Color(0xFF3A4B7C)),
                              ),
                            ),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      
                      // --- CUERPO PRINCIPAL ASIMÉTRICO EN DOS COLUMNAS ---
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // COLUMNA IZQUIERDA: Módulo de Descargas de Red
                            Expanded(
                              flex: 1,
                              child: _buildWindow(
                                title: 'ECLIPSESHELL NET DOWNLOADER (YT-DL CORE)',
                                child: _buildNetDownloader(),
                              ),
                            ),
                            const SizedBox(width: 6),
                            // COLUMNA DERECHA: Explorador Local y Controles de Audio
                            Expanded(
                              flex: 1,
                              child: Column(
                                children: [
                                  Expanded(
                                    flex: 5,
                                    child: _buildWindow(
                                      title: 'ECLIPSESHELL FILE EXPLORER',
                                      child: _buildFileExplorer(),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Expanded(
                                    flex: 5,
                                    child: _buildWindow(
                                      title: 'PLAYCONTROL & INFO PANEL',
                                      child: _buildPlayControl(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
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
      margin: EdgeInsets.zero,
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
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }

  // --- NUEVA SECCIÓN DE DESCARGAS (IZQUIERDA) ---
  Widget _buildNetDownloader() {
    return Padding(
      padding: const EdgeInsets.all(6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Input de búsqueda en YT
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onSubmitted: _executeYoutubeSearch,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Buscar música en red...',
                    hintStyle: const TextStyle(color: Colors.white38),
                    filled: true,
                    fillColor: const Color(0xFF0B1226),
                    isDense: true,
                    contentPadding: const EdgeInsets.all(10),
                    border: OutlineInputBorder(borderSide: const BorderSide(color: Color(0xFF3A4B7C))),
                    enabledBorder: OutlineInputBorder(borderSide: const BorderSide(color: Color(0xFF3A4B7C))),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                backgroundColor: const Color(0xFF1A264F),
                icon: const Icon(Icons.cloud_download, color: Colors.cyanAccent, size: 20),
                onPressed: () => _executeYoutubeSearch(_searchController.text),
              )
            ],
          ),
          const SizedBox(height: 6),
          // Selector de Categorías (Canciones, Álbumes, Playlists)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: ['Canciones', 'Álbumes', 'Playlists'].map((category) {
              final isSelected = _selectedCategory == category;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2.0),
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: isSelected ? const Color(0xFF3A4B7C) : Colors.transparent,
                      side: const BorderSide(color: Color(0xFF3A4B7C)),
                      padding: EdgeInsets.zero,
                    ),
                    onPressed: () {
                      setState(() {
                        _selectedCategory = category;
                        _searchResults.clear();
                        _selectedDownloadItem = null;
                      });
                    },
                    child: Text(
                      category,
                      style: TextStyle(color: isSelected ? Colors.cyanAccent : Colors.white70, fontSize: 11),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 6),
          // Resultados de la Ventana Superior de Red
          Expanded(
            child: _isSearching
                ? const Center(child: CircularProgressIndicator(color: Colors.cyanAccent))
                : _searchResults.isEmpty
                    ? const Center(child: Text('Usa la barra superior para buscar en la red de YT', style: TextStyle(color: Colors.white38, fontSize: 12), textAlign: Center.center))
                    : ListView.builder(
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final item = _searchResults[index];
                          final id = item['id'] as String;
                          final progress = _downloadProgress[id];
                          final isDownloading = progress != null && progress < 1.0;
                          final isSelected = _selectedDownloadItem?['id'] == id;

                          return ListTile(
                            dense: true,
                            selected: isSelected,
                            selectedTileColor: const Color(0xFF0B1226),
                            title: Text(item['title'], style: TextStyle(color: isSelected ? Colors.cyanAccent : Colors.white, fontSize: 13, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item['author'] ?? '', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                                if (isDownloading) ...[
                                  const SizedBox(height: 4),
                                  LinearProgressIndicator(value: progress, backgroundColor: Colors.white12, color: Colors.cyanAccent, minHeight: 3),
                                ]
                              ],
                            ),
                            onTap: () {
                              setState(() {
                                _selectedDownloadItem = item;
                              });
                            },
                            trailing: IconButton(
                              icon: isDownloading 
                                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.cyanAccent))
                                  : const Icon(Icons.download, color: Colors.greenAccent, size: 18),
                              onPressed: () => _downloadElement(item, subFolder: item['type'] != 'track' ? item['title'] : null),
                            ),
                          );
                        },
                      ),
          ),
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
              ? const Center(
                  child: Text(
                    'No hay pistas cargadas. Añade archivos para comenzar a reproducir.',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView.builder(
                  itemCount: audioHandler.queue.length,
                  itemBuilder: (context, index) {
                    final path = audioHandler.queue[index];
                    final meta = audioHandler.metadataForPath(path) ?? {'title': path.split(Platform.pathSeparator).last};
                    final title = meta['title'] ?? path.split(Platform.pathSeparator).last;
                    final isActive = audioHandler.currentTitle == title;
                    return ListTile(
                      dense: true,
                      title: Text(
                        title,
                        style: TextStyle(color: isActive ? Colors.cyanAccent : Colors.white70, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: (meta['artist'] != null && (meta['artist'] as String).isNotEmpty)
                          ? Text(meta['artist'], style: const TextStyle(color: Colors.white54, fontSize: 11))
                          : null,
                      onTap: () => audioHandler.playIndex(index),
                      leading: _trackArt(
                        meta['artPath'] as String?,
                        size: 32,
                        iconColor: isActive ? Colors.cyanAccent : Colors.white70,
                      ),
                      trailing: isActive ? const Icon(Icons.play_arrow, color: Colors.cyanAccent, size: 16) : null,
                    );
                  },
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(4.0),
          child: ElevatedButton.icon(
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
            icon: const Icon(Icons.folder_open, size: 16),
            label: const Text('Agregar pistas', style: TextStyle(fontSize: 11)),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A264F), dense: true),
          ),
        ),
      ],
    );
  }

  // --- SECCIÓN INFERIOR DERECHA: AHORA INCLUYE REPRODUCTOR INFO E INFO DE ÁLBUMES/PLAYLISTS SELECCIONADOS ---
  Widget _buildPlayControl() {
    final audioHandler = Provider.of<AudioHandlerImpl>(context);
    
    // Si el usuario seleccionó un Álbum o Playlist en la ventana de red, mostramos sus canciones en este panel inferior
    if (_selectedDownloadItem != null && _selectedDownloadItem!['type'] != 'track') {
      final subTracks = _selectedDownloadItem!['tracks'] as List<Map<String, String>>;
      final parentTitle = _selectedDownloadItem!['title'] as String;

      return Padding(
        padding: const EdgeInsets.all(6.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'CONTENIDO DE: $parentTitle',
                    style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton(
                  style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(50, 20)),
                  onPressed: () => setState(() => _selectedDownloadItem = null),
                  child: const Text('Volver a Player', style: TextStyle(color: Colors.orangeAccent, fontSize: 11)),
                )
              ],
            ),
            const SizedBox(height: 4),
            Expanded(
              child: ListView.builder(
                itemCount: subTracks.length,
                itemBuilder: (context, idx) {
                  final track = subTracks[idx];
                  final tid = track['id']!;
                  final trackProgress = _downloadProgress[tid];
                  final isTrackDownloading = trackProgress != null && trackProgress < 1.0;

                  return ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(track['title']!, style: const TextStyle(color: Colors.white70, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: isTrackDownloading 
                        ? LinearProgressIndicator(value: trackProgress, backgroundColor: Colors.white12, color: Colors.greenAccent)
                        : Text(track['duration']!, style: const TextStyle(color: Colors.white38, fontSize: 10)),
                    trailing: IconButton(
                      icon: isTrackDownloading
                          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.greenAccent))
                          : const Icon(Icons.download_rounded, color: Colors.white54, size: 16),
                      onPressed: () => _downloadElement({'id': tid, 'title': track['title']!}, subFolder: parentTitle),
                    ),
                  );
                },
              ),
            )
          ],
        ),
      );
    }

    // --- CODIGO DE REPRODUCCIÓN ORIGINAL CUANDO NO HAY ELEMENTO DE RED SELECCIONADO ---
    return Padding(
      padding: const EdgeInsets.all(6.0),
      child: ListView(
        shrinkWrap: true,
        physics: const ClampingScrollPhysics(),
        children: [
          const Text('Reproduciendo', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 4),
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                margin: const EdgeInsets.only(right: 8),
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(4)),
                child: _trackArt(audioHandler.currentMetadata['artPath'] as String?, size: 44),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      audioHandler.currentMetadata['title'] ?? 'Sin pista seleccionada',
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${audioHandler.currentMetadata['artist'] ?? ''} · ${audioHandler.currentMetadata['album'] ?? ''}',
                      style: const TextStyle(color: Colors.white70, fontSize: 11),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A264F), padding: EdgeInsets.zero, minimumSize: const Size(0, 30)),
                  onPressed: () async {
                    final selectedRoot = await audioHandler.pickScanRoot();
                    if (!mounted || selectedRoot == null) return;
                    await audioHandler.scanAndAddRoot(rootOverride: selectedRoot);
                  },
                  child: const Text('Asignar Directorio', style: TextStyle(fontSize: 10)),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1A264F), padding: EdgeInsets.zero, minimumSize: const Size(0, 30)),
                  onPressed: () async => await audioHandler.scanAndAddRoot(),
                  child: const Text('Forzar Escaneo', style: TextStyle(fontSize: 10)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _trackArt(String? artPath, {double size = 40, Color iconColor = Colors.white70}) {
    if (artPath != null && artPath.isNotEmpty && File(artPath).existsSync()) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Image.file(File(artPath), width: size, height: size, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Icon(Icons.music_note, color: iconColor, size: size * 0.5)),
      );
    }
    return Icon(Icons.music_note, color: iconColor, size: size * 0.5);
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}