# EclipseShell

EclipseShell es un reproductor de música local con estética inspirada en MoonShell (NDS). Su objetivo es ofrecer una experiencia visual retro y una reproducción suave de archivos locales, con una interfaz cuidada y controles tipo "ventana".

**Qué hace**

- Reproduce archivos de audio locales en cola (gapless con `just_audio`).
- Interfaz estilo MoonShell: fondo estrellado, ventanas tipo retro y controles de reproducción sencillos.
- Explorador básico de pistas y controles de reproducción (play/pause/skip/seek).

**Características actuales**

- Reproducción local usando `just_audio`.
- Cola dinámica y selección de pista para reproducir.
- Barra de progreso y información de pista actual.
- Fondo animado/estético (starfield) inspirado en MoonShell.
- Gestión simple del estado con `provider`.

**Instalación (desarrollo)**

1. Instala Flutter y asegura que `flutter` esté en tu PATH.
2. Desde la raíz del proyecto:

```bash
flutter pub get
flutter run
```

(Para compilación release: `flutter build apk --release` — requiere carpetas `android/` y SDK configurado.)

**Uso**

- Ejecuta la app, abre el "ECLIPSESHELL FILE EXPLORER" y agrega pistas locales.
- Usa los controles en la sección "PLAYCONTROL" para reproducir/pausar/avanzar.

**Roadmap / Futuro deseado**

Estos son objetivos y mejoras planeadas:

- App de streaming integrada: reproducir desde fuentes remotas (HTTP, HLS).
- Descargador y gestor de archivos FLAC con soporte para metadatos y descargas en background.
- Mantener la estética MoonShell (paleta, tipografías, ventanas) como línea guía UI/UX.
- Integración nativa (Android/iOS): permisos, notificaciones de reproducción y controles en lockscreen.
- Mejoras de accesibilidad y rendimiento (carga progresiva, manejo de colas grandes).
- Sincronización offline + cache para streaming y descargas.
- Empaquetado y publicación en Play Store / App Store.

**Contribuir**

Pull requests y issues bienvenidos. Para grandes cambios, abre primero un issue describiendo la propuesta.

**Licencia**

Propuesta: MIT — modifica según prefieras.

---

_Nota:_ Algunos plugins que facilitan la selección de archivos pueden tener problemas de compatibilidad con ciertos targets. Si la selección de archivos no funciona en tu plataforma, revisa `pubspec.yaml` y considera usar `file_selector` o implementar un canal nativo.
