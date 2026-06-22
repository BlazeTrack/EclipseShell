import 'dart:io';

// Top-level function for compute/isolate usage.
List<String> scanDirectoryPaths(String rootPath) {
  final results = <String>[];
  try {
    final root = Directory(rootPath);
    if (!root.existsSync()) return results;
    final walker = root.listSync(recursive: true);
    for (final entry in walker) {
      if (entry is File) {
        final path = entry.path.toLowerCase();
        if (path.endsWith('.mp3') || path.endsWith('.wav') || path.endsWith('.m4a') || path.endsWith('.aac') || path.endsWith('.flac') || path.endsWith('.ogg')) {
          results.add(entry.path);
        }
      }
    }
  } catch (_) {
    // ignore errors, return what we found
  }
  return results;
}
