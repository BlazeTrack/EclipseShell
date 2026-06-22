import 'package:flutter/material.dart';
import 'starfield_painter.dart'; // Importación vital para el fondo animado

class EclipseShellApp extends StatefulWidget {
  const EclipseShellApp({Key? key}) : super(key: key);

  @override
  State<EclipseShellApp> createState() => _EclipseShellAppState();
}

class _EclipseShellAppState extends State<EclipseShellApp> {
  // --- AQUÍ COMIENZA EL MÉTODO BUILD PRINCIPAL ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF02030A),
      body: Stack(
        children: [
          // 1. Fondo Cósmico con gradiente estilo MoonShell
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
          // 2. Efecto de Estrellas de fondo
          Positioned.fill(
            child: CustomPaint(
              painter: StarfieldPainter(), 
            ),
          ),
          // 3. Interfaz de ventanas rígidas estilo DS
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Expanded(
                    child: _buildWindow(
                      title: 'MOONSHL FILE EXPLORER',
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
      ),
    );
  }

  // --- COMPONENTES AUXILIARES DE LA INTERFAZ ---
  Widget _buildWindow({required String title, required Widget child}) {
    return Card(
      color: Colors.black45,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: Color(0xFF3A4B7C), width: 2), // Borde rígido retro
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
    // TODO: Vincular con la lógica de archivos de audio_handler posterior
    return const Center(
      child: Text('Explorador de Archivos', style: TextStyle(color: Colors.white70)),
    );
  }

  Widget _buildPlayControl() {
    // TODO: Diseñar botones de reproducción (Play, Stop, Skip)
    return const Center(
      child: Text('Panel de Control de Audio', style: TextStyle(color: Colors.white70)),
    );
  }
}