// ════════════════════════════════════════════════════════════════════════
// LUMO ABC-TAFEL — Mia & Mo inspirierter Leselehrgang fuer Klasse 1
// ════════════════════════════════════════════════════════════════════════
// 2026-06-05 Iter 23: 26 deutsche Grossbuchstaben mit Beispiel-Wort +
// Emoji-Illustration. Tippt das Kind eine Kachel an, spricht Lumo den
// Buchstaben + das Beispielwort vor. Inspiriert vom Mildenberger
// "Wir lernen Deutsch mit Mia und Mo | Leselehrgang" ABC-Poster.
// ════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../../core/lumo_voice.dart';
import '../../widgets/premium/lumo_magic_background.dart';

class _LetterEntry {
  const _LetterEntry({
    required this.letter,
    required this.exampleWord,
    required this.emoji,
  });
  final String letter;
  final String exampleWord;
  final String emoji;
}

// Auswahl folgt der Mia & Mo Poster-Reihenfolge (Bild #1 von Heinz).
// Pro Buchstabe ein konkretes, kindgerechtes Beispielwort + Emoji.
const List<_LetterEntry> _abc = <_LetterEntry>[
  _LetterEntry(letter: 'A', exampleWord: 'Affe', emoji: '🐒'),
  _LetterEntry(letter: 'B', exampleWord: 'Ball', emoji: '⚽'),
  _LetterEntry(letter: 'C', exampleWord: 'Clown', emoji: '🤡'),
  _LetterEntry(letter: 'D', exampleWord: 'Dino', emoji: '🦕'),
  _LetterEntry(letter: 'E', exampleWord: 'Esel', emoji: '🫏'),
  _LetterEntry(letter: 'F', exampleWord: 'Fisch', emoji: '🐟'),
  _LetterEntry(letter: 'G', exampleWord: 'Gans', emoji: '🪿'),
  _LetterEntry(letter: 'H', exampleWord: 'Hamster', emoji: '🐹'),
  _LetterEntry(letter: 'I', exampleWord: 'Igel', emoji: '🦔'),
  _LetterEntry(letter: 'J', exampleWord: 'Jacke', emoji: '🧥'),
  _LetterEntry(letter: 'K', exampleWord: 'Kakao', emoji: '🍫'),
  _LetterEntry(letter: 'L', exampleWord: 'Lampe', emoji: '💡'),
  _LetterEntry(letter: 'M', exampleWord: 'Maus', emoji: '🐭'),
  _LetterEntry(letter: 'N', exampleWord: 'Nest', emoji: '🪺'),
  _LetterEntry(letter: 'O', exampleWord: 'Oma', emoji: '👵'),
  _LetterEntry(letter: 'P', exampleWord: 'Papagei', emoji: '🦜'),
  _LetterEntry(letter: 'Q', exampleWord: 'Quartett', emoji: '🃏'),
  _LetterEntry(letter: 'R', exampleWord: 'Rad', emoji: '🚲'),
  _LetterEntry(letter: 'S', exampleWord: 'Sonne', emoji: '☀️'),
  _LetterEntry(letter: 'T', exampleWord: 'Tisch', emoji: '🪑'),
  _LetterEntry(letter: 'U', exampleWord: 'Uhr', emoji: '⏰'),
  _LetterEntry(letter: 'V', exampleWord: 'Vogel', emoji: '🐦'),
  _LetterEntry(letter: 'W', exampleWord: 'Wald', emoji: '🌲'),
  _LetterEntry(letter: 'X', exampleWord: 'Xylophon', emoji: '🎹'),
  _LetterEntry(letter: 'Y', exampleWord: 'Yacht', emoji: '⛵'),
  _LetterEntry(letter: 'Z', exampleWord: 'Zebra', emoji: '🦓'),
];

class LumoAbcTafelScreen extends StatefulWidget {
  const LumoAbcTafelScreen({super.key});

  @override
  State<LumoAbcTafelScreen> createState() => _LumoAbcTafelScreenState();
}

class _LumoAbcTafelScreenState extends State<LumoAbcTafelScreen> {
  String? _selectedLetter;

  void _onTap(_LetterEntry e) {
    setState(() => _selectedLetter = e.letter);
    LumoVoice.instance.speak(
      '${e.letter} wie ${e.exampleWord}',
      style: VoiceStyle.explain,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'ABC-Tafel',
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
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                sliver: SliverToBoxAdapter(child: _HeroBanner()),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 28),
                sliver: SliverGrid(
                  gridDelegate:
                      const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 130,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 0.85,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final e = _abc[i];
                      return _LetterCard(
                        entry: e,
                        highlighted: _selectedLetter == e.letter,
                        onTap: () => _onTap(e),
                      );
                    },
                    childCount: _abc.length,
                  ),
                ),
              ),
              const SliverPadding(
                padding: EdgeInsets.fromLTRB(14, 0, 14, 28),
                sliver: SliverToBoxAdapter(child: _Tip()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF60A5FA), Color(0xFFA855F7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(LumoRadius.lg),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF60A5FA).withOpacity(0.4),
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
                  'Mia & Mo lernen das ABC',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Tipp einen Buchstaben an - Lumo spricht ihn dir vor!',
                  style: TextStyle(
                    fontFamily: 'Nunito',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFEDE9FE),
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 10),
          Text('📖', style: TextStyle(fontSize: 56)),
        ],
      ),
    );
  }
}

class _LetterCard extends StatelessWidget {
  const _LetterCard({
    required this.entry,
    required this.highlighted,
    required this.onTap,
  });
  final _LetterEntry entry;
  final bool highlighted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF60A5FA);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        decoration: BoxDecoration(
          color: highlighted
              ? const Color(0xFFFEF9C3)
              : Colors.white,
          borderRadius: BorderRadius.circular(LumoRadius.lg),
          border: Border.all(
            color: highlighted
                ? const Color(0xFFFB923C)
                : accent.withOpacity(0.35),
            width: highlighted ? 2.4 : 1.4,
          ),
          boxShadow: [
            BoxShadow(
              color: (highlighted ? const Color(0xFFFB923C) : accent)
                  .withOpacity(0.18),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Bild
            Text(entry.emoji, style: const TextStyle(fontSize: 38)),
            // Beispielwort
            Text(
              entry.exampleWord,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Nunito',
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E3A8A),
              ),
            ),
            // Buchstabenleiste mit Gross + Klein
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(LumoRadius.md),
                border: Border.all(
                    color: const Color(0xFFFCD34D), width: 1.3),
              ),
              child: Text(
                '${entry.letter} ${entry.letter.toLowerCase()}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFFB91C1C),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tip extends StatelessWidget {
  const _Tip();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(LumoRadius.lg),
        border: Border.all(
            color: const Color(0xFFFFD68A).withOpacity(0.5), width: 1.4),
      ),
      child: const Row(
        children: [
          Text('🦊', style: TextStyle(fontSize: 28)),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Tipp: Sprich jeden Buchstaben langsam. Das Beispielwort '
              'hilft dir den Laut zu lernen. So liest du immer besser!',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: LumoColors.ink700,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
