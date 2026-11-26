import 'package:lumo_lernen/domain/school/attempt.dart';

/// Testantworten eines Testkindes (keine Beispielzahlen in der App).
/// [tage] zurück liegt um 12 Uhr Ortszeit, heute eine Minute vor jetzt:
/// unabhängig von Uhrzeit und Sommerzeit am Testtag.
Attempt antwort(String kind, String id, String subject, String unit,
    String competency, bool ok, int tage,
    {bool hilfe = false}) {
  final now = DateTime.now();
  return Attempt(
    id: '$kind-$id',
    studentId: kind,
    subject: subject,
    unit: unit,
    competency: competency,
    correct: ok,
    hintUsed: hilfe,
    durationMs: 9000,
    at: tage == 0
        ? now.subtract(const Duration(minutes: 1))
        : DateTime(now.year, now.month, now.day - tage, 12),
  );
}

/// Die 36 Antworten aus Heinz' Befund (33 ohne Hilfe, 3 mit Hilfe),
/// verteilt auf die letzten drei Wochen, keine davon heute.
List<Attempt> sechsunddreissigAntworten(String kind) => [
      for (var i = 0; i < 12; i++)
        antwort(kind, 'p$i', 'Mathematik', 'Plus bis 20',
            'Addition ohne Zehnerübergang', i != 3, 1 + i % 5),
      for (var i = 0; i < 7; i++)
        antwort(kind, 'm$i', 'Mathematik', 'Minus bis 100',
            'Subtraktion mit Zehnerübergang', i == 2 || i == 5, 1 + i % 3),
      for (var i = 0; i < 3; i++)
        antwort(kind, 'mh$i', 'Mathematik', 'Minus bis 100',
            'Subtraktion mit Zehnerübergang', true, 2,
            hilfe: true),
      for (var i = 0; i < 8; i++)
        antwort(kind, 'e$i', 'Mathematik', 'Einmaleins', 'Einmaleins', i >= 3,
            20 - i * 2),
      for (var i = 0; i < 6; i++)
        antwort(kind, 's$i', 'Deutsch', 'Silben', 'Silben', i != 1, 3 + i),
    ];
