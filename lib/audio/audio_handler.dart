import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart' show ChangeNotifier, compute;
import 'package:just_audio/just_audio.dart' as just_audio;
import 'package:file_selector/file_selector.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../utils/scanner.dart';

class AudioHandlerImpl extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();
  final ConcatenatingAudioSource _playlist = ConcatenatingAudioSource(children: []);

  /// Looping del reproductor local.
  /// - off: reproduce una vez (se detiene al final)
  /// - all: loop de toda la cola
  /// - once: sin cambios vs off, pero mantenemos nomenclatura para UI
  LoopMode _loopMode = LoopMode.off;

  LoopMode get loopMode => _loopMode;

  Future<void> setLoopMode(LoopMode mode) async {
    _loopMode = mode;
    // JustAudio: `LoopMode.off` / `LoopMode.one` / `LoopMode.all`
    // Para "una vez": off.
    // Para "loop todo": all.
    switch (_loopMode) {
      case LoopMode.off:
      case LoopMode.once:
        await _player.setLoopMode(just_audio.LoopMode.off);
        break;
      case LoopMode.all:
        await _player.setLoopMode(just_audio.LoopMode.all);
        break;
    }
    notifyListeners();
  }

  /// Alias local para evitar confusión con LoopMode de just_audio (también existe).
  /// Usamos nuestros valores y los map-eamos arriba.
  enum LoopMode { off, once, all }
  final List<String> _paths = [];
  final List<Map<String, dynamic>> _metadata = [];
  bool _loadingFromStorage = false;
  bool _isShuffle = false;
  String? _scanRoot;

  AudioHandlerImpl() {
    _initialize();
  }

  Future<void> _initialize() async {
    _player.playerStateStream.listen((_) => notifyListeners());
    _player.currentIndexStream.listen((_) => notifyListeners());
    _player.positionStream.listen((_) => notifyListeners());
    // Load persisted playlist and scan root
    _loadingFromStorage = true;
    final playlistBox = Hive.box<List>('playlist');
    final storedRaw = playlistBox.get('default');
    final stored = storedRaw is List
        ? List<String>.from(storedRaw.whereType<String>())
        : <String>[];

    final settingsBox = Hive.box('settings');
    final storedScanRoot = settingsBox.get('scanRoot');
    if (storedScanRoot is String && storedScanRoot.isNotEmpty) {
      _scanRoot = storedScanRoot;
    }

    // Si no hay una cola persistida, intentamos escanear automáticamente una sola vez.
    // Esto corrige el comportamiento de "solo detecta pistas si seleccionas carpeta".
    if (stored.isNotEmpty) {
      await addFiles(stored, persist: false);
    } else {
      final rootPath = _scanRoot ?? _defaultScanRoot();
      if (rootPath != null && rootPath.isNotEmpty) {
        final found = await scanAndAddRoot(rootOverride: rootPath);
        // scanAndAddRoot ya se encarga de setear _scanRoot si hace falta.
        // scanAndAddRoot() llama a addFiles(...), que persiste la playlist y metadatos.
        // No es necesario usar el valor de found aquí; solo disparamos el escaneo una vez.
        // (para evitar nuevas ejecuciones, al final habrá playlist persistida)
        await found;

      }
    }

    await _player.setAudioSource(_playlist);
    // Inicializa loop por defecto
    await setLoopMode(LoopMode.off);
    _loadingFromStorage = false;
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
    final rootPath = rootOverride ?? _scanRoot ?? _defaultScanRoot();
    if (rootPath == null) return <String>[];
    if (_scanRoot == null) {
      await setScanRoot(rootPath);
    }
    final found = await compute(scanDirectoryPaths, rootPath);
    await addFiles(found);
    return found;
  }

  Future<String?> pickScanRoot() async {
    final selected = await getDirectoryPath();
    if (selected != null && selected.isNotEmpty) {
      await setScanRoot(selected);
    }
    return selected;
  }

  String? _defaultScanRoot() {
    if (Platform.isAndroid) {
      return '/storage/emulated/0/EclipseMusic';
    }
    final home = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'] ?? '.';
    return '$home/EclipseMusic';
  }

  Future<void> addFiles(List<String> paths, {bool persist = true}) async {
    for (final path in paths) {
      if (path.isEmpty) continue;
      if (_paths.contains(path)) continue;
      final fileName = path.split(Platform.pathSeparator).last;
      _paths.add(path);
      final metaBox = Hive.box('metadata');
      Map<String, dynamic>? meta;
      if (!persist && metaBox.containsKey(path)) {
        final stored = metaBox.get(path);
        if (stored is Map) meta = Map<String, dynamic>.from(stored);
      }
      meta ??= _readId3v1(path) ?? {'title': fileName};
      _metadata.add(meta);
      await _playlist.add(AudioSource.uri(Uri.file(path), tag: meta));
      // persist metadata per-file
      try {
        await metaBox.put(path, meta);
      } catch (_) {}
    }
    notifyListeners();
    if (persist) await _persist();
    if (!_player.playing && _paths.isNotEmpty) {
      await playIndex(_paths.length - 1);
    }
  }


  String _localSearchQuery = '';

  String get localSearchQuery => _localSearchQuery;

  void setLocalSearchQuery(String query) {
    _localSearchQuery = query;
    notifyListeners();
  }



  List<String> get filteredQueue {
    final q = _localSearchQuery.trim().toLowerCase();
    if (q.isEmpty) return queue;

    bool containsAny(Map<String, dynamic> meta) {
      final title = (meta['title'] ?? '').toString().toLowerCase();
      final artist = (meta['artist'] ?? '').toString().toLowerCase();
      final album = (meta['album'] ?? '').toString().toLowerCase();
      return title.contains(q) || artist.contains(q) || album.contains(q);
    }

    final out = <String>[];
    for (var i = 0; i < _paths.length; i++) {
      final meta = i < _metadata.length ? _metadata[i] : <String, dynamic>{};
      if (containsAny(meta)) out.add(_paths[i]);
    }
    return out;
  }

  String? get currentPath {
    final idx = _player.currentIndex;
    if (idx == null || idx < 0 || idx >= _paths.length) return null;
    return _paths[idx];
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

  String? _defaultScanRoot() {
    if (Platform.isAndroid) {
      return '/storage/emulated/0/EclipseMusic';
    }
    final home = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'] ?? '.';
    return '$home/EclipseMusic';
  }

  Map<String, String>? _readId3v1(String path) {
    try {
      final file = File(path);
      if (!file.existsSync()) return null;
      final raf = file.openSync(mode: FileMode.read);
      final len = raf.lengthSync();
      if (len < 128) {
        raf.closeSync();
        return null;
      }
      raf.setPositionSync(len - 128);
      final bytes = raf.readSync(128);
      raf.closeSync();
      final tag = String.fromCharCodes(bytes.sublist(0, 3));
      if (tag != 'TAG') return null;
      String readString(List<int> b) => String.fromCharCodes(b).trim().replaceAll('\u0000', '');
      final title = readString(bytes.sublist(3, 33));
      final artist = readString(bytes.sublist(33, 63));
      final album = readString(bytes.sublist(63, 93));
      return {'title': title.isNotEmpty ? title : path.split(Platform.pathSeparator).last, 'artist': artist, 'album': album};
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
