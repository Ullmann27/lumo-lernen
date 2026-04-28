import 'package:flutter/material.dart';
import 'lumo_design_tokens.dart';

class LumoAppTheme {
  const LumoAppTheme._();

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: LumoColors.brandOrange,
      brightness: Brightness.light,
      surface: LumoColors.cream,
      primary: LumoColors.brandOrange,
      secondary: LumoColors.lavender,
      tertiary: LumoColors.mint,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: LumoColors.cream,
      fontFamily: 'Roboto',
      textTheme: const TextTheme(
        headlineLarge: LumoTextStyles.headline,
        titleMedium: LumoTextStyles.subtitle,
        bodyMedium: TextStyle(color: LumoColors.warmText, fontWeight: FontWeight.w600),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(LumoRadius.pill)),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          textStyle: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(LumoRadius.pill)),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(LumoRadius.pill)),
        labelStyle: const TextStyle(fontWeight: FontWeight.w800, color: LumoColors.warmText),
        backgroundColor: Colors.white.withOpacity(.78),
        selectedColor: LumoColors.peach.withOpacity(.7),
        side: BorderSide(color: Colors.white.withOpacity(.75)),
      ),
      cardTheme: CardThemeData(
        color: Colors.white.withOpacity(.78),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(LumoRadius.card)),
        margin: EdgeInsets.zero,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: LumoColors.cream,
        indicatorColor: LumoColors.peach.withOpacity(.55),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (_) => const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: LumoColors.warmText),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withOpacity(.78),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(LumoRadius.card),
          borderSide: BorderSide(color: Colors.white.withOpacity(.8)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(LumoRadius.card),
          borderSide: BorderSide(color: Colors.white.withOpacity(.8)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(LumoRadius.card),
          borderSide: const BorderSide(color: LumoColors.brandOrange, width: 1.4),
        ),
      ),
    );
  }
}
