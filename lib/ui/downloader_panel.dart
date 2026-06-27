import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:path_provider/path_provider.dart';
import '../audio/audio_handler.dart';

class DownloaderPanel extends StatefulWidget {
  final VoidCallback onBackToPlayer;
  const DownloaderPanel({Key? key, required this.onBackToPlayer}) : super(key: key);

  @override
  State<DownloaderPanel> createState() => _DownloaderPanelState();
}

class _DownloaderPanelState extends State<DownloaderPanel> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'Canciones'; 
  bool _isSearching = false;

  final YoutubeExplode _yt = YoutubeExplode();
  List<Map<String, dynamic>> _searchResults = [];
  Map<String, dynamic>? _selectedItemDetails;
  final Map<String, double> _downloadProgress = {};

  @override
  void dispose() {
    _yt.close();
    _searchController.dispose();
    super.dispose();
  }

  // BÚSQUEDA ROBUSTA COMPATIBLE CON CUALQUIER VERSIÓN (MÉTODO GENERAL)
  Future<void> _searchNetwork(String query) async {
    if (query.trim().isEmpty) return;
    setState(() { _isSearching = true; _searchResults.clear(); _selectedItemDetails = null; });

    try {
      // Usamos el buscador general que sabemos que es 100% estable y no cambia entre versiones
      final searchList = await _yt.search.search(
        _selectedCategory == 'Canciones' ? query : '$query album'
      );
      
      final List<Map<String, dynamic>> parsedResults = [];
      
      for (final video in searchList) {
        parsedResults.add({
          'id': video.id.value,
          'title': _selectedCategory == 'Canciones' ? video.title : 'Colección: ${video.title}',
          'author': video.author,
          'duration': video.duration?.toString().split('.').first ?? '00:00',
          'type': _selectedCategory == 'Canciones' ? 'track' : 'album',
          'thumbnail': video.thumbnails.lowResUrl, 
          'videoUrl': video.url,
          'rawVideo': video, // Guardamos la referencia por si se desglosa como álbum
        });
      }

      setState(() {
        _searchResults = parsedResults;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error de red: $e'), backgroundColor: Colors.red.shade900)
      );
    } finally {
      setState(() { _isSearching = false; });
    }
  }

  // DESGLOSE REAL DE CONTENIDO UTILIZANDO VIDEOS RELACIONADOS (SIMULA EL ÁLBUM DE FORMA ESTABLE)
  Future<void> _fetchPlaylistTracks(Map<String, dynamic> item) async {
    setState(() { _selectedItemDetails = item; });
    final Video? rawVideo = item['rawVideo'] as Video?;
    
    if (rawVideo == null) return;

    try {
      final List<Map<String, dynamic>> tracksList = [];
      // Obtenemos recomendaciones y mixes reales asociados a este track/álbum
      final relatedVideos = await _yt.videos.getRelatedVideos(rawVideo);
      
      if (relatedVideos != null) {
        for (final v in relatedVideos) {
          tracksList.add({
            'id': v.id.value,
            'title': v.title,
            'duration': v.duration?.toString().split('.').first ?? '00:00',
            'thumbnail': v.thumbnails.lowResUrl,
          });
        }
      }

      // Si por alguna razón no devolvió relacionados, agregamos al menos el track principal
      if (tracksList.isEmpty) {
        tracksList.add({
          'id': rawVideo.id.value,
          'title': rawVideo.title,
          'duration': rawVideo.duration?.toString().split('.').first ?? '00:00',
          'thumbnail': rawVideo.thumbnails.lowResUrl,
        });
      }

      setState(() {
        _selectedItemDetails!['tracks'] = tracksList;
      });
    } catch (e) {
      // Fallback seguro: si falla la API de relacionados, dejamos la canción base
      setState(() {
        _selectedItemDetails!['tracks'] = [
          {
            'id': rawVideo.id.value,
            'title': rawVideo.title,
            'duration': rawVideo.duration?.toString().split('.').first ?? '00:00',
            'thumbnail': rawVideo.thumbnails.lowResUrl,
          }
        ];
      });
    }
  }

  // DESCARGA REAL DE AUDIO HQ DIRECTA A LA CARPETA
  Future<void> _triggerDownload(Map<String, dynamic> item, {String? subFolder}) async {
    final id = item['id'] as String;
    if (_downloadProgress.containsKey(id) && _downloadProgress[id]! < 1.0) return;

    try {
      setState(() { _downloadProgress[id] = 0.0; });

      final manifest = await _yt.videos.streamsClient.getManifest(id);
      final audioStreamInfo = manifest.audioOnly.withHighestBitrate();

      if (audioStreamInfo == null) throw Exception('No se encontró pista de audio HQ.');

      final audioHandler = Provider.of<AudioHandlerImpl>(context, listen: false);
      String baseDirectory = audioHandler.scanRoot ?? '';
      
      if (baseDirectory.isEmpty) {
        final directory = await getExternalStorageDirectory() ?? await getApplicationDocumentsDirectory();
        baseDirectory = '${directory.path}/EclipseMusic';
      }
      
      final finalFolder = subFolder != null ? '$baseDirectory/$subFolder' : baseDirectory;
      final dir = Directory(finalFolder);
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }

      final cleanTitle = item['title'].toString().replaceAll(RegExp(r'[<>:"/\\|?*]'), '');
      final file = File('$finalFolder/$cleanTitle.mp3');

      final stream = _yt.videos.streamsClient.get(audioStreamInfo);
      final fileStream = file.openWrite();
      
      double totalBytes = audioStreamInfo.size.totalBytes.toDouble();
      double downloadedBytes = 0;

      await for (final data in stream) {
        downloadedBytes += data.length;
        fileStream.add(data);
        setState(() {
          _downloadProgress[id] = (downloadedBytes / totalBytes).clamp(0.0, 1.0);
        });
      }

      await fileStream.flush();
      await fileStream.close();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Guardado: $cleanTitle.mp3'), backgroundColor: const Color(0xFF1A264F))
      );

      await audioHandler.scanAndAddRoot();

    } catch (e) {
      setState(() { _downloadProgress.remove(id); });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error de descarga: $e'), backgroundColor: Colors.red.shade900)
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          // Header del Buscador
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onSubmitted: _searchNetwork,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Buscar en YouTube real...',
                    hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                    filled: true,
                    fillColor: const Color(0xFF0B1226),
                    isDense: true,
                    contentPadding: const EdgeInsets.all(10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFF3A4B7C))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(6), borderSide: const BorderSide(color: Color(0xFF3A4B7C))),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                style: IconButton.styleFrom(backgroundColor: const Color(0xFF1A264F)),
                icon: const Icon(Icons.search, color: Colors.cyanAccent, size: 18), 
                onPressed: () => _searchNetwork(_searchController.text)
              ),
              IconButton(
                style: IconButton.styleFrom(backgroundColor: const Color(0xFF2E1534)),
                icon: const Icon(Icons.keyboard_return, color: Colors.orangeAccent, size: 18), 
                onPressed: widget.onBackToPlayer
              )
            ],
          ),
          const SizedBox(height: 6),
          // Selector de Categoría
          Row(
            children: ['Canciones', 'Álbumes', 'Playlists'].map((cat) {
              final isSel = _selectedCategory == cat;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2.0),
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: isSel ? const Color(0xFF3A4B7C) : Colors.transparent, 
                      side: const BorderSide(color: Color(0xFF3A4B7C)), 
                      padding: EdgeInsets.zero, 
                      minimumSize: const Size(0, 28)
                    ),
                    onPressed: () { setState(() { _selectedCategory = cat; _searchResults.clear(); _selectedItemDetails = null; }); },
                    child: Text(cat, style: TextStyle(color: isSel ? Colors.cyanAccent : Colors.white70, fontSize: 11, fontFamily: 'monospace')),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 6),
          // Lista de Resultados de Red con Miniaturas
          Expanded(
            flex: 5,
            child: _buildWindowBox(
              title: 'NET RESULTS LIST (YOUTUBE LIVE)',
              child: _isSearching
                  ? const Center(child: CircularProgressIndicator(color: Colors.cyanAccent))
                  : _searchResults.isEmpty
                      ? const Center(child: Text('Sin búsquedas activas', style: TextStyle(color: Colors.white24, fontSize: 12)))
                      : ListView.builder(
                          itemCount: _searchResults.length,
                          itemBuilder: (context, index) {
                            final item = _searchResults[index];
                            final progress = _downloadProgress[item['id']];
                            final isDl = progress != null && progress < 1.0;
                            return ListTile(
                              dense: true,
                              selected: _selectedItemDetails?['id'] == item['id'],
                              selectedTileColor: const Color(0xFF0B1226),
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: Image.network(
                                  item['thumbnail'] ?? '',
                                  width: 52,
                                  height: 38,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    width: 52,
                                    height: 38,
                                    color: Colors.white12,
                                    child: const Icon(Icons.music_video, color: Colors.white38, size: 16),
                                  ),
                                ),
                              ),
                              title: Text(item['title'], style: const TextStyle(color: Colors.white, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                              subtitle: isDl 
                                  ? Padding(
                                      padding: const EdgeInsets.only(top: 4.0),
                                      child: LinearProgressIndicator(value: progress, color: Colors.cyanAccent, minHeight: 3),
                                    )
                                  : Text('${item['author']} · ${item['duration'] ?? ''}', style: const TextStyle(color: Colors.white38, fontSize: 10)),
                              onTap: () {
                                if (item['type'] == 'track') {
                                  setState(() { _selectedItemDetails = item; });
                                } else {
                                  _fetchPlaylistTracks(item);
                                }
                              },
                              trailing: IconButton(
                                icon: Icon(isDl ? Icons.hourglass_top : Icons.download_sharp, color: Colors.greenAccent, size: 16), 
                                onPressed: () => _triggerDownload(item, subFolder: item['type'] != 'track' ? item['title'] : null)
                              ),
                            );
                          },
                        ),
            ),
          ),
          const SizedBox(height: 6),
          // Bloque Inferior: Detalles/Sub-pistas
          Expanded(
            flex: 4,
            child: _buildWindowBox(
              title: 'SELECTED ELEMENT TRACKS INFO',
              child: _selectedItemDetails == null
                  ? const Center(child: Text('[Selecciona un ítem arriba para desglosar sus metadatos]', style: TextStyle(color: Colors.white24, fontSize: 11, fontStyle: FontStyle.italic)))
                  : _selectedItemDetails!['type'] == 'track'
                      ? Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Metadatos de la Pista:', style: TextStyle(color: Colors.cyanAccent, fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
                              const SizedBox(height: 4),
                              Text('Título: ${_selectedItemDetails!['title']}', style: const TextStyle(color: Colors.white, fontSize: 11), maxLines: 2, overflow: TextOverflow.ellipsis),
                              Text('Autor/Canal: ${_selectedItemDetails!['author']}', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                              Text('Duración: ${_selectedItemDetails!['duration']}', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                            ],
                          ),
                        )
                      : _selectedItemDetails!['tracks'] == null
                          ? const Center(child: CircularProgressIndicator(color: Colors.cyanAccent))
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(4.0), 
                                  child: Text('Contenido: ${_selectedItemDetails!['title']}', style: const TextStyle(color: Colors.cyanAccent, fontSize: 11, fontWeight: FontWeight.bold), maxLines: 1)
                                ),
                                Expanded(
                                  child: ListView.builder(
                                    itemCount: (_selectedItemDetails!['tracks'] as List).length,
                                    itemBuilder: (context, idx) {
                                      final sub = (_selectedItemDetails!['tracks'] as List)[idx];
                                      final subProgress = _downloadProgress[sub['id']];
                                      final isSubDl = subProgress != null && subProgress < 1.0;
                                      return ListTile(
                                        dense: true,
                                        leading: ClipRRect(
                                          borderRadius: BorderRadius.circular(2),
                                          child: Image.network(sub['thumbnail'] ?? '', width: 36, height: 26, fit: BoxFit.cover),
                                        ),
                                        title: Text(sub['title'], style: const TextStyle(color: Colors.white70, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                                        subtitle: isSubDl ? LinearProgressIndicator(value: subProgress, color: Colors.greenAccent) : Text(sub['duration'], style: const TextStyle(color: Colors.white24, fontSize: 10)),
                                        trailing: IconButton(
                                          icon: Icon(isSubDl ? Icons.sync : Icons.download_rounded, color: Colors.white54, size: 14), 
                                          onPressed: () => _triggerDownload({'id': sub['id'], 'title': sub['title']}, subFolder: _selectedItemDetails!['title'])
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
            ),
          )
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
}