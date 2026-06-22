# EclipseShell

EclipseShell es un reproductor de música local con estética inspirada en MoonShell (NDS). Su objetivo es ofrecer una experiencia visual retro y una reproducción suave de archivos locales, con una interfaz cuidada y controles tipo "ventana".

<img width="584" height="1280" alt="image" src="https://github.com/user-attachments/assets/c0eaa9cd-212b-4cb9-a530-24d890a552ce" />
<img width="354" height="644" alt="image" src="https://github.com/user-attachments/assets/25589846-4156-4a3f-8244-47a121f0f08d" />

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

**Pruebas y ejecución (pasos estables recomendados)**

- Entorno: prueba en una máquina con Flutter SDK y plataformas Android (carpeta `android/`).
- Dependencias nativas: algunos paquetes (`flutter_media_metadata`, `image`) requieren compilación nativa; asegúrate de tener el SDK de Android configurado.

Comandos básicos para desarrollo y verificación:

```bash
flutter pub get
flutter analyze
flutter run
```

Para construir un APK release (CI o local):

```bash
flutter pub get
flutter build apk --release
```

Si hay conflictos de resolución de paquetes en CI (p. ej. por versiones de Dart/Flutter), una forma segura es actualizar solo en la máquina de CI:

```bash
# intenta resolver mayores versiones en CI si es apropiado
flutter pub upgrade --major-versions
```

**Configuración CI (recomendación estable)**

- Usa un runner con una versión estable de Flutter (por ejemplo, la rama `stable`) y asegúrate de que la versión de Dart sea compatible con las dependencias del `pubspec.yaml`.
- Ejecuta `flutter pub get` antes de construir. Si ves errores de resolución, revisa `pubspec.yaml` y evita dependencias muy nuevas o inestables — prefieres fijar versiones comprobadas.
- Añade estos pasos en tu flujo de CI:

```yaml
- name: Install Flutter
	uses: subosito/flutter-action@v2
	with:
		channel: 'stable'

- name: Get dependencies
	run: flutter pub get

- name: Analyze
	run: flutter analyze

- name: Build APK
	run: flutter build apk --release
```

**Permisos Android**

- Para escanear almacenamiento en dispositivos Android modernos puede ser necesario pedir permisos en tiempo de ejecución o adaptar scoped storage. Agrega los permisos apropiados en `android/app/src/main/AndroidManifest.xml` (ej. `READ_EXTERNAL_STORAGE`) y maneja solicitudes en runtime desde la app si apuntas a API levels que lo requieren.

**Notas sobre dependencias y compatibilidad**

- Si tu CI falla con errores tipo "version solving failed" revisa si alguna dependencia no está disponible para la versión de Dart/Flutter del runner. En este repositorio se eliminó temporalmente `rxdart` para evitar un fallo de resolución en CI; si la necesitas, pínchala a una versión compatible con tu runner.

---

Si quieres, escribo un archivo `ci.yml` de ejemplo listo para GitHub Actions y añado pasos para solicitar permisos en Android y pruebas manuales detalladas. ¿Lo genero ahora? 
