import 'package:flutter/material.dart';
import 'navigation/adaptive_nav.dart';
import 'theme/app_theme.dart';

class LumoLernenApp extends StatelessWidget {
  const LumoLernenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lumo Lernen',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: const AdaptiveNav(),
    );
  }
}
