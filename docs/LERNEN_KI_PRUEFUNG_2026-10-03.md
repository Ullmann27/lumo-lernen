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
  Silben- und Lauthilfe verwenden das tatsächlich erfragte Wort, statt eine
  Silbenanzahl oder einen Lösungslaut als Wort darzustellen.
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
- Der redundante Fuchs über den Antwortflächen wurde entfernt. Der Begleiter
  bleibt auf seiner reservierten Fläche. Der Wortschreib-Coach beachtet auch
  die gespeicherte Einstellung für ruhige Animationen.

## Tatsächliche Live-KI-Prüfung vor dem Rollout

Am 3. Oktober um 06:18 UTC wurde die Aufgabenanfrage ohne Kinddaten ausgeführt.
`/health` lieferte HTTP 200 und einen konfigurierten Schlüssel;
`/chat` lieferte HTTP 503 mit `openai_rate_limited`.

Der vorhandene Renderdienst wurde anschließend zunächst ausschließlich lesend geprüft.
URL, GitHub-Repository und `server/lumo-ai-proxy` stimmen überein. Er läuft
zu diesem Prüfzeitpunkt auf `main`-Commit `1e0eeaa7d0a78fcaf89977b47bf03826b56f34eb`, vor PR #152.
Die zeitlich passenden Anwendungslogs belegen `OpenAI returned 429` und
`/chat failed: openai_rate_limited`. Es wurde keine neue Instanz, kein Schlüssel
und keine Abrechnungseinstellung angelegt oder geändert.

Diese damalige Livefassung prüft `provider.error.code`, protokolliert aber
keinen genauen Providerfehler. Der neue Servercode prüft zusätzlich
`provider.error.type == insufficient_quota` und unterscheidet das vom
vorübergehenden Anfragelimit. Diese Zuordnung wurde mit künstlichen
Providerantworten getestet; sie ist kein Beleg für den konkreten Kontostand.
Ein ausgeschöpftes Guthaben oder ein bestimmtes Token-/Anfragelimit lässt sich
aus den vorhandenen Logs nicht behaupten. Die Online-KI ist nicht bestätigt.

Belege ohne Geheimnisse und ohne echte Kinddaten:

- [Neutrale Tutor-Anfrage und Healthantwort](evidence/ai-neutral-tutor-live-2026-10-03.json)
- [Passendes Live-Deployment und Renderlogs](evidence/ai-render-live-2026-10-03.json)

## Aktueller Livezustand nach geprüftem Backend-Rollout

Ein kleiner separater Backend-Branch auf frischem `origin/main` wurde geprüft
und als [PR #155](https://github.com/Ullmann27/lumo-lernen/pull/155) übernommen.
Er ergänzt die Quota-Auswertung aus `error.type` und sichere Diagnoselogs
mit einer festen Liste bekannter `code`-/`type`-Werte. Unbekannte Werte werden
als `other`, fehlende als `absent` protokolliert. Es werden keine Provider-
Rohantworten, Fehlermeldungen, Schlüssel oder Kinddaten protokolliert.
Das bisherige automatische Veröffentlichen der alten APK auf `main`-Push
wurde im selben PR auf manuellen Workflowstart begrenzt; dies veröffentlicht
keine neue APK. Im Flutter-Featurebranch wurde nur der Backend-Diagnosepatch
übernommen, dessen eigener APK-Workflow bleibt erhalten.

Der bestehende Renderdienst deployte automatisch exakt den Merge-Commit
`fcca1f372ea24ea5a5057d79688cc8e0f2ad7c06` und wurde um 07:11:23 UTC live
(Deployment `dep-db0aktnf3r2c73asf17g`). Host, Modell `gpt-6-luna`, Secrets
und Tarif wurden nicht verändert. Es wurde kein zweiter Dienst angelegt.

Eine neue neutrale Tutor-Anfrage zu `3 + 4` wurde um 07:12:50 UTC ausgeführt.
Sie erhielt HTTP 503 mit `reason: openai_quota_exceeded`. Das zeitlich passende
Renderlog lautet um 07:12:51.463823719 UTC:

```text
[lumo-ai-proxy] OpenAI error status=429 code=other type=insufficient_quota
```

Damit ist eine Quota-Ablehnung des bestehenden Provider-Projekts jetzt live
belegt. Der konkrete Kontostand oder eine Abrechnungshöhe wurden nicht
abgerufen. `code=other` wird nicht als tatsächlicher Providercode ausgegeben;
der beobachtete, erlaubte Typ lautet ausdrücklich `insufficient_quota`.
Die Healthantwort danach meldet `upstreamStatus: openai_quota_exceeded`.
Ein erfolgreicher Tutor-Inhalt wurde weiterhin nicht geliefert. Online-KI
bleibt daher blockiert, lokale Aufgabenhilfe bleibt nutzbar. Die fehlende
Voraussetzung ist verfügbare Quota im vorhandenen Provider-Projekt; es wurden
keine kostenpflichtigen Änderungen oder neue Zugangsdaten eingerichtet.

- [Neue neutrale Anfrage mit Health vor/nach dem Rollout](evidence/ai-neutral-tutor-after-rollout-2026-10-03.json)
- [Exakte Deployment-SHA und neue Providerlogs](evidence/ai-render-after-rollout-2026-10-03.json)

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
  Nach der Korrektur von Wortvisualisierung und Fuchsplatzierung bestanden
  zusätzlich alle 25 ausgeführten Tutor-/Aufgabenhilfe-/Schreibprüfungen.
- Node-Backend: nach dem Diagnosepatch 22 Regressionen auf Node 24.19.0
  bestanden; künstliche Providerantworten einschließlich Tutor-/Batch-Quota,
  Token-/Anfragelimit, unerwarteten Labels und Nicht-JSON-Rohantworten.
  Der minimale ausgerollte `main`-Backendstand bestand alle dortigen 11 Tests.
- Flutteranalyse: keine Fehler im geprüften gemeinsamen Zwischenstand;
  vorhandene Warnungen/Hinweise bleiben im Gesamtprojekt sichtbar.

Reale Mikrofonaufnahme, TTS-Stimmenqualität und Kamera wurden auf keinem
Galaxy Z Fold überprüft. Online-KI bleibt wegen der live belegten Provider-Quota
blockiert; genaue Kontodetails und neue hochwertige Geschichtenillustrationen
bleiben offen. APK und Emulator werden separat geprüft.
