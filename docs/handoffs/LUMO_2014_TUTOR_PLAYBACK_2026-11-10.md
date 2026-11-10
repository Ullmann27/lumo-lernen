# LUMO 2014: Zehner-Erklärung und ehrliche Lernbeobachtung

Ausgangsstand: Flutter `76aa559cb03d968f492b59129c1b7cee057e76e9` (APK-Kandidat 2013).
Entwicklungszweig: `lumo-2014/learning-tutor-20261110`. Kein Main-Merge, kein Release.

## Referenz, Ist und neue Umsetzung

Die Originalmappe `Lumo_Referenzmappe_2026-11-03.pdf`, Bildtafel 71 auf Seite 68
und die Lernregeln auf Seite 146 wurden geprüft. Navy, Cyan, sparsames Gold,
native mathematische Mengen, bestehende App-Shell und Original-Lumo bleiben
maßgeblich. Vorhandene Apfelgrafiken werden weiterverwendet.

| Bereich | Alter Iststand | Neuer Iststand | Offenes Soll |
| --- | --- | --- | --- |
| Zehner-Beispiel | 1,6-Sekunden-Tween ohne eigene Wiedergabesteuerung; Ergebnis sofort sichtbar | 8+5 mit sechs nachvollziehbaren Phasen; zwei Äpfel einzeln in freie Plätze, dann drei übrige umordnen; Ergebnis erst am Schluss | Weitere Rechenoperationen auf dieselbe steuerbare Architektur übertragen |
| Bedienung | Nur gesamtes Beispiel neu starten | Pause/Abspielen, halbes Tempo, Schritt vor/zurück, Neustart; mindestens 48dp; reduzierte Bewegung als manuelle Zustände; App-Hintergrund pausiert; Phasentext mit bestehender Stimme verbunden | Hörbare Abnahme auf Android und Sternen-Objektvariante |
| Lernbeobachtung | Aufgabenart konnte trotz Tipp als selbstständig gelobt/gezählt werden; finale Probe erzeugte keinen Transfermarker | Tipps und Versuche nach Feedback bleiben begleitet; echte erste Antwort ohne Hilfe kann Transferprobe werden; Wiederholungsplan nutzt vorhandene lokale Journey | Kein neues umfassendes Diagnosemodell behauptet |
| Hilfewahl | Gleicher allgemeiner Hinweis unabhängig von der Antwort | Bei Zehner-Summen konkrete Hinweise für Antwort gleich Rest, Ergänzung oder zehn; nur beobachtete Beziehungen, keine behaupteten Ursachen | Weitere fachlich geprüfte Fehlermuster und Voraussetzungstests |
| Rückkehr aus leichter Übung | Hilfehistorie derselben Aufgabe wurde zurückgesetzt | Begleitete Vorgeschichte bleibt für diesen Schritt erhalten | Vorhandene Discovery-Speichersemantik bleibt unverändert |

## Erhaltung

Keine neue Datenbank, Cloud-Anfrage, Kinderdatenübermittlung, Paketkennung,
Versionsänderung oder Signaturänderung. Bestehender Schreibtrainer und Journal
werden nicht angefasst. Beobachtungen gehen über den bestehenden Profil-Lease,
die idempotente Speicherwarteschlange und `LearningJourney` Version 1. Gespeichert
werden an dieser Grenze Fehlercodes, keine neuen Rohantwort-/Namensfelder.

Der bestehende Abstandplan von 1/3/7/14 Tagen bleibt eine transparente Heuristik.
Eine begleitete Lösung bestätigt keine Beherrschung; der abschließende erste
Versuch ohne Hilfe ist eine Übertragungsbeobachtung, keine umfassende Diagnose.

## Prüfbefehle

Flutter 3.44.9, Dart 3.12.2; alle Befehle mit `CI=true BOT=true
FLUTTER_SUPPRESS_ANALYTICS=true`. Abhängigkeiten unverändert mit
`flutter pub get --offline --enforce-lockfile` aufgelöst.

```sh
flutter test --no-pub --concurrency=1 \
  test/tutoring/guided_lesson_evidence_test.dart \
  test/tutoring/guided_ten_frame_playback_test.dart \
  test/tutoring/guided_quantity_animation_test.dart \
  test/tutoring/guided_lesson_catalog_test.dart \
  test/tutoring/guided_lesson_runtime_test.dart
flutter analyze --no-pub lib/domain/tutoring lib/features/tutoring test/tutoring
```

Erster Gesamtlauf: 102 Tests bestanden. Nach Schrift-/Bedienungsprüfung:
38 betroffene Tests bestanden; sechs Wiedergabetests inklusive echter PNGs
erneut bestanden. Die letzte Nachrunde nach Entfernen der doppelten Replay-Schaltfläche:
25 von 25 real bedienten Lektionsabläufen bestanden. Die gezielte Analyse
der sieben geänderten Dart-Dateien ist ohne Befund; die breitere Analyse
der bestehenden Tutoring-Verzeichnisse meldet sechs bereits unveränderte
Stilhinweise in Sprach-/Natur- und Stellenwertdateien (keine Compilerfehler).

Die Tests prüfen echte Mengen auch während Bewegung, keine Antwortvorgabe bei
selbstständigen Aufgaben, Pause/Tempo/Zurück/Neustart, App-Lifecycle,
260/360/720dp, mathematische Antworten, Hilfe-/Wiederholungsnachweise,
Speichern/Wiederladen, Profilwechsel und reale Handy-/Fold-Lektionsbedienung.

## Echte Bildnachweise

Nachher-PNGs entstehen mit `LUMO_TEN_FRAME_CAPTURES=<Ordner>` beim
`guided_ten_frame_playback_test.dart`. `ten-frame-step-1.png` bis
`ten-frame-step-6.png` zeigen die einzeln bedienten Phasen; `ten-frame-260.png`,
`ten-frame-360.png`, `ten-frame-720.png` die statischen barrierearmen Zustände.
Nunito und MaterialIcons werden explizit geladen.

Vorher-PNGs wurden im separaten unveränderten Basis-Worktree aus
`GuidedMathIllustration` gerendert, mit derselben Aufgabe 8+5, denselben Breiten
und Pixeldichte 2. Der Basiskatalog enthält 7+5; für einen ehrlichen Bildvergleich
wurde ausschließlich der reguläre Testeingabeparameter auf 8+5 gesetzt.
Es sind tatsächliche Flutter-Widget-Rendererbilder, keine Android-Aufnahmen
und keine generierten Gestaltungsbilder.

## Ergänzung: Elternentscheidung und dauerhafte Lernkette

Die bestehende Elternkarte zeigt nun auch gespeicherte Journey-Belege mit
getrennter Hilfe-/Selbstständig-Zählung. „Lerneinschätzungen zurücksetzen“ öffnet
eine Erklärung des genauen Umfangs, eine ausdrückliche Erwachsenenbestätigung
und eine abschließende Löschschaltfläche. Das entspricht der bestehenden lokalen
Elternfreigabe; es ist keine verifizierte Erwachsenenidentität oder PIN-Sperre.
Ein Profilwechsel während des Dialogs bricht die Löschwirkung ab.

Gelöscht werden ausschließlich Journey-Beobachtungen, Methodenrückmeldungen und
ausstehende Tutorbelege des erfassten Kindes. Ein dauerhafter, profilspezifischer
Reset-Marker beendet einen unterbrochenen Löschvorgang vor dem nächsten Tutorlesen.
Alte Lesson-Leases werden ungültig, damit verzögerte Aktionen nichts wiederherstellen.
Reale Schulantworten, Tagesfortschritt, Profile, Wallet, Spiele, Schreibtrainer und
Journal bleiben erhalten. Eine manuelle Kompetenzkorrektur mit Herkunftsnachweis
ist damit ausdrücklich noch nicht implementiert; die Eltern können eine unpassende
Tutor-Einschätzung verwerfen und durch neue Aufgaben prüfen lassen.

`test/tutoring/tutor_parent_reset_test.dart` prüft die tatsächlichen Speicherpfade:
drei beobachtete Zehnerfehler, passende Hilfe, begleitete Korrektur, verschiedene
unabhängige Aufgaben und Übertragung, danach verspätete Wiederholung an Tag 3
und Tag 7. Der vorhandene Abstandsplan setzt dann Tag 6 bzw. Tag 14 als nächste
Fälligkeit. Jeder Schritt wird neu aus der Persistenz geladen. Ein unbeobachtetes
anderes Kind bleibt ohne erfundene Kompetenz. Zusätzlich werden Abbrechen,
Erwachsenenbestätigung, Profilwechsel, unterbrochene Speicherung, alte Aktionen und
unveränderte andere Speicherfelder inklusive echter Schreib-/Journal-/Spiel-Wallet-
Testeinträge geprüft. Es werden ausschließlich fiktive Testprofile verwendet.

Gezielte Abnahme: neun Tests für Reset/Elternkarte/Tutorpersistenz bestanden;
36 Tests für Reset/Szenenpersistenz/Profiltrennung/Legacy-Daten bestanden.
Die Analyse der fünf neuen bzw. geänderten Dart-Dateien meldet keine Befunde.
Die sechs Sprach-/Natur-Widgettests wurden auf eine tatsächlich selbstständig
gelöste Aufgabe und einen begleiteten Erfolg berichtigt und bestehen vollständig.

## Noch nicht auf Android nachgewiesen

Android-Emulator, echte Fold7-Hardware, gesamte App-Regression und signierte
APK sind Aufgabe des Integrationsstands und hier nicht nachgewiesen.
Die schrittgebundene Sprachsteuerung wird unten beschrieben; eine tatsächliche
hörbare Geräteprüfung steht aus. Weitere Themenanimationen und eine
vollständige persönliche Nachhilfe für alle Lerngebiete sind mit diesem
gezielten Patch nicht abgeschlossen.

## Ergänzung: Phasentext und bestehende Sprachausgabe

`GuidedLessonScreen` reicht den sichtbaren Phasentext über die vorhandene,
abbrechbare `LumoVoice.speak`-Kette weiter. Der gesamte Beispielabsatz wird nicht
zusätzlich automatisch oder über einen zweiten Vorleseknopf gestartet. Bei
aktiviertem automatischen Vorlesen bleibt eine Phase stehen, bis ihr Sprachaufruf
beendet ist; danach bewegt sich die vorhandene Menge zur nächsten Phase. Pause,
Schritt vor/zurück, Wiederholen, Tempoänderung, Stummschalten, App-Hintergrund und
Verlassen stoppen die eigene alte Narration. Eine verspätete Sprachbeendigung
kann weder die Animation wieder starten noch einen alten Satz nachschieben.
Das Entsorgen der alten Animation stoppt keine Ansage der nächsten Lernaufgabe.

`voiceEnabled`, `autoReadEnabled` und `calmMode` bleiben maßgeblich. Ohne
automatisches Vorlesen gibt es bei eingeschalteter Stimme den ausdrücklichen
Knopf „Schritt anhören“; reduzierte Bewegung startet dadurch keinen Lauf.
Ohne Stimme bleibt die vollständige Bildsteuerung verfügbar. Es wird weder eine
neue TTS-Abhängigkeit noch eine neue Sprachfreigabe eingeführt. Die vorhandene
Stimmidentität, lokale Lizenz-/Onlinefreigaben und Meldungen für fehlendes Audio
werden nicht umgangen. Die lokale Kanalkette ist mit deaktivierter Cloud geprüft.

Neue Vertragstests prüfen laufende/langsame Sprache, deren Abbruch und alte
Abschlüsse sowie die echte Kette Screen → LumoVoice → lokaler Sprachkanal für
automatisch, manuell, Ruhemodus und stumm. Der native Syntheseaufruf wird dabei
kontrolliert simuliert; das ist kein hörbarer Android-Nachweis. Darstellung und
Ansage sagen konsistent „Äpfel“. Die ausdrücklich gewünschte Sternenvariante
bleibt eine Abweichung vom Nutzerbeispiel und ist nicht implementiert.

Nach dieser Integration bestanden 13 Wiedergabe-/Sprachkanal-Vertragstests,
31 bediente Lektions-/Sprach-/Naturabläufe sowie die Analyse aller fünf
betroffenen Dart-Dateien ohne Befund. Zuvor bestanden 59 Mengen-/Wiedergabetests.
