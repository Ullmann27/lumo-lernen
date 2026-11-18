// Fachprüfung 2026-11 (S-M17): Aktivitätskarten standen in Lehrersprache
// („Entscheidungsmatrix“, „Mobilitätsbezogene Reflexionskompetenz“,
// „Analysiere drei dargestellte Verkehrssituationen“). Das Kind liest Auftrag,
// Lernziel und Nachweis selbst.
import 'package:flutter_test/flutter_test.dart';
import 'package:lumo_lernen/core/curriculum/primary_activity_catalog.dart';

import 'ersatz_spelling.dart';

void main() {
  test('Aktivitätskarten sind in Kindersprache geschrieben', () {
    const adultWords = <String>[
      'kompetenz',
      'matrix',
      'analysiere',
      'reflexion',
      'lehrkraft',
      'dargestellte',
      'zielgruppe',
      'visuelle',
      'prozesskette',
      'protokoll',
      'absolviere',
      'kriterien',
      'umweltwirkung',
      'stellung',
    ];
    expect(PrimaryActivityCatalog.all, hasLength(60));
    for (final activity in PrimaryActivityCatalog.all) {
      for (final text in <String>[
        activity.instruction,
        activity.competency,
        activity.evidence,
      ]) {
        for (final word in adultWords) {
          expect(text.toLowerCase(), isNot(contains(word)),
              reason: '${activity.id}: $text');
        }
        expect(ersatzSpellingsIn(text), isEmpty, reason: text);
      }
      expect(activity.instruction.length, lessThanOrEqualTo(200),
          reason: activity.id);
      expect(activity.competency, isNot(activity.title), reason: activity.id);
    }
  });
}
