import 'package:flutter/material.dart';

class AppTheme {
  static const Color orange = Color(0xFFFF8C42);
  static const Color cream = Color(0xFFFFF8F0);
  static const Color turquoise = Color(0xFF4ECDC4);
  static const Color softGreen = Color(0xFF95D5B2);
  static const Color lightBlue = Color(0xFF87CEEB);
  static const Color yellow = Color(0xFFFFD166);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: orange,
        primary: orange,
        secondary: turquoise,
        surface: cream,
        // ignore: deprecated_member_use
        background: cream,
      ),
      scaffoldBackgroundColor: cream,
      cardTheme: CardTheme(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        color: Colors.white.withOpacity(0.9),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: orange,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF2D2D2D)),
        headlineMedium: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2D2D2D)),
        bodyLarge: TextStyle(fontSize: 18, color: Color(0xFF4A4A4A)),
        bodyMedium: TextStyle(fontSize: 16, color: Color(0xFF4A4A4A)),
      ),
    );
  }
}
