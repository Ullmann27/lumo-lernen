# Lumo: Lernfuchs, Aufgaben, Eltern-PIN und APK

Stand: 2. Oktober 2026. Fortsetzung auf PR #152 und
`codex/lumo-school-readiness-followup-2026-10-02`. Vorher ausgelieferte APK:
[school-test-270](https://github.com/Ullmann27/lumo-lernen/releases/tag/school-test-270).
Alle 19 historischen Projektdateien bleiben unverändert archiviert.

## Umsetzung

- Der Fuchs ist im echten AppShell und Lehrerbildschirm angeschlossen. Vollständige
  Original-Sprites ersetzen abgeschnittene Frames. Eased Bewegung, passende
  Lauf-/Ruheanimation, Bodenlinie und kurze Wendepause vermeiden Sprünge und
  abruptes Spiegeln. Die reservierte Laufzone verdeckt keine Antworten/Navigation.
  Der bisherige Home-Rundgang öffnet jetzt dieselbe App-Erklärung.
- Eigeninitiative verwendet lokal gespeicherte Aufgabenversuche: passende Themen,
  Hilfe nach Fehlern und Pausenideen. Das Kind nimmt Vorschläge freiwillig an.
  Keine Behauptung eines eigenen Bewusstseins; die Initiative ist lokale Logik.
  Ruhige Animation, Hintergrund, modale Dialoge und Schularbeiten werden beachtet.
- Aufgabenhilfe bleibt bei der aktuellen Aufgabe. Lernfragen öffnen einen Dialog,
  ohne Aufgabe und Eingabe zu ersetzen. Mikrofonzugriff erst nach Antippen.
  Schularbeiten verraten keine Lösungen über den Begleiter.
- Mathematik, Deutsch, Rechtschreibung, Lesen, Schreiben, Englisch und Sachunterricht
  erhalten korrigierte Inhalte und tatsächlich erreichbare Themen der Klassen 1–4.
  Antwortprüfung und Anzeige verwenden dieselbe qualitätsgeprüfte Aufgabe.
  Laut und Buchstabe werden unterschieden (Hund: Auslaut T, letzter Buchstabe D).
- 48 echte Schreibvorlagen (A–Z, 0–20, Wellenlinie) ersetzen Ersatzformen.
  Strichverlauf und Abdeckung werden geprüft. Freies Schreiben wird ausdrücklich
  nicht als automatische Richtig/Falsch-Bewertung ausgegeben.
- Bestehende individuelle Eltern-PINs bleiben erhalten. Alte unveränderte Standard-PIN
  ist 2468. Bei noch nicht eingerichteter PIN wird eine eigene PIN eingerichtet und
  ein einmalig gezeigter Wiederherstellungscode angeboten; gespeichert wird dessen
  Hash. Kein universeller Umgehungscode für individuelle PINs.
- Die angeforderte KI-Freigabe wird in diesem APK-Build einmalig gesetzt. Ein späteres
  Ausschalten durch Eltern bleibt erhalten. Kindname/ungeprüfte Persona werden nicht
  an den KI-Proxy geschickt. Nur erfolgreiche echte Providerantworten gelten als online.
- APK wird optimiert im Release-Modus gebaut. Das Repository-Zertifikat wird
  explizit im Gradle-Bau gesetzt und die fertige APK damit verglichen.
  Optionale nicht gebündelte MLKit-Sprachklassen erhalten gezielte R8-Regeln.
- Prüfung der wirklich ausgelieferten APK 270 zeigte einen abweichenden Signierer:
  SHA-256 edff8e83e12993fbdf0e054bda44949269ea69f1949c7ccafc1ecd47a1735b74.
  Das Repository-Zertifikat hat a6b1ef61bf59db4e0794c742aeb3b5506d130f4d21175c9975140e6acdb80702.
  Das frühere bloße Kopieren nach HOME/.android garantierte den verwendeten
  Schlüssel nicht. Der private Schlüssel von 270 liegt hier nicht vor.
  Deshalb gibt es zusätzlich Lumo-Lernen-Neu.apk mit eigener Paketkennung
  dev.ullmann.lumo.lumo_lernen.coachpreview und Name „Lumo Lernen Neu“.
  Sie installiert parallel, ohne alte App/Daten zu löschen; Lernstände werden
  nicht automatisch übernommen. Die alte App für den Test nicht deinstallieren.
  Die normale Lumo-Lernen-latest.apk behält die ursprüngliche Paketkennung,
  kann Build 270 wegen der Signatur aber nicht direkt aktualisieren.
  Beide Varianten wählen künftig nur APK-Assets ihrer eigenen Paketkennung.

## Live-KI: noch offen

Öffentlicher Health-Endpunkt erreichbar, Schlüssel konfiguriert, gemeldetes Modell
`gpt-6-luna`. Neutraler Chat-Aufruf ohne Kinddaten: HTTP 503,
`openai_rate_limited`. Dies belegt weder erschöpftes Guthaben noch den konkreten
Kontogrenzwert. Live-Backend ist älter als der überarbeitete Servercode.

Render verlangt vor Kontozugriff eine ausdrückliche Workspace-Wahl durch den Nutzer.
Angeboten wurde `My Workspace`; Auswahl steht noch aus. Kein Deployment und keine
Änderung an Render/Provider-Konto. Die App-Freigabe allein beseitigt das externe
Limit nicht. Hinweise und Vorschläge sind auch offline verfügbar.

## Prüfung und Übergabe

- Inhaltsaudit: 37.540 erzeugte Aufgabenvarianten geprüft.
- Node-Backend: 19 Regressionstests bestanden (simulierte Providerantworten).
- Android-Vorbereitung und Verifikationsaufruf: 4 Python-Tests bestanden.
  Signaturen werden direkt über Androids ApkVerifier-API und DER-Zertifikate
  geprüft, ohne CLI-Ausgabetext zu interpretieren. Echte APK-Gegenprobe:
  Kopie mit Repository-Schlüssel akzeptiert, ursprüngliche APK 270 abgewiesen.
- Repair Guard und `git diff --check`: bestanden.
- Vollständige Flutter-Suite in CI #950: 376 bestanden, 4 zuvor übersprungen, keine Fehler.
- Flutter-Analyse: 0 Fehler; vorhandene Warnungen/Hinweise bleiben sichtbar.
- Abschließender CI-APK-Bau: Ergebnis wird in PR #152 und im Release protokolliert.
- Layouttest verwendet echte AppShell und prüft 360×740, 840×560 und 280×640,
  Navigation, freiwillige Erklärung sowie die vollständig sichtbare Fuchsfläche.
- Android-Gerätetest (Installation, reale Bildrate, Mikrofon, Kamera, Godot-App)
  und pädagogischer Unterrichtstest stehen weiterhin aus.
- Vier bereits im Ausgangsstand übersprungene Flutter-Tests bleiben sichtbar.

Sicherheitsfund: Ein alter GitHub-PAT stand in CODEX_BRIEFING.md und wurde aus dem
aktuellen Text entfernt, ohne ihn zu verwenden. Das löscht keine Git-Historie.
Der Kontoinhaber muss diesen öffentlich gewordenen Schlüssel widerrufen.
