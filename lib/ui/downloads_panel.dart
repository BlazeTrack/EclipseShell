import 'package:flutter/material.dart';

class DownloadsPanel extends StatelessWidget {
  const DownloadsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 6),
        const _SectionTitle('DESCARGAS'),
        const SizedBox(height: 8),
        TextField(
          readOnly: true,
          decoration: InputDecoration(
            hintText: 'Buscar en descargas...',
            hintStyle: const TextStyle(color: Colors.white54),
            prefixIcon: const Icon(Icons.search, color: Colors.white54),
            filled: true,
            fillColor: const Color(0xFF0B1226),
            contentPadding:
                const EdgeInsets.symmetric(vertical: 12.0, horizontal: 12.0),
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
        const SizedBox(height: 12),
        const _InfoBox(),
        const SizedBox(height: 12),
        const _ProgressBox(),
        const SizedBox(height: 12),
        const _ThumbsGrid(),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      color: const Color(0xFF1A264F),
      child: Text(
        title,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  const _InfoBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black38,
        border: Border.all(color: const Color(0xFF3A4B7C), width: 1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Text(
        'Sin descargas activas.\n(En esta fase solo UI; el flujo con yt-dlp se implementará después.)',
        style: TextStyle(color: Colors.white70, fontSize: 12),
      ),
    );
  }
}

class _ProgressBox extends StatelessWidget {
  const _ProgressBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black38,
        border: Border.all(color: const Color(0xFF3A4B7C), width: 1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Progreso',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 10),
          const LinearProgressIndicator(value: 0),
          const SizedBox(height: 8),
          const Text('0% · 00:00 / 00:00', style: TextStyle(color: Colors.white54, fontSize: 12)),
        ],
      ),
    );
  }
}

class _ThumbsGrid extends StatelessWidget {
  const _ThumbsGrid();

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GridView.builder(
        itemCount: 6,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 0.9,
        ),
        itemBuilder: (context, index) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.black38,
              border: Border.all(color: const Color(0xFF3A4B7C), width: 1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Color(0xFF0B1226),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(6)),
                    ),
                    child: const Icon(Icons.music_note, color: Colors.white54),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: Text(
                    'Item ${index + 1}',
                    style: const TextStyle(color: Colors.white60, fontSize: 11),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

