# Lernen, Tutor und ausdrückliche Freigaben

Fortsetzung am 3. Oktober 2026 auf dem gespeicherten PR-152-Stand.
Die historischen Prototypen wurden nicht als Anwendungscode übernommen.

## Umgesetzt

- Logik ist ein eigenes erreichbares Lernfach mit Mustern und Reihenfolgen
  ab Klasse 1, Zahlenmustern ab Klasse 2, Schlussfolgerungen ab Klasse 3
  und kombinierten Regeln in Klasse 4. Erzeugung, angezeigtes Fach,
  Antwortauswertung, Hinweise und gespeicherter Lernstand sind verbunden.
- Wiederholtes Antippen von Aufgabenhilfe liefert drei verschiedene Stufen.
  Die aktuelle Aufgabe bleibt dabei erhalten. Multiplikation und Division
  erhalten passende Gruppenhinweise. Brüche und sachliche Fragen werden
  nicht mehr irrtümlich als Plusaufgabe mit Äpfeln dargestellt.
- Ein tatsächlicher Generatorfehler wurde bei der Prüfung entdeckt:
  Bei bereits vier eigenen numerischen Antwortmöglichkeiten wurden weitere
  Zahlen angefügt. Diese konnten ebenfalls eine Logikregel erfüllen. Die
  Optionen bleiben jetzt bei vier; genau eine angebotene Antwort ist korrekt.
- Der Tutor hält lokale Aufgabenhilfe bei Providerfehlern sichtbar. Cloudhilfe
  ist an die gespeicherte Elternfreigabe für Aufgaben beziehungsweise Lesen
  gebunden, zusätzlich zur allgemeinen Onlinefreigabe. „Nur Chat“ startet
  weder Tutorhilfe noch neue Aufgabenbatches.
- Der KI-Test im Elternbereich sendet eine neutrale tatsächliche Aufgabe
  (3 + 4) im Kontext `learning_tutor`, ohne Namen oder reale Kinddaten.
  Eine erfolgreiche Healthantwort alleine bestätigt weiterhin keine Online-KI.
- Live, Live Pro, Lesebegleiter, Geschichten, Foto-Lektion, Lesen und Lumo-Fragen
  beachten gespeicherte Mikrofon-/Kameraeinstellungen. Mikrofoninitialisierung
  erfolgt nach Antippen. Hintergrundwechsel beendet laufende Aufnahmen;
  verspätete Aufnahmeereignisse greifen nicht auf entsorgte Listener zu.
- Live- und Geschichtenbilder senden keine ungefragten Sprach-/Storywörter
  mehr an den früher verwendeten Drittanbieter. Safari verwendet lokale
  Tierdarstellungen, Geschichten ein lokales Buchsymbol. Das ist noch keine
  neue hochwertige Szenenillustrationssammlung.
- Stummschalten beendet TTS und verwirft auch auf die TTS-Initialisierung
  wartende Sprechaufträge. Live-Pro-Mundbewegung verwendet den tatsächlichen
  Sprechstatus statt eines geschätzten Timers. Die separate Fuchsanimation
  wird in einem eigenen Arbeitsschritt überarbeitet.

## Tatsächliche Live-KI-Prüfung

Am 3. Oktober um 06:18 UTC wurde die Aufgabenanfrage ohne Kinddaten ausgeführt.
`/health` lieferte HTTP 200 und einen konfigurierten Schlüssel;
`/chat` lieferte HTTP 503 mit `openai_rate_limited`.

Der vorhandene Renderdienst wurde anschließend ausschließlich lesend geprüft.
URL, GitHub-Repository und `server/lumo-ai-proxy` stimmen überein. Er läuft
noch auf `main`-Commit `1e0eeaa7d0a78fcaf89977b47bf03826b56f34eb`, vor PR #152.
Die zeitlich passenden Anwendungslogs belegen `OpenAI returned 429` und
`/chat failed: openai_rate_limited`. Es wurde keine neue Instanz, kein Schlüssel
und keine Abrechnungseinstellung angelegt oder geändert.

Die vorhandene Livefassung prüft `provider.error.code`, protokolliert aber
keinen genauen Providerfehler. Der neue Servercode prüft zusätzlich
`provider.error.type == insufficient_quota` und unterscheidet das vom
vorübergehenden Anfragelimit. Diese Zuordnung wurde mit künstlichen
Providerantworten getestet; sie ist kein Beleg für den konkreten Kontostand.
Ein ausgeschöpftes Guthaben oder ein bestimmtes Token-/Anfragelimit lässt sich
aus den vorhandenen Logs nicht behaupten. Die Online-KI ist nicht bestätigt.

Belege ohne Geheimnisse und ohne echte Kinddaten:

- [Neutrale Tutor-Anfrage und Healthantwort](evidence/ai-neutral-tutor-live-2026-10-03.json)
- [Passendes Live-Deployment und Renderlogs](evidence/ai-render-live-2026-10-03.json)

## Prüfung

- Inhaltsaudit: 37.940 generierte Varianten aus allen vorhandenen Fächern
  und Klassen bestanden. Prüft richtige Rechenergebnisse, eindeutige Optionen,
  deklarierte Zahlenräume und mehrstufige Sachgeschichten; keine vollständige
  pädagogische Lehrplanabnahme.
- Neue Logikprüfung kontrolliert zusätzlich 1.400 Varianten, Zahlenabstände,
  kombinierte Regeln, Klassenverfügbarkeit, echte Aufgabenanzeige/-auswertung
  und gespeicherten Fortschritt nach erneutem Laden.
- Gezielte Flutterprüfungen decken Tutor, dreistufige Hilfe, Prüfungsmodus,
  KI-Freigaben/Transport/Diagnose, TTS-Mute und verweigerte Sensorfreigaben ab.
  38 Tests bestanden. Der umfassende APK-/Emulatorprüfstand folgt im Gesamtbericht.
- Node-Backend: 20 Regressionen bestanden; künstliche Providerantworten.
- Flutteranalyse: keine Fehler im geprüften gemeinsamen Zwischenstand;
  vorhandene Warnungen/Hinweise bleiben im Gesamtprojekt sichtbar.

Reale Mikrofonaufnahme, TTS-Stimmenqualität und Kamera wurden auf keinem
Galaxy Z Fold überprüft. Online-KI, echte Kontolimits und neue hochwertige
Geschichtenillustrationen bleiben offen. APK und Emulator werden separat geprüft.
