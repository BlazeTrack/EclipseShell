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

  Future<void> _searchNetwork(String query) async {
    if (query.trim().isEmpty) return;
    setState(() { _isSearching = true; _searchResults.clear(); });
    await Future.delayed(const Duration(seconds: 1)); // Simula latencia del parche dinámico

    setState(() {
      _isSearching = false;
      if (_selectedCategory == 'Canciones') {
        _searchResults = [
          {'id': 'v1', 'title': '$query (Lossless Audio)', 'author': 'Core Studio', 'duration': '04:02', 'type': 'track'},
          {'id': 'v2', 'title': '$query (Live HQ)', 'author': 'Estación Solar', 'duration': '05:14', 'type': 'track'}
        ];
      } else if (_selectedCategory == 'Álbumes') {
        _searchResults = [
          {
            'id': 'a1', 'title': 'Antología de $query', 'author': 'Fonoteca Disc', 'type': 'album',
            'tracks': [
              {'id': 'a1_t1', 'title': 'Parte I - El Origen de $query', 'duration': '03:10'},
              {'id': 'a1_t2', 'title': 'Parte II - Desarrollo de $query', 'duration': '04:45'}
            ]
          }
        ];
      } else {
        _searchResults = [
          {
            'id': 'p1', 'title': 'Colección Completa: $query', 'author': 'Sincronía Network', 'type': 'playlist',
            'tracks': [
              {'id': 'p1_t1', 'title': 'Mix Esencial $query', 'duration': '02:55'},
              {'id': 'p1_t2', 'title': 'Fase Alterna $query', 'duration': '03:40'}
            ]
          }
        ];
      }
    });
  }

  Future<void> _triggerDownload(Map<String, dynamic> item, {String? subFolder}) async {
    final id = item['id'] as String;
    if (_downloadProgress.containsKey(id) && _downloadProgress[id]! < 1.0) return;

    setState(() { _downloadProgress[id] = 0.0; });
    for (int i = 1; i <= 10; i++) {
      await Future.delayed(const Duration(milliseconds: 120));
      setState(() { _downloadProgress[id] = i / 10.0; });
    }

    final audioHandler = Provider.of<AudioHandlerImpl>(context, listen: false);
    final folder = subFolder != null ? '${audioHandler.scanRoot ?? "EclipseMusic"}/$subFolder' : '${audioHandler.scanRoot ?? "EclipseMusic"}';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Guardado en alta fidelidad en: $folder/${item['title']}.flac'), backgroundColor: Colors.cyan.shade900));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          // Header del Buscador con botón de retorno rápido
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onSubmitted: _searchNetwork,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Buscar en red (YT-DL Auto-Update)...',
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
              IconButton(backgroundColor: const Color(0xFF1A264F), icon: const Icon(Icons.search, color: Colors.cyanAccent, size: 18), onPressed: () => _searchNetwork(_searchController.text)),
              IconButton(backgroundColor: const Color(0xFF2E1534), icon: const Icon(Icons.keyboard_return, color: Colors.orangeAccent, size: 18), onPressed: widget.onBackToPlayer)
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
                    style: OutlinedButton.styleFrom(backgroundColor: isSel ? const Color(0xFF3A4B7C) : Colors.transparent, side: const BorderSide(color: Color(0xFF3A4B7C)), padding: EdgeInsets.zero, minimumSize: const Size(0, 28)),
                    onPressed: () { setState(() { _selectedCategory = cat; _searchResults.clear(); _selectedItemDetails = null; }); },
                    child: Text(cat, style: TextStyle(color: isSel ? Colors.cyanAccent : Colors.white70, fontSize: 11, fontFamily: 'monospace')),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 6),
          // Bloque Superior: Resultados de Red
          Expanded(
            flex: 5,
            child: _buildWindowBox(
              title: 'NET RESULTS LIST',
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
                              title: Text(item['title'], style: const TextStyle(color: Colors.white, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                              subtitle: isDl ? LinearProgressIndicator(value: progress, color: Colors.cyanAccent, minHeight: 2) : Text(item['author'], style: const TextStyle(color: Colors.white38, fontSize: 10)),
                              onTap: () { setState(() { _selectedItemDetails = item; }); },
                              trailing: IconButton(icon: Icon(isDl ? Icons.hourglass_top : Icons.download_sharp, color: Colors.greenAccent, size: 16), onPressed: () => _triggerDownload(item, subFolder: item['type'] != 'track' ? item['title'] : null)),
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
                  ? const Center(child: Text('[Selecciona un álbum o playlist arriba para desglosar sus pistas]', style: TextStyle(color: Colors.white24, fontSize: 11, style: FontStyle.italic)))
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(padding: const EdgeInsets.all(4.0), child: Text('Contenido: ${_selectedItemDetails!['title']}', style: const TextStyle(color: Colors.cyanAccent, fontSize: 11, fontWeight: FontWeight.bold), maxLines: 1)),
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
                                trailing: IconButton(icon: Icon(isSubDl ? Icons.sync : Icons.download_rounded, color: Colors.white54, size: 14), onPressed: () => _triggerDownload({'id': sub['id'], 'title': sub['title']}, subFolder: _selectedItemDetails!['title'])),
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