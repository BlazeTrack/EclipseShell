import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart' show ChangeNotifier, compute;
import 'package:just_audio/just_audio.dart';
import 'package:file_selector/file_selector.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../utils/scanner.dart';

class AudioHandlerImpl extends ChangeNotifier {
  final AudioPlayer _player = AudioPlayer();
  final ConcatenatingAudioSource _playlist = ConcatenatingAudioSource(children: []);
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
    if (stored.isNotEmpty) {
      await addFiles(stored, persist: false);
    }
    final settingsBox = Hive.box('settings');
    final storedScanRoot = settingsBox.get('scanRoot');
    if (storedScanRoot is String && storedScanRoot.isNotEmpty) {
      _scanRoot = storedScanRoot;
    }
    await _player.setAudioSource(_playlist);
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
