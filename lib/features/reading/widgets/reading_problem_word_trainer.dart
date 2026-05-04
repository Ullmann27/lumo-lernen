import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../../shared/widgets/lumo_modern_card.dart';
import 'reading_syllable_chip.dart';

class ReadingProblemWordTrainer extends StatelessWidget {
  const ReadingProblemWordTrainer({
    super.key,
    required this.words,
    this.activeProblemWord,
  });

  final List<String> words;
  final String? activeProblemWord;

  @override
  Widget build(BuildContext context) {
    final activeWord = _clean(activeProblemWord);
    final uniqueWords = _uniqueCleanWords(words);
    final hasFocusWord = activeWord.isNotEmpty;
    final visibleWords = hasFocusWord
        ? <String>[activeWord, ...uniqueWords.where((word) => word != activeWord)]
        : uniqueWords;

    if (visibleWords.isEmpty) return const SizedBox.shrink();

    return LumoModernCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: hasFocusWord ? LumoColors.orangeSurface : LumoColors.goldSurface,
                  borderRadius: BorderRadius.circular(LumoRadius.md),
                ),
                child: Text(hasFocusWord ? '🦊' : '⭐', style: const TextStyle(fontSize: 26)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      hasFocusWord ? 'Lass uns das Wort kurz üben!' : 'Übungswörter für später',
                      style: LumoTextStyles.heading3.copyWith(color: LumoColors.ink900),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hasFocusWord
                          ? 'Schau mal, so teilen wir das Wort:'
                          : 'Diese Wörter merkt sich Lumo und übt sie wieder mit dir.',
                      style: LumoTextStyles.body.copyWith(color: LumoColors.ink600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (hasFocusWord)
            _FocusedProblemWord(word: activeWord)
          else
            _ProblemWordWrap(words: visibleWords),
          if (hasFocusWord && visibleWords.length > 1) ...<Widget>[
            const SizedBox(height: 14),
            Text('Auch diese Wörter üben wir später:', style: LumoTextStyles.label.copyWith(color: LumoColors.ink600)),
            const SizedBox(height: 8),
            _ProblemWordWrap(words: visibleWords.skip(1).toList(growable: false)),
          ],
        ],
      ),
    );
  }

  static String _clean(String? value) {
    return (value ?? '')
        .trim()
        .replaceAll(RegExp(r'^["„“\(\[]+|[.,!?;:"„“\)\]]+$'), '')
        .trim();
  }

  static List<String> _uniqueCleanWords(List<String> values) {
    final seen = <String>{};
    final result = <String>[];
    for (final raw in values) {
      final word = _clean(raw);
      if (word.isEmpty) continue;
      final key = word.toLowerCase();
      if (seen.add(key)) result.add(word);
    }
    return result;
  }
}

class _FocusedProblemWord extends StatelessWidget {
  const _FocusedProblemWord({required this.word});

  final String word;

  @override
  Widget build(BuildContext context) {
    final parts = _syllables(word);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(LumoRadius.lg),
        border: Border.all(color: LumoColors.orange.withOpacity(.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ReadingSyllableChip(parts: parts, active: true, problem: true),
          const SizedBox(height: 12),
          Text('1. Sag zuerst: ${parts.first}', style: LumoTextStyles.body.copyWith(color: LumoColors.ink700, fontWeight: FontWeight.w900)),
          if (parts.length > 1) ...<Widget>[
            const SizedBox(height: 4),
            Text('2. Dann: ${parts.skip(1).join('-')}', style: LumoTextStyles.body.copyWith(color: LumoColors.ink700, fontWeight: FontWeight.w900)),
          ],
          const SizedBox(height: 4),
          Text('3. Jetzt zusammen: $word', style: LumoTextStyles.body.copyWith(color: LumoColors.orange, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class _ProblemWordWrap extends StatelessWidget {
  const _ProblemWordWrap({required this.words});

  final List<String> words;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: words.map((word) {
        return ReadingSyllableChip(parts: _syllables(word), problem: true);
      }).toList(growable: false),
    );
  }
}

List<String> _syllables(String word) {
  final cleaned = word.replaceAll(RegExp(r'[^A-Za-zÄÖÜäöüß]'), '');
  if (cleaned.isEmpty) return <String>[word];
  if (cleaned.length <= 3) return <String>[cleaned];

  final parts = <String>[];
  final buffer = StringBuffer();
  const vowels = 'aeiouäöüyAEIOUÄÖÜY';
  for (var i = 0; i < cleaned.length; i++) {
    buffer.write(cleaned[i]);
    final isVowel = vowels.contains(cleaned[i]);
    final nextIsConsonant = i + 1 < cleaned.length && !vowels.contains(cleaned[i + 1]);
    if (isVowel && nextIsConsonant && buffer.length >= 2 && i < cleaned.length - 2) {
      parts.add(buffer.toString());
      buffer.clear();
    }
  }
  if (buffer.isNotEmpty) parts.add(buffer.toString());
  return parts.isEmpty ? <String>[cleaned] : parts;
}
