import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../../../domain/learning/lumo_learning_domain.dart';

/// Sammlung aller neuen Visuals fuer die erweiterten Aufgaben-Templates
/// (Mai 2026). Jedes Visual rendert Daten aus task.visualPayload.data oder
/// faellt sicher auf einen lesbaren Schoolbook-Look zurueck.

// ─────────────────────────────────────────────────────────────────────
//  GEMEINSAME HILFEN
// ─────────────────────────────────────────────────────────────────────

/// Liest eine ganze Zahl aus dem Visual-Payload, oder null wenn nicht da.
int? _readInt(Object? value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is double) return value.toInt();
  return int.tryParse(value.toString());
}

/// Findet die erste/zweite Zahl im Aufgabentext, falls Payload leer.
List<int> _digitsFromPrompt(String prompt) {
  final regex = RegExp(r'\d+');
  return regex.allMatches(prompt).map((m) => int.parse(m.group(0)!)).toList(growable: false);
}

/// Premium-Hintergrund fuer Visual-Karten.
BoxDecoration _stageDecoration(Color tint) => BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Colors.white, tint.withOpacity(0.10)],
      ),
      borderRadius: BorderRadius.circular(LumoRadius.lg),
      border: Border.all(color: tint.withOpacity(0.22), width: 1.4),
      boxShadow: [
        BoxShadow(color: tint.withOpacity(0.18), blurRadius: 20, offset: const Offset(0, 8), spreadRadius: -3),
        BoxShadow(color: Colors.white.withOpacity(0.65), blurRadius: 6, offset: const Offset(-2, -2), spreadRadius: -2),
      ],
    );

// ─────────────────────────────────────────────────────────────────────
//  MATHE-VISUALS
// ─────────────────────────────────────────────────────────────────────

/// Mengenvergleich: 🍎🍎🍎 vs 🍎🍎🍎🍎🍎
class QuantityCompareVisual extends StatelessWidget {
  const QuantityCompareVisual({super.key, required this.task});
  final TaskInstance task;

  @override
  Widget build(BuildContext context) {
    final data = task.visualPayload.data;
    final nums = _digitsFromPrompt(task.prompt);
    final left = _readInt(data['left']) ?? (nums.isNotEmpty ? nums[0] : 3);
    final right = _readInt(data['right']) ?? (nums.length > 1 ? nums[1] : 5);
    final emoji = data['emoji']?.toString() ?? '🍎';
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      decoration: _stageDecoration(LumoColors.orange),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(child: _Pile(count: left, emoji: emoji, accent: const Color(0xFF60A5FA))),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFFFB96B), Color(0xFFFF7A2F)]),
              borderRadius: BorderRadius.circular(LumoRadius.pill),
              boxShadow: [
                BoxShadow(color: LumoColors.orange.withOpacity(0.40), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: const Text(
              'oder',
              style: TextStyle(fontFamily: 'Nunito', fontSize: 13, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.4),
            ),
          ),
          Expanded(child: _Pile(count: right, emoji: emoji, accent: const Color(0xFFF472B6))),
        ],
      ),
    );
  }
}

class _Pile extends StatelessWidget {
  const _Pile({required this.count, required this.emoji, required this.accent});
  final int count;
  final String emoji;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final clamped = count.clamp(0, 10);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(LumoRadius.md),
        border: Border.all(color: accent.withOpacity(0.30), width: 1.4),
        boxShadow: [
          BoxShadow(color: accent.withOpacity(0.18), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 2,
            runSpacing: 2,
            children: List.generate(clamped, (_) => Text(emoji, style: const TextStyle(fontSize: 22, height: 1.0))),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(color: accent.withOpacity(0.15), borderRadius: BorderRadius.circular(99)),
            child: Text('$count', style: TextStyle(fontFamily: 'Nunito', fontSize: 18, fontWeight: FontWeight.w900, color: accent, height: 1.0)),
          ),
        ],
      ),
    );
  }
}

/// Uhrzeit-Visual: analoge Uhr mit Stunden- und Minutenzeiger
class ClockFaceVisual extends StatelessWidget {
  const ClockFaceVisual({super.key, required this.task});
  final TaskInstance task;

  @override
  Widget build(BuildContext context) {
    final data = task.visualPayload.data;
    final hour = _readInt(data['hour']) ?? _hourFromPrompt(task.prompt);
    final minute = _readInt(data['minute']) ?? _minuteFromPrompt(task.prompt);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _stageDecoration(LumoColors.blue),
      child: Center(
        child: SizedBox(
          width: 180,
          height: 180,
          child: CustomPaint(painter: _ClockPainter(hour: hour, minute: minute)),
        ),
      ),
    );
  }

  int _hourFromPrompt(String p) {
    final m = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(p);
    if (m != null) return int.tryParse(m.group(1)!) ?? 12;
    return 12;
  }

  int _minuteFromPrompt(String p) {
    final m = RegExp(r'(\d{1,2}):(\d{2})').firstMatch(p);
    if (m != null) return int.tryParse(m.group(2)!) ?? 0;
    return 0;
  }
}

class _ClockPainter extends CustomPainter {
  _ClockPainter({required this.hour, required this.minute});
  final int hour;
  final int minute;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 4;

    // Schatten
    canvas.drawCircle(center.translate(0, 6), radius, Paint()..color = Colors.black.withOpacity(0.12));
    // Zifferblatt
    canvas.drawCircle(center, radius, Paint()..color = Colors.white);
    canvas.drawCircle(center, radius,
        Paint()..style = PaintingStyle.stroke..strokeWidth = 4..color = const Color(0xFF60A5FA));

    // 12 Stundenmarken + Zahlen
    for (var i = 1; i <= 12; i++) {
      final angle = (i / 12) * 2 * math.pi - math.pi / 2;
      final outer = center + Offset(math.cos(angle) * (radius - 6), math.sin(angle) * (radius - 6));
      final inner = center + Offset(math.cos(angle) * (radius - 14), math.sin(angle) * (radius - 14));
      canvas.drawLine(outer, inner,
          Paint()..strokeWidth = 2.4..color = const Color(0xFF1E40AF)..strokeCap = StrokeCap.round);
      final tp = TextPainter(
        text: TextSpan(text: '$i', style: const TextStyle(fontFamily: 'Nunito', fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF1E40AF))),
        textDirection: TextDirection.ltr,
      )..layout();
      final textPos = center + Offset(math.cos(angle) * (radius - 28), math.sin(angle) * (radius - 28));
      tp.paint(canvas, textPos.translate(-tp.width / 2, -tp.height / 2));
    }

    // Stundenzeiger
    final hourAngle = ((hour % 12) + minute / 60) / 12 * 2 * math.pi - math.pi / 2;
    canvas.drawLine(center, center + Offset(math.cos(hourAngle) * radius * 0.55, math.sin(hourAngle) * radius * 0.55),
        Paint()..strokeWidth = 6..strokeCap = StrokeCap.round..color = const Color(0xFF1E40AF));
    // Minutenzeiger
    final minuteAngle = (minute / 60) * 2 * math.pi - math.pi / 2;
    canvas.drawLine(center, center + Offset(math.cos(minuteAngle) * radius * 0.80, math.sin(minuteAngle) * radius * 0.80),
        Paint()..strokeWidth = 4..strokeCap = StrokeCap.round..color = const Color(0xFFFF7A2F));
    // Mittelpunkt
    canvas.drawCircle(center, 6, Paint()..color = const Color(0xFFFF7A2F));
    canvas.drawCircle(center, 3, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(_ClockPainter old) => old.hour != hour || old.minute != minute;
}

/// Geld-Visual: Münzen und Scheine als Layout
class MoneyCoinsVisual extends StatelessWidget {
  const MoneyCoinsVisual({super.key, required this.task});
  final TaskInstance task;

  @override
  Widget build(BuildContext context) {
    final data = task.visualPayload.data;
    final amountCents = _readInt(data['cents']) ?? _readInt(data['amount']) ?? _amountFromPrompt(task.prompt);
    final coins = _splitInCoins(amountCents);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _stageDecoration(LumoColors.gold),
      child: Column(
        children: [
          const Text(
            '💰',
            style: TextStyle(fontSize: 32),
          ),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: coins.map((c) => _Coin(value: c)).toList(growable: false),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFFFE08A), Color(0xFFFFB800)]),
              borderRadius: BorderRadius.circular(LumoRadius.pill),
              boxShadow: [
                BoxShadow(color: LumoColors.gold.withOpacity(0.30), blurRadius: 8, offset: const Offset(0, 3)),
              ],
            ),
            child: Text(
              _formatEuro(amountCents),
              style: const TextStyle(fontFamily: 'Nunito', fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF92400E), height: 1.0),
            ),
          ),
        ],
      ),
    );
  }

  int _amountFromPrompt(String p) {
    final euro = RegExp(r'(\d+)(?:[.,](\d{1,2}))?\s*€').firstMatch(p);
    if (euro != null) {
      final e = int.tryParse(euro.group(1)!) ?? 0;
      final c = int.tryParse(euro.group(2) ?? '0') ?? 0;
      return e * 100 + c;
    }
    return 100;
  }

  List<int> _splitInCoins(int cents) {
    const denominations = <int>[200, 100, 50, 20, 10, 5, 2, 1];
    final out = <int>[];
    var remaining = cents;
    for (final d in denominations) {
      while (remaining >= d && out.length < 12) {
        out.add(d);
        remaining -= d;
      }
    }
    return out;
  }

  String _formatEuro(int cents) {
    final e = cents ~/ 100;
    final c = cents % 100;
    if (c == 0) return '$e €';
    return '$e,${c.toString().padLeft(2, '0')} €';
  }
}

class _Coin extends StatelessWidget {
  const _Coin({required this.value});
  final int value;

  @override
  Widget build(BuildContext context) {
    final isEuro = value >= 100;
    final label = isEuro ? '${value ~/ 100}€' : '${value}c';
    final color = isEuro ? const Color(0xFFFFB800) : const Color(0xFFC0C0C0);
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: RadialGradient(
          colors: [Colors.white, color],
          radius: 0.85,
        ),
        shape: BoxShape.circle,
        border: Border.all(color: color.withOpacity(0.55), width: 2),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.40), blurRadius: 6, offset: const Offset(0, 2)),
        ],
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Nunito',
          fontSize: 12,
          fontWeight: FontWeight.w900,
          color: isEuro ? const Color(0xFF78350F) : const Color(0xFF374151),
        ),
      ),
    );
  }
}

/// Bruch als Pizza
class FractionPizzaVisual extends StatelessWidget {
  const FractionPizzaVisual({super.key, required this.task});
  final TaskInstance task;

  @override
  Widget build(BuildContext context) {
    final data = task.visualPayload.data;
    final num = _readInt(data['numerator']) ?? 1;
    final den = _readInt(data['denominator']) ?? _denomFromPrompt(task.prompt);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _stageDecoration(LumoColors.practice),
      child: Center(
        child: SizedBox(
          width: 160,
          height: 160,
          child: CustomPaint(painter: _PizzaPainter(numerator: num.clamp(0, den), denominator: den.clamp(1, 12))),
        ),
      ),
    );
  }

  int _denomFromPrompt(String p) {
    final m = RegExp(r'/(\d+)').firstMatch(p);
    if (m != null) return int.tryParse(m.group(1)!) ?? 2;
    return 2;
  }
}

class _PizzaPainter extends CustomPainter {
  _PizzaPainter({required this.numerator, required this.denominator});
  final int numerator;
  final int denominator;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 6;
    canvas.drawCircle(center.translate(0, 5), radius, Paint()..color = Colors.black.withOpacity(0.14));
    // Background
    canvas.drawCircle(center, radius, Paint()..color = const Color(0xFFFFF3D6));
    // Slices
    final perSlice = 2 * math.pi / denominator;
    for (var i = 0; i < denominator; i++) {
      final start = -math.pi / 2 + i * perSlice;
      final fillPaint = Paint()
        ..color = i < numerator ? const Color(0xFFFF7A2F) : const Color(0xFFFFE08A);
      final rect = Rect.fromCircle(center: center, radius: radius);
      canvas.drawArc(rect, start, perSlice, true, fillPaint);
      // Slice border
      canvas.drawArc(rect, start, perSlice, true,
          Paint()..style = PaintingStyle.stroke..strokeWidth = 2.4..color = Colors.white);
    }
    // Outer ring
    canvas.drawCircle(center, radius,
        Paint()..style = PaintingStyle.stroke..strokeWidth = 3..color = const Color(0xFFC2410C));
  }

  @override
  bool shouldRepaint(_PizzaPainter old) =>
      old.numerator != numerator || old.denominator != denominator;
}

/// Mini-Balkendiagramm
class BarChartMiniVisual extends StatelessWidget {
  const BarChartMiniVisual({super.key, required this.task});
  final TaskInstance task;

  @override
  Widget build(BuildContext context) {
    final data = task.visualPayload.data;
    final raw = data['bars'];
    final extracted = raw is List
        ? raw.map((e) => _readInt(e) ?? 0).toList(growable: false)
        : _digitsFromPrompt(task.prompt);
    // Fallback wenn keine Daten: kleines Demo-Diagramm zeigen statt leere Karte.
    final bars = extracted.isEmpty ? <int>[3, 5, 2, 4] : extracted;
    final maxValue = bars.fold<int>(1, (a, b) => b > a ? b : a);
    final colors = <Color>[
      const Color(0xFFFF7A2F),
      const Color(0xFF60A5FA),
      const Color(0xFF34D399),
      const Color(0xFFF472B6),
      const Color(0xFFFFB800),
      const Color(0xFF8B5CF6),
    ];
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
      decoration: _stageDecoration(LumoColors.blue),
      height: 200,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: bars.asMap().entries.map((e) {
          final i = e.key;
          final v = e.value;
          final h = (v / maxValue) * 140;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text('$v', style: TextStyle(fontFamily: 'Nunito', fontSize: 12, fontWeight: FontWeight.w900, color: colors[i % colors.length])),
                  const SizedBox(height: 4),
                  TweenAnimationBuilder<double>(
                    duration: Duration(milliseconds: 540 + i * 80),
                    curve: Curves.easeOutCubic,
                    tween: Tween<double>(begin: 0, end: h),
                    builder: (_, animH, __) => Container(
                      width: double.infinity,
                      height: animH,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [colors[i % colors.length], colors[i % colors.length].withOpacity(0.65)],
                        ),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                        boxShadow: [
                          BoxShadow(color: colors[i % colors.length].withOpacity(0.30), blurRadius: 6, offset: const Offset(0, 3)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(growable: false),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
//  DEUTSCH-VISUALS
// ─────────────────────────────────────────────────────────────────────

/// Reim-Blasen
class RhymeBubbleVisual extends StatelessWidget {
  const RhymeBubbleVisual({super.key, required this.task});
  final TaskInstance task;

  @override
  Widget build(BuildContext context) {
    final data = task.visualPayload.data;
    final raw = data['rhymes'];
    final rhymes = raw is List
        ? raw.map((e) => e.toString()).toList(growable: false)
        : <String>[];
    final word = data['word']?.toString() ?? task.parameters['word']?.toString() ?? task.prompt.split(' ').last;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _stageDecoration(LumoColors.purple),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFA78BFA), Color(0xFF8B5CF6)]),
              borderRadius: BorderRadius.circular(LumoRadius.pill),
              boxShadow: [
                BoxShadow(color: LumoColors.purple.withOpacity(0.40), blurRadius: 12, offset: const Offset(0, 5)),
              ],
            ),
            child: Text(word,
                style: const TextStyle(fontFamily: 'Nunito', fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
          ),
          const SizedBox(height: 14),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            runSpacing: 8,
            children: rhymes.map((r) => _RhymeBubble(text: r)).toList(growable: false),
          ),
        ],
      ),
    );
  }
}

class _RhymeBubble extends StatelessWidget {
  const _RhymeBubble({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(LumoRadius.pill),
        border: Border.all(color: LumoColors.purple.withOpacity(0.30), width: 1.4),
        boxShadow: [
          BoxShadow(color: LumoColors.purple.withOpacity(0.18), blurRadius: 6, offset: const Offset(0, 3)),
        ],
      ),
      child: Text(text, style: const TextStyle(fontFamily: 'Nunito', fontSize: 14, fontWeight: FontWeight.w800, color: LumoColors.ink700)),
    );
  }
}

/// Silben-Klatschen
class SyllableClapVisual extends StatelessWidget {
  const SyllableClapVisual({super.key, required this.task});
  final TaskInstance task;

  @override
  Widget build(BuildContext context) {
    final data = task.visualPayload.data;
    final raw = data['syllables'];
    final word = data['word']?.toString() ?? task.parameters['word']?.toString() ?? '';
    final syllables = raw is List
        ? raw.map((e) => e.toString()).toList(growable: false)
        : (word.isEmpty ? <String>[] : <String>[word]);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _stageDecoration(LumoColors.purple),
      child: Column(
        children: [
          const Text('👏', style: TextStyle(fontSize: 32)),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: syllables.asMap().entries.map((e) {
              final colors = const [Color(0xFFF472B6), Color(0xFF60A5FA), Color(0xFF34D399), Color(0xFFFFB800)];
              return _SyllableChip(text: e.value, color: colors[e.key % colors.length]);
            }).toList(growable: false),
          ),
          const SizedBox(height: 10),
          Text(
            'Sprich langsam und klatsche bei jeder Silbe.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontFamily: 'Nunito', fontSize: 12, fontWeight: FontWeight.w700, color: LumoColors.ink500),
          ),
        ],
      ),
    );
  }
}

class _SyllableChip extends StatelessWidget {
  const _SyllableChip({required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color, color.withOpacity(0.75)]),
        borderRadius: BorderRadius.circular(LumoRadius.md),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.40), blurRadius: 8, offset: const Offset(0, 4)),
        ],
      ),
      child: Text(text,
          style: const TextStyle(fontFamily: 'Nunito', fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
    );
  }
}

/// Wortfamilien-Baum (vereinfacht: Stamm in Mitte, Aeste rundum)
class WordFamilyTreeVisual extends StatelessWidget {
  const WordFamilyTreeVisual({super.key, required this.task});
  final TaskInstance task;

  @override
  Widget build(BuildContext context) {
    final data = task.visualPayload.data;
    final root = data['root']?.toString() ?? task.parameters['root']?.toString() ?? 'fahren';
    final raw = data['family'];
    final family = raw is List
        ? raw.map((e) => e.toString()).toList(growable: false)
        : <String>[];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _stageDecoration(LumoColors.teal),
      child: Column(
        children: [
          const Text('🌳', style: TextStyle(fontSize: 36)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF34D399), Color(0xFF10B981)]),
              borderRadius: BorderRadius.circular(LumoRadius.md),
              boxShadow: [
                BoxShadow(color: LumoColors.teal.withOpacity(0.40), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: Text(root,
                style: const TextStyle(fontFamily: 'Nunito', fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
          ),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: family.map((w) => _Leaf(text: w)).toList(growable: false),
          ),
        ],
      ),
    );
  }
}

class _Leaf extends StatelessWidget {
  const _Leaf({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(LumoRadius.pill),
        border: Border.all(color: LumoColors.teal.withOpacity(0.40), width: 1.4),
        boxShadow: [
          BoxShadow(color: LumoColors.teal.withOpacity(0.18), blurRadius: 6, offset: const Offset(0, 3)),
        ],
      ),
      child: Text(text, style: const TextStyle(fontFamily: 'Nunito', fontSize: 13, fontWeight: FontWeight.w800, color: LumoColors.ink700)),
    );
  }
}

/// Satz-Bauklötze
class SentenceBlocksVisual extends StatelessWidget {
  const SentenceBlocksVisual({super.key, required this.task});
  final TaskInstance task;

  @override
  Widget build(BuildContext context) {
    final data = task.visualPayload.data;
    final raw = data['blocks'];
    final words = raw is List
        ? raw.map((e) => e.toString()).toList(growable: false)
        : task.prompt.split(' ').take(6).toList(growable: false);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _stageDecoration(LumoColors.blue),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 6,
        runSpacing: 6,
        children: words.asMap().entries.map((e) {
          final colors = const [
            Color(0xFFFF7A2F), Color(0xFF60A5FA), Color(0xFF34D399),
            Color(0xFFF472B6), Color(0xFFFFB800), Color(0xFF8B5CF6),
          ];
          return _Block(text: e.value, color: colors[e.key % colors.length]);
        }).toList(growable: false),
      ),
    );
  }
}

class _Block extends StatelessWidget {
  const _Block({required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color, color.withOpacity(0.75)]),
        borderRadius: BorderRadius.circular(LumoRadius.sm),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.40), blurRadius: 6, offset: const Offset(0, 3)),
        ],
      ),
      child: Text(text, style: const TextStyle(fontFamily: 'Nunito', fontSize: 14, fontWeight: FontWeight.w900, color: Colors.white)),
    );
  }
}

/// Wortarten farbig (Nomen blau, Verb rot, Adjektiv grün)
class WordTypeColorVisual extends StatelessWidget {
  const WordTypeColorVisual({super.key, required this.task});
  final TaskInstance task;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _stageDecoration(LumoColors.orange),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ColorTag(label: 'Nomen', color: const Color(0xFF60A5FA)),
              const SizedBox(width: 8),
              _ColorTag(label: 'Verb', color: const Color(0xFFEF4444)),
              const SizedBox(width: 8),
              _ColorTag(label: 'Adjektiv', color: const Color(0xFF34D399)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            task.prompt,
            textAlign: TextAlign.center,
            style: const TextStyle(fontFamily: 'Nunito', fontSize: 18, fontWeight: FontWeight.w900, color: LumoColors.ink900, height: 1.3),
          ),
        ],
      ),
    );
  }
}

class _ColorTag extends StatelessWidget {
  const _ColorTag({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.18),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color, width: 1.4),
      ),
      child: Text(label,
          style: TextStyle(fontFamily: 'Nunito', fontSize: 11, fontWeight: FontWeight.w900, color: color)),
    );
  }
}

/// Artikel-Karten: der/die/das
class ArticleCardsVisual extends StatelessWidget {
  const ArticleCardsVisual({super.key, required this.task});
  final TaskInstance task;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _stageDecoration(LumoColors.purple),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _ArticleCard(article: 'der', color: const Color(0xFF60A5FA), icon: '👨'),
          const SizedBox(width: 8),
          _ArticleCard(article: 'die', color: const Color(0xFFF472B6), icon: '👩'),
          const SizedBox(width: 8),
          _ArticleCard(article: 'das', color: const Color(0xFF34D399), icon: '🧒'),
        ],
      ),
    );
  }
}

class _ArticleCard extends StatelessWidget {
  const _ArticleCard({required this.article, required this.color, required this.icon});
  final String article;
  final Color color;
  final String icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 78,
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.white, color.withOpacity(0.18)]),
        borderRadius: BorderRadius.circular(LumoRadius.md),
        border: Border.all(color: color, width: 1.6),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.30), blurRadius: 10, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 28)),
          const SizedBox(height: 4),
          Text(article,
              style: TextStyle(fontFamily: 'Nunito', fontSize: 18, fontWeight: FontWeight.w900, color: color)),
        ],
      ),
    );
  }
}
