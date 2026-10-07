import 'package:flutter/material.dart';

import '../../theme/lumo_visual_tokens.dart';

/// Night styling for a complete route subtree, including captured dialogs.
/// Does not change permissions, preferences or the legacy global app theme.
class LumoNightScope extends StatelessWidget {
  const LumoNightScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final original = Theme.of(context);
    const scheme = ColorScheme.dark(
      primary: LumoVisualTokens.cyanBright,
      onPrimary: LumoVisualTokens.night,
      secondary: LumoVisualTokens.gold,
      onSecondary: LumoVisualTokens.night,
      surface: LumoVisualTokens.navigation,
      onSurface: LumoVisualTokens.white,
      onSurfaceVariant: LumoVisualTokens.muted,
      surfaceContainerHighest: LumoVisualTokens.glassRow,
      error: Color(0xFFFFB4B4),
      onError: Color(0xFF44242C),
      outline: Color(0xFF6486AA),
    );
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: Color(0xFF6486AA)),
    );
    return Theme(
      data: original.copyWith(
        brightness: Brightness.dark,
        colorScheme: scheme,
        scaffoldBackgroundColor: LumoVisualTokens.night,
        canvasColor: LumoVisualTokens.navigation,
        disabledColor: const Color(0xFF91A6C0),
        dividerColor: const Color(0xFF36597D),
        textTheme: original.textTheme.apply(
          bodyColor: LumoVisualTokens.white,
          displayColor: LumoVisualTokens.white,
        ),
        iconTheme: const IconThemeData(color: LumoVisualTokens.cyanBright),
        dialogTheme: const DialogThemeData(
          backgroundColor: LumoVisualTokens.navigation,
          surfaceTintColor: Colors.transparent,
          titleTextStyle: TextStyle(
            fontFamily: 'Nunito', color: LumoVisualTokens.white,
            fontSize: 22, fontWeight: FontWeight.w900,
          ),
          contentTextStyle: TextStyle(
            fontFamily: 'Nunito', color: LumoVisualTokens.muted,
            fontSize: 15, height: 1.45,
          ),
        ),
        cardTheme: CardThemeData(
          color: LumoVisualTokens.glass,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF0B2A55),
          labelStyle: const TextStyle(color: LumoVisualTokens.muted),
          hintStyle: const TextStyle(color: Color(0xFFB8C8DF)),
          border: border, enabledBorder: border,
          focusedBorder: border.copyWith(
            borderSide: const BorderSide(color: LumoVisualTokens.cyanBright, width: 2),
          ),
        ),
        textSelectionTheme: const TextSelectionThemeData(
          cursorColor: LumoVisualTokens.cyanBright,
          selectionColor: Color(0x6637D2FD),
          selectionHandleColor: LumoVisualTokens.cyanBright,
        ),
        snackBarTheme: const SnackBarThemeData(
          backgroundColor: LumoVisualTokens.glassRow,
          contentTextStyle: TextStyle(color: LumoVisualTokens.white),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size(48, 48),
            backgroundColor: const Color(0xFF1267A2),
            foregroundColor: LumoVisualTokens.white,
            disabledBackgroundColor: const Color(0xFF243B59),
            disabledForegroundColor: const Color(0xFFB8C8DF),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(48, 48),
            foregroundColor: LumoVisualTokens.cyanBright,
            side: const BorderSide(color: Color(0xFF6486AA)),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            minimumSize: const Size(48, 48),
            foregroundColor: LumoVisualTokens.cyanBright,
          ),
        ),
        chipTheme: original.chipTheme.copyWith(
          backgroundColor: LumoVisualTokens.glassRow,
          selectedColor: const Color(0xFF14527B),
          labelStyle: const TextStyle(color: LumoVisualTokens.white),
          secondaryLabelStyle: const TextStyle(color: LumoVisualTokens.white),
        ),
      ),
      child: child,
    );
  }
}
