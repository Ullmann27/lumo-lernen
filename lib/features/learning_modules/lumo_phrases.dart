// ════════════════════════════════════════════════════════════════════════
// LUMO PHRASE LIBRARY — konsistente Persoenlichkeit fuer Lumo
// ════════════════════════════════════════════════════════════════════════
// Heinz-Auftrag Punkt 21: Lumo soll eine einheitliche Persoenlichkeit haben.
// - Lumo sagt nicht 'Das ist falsch', 'Du hast verloren'.
// - Lumo sagt 'Fast', 'Ich helfe dir', 'Wir schaffen das'.
// - Variierte Lobsprueche damit es nicht langweilig wird.
//
// Diese Library wird von ALLEN Lern-Modulen verwendet damit Lumo ueberall
// gleich klingt.
// ════════════════════════════════════════════════════════════════════════

import 'dart:math' as math;

class LumoPhrases {
  LumoPhrases._();
  static final _rng = math.Random();

  /// Lob bei richtiger Antwort - variiert, nie gleich.
  static String correct() => _pick(_correctPhrases);

  /// Sanftes Feedback bei falscher Antwort - nie hart.
  static String wrongGentle() => _pick(_wrongGentlePhrases);

  /// Hilfreicher Tipp ohne Hilfe-Stigma.
  static String hint() => _pick(_hintPhrases);

  /// Beim Modul-Start.
  static String greeting() => _pick(_greetingPhrases);

  /// Beim Modul-Ende (Erfolg).
  static String celebrate() => _pick(_celebratePhrases);

  /// Bei Schwierigkeit / wiederholter Fehler.
  static String comfort() => _pick(_comfortPhrases);

  static String _pick(List<String> list) =>
      list[_rng.nextInt(list.length)];

  // ── Lobsprueche (correct) ──
  static const _correctPhrases = [
    'Super!',
    'Toll gemacht!',
    'Genau richtig!',
    'Wow, du bist gut!',
    'Bravo!',
    'Klasse!',
    'Stark!',
    'Genial!',
    'Perfekt!',
    'Wahnsinn, weiter so!',
    'Ich bin stolz auf dich!',
    'Voll richtig!',
  ];

  // ── Sanftes Falsch-Feedback (NIE hart!) ──
  static const _wrongGentlePhrases = [
    'Fast! Schau nochmal.',
    'Knapp daneben, versuchen wir es nochmal!',
    'Hmm, nochmal probieren?',
    'Das war fast richtig. Probier nochmal!',
    'Kein Problem, wir schaffen das zusammen.',
    'Nicht ganz - aber du bist nah dran!',
    'Schau noch einmal genau hin.',
  ];

  // ── Hinweise / Tipps ──
  static const _hintPhrases = [
    'Hier ist ein kleiner Tipp:',
    'Lass mich dir helfen:',
    'Schau mal so:',
    'Probier es so:',
    'Tipp:',
  ];

  // ── Begruessung beim Modul-Start ──
  static const _greetingPhrases = [
    'Hi! Lass uns gemeinsam üben!',
    'Hallo! Heute lernen wir etwas Tolles.',
    'Schön dich zu sehen! Bereit?',
    'Komm, wir machen das zusammen!',
    'Auf gehts! Du schaffst das.',
  ];

  // ── Abschluss-Feiern ──
  static const _celebratePhrases = [
    'Mega! Du hast es geschafft!',
    'Wow, was für eine Leistung!',
    'Du bist ein Lern-Profi!',
    'Hammer! Geht doch!',
    'Spitze, weiter so!',
  ];

  // ── Trost bei Schwierigkeit ──
  static const _comfortPhrases = [
    'Kein Problem - jeder fängt mal an.',
    'Das war schwierig. Versuchen wir es einfacher.',
    'Wir lernen zusammen. Kein Stress.',
    'Du wirst das bald können!',
    'Ruhig - wir machen einen kleinen Schritt.',
  ];
}
