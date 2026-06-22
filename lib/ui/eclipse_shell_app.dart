import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../audio/audio_handler.dart';
import 'starfield_painter.dart';

class EclipseShellApp extends StatelessWidget {
  const EclipseShellApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'EclipseShell',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.transparent,
        textTheme: ThemeData.dark().textTheme.apply(
              fontFamily: 'monospace',
            ),
      ),
      home: const Scaffold(
        body: EclipseShellHome(),
      ),
    );
  }
}

class EclipseShellHome extends StatefulWidget {
  const EclipseShellHome({super.key});

  @override
  State<EclipseShellHome> createState() => _EclipseShellHomeState();
}

class _EclipseShellHomeState extends State<EclipseShellHome> {
  Directory? _currentDir;
  List<FileSystemEntity> _children = [];

  @override
  void initState() {
    super.initState();
    _loadInitialDirectory();
  }

  Future<void> _loadInitialDirectory() async {
    final audioHandler = context.read<AudioHandlerImpl>();
    final root = await audioHandler.getLocalMusicRoot();
    setState(() => _currentDir = root);
    _refreshChildren(root);
  }

  Future<void> _refreshChildren(Directory dir) async {
    final audioHandler = context.read<AudioHandlerImpl>();
    final items = await audioHandler.listDirectory(dir);
    items.sort((a, b) {
      if (a is Directory && b is File) return -1;
      if (a is File && b is Directory) return 1;
      return a.path.compareTo(b.path);
    });
    setState(() {
      _children = items;
      _currentDir = dir;
    });
  }

  Widget _buildWindow({required Widget child, required String title}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.72),
        border: Border.all(color: Colors.blue.shade200, width: 2),
        boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Container(
            height: 28,
            color: const Color(0xFF1A3E9E),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            alignment: Alignment.centerLeft,
            child: Row(
              children: [
                Text(title, style: const TextStyle(fontFamily: 'monospace', fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                const Spacer(),
                _buildCloseButton(),
              ],
            ),
          ),
          Expanded(child: Padding(padding: const EdgeInsets.all(10), child: child)),
        ],
      ),
    );
  }

  Widget _buildCloseButton() {
    return Container(
      width: 22,
      height: 18,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white70, width: 1),
        color: Colors.red.shade700,
      ),
      child: const Text('X', style: TextStyle(fontSize: 12, fontFamily: 'monospace', color: Colors.white)),
    );
  }

  Widget _buildFileExplorer() {
    final currentPath = _currentDir?.path ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Path: $currentPath', style: const TextStyle(fontSize: 12, fontFamily: 'monospace')),
        const SizedBox(height: 8),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.blueAccent.shade100, width: 1),
            ),
            child: ListView.builder(
              itemCount: _children.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  final parent = _currentDir?.parent;
                  return _buildFileRow('..', parent?.path ?? '/', isParent: true);
                }
                final entity = _children[index - 1];
                final name = entity.path.split(Platform.pathSeparator).last;
                final suffix = entity is File ? '${entity.lengthSync()} bytes' : '<DIR>';
                return _buildFileRow(name, suffix, entity: entity);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFileRow(String name, String suffix, {FileSystemEntity? entity, bool isParent = false}) {
    return InkWell(
      onTap: () {
        if (isParent && _currentDir != null) {
          _refreshChildren(_currentDir!.parent);
        } else if (entity is Directory) {
          _refreshChildren(entity);
        } else if (entity is File) {
          context.read<AudioHandlerImpl>().addFile(entity);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white12, width: 0.5))),
        child: Row(
          children: [
            Expanded(child: Text(name, style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: Colors.white))),
            Text(suffix, style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: Colors.white70)),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayControl() {
    return Consumer<AudioHandlerImpl>(builder: (context, audioHandler, child) {
      final playing = audioHandler.isPlaying;
      final currentMedia = audioHandler.currentMedia;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            _buildStatusBadge(playing ? 'PLAYING' : 'PAUSED'),
            const SizedBox(width: 8),
            _buildStatusBadge(audioHandler.isLooping ? 'LOOP ON' : 'LOOP OFF'),
          ]),
          const SizedBox(height: 12),
          Text('Track: ${currentMedia?.title ?? 'None'}', style: const TextStyle(fontFamily: 'monospace', fontSize: 14)),
          const SizedBox(height: 6),
          Text('Artist: ${currentMedia?.artist ?? 'Unknown'}', style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: Colors.white70)),
          const SizedBox(height: 6),
          Text('Volume: x${(audioHandler.volume * 100).round()}', style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: Colors.white70)),
          const SizedBox(height: 16),
          Row(children: [
            _buildControlButton('PREV', audioHandler.skipToPrevious),
            const SizedBox(width: 8),
            _buildControlButton(playing ? 'PAUSE' : 'PLAY', playing ? audioHandler.pause : audioHandler.play),
            const SizedBox(width: 8),
            _buildControlButton('NEXT', audioHandler.skipToNext),
            const SizedBox(width: 8),
            _buildControlButton('LOOP', audioHandler.toggleLoop),
          ]),
          const SizedBox(height: 16),
          Row(children: [
            const Text('Volume:', style: TextStyle(fontFamily: 'monospace', fontSize: 12)),
            Expanded(
              child: Slider(
                value: audioHandler.volume,
                min: 0,
                max: 1,
                divisions: 10,
                onChanged: (value) => audioHandler.setVolume(value),
              ),
            ),
          ]),
        ],
      );
    });
  }

  Widget _buildStatusBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade900,
        border: Border.all(color: Colors.blueAccent.shade100),
      ),
      child: Text(label, style: const TextStyle(fontFamily: 'monospace', fontSize: 10, color: Colors.white)),
    );
  }

  Widget _buildControlButton(String label, VoidCallback onPressed) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.transparent,
        side: const BorderSide(color: Colors.white54),
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      ),
      onPressed: onPressed,
      child: Text(label, style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: Colors.white)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
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
        Positioned.fill(
          child: CustomPaint(
            painter: _StarfieldPainter(),
          ),
        ),
        SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Expanded(
                child: _buildWindow(
                  title: 'MOONSHL FILE EXPLORER',
                  child: _buildFileExplorer(),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 280,
                child: _buildWindow(
                  title: 'PLAYCONTROL',
                  child: _buildPlayControl(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
