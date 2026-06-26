import 'package:flutter/material.dart';

class DownloadsPanel extends StatefulWidget {
  const DownloadsPanel({Key? key}) : super(key: key);

  @override
  State<DownloadsPanel> createState() => _DownloadsPanelState();
}

class _DownloadsPanelState extends State<DownloadsPanel> {
  final TextEditingController _urlController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey.shade950,
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Barra de Título del Panel de Descargas
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            color: Colors.dark_purple.shade900, // Variación estética retro
            width: double.infinity,
            child: const Text(
              "DESCARGAS (UI TEMPORAL)",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'monospace', fontSize: 12),
            ),
          ),
          const SizedBox(height: 15),
          const Text(
            "Extractor Lossless",
            style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _urlController,
            style: const TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 12),
            decoration: InputDecoration(
              hintText: "Pega el enlace de YouTube aquí...",
              hintStyle: const TextStyle(color: Colors.grey, fontSize: 11),
              filled: true,
              fillColor: Colors.black,
              enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: Colors.grey.shade800)),
              focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.purple)),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.purple.shade900),
              onPressed: () {
                // Notificación visual de UI sin lógica por el momento
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Flujo de yt-dlp / yt-dl deshabilitado temporalmente en este parche.'),
                    backgroundColor: Colors.purple,
                  ),
                );
              },
              icon: const Icon(Icons.cloud_download, size: 16, color: Colors.white),
              label: const Text(
                "Descargar FLAC",
                style: TextStyle(color: Colors.white, fontFamily: 'monospace', fontSize: 12),
              ),
            ),
          ),
          const SizedBox(height: 20),
          // Simulación de sección de progreso vacía
          Divider(color: Colors.grey.shade800),
          const SizedBox(height: 5),
          const Text(
            "PROGRESO ACTUAL:",
            style: TextStyle(color: Colors.grey, fontSize: 11, fontFamily: 'monospace'),
          ),
          const Expanded(
            child: Center(
              key: Key("empty_state_downloads"),
              child: Text(
                "[Sin descargas activas]",
                style: TextStyle(color: Colors.grey, fontSize: 11, fontFamily: 'monospace', style: FontStyle.italic),
              ),
            ),
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }
}

// Extensión rápida de color por si acaso tu app usa una paleta oscura customizada
extension on Colors {
  static MaterialColor get dark_purple => Colors.purple;
  
}