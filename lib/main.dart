import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'audio/audio_handler.dart';
import 'ui/eclipse_shell_app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
