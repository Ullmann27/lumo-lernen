# Zwei zusätzliche native Androidfälle für die unveränderte APK 2031

Basis der QA-Komponente: `51a3bfdedf4d6a745fb574ae9186c1094eb11abf`.
APK-Quelle: `e05a96a52aaf57e466e79831f15aaffd144284ee`, Native:
`678cb38fea3a83a7f5841e71fba9bb2f3bfa2eef`, Version `0.13.19+2031`.
Die Komponente enthält ausschließlich neue QA-, Test- und Belegdateien.
Keine bestehende Probe, Gate-, App-, Publisher- oder Workflowdatei wurde geändert.
Der laufende vollständige Replay wird hierdurch nicht verändert.

## Schnittstelle und sichtbare Wege

`run_native_cases(probe)` erhält eine bestehende `ReferenceProbe`-kompatible
Instanz mit bereits verifizierter unveränderter 2031-Installation und dem durch
UI angelegten fiktiven Klasse-1-Profil. Der tatsächlich sichtbare Start- und
Endbildschirm ist **LUMO AKADEMIE**. Es erfolgen keine Installation, kein Reset,
keine privaten Appdaten-Schreibzugriffe und keine Remoteaktion.

Das Ergebnis steht in `probe.result['native_runtime_cases']` und zusätzlich in
`native-runtime-cases.json` im vom Aufrufer bestimmten Belegverzeichnis. Der reine
`verify_native_cases(native_result, *, candidate)` wird am Ende selbst aufgerufen
und kann unverändert vom getrennten Einstieg erneut genutzt werden.

1. **Banane / Langsamer:** Der vorhandene geführte UI-Weg führt zu „Ba – na – ne“
   und zum vorhandenen 3D-Einstieg. Nach abgeschlossener Anfangswiedergabe wird
   das sichtbare Modell `0 / 3 bewegt` geprüft. Im tatsächlich geöffneten
   Fragepanel wird dessen Hintergrund aus aktuellen Pixeln ermittelt; Kopf und
   Zurück-Label sowie die sichtbaren Shortcuts begrenzen den Langsamer-Treffer.
   Zwei frische Targetbeobachtungen sind vor dem Tap nötig. Der unveränderte
   vorhandene `playback(..., segments=4)` verlangt vier neue geordnete
   Starts/Completions. Vorherige IDs erfüllen diesen Fall nicht. Nachher müssen
   das Fragepanel geschlossen, der Audioknopf wieder „Schritt anhören“ und das
   Modell weiterhin `0 / 3 bewegt` sein. Rückkehr zur gleichen sichtbaren
   Guided-Stufe und unveränderte Profil-/Lern-/Belohnungsdaten sind Pflicht.

2. **Bridge / laufende Stimme direkt stoppen:** Der vorhandene echte
   Warum-zwei-Frageweg bereitet eine längere Erklärung vor und beendet diese
   zunächst vollständig. Beim anschließenden neuen „Schritt anhören“-Auftrag
   muss eine neue gestartete, noch nicht abgeschlossene ID im tatsächlichen PID
   und richtigen Profil vorliegen. Das Fragepanel wird in diesem Stopfenster
   nicht geöffnet. Der Stopknopf wird auf zwei aktuellen Bildern beobachtet;
   PID/Profil/ID und verbleibende Frist werden währenddessen und unmittelbar vor
   dem einzigen direkten Tastendruck erneut geprüft. Verpasste Wiedergabe oder
   abgelaufene 45-Sekunden-Frist führen zum Fehler, ohne neuen Startversuch.
   Danach werden mindestens fünf Sekunden ohne neue Segmente oder Completion
   dieser ID, der sichtbare Rückwechsel zu „Schritt anhören“ und das unveränderte
   Modell `2 / 5 bewegt` verlangt. Der begrenzte Nachbeobachtungszeitraum wird
   protokolliert. Rückweg und Datenerhalt bleiben ebenfalls Pflicht.

Die Modellfelder bezeichnen die unabhängig vorher/nachher geprüften sichtbaren
Zähler und Aufgabenbeschriftungen; sie sind kein erfundener nativer Debugdump.
Alle Tastpunkte stammen aus aktuellen UI-/OCR-Beobachtungen. Historische
Fixturekoordinaten werden nie als neue Live-Eingabe verwendet. Bestehende
Aufnahme-, Dekodier-, positive Videodauer- und 180-Sekunden-Blockgrenzen gelten
unverändert weiter.

## Tatsächlich ausgeführte lokale Prüfung

`python3 -B -m unittest tools.android_qa.tests.test_nextgen_2031_native_runtime_cases -v`

Der abschließende Lauf in `host-tests-final.log` enthält **12 PASS, 0 FAIL,
0 SKIP**. Der frühere Neun-Test-Lauf ist separat erhalten; die Anzahlen werden
nicht addiert. Geprüft werden echte historische Start/Completion-Fixtures,
falsche PID/Profile/alte IDs, explizite aktuelle Hostfehler, Abschluss vor Tap,
Fristablauf, Folgeereignisse nach Tap, Panelbegrenzung, reale Beschriftungen,
positive Videodauer und der gemeinsame Ergebnisvertrag. Zeit- und ADB-Abläufe
in den Hosttests sind ausdrücklich simuliert. Die vier kleinen Originalfixtures
stammen aus der früheren 2029-Bridge-Diagnose und werden nur zum Prüfen des
Lesers verwendet. Ihre Provenienz und die getrennten exakten Quellzeilen stehen
unter `tools/android_qa/tests/fixtures/nextgen_native_runtime_2031/`.

## Unveränderte Nachweisgrenzen

**Hier wurde kein neuer Androidlauf ausgeführt.** Es gibt daher noch keinen
Geräte-PASS für diese beiden Fälle und keine zusätzliche Releasefreigabe.
Die MediaPlayer-Callbacks enthalten weder Rate noch gesprochene Wörter.
Die vier Segmente und `max(0.70, baseRate * 0.75)` sind an den gelesenen
Quellvertrag gebunden; eine akustische Verlangsamung oder Phonemqualität wird
nicht behauptet. Der Host veröffentlicht keinen eigenen Stop-Callback.
Auch bei einem späteren erfolgreichen Lauf beweist dieser Fall nur das
beschriebene begrenzte Callback-/UI-Fenster, keinen millisekundengenauen,
akustischen oder gemeinsam gemessenen Mund-/Gestenstopp. Die Videos haben
keine Tonspur. Originale frühere Fehlversuche bleiben unverändert.
