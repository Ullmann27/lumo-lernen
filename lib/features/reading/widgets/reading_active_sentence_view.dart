import 'package:flutter/material.dart';

import '../../../domain/reading/reading_domain.dart';
import 'reading_syllable_chip.dart';

class ReadingActiveSentenceView extends StatelessWidget {
  const ReadingActiveSentenceView({
    super.key,
    required this.sentence,
    required this.activeWordIndex,
    this.problemWord,
    this.listening = false,
  });

  final StorySentence sentence;
  final int activeWordIndex;
  final String? problemWord;
  final bool listening;

  @override
  Widget build(BuildContext context) {
    final liveProblem = _normalize(problemWord);
    return Wrap(
      spacing: 7,
      runSpacing: 7,
      children: sentence.words.asMap().entries.map((entry) {
        final word = entry.value;
        final normalized = _normalize(word.text);
        return ReadingSyllableChip(
          parts: word.syllables,
          active: entry.key == activeWordIndex,
          problem: liveProblem.isNotEmpty && normalized == liveProblem,
          listening: listening,
        );
      }).toList(growable: false),
    );
  }

  String _normalize(String? value) {
    return (value ?? '')
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-zäöüß]'), '')
        .trim();
  }
}
