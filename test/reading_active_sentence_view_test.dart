import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/domain/reading/reading_domain.dart';
import 'package:lumo_lernen/features/reading/widgets/reading_active_sentence_view.dart';
import 'package:lumo_lernen/features/reading/widgets/reading_syllable_chip.dart';

void main() {
  testWidgets('renders every word as a syllable chip', (tester) async {
    const sentence = StorySentence(
      id: 's1',
      index: 0,
      text: 'Lumo geht Garten',
      words: <WordToken>[
        WordToken(text: 'Lumo', syllables: <String>['Lu', 'mo']),
        WordToken(text: 'geht', syllables: <String>['geht']),
        WordToken(text: 'Garten', syllables: <String>['Gar', 'ten']),
      ],
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ReadingActiveSentenceView(sentence: sentence, activeWordIndex: 2),
        ),
      ),
    );

    expect(find.byType(ReadingSyllableChip), findsNWidgets(3));
    expect(find.text('Lumo'), findsNothing);
    expect(find.text('Garten'), findsNothing);
  });

  testWidgets('marks matching problem word', (tester) async {
    const sentence = StorySentence(
      id: 's1',
      index: 0,
      text: 'Lumo liest Garten',
      words: <WordToken>[
        WordToken(text: 'Lumo', syllables: <String>['Lu', 'mo']),
        WordToken(text: 'liest', syllables: <String>['liest']),
        WordToken(text: 'Garten', syllables: <String>['Gar', 'ten']),
      ],
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ReadingActiveSentenceView(
            sentence: sentence,
            activeWordIndex: 0,
            problemWord: 'Garten',
            listening: true,
          ),
        ),
      ),
    );

    expect(find.byType(ReadingSyllableChip), findsNWidgets(3));
  });
}
