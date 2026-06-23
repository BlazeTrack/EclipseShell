import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart' show ChangeNotifier, compute;
import 'package:just_audio/just_audio.dart';
import 'package:file_selector/file_selector.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../utils/scanner.dart';
import '../utils/metadata.dart';

class AudioHandlerImpl extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();
  final ConcatenatingAudioSource _playlist = ConcatenatingAudioSource(children: []);
  final List<String> _paths = [];
  final List<Map<String, dynamic>> _metadata = [];
  bool _loadingFromStorage = false;
  bool _isShuffle = false;
  String? _scanRoot;
  String? _artDir;
  bool lastScanPermissionDenied = false;

  AudioHandlerImpl() {
    _initialize();
  }

  Future<void> _initialize() async {
    _player.playerStateStream.listen((_) => notifyListeners());
    _player.currentIndexStream.listen((_) => notifyListeners());
    _player.positionStream.listen((_) => notifyListeners());

    try {
      final dir = await getTemporaryDirectory();
      _artDir = '${dir.path}/eclipse_art';
      await Directory(_artDir!).create(recursive: true);
    } catch (_) {}

    // Attach the (empty) playlist to the player BEFORE restoring tracks so that
    // later additions are live and playable. Restoring before this left the
    // player without a usable source, so saved tracks would not play after a
    // restart.
    await _player.setAudioSource(_playlist);

    final settingsBox = Hive.box('settings');
    final storedScanRoot = settingsBox.get('scanRoot');
    if (storedScanRoot is String && storedScanRoot.isNotEmpty) {
      _scanRoot = storedScanRoot;
    }

    // Restore the saved playlist without auto-playing it.
    _loadingFromStorage = true;
    final playlistBox = Hive.box<List>('playlist');
    final storedRaw = playlistBox.get('default');
    final stored = storedRaw is List
        ? List<String>.from(storedRaw.whereType<String>())
        : <String>[];
    if (stored.isNotEmpty) {
      await addFiles(stored, persist: false, autoPlay: false);
    }
    _loadingFromStorage = false;
    notifyListeners();
  }

  List<String> get queue => List.unmodifiable(_paths);

  List<Map<String, dynamic>> get metadataList => List.unmodifiable(_metadata);

  bool get isPlaying => _player.playing;

  bool get isShuffle => _isShuffle;

  Map<String, dynamic> get currentMetadata {
    final index = _player.currentIndex;
    if (index == null || index < 0 || index >= _metadata.length) return {'title': 'Sin pista seleccionada'};
    return _metadata[index];
  }

  String? get currentTitle {
    final meta = currentMetadata;
    final t = meta['title'];
    if (t is String && t.isNotEmpty) return t;
    final idx = _player.currentIndex;
    if (idx == null || idx < 0 || idx >= _paths.length) return null;
    return _paths[idx].split(Platform.pathSeparator).last;
  }


  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;

  Duration get position => _player.position;

  Duration get duration => _player.duration ?? Duration.zero;

  Future<void> _persist() async {
    if (_loadingFromStorage) return;
    final box = Hive.box<List>('playlist');
    await box.put('default', _paths);
  }

  Future<void> setScanRoot(String path) async {
    _scanRoot = path;
    final settingsBox = Hive.box('settings');
    await settingsBox.put('scanRoot', path);
    notifyListeners();
  }

  String? get scanRoot => _scanRoot;

  Future<List<String>> scanAndAddRoot({String? rootOverride}) async {
    lastScanPermissionDenied = false;
    final granted = await _ensureStoragePermission();
    if (!granted) {
      lastScanPermissionDenied = true;
      notifyListeners();
      return <String>[];
    }
    final rootPath = rootOverride ?? _scanRoot ?? _defaultScanRoot();
    if (rootPath == null) return <String>[];
    if (_scanRoot == null) {
      await setScanRoot(rootPath);
    }
    final found = await compute(scanDirectoryPaths, rootPath);
    await addFiles(found);
    return found;
  }

  Future<bool> _ensureStoragePermission() async {
    if (!Platform.isAndroid) return true;
    if (await Permission.manageExternalStorage.isGranted) return true;
    // Granular media permission (Android 13+) and legacy storage (<=12).
    final audio = await Permission.audio.request();
    final storage = await Permission.storage.request();
    // All-files access is required to read arbitrary folders by raw path.
    final manage = await Permission.manageExternalStorage.request();
    return manage.isGranted || audio.isGranted || storage.isGranted;
  }

  Future<String?> pickScanRoot() async {
    final selected = await getDirectoryPath();
    if (selected != null && selected.isNotEmpty) {
      final normalized = _normalizeAndroidDirPath(selected);
      await setScanRoot(normalized);
      return normalized;
    }
    return selected;
  }

  // file_selector may return a Storage Access Framework tree URI on Android
  // (e.g. content://.../tree/primary:Music/Sub). Convert it to a raw filesystem
  // path so the recursive scanner can read it.
  String _normalizeAndroidDirPath(String p) {
    if (!Platform.isAndroid) return p;
    final decoded = Uri.decodeFull(p);
    final match = RegExp(r'tree/([^:/]+):(.*)$').firstMatch(decoded);
    if (match != null) {
      final volume = match.group(1)!;
      final rel = match.group(2) ?? '';
      final base = volume == 'primary' ? '/storage/emulated/0' : '/storage/$volume';
      return '$base/$rel'.replaceAll(RegExp(r'/+$'), '');
    }
    return p;
  }

  String? _defaultScanRoot() {
    if (Platform.isAndroid) {
      return '/storage/emulated/0/Download/EclipseMusic';
    }
    final home = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'] ?? '.';
    return '$home/EclipseMusic';
  }

  Future<void> addFiles(List<String> paths, {bool persist = true, bool autoPlay = true}) async {
    for (final path in paths) {
      if (path.isEmpty) continue;
      if (_paths.contains(path)) continue;
      final fileName = path.split(Platform.pathSeparator).last;
      _paths.add(path);
      final metaBox = Hive.box('metadata');
      Map<String, dynamic>? meta;
      if (metaBox.containsKey(path)) {
        final stored = metaBox.get(path);
        if (stored is Map) meta = Map<String, dynamic>.from(stored);
      }
      meta ??= _buildMetadata(path, fileName);
      _metadata.add(meta);
      await _playlist.add(AudioSource.uri(Uri.file(path), tag: meta));
      // persist metadata per-file
      try {
        await metaBox.put(path, meta);
      } catch (_) {}
    }
    notifyListeners();
    if (persist) await _persist();
    if (autoPlay && !_player.playing && _paths.isNotEmpty) {
      await playIndex(_paths.length - 1);
    }
  }

  Map<String, dynamic> _buildMetadata(String path, String fileName) {
    final tags = readTrackTags(path);
    final meta = <String, dynamic>{
      'title': tags.title ?? fileName,
      'artist': tags.artist ?? '',
      'album': tags.album ?? '',
    };
    final art = tags.artwork;
    if (art != null && art.isNotEmpty && _artDir != null) {
      try {
        final artFile = File('$_artDir/${path.hashCode}.img');
        artFile.writeAsBytesSync(art, flush: true);
        meta['artPath'] = artFile.path;
      } catch (_) {}
    }
    return meta;
  }


  Map<String, dynamic>? metadataForPath(String path) {
    final box = Hive.box('metadata');
    final v = box.get(path);
    if (v == null) return null;
    if (v is Map) return Map<String, dynamic>.from(v);
    return null;
  }


  Future<void> play() async {
    await _player.play();
    notifyListeners();
  }

  Future<void> pause() async {
    await _player.pause();
    notifyListeners();
  }

  Future<void> stop() async {
    await _player.stop();
    notifyListeners();
  }

  Future<void> seekTo(Duration position) async {
    await _player.seek(position);
    notifyListeners();
  }

  Future<void> playIndex(int index) async {
    if (index < 0 || index >= _paths.length) return;
    await _player.seek(Duration.zero, index: index);
    await play();
    notifyListeners();
  }

  Future<void> skipToNext() async {
    await _player.seekToNext();
    notifyListeners();
  }

  Future<void> skipToPrevious() async {
    await _player.seekToPrevious();
    notifyListeners();
  }

  Future<void> toggleShuffle() async {
    _isShuffle = !_isShuffle;
    await _player.setShuffleModeEnabled(_isShuffle);
    if (_isShuffle) {
      await _player.shuffle();
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
