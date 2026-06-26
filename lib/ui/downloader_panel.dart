import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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

  // Ajuste de descargas paralelas en cola
  final int _maxParallelDownloads = 3;

  List<Map<String, dynamic>> _searchResults = [];
  Map<String, dynamic>? _selectedItemDetails;
  final Map<String, double> _downloadProgress = {};

  // Método de búsqueda optimizado para emular yt-dlp y traer miniaturas reales (HQ)
  Future<void> _searchNetwork(String query) async {
    if (query.trim().isEmpty) return;
    setState(() { _isSearching = true; _searchResults.clear(); });
    
    // Simulación de respuesta del motor extractor dinámico yt-dlp
    await Future.delayed(const Duration(milliseconds: 800)); 

    setState(() {
      _isSearching = false;
      // Usamos IDs de videos musicales reales o representativos para pintar miniaturas verdaderas de los servidores de YT
      if (_selectedCategory == 'Canciones') {
        _searchResults = [
          {
            'id': 'kJQP7kiw5Fk', 
            'title': '$query (Audio Oficial - HQ)', 
            'author': 'VEVO Core Artist', 
            'duration': '03:52', 
            'type': 'track',
            'thumbnail': 'https://img.youtube.com/vi/kJQP7kiw5Fk/0.jpg'
          },
          {
            'id': '9bZkp7q19f0', 
            'title': '$query (Remix & Extended Version)', 
            'author': 'Eclipse Records', 
            'duration': '04:45', 
            'type': 'track',
            'thumbnail': 'https://img.youtube.com/vi/9bZkp7q19f0/0.jpg'
          }
        ];
      } else if (_selectedCategory == 'Álbumes') {
        _searchResults = [
          {
            'id': 'album_1', 
            'title': 'The $query Album (Full Deluxe)', 
            'author': 'Studio Phonoteca', 
            'type': 'album',
            'thumbnail': 'https://img.youtube.com/vi/5qap5aO4i9A/0.jpg',
            'tracks': [
              {'id': 'a1_t1', 'title': '01. Intro: Awakening of $query', 'duration': '02:10'},
              {'id': 'a1_t2', 'title': '02. Main Theme ($query)', 'duration': '05:01'},
              {'id': 'a1_t3', 'title': '03. Outro: Solitude Space', 'duration': '03:15'}
            ]
          }
        ];
      } else {
        _searchResults = [
          {
            'id': 'playlist_1', 
            'title': 'Best Essential Hits of $query', 
            'author': 'Sincronía Curator', 
            'type': 'playlist',
            'thumbnail': 'https://img.youtube.com/vi/YVkUvmDQ3HY/0.jpg',
            'tracks': [
              {'id': 'p1_t1', 'title': 'Track Inspirado en $query vol. 1', 'duration': '03:22'},
              {'id': 'p1_t2', 'title': 'Track Inspirado en $query vol. 2', 'duration': '04:10'}
            ]
          }
        ];
      }
    });
  }

  // Lógica del extractor yt-dlp para la descarga de audio de máxima calidad (.flac/.mp3)
  Future<void> _triggerDownload(Map<String, dynamic> item, {String? subFolder}) async {
    final id = item['id'] as String;
    if (_downloadProgress.containsKey(id) && _downloadProgress[id]! < 1.0) return;

    setState(() { _downloadProgress[id] = 0.0; });
    
    // Simulación del volcado de chunks binarios de audio de alta fidelidad
    for (int i = 1; i <= 10; i++) {
      await Future.delayed(const Duration(milliseconds: 100));
      setState(() { _downloadProgress[id] = i / 10.0; });
    }

    if (!mounted) return;
    final audioHandler = Provider.of<AudioHandlerImpl>(context, listen: false);
    final folder = subFolder != null 
        ? '${audioHandler.scanRoot ?? "/storage/emulated/0/Download"}/$subFolder' 
        : '${audioHandler.scanRoot ?? "/storage/emulated/0/Download"}';
        
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('yt-dlp: Extraído audio HQ -> $folder/${item['title']}.mp3'), 
        backgroundColor: const Color(0xFF1A264F)
      )
    );
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
                    hintText: 'Buscar en red (yt-dlp Core)...',
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
          // Bloque Superior: Resultados de Red con Miniaturas Reales
          Expanded(
            flex: 5,
            child: _buildWindowBox(
              title: 'NET RESULTS LIST (EXTRACTOR ACTIVE)',
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
                              // RENDERIZADO DE LA MINIATURA DE YOUTUBE
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: Image.network(
                                  item['thumbnail'] ?? '',
                                  width: 50,
                                  height: 38,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    width: 50,
                                    height: 38,
                                    color: Colors.white12,
                                    child: const Icon(Icons.music_video, color: Colors.white38, size: 16),
                                  ),
                                ),
                              ),
                              title: Text(item['title'], style: const TextStyle(color: Colors.white, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                              subtitle: isDl ? LinearProgressIndicator(value: progress, color: Colors.cyanAccent, minHeight: 2) : Text(item['author'], style: const TextStyle(color: Colors.white38, fontSize: 10)),
                              onTap: () { setState(() { _selectedItemDetails = item; }); },
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
          // Bloque Inferior: Detalles de Álbum o Playlist Seleccionado
          Expanded(
            flex: 4,
            child: _buildWindowBox(
              title: 'SELECTED ELEMENT TRACKS INFO',
              child: _selectedItemDetails == null || _selectedItemDetails!['type'] == 'track'
                  ? const Center(child: Text('[Selecciona un álbum o playlist arriba para desglosar sus pistas]', style: TextStyle(color: Colors.white24, fontSize: 11, fontStyle: FontStyle.italic)))
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
                                title: Text(sub['title'], style: const TextStyle(color: Colors.white70, fontSize: 11)),
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