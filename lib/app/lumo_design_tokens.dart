import 'package:flutter/material.dart';

class LumoColors {
  const LumoColors._();

  static const cream = Color(0xfffffbf4);
  static const vanilla = Color(0xfffff7e8);
  static const peach = Color(0xffffdfb3);
  static const apricot = Color(0xffffc982);
  static const softGold = Color(0xffffc857);
  static const brandOrange = Color(0xffff6d00);
  static const warmText = Color(0xff2d2621);
  static const mutedText = Color(0xff766a61);
  static const lavender = Color(0xff8b5cf6);
  static const pinkLavender = Color(0xffb455f6);
  static const mint = Color(0xff14b8a6);
  static const turquoise = Color(0xff08a892);
  static const sky = Color(0xff3b8dff);
  static const success = Color(0xff4ec96f);
  static const softWhite = Color(0xffffffff);
}

class LumoRadius {
  const LumoRadius._();

  static const double shell = 38;
  static const double stage = 38;
  static const double card = 30;
  static const double kpi = 24;
  static const double pill = 99;
  static const double bubble = 28;
  static const double small = 16;
}

class LumoSpacing {
  const LumoSpacing._();

  static const double xs = 6;
  static const double sm = 10;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 44;
}

class LumoDurations {
  const LumoDurations._();

  static const fast = Duration(milliseconds: 180);
  static const normal = Duration(milliseconds: 260);
  static const slow = Duration(milliseconds: 420);
}

class LumoTextStyles {
  const LumoTextStyles._();

  static const headline = TextStyle(fontSize: 34, height: 1.05, fontWeight: FontWeight.w900, color: LumoColors.warmText);
  static const subtitle = TextStyle(fontSize: 16, height: 1.25, fontWeight: FontWeight.w700, color: LumoColors.mutedText);
  static const logoLumo = TextStyle(fontSize: 30, height: .9, fontWeight: FontWeight.w900, color: LumoColors.brandOrange);
  static const logoLernen = TextStyle(fontSize: 30, height: .9, fontWeight: FontWeight.w900, color: LumoColors.warmText);
  static const cardTitle = TextStyle(fontSize: 20, height: 1.08, fontWeight: FontWeight.w900, color: LumoColors.warmText);
  static const cardBody = TextStyle(fontSize: 13, height: 1.15, fontWeight: FontWeight.w700, color: Color(0xff635850));
  static const kpiValue = TextStyle(fontSize: 24, height: 1.0, fontWeight: FontWeight.w900, color: LumoColors.warmText);
  static const kpiLabel = TextStyle(fontSize: 12, height: 1.0, fontWeight: FontWeight.w900);
}

class LumoGradients {
  const LumoGradients._();

  static const appBackground = RadialGradient(
    center: Alignment.topRight,
    radius: 1.28,
    colors: [LumoColors.peach, LumoColors.cream, Color(0xffecfff7)],
  );

  static const shellSurface = LinearGradient(
    colors: [LumoColors.cream, LumoColors.vanilla],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const sidebar = LinearGradient(
    colors: [Color(0xfffff7ee), Color(0xfffffbf6)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const lumoStage = LinearGradient(
    colors: [Color(0xffffd190), Color(0xffffe2af), Color(0xffffedcf)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class LumoShadows {
  const LumoShadows._();

  static List<BoxShadow> shell = [
    BoxShadow(color: LumoColors.brandOrange.withOpacity(.14), blurRadius: 46, offset: const Offset(0, 24)),
    BoxShadow(color: Colors.white.withOpacity(.90), blurRadius: 20, offset: const Offset(-8, -8)),
  ];

  static List<BoxShadow> soft(Color color) => [
        BoxShadow(color: color.withOpacity(.16), blurRadius: 22, offset: const Offset(0, 13)),
        BoxShadow(color: Colors.white.withOpacity(.70), blurRadius: 10, offset: const Offset(-4, -4)),
      ];

  static List<BoxShadow> stage = [
    BoxShadow(color: const Color(0xffffb96b).withOpacity(.38), blurRadius: 32, spreadRadius: 4, offset: const Offset(0, 14)),
  ];
}

class LumoSurfaces {
  const LumoSurfaces._();

  static BoxDecoration shell() => BoxDecoration(
        color: LumoColors.cream,
        borderRadius: BorderRadius.circular(LumoRadius.shell),
        boxShadow: LumoShadows.shell,
      );

  static BoxDecoration softCard({Color color = Colors.white, double radius = LumoRadius.card, Color shadowColor = LumoColors.brandOrange}) => BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: Colors.white.withOpacity(.76), width: 1),
        boxShadow: LumoShadows.soft(shadowColor),
      );

  static BoxDecoration module(Color accent) => BoxDecoration(
        gradient: LinearGradient(colors: [accent.withOpacity(.15), Colors.white.withOpacity(.86)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(LumoRadius.card),
        border: Border.all(color: Colors.white.withOpacity(.78), width: 1.2),
        boxShadow: LumoShadows.soft(accent),
      );
}
