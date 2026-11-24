import 'package:flutter/material.dart';

/// Original local 3D LUMO object art for learning tasks.
///
/// Generated images replace historic emoji placeholders. Task answers,
/// prompts and scoring stay owned by the learning modules and templates.
/// If no asset is registered the previous emoji is shown as fallback.
class LumoTaskObjectArt extends StatelessWidget {
  const LumoTaskObjectArt({
    super.key,
    this.name,
    this.emoji,
    this.size = 140,
    this.semanticLabel,
  });

  final String? name;
  final String? emoji;
  final double size;
  final String? semanticLabel;

  static const String folder = 'assets/lumo_design/task_objects';

  static const Map<String, String> assetsByKey = {
    'apfel': 'assets/lumo_design/icons/apple_red.png',
    'aepfel': 'assets/lumo_design/icons/apple_red.png',
    'buch': 'assets/lumo_design/icons/book_open.png',
    'stern': 'assets/lumo_design/icons/star_gold.png',
    'hund': '$folder/hund.webp',
    'katze': '$folder/katze.webp',
    'maus': '$folder/maus.webp',
    'hase': '$folder/hase.webp',
    'fuchs': '$folder/fuchs.webp',
    'kuh': '$folder/kuh.webp',
    'schwein': '$folder/schwein.webp',
    'biene': '$folder/biene.webp',
    'banane': '$folder/banane.webp',
    'birne': '$folder/birne.webp',
    'karotte': '$folder/karotte.webp',
    'baum': '$folder/baum.webp',
    'auto': '$folder/auto.webp',
    'bus': '$folder/bus.webp',
    'ball': '$folder/ball.webp',
    'sonne': '$folder/sonne.webp',
    'mond': '$folder/mond.webp',
    'haus': '$folder/haus.webp',
    'schaf': '$folder/schaf.webp',
    'pferd': '$folder/pferd.webp',
    'huhn': '$folder/huhn.webp',
    'ente': '$folder/ente.webp',
    'frosch': '$folder/frosch.webp',
    'loewe': '$folder/loewe.webp',
    'elefant': '$folder/elefant.webp',
    'pinguin': '$folder/pinguin.webp',
    'affe': '$folder/affe.webp',
  };

  static const Map<String, String> nameByEmoji = {
    '🐶': 'Hund',
    '🐕': 'Hund',
    '🐱': 'Katze',
    '🐈': 'Katze',
    '🐭': 'Maus',
    '🐁': 'Maus',
    '🐰': 'Hase',
    '🦊': 'Fuchs',
    '🐮': 'Kuh',
    '🐄': 'Kuh',
    '🐷': 'Schwein',
    '🐝': 'Biene',
    '🍎': 'Apfel',
    '🍌': 'Banane',
    '🍐': 'Birne',
    '🥕': 'Karotte',
    '🌳': 'Baum',
    '🚗': 'Auto',
    '🚌': 'Bus',
    '📘': 'Buch',
    '📖': 'Buch',
    '⚽': 'Ball',
    '☀️': 'Sonne',
    '🌞': 'Sonne',
    '🌙': 'Mond',
    '🏠': 'Haus',
    '🐑': 'Schaf',
    '🐴': 'Pferd',
    '🐔': 'Huhn',
    '🦆': 'Ente',
    '🐸': 'Frosch',
    '🦁': 'Löwe',
    '🐘': 'Elefant',
    '🐧': 'Pinguin',
    '🐵': 'Affe',
    '🍪': 'Keks',
    '🍫': 'Schokolade',
    '🌸': 'Blume',
    '⭐': 'Stern',
  };

  static final RegExp wordImagePrompt = RegExp(
    r'^(Welches Wort passt zum Bild:)\s*(.+?)\s*\?\s*$',
  );

  static String normalize(String raw) {
    var value = raw.trim().toLowerCase();
    value = value
        .replaceAll('ä', 'ae')
        .replaceAll('ö', 'oe')
        .replaceAll('ü', 'ue')
        .replaceAll('ß', 'ss');
    return value;
  }

  static String? nameForEmoji(String emoji) => nameByEmoji[emoji.trim()];

  static String? assetForName(String? name) {
    if (name == null || name.isEmpty) return null;
    return assetsByKey[normalize(name)];
  }

  static String? assetForEmoji(String? emoji) {
    if (emoji == null || emoji.isEmpty) return null;
    return assetForName(nameForEmoji(emoji));
  }

  static String? resolvedAsset({String? name, String? emoji}) {
    return assetForName(name) ?? assetForEmoji(emoji);
  }

  static LumoWordImageCue? matchWordImage({
    required String prompt,
    required Object answer,
  }) {
    final match = wordImagePrompt.firstMatch(prompt);
    if (match == null) return null;
    var lead = match.group(1)!;
    if (lead.endsWith(':')) {
      lead = lead.substring(0, lead.length - 1).trimRight();
    }
    return LumoWordImageCue(
      displayPrompt: '$lead?',
      name: '$answer',
      emoji: match.group(2)?.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final asset = resolvedAsset(name: name, emoji: emoji);
    final label = semanticLabel ?? name ?? nameForEmoji(emoji ?? '') ?? 'Bild';
    if (asset != null) {
      return Image.asset(
        asset,
        width: size,
        height: size,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
        semanticLabel: label,
      );
    }
    if (emoji != null && emoji!.isNotEmpty) {
      return Text(
        emoji!,
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: size * 0.72, height: 1),
        semanticsLabel: label,
      );
    }
    return SizedBox(width: size, height: size);
  }
}

class LumoWordImageCue {
  const LumoWordImageCue({
    required this.displayPrompt,
    required this.name,
    this.emoji,
  });

  final String displayPrompt;
  final String name;
  final String? emoji;
}

/// Shared picture frame: depth, soft shadow and a light rim.
class LumoTaskHeroCard extends StatelessWidget {
  const LumoTaskHeroCard({
    super.key,
    required this.child,
    this.size = 220,
    this.colors = const [Color(0xFFFFF6E8), Color(0xFFFFD089)],
  });

  final Widget child;
  final double size;
  final List<Color> colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: RadialGradient(
          colors: [colors[0], colors[1]],
          radius: 0.95,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xF2FFFFFF), width: 5),
        boxShadow: [
          BoxShadow(
            color: colors.last.withValues(alpha: .42),
            blurRadius: 28,
            offset: const Offset(0, 12),
            spreadRadius: -3,
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: .35),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: child,
    );
  }
}
