import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'audio/audio_handler.dart';
import 'ui/eclipse_shell_app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final audioHandler = await AudioHandlerImpl.init();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => audioHandler),
      ],
      child: const EclipseShellApp(),
    ),
  );
}
