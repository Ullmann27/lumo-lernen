import '../../core/discovery_progress.dart';
import 'tutoring_session_planner.dart';

/// Small reviewed local lessons inside the existing tutoring architecture.
/// No generated answer, provider request, new profile or second database.
enum GuidedLessonConcept {
  bridgeTen,
  equalGroups,
  subtractTen,
  syllables,
  plantParts
}

enum GuidedPlantPart {
  root('Wurzel'),
  stem('Stängel'),
  leaf('Blatt'),
  flower('Blüte');

  const GuidedPlantPart(this.label);
  final String label;
}

enum GuidedAnswerKind {
  count,
  gapToTen,
  remainder,
  sum,
  groups,
  repeatedAddition,
  toPreviousTen,
  subtractRemainder,
  difference,
  syllableCount,
  plantPart,
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
    this.word = '',
    this.syllables = const [],
    this.plantPart,
    this.plantVariant = 0,
  });

  final TutoringStepType type;
  final String title;
  final String instruction;
  final int a;
  final int b;
  final GuidedAnswerKind? answerKind;
  final DiscoveryStepKind? observation;
  final String word;
  final List<String> syllables;
  final GuidedPlantPart? plantPart;
  final int plantVariant;

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
        GuidedAnswerKind.toPreviousTen => '${a % 10}',
        GuidedAnswerKind.subtractRemainder => '${b - a % 10}',
        GuidedAnswerKind.difference => '${a - b}',
        GuidedAnswerKind.syllableCount => '${syllables.length}',
        GuidedAnswerKind.plantPart => plantPart!.label,
        null => throw StateError('This step has no answer'),
      };

  List<String> get choices {
    if (answerKind == GuidedAnswerKind.plantPart) {
      return GuidedPlantPart.values.map((part) => part.label).toList();
    }
    if (answerKind == GuidedAnswerKind.repeatedAddition) {
      return ['$a + $b', expected, List.filled(a + 1, '$b').join(' + ')];
    }
    final number = int.parse(expected);
    final values = <String>{
      '${(number - 1).clamp(0, 100)}',
      expected,
      '${number + 2}',
      '${number + 1}',
    };
    // Zero is a valid answer, but must appear only once.
    for (var next = number + 3; values.length < 4; next++) {
      values.add('$next');
    }
    return values.toList();
  }

  bool accepts(String value) => isQuestion && value == expected;

  String help({required int level}) {
    if (answerKind == GuidedAnswerKind.syllableCount) {
      return level < 2
          ? 'Sprich „$word“ langsam. Klatsche bei jedem Sprechstück einmal. '
              'Zähle deine Klatscher, nicht die Buchstaben.'
          : 'Wir probieren es anders: Sprich ${syllables.join(" – ")}. '
              'Lege für jedes Sprechstück einen Finger auf den Tisch.';
    }
    if (answerKind == GuidedAnswerKind.plantPart) {
      return switch ((plantPart!, level < 2)) {
        (GuidedPlantPart.root, true) =>
          'Schau unter die Erde. Dieser Teil hält die Pflanze fest und nimmt Wasser auf.',
        (GuidedPlantPart.root, false) =>
          'Stell dir vor, du gießt die Erde. Welcher Pflanzenteil berührt dort das Wasser?',
        (GuidedPlantPart.stem, true) =>
          'Suche die Verbindung zwischen der Erde, den Blättern und der Blüte.',
        (GuidedPlantPart.stem, false) =>
          'Dieser Teil trägt die Pflanze. Durch ihn wird Wasser nach oben transportiert.',
        (GuidedPlantPart.leaf, true) =>
          'Suche die grünen Flächen, die seitlich wachsen. Sie nutzen das Licht.',
        (GuidedPlantPart.leaf, false) =>
          'Mit Licht stellt die Pflanze dort eigene Nahrung her. Suche seitlich am Stängel.',
        (GuidedPlantPart.flower, true) =>
          'Suche den bunten Teil oben. Bei vielen Pflanzen entstehen dort später Früchte mit Samen.',
        (GuidedPlantPart.flower, false) =>
          'Stell dir eine Blütenpflanze vor, die Bienen besuchen. Welchen bunten Teil besuchen sie?',
      };
    }
    if (answerKind == GuidedAnswerKind.toPreviousTen) {
      return level < 2
          ? 'Zähle von $a rückwärts bis zehn. Wie viele Schritte brauchst du?'
          : 'Lass zehn Äpfel liegen. Wie viele liegen über diesen zehn?';
    }
    if (answerKind == GuidedAnswerKind.subtractRemainder) {
      return level < 2
          ? 'Insgesamt nehmen wir $b weg. ${a % 10} sind schon weg. '
              'Wie viele fehlen noch?'
          : 'Stell dir $b Finger vor. Klappe ${a % 10} ein. '
              'Die übrigen Finger zeigen den zweiten Schritt.';
    }
    if (answerKind == GuidedAnswerKind.difference) {
      return level < 2
          ? 'Nimm zuerst ${a % 10} weg, bis zehn bleiben. '
              'Nimm dann die übrigen ${b - a % 10} weg. Wo landest du?'
          : 'Zähle von $a genau $b Schritte rückwärts. '
              'Prüfe danach: Deine Antwort plus $b muss wieder $a sein.';
    }
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
    this.subject = 'Mathematik',
  });

  final String id;
  final String title;
  final String description;
  final int grade;
  final String schoolUnit;
  final String subject;
  final GuidedLessonConcept concept;
  final List<GuidedLessonStep> steps;

  DiscoveryLearningTarget get discoveryTarget =>
      DiscoveryLearningTarget(topicId: id, grade: grade);

  GuidedLessonStep get easierPractice => switch (concept) {
        GuidedLessonConcept.syllables => const GuidedLessonStep(
            type: TutoringStepType.guidedTask,
            title: 'Ein kurzes Wort',
            instruction: 'Sprich Mama. Wie oft klatschst du?',
            word: 'Mama',
            syllables: ['Ma', 'ma'],
            answerKind: GuidedAnswerKind.syllableCount,
            observation: DiscoveryStepKind.foundation),
        GuidedLessonConcept.plantParts => const GuidedLessonStep(
            type: TutoringStepType.guidedTask,
            title: 'Unter der Erde',
            instruction: 'Welcher Teil nimmt Wasser aus der Erde auf?',
            plantPart: GuidedPlantPart.root,
            answerKind: GuidedAnswerKind.plantPart,
            observation: DiscoveryStepKind.foundation),
        _ => const GuidedLessonStep(
            type: TutoringStepType.guidedTask,
            title: 'Ein kleiner Schritt',
            instruction: 'Zähle diese Äpfel in Ruhe. Danach kannst du zurück.',
            a: 3,
            answerKind: GuidedAnswerKind.count,
            observation: DiscoveryStepKind.foundation,
          ),
      };
}

abstract final class GuidedLessonCatalog {
  static const bridgeTen = GuidedLesson(
    id: 'bridge_ten',
    title: 'Über den Zehner',
    description: 'Erst den Zehner füllen, dann weiterrechnen.',
    grade: 1,
    schoolUnit: 'Plus bis 20',
    concept: GuidedLessonConcept.bridgeTen,
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
    concept: GuidedLessonConcept.equalGroups,
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

  static const subtractTen = GuidedLesson(
    id: 'subtract_ten',
    title: 'Minus über den Zehner',
    description: 'Erst bis zehn zurück, dann den Rest wegnehmen.',
    grade: 1,
    schoolUnit: 'Minus bis 20',
    concept: GuidedLessonConcept.subtractTen,
    steps: [
      GuidedLessonStep(
        type: TutoringStepType.greeting,
        title: 'Mit Lumo zurückrechnen',
        instruction: 'Bei Minus nehmen wir etwas weg. Heute gehen wir '
            'zuerst bis zehn zurück und dann noch ein Stück weiter.',
      ),
      GuidedLessonStep(
        type: TutoringStepType.guidedTask,
        title: 'Unsere Startmenge',
        instruction: 'Zähle die Äpfel. Wie viele sind am Anfang da?',
        a: 12,
        answerKind: GuidedAnswerKind.count,
        observation: DiscoveryStepKind.foundation,
      ),
      GuidedLessonStep(
        type: TutoringStepType.showExample,
        title: 'Zwölf minus fünf',
        instruction: 'Von zwölf nehmen wir zuerst zwei weg. Dann bleiben '
            'zehn. Von den fünf fehlen noch drei. Wir nehmen drei weitere '
            'weg. Jetzt bleiben sieben. Zwei und drei zusammen sind fünf.',
        a: 12,
        b: 5,
      ),
      GuidedLessonStep(
        type: TutoringStepType.guidedTask,
        title: 'Gemeinsam zurück bis zehn',
        instruction: 'Dreizehn minus sechs: Wie viele nehmen wir zuerst '
            'weg, damit zehn bleiben?',
        a: 13,
        b: 6,
        answerKind: GuidedAnswerKind.toPreviousTen,
        observation: DiscoveryStepKind.guided,
      ),
      GuidedLessonStep(
        type: TutoringStepType.guidedTask,
        title: 'Noch ein Stück zurück',
        instruction: 'Drei Äpfel sind schon weg. Insgesamt sollen sechs '
            'weg. Wie viele nehmen wir noch weg?',
        a: 13,
        b: 6,
        answerKind: GuidedAnswerKind.subtractRemainder,
        observation: DiscoveryStepKind.guided,
      ),
      GuidedLessonStep(
        type: TutoringStepType.independentTask,
        title: 'Du rechnest selbst zurück',
        instruction: 'Vierzehn minus acht. Wie viele bleiben?',
        a: 14,
        b: 8,
        answerKind: GuidedAnswerKind.difference,
        observation: DiscoveryStepKind.independent,
      ),
      GuidedLessonStep(
        type: TutoringStepType.independentTask,
        title: 'Dein neuer Minusversuch',
        instruction: 'Elf minus vier. Welche Antwort passt?',
        a: 11,
        b: 4,
        answerKind: GuidedAnswerKind.difference,
        observation: DiscoveryStepKind.check,
      ),
      GuidedLessonStep(
        type: TutoringStepType.recap,
        title: 'Du kannst in zwei Schritten rechnen',
        instruction: 'Du hast zuerst bis zehn zurückgerechnet und dann '
            'den Rest weggenommen. Mit Plus kannst du deine Minusrechnung '
            'prüfen. Wenn du magst, üben wir später weiter.',
      ),
    ],
  );

  static const syllables = GuidedLesson(
    id: 'syllables',
    title: 'Wörter in Silben hören',
    description:
        'Sprechstücke hören, mitklatschen und ein neues Wort selbst gliedern.',
    subject: 'Deutsch',
    schoolUnit: 'Silben',
    grade: 1,
    concept: GuidedLessonConcept.syllables,
    steps: [
      GuidedLessonStep(
          type: TutoringStepType.greeting,
          title: 'Wir hören genau hin',
          instruction:
              'Ein Wort besteht aus Sprechstücken. Diese heißen Silben. Wir sprechen langsam und klatschen mit.'),
      GuidedLessonStep(
          type: TutoringStepType.explain,
          title: 'Sprechen statt Buchstaben zählen',
          instruction:
              'Sprich Mama: Ma – ma. Klatsche bei jedem Sprechstück einmal. Buchstaben zählen wir dabei nicht.',
          word: 'Mama',
          syllables: ['Ma', 'ma'],
          observation: DiscoveryStepKind.foundation),
      GuidedLessonStep(
          type: TutoringStepType.showExample,
          title: 'Ba – na – ne',
          instruction:
              'Sprich Banane langsam: Ba – na – ne. Klatsche dreimal. Das Wort hat drei Silben.',
          word: 'Banane',
          syllables: ['Ba', 'na', 'ne']),
      GuidedLessonStep(
          type: TutoringStepType.guidedTask,
          title: 'Gemeinsam mitklatschen',
          instruction: 'Sprich Sonne langsam. Wie viele Silben hörst du?',
          word: 'Sonne',
          syllables: ['Son', 'ne'],
          answerKind: GuidedAnswerKind.syllableCount,
          observation: DiscoveryStepKind.guided),
      GuidedLessonStep(
          type: TutoringStepType.guidedTask,
          title: 'Noch ein Wort zusammen',
          instruction:
              'Sprich Tomate und klatsche mit. Wie viele Silben sind es?',
          word: 'Tomate',
          syllables: ['To', 'ma', 'te'],
          answerKind: GuidedAnswerKind.syllableCount,
          observation: DiscoveryStepKind.guided),
      GuidedLessonStep(
          type: TutoringStepType.independentTask,
          title: 'Ein neues Wort für dich',
          instruction: 'Sprich Blume. Wie viele Silben hörst du?',
          word: 'Blume',
          syllables: ['Blu', 'me'],
          answerKind: GuidedAnswerKind.syllableCount,
          observation: DiscoveryStepKind.independent),
      GuidedLessonStep(
          type: TutoringStepType.independentTask,
          title: 'Dein eigener Silbenversuch',
          instruction: 'Sprich Rakete langsam. Wie viele Silben sind es?',
          word: 'Rakete',
          syllables: ['Ra', 'ke', 'te'],
          answerKind: GuidedAnswerKind.syllableCount,
          observation: DiscoveryStepKind.check),
      GuidedLessonStep(
          type: TutoringStepType.recap,
          title: 'Du hast Silben gehört',
          instruction:
              'Du hast langsam gesprochen und mitgeklatscht. Jede Silbe ist ein Sprechstück. Du kannst das auch mit deinem Namen ausprobieren.'),
    ],
  );

  static const plantParts = GuidedLesson(
    id: 'flowering_plant_parts',
    title: 'Eine Blütenpflanze entdecken',
    description:
        'Wurzel, Stängel, Blatt und Blüte erkennen und ihre Aufgaben verstehen.',
    subject: 'Sachunterricht',
    schoolUnit: 'Pflanzen',
    grade: 1,
    concept: GuidedLessonConcept.plantParts,
    steps: [
      GuidedLessonStep(
          type: TutoringStepType.greeting,
          title: 'Was wächst da?',
          instruction:
              'Wir entdecken eine Blütenpflanze. Schau genau hin: Ein Teil wächst in der Erde, andere Teile darüber.'),
      GuidedLessonStep(
          type: TutoringStepType.explain,
          title: 'Von unten nach oben',
          instruction:
              'Die Wurzel hält die Pflanze fest und nimmt Wasser aus der Erde auf. Der Stängel trägt die Pflanze und transportiert Wasser nach oben.',
          observation: DiscoveryStepKind.foundation),
      GuidedLessonStep(
          type: TutoringStepType.showExample,
          title: 'Das Blatt nutzt Licht',
          instruction:
              'Der hervorgehobene Teil heißt Blatt. Mit Licht stellt die Pflanze dort eigene Nahrung her. Die Blüte ist oben. Bei vielen Blütenpflanzen entstehen dort später Früchte mit Samen.',
          plantPart: GuidedPlantPart.leaf),
      GuidedLessonStep(
          type: TutoringStepType.guidedTask,
          title: 'Gemeinsam unter die Erde schauen',
          instruction: 'Welcher Teil nimmt Wasser aus der Erde auf?',
          plantPart: GuidedPlantPart.root,
          answerKind: GuidedAnswerKind.plantPart,
          observation: DiscoveryStepKind.guided),
      GuidedLessonStep(
          type: TutoringStepType.guidedTask,
          title: 'Der Weg nach oben',
          instruction:
              'Welcher Teil trägt die Pflanze und transportiert Wasser nach oben?',
          plantPart: GuidedPlantPart.stem,
          answerKind: GuidedAnswerKind.plantPart,
          observation: DiscoveryStepKind.guided),
      GuidedLessonStep(
          type: TutoringStepType.independentTask,
          title: 'Du erkennst den Pflanzenteil',
          instruction: 'Welcher Teil ist im Bild hervorgehoben?',
          plantPart: GuidedPlantPart.flower,
          answerKind: GuidedAnswerKind.plantPart,
          observation: DiscoveryStepKind.independent),
      GuidedLessonStep(
          type: TutoringStepType.independentTask,
          title: 'Eine andere Blütenpflanze',
          instruction:
              'Diese Pflanze sieht anders aus. Wie heißt der hervorgehobene Teil?',
          plantPart: GuidedPlantPart.leaf,
          plantVariant: 1,
          answerKind: GuidedAnswerKind.plantPart,
          observation: DiscoveryStepKind.check),
      GuidedLessonStep(
          type: TutoringStepType.recap,
          title: 'Du kennst ihre Teile',
          instruction:
              'Wurzel, Stängel, Blatt und Blüte haben verschiedene Aufgaben. Entdecke diese Teile mit einer erwachsenen Person an einer echten Blütenpflanze. Unbekannte Pflanzen lassen wir stehen und essen sie nicht.'),
    ],
  );

  static const all = [
    bridgeTen,
    equalGroups,
    subtractTen,
    syllables,
    plantParts
  ];

  /// Map only explicit, compatible mathematical topics to actual introductions.
  /// A German/science recommendation must never silently become a maths lesson.
  static GuidedLesson? schoolIntroduction({
    required String subject,
    required String unit,
    required int grade,
  }) {
    final lesson = switch ((subject, unit)) {
      ('Mathematik', 'Plus bis 20') => bridgeTen,
      ('Mathematik', 'Minus bis 20') => subtractTen,
      ('Mathematik', 'Einmaleins' || 'Kleines 1×1') => equalGroups,
      ('Deutsch', 'Silben') => syllables,
      ('Sachunterricht', 'Pflanzen') => plantParts,
      _ => null,
    };
    return lesson != null && lesson.grade <= grade ? lesson : null;
  }
}
