import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'audio/audio_handler.dart';
import 'ui/eclipse_shell_app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox<List>('playlist');
  await Hive.openBox('metadata');
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AudioHandlerImpl()),
      ],
      child: const MaterialApp(
        title: 'EclipseShell',
        debugShowCheckedModeBanner: false,
        home: EclipseShellApp(),
      ),
    ),
  );
}
