import 'package:flutter/material.dart';

// ═══════════════════════════════════════════════════════════
//  LUMO LERNEN – DESIGN TOKENS
//  Single source of truth for every visual decision.
// ═══════════════════════════════════════════════════════════

class LumoColors {
  LumoColors._();

  static const appBg        = Color(0xFFFFF6EE);
  static const leftNavBg    = Colors.white;
  static const cardBg       = Colors.white;
  static const stageBg1     = Color(0xFFFFE4C0);
  static const stageBg2     = Color(0xFFFFF2E0);

  static const orange       = Color(0xFFFF7A2F);
  static const orangeLight  = Color(0xFFFF9A5C);
  static const orangeGlow   = Color(0x33FF7A2F);
  static const orangeSurface= Color(0xFFFFF0E8);

  static const purple       = Color(0xFF8B5CF6);
  static const purpleLight  = Color(0xFFA78BFA);
  static const purpleSurface= Color(0xFFF3F0FF);

  static const teal         = Color(0xFF10A894);
  static const tealLight    = Color(0xFF34D399);
  static const tealSurface  = Color(0xFFECFDF5);

  static const gold         = Color(0xFFFFB800);
  static const goldLight    = Color(0xFFFFD166);
  static const goldSurface  = Color(0xFFFFFBEB);

  static const blue         = Color(0xFF3B82F6);
  static const blueSurface  = Color(0xFFEFF6FF);

  static const math         = Color(0xFFFF8700);
  static const mathSurface  = Color(0xFFFFF4BD);
  static const german       = Color(0xFF8B5CF6);
  static const germanSurface= Color(0xFFFFE8FB);
  static const english      = Color(0xFF10A894);
  static const englishSurface=Color(0xFFDFFFF6);
  static const practice     = Color(0xFFFF625D);
  static const practiceSurface=Color(0xFFFFE6E2);
  static const testColor    = Color(0xFF3A86E8);
  static const testSurface  = Color(0xFFEAF3FF);
  static const schoolwork   = Color(0xFFFF9800);
  static const schoolworkSurface=Color(0xFFFFF2C9);
  static const scanner      = Color(0xFF9C55E8);
  static const scannerSurface=Color(0xFFFFE8FF);
  static const continueColor= Color(0xFF08A892);
  static const continueSurface=Color(0xFFE5FFF6);

  static const ink900       = Color(0xFF1F1713);
  static const ink700       = Color(0xFF3D342C);
  static const ink500       = Color(0xFF766A61);
  static const ink300       = Color(0xFFB0A89F);
  static const ink100       = Color(0xFFEDE8E4);
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
    BoxShadow(color: const Color(0xFFFFB96B).withOpacity(.18), blurRadius: 28, offset: const Offset(0, 12)),
    BoxShadow(color: Colors.white.withOpacity(.90), blurRadius: 8, offset: const Offset(-3, -3)),
  ];

  static List<BoxShadow> pill = [
    BoxShadow(color: const Color(0xFFFF7A2F).withOpacity(.28), blurRadius: 18, offset: const Offset(0, 8)),
  ];

  static List<BoxShadow> stage = [
    BoxShadow(color: const Color(0xFFFFB96B).withOpacity(.22), blurRadius: 40, offset: const Offset(0, 20)),
  ];

  static List<BoxShadow> hologram(Color color) => [
    BoxShadow(color: color.withOpacity(.24), blurRadius: 28, offset: const Offset(0, 12)),
    BoxShadow(color: Colors.white.withOpacity(.58), blurRadius: 14, offset: const Offset(-4, -5)),
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
      seedColor: LumoColors.orange,
      brightness: Brightness.light,
      primary: LumoColors.orange,
      secondary: LumoColors.purple,
      tertiary: LumoColors.teal,
      surface: LumoColors.appBg,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamily: 'Nunito',
      scaffoldBackgroundColor: LumoColors.appBg,
      textTheme: const TextTheme(
        headlineLarge: LumoTextStyles.heading1,
        headlineMedium: LumoTextStyles.heading2,
        titleMedium: LumoTextStyles.heading3,
        bodyMedium: LumoTextStyles.body,
        labelMedium: LumoTextStyles.label,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: LumoColors.orange,
          foregroundColor: Colors.white,
          textStyle: LumoTextStyles.cta,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(LumoRadius.pill)),
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white.withOpacity(.82),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(LumoRadius.xl)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: LumoColors.appBg,
        indicatorColor: LumoColors.orangeSurface,
        labelTextStyle: WidgetStatePropertyAll(LumoTextStyles.caption.copyWith(color: LumoColors.ink700)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white.withOpacity(.82),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(LumoRadius.lg), borderSide: BorderSide(color: Colors.white.withOpacity(.75))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(LumoRadius.lg), borderSide: BorderSide(color: Colors.white.withOpacity(.75))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(LumoRadius.lg), borderSide: const BorderSide(color: LumoColors.orange, width: 1.4)),
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
    border: border ?? Border.all(color: Colors.white.withOpacity(.75), width: 1.2),
    boxShadow: shadow ?? LumoShadow.card,
  );
}
