# Eigene Aufgabe aus Text erkennen und bearbeiten

## Ausgangsbeleg und modularer Anschluss

Das bereitgestellte Original HTML05 besitzt in `Recognizer.parse`, `recognizeNow` und `recognizeStart` (Zeilen 702–742) einen lokalen Ablauf von Texteingabe über Vorschau zur genau erkannten Aufgabe. Der vorliegende Flutter-Foto-/Dialogweg hatte diesen Ablauf nicht: Foto-Lektion erzeugt neue Themenaufgaben, der Agent beantwortet Fragen zur aktuellen Situation.

Die Integration ergänzt eigene Dateien für Parser/Versuch, Repository, Controller und Bildschirm. Einstieg: `LumoTaskRecognitionScreen(appState: appState)` aus `lib/features/recognition/lumo_task_recognition_screen.dart`. Der koordinierte Home-Anschluss heißt „Aufgabe eintippen“ im Bereich „Mehr mit Lumo entdecken“. Bestehende Elternaufgaben, Journal- und Schreiboberflächen werden nicht verändert.

## Unterstützte Eingaben

| Fall | Beispiel | Prüfung |
|---|---|---|
| Ganze Rechnung | `12 + 7`, `3 − 8`, `6 × -2`, `999 * 10 = ?` | Vollständiger Ausdruck mit genau einer binären Addition, Subtraktion oder Multiplikation. `x`, `X`, `×` und `*` bezeichnen Multiplikation. Vorzeichen werden mathematisch berücksichtigt. |
| Anfangsbuchstabe | `Anfangsbuchstabe Mama`, `Anfangsbuchstabe von Äpfel`, `Mit welchem Buchstaben beginnt Schule?`, `Hund Anfangsbuchstabe` | Ein einzelnes Wort aus deutschen Buchstaben, höchstens 40 Zeichen. Kein freier mehrdeutiger Satz. |
| Arithmetische Folge | `2, 4, 6, ?`, `9 6 3 ?`, `-2, -5, -8, ?` | Drei bis acht ganze Zahlen. Jeder benachbarte Abstand muss gleich sein. Auch fallende und konstante Folgen sind möglich. |

Der gesamte Text muss passen; es gibt keine Auswertung beliebigen Codes, keine Cloud-Anfrage und keine erfundene Ersatzaufgabe. Die Eingabe ist auf 240 Zeichen begrenzt. Rechenoperanden liegen zwischen −999 und 999; Rechnungsergebnis, Folgenwerte und nächster Wert zwischen −9999 und 9999. Verkettete Rechnungen, Dezimalwerte, Division, widersprüchliche Folgen, bereits ausgefüllte Gleichungen und unbekannte Formulierungen zeigen eine verständliche Fehlermeldung.

Die Antwortauswahl enthält genau vier verschiedene Werte. Die richtige Antwort wird vor den Ablenkantworten aufgenommen und bleibt auch an den Zahlengrenzen enthalten. Die Anzeige mischt nur deren Reihenfolge anhand der Versuchsidentität. Inhalt und richtige Lösung werden nicht neu generiert.

## Vorschau und tatsächlicher Übungsfluss

„Aufgabe erkennen“ zeigt die erkannte Art und die konkrete Frage. „Genau diese Aufgabe starten“ speichert diese Definition und öffnet den bestehenden `AdaptiveTaskRenderer`. Jede Änderung am Eingabefeld verwirft die alte Vorschau; ein Profilwechsel entfernt die vorherige Eingabe und Aufgabe sofort.

Die Lösung wird nach der Antwort bzw. als gekennzeichnete Hilfe gezeigt. Der Renderer prüft die tatsächliche Antwort. Der Controller überprüft zusätzlich Versuchs-ID, Kind, Frage und die Übereinstimmung von Antwortwert und Korrektheitsmeldung. Die bestehende `RewardEngine` liefert die aktuellen App-Belohnungen: selbständig richtig 6 Sterne/25 XP, mit Hilfe richtig 2 Sterne/10 XP, falsch 0/0. Der alte HTML-Bonus wird nicht als zweite parallele Belohnungsregel eingeführt.

## Dauerhafte Ergebniszuordnung

Jeder Versuch erhält eine ID `recognized:<sha256(ownerId)>:<32hex>`. `RecognizedTaskRepository` speichert unter `lumo_recognized_task_v1::<owner>` mit `LearningStorage`-Serialisierung zuerst Aufgabe und anschließend die angenommene Antwort. Das Aufgabenprotokoll, die idempotente Wallet-Buchung und der Abschlussbeleg verwenden dieselbe ID. Ein Abbruch nach erfolgreicher Wallet-Buchung lässt einen offenen Beleg zurück; Neustart/Retry bestätigt dieselbe Buchung, ohne noch einmal zu bezahlen.

Während eines Profilwechsels bleibt ein bereits gespeicherter Versuch bei seinem ursprünglichen Kind. Eine spätere Wallet-Phase darf erst unter dessen gültiger Lease fortgesetzt werden. Beschädigte oder unbekannte Speicherformate werden nicht durch eine neue Aufgabe überschrieben. Der Backup-Präferenzbereich enthält dieses neue lokale Format automatisch.

Der Aufgabenbericht verwendet das eigene Fachlabel **Eigene Textaufgaben** und die Kompetenzangabe **Freie Texteingabe**. Diese frei eingegebenen Aufgaben schreiben keine Curriculum-Kompetenz, kein Tagesmissions-Ergebnis und keinen Prüfungsnachweis. Der Profil-Spielzähler filtert den `recognized:`-Präfix wie `parent:` aus. AppState hält außerdem bei gewöhnlichen Reward-Writes den ursprünglichen Owner bis zum Commit fest; der bestehende Lernmodul-Adapter übergibt seine bereits angenommene Lease ausdrücklich.

## Lokale Nachweise

| Prüfung | Ergebnis |
|---|---|
| `test/recognized_task_parser_test.dart` | 36/36 PASS: alle Grammatiken, negative/konstante/randnahe Werte, richtige Auswahl, Rundlauf, Mehrdeutigkeit, Grenzen und beschädigte gespeicherte Daten. |
| `test/recognized_task_flow_test.dart` | 9/9 PASS: drei tatsächlich bediente 390-dp-Flows, fehlerhafte/stale Vorschau, doppelte Abgabe, falsche Antwort, Neustart nach Wallet-Erfolg, A/B-Wechsel und ursprünglicher Owner eines verzögerten Reward-Writes. |
| Gemeinsamer gezielter Lauf | 45/45 PASS, Exit 0, etwa 3 Sekunden; Log `recognition-tests.txt`. |
| Gezielte statische Analyse | Neue Modul-/Testdateien, AppState und bestehender Lernmodul-Adapter; Ergebnis in `recognition-analysis.txt`. |

Diese Nachweise stammen aus Flutter-/Dart-Tests. Sie behaupten keinen bereits erfolgreichen Android-2067-Rundgang. Der endgültige gemeinsame Workflowlauf und die tatsächliche Android-Prüfung werden separat belegt.
