import '../../core/discovery_progress.dart';
import 'tutoring_session_planner.dart';

/// Small reviewed local lessons inside the existing tutoring architecture.
/// No generated answer, provider request, new profile or second database.
enum GuidedMathConcept { bridgeTen, equalGroups }

enum GuidedAnswerKind {
  count,
  gapToTen,
  remainder,
  sum,
  groups,
  repeatedAddition
}

class GuidedLessonStep {
  const GuidedLessonStep({
    required this.type,
    required this.title,
    required this.instruction,
    this.a = 0,
    this.b = 0,
    this.answerKind,
    this.observation,
  });

  final TutoringStepType type;
  final String title;
  final String instruction;
  final int a;
  final int b;
  final GuidedAnswerKind? answerKind;
  final DiscoveryStepKind? observation;

  bool get isQuestion => answerKind != null;
  bool get isIndependent =>
      observation == DiscoveryStepKind.independent ||
      observation == DiscoveryStepKind.check;

  /// Arithmetic and the required representation are checked deterministically.
  /// Never publish this value in the companion's remote/visible task context.
  String get expected => switch (answerKind) {
        GuidedAnswerKind.count => '$a',
        GuidedAnswerKind.gapToTen => '${10 - a}',
        GuidedAnswerKind.remainder => '${b - (10 - a)}',
        GuidedAnswerKind.sum => '${a + b}',
        GuidedAnswerKind.groups => '${a * b}',
        GuidedAnswerKind.repeatedAddition => List.filled(a, '$b').join(' + '),
        null => throw StateError('This step has no answer'),
      };

  List<String> get choices {
    if (answerKind == GuidedAnswerKind.repeatedAddition) {
      return ['$a + $b', expected, List.filled(a + 1, '$b').join(' + ')];
    }
    final number = int.parse(expected);
    return [
      '${(number - 1).clamp(0, 100)}',
      expected,
      '${number + 2}',
      '${number + 1}',
    ];
  }

  bool accepts(String value) => isQuestion && value == expected;

  String help({required int level}) {
    if (answerKind == GuidedAnswerKind.count) {
      return level < 2
          ? 'Tippe gedanklich auf jeden Apfel. Zähle ihn nur einmal.'
          : 'Zähle langsam von links nach rechts. Beginne bei eins.';
    }
    if (answerKind == GuidedAnswerKind.gapToTen) {
      return level < 2
          ? 'Schau auf die freien Plätze im Zehnerfeld. '
              'Wie viele fehlen von $a bis zehn?'
          : 'Beginne bei $a und zähle bis zehn weiter. '
              'Für jeden Zählschritt hebst du einen Finger.';
    }
    if (answerKind == GuidedAnswerKind.remainder) {
      return level < 2
          ? 'Von den $b Äpfeln füllt zuerst ein Teil den Zehner. '
              'Wie viele bleiben danach in der zweiten Gruppe?'
          : 'Der Zehner ist jetzt voll. Schau nur auf die Äpfel daneben '
              'und zähle sie von links nach rechts.';
    }
    if (answerKind == GuidedAnswerKind.repeatedAddition) {
      return level < 2
          ? 'Für jede Gruppe schreibst du einmal $b. '
              'Verbinde diese Zahlen mit Pluszeichen.'
          : 'Vergleiche die Gruppen mit den Teilen der Plusrechnung: '
              'eine gleiche Zahl für jede Gruppe, nicht eine Zahl für '
              'die Anzahl der Gruppen.';
    }
    if (answerKind == GuidedAnswerKind.groups) {
      return level < 2
          ? 'In jeder Gruppe liegen gleich viele Äpfel. '
              'Zähle alle Gruppen zusammen.'
          : 'Beginne mit einer Gruppe. Zähle dann immer $b weiter. '
              'Du kannst auch gleiche Pluszahlen verwenden.';
    }
    return level < 2
        ? 'Fülle zuerst den Zehner. Zähle danach die übrigen Äpfel dazu.'
        : 'Von $a bis zehn fehlen ${10 - a}. '
            'Nimm diesen Teil von den $b. Was bleibt noch übrig?';
  }
}

class GuidedLesson {
  const GuidedLesson({
    required this.id,
    required this.title,
    required this.description,
    required this.grade,
    required this.schoolUnit,
    required this.concept,
    required this.steps,
  });

  final String id;
  final String title;
  final String description;
  final int grade;
  final String schoolUnit;
  final GuidedMathConcept concept;
  final List<GuidedLessonStep> steps;

  DiscoveryLearningTarget get discoveryTarget =>
      DiscoveryLearningTarget(topicId: id, grade: grade);

  GuidedLessonStep get easierPractice => GuidedLessonStep(
        type: TutoringStepType.guidedTask,
        title: 'Ein kleiner Schritt',
        instruction: 'Zähle diese Äpfel in Ruhe. Danach kannst du zurück.',
        a: 3,
        answerKind: GuidedAnswerKind.count,
        observation: DiscoveryStepKind.foundation,
      );
}

abstract final class GuidedLessonCatalog {
  static const bridgeTen = GuidedLesson(
    id: 'bridge_ten',
    title: 'Über den Zehner',
    description: 'Erst den Zehner füllen, dann weiterrechnen.',
    grade: 1,
    schoolUnit: 'Plus bis 20',
    concept: GuidedMathConcept.bridgeTen,
    steps: [
      GuidedLessonStep(
        type: TutoringStepType.greeting,
        title: 'Lumo erklärt es mir',
        instruction: 'Heute lernen wir einen Rechentrick: '
            'Wir füllen zuerst den Zehner. Du kannst dir Zeit lassen.',
      ),
      GuidedLessonStep(
        type: TutoringStepType.guidedTask,
        title: 'Was kannst du schon?',
        instruction: 'Zähle die Äpfel. Wie viele sind es?',
        a: 6,
        answerKind: GuidedAnswerKind.count,
        observation: DiscoveryStepKind.foundation,
      ),
      GuidedLessonStep(
        type: TutoringStepType.showExample,
        title: 'Sieben und fünf',
        instruction: 'Sieben Äpfel sind schon da. Von den fünf neuen '
            'nehmen wir drei. Sieben plus drei ist zehn. '
            'Dann bleiben zwei. Zehn plus zwei ist zwölf.',
        a: 7,
        b: 5,
      ),
      GuidedLessonStep(
        type: TutoringStepType.guidedTask,
        title: 'Gemeinsam zum Zehner',
        instruction: 'Neun plus vier: Wie viele fehlen von neun bis zehn?',
        a: 9,
        b: 4,
        answerKind: GuidedAnswerKind.gapToTen,
        observation: DiscoveryStepKind.guided,
      ),
      GuidedLessonStep(
        type: TutoringStepType.guidedTask,
        title: 'Was bleibt übrig?',
        instruction: 'Eine von den vier füllt den Zehner. '
            'Wie viele von den vier bleiben dann noch?',
        a: 9,
        b: 4,
        answerKind: GuidedAnswerKind.remainder,
        observation: DiscoveryStepKind.guided,
      ),
      GuidedLessonStep(
        type: TutoringStepType.independentTask,
        title: 'Jetzt probierst du',
        instruction: 'Acht plus sechs. Wie viel ist das zusammen?',
        a: 8,
        b: 6,
        answerKind: GuidedAnswerKind.sum,
        observation: DiscoveryStepKind.independent,
      ),
      GuidedLessonStep(
        type: TutoringStepType.independentTask,
        title: 'Ein neues Beispiel',
        instruction: 'Sechs plus fünf. Welche Antwort passt?',
        a: 6,
        b: 5,
        answerKind: GuidedAnswerKind.sum,
        observation: DiscoveryStepKind.check,
      ),
      GuidedLessonStep(
        type: TutoringStepType.recap,
        title: 'Du hast selbst gerechnet',
        instruction: 'Du hast den Zehner mit einem Beispiel kennengelernt '
            'und neue Aufgaben ausprobiert. '
            'Wenn du magst, üben wir später noch einmal.',
      ),
    ],
  );

  static const equalGroups = GuidedLesson(
    id: 'equal_groups',
    title: 'Das Einmaleins entdecken',
    description: 'Gleiche Gruppen zählen und als Plusrechnung verstehen.',
    grade: 2,
    schoolUnit: 'Kleines 1×1',
    concept: GuidedMathConcept.equalGroups,
    steps: [
      GuidedLessonStep(
        type: TutoringStepType.greeting,
        title: 'Neue Dinge entdecken',
        instruction: 'Super! Ich zeige dir, wie man mit gleichen Gruppen '
            'rechnen kann. Zuerst zählen wir gemeinsam.',
      ),
      GuidedLessonStep(
        type: TutoringStepType.guidedTask,
        title: 'Zählen als Grundlage',
        instruction: 'Wie viele Äpfel siehst du hier?',
        a: 4,
        answerKind: GuidedAnswerKind.count,
        observation: DiscoveryStepKind.foundation,
      ),
      GuidedLessonStep(
        type: TutoringStepType.showExample,
        title: 'Drei gleiche Gruppen',
        instruction: 'Hier sind drei Gruppen. In jeder Gruppe liegen zwei '
            'Äpfel. Zwei plus zwei plus zwei ist sechs. '
            'Dazu können wir auch sagen: drei mal zwei.',
        a: 3,
        b: 2,
      ),
      GuidedLessonStep(
        type: TutoringStepType.guidedTask,
        title: 'Wir zählen zusammen',
        instruction: 'Zwei Gruppen mit je drei Äpfeln. '
            'Wie viele Äpfel sind es zusammen?',
        a: 2,
        b: 3,
        answerKind: GuidedAnswerKind.groups,
        observation: DiscoveryStepKind.guided,
      ),
      GuidedLessonStep(
        type: TutoringStepType.independentTask,
        title: 'Deine Gruppenaufgabe',
        instruction: 'Vier Gruppen mit je zwei Äpfeln. '
            'Wie viele sind es zusammen?',
        a: 4,
        b: 2,
        answerKind: GuidedAnswerKind.groups,
        observation: DiscoveryStepKind.independent,
      ),
      GuidedLessonStep(
        type: TutoringStepType.independentTask,
        title: 'Verstehst du die Gruppen?',
        instruction: 'Drei Gruppen mit je drei Äpfeln: '
            'Welche Plusrechnung beschreibt die Gruppen?',
        a: 3,
        b: 3,
        answerKind: GuidedAnswerKind.repeatedAddition,
        observation: DiscoveryStepKind.check,
      ),
      GuidedLessonStep(
        type: TutoringStepType.recap,
        title: 'Ein neues Prinzip entdeckt',
        instruction: 'Du hast gleiche Gruppen gezählt und als Plusrechnung '
            'beschrieben. So beginnt das Einmaleins. '
            'Deine eingestellte Schulklasse bleibt unverändert.',
      ),
    ],
  );

  static const all = [bridgeTen, equalGroups];

  /// Map only explicit, compatible mathematical topics to actual introductions.
  /// A German/science recommendation must never silently become a maths lesson.
  static GuidedLesson? schoolIntroduction({
    required String subject,
    required String unit,
    required int grade,
  }) {
    if (subject != 'Mathematik') return null;
    final lesson = switch (unit) {
      'Plus bis 20' => bridgeTen,
      'Einmaleins' || 'Kleines 1×1' => equalGroups,
      _ => null,
    };
    return lesson != null && lesson.grade <= grade ? lesson : null;
  }
}
