# TODO - Fix “unsupported Gradle project” for Flutter CI

- [ ] Confirm what Flutter expects in `android/` for the installed Flutter version (missing template files, gradle properties, gradle plugin setup, etc.)
- [ ] Create a temporary Flutter app scaffold in a working environment (where `flutter` is available) and compare its `android/` folder with this repo’s `android/` folder.
- [ ] Copy/merge the missing/changed files from the fresh scaffold into this repo’s `android/` (keeping `lib/`, `assets/`, `pubspec.yaml` intact).
- [ ] Remove any incompatible Gradle config and ensure `android/gradle/wrapper/gradle-wrapper.properties` + plugin versions match Flutter’s expectations.
- [ ] Re-run `flutter build apk --release --no-pub` and verify the CI step passes.

