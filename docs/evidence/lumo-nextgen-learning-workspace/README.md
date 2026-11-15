# Ausgeführte Flutter-Lernflächen

Diese PNGs stammen aus dem laufenden Flutter-Widget-Renderer. Die Tests laden
die App-Schriften und Assets, führen die beschriebenen Berührungen aus und
erfassen anschließend die echte `RepaintBoundary`. Die Aufnahmen sind keine
Mockups und keine Aufnahmen eines physischen Android- oder Fold-Geräts. Die
transparente Umgebung gehört zum Widget-Ausschnitt; die vollständige App-Hülle
und das gemeinsame LUMO-/Sprachsystem werden gesondert integriert geprüft.

## Ansichten

| Präfix | Logische Testfläche | Textskalierung |
| --- | --- | --- |
| `phone-320` | 320 × 800 | 1,0 |
| `fold-cover` | 344 × 882 | 1,4 |
| `fold-open` | 840 × 900 | 1,0 |

Jede Fläche enthält drei reale Zustände:

- `quantity`: 8 + 5 nach zwei Bewegungen. Zehn unterscheidbare Steine liegen im
  Feld, drei im Vorrat. Die ursprünglichen 13 Objektkennungen bleiben erhalten.
- `syllables`: Banane nach dem ausdrücklich angeforderten Silbenhinweis.
  Ba, na und ne sind getrennt bedienbar. Die Textmarkierung folgt beim
  Host-Anschluss dessen tatsächlichem aktuellem Segment, keinem geschätzten
  Audiotimer.
- `pattern`: Kreis–Dreieck–Kreis–Dreieck–Kreis nach Anforderung der
  Wiederholungsgruppe. Ein echter gemeinsamer Rahmen markiert die ersten zwei
  Formen. Die Positionszahlen bleiben auch ohne Farberkennung verständlich.

Die Aufnahme kann vertikal gescrollte Inhalte zeigen. Dadurch wird die
Lernfläche in den schmalen Ansichten lesbar; diese Ausschnitte belegen keine
gleichzeitige Sichtbarkeit aller Elemente der gesamten Seite.

## Reproduzieren

```sh
LUMO_WORKSPACE_CAPTURES="$PWD/docs/evidence/lumo-nextgen-learning-workspace" \
  flutter test --no-pub test/learning/interactive_task_workspace_test.dart \
  --reporter=expanded
```

In einer gemeinsam genutzten SDK-Installation wird der Flutter-Aufruf mit dem
gemeinsamen `flock --close` geschützt. Die Datei
`test/learning/interactive_task_workspace_test.dart` prüft außerdem
Mengenerhaltung, schnelle Mehrfacheingaben, Wiederholung, Aufgabenwechsel,
mindestens 48-dp-Aktionen, unterstützte Antworten, Dezimalstellen, gleich große
Bruchteile, Pflanzenteile, absteigende Zahlenfolgen und die Zustandskennungen
für den Begleiter-Anschluss.

Weitere konkrete Regressionen liegen in
`test/learning/sentence_prompt_privacy_test.dart` und
`test/learning/fallback_prompt_integrity_test.dart`: Sichtbare Modelle dürfen
vor der Antwort weder den Lösungssatz zusammensetzen noch ein verstecktes
Lösungswort als Schreib- oder Lautvorlage nutzen. Zwei beliebige Promptzahlen
begründen keine Rechnung. Zehn Zehner werden nicht auf neun gekürzt.
