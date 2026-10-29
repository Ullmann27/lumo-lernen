// Lumo ABC-Abenteuer – responsive Hologlas-Lernwelt.
// Alle 26 deutschen Buchstaben, Beispielwörter und Lumo-Audio bleiben erhalten.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/lumo_voice.dart';
import '../../widgets/design/lumo_design_system.dart';
import '../../theme/lumo_visual_tokens.dart';

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

// Die vertrauten Beispielwörter bleiben unverändert.
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

  void _onTap(_LetterEntry entry) {
    HapticFeedback.selectionClick();
    setState(() => _selectedLetter = entry.letter);
    _speak(entry);
  }

  void _speak(_LetterEntry entry) {
    LumoVoice.instance.speak(
      '${entry.letter} wie ${entry.exampleWord}',
      style: VoiceStyle.explain,
    );
  }

  @override
  Widget build(BuildContext context) {
    final selected = _abc.where((e) => e.letter == _selectedLetter);
    final chosen = selected.isEmpty ? null : selected.first;
    return Scaffold(
      backgroundColor: LumoVisualTokens.night,
      appBar: AppBar(
        backgroundColor: const Color(0xEE081D3D),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        title: const Text(
          'ABC-Abenteuer',
          style: TextStyle(
            fontFamily: 'Nunito',
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
      ),
      body: LumoSceneBackground(
        scene: LumoScene.learning,
        dimmed: true,
        child: SafeArea(
          top: false,
          child: CustomScrollView(
            key: const ValueKey('abc-premium-scroll'),
            slivers: [
              const SliverPadding(
                padding: EdgeInsets.fromLTRB(16, 18, 16, 12),
                sliver: SliverToBoxAdapter(child: _AbcHero()),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                sliver: SliverToBoxAdapter(
                  child: _SelectedLetterBar(
                    entry: chosen,
                    onReplay: chosen == null ? null : () => _speak(chosen),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverLayoutBuilder(
                  builder: (context, constraints) {
                    final width = constraints.crossAxisExtent - 32;
                    // Größere Touch-Ziele statt sieben winziger Karten auf
                    // dem Fold. Auf schmalen Geräten mindestens drei Spalten.
                    final columns = width >= 1100
                        ? 7
                        : width >= 840
                            ? 6
                            : width >= 630
                                ? 5
                                : width >= 410
                                    ? 4
                                    : 3;
                    return SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: columns <= 3 ? 0.70 : columns >= 6 ? 0.88 : 0.78,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final entry = _abc[index];
                          return _AbcCard(
                            key: ValueKey('abc-letter-${entry.letter}'),
                            entry: entry,
                            accent: _AbcCard.accents[index % _AbcCard.accents.length],
                            selected: entry.letter == _selectedLetter,
                            onTap: () => _onTap(entry),
                          );
                        },
                        childCount: _abc.length,
                      ),
                    );
                  },
                ),
              ),
              const SliverPadding(
                padding: EdgeInsets.fromLTRB(16, 20, 16, 26),
                sliver: SliverToBoxAdapter(child: _AbcHint()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AbcHero extends StatelessWidget {
  const _AbcHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 142),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xF216457C),
            Color(0xF00C2B54),
            Color(0xF21A2153),
          ],
        ),
        border: Border.all(color: const Color(0xBB54E1F8), width: 1.3),
        boxShadow: const [
          BoxShadow(color: Color(0x3316CFF6), blurRadius: 20, offset: Offset(0, 7)),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, bounds) {
          final compact = bounds.maxWidth < 440;
          final foxSize = compact ? 100.0 : 148.0;
          return Padding(
            padding: EdgeInsets.fromLTRB(compact ? 15 : 22, 14, 10, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'LUMO · LESEWELT',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          color: Color(0xFF7DEBFA),
                          letterSpacing: 1.2,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        'Entdecke dein ABC!',
                        maxLines: 2,
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: compact ? 22 : 29,
                          height: 1.08,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 9),
                      Text(
                        'Tippe auf einen Buchstaben. Lumo spricht ihn dir vor.',
                        style: TextStyle(
                          fontFamily: 'Nunito',
                          fontSize: compact ? 12.5 : 15,
                          height: 1.25,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFE1F5FF),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 3),
                Image.asset(
                  'assets/lumo_design/fox/fox_book_point.png',
                  key: const ValueKey('abc-original-lumo-fox'),
                  width: foxSize,
                  height: foxSize,
                  fit: BoxFit.contain,
                  semanticLabel: 'Lumo zeigt dir das ABC',
                  errorBuilder: (_, __, ___) => Icon(
                    Icons.auto_stories_rounded,
                    color: const Color(0xFF7DEBFA),
                    size: foxSize * .60,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SelectedLetterBar extends StatelessWidget {
  const _SelectedLetterBar({required this.entry, this.onReplay});
  final _LetterEntry? entry;
  final VoidCallback? onReplay;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        key: const ValueKey('abc-selected-guide'),
        constraints: const BoxConstraints(minHeight: 56),
        decoration: BoxDecoration(
          color: const Color(0xED081D3D),
          border: Border.all(color: const Color(0x9968E8FA)),
          borderRadius: BorderRadius.circular(19),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Row(
          children: [
            Icon(
              entry == null ? Icons.touch_app_rounded : Icons.volume_up_rounded,
              color: const Color(0xFF76EFF9),
              size: 25,
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Text(
                entry == null
                    ? 'Wähle deinen ersten Buchstaben!'
                    : '${entry!.letter} wie ${entry!.exampleWord}',
                key: const ValueKey('abc-selected-caption'),
                maxLines: 2,
                style: const TextStyle(
                  fontFamily: 'Nunito',
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  fontSize: 17,
                ),
              ),
            ),
            if (onReplay != null)
              IconButton.filledTonal(
                key: const ValueKey('abc-replay-sound'),
                tooltip: 'Buchstaben erneut anhören',
                onPressed: onReplay,
                icon: const Icon(Icons.replay_rounded),
                style: IconButton.styleFrom(
                  minimumSize: const Size(48, 48),
                  foregroundColor: const Color(0xFF00253B),
                  backgroundColor: const Color(0xFF86ECFF),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AbcCard extends StatelessWidget {
  const _AbcCard({
    super.key,
    required this.entry,
    required this.accent,
    required this.selected,
    required this.onTap,
  });

  final _LetterEntry entry;
  final Color accent;
  final bool selected;
  final VoidCallback onTap;

  static const accents = <Color>[
    Color(0xFF77E7FF),
    Color(0xFFBCA3FF),
    Color(0xFF7EF6C0),
    Color(0xFFFFD17A),
  ];

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: '${entry.letter} wie ${entry.exampleWord}. Zum Anhören tippen.',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: AnimatedContainer(
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: selected
                    ? [const Color(0xFF25678E), const Color(0xFF0B365E)]
                    : [const Color(0xF21A4772), const Color(0xF20B2549)],
              ),
              border: Border.all(
                color: selected ? Colors.white : accent.withValues(alpha: .66),
                width: selected ? 2.5 : 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: selected ? .37 : .13),
                  blurRadius: selected ? 20 : 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(7, 6, 7, 7),
            child: LayoutBuilder(
              builder: (context, space) {
                final compact = space.maxHeight < 135;
                final symbolSize = (space.maxHeight * (compact ? .25 : .28))
                    .clamp(23.0, 46.0)
                    .toDouble();
                final letterSize = (space.maxHeight * .22)
                    .clamp(23.0, 39.0)
                    .toDouble();
                return Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: accent.withValues(alpha: .15),
                        border: Border.all(color: accent.withValues(alpha: .28)),
                      ),
                      padding: const EdgeInsets.all(5),
                      child: ExcludeSemantics(
                        child: Text(
                          entry.emoji,
                          style: TextStyle(
                            fontSize: symbolSize,
                            // Nunito does not contain emoji. Explicit fallback
                            // keeps icons readable in the app and real-font QA.
                            fontFamilyFallback: const ['Noto Color Emoji'],
                          ),
                        ),
                      ),
                    ),
                    Text(
                      entry.exampleWord,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'Nunito',
                        fontWeight: FontWeight.w900,
                        fontSize: compact ? 11.5 : 13.5,
                        color: Colors.white,
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(13),
                        color: const Color(0xCC08192F),
                        border: Border.all(color: accent.withValues(alpha: .48)),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '${entry.letter} ${entry.letter.toLowerCase()}',
                          style: TextStyle(
                            fontFamily: 'Nunito',
                            fontWeight: FontWeight.w900,
                            fontSize: letterSize,
                            color: accent,
                            height: 1.05,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _AbcHint extends StatelessWidget {
  const _AbcHint();

  @override
  Widget build(BuildContext context) {
    return LumoGlassCard(
      radius: 20,
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
      child: const Row(
        children: [
          Icon(Icons.tips_and_updates_rounded,
              size: 26, color: Color(0xFF86ECFF)),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Lumos Tipp: Sprich den Buchstaben langsam nach. '
              'Das Beispielwort hilft dir beim Lesen!',
              style: TextStyle(
                fontFamily: 'Nunito',
                fontSize: 14,
                fontWeight: FontWeight.w800,
                height: 1.35,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
