/// 2026-06-05 Iter 21: Rechentricks-Mentoren-System.
///
/// 5 Mentor-Figuren (Emma, Max, Hanna, Tim, Mira) bringen Kindern
/// Rechen-Strategien bei - inspiriert vom Mildenberger Übungsheft
/// Mathematik 1 + 3. Jede Figur hat einen eigenen Strategie-Stil und
/// einen Catchphrase. Wird im Lernmodus bei schwierigen Aufgaben
/// oder bei mehreren Fehlversuchen eingeblendet.

import 'dart:math' as math;

enum RechentricksKind {
  /// Emma (K1): "Ich tausche die Zahlen!"
  /// Bei 2 + 6 statt vorne rechnen, hinten die kleinere addieren.
  swapNumbers,

  /// Max (K1): "Ich suche eine Nachbaraufgabe!"
  /// 5+4 ist fast 4+4. Erst die einfache Doppelaufgabe, dann +1.
  neighborTask,

  /// Hanna (K1): "Ich rechne die Umkehraufgabe zur Kontrolle!"
  /// 9-4=5 -> Kontrolle: 5+4=9 stimmt.
  inverseCheck,

  /// Tim (K1): "Ich rechne zuerst die kleine Aufgabe!"
  /// 12+4=16 zerlegt zu 2+4=6, dann 10+6=16.
  smallFirst,

  /// Mira (K1): "Ich rechne bis zur 10 und dann weiter!"
  /// 8+6: erst 8+2=10 (Zehnerübergang), dann 10+4=14.
  bridgeTen,

  /// Emma (K2/K3): "Ich rechne in Schritten!"
  /// 467+258 = 467+200 +50 +8 = 725.
  stepByStep,

  /// Max (K3): "Ich zerlege beide Zahlen!"
  /// 234+382 = (200+300)+(30+80)+(4+2) = 500+110+6 = 616.
  decomposeBoth,

  /// Hanna (K3): "Ich vereinfache die Aufgabe!"
  /// 325+197 = 322+200 = 522 (3 von 325 weg, 3 zu 197 dazu).
  simplify,
}

class RechentricksMentor {
  const RechentricksMentor({
    required this.kind,
    required this.name,
    required this.emoji,
    required this.catchphrase,
    required this.color,
  });

  final RechentricksKind kind;
  final String name;
  final String emoji;
  final String catchphrase;
  final int color; // RGB hex
}

const List<RechentricksMentor> kAllRechentricksMentors = <RechentricksMentor>[
  RechentricksMentor(
    kind: RechentricksKind.swapNumbers,
    name: 'Emma',
    emoji: '🧒',
    catchphrase: 'Ich tausche die Zahlen!',
    color: 0xFFEC4899,
  ),
  RechentricksMentor(
    kind: RechentricksKind.neighborTask,
    name: 'Max',
    emoji: '👦',
    catchphrase: 'Ich suche eine Nachbaraufgabe!',
    color: 0xFF60A5FA,
  ),
  RechentricksMentor(
    kind: RechentricksKind.inverseCheck,
    name: 'Hanna',
    emoji: '👧',
    catchphrase: 'Ich rechne die Umkehraufgabe zur Kontrolle!',
    color: 0xFFF59E0B,
  ),
  RechentricksMentor(
    kind: RechentricksKind.smallFirst,
    name: 'Tim',
    emoji: '🧑',
    catchphrase: 'Ich rechne zuerst die kleine Aufgabe!',
    color: 0xFF22C55E,
  ),
  RechentricksMentor(
    kind: RechentricksKind.bridgeTen,
    name: 'Mira',
    emoji: '👩',
    catchphrase: 'Ich rechne bis zur 10 und dann weiter!',
    color: 0xFFA855F7,
  ),
  RechentricksMentor(
    kind: RechentricksKind.stepByStep,
    name: 'Emma',
    emoji: '🧒',
    catchphrase: 'Ich rechne in Schritten!',
    color: 0xFFEC4899,
  ),
  RechentricksMentor(
    kind: RechentricksKind.decomposeBoth,
    name: 'Max',
    emoji: '👦',
    catchphrase: 'Ich zerlege beide Zahlen!',
    color: 0xFF60A5FA,
  ),
  RechentricksMentor(
    kind: RechentricksKind.simplify,
    name: 'Hanna',
    emoji: '👧',
    catchphrase: 'Ich vereinfache die Aufgabe!',
    color: 0xFFF59E0B,
  ),
];

class RechentricksExplanation {
  const RechentricksExplanation({
    required this.mentor,
    required this.taskText,
    required this.steps,
    required this.resultText,
  });

  final RechentricksMentor mentor;
  final String taskText;
  final List<String> steps;
  final String resultText;
}

/// Kernlogik: parst den Aufgaben-Prompt, waehlt den passenden Mentor
/// und generiert die Schritt-Erklaerung.
class LumoRechentricks {
  const LumoRechentricks();

  /// Liefert eine Rechentricks-Erklärung zur Aufgabe oder null,
  /// wenn die Aufgabe kein Rechentrick-Fall ist (z.B. Buchstabe, Form).
  RechentricksExplanation? explain({
    required String prompt,
    required String correctAnswer,
    required int grade,
  }) {
    final parsed = _parseTask(prompt);
    if (parsed == null) return null;
    final a = parsed.a;
    final b = parsed.b;
    final op = parsed.op;
    final answer = int.tryParse(correctAnswer.replaceAll(RegExp(r'[^0-9-]'), ''));
    if (answer == null) return null;

    // K3+ Profi-Tricks fuer dreistellige Zahlen.
    if (grade >= 3 && (a >= 100 || b >= 100)) {
      return _gradeThreeTrick(op, a, b, answer);
    }
    return _gradeOneTrick(op, a, b, answer);
  }

  RechentricksExplanation? _gradeOneTrick(String op, int a, int b, int answer) {
    if (op == '+') {
      // Mira: Zehnerübergang wenn a+b > 10 und a < 10 und b < 10
      if (a < 10 && b < 10 && a + b > 10) {
        final toTen = 10 - a;
        final rest = b - toTen;
        return RechentricksExplanation(
          mentor: _mentorOf(RechentricksKind.bridgeTen),
          taskText: '$a + $b = ?',
          steps: <String>[
            '$a + $toTen = 10',
            '10 + $rest = $answer',
          ],
          resultText: 'Also: $a + $b = $answer',
        );
      }
      // Emma: Tauschen wenn a < b (kommutativ)
      if (a < b && a <= 4) {
        return RechentricksExplanation(
          mentor: _mentorOf(RechentricksKind.swapNumbers),
          taskText: '$a + $b = ?',
          steps: <String>[
            'Vertausche: $b + $a = $answer',
            'So muss ich nur $a Schritte weiterzaehlen.',
          ],
          resultText: 'Antwort: $answer',
        );
      }
      // Tim: Kleine Aufgabe zuerst wenn a > 10 und b < 10
      if (a >= 10 && b < 10) {
        final aOnes = a % 10;
        final aTens = a - aOnes;
        return RechentricksExplanation(
          mentor: _mentorOf(RechentricksKind.smallFirst),
          taskText: '$a + $b = ?',
          steps: <String>[
            '$aOnes + $b = ${aOnes + b}',
            '$aTens + ${aOnes + b} = $answer',
          ],
          resultText: 'Antwort: $answer',
        );
      }
      // Max: Nachbar (a+a = Doppel)
      if ((a - b).abs() == 1 && a < 10 && b < 10) {
        final doubl = a == b - 1 ? a * 2 : b * 2;
        return RechentricksExplanation(
          mentor: _mentorOf(RechentricksKind.neighborTask),
          taskText: '$a + $b = ?',
          steps: <String>[
            'Doppelaufgabe: ${a < b ? a : b} + ${a < b ? a : b} = $doubl',
            '$doubl + 1 = $answer',
          ],
          resultText: 'Antwort: $answer',
        );
      }
    }
    if (op == '-') {
      // Hanna: Umkehraufgabe zur Kontrolle
      return RechentricksExplanation(
        mentor: _mentorOf(RechentricksKind.inverseCheck),
        taskText: '$a - $b = ?',
        steps: <String>[
          '$a - $b = $answer',
          'Kontrolle: $answer + $b = $a ✓',
        ],
        resultText: 'Stimmt: $answer',
      );
    }
    return null;
  }

  RechentricksExplanation? _gradeThreeTrick(String op, int a, int b, int answer) {
    if (op == '+') {
      // Hanna: Vereinfachen wenn b nah an einer runden Zahl
      final bToRound = _distanceToRound(b);
      if (bToRound != null && bToRound.abs() <= 5) {
        final newB = b + bToRound;
        final newA = a - bToRound;
        return RechentricksExplanation(
          mentor: _mentorOf(RechentricksKind.simplify),
          taskText: '$a + $b = ?',
          steps: <String>[
            'Vereinfachen: ${bToRound > 0 ? '+$bToRound' : '$bToRound'} zu $b und ${-bToRound > 0 ? '+${-bToRound}' : '${-bToRound}'} zu $a',
            '$newA + $newB = $answer',
          ],
          resultText: 'Antwort: $answer',
        );
      }
      // Max: Zerlegen beider Zahlen
      final aHundreds = (a ~/ 100) * 100;
      final aRest = a - aHundreds;
      final bHundreds = (b ~/ 100) * 100;
      final bRest = b - bHundreds;
      if (aHundreds > 0 && bHundreds > 0) {
        return RechentricksExplanation(
          mentor: _mentorOf(RechentricksKind.decomposeBoth),
          taskText: '$a + $b = ?',
          steps: <String>[
            'Hunderter: $aHundreds + $bHundreds = ${aHundreds + bHundreds}',
            'Rest: $aRest + $bRest = ${aRest + bRest}',
            'Zusammen: ${aHundreds + bHundreds} + ${aRest + bRest} = $answer',
          ],
          resultText: 'Antwort: $answer',
        );
      }
      // Emma: In Schritten
      final bHundredsPart = (b ~/ 100) * 100;
      final bTensPart = ((b - bHundredsPart) ~/ 10) * 10;
      final bOnesPart = b - bHundredsPart - bTensPart;
      final step1 = a + bHundredsPart;
      final step2 = step1 + bTensPart;
      return RechentricksExplanation(
        mentor: _mentorOf(RechentricksKind.stepByStep),
        taskText: '$a + $b = ?',
        steps: <String>[
          '$a + $bHundredsPart = $step1',
          '$step1 + $bTensPart = $step2',
          '$step2 + $bOnesPart = $answer',
        ],
        resultText: 'Antwort: $answer',
      );
    }
    if (op == '-') {
      final bHundredsPart = (b ~/ 100) * 100;
      final bTensPart = ((b - bHundredsPart) ~/ 10) * 10;
      final bOnesPart = b - bHundredsPart - bTensPart;
      final step1 = a - bHundredsPart;
      final step2 = step1 - bTensPart;
      return RechentricksExplanation(
        mentor: _mentorOf(RechentricksKind.stepByStep),
        taskText: '$a - $b = ?',
        steps: <String>[
          '$a - $bHundredsPart = $step1',
          '$step1 - $bTensPart = $step2',
          '$step2 - $bOnesPart = $answer',
        ],
        resultText: 'Antwort: $answer',
      );
    }
    return null;
  }

  RechentricksMentor _mentorOf(RechentricksKind kind) {
    return kAllRechentricksMentors.firstWhere((m) => m.kind == kind);
  }

  /// Distanz zu naechster runden Zahl (10er-Schritt), Wertebereich -5..+5.
  int? _distanceToRound(int n) {
    final mod = n % 10;
    if (mod == 0) return null;
    return mod <= 5 ? -mod : 10 - mod;
  }

  _ParsedTask? _parseTask(String prompt) {
    final m = RegExp(r'(\d+)\s*([+\-])\s*(\d+)').firstMatch(prompt);
    if (m == null) return null;
    return _ParsedTask(
      a: int.parse(m.group(1)!),
      op: m.group(2)!,
      b: int.parse(m.group(3)!),
    );
  }
}

class _ParsedTask {
  const _ParsedTask({required this.a, required this.op, required this.b});
  final int a;
  final String op;
  final int b;
}

/// Zeigt eine kurze Statistik-Beschreibung an, welcher Mentor wofür
/// zustaendig ist. Fuer die Akademie-Uebersicht.
const Map<RechentricksKind, String> kRechentricksDescription =
    <RechentricksKind, String>{
  RechentricksKind.swapNumbers:
      'Wenn die zweite Zahl groesser ist, kannst du sie vertauschen. '
          'Dann musst du weniger weiterzaehlen.',
  RechentricksKind.neighborTask:
      'Suche eine aehnliche Aufgabe die du schon kannst. Dann nur '
          '+1 oder -1.',
  RechentricksKind.inverseCheck:
      'Nach dem Minus-Rechnen: Plus zurueck und du siehst ob es stimmt.',
  RechentricksKind.smallFirst:
      'Zerlege die grosse Zahl in Zehner und Einer. Erst die '
          'einfache kleine Rechnung, dann den Zehner dazu.',
  RechentricksKind.bridgeTen:
      'Wenn die Antwort ueber 10 geht: Erst bis zur 10 rechnen, '
          'dann den Rest dazu.',
  RechentricksKind.stepByStep:
      'Bei grossen Zahlen: Hunderter, dann Zehner, dann Einer - '
          'Schritt fuer Schritt.',
  RechentricksKind.decomposeBoth:
      'Beide Zahlen in Hunderter, Zehner und Einer zerlegen, dann '
          'gleiche Teile zusammenrechnen.',
  RechentricksKind.simplify:
      'Verschiebe ein paar Einer von der einen zur anderen Zahl - '
          'so wird eine runde Zahl draus.',
};
