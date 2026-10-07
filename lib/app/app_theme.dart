import 'package:flutter/material.dart';

import '../widgets/design/lumo_motion.dart';

// ═══════════════════════════════════════════════════════════
//  LUMO LERNEN – DESIGN TOKENS
//  Single source of truth for every visual decision.
// ═══════════════════════════════════════════════════════════

class LumoColors {
  LumoColors._();

  static const appBg        = Color(0xFF03193F);
  static const leftNavBg    = Color(0xFF061839);
  static const cardBg       = Color(0xE60B2A55);
  static const stageBg1     = Color(0xFF0A315D);
  static const stageBg2     = Color(0xFF071F46);

  static const orange       = Color(0xFFFF7A2F);
  static const orangeLight  = Color(0xFFFF9A5C);
  static const orangeGlow   = Color(0x33FF7A2F);
  static const orangeSurface= Color(0xFF3A2B28);

  static const purple       = Color(0xFF8B5CF6);
  static const purpleLight  = Color(0xFFA78BFA);
  static const purpleSurface= Color(0xFF24285A);

  static const teal         = Color(0xFF10A894);
  static const tealLight    = Color(0xFF34D399);
  static const tealSurface  = Color(0xFF123E4F);

  static const gold         = Color(0xFFFFB800);
  static const goldLight    = Color(0xFFFFD166);
  static const goldSurface  = Color(0xFF3A3524);

  static const blue         = Color(0xFF3B82F6);
  static const blueSurface  = Color(0xFF15345F);

  static const math         = Color(0xFFFF8700);
  static const mathSurface  = Color(0xFF3B3020);
  static const german       = Color(0xFF8B5CF6);
  static const germanSurface= Color(0xFF2E255F);
  static const english      = Color(0xFF10A894);
  static const englishSurface=Color(0xFF123F4C);
  static const practice     = Color(0xFFFF625D);
  static const practiceSurface=Color(0xFF432A32);
  static const testColor    = Color(0xFF3A86E8);
  static const testSurface  = Color(0xFF17345F);
  static const schoolwork   = Color(0xFFFF9800);
  static const schoolworkSurface=Color(0xFF403122);
  static const scanner      = Color(0xFF9C55E8);
  static const scannerSurface=Color(0xFF30245A);
  static const continueColor= Color(0xFF08A892);
  static const continueSurface=Color(0xFF123F4A);

  static const ink900       = Color(0xFFF7FBFF);
  static const ink700       = Color(0xFFDDEBFA);
  static const ink600       = Color(0xFFC8DDF0);
  static const ink500       = Color(0xFFB8C8DF);
  static const ink400       = Color(0xFF91A9C4);
  static const ink300       = Color(0xFF748DAA);
  static const ink100       = Color(0xFF28486D);
}

class LumoRadius {
  LumoRadius._();
  static const xs   = 10.0;
  static const sm   = 14.0;
  static const md   = 20.0;
  static const lg   = 26.0;
  static const xl   = 32.0;
  static const pill = 99.0;
}

class LumoShadow {
  LumoShadow._();

  static List<BoxShadow> card = [
    BoxShadow(color: const Color(0xFF37D2FD).withOpacity(.16), blurRadius: 24, offset: const Offset(0, 10)),
    const BoxShadow(color: Color(0x66000000), blurRadius: 18, offset: Offset(0, 12)),
  ];

  static List<BoxShadow> pill = [
    BoxShadow(color: const Color(0xFFFF7A2F).withOpacity(.28), blurRadius: 18, offset: const Offset(0, 8)),
  ];

  static List<BoxShadow> stage = [
    BoxShadow(color: const Color(0xFFFFB96B).withOpacity(.22), blurRadius: 40, offset: const Offset(0, 20)),
  ];

  static List<BoxShadow> hologram(Color color) => [
    BoxShadow(color: color.withOpacity(.28), blurRadius: 28, offset: const Offset(0, 12)),
    const BoxShadow(color: Color(0x55000000), blurRadius: 18, offset: Offset(0, 10)),
  ];

  /// Sanfte Hilfe-Karte: warmer Schatten, leicht angehoben.
  /// Fuer Tutor-Hints und Visual-Aids - signalisiert: hier ist Hilfe.
  static List<BoxShadow> help(Color tint) => [
    BoxShadow(color: tint.withOpacity(.24), blurRadius: 24, offset: const Offset(0, 10)),
    const BoxShadow(color: Color(0x55000000), blurRadius: 12, offset: Offset(0, 8)),
  ];

  /// Erfolg-Glow: leuchtender goldener Schein bei richtigen Antworten.
  static List<BoxShadow> success = [
    BoxShadow(color: const Color(0xFF34D399).withOpacity(.30), blurRadius: 32, offset: const Offset(0, 14)),
    BoxShadow(color: const Color(0xFFFFE08A).withOpacity(.45), blurRadius: 16, offset: const Offset(0, 6)),
  ];
}

class LumoTextStyles {
  LumoTextStyles._();

  static const heading1 = TextStyle(fontFamily: 'Nunito', fontSize: 32, fontWeight: FontWeight.w900, color: LumoColors.ink900, height: 1.1);
  static const heading2 = TextStyle(fontFamily: 'Nunito', fontSize: 22, fontWeight: FontWeight.w900, color: LumoColors.ink900);
  static const heading3 = TextStyle(fontFamily: 'Nunito', fontSize: 17, fontWeight: FontWeight.w900, color: LumoColors.ink900);
  static const body = TextStyle(fontFamily: 'Nunito', fontSize: 14, fontWeight: FontWeight.w700, color: LumoColors.ink500, height: 1.4);
  static const caption = TextStyle(fontFamily: 'Nunito', fontSize: 12, fontWeight: FontWeight.w700, color: LumoColors.ink300);
  static const label = TextStyle(fontFamily: 'Nunito', fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: .4, color: LumoColors.ink500);
  static const kpiValue = TextStyle(fontFamily: 'Nunito', fontSize: 30, fontWeight: FontWeight.w900, color: LumoColors.ink900, height: 1.0);
  static const navItem = TextStyle(fontFamily: 'Nunito', fontSize: 15, fontWeight: FontWeight.w800, color: LumoColors.ink700);
  static const navItemActive = TextStyle(fontFamily: 'Nunito', fontSize: 15, fontWeight: FontWeight.w900, color: Colors.white);
  static const cardTitle = TextStyle(fontFamily: 'Nunito', fontSize: 17, fontWeight: FontWeight.w900, color: LumoColors.orange, height: 1.2);
  static const cardSub = TextStyle(fontFamily: 'Nunito', fontSize: 12, fontWeight: FontWeight.w700, color: LumoColors.ink500, height: 1.35);
  static const cta = TextStyle(fontFamily: 'Nunito', fontSize: 12, fontWeight: FontWeight.w900);
}

class LumoAppTheme {
  LumoAppTheme._();

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF37D2FD),
      brightness: Brightness.dark,
      primary: const Color(0xFF37D2FD),
      secondary: LumoColors.purple,
      tertiary: LumoColors.orange,
      surface: LumoColors.appBg,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: 'Nunito',
      scaffoldBackgroundColor: LumoColors.appBg,
      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.android: LumoPageTransitionsBuilder(),
        TargetPlatform.iOS: LumoPageTransitionsBuilder(),
        TargetPlatform.linux: LumoPageTransitionsBuilder(),
        TargetPlatform.macOS: LumoPageTransitionsBuilder(),
        TargetPlatform.windows: LumoPageTransitionsBuilder(),
      }),
      textTheme: const TextTheme(
        headlineLarge: LumoTextStyles.heading1,
        headlineMedium: LumoTextStyles.heading2,
        titleMedium: LumoTextStyles.heading3,
        bodyMedium: LumoTextStyles.body,
        labelMedium: LumoTextStyles.label,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF207DE1),
          foregroundColor: Colors.white,
          textStyle: LumoTextStyles.cta,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(LumoRadius.pill)),
        ),
      ),
      cardTheme: CardThemeData(
        color: LumoColors.cardBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(LumoRadius.xl)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: LumoColors.leftNavBg,
        indicatorColor: const Color(0x6637D2FD),
        labelTextStyle: WidgetStatePropertyAll(LumoTextStyles.caption.copyWith(color: LumoColors.ink700)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xD90B2A55),
        hintStyle: const TextStyle(color: Color(0xFF8FAAC5)),
        labelStyle: const TextStyle(color: Color(0xFFB8C8DF)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(LumoRadius.lg), borderSide: const BorderSide(color: Color(0x5537D2FD))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(LumoRadius.lg), borderSide: const BorderSide(color: Color(0x6637D2FD))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(LumoRadius.lg), borderSide: const BorderSide(color: Color(0xFF53DDFD), width: 1.6)),
      ),
    );
  }
}

BoxDecoration lumoCard({
  Color? color,
  double radius = LumoRadius.xl,
  List<BoxShadow>? shadow,
  Gradient? gradient,
  Border? border,
}) {
  return BoxDecoration(
    color: color ?? LumoColors.cardBg,
    gradient: gradient,
    borderRadius: BorderRadius.circular(radius),
    border: border ?? Border.all(color: const Color(0x6637D2FD), width: 1.2),
    boxShadow: shadow ?? LumoShadow.card,
  );
}
