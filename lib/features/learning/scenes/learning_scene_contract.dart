import 'package:flutter/foundation.dart';

/// Lernszenen-Vertrag zwischen Sols Lern-Engine und Opus' Darstellung.
///
/// Sol verantwortet Lernlogik, Lösungskontrolle, Lernhistorie und die
/// didaktische Auswahl. Ein [LearningSceneDirector] beschreibt mit einer
/// [LearningSceneRequest], was zu sehen ist, welche Texte gelten und welche
/// Handlungen gerade erlaubt sind. Der Renderer zeigt genau das, spielt die
/// passenden Animationen und meldet jede Handlung des Kindes als
/// [LearningSceneEvent] zurück. Er bewertet nichts selbst und speichert
/// keine Lernstände.
///
/// Datenschutz wie im übrigen Tutor: keine Kindidentität, keine Zeitstempel,
/// keine Berührungskoordinaten und keine Lösung vor ihrer Prüfung.

/// Welche Art von Szene dargestellt wird.
enum LearningSceneKind {
  /// Stellenwerte mit Zehnerstangen und Einerwürfeln.
  placeValue,
}

/// Abschnitt einer Szene. Die Reihenfolge legt die Engine fest.
enum LearningSceneStage { explore, construct, explain, done }

/// Handlungen, die ein Kind in einer Szene auslösen kann.
enum LearningSceneInput {
  /// Zählen der vollen Zehner (Stangen antippen).
  startCounting,

  /// Ein Objekt (zum Beispiel eine Zehnerstange) zählen oder entzählen.
  countObject,
  resetCount,

  /// Eine Stange öffnen und zehn lose Würfel selbst bündeln.
  startBundling,
  selectObject,
  bundleTen,

  /// Lumo zeigt das Bündeln noch einmal vor. Ohne Bewertung.
  replayDemonstration,

  /// Eine andere Zahl selbst bauen.
  startConstruction,
  addTen,
  removeTen,
  addOne,
  removeOne,
  submitConstruction,

  /// Verständnisfrage beantworten („Erklär es Lumo“).
  answerChoice,
}

/// Was Lumo ausdrücken soll. Der Renderer wählt die passende Animation.
enum LumoPerformanceIntent {
  greet,
  listen,
  think,
  explain,
  demonstrate,
  encourage,
  approve,
  idea,
  celebrate,
  pause,
  wait,
}

/// Ein sichtbares, ansprechbares Objekt der Szene.
@immutable
class LearningSceneObject {
  const LearningSceneObject(
      {required this.id, required this.type, this.marked = false});

  /// Stabil innerhalb einer Szene, z. B. `ten-3` oder `loose-7`.
  final String id;

  /// `ten_rod` oder `unit_cube`.
  final String type;

  /// Gezählt oder ausgewählt.
  final bool marked;

  @override
  bool operator ==(Object other) =>
      other is LearningSceneObject &&
      other.id == id &&
      other.type == type &&
      other.marked == marked;

  @override
  int get hashCode => Object.hash(id, type, marked);
}

/// Was die Engine gerade darstellen lässt. Jede Änderung erhöht [revision].
@immutable
class LearningSceneRequest {
  const LearningSceneRequest({
    required this.sceneId,
    required this.kind,
    required this.stage,
    required this.revision,
    required this.instruction,
    required this.facts,
    required this.objects,
    required this.allowedInputs,
    required this.lumo,
    this.feedback,
    this.choices = const [],
    this.lumoFocus,
  });

  final String sceneId;
  final LearningSceneKind kind;
  final LearningSceneStage stage;
  final int revision;

  /// Kindgerechter Arbeitsauftrag, von der Engine formuliert.
  final String instruction;

  /// Rückmeldung zur letzten Handlung, falls die Engine eine gibt.
  final String? feedback;

  /// Sichtbare Zahlen der Szene, z. B. `number`, `tens`, `ones`, `target`.
  final Map<String, int> facts;
  final List<LearningSceneObject> objects;
  final Set<LearningSceneInput> allowedInputs;

  /// Antwortmöglichkeiten der Verständnisfrage.
  final List<int> choices;
  final LumoPerformanceIntent lumo;

  /// Objekt oder Bereich, zu dem Lumo schaut oder zeigt.
  final String? lumoFocus;

  int fact(String name) => facts[name] ?? 0;
  bool allows(LearningSceneInput input) => allowedInputs.contains(input);
}

/// Eine Handlung des Kindes, zurück an die Engine.
@immutable
class LearningSceneEvent {
  const LearningSceneEvent({
    required this.sceneId,
    required this.revision,
    required this.input,
    this.objectId,
    this.value,
  });

  final String sceneId;

  /// Revision der Anfrage, die das Kind gesehen hat.
  final int revision;
  final LearningSceneInput input;
  final String? objectId;
  final int? value;
}

/// Die Engine-Seite einer Szene. Sie allein prüft und entscheidet.
abstract class LearningSceneDirector implements Listenable {
  String get sceneId;
  LearningSceneRequest get request;

  /// Wendet eine Handlung an. Gibt `false` zurück, wenn sie zur gezeigten
  /// Revision nicht passt oder gerade nicht erlaubt ist; dann ändert sich
  /// nichts.
  bool handle(LearningSceneEvent event);
}
