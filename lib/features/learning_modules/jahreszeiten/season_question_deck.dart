import 'dart:math' as math;

/// A complete, non-repeating thirty-question season round.
///
/// Indices follow Frühling=0, Sommer=1, Herbst=2, Winter=3.
/// An image prompt is different for each season; every verbal hint is unique.
/// The deck is built once per round, so answers never affect question order.
class SeasonQuestion {
  const SeasonQuestion({required this.id, required this.seasonIndex, this.hint});

  final String id;
  final int seasonIndex;
  final String? hint;

  bool get isImage => hint == null;
}

class SeasonQuestionDeck {
  SeasonQuestionDeck({math.Random? random}) : _random = random ?? math.Random();

  static const int questionCount = 30;
  final math.Random _random;

  // Avoid ambiguous cues like "eating ice cream" or "wind and rain":
  // those can occur in several seasons and are unfair as quiz answers.
  static const List<SeasonQuestion> _questions = [
    SeasonQuestion(id: 'image-spring', seasonIndex: 0),
    SeasonQuestion(id: 'image-summer', seasonIndex: 1),
    SeasonQuestion(id: 'image-autumn', seasonIndex: 2),
    SeasonQuestion(id: 'image-winter', seasonIndex: 3),
    SeasonQuestion(id: 'spring-01', seasonIndex: 0, hint: 'Nach dem Winter öffnen sich viele Knospen.'),
    SeasonQuestion(id: 'spring-02', seasonIndex: 0, hint: 'Die ersten Krokusse wachsen im Garten.'),
    SeasonQuestion(id: 'spring-03', seasonIndex: 0, hint: 'Die Bäume bekommen wieder frische grüne Blätter.'),
    SeasonQuestion(id: 'spring-04', seasonIndex: 0, hint: 'Das erste zarte Grün erscheint auf den Wiesen.'),
    SeasonQuestion(id: 'spring-05', seasonIndex: 0, hint: 'Nach den kalten Monaten beginnt die Blütezeit.'),
    SeasonQuestion(id: 'spring-06', seasonIndex: 0, hint: 'Viele Pflanzen beginnen nach dem Winter zu wachsen.'),
    SeasonQuestion(id: 'spring-07', seasonIndex: 0, hint: 'Die Natur erwacht aus ihrer Winterruhe.'),
    SeasonQuestion(id: 'summer-01', seasonIndex: 1, hint: 'Die Sommerferien haben begonnen.'),
    SeasonQuestion(id: 'summer-02', seasonIndex: 1, hint: 'An heißen Tagen suchen wir Schatten.'),
    SeasonQuestion(id: 'summer-03', seasonIndex: 1, hint: 'Im Garten blühen viele Sonnenblumen.'),
    SeasonQuestion(id: 'summer-04', seasonIndex: 1, hint: 'Die Sonne geht erst sehr spät unter.'),
    SeasonQuestion(id: 'summer-05', seasonIndex: 1, hint: 'Im Juli und August besuchen viele Menschen das Freibad.'),
    SeasonQuestion(id: 'summer-06', seasonIndex: 1, hint: 'Nach dem Schulschluss beginnen die langen Ferien.'),
    SeasonQuestion(id: 'autumn-01', seasonIndex: 2, hint: 'Viele Blätter werden rot, gelb und braun.'),
    SeasonQuestion(id: 'autumn-02', seasonIndex: 2, hint: 'Reife Kastanien fallen von den Bäumen.'),
    SeasonQuestion(id: 'autumn-03', seasonIndex: 2, hint: 'Viele Zugvögel ziehen in wärmere Gebiete.'),
    SeasonQuestion(id: 'autumn-04', seasonIndex: 2, hint: 'Wir sammeln die bunt gefärbten Blätter.'),
    SeasonQuestion(id: 'autumn-05', seasonIndex: 2, hint: 'Zu Halloween werden Kürbisse geschnitzt.'),
    SeasonQuestion(id: 'autumn-06', seasonIndex: 2, hint: 'Nach dem Sommer werden die Tage wieder kürzer.'),
    SeasonQuestion(id: 'winter-01', seasonIndex: 3, hint: 'An kalten Tagen bildet sich Frost an den Fenstern.'),
    SeasonQuestion(id: 'winter-02', seasonIndex: 3, hint: 'Ein Schneemann steht im verschneiten Garten.'),
    SeasonQuestion(id: 'winter-03', seasonIndex: 3, hint: 'Die Zweige sind mit Schnee bedeckt.'),
    SeasonQuestion(id: 'winter-04', seasonIndex: 3, hint: 'Im Dezember feiern viele Menschen Weihnachten.'),
    SeasonQuestion(id: 'winter-05', seasonIndex: 3, hint: 'Die Pfütze ist bei Frost zugefroren.'),
    SeasonQuestion(id: 'winter-06', seasonIndex: 3, hint: 'Wir ziehen Handschuhe und eine dicke Winterjacke an.'),
    SeasonQuestion(id: 'winter-07', seasonIndex: 3, hint: 'Eiszapfen hängen an einer Dachrinne.'),
  ];

  List<SeasonQuestion> build() {
    final remaining = _questions.toList()..shuffle(_random);
    final result = <SeasonQuestion>[];
    var lastSeason = -1;
    while (remaining.isNotEmpty) {
      final candidates =
          remaining.where((question) => question.seasonIndex != lastSeason).toList();
      if (candidates.isEmpty) {
        throw StateError('Season bank must allow alternating correct answers.');
      }
      // Prioritize the most frequent remaining season to avoid a dead end,
      // then vary individual cues within that season.
      final counts = <int, int>{};
      for (final question in remaining) {
        counts.update(question.seasonIndex, (value) => value + 1,
            ifAbsent: () => 1);
      }
      final highest = candidates
          .map((question) => counts[question.seasonIndex]!)
          .reduce(math.max);
      final possible = candidates
          .where((question) => counts[question.seasonIndex] == highest)
          .toList()
        ..shuffle(_random);
      final chosen = possible.first;
      result.add(chosen);
      lastSeason = chosen.seasonIndex;
      remaining.remove(chosen);
    }
    return result;
  }
}
