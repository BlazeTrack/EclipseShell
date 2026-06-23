import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'audio/audio_handler.dart';
import 'ui/eclipse_shell_app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  await Hive.initFlutter();
  await Hive.openBox<List>('playlist');
  await Hive.openBox('metadata');
  await Hive.openBox('settings');
  runApp(
    MultiProvider(
      providers: [
       Provider<AudioHandlerImpl>(create: (_) => AudioHandlerImpl()),
      ],
      child: const MaterialApp(
        title: 'EclipseShell',
        debugShowCheckedModeBanner: false,
        home: EclipseShellApp(),
      ),
    ),
  );
}
