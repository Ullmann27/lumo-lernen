# Lumo: persönliches Lerngehirn, Meilenstein 2001

Auftrag: selbstständig entwickeln und auf GitHub sichern. Basis ist PR #413,
`a79ff08ccc20c92943969e0f1ebf2226e78a4bca`, einschließlich #412 und #411.
Die Build-2000-Gates laufen am unveränderten `a6558161`; kein Merge nach main.

## Architekturentscheidung
Die vorhandenen lokalen Engines bleiben bestehen. Eine deterministische
TutorCoordinationEngine steuert Aufgabenkontext, freiwillige Angebote,
Methodenwechsel und Verständnisereignisse über CompanionRequests. Das vorhandene
LearningJourney speichert zusätzliche Evidenz im bestehenden Profilnamespace.
Kein Cloudzwang, keine zweite Profildatenbank, keine neuen Pakete.
Alternative: unabhängige Zustände je Karte würden das bestehende Problem
fortsetzen. Eine neue KI-Orchestrierung wäre offline ungeeignet.

## Verbindliches Verhalten
- Profile werden durch Generation und echte Aufgabenidentität abgegrenzt;
  verspätete Ereignisse früherer Profile dürfen den neuen Tutor nicht verändern.
- Zwei Fehler erlauben eine Einladung. Zustimmung und Ablehnung gelten bis zur
  nächsten Aufgabe; fachliche Hilfe erscheint erst nach ausdrücklichem Wunsch.
- Tests und Schularbeiten sperren fachliche Hilfe und Werkstatt vollständig.
- Jede tatsächlich verwendete Hilfe bleibt für die Aufgabe vermerkt.
  Die Lösung nach Hilfe ist keine selbstständige Lösung.
- Zehner-Werkstatt: zählen, bündeln, zerlegen; dann andere Zahl konstruieren und
  Verständnisfrage beantworten. Nur eine selbstständige neue Aufgabe darf
  zusätzliche Transferevidenz liefern. Keine zusätzlichen Sterne/XP.
- Original-Lumo, dunkelblaues Hologlas, mindestens 48dp aktive Ziele, keine
  verdeckenden Overlays, responsive Gestaltung und Reduce Motion.
- Tagesplan berücksichtigt vorhandene Kompetenzdaten UND konkrete
  Journey-Evidenz. Keine erfundenen Stärken; einzelne Fehler sind keine Diagnose.
- Sprache bleibt auf bestehendem geprüften Einwilligungs-/Offlinepfad.
  Ohne Zielgerätbeleg wird lokale Spracherkennung nicht als verfügbar behauptet.

## Prüfung und Auslieferung
Tests für zentrale Regeln, Profilwechsel, Exams, asynchrone Speicherung,
Werkstatt-Transfer und reale Navigation. Vollständige Flutter-Suite und Analyse;
echte gerenderte Flutter-Screenshots für kleine/Fold-/Großschriftansichten.
Klassen-/Modulaudit dokumentiert Anschlüsse und verbleibende Lücken.
Neue Haupt-App ausschließlich als Build 2001 oder höher mit bestehenden
Signatur-/Datenerhaltungs-/APK-Gates; keine Freigabe ohne deren Belege.
