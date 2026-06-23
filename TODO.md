# TODO - Fix "unsupported Gradle project" (Flutter)

## Paso 1: Regenerar Android con template soportado (sin ejecutar aquí)
- [ ] Crear proyecto nuevo: `flutter create -t app <app-directory-nuevo>`
- [ ] Mantener paquete `com.example.eclipseshell` en manifest/actividad/build.gradle del proyecto nuevo (ajustar si hace falta)

## Paso 2: Migrar contenido
- [ ] Copiar `lib/` del proyecto actual al nuevo
- [ ] Copiar `assets/` del proyecto actual al nuevo
- [ ] Copiar `pubspec.yaml` del proyecto actual al nuevo

## Paso 3: Sustituir carpeta android final
- [ ] Reemplazar la carpeta `android/` del proyecto original con la del template soportado (del nuevo proyecto)
- [ ] Verificar recursos requeridos (por ejemplo `android/app/src/main/res/` si aplica)

## Paso 4: Validación
- [ ] Ejecutar `flutter build apk --release --no-pub`
- [ ] Confirmar que desaparece el error de “unsupported Gradle project”

