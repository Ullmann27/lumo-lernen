# Lumo – Bestandsaufnahme und Prüfstand, Etappe 1

Stand: 2. Oktober 2026. Dies ist eine überprüfbare Bestandsaufnahme mit einem
implementierten zusätzlichen Inhaltsprüfer. Es ist keine Fertigstellung der App
und keine neu ausgelieferte APK.

## Maßgebliche Projektstände

| Projekt | Geprüfter Stand | Bedeutung |
|---|---|---|
| Flutter-Lern-App | `Ullmann27/lumo-lernen`, PR #152, `44095eb9527602c72ff7fe21de0b96329b8a64c1` | Neueste hier untersuchte Weiterentwicklung; noch nicht in main |
| Flutter main | `1e0eeaa7d0a78fcaf89977b47bf03826b56f34eb` | Vergleichsstand; enthält ebenfalls eine PIN |
| Godot-Abenteuer | `Ullmann27/lumo-godot`, PR #1, `3435acd4a1b1265467d58aca7d7d8033e1437e9e` | Separate 3D-App mit Insel-Cup und Wolkeninseln |
| 19 hochgeladene Dateien | Originaldateien unverändert | Historische HTML-, Flutter- und Übergabestände |

[Flutter-Weiterentwicklung](https://github.com/Ullmann27/lumo-lernen/pull/152)
und [Godot-Weiterentwicklung](https://github.com/Ullmann27/lumo-godot/pull/1).
Die ZIP-Bundles 01/02 sowie die HTML-Dateien 07/10 sind jeweils byteidentisch.
Das Flutter-MVP enthält 68 Dateien, aber keine ausgelieferten Avatar-/Audio-Assets
und keinen vollständigen Android-Host. Der Blueprint ist ein älterer Entwurf.
Die aktuelle App wird deshalb aus dem vorhandenen Repository weiterentwickelt.

Die Prüfung las gezielt die Einstiegspunkte, Shell, Begleiter, Spielregeln,
Aufgabenanzeige, Aufgabenpakete, Backend, Buildskripte und CI-Protokolle.
Die vollständige GitHub-Dateiliste des Flutter-Prüfstands enthält 902 Dateien,
darunter 373 Dart-Dateien. Diese Dateiliste ist kein Beleg, dass alle Dateien
inhaltlich geprüft wurden. Lokal liegen nur die für diesen Audit abgerufenen
Dateien vor. Flutter-, Dart- und Godot-SDK stehen in dieser Sitzung nicht zur
Verfügung; ein direkter Git-Checkout war durch die Netzwerkfreigabe blockiert.
Der GitHub-Zugriff selbst funktioniert. Daher werden lokale Einzeltests und
die fest zugeordneten CI-Ergebnisse getrennt ausgewiesen.

## Wiederverwendbare Grundlage

- Flutter/Android, SharedPreferences und vorhandene Profile, Lernfortschritt,
  Wallet, Lernansichten, Lesen, Schreiben, Hilfen und Lehrerbereich.
- Vorhandene responsive Shell und zentrale Theme-/Designbausteine.
- Mathematik-/Deutsch-Templates, weitere Fachgeneratoren, Aufgabenadapter,
  Qualitätswächter und Wiederholungslogik. Der bestehende Template-Audit bleibt.
- Begleiter im echten AppShell: lokal begründete Vorschläge, freiwillige Hilfe,
  App-Erklärung, Sprite-Laufen und Ruhephasen. Der Host berücksichtigt ruhigen
  Modus, reduzierte Bewegung und Systemeinstellungen. Flüssigkeit auf einem
  echten Android-Gerät ist damit noch nicht gemessen.
- Memory-Brett, Gegnergedächtnis und Ergebnisdialog sowie beim Kartenspiel
  Kartenhand, Regel-Engine, Bot, Kartenanimationen und Ergebnisanzeige.
- Separate native Godot-Strecke mit Lenken, Drift, Boost und Gegnern sowie
  vorhandene Engine-Regressionen. Keine vollständige Neuentwicklung nötig.
- Node-KI-Proxy ohne zusätzliche npm-Abhängigkeiten; Schlüssel bleiben serverseitig.

## Konkrete Befunde

| Priorität | Befund mit Codebezug | Konsequenz |
|---|---|---|
| P0 | Release-Lauf 37035422400 baut die APK, scheitert aber an Schritt 14: `verify_android_apk.py` erkennt keine Signatur-Digest-Zeilen. | Neue Download-APK wurde in diesem Lauf nicht veröffentlicht. Den tatsächlichen Tool-Output sicher untersuchen; Prüfung nicht umgehen. |
| P0 | `app_settings.dart`, `parental_gate.dart`, PIN-Editor, Setupdialog und Wiederherstellung sind aktiv. | Verstößt gegen den neuen Auftrag „keine PIN“. Entfernung und Migration vorhandener Einstellungen sind offen. |
| P1 | Alle vier JSON-Fragenpakete haben bei allen 200 Fragen `correctIndex: 0`. Repository und Lernfragen-Overlay geben die Antwortreihenfolge unverändert weiter. | Die erste Antwort ist immer richtig; Kinder können den Inhalt umgehen. Antworten mit korrekt umgerechneter Lösung mischen. |
| P1 | Acht Fragen haben doppelte Antwortmöglichkeiten: Klasse-1-Deutsch Zeilen 41–45, Klasse-2-Deutsch 16/25, Klasse-2-Mathe 34. | Bei „Mehrzahl von Hund?“ steht „Hunde“ zweimal; eine sachlich richtige Auswahl kann falsch bewertet werden. |
| P1 | Klasse-2-Deutsch Zeilen 47–50 wiederholen Zeile 46 exakt. | Vier vermeidbare Wiederholungen. Inhalt fachlich ersetzen, nicht automatisch veröffentlichen. |
| P1 | JSON enthält nur `prompt`, `options`, `correctIndex`, `hint`. Loader mischt Klassen 1/2 und Fächer ohne Klassen-/Fachparameter; die Karten-Controller-Anfrage gibt keinen solchen Filter mit. | Kartenfragen passen nicht verlässlich zum Kind. IDs, Fach-/Klassenfilter, Kompetenz, Schwierigkeit, Vorwissen, Erklärung und Quellen fehlen hier. |
| P1 | Vorhandenes `TopicCurriculum` hat Themenkontexte, aber in der geprüften Datei keine nachvollziehbaren RIS-/Lehrplanquellen oder Fassungen. | Keine Bestätigung vollständiger Übereinstimmung mit dem aktuell geltenden Lehrplan. Fachliche Quellenprüfung bleibt Etappe 3. |
| P1 | Memory hat ein festes 6×4-Brett, 12 Emoji-Paare und keine wählbaren Lern-/Klassenvarianten. | Brett und Gegner behalten; Bild–Begriff-/Rechnung–Ergebnis-Paare und abgestufte Größen ergänzen. |
| P1 | Memory-Neustart ist jederzeit erreichbar; `Timer` und `Future.delayed` prüfen nur `mounted`, nicht die Rundennummer. | Alte Züge können nach einem Neustart das neue Brett verändern. Timer abbrechen und asynchrone Züge an die jeweilige Runde binden. Dies ist ein statisch belegter Ablaufkonflikt, noch kein hier ausgeführter Widget-Reproduktionstest. |
| P1 | Kartenmodell/-regeln verwenden Zahlen/Farben, sieben Startkarten, Aussetzen, Richtungswechsel, Ziehen 2/4 und Farbwahl. | Die gewünschte eigenständige Lernmechanik ist noch zu entwickeln. Animationen/Hand/Engine-Struktur bleiben nutzbar; bloßes Umbenennen genügt nicht. Keine rechtliche Bewertung einer Schutzrechtsverletzung. |
| P1 | Flutter-Kart `_onTick` und Godot-Kart `_physics_process` stoppen den Rennfortschritt, solange eine Frage offen ist. | Beide Fassungen unterbrechen das Rennen hart. Neue Lernintegration schrittweise im vorhandenen Godot-Rennen aufbauen. |
| P1 | Memory/Kartencontroller besitzen in den geprüften Dateien keine vollständige Sitzungsspeicherung samt Hintergrund-/Fortsetzungsprotokoll. | Unterbrechung, Neustart, Abbruch und einmalige Ergebnisbelohnung müssen gezielt getestet werden. |
| P1 | `assets/videos/lumo_intro.mp4` existiert (2.377.499 Bytes). Der untersuchte Einstieg enthält keinen Videoplayer; Karten-Splash ist Logoanimation. Die main-Code-Suche findet keine Videoplayer-Verwendung. | Videoasset wiederverwenden, wenn Inhalt/Rechte/Abspielbarkeit passen. Wiedergabe, Überspringen und Erstausführung sind nicht als fertig nachgewiesen. Datei wurde hier nicht dekodiert. |
| P2 | Aufgabenrenderer enthält Karten und animiertes Antwortfeedback, aber keine nachgewiesene zentrale räumliche Hologramm-Fragefläche. | Gezielt ein gemeinsames Aufgabenpanel mit ruhiger Darstellung entwickeln. |
| P2 | 32 wörtliche Asset-Dateiverweise aus 22 untersuchten Dart-Dateien existieren in der vollständigen Git-Dateiliste. Fünf Kart-Asset-Verzeichnisse sind im pubspec doppelt deklariert. | In dieser begrenzten Stichprobe keine fehlenden Assets. Kein vollständiger Asset-, Bildqualitäts- oder Lizenznachweis. |

Die fachliche Erstprüfung findet außerdem die Verwechslungsmöglichkeit von
Laut und Buchstabe: „Womit beginnt Vogel?“ ist mit V markiert, der Hinweis
verlangt jedoch den ersten Laut. Auch Silben-Distraktoren wie „Ma-ma-x“ und
Sachgeschichten ohne ausdrückliche Fragestellung brauchen didaktische Überarbeitung.
Diese Punkte werden nicht durch einen automatischen Rechenergebnis-Test freigegeben.

Die ältere öffentliche Briefing-Fassung enthielt einen Zugangsschlüssel; die
untersuchte Weiterentwicklung hat ihn bereits aus dem aktuellen Text entfernt.
Es wurde kein Schlüssel verwendet. Widerruf durch den Kontoinhaber bleibt nötig,
weil die Git-Historie dadurch nicht bereinigt wird.

## Tatsächlich geändert in dieser Etappe

`scripts/audit_question_bundles.py` ergänzt den vorhandenen Template-Audit um
die bisher getrennten ausgelieferten JSON-Fragen. Das Skript liest nur und
ändert keine Aufgaben, Lösungen, Dateien oder Lehrplanbezüge.

Es prüft Schema, leere/doppelte Optionen, numerisch gleichwertige Antworten,
exakte Aufgabenwiederholungen, Antwortpositions-Verteilung und unabhängig
berechnete Ergebnisse eindeutig erkannter Plus-/Minus-/Mal-/Divisionsfragen.
Fehlende Inhaltsmetadaten und fachlich noch ungeprüfte Fragen bleiben sichtbar.
Bei Problemen endet es mit Exitcode 1; das bedeutet gefundene Inhaltsmängel,
keinen Absturz. Es wird vor deren Behebung nicht als neue harte APK-Sperre
in den bestehenden Workflow eingebaut.

App-Funktionen, PIN, Spielregeln, Assets und Produktivdienste wurden in dieser
Etappe nicht verändert. Es wurde kein kostenpflichtiger Dienst gestartet und
keine APK als fertige Umsetzung ausgegeben.

## Ausgeführte Prüfungen

| Prüfung | Ergebnis | Abgrenzung |
|---|---|---|
| Neue Python-Audit-Tests | 8 bestanden | Falsche Lösung, numerisch gleiche Antworten, Unicode-Dubletten, ungültiger Index, Wiederholungen, ungelesene Fachbedeutung und fehlende Dateien |
| Vorhandene Node-Backend-Suite | 19 bestanden, 0 übersprungen | Lokal, simulierte Providerantworten; kein Live-KI-Nachweis |
| Vorhandene Python-Android-/Signaturtests | 8 bestanden | Lokal, Testfixtures; kein echtes APK-Signatur-Abnahmeergebnis |
| Neuer JSON-Audit | 200 Fragen gelesen, 73 Rechenfragen unabhängig bestätigt, 127 Fragen fachlich noch manuell zu prüfen; 16 Probleme gefunden | 8 doppelte Antwortlisten, 4 wiederholte Fragen, 4 Pakete mit fester Lösungsposition |
| GitHub-CI zum exakt gleichen Flutter-Stand | 376 Flutter-Tests bestanden, 4 übersprungen; 37.540 generierte Aufgaben geprüft; Debug-APK gebaut | Verifiziert im CI-Protokoll, nicht hier lokal ausgeführt; 144 Analysewarnungen/-hinweise sichtbar |
| Release-CI am gleichen Stand | APK gebaut, Signaturprüfung fehlgeschlagen, Veröffentlichung übersprungen | Keine erfolgreich freigegebene neue Download-APK |
| Vollständige Spielrunden, Android/Fold-Gerät, FPS, Videowiedergabe, persistente Spiel-Fortsetzung | **offen** | Nicht durch Code-Lesen, Screenshots oder Bestandstests ersetzt |

[Erfolgreicher Debug-Prüfbau](https://github.com/Ullmann27/lumo-lernen/actions/runs/37035430147)
und [fehlgeschlagene Release-Freigabe](https://github.com/Ullmann27/lumo-lernen/actions/runs/37035422400).

## Reproduzieren

Die Änderungen gehören in das bestehende Repository, nicht in einen neuen App-Entwurf.

```bash
python3 -m unittest discover -s scripts/tests -p 'test_audit_question_bundles.py' -v
python3 scripts/audit_question_bundles.py --json-output /tmp/lumo-question-audit.json
```

Mit vollständigem Projekt und Flutter 3.44.9 gemäß vorhandener CI:

```bash
flutter pub get
flutter analyze --no-fatal-infos --no-fatal-warnings
flutter test --no-pub --reporter=expanded --timeout=45s --concurrency=2
dart scripts/audit_content.dart
```

Für Android zuerst den vorhandenen Host-/Signierungsprozess verwenden und
die Signaturstörung beseitigen. Keine Installation eines ungeprüften Builds
als vermeintlich fertige neue Lumo-Version empfehlen.

## Priorisierter Umsetzungsplan

| Etappe | Klein abgegrenzter nächster Stand | Abnahme |
|---|---|---|
| 1 – jetzt | Ausgangsstände, echte Befunde, zusätzlicher JSON-Audit und Regressionen | Audit reproduziert die 16 Probleme; keine Originaldatei überschrieben |
| 2a | Ausgabe der APK-Signaturprüfung anhand realer Tool-Ausgabe reparieren | Echtes APK gegen das erwartete Zertifikat prüfen; falsche/mehrere Signierer weiter ablehnen; Release erfolgreich |
| 2b | Sämtliche App-PINs, Setup, Wiederherstellung und gespeicherte Sperren entfernen | Bestehende Profile ohne PIN starten; Eltern/Einstellungen/Einlösen/Deep-Links ohne PIN; Lernstände erhalten |
| 2c | Erwachsene klar kennzeichnen; ohne verlässlichen Schutz riskante Freigaben inaktiv halten; zentrale Bewegungs-/Audio-/Geräteeinstellungen vereinheitlichen | Keine versteckte Ersatz-PIN und keine als Sicherheit ausgegebene Rechenfrage; sensible Aktionen nicht ungeschützt aktivieren |
| 3 | JSON-Fragen und Generatoren mit IDs, Metadaten, Erklärungen, Klassen-/Fachfilter und aktuellen amtlichen Lehrplanquellen prüfen; danach Hologramm-Aufgabenfläche und situativer Lumo | Fachprüfung plus eindeutig bewertbare Aufgaben; reduzierte Bewegung; kleine Displays; keine Ablenkung/Überdeckung |
| 4 | Vorhandenes Memory zuerst mit sauberer Rundentrennung, Pause und Lernpaaren ausbauen | Eine komplette Runde je Schwierigkeitsstufe plus Neustart während Botzug und Hintergrund/Fortsetzung |
| 5 | Eigenständige Lern-Kartenregeln entwerfen, vorhandene Darstellung/Hand/Botstruktur weiterverwenden | Volle Runde, verständliche Regeln, Sieg, Abbruch, Pause, Lösungsauswertung und Belohnung genau einmal |
| 6 | Bestehendes Godot-Kart in spielbaren Schritten: Fahrgefühl, sanfte Lernintegration, Strecke/Hindernisse, Progressionsabgleich | Komplette Rennen; Lernen ohne harte Stopps; vereinbarter Leistungswert auf echtem Gerät |
| 7 | Vorhandenes Video prüfen und gegebenenfalls rechtmäßig ergänzen; Player anschließen | Tatsächliche Video-/Tonwiedergabe, Untertitel/Text, Überspringen, späterer Start ohne Zwang |
| 8 | Gesamtabnahme, Installation/Update, Geräte-/Leistungstests, Pflege- und Builddokumentation | Aufgaben und alle drei vollständigen Spiele starten; Lumo animiert; Intro abspielbar; nirgendwo PIN |

Die Reihenfolge bleibt beim Auftrag. Die Release-Störung steht innerhalb der
technischen Grundlage zuerst, damit spätere geprüfte Änderungen zuverlässig
als APK ankommen. Die PIN-Entfernung ist ausdrücklich beauftragt; eine neue
PIN-Konfiguration ist keine Lösung für diesen Auftrag.

Offen bleiben ein gemeinsamer Fortschritt zwischen Flutter und Godot,
vollständiger Quellen-/Lizenznachweis, Datenschutzprüfung der realen Datenflüsse,
externe KI-Verfügbarkeit und Lehrkräfte-/Kindererprobung. Langfristig müssen
Flutter/Godot/Android, Abhängigkeiten, Server, Datenschutz und Lehrplanquellen
weiter gepflegt werden. Keine Zusage jahrelanger Wartungsfreiheit.
