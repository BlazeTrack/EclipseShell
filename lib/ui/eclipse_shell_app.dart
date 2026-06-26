import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'starfield_painter.dart';
import 'local_player_panel.dart';
import 'downloader_panel.dart';

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
  
  // Controlador para manejar el deslizamiento de pantallas
  final PageController _pageController = PageController(initialPage: 0);
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pageController.dispose();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF02030A),
      body: LayoutBuilder(
        builder: (context, constraints) {
          _initializeStars(constraints.biggest);
          return Stack(
            children: [
              // Fondo de Degradado Espacial
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
              // Capa de Estrellas Estática estilo MoonShell
              Positioned.fill(
                child: CustomPaint(
                  painter: StarfieldPainter(
                    stars: _stars!,
                    eclipseCenter: _eclipseCenter!,
                    eclipseRadius: _eclipseRadius!,
                  ),
                ),
              ),
              // Sistema de Deslizamiento entre Pantallas Dedicadas
              SafeArea(
                child: Column(
                  children: [
                    // Indicador Visual de Ventana Activa (Opcional, estilo retro)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 12.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _currentPage == 0 ? "MODE: LOCAL PLAYER" : "MODE: NET DOWNLOADER",
                            style: const TextStyle(color: Colors.white54, fontSize: 10, fontFamily: 'monospace', fontWeight: FontWeight.bold),
                          ),
                          Row(
                            children: [
                              Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: _currentPage == 0 ? Colors.cyanAccent : Colors.white24)),
                              const SizedBox(width: 6),
                              Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: _currentPage == 1 ? Colors.cyanAccent : Colors.white24)),
                            ],
                          )
                        ],
                      ),
                    ),
                    Expanded(
                      child: PageView(
                        controller: _pageController,
                        onPageChanged: (index) {
                          setState(() {
                            _currentPage = index;
                          });
                        },
                        children: [
                          // Pantalla 1: Reproductor Local
                          const LocalPlayerPanel(),
                          // Pantalla 2: Descargador Dedicado
                          DownloaderPanel(
                            onBackToPlayer: () {
                              _pageController.animateToPage(0, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}