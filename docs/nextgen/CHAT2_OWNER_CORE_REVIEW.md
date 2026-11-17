# Selektive 2f-Kernintegration

Stand: 15.11.2026. Getestete Teillieferung; kein vollständiger
Modernisierungs-, 3D- oder APK-Abschluss.

## Quellen und Grenzen

- Root-Basis: `de2344417a55a542ab546cf5c524915cd5f49cd9`.
- Tatsächlich committed 2f-Quelle:
  `573eb1a14045eb2e7071f250107d6b9a4fb3bf96`.
- Übernommen: Lab-Katalog und LabScreen, CoachBinding, Resume-Repository,
  ModuleTaskScope, Mengenarbeitsbereiche, zwölf Fachmodule, begrenzter
  Money-/Clock-Abschnitt sowie passende Tests.
- Root-Vertrag, Root-Bus, Native-Factory, c5-Aufgabenadapter,
  AdaptiveTaskRenderer, NumberCompare und der bereits integrierte
  Progress-Hilfehelper bleiben unverändert.
- Keine Änderungen an Host, Kotlin, Sprachcontroller, Minispielen,
  IQ, Foto-Übungsoberfläche, Story, Schreibtrainer- oder Journal-Innereien.

Der 573-Checkpoint enthält unvollständige Guided-Änderungen: Beim echten
Analyzer-Lauf fehlten `_cancelPresentation`, `_proposeAnswer`, `_objectIds`,
`_bound` sowie zwei `ValueListenable`-Imports. Diese Guided-Dateien wurden
deshalb nicht in den frühen Kern aufgenommen. `learning_content.dart`
enthält in 573 noch nicht die danach im fremden Working Tree sichtbare
Integration. Die neue Content-Testdatei aus 573 wird bis zu einer
zusammengehörigen committed Lieferung ebenfalls zurückgestellt.

Die anschließenden 2f-Änderungen an Guided, LearningContent, Scope und
Farben/Jahreszeiten/Tiere/Verkehr/Wetter sowie Mehrzahl sind nicht als
committed Fertigstand übernommen. Eine genaue Lieferung wurde über den
vereinbarten Chat-2-Eingang angefordert.

## Eigene geprüfte Integrationskorrekturen

1. **Lab-Lebenszyklus:** Nur die sichtbare aktive Route empfängt Befehle.
   Pause oder Überdeckung gibt die Bindung ab. Resume/Resize erhält das
   Modell; alte Identitäten bleiben ungültig. Wiederöffnen stellt den
   gespeicherten Arbeitsschritt samt Hilfestand wieder her.
2. **Sprachvorschlag:** Im Lab bleibt ein Vorschlag ungewertet, bis das
   Kind „Antwort prüfen“ betätigt. Stopp entfernt einen unbestätigten
   Sprachkandidaten. Bereits selbst eingegebener Text wird dadurch nicht
   pauschal gelöscht. Beide zuerst roten Busregressionen sind grün.
3. **Lab-Hub:** Zwei fehlende Switch-Cases verbinden die neue Musterwelt
   mit ihrem vorhandenen Hub. Die Katalogprüfung umfasst sechs Welten
   und prüft die Musterantwort getrennt von geordneten Wortbausteinen.
4. **Moduloberflächen:** Die zusätzliche Lernzielzeile steht unter der
   bestehenden Aufgabe, damit Antworten im sichtbaren Bereich bleiben.
   Minus nutzt im kurzen Querformat obere Ausrichtung; dafür erhält der
   gemeinsame TaskLayout einen optionalen Parameter mit unverändertem
   Standardwert. Plus stapelt Tipp/Weiter bei zu geringer Breite.
5. **Artikel-Einstieg:** Der aktuelle Jahrgangsfilter verbarg `d2_artikel`.
   Ein zusätzlicher Eintrag im vorhandenen Werkzeugfilter erreicht das
   bestehende Modul; IDs, Inhalte und Profilstufe bleiben erhalten.
6. **Rücksetzen:** Bestätigte Rücksetzungen leeren die profilgebundenen
   Lab-Ansichten und den von Root beauftragten Photo-Session-Key.
   Andere Kinder und fremde Speichereinträge bleiben unverändert.

## Tatsächliche Prüfungen

**198/198 Tests in 14 Dateien bestanden.** Der vollständige Abschlusslauf
ist in `evidence/chat2_core_20261115/core_tests.log` enthalten. Dazu gehört:

- Reale Klicknavigation aus der Akademie zu **19 Registry-Einstiegen für
  18 Fachmodule**. Zwei Einmaleins-Einstiege teilen einen Screen. Das
  geschützte Wortdiktat gehört nicht zu diesen 18 Modernisierungsmodulen.
- In den **13 Einstiegen der zwölf gelieferten Scope-Module** echte
  Busfolgen `hint → repeat → slower → hint → stop`: Hilfe bleibt bei
  Wiederholung auf Stufe eins, steigt anschließend auf zwei, alte
  Identitäten werden zurückgewiesen; Sterne, XP und Daily bleiben gleich.
- Lab-Pause, überdeckte Route, Resume, Resize, bestätigungspflichtiger
  Kandidat, Stopp und dauerhaftes Wiederöffnen ohne zusätzliche Wertung.
- Mengen-/Geld-/Uhr-Konsistenz, gespeicherte vollständige Modulabläufe,
  Hilfen, Schreib-/Diktat-Regressionen, profilgebundene Rücksetzungen sowie
  echte Antworten im Handy-, Fold- und Querformat mit mindestens 48 dp.

Der gezielte Analyzer über 35 geänderte Dart-Dateien ist ohne Befund.
Die neue Wiederöffnen-Regression wurde zusätzlich kompiliert und im
198er-Abschlusslauf ausgeführt. Logs sind echte Konsolenausgaben; nur
abschließende Leerzeichen wurden für `git diff --check` entfernt.

## Noch nicht als fertig belegt

Die Erreichbarkeit aller 18 Module ist bewiesen. Die vollständige
inhaltliche Modernisierung aller 18 Module ist damit nicht bewiesen.
Die zwölf neuen Module besitzen gestufte Hilfen und konkrete Aufgaben-
Snapshots; ihre Scope-API erlaubt bisher keinen gesprochenen
Antwortkandidaten mit eigenem Bestätigungsfeld. Die bestehenden fachlichen
Antwortbuttons bleiben der gültige Wertungsweg.

Die fertige Guided-/Content-Lieferung und die übrigen Moduladapter fehlen
in dieser committed Quelle. Die neuen Lernansichten sind Flutter-2D.
Ein eigenständiger Godot-Durchlauf, dauerhafte 3D-Figur auf jedem Lernpfad,
echte Audio-Synchronität, physische Geräteprüfung und APK-Auslieferung
werden durch diese Teilintegration nicht behauptet.
