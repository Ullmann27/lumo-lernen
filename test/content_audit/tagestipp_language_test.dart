// Fachprüfung 2026-11 (D-S5): Tagestipps enthielten Ersatzschreibungen und
// Grammatikfehler ("Die kleine Zeiger", "ein Wechselwarmer Tier").
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/features/shared/widgets/lumo_tagestipp_card.dart';

import 'ersatz_spelling.dart';

void main() {
  final texts = LumoTagestippCard.allTipTexts;

  test('Tagestipps nutzen echte Umlaute und ß', () {
    expect(texts.length, greaterThanOrEqualTo(28));
    for (final text in texts) {
      expect(ersatzSpellingsIn(text), isEmpty, reason: text);
    }
  });

  test('gemeldete Grammatikfehler kommen nicht mehr vor', () {
    const forbidden = <String>[
      'Die kleine Zeiger',
      'die grosse',
      'Wechselwarmer Tier',
      'Namenswoerter',
      'Namenswörter',
      'Schau dir Pizza',
      'GROSS',
      'helfen dir lange',
      'leichter wenn',
    ];
    final all = texts.join('\n');
    for (final phrase in forbidden) {
      expect(all.contains(phrase), isFalse, reason: phrase);
    }
    expect(all, contains('Der kleine Zeiger zeigt die Stunde, der große'));
    expect(all, contains('wechselwarmes Tier'));
  });

  test('jeder Tipp ist ein vollständiger Satz mit Satzzeichen', () {
    for (var i = 1; i < texts.length; i += 2) {
      expect(RegExp(r'[.!?]$').hasMatch(texts[i].trim()), isTrue,
          reason: texts[i]);
    }
  });
}
