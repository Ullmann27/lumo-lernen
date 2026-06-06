// ════════════════════════════════════════════════════════════════════════
// LUMO RECHENTRICKS POSTER — Mildenberger-inspirierte Mentor-Uebersicht
// ════════════════════════════════════════════════════════════════════════
// 2026-06-05 Iter 22: Die 5 Mentoren (Emma, Max, Hanna, Tim, Mira) auf
// einer scrollbaren Seite mit Catchphrase + 2 Beispiel-Aufgaben pro
// Strategie. Kind kann hier in Ruhe schauen, welcher Trick wofuer gut
// ist. Inspiriert vom Mildenberger Uebungsheft Mathematik 1+3 Poster
// "Meine Rechentricks".
// ════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../../core/math/lumo_rechentricks.dart';
import '../../widgets/premium/lumo_magic_background.dart';
import 'widgets/rechentricks_mentor_card.dart';

class LumoRechentricksPosterScreen extends StatelessWidget {
  const LumoRechentricksPosterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tricks = const LumoRechentricks();
    // Pro Mentor 2 Beispiel-Aufgaben generieren.
    final entries = <_PosterEntry>[];
    for (final m in kAllRechentricksMentors) {
      final examples = _examplesFor(m, tricks);
      if (examples.isEmpty) continue;
      entries.add(_PosterEntry(mentor: m, examples: examples));
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Meine Rechentricks',
          style: TextStyle(
            fontFamily: 'Nunito',
            fontWeight: FontWeight.w900,
            color: Colors.white,
            fontSize: 18,
          ),
        ),
      ),
      body: LumoMagicBackground(
        intensity: 1.0,
        starCount: 22,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _HeroBanner(),
                const SizedBox(height: 14),
                for (final e in entries) ...[
                  _MentorSection(entry: e),
                  const SizedBox(height: 14),
                ],
                const _FooterCredit(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<RechentricksExplanation> _examplesFor(
      RechentricksMentor m, LumoRechentricks tricks) {
    // Pro Strategie hartcodiert 2 Beispielaufgaben damit die Erklaerungen
    // pedagogisch eindeutig sind.
    switch (m.kind) {
      case RechentricksKind.swapNumbers:
        return [
          tricks.explain(prompt: '2 + 7 = ?', correctAnswer: '9', grade: 1),
          tricks.explain(prompt: '3 + 8 = ?', correctAnswer: '11', grade: 1),
          // 2026-06-05 Iter 24: Mal-Tauschtrick
          tricks.explain(prompt: '7 × 3 = ?', correctAnswer: '21', grade: 3),
        ].whereType<RechentricksExplanation>().toList(growable: false);
      case RechentricksKind.neighborTask:
        return [
          tricks.explain(prompt: '5 + 4 = ?', correctAnswer: '9', grade: 1),
          tricks.explain(prompt: '6 + 7 = ?', correctAnswer: '13', grade: 1),
          // 2026-06-05 Iter 24: Verdoppeln-Trick (Mal-Aufgabe)
          tricks.explain(prompt: '4 × 8 = ?', correctAnswer: '32', grade: 3),
        ].whereType<RechentricksExplanation>().toList(growable: false);
      case RechentricksKind.inverseCheck:
        return [
          tricks.explain(prompt: '9 - 4 = ?', correctAnswer: '5', grade: 1),
          tricks.explain(prompt: '15 - 7 = ?', correctAnswer: '8', grade: 1),
        ].whereType<RechentricksExplanation>().toList(growable: false);
      case RechentricksKind.smallFirst:
        return [
          tricks.explain(prompt: '12 + 4 = ?', correctAnswer: '16', grade: 1),
          tricks.explain(prompt: '15 + 3 = ?', correctAnswer: '18', grade: 1),
          // 2026-06-05 Iter 24: 5er-Trick fuer Einmaleins
          tricks.explain(prompt: '7 × 8 = ?', correctAnswer: '56', grade: 3),
        ].whereType<RechentricksExplanation>().toList(growable: false);
      case RechentricksKind.bridgeTen:
        return [
          tricks.explain(prompt: '8 + 6 = ?', correctAnswer: '14', grade: 1),
          tricks.explain(prompt: '7 + 5 = ?', correctAnswer: '12', grade: 1),
        ].whereType<RechentricksExplanation>().toList(growable: false);
      case RechentricksKind.stepByStep:
        return [
          tricks.explain(
              prompt: '467 + 258 = ?', correctAnswer: '725', grade: 3),
          tricks.explain(
              prompt: '725 - 258 = ?', correctAnswer: '467', grade: 3),
        ].whereType<RechentricksExplanation>().toList(growable: false);
      case RechentricksKind.decomposeBoth:
        return [
          tricks.explain(
              prompt: '234 + 382 = ?', correctAnswer: '616', grade: 3),
          tricks.explain(
              prompt: '156 + 273 = ?', correctAnswer: '429', grade: 3),
        ].whereType<RechentricksExplanation>().toList(growable: false);
      case RechentricksKind.simplify:
        return [
          tricks.explain(
              prompt: '325 + 197 = ?', correctAnswer: '522', grade: 3),
          tricks.explain(
              prompt: '504 - 199 = ?', correctAnswer: '305', grade: 3),
        ].whereType<RechentricksExplanation>().toList(growable: false);
    }
  }
}

class _PosterEntry {
  const _PosterEntry({required this.mentor, required this.examples});
  final RechentricksMentor mentor;
  final List<RechentricksExplanation> examples;
}

class _HeroBanner extends StatelessWidget {
  const _HeroBanner();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFB923C), Color(0xFFEC4899)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(LumoRadius.lg),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFB923C).withOpacity(0.4),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: const [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '5 schlaue Wege zur Antwort',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Jeder Mentor zeigt dir einen anderen Trick. '
                  'Such dir den aus der dir gefaellt!',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFFFF7ED),
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 10),
          Text('🦊', style: TextStyle(fontSize: 56)),
        ],
      ),
    );
  }
}

class _MentorSection extends StatelessWidget {
  const _MentorSection({required this.entry});
  final _PosterEntry entry;

  @override
  Widget build(BuildContext context) {
    final m = entry.mentor;
    final accent = Color(m.color);
    final desc = kRechentricksDescription[m.kind] ?? '';
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(LumoRadius.lg),
        border: Border.all(color: accent.withOpacity(0.45), width: 1.6),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 2026-06-06 Iter 31: Premium-Avatar-PNG mit Emoji-Fallback.
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withOpacity(0.18),
                  border: Border.all(color: accent, width: 1.6),
                ),
                child: ClipOval(
                  child: m.avatarAsset != null
                      ? Image.asset(
                          m.avatarAsset!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Center(
                            child: Text(m.emoji,
                                style: const TextStyle(fontSize: 26)),
                          ),
                        )
                      : Center(
                          child: Text(m.emoji,
                              style: const TextStyle(fontSize: 26)),
                        ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${m.name} sagt:',
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: accent,
                      ),
                    ),
                    Text(
                      '„${m.catchphrase}"',
                      style: const TextStyle(
                        fontFamily: 'Nunito',
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: LumoColors.ink900,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (desc.isNotEmpty)
            Text(
              desc,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: LumoColors.ink600,
                height: 1.32,
              ),
            ),
          const SizedBox(height: 12),
          for (final ex in entry.examples) ...[
            RechentricksMentorCard(explanation: ex),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _FooterCredit extends StatelessWidget {
  const _FooterCredit();
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Text(
        'Diese Tricks sind in Anlehnung an die "Meine Rechentricks"-Poster '
        'aus dem Mildenberger-Uebungsheft Mathematik 1 + 3 entstanden.',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'Nunito',
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.white70,
        ),
      ),
    );
  }
}
