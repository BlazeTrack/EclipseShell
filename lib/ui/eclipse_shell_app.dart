import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../audio/audio_handler.dart'; // Asegúrate de que apunte bien a tu archivo de audio

class EclipseShellApp extends StatelessWidget {
  const EclipseShellApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Suponiendo que obtienes tu manejador mediante Provider
    final audioHandler = Provider.of<AudioHandlerImpl>(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ... Tus widgets superiores ...

            // 1. CORREGIDO: Bloque Builder con llaves, paréntesis y retornos bien estructurados
            Builder(
              builder: (context) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Controles de Reproducción'),
                    const SizedBox(height: 4),
                    
                    // Botón de Shuffle (Llama al método corregido)
                    IconButton(
                      icon: const Icon(Icons.shuffle),
                      onPressed: () async => await audioHandler.toggleShuffle(),
                    ),
                    const SizedBox(height: 8),

                    // 2. CORREGIDO: Selección de LoopMode sin el prefijo de clase antiguo
                    PopupMenuButton<LoopMode>(
                      initialValue: audioHandler.loopMode,
                      onSelected: (LoopMode mode) async {
                        await audioHandler.setLoopMode(mode);
                      },
                      itemBuilder: (BuildContext context) => <PopupMenuEntry<LoopMode>>[
                        const PopupMenuItem<LoopMode>(
                          value: LoopMode.off,
                          child: Text('Repetir: Apagado'),
                        ),
                        const PopupMenuItem<LoopMode>(
                          value: LoopMode.all,
                          child: Text('Repetir: Todo'),
                        ),
                        const PopupMenuItem<LoopMode>(
                          value: LoopMode.once,
                          child: Text('Repetir: Una'),
                        ),
                      ],
                      child: Icon(
                        audioHandler.loopMode == LoopMode.all 
                            ? Icons.repeat 
                            : Icons.repeat_one,
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                );
              },
            ), // Cierre correcto del Builder

            // ... El resto de los elementos de tu interfaz ...
          ],
        ),
      ),
    );
  }
}