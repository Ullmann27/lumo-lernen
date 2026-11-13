# Unabhängige Prüfung des Lernpatches

**Nachtrag:** Der unten dokumentierte native Profil-ID-Altfehler wurde danach
in einem gesonderten, gezielt getesteten Hostpatch repariert. Der ursprüngliche
Vorher-Nachweis bleibt unverändert erhalten. Implementierung, 53 gezielte Tests
und neue Flutter-Rendererbilder stehen in
`STUDIO_NATIVE_PROFILE_KEYS_20261113.md`.

Prüfer: Agent C (Spiele). Geprüft wurden die aktuellen, gemeinsam integrierten
Arbeitskopien vom 13.11.2026. Es wurden keine Dateien aus dem Verantwortungsbereich
von Agent A umgeschrieben. Dieser Bericht ergänzt dessen Funktionsnachweise.

## Ergebnis für die neuen Lernfunktionen

Im Quellvergleich wurde keine neue blockierende Regression in den Änderungen
für Teilen, Multiplikation und Bruchaddition bestätigt. Die folgenden Aussagen
stammen aus der unabhängigen Quellprüfung, nicht aus einem zusätzlichen Gerätetest:

- `LearningActivity` akzeptiert ausschließlich endliche, exakte ganzzahlige
  Operanden. `equal_sharing` ist auf 2–6 Gruppen, 1–6 Objekte pro Gruppe und
  maximal 36 Objekte begrenzt. Nicht ganzzahlige Quotienten werden abgewiesen.
- Die Ziele `(Schritt % Gruppen) * Gruppengröße + Schritt / Gruppen`
  ordnen jede Runde gleichmäßig zu. Die Gruppenzähler konservieren die bereits
  verteilte Menge; Vollständigkeit und Wiederholungssperre verwenden den
  bestehenden Modellpfad.
- `LearningWorld` benutzt für Antippen, Ziehen und den Aktionsknopf denselben
  `move_token`-Pfad. Die neuen Gruppenzähler hängen an diesem Modell. Der
  Layoutwechsel ordnet bereits verteilte Objekte über denselben Zielindex zu.
  Der bestehende Suspend- und Fingerbesitzpfad bleibt angeschlossen.
- `NativeLearningActivity` prüft den Quotienten beziehungsweise das Produkt
  gegen die tatsächliche Aufgabenlösung. Bruchaddition muss gleichnamig,
  positiv und höchstens ein Ganzes sein; die Ergebnisprüfung verwendet die
  Kreuzprodukte der rationalen Werte. Das Godot-Modell stellt zunächst den
  ursprünglichen Zähler dar und verschiebt anschließend genau die zusätzlichen
  Teile bei unverändertem Nenner.
- Der Legacy-Adapter prüft `fraction_add` vor ganzzahligen Plus-Ausdrücken.
  Dadurch wird `1/4 + 2/4` nicht als `4 + 2` interpretiert. Rationale Antworten
  behalten den Schrägstrich; Antwortoptionen und richtige Antwort gehen durch
  denselben Payload-Pfad.
- `DivisionGroupsVisual` zeichnet jede gültige Gruppe vollständig. Größere
  Mengen werden durch explizit mit 100, 10 und 1 beschriftete Bündel dargestellt.
  Nicht unterstützte Eingaben zeigen den eigentlichen Aufgabentext. Die neue
  Bruchdarstellung zeigt bei Addition das Pluszeichen.
- Die Kotlin-Zulassung enthält `equal_sharing`; die produktive Flutter-Route
  öffnet weiterhin die bestehende native Lernszene. Hilfe wird vor dem Start
  markiert. Die Rückkehr liefert keine selbstständig richtige Antwort und
  keine Belohnung. Die vorhandenen Profil- und Aufgabenidentitätswachen bleiben
  an den asynchronen Übergängen bestehen.

Die Protokolle von Agent A dokumentieren 47 gezielte Flutter-Tests, 4
Host-Vorbereitungstests, 1811 neue Godot-Prüfungen und 5328 bestehende
Godot-Prüfungen. Diese Zahlen wurden hier nicht als eigene erneute Testläufe
ausgegeben. Die unabhängige Ausführung unten betrifft genau den zusätzlich
gefundenen nativen Speichergrenzfall.

## Bestätigter Altfehler: native Spiele teilen den Schlüssel trotz getrennter Profile

**Bedeutung:** Die Trennung des adaptiven Lernprofils ist nicht gleichbedeutend
mit der Trennung der nativen Spielstände. Der Fehler befindet sich bereits im
unveränderten Launcher der Baseline; er wurde nicht durch den Lernpatch erzeugt.
Die native Erklärszene speichert selbst keine Lernergebnisse und verursacht
dadurch keine neue Antwortzuordnung. Für die übergreifende Abnahme „getrennt pro
Kind“ ist der native Spielstandpfad trotzdem eine offene Grenze.

### Tatsächlich ausgeführte Reproduktion

Fixture:
`docs/evidence/studio-learning-review-20261113/native_profile_key_probe.dart.txt` (unveränderte Rohquelle der historischen Diagnose)

Rohlog:
`docs/evidence/studio-learning-review-20261113/native-profile-key-probe.log`

Aufruf:

```text
cp docs/evidence/studio-learning-review-20261113/native_profile_key_probe.dart.txt docs/evidence/studio-learning-review-20261113/native_profile_key_probe.dart
flutter --no-version-check test --no-pub --reporter expanded docs/evidence/studio-learning-review-20261113/native_profile_key_probe.dart
rm docs/evidence/studio-learning-review-20261113/native_profile_key_probe.dart
```

Der Test verwendet ausschließlich synthetische Daten in einem
`SharedPreferences`-Speicher im Arbeitsspeicher. Er erstellt über die produktive
`SchoolRepository` zwei unterschiedliche Schüler-IDs in derselben Klasse mit
dem gleichen Namen. Nach jeder echten Profilauswahl bestätigt
`captureLearningProfile()` die jeweils unterschiedliche Schüler-ID. Ein echter
Flutter-Button startet `launchLumo3D(scene: 'puzzle')`. Nur die Android-
MethodChannel-Grenze wird aufgezeichnet und mit einer Rückkehr beantwortet.

Beobachtete Launchoptionen:

| Auswahl | Stabile Lernprofil-ID | Native `childKey` |
| --- | --- | --- |
| Erstes gespeichertes Kind | Erste unterschiedliche Schüler-ID | `p_bbb6dafc1cc5a599d2c092e22928f3dd` |
| Zweites gespeichertes Kind | Zweite unterschiedliche Schüler-ID | `p_bbb6dafc1cc5a599d2c092e22928f3dd` |
| Zweites Kind nach Klassenänderung | Dasselbe ausgewählte Kind | `p_11200e1edb9435368ca9c0b3474c71b1` |

Beide ursprünglichen Payloads enthalten keine zusätzliche `profileId`.
Die Fixture meldet `COLLISION_CONFIRMED` und beendet sich mit Exitcode 0,
weil sie die bekannte Fehlersituation diagnostisch bestätigt. Das ist
ausdrücklich kein bestandener Isolationstest. Sie trägt deshalb keinen
`_test.dart`-Namen und gehört nicht zur normalen Testsuche.

### Vollständiger relevanter Produktionspfad

1. `lib/features/lumo3d/lumo3d_launcher.dart`: `launchLumo3D` ruft
   `_childSaveKey(appState)` auf. `_childSaveKey` bildet einen Hash aus dem
   globalen Salt `lumo_3d_save_salt_v1`, `state.childName` und `state.grade`.
   Eine aktive Schüler-ID wird an dieser Stelle nicht verwendet.
2. Derselbe Launcher sendet genau diesen Wert als `childKey` an `launch3D`.
3. `tools/auto_install/MainActivity.kt` übernimmt den syntaktisch gültigen
   Schlüssel unverändert in `lumoLaunchOptions`.
4. Godot `scripts/creative/puzzle_world.gd` erzeugt daraus
   `user://lumo_puzzle_<childKey>.json`. Schatzsuche und Bauwelt verwenden
   denselben Schlüssel für ihre Dateien; Kart-Streckenpass und Jump & Run
   benutzen weitere Hashes dieses gleichen Schlüssels. Ein späteres Hashen
   trennt bereits gleiche Ausgangsschlüssel nicht.

Es wurde kein echter Android-Dateisystemzugriff dieser Reproduktion behauptet.
Die gleiche tatsächliche Launchoption und ihre unveränderte Verwendung als
Dateiidentität sind jedoch konkret nachgewiesen. Keine Kinderdaten wurden
gelesen, verändert, gelöscht oder migriert.

## Minimaler Reparaturzuschnitt für einen gesonderten Patch

Neue native Speicheridentitäten müssen die stabile ausgewählte Schüler-ID oder
die bestehende unveränderliche lokale Profil-ID verwenden. Anzeigename und
Klassenstufe dürfen nicht die Identität bestimmen. Die Identität muss vor
asynchronen Wartezeiten eingefangen und nach den vorhandenen
`profileGeneration`-Wachen geprüft werden.

Die historischen Namen-/Klasse-Schlüssel müssen erhalten bleiben. Sie tragen
keine beweisbare Besitzer-ID. Ein historisch kollidierter Stand darf deshalb
nicht automatisch dem zuerst geöffneten Kind oder mehreren Kindern zugeteilt
werden. Vollständiger Bestandsschutz benötigt eine separat erreichbare
Altstand-Ansicht beziehungsweise eine ausdrückliche Altstand-Zuordnung mit
gesichertem Original. Reines Umbenennen oder mehrfaches Kopieren wäre keine
saubere Profilreparatur.

Für diesen Review wurden keine solchen Änderungen oder Migrationen ausgeführt.
Die bestehenden Lernprofil-, Schreibtrainer-, Journal- und Offline-Funktionen
bleiben unverändert. Echte Renderer-Abnahme, Android-Lebenszyklus und Fold7-
Leistungsmessung sind eigene Integrationsschritte und werden durch diese
Quellprüfung nicht ersetzt.
