import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app/app_shell.dart';
import 'app/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
    DeviceOrientation.portraitUp,
  ]);
  runApp(const LumoApp());
}

class LumoApp extends StatelessWidget {
  const LumoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lumo Lernen',
      debugShowCheckedModeBanner: false,
      theme: LumoAppTheme.light(),
      home: const AppShell(),
    );
  }
}
