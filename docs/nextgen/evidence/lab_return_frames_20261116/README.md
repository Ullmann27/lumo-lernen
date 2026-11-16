# Lab-Modell nur mit gültiger Aufgabenbindung anbieten

## Tatsächlicher Androidbefund

Die APK 2029 aus `684f54a6d11cfb5eccaec30f39fe34d6c17c82cc` scheiterte im
Lauf `43785937519`, Job `133040408296`, erneut am ersten Stein nach dem Gespräch.
Die Produktdatei enthielt bereits den vorherigen Rebuild-Fix (SHA-256 `9ba19a…`).
Die frischen Originalhierarchien `0153` und `0156` boten Vorratsstein 1 als aktiv
und anklickbar an, während Coach-, Bau- und Audiobuttons deaktiviert waren.
`0158` dokumentiert den richtigen Tap auf die beobachteten Bounds
`[138,665,270,797]`. Der Checkpoint blieb bei `moved=0`, `phase=example`.

Anders als bei 2028 zeigt das abschließende Originalbild `0233` wieder aktive
Lernbuttons. Eine dauerhaft verlorene Bindung ist daher nicht die Behauptung
dieses Nachtrags. Belegt ist die **vorzeitig angebotene Modelleingabe**: `_model`
erlaubte die Bedienung unabhängig von der Identität, die sein Callback erfasste.
War diese leer, verwarf der Callback den Tap ohne Modellbewegung.

## Reproduktion und enger Fix

Die verschärfte bestehende Regression setzt das echte Flutter-Systemflag
`FakeAccessibilityFeatures(disableAnimations: true)`, stellt im vorhandenen
Gespräch die Frage „Warum zuerst zwei?“ und betätigt Stopp. Beide Varianten
prüfen jeden vom Scheduler tatsächlich angeforderten Rückkehrframe; eine
simuliert zusätzlich `inactive` → `resumed`. Sie erzwingen nach dem Schließen
keinen zusätzlichen Frame, keinen Resize und keine Settings-Änderung.

- **RED auf unveränderter 684-Produktdatei:** Ein Resume-Fall besteht; beide
  Gesprächsfälle scheitern an `enabled=true` bei fehlender Aufgabenidentität.
  Der erste Original-RED und der RED mit finalem Testinhalt bleiben unverändert
  erhalten. Die zugehörigen Hashes stehen in den beiden Provenienzdateien.
- **Modellfreigabe:** Alle sechs Modellanschlüsse verwenden dieselbe Prüfung
  der beim Build erfassten eigenen aktuellen Coach-Identität. Dadurch wird eine
  unwirksame Eingabe während der Übergangsframes nicht mehr aktiv angeboten.
  Der vorhandene Scope-Check beim späteren Callback bleibt bestehen.
- **Zusätzliche Scheduling-Härtung:** Nach der vorhandenen post-frame
  Registrierung fordert `ensureVisualUpdate` den benötigten Frame ausdrücklich
  an. Flutter 3.44.9 dokumentiert, dass `addPostFrameCallback` allein keinen Frame
  anfordert. Ein dauerhaft ausbleibender Frame wurde in den lokalen Tests
  **nicht separat reproduziert**; dies bleibt von der belegten Modelllücke
  getrennt.

Die finale Regression tippt den Stein genau einmal im **ersten tatsächlich
aktiv angebotenen Rückkehrframe**. Sie verlangt anschließend `moved=1` im
Modell und im vorhandenen Checkpoint. Aufgabe, Sitzung, Phase, bisherige Hilfe,
Versuchszähler und Belohnungen bleiben erhalten; alte Callbacks und Identitäten
bleiben ungültig. Der Hilfestand wird nach der bewusst gestellten Frage erfasst,
da deren Erklärung fachlich korrekt zusätzliche Hilfe markieren darf.

## Ergebnis und Grenzen

`green.log`: **27/27 PASS**, einschließlich der verschärften drei Regressionen
und der bestehenden Lab-Bus-, Native-Entry- und Runtime-Suiten.
`analyze.log`: keine Befunde in den beiden geänderten Dart-Dateien.
Der Testlauf fand vor dem Commit im eigenen Arbeitszweig statt; Quell- und
Testhashes stehen in `handoff.json`. Er ist kein vollständiger integrierter
Root-Testlauf. Die bestehende Widgetfixture verwendet keine echte Stimme oder
Android-Berechtigung; die Lifecycle-Unterbrechung ist simuliert.

Keine Änderung an Android-Probe, Auswahl-/Speichergates, fachlicher Bewertung,
Busvertrag, Audioeigentum, Aufgaben-IDs, Belohnungen oder Checkpointformat.
**Kein neuer Android-PASS und kein neuer APK-Build durch diesen Nachtrag.** Die
unveränderte vollständige Tour muss den neuen Kandidaten erst tatsächlich prüfen.
