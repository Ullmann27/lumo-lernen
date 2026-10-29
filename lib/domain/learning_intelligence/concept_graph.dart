import '../../core/school_exercise_generator.dart';

class LumoConcept {
  const LumoConcept(
      {required this.id,
      required this.subject,
      required this.units,
      this.prerequisites = const [],
      this.goal = ''});
  final String id;
  final String subject;
  final List<String> units;
  final List<String> prerequisites;
  final String goal;
}

class ConceptTaskBinding {
  const ConceptTaskBinding(this.conceptId, this.subject, this.unit);
  final String conceptId;
  final String subject;
  final String unit;
}

/// Versioned, deliberately partial mapping to existing application tasks.
/// Edges are teaching prerequisites, never inferred diagnoses or child facts.
class LumoConceptGraph {
  LumoConceptGraph(Iterable<LumoConcept> source) {
    final entries = <String, LumoConcept>{};
    for (final n in source) {
      if (entries.containsKey(n.id) || n.id.isEmpty)
        throw ArgumentError('Duplicate concept');
      entries[n.id] = LumoConcept(
          id: n.id,
          subject: n.subject,
          units: List.unmodifiable(n.units),
          prerequisites: List.unmodifiable(n.prerequisites),
          goal: n.goal);
    }
    final visiting = <String>{};
    final visited = <String>{};
    void visit(String id) {
      if (!entries.containsKey(id)) throw ArgumentError('Unknown prerequisite');
      if (visiting.contains(id)) throw ArgumentError('Cyclic concept graph');
      if (!visited.add(id)) return;
      visiting.add(id);
      for (final parent in entries[id]!.prerequisites) {
        visit(parent);
      }
      visiting.remove(id);
    }

    for (final id in entries.keys) {
      visit(id);
    }
    _nodes = Map.unmodifiable(entries);
  }
  static const version = 1;
  late final Map<String, LumoConcept> _nodes;
  List<LumoConcept> get nodes => List.unmodifiable(_nodes.values);
  LumoConcept? operator [](String id) => _nodes[id];
  List<LumoConcept> forTask(String subject, String unit) =>
      List.unmodifiable(_nodes.values
          .where((n) => n.subject == subject && n.units.contains(unit)));
  Set<String> prerequisitesOf(String id) {
    if (!_nodes.containsKey(id)) throw ArgumentError('Unknown concept');
    final result = <String>{};
    void add(String key) {
      for (final p in _nodes[key]!.prerequisites) {
        if (result.add(p)) add(p);
      }
    }

    add(id);
    return Set.unmodifiable(result);
  }

  List<ConceptTaskBinding> bindingsForGrade(int grade,
      {bool currentGradeOnly = false}) {
    if (grade < 1 || grade > 4) throw ArgumentError('Invalid grade');
    return List.unmodifiable([
      for (final node in nodes)
        for (final unit in node.units)
          if (Curriculum.unitsForGrade(node.subject, grade,
                  currentGradeOnly: currentGradeOnly)
              .contains(unit))
            ConceptTaskBinding(node.id, node.subject, unit)
    ]);
  }

  factory LumoConceptGraph.reference() => LumoConceptGraph(const [
        LumoConcept(
            id: 'math.counting',
            subject: 'Mathematik',
            units: ['Mengenvergleich', 'Zahlenreihe'],
            goal: 'Gegenstände einzeln und vollständig zählen'),
        LumoConcept(
            id: 'math.bundling',
            subject: 'Mathematik',
            // The shipped Zehner/Einer workshop contains the bundling practice.
            // A practice link alone never confirms the bundling process goal.
            units: ['Zehner und Einer'],
            prerequisites: ['math.counting'],
            goal: 'Genau zehn Einer zu einem Bündel zusammenfassen'),
        LumoConcept(
            id: 'math.tens_ones',
            subject: 'Mathematik',
            units: ['Zehner und Einer'],
            prerequisites: ['math.bundling'],
            goal: 'Zehnerbündel und verbleibende Einer unterscheiden'),
        LumoConcept(
            id: 'math.place_value',
            subject: 'Mathematik',
            units: ['Zahl in Worten', 'Zehner und Einer'],
            prerequisites: ['math.tens_ones'],
            goal: 'Eine zweistellige Zahl bauen und ihre Stellen erklären'),
        LumoConcept(
            id: 'math.cross_ten',
            subject: 'Mathematik',
            units: ['Plus bis 20', 'Minus ueber 10'],
            prerequisites: ['math.place_value'],
            goal: 'Den nächsten vollen Zehner als Zwischenschritt nutzen'),
        LumoConcept(
            id: 'math.multi_digit_addition',
            subject: 'Mathematik',
            units: ['Schriftliche Addition'],
            prerequisites: ['math.cross_ten'],
            goal: 'Stellenweise addieren und Bündelübertrag begründen'),
        LumoConcept(
            id: 'language.sounds',
            subject: 'Deutsch',
            units: ['Anfangslaute', 'Buchstaben-Lautierung'],
            goal: 'Anfangslaute und Buchstaben zuordnen'),
        LumoConcept(
            id: 'language.syllables',
            subject: 'Deutsch',
            units: ['Silben'],
            prerequisites: ['language.sounds'],
            goal: 'Wörter aus geordneten Silben zusammensetzen'),
        LumoConcept(
            id: 'language.sentences',
            subject: 'Deutsch',
            units: ['Satz bauen', 'Satzglieder'],
            prerequisites: ['language.syllables'],
            goal: 'Satzbausteine sinnvoll ordnen'),
        LumoConcept(
            id: 'reading.words',
            subject: 'Lesen',
            units: ['Woerter lesen', 'Bild und Wort'],
            prerequisites: ['language.syllables'],
            goal: 'Ein Wort seinem Inhalt zuordnen'),
        LumoConcept(
            id: 'reading.evidence',
            subject: 'Lesen',
            units: ['Lesesinn', 'Sätze lesen'],
            prerequisites: ['reading.words'],
            goal: 'Eine Aussage mit einer passenden Textstelle begründen'),
        LumoConcept(
            id: 'spelling.words',
            subject: 'Rechtschreibung',
            units: ['Haeufige Woerter', 'Doppelmitlaut'],
            prerequisites: ['language.sounds'],
            goal: 'Geübte Schreibweisen ohne vorgegebene Lösung anwenden'),
        LumoConcept(
            id: 'nature.observation',
            subject: 'Sachunterricht',
            units: ['Tiere', 'Wetter', 'Jahreszeiten'],
            goal: 'Beobachtungen anhand passender Merkmale zuordnen'),
        LumoConcept(
            id: 'nature.connections',
            subject: 'Sachunterricht',
            units: ['Wasserkreislauf', 'Ökosysteme'],
            prerequisites: ['nature.observation'],
            goal:
                'Beobachtete Zusammenhänge in eine begründete Reihenfolge bringen'),
      ]);
}
