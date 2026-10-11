# Lumo Stimme: Originalwiedergabe, Pause und sichere Sprachgrenzen

Dieser Meilenstein erweitert die vorhandene Lern-App und die vorhandene Stimme.
Er ist ausdrücklich keine vollständige appweite Hörabnahme, kein neuer
Sprachprovider und keine produktive Serverbereitstellung. Die Lernmodul-UI aus
Produktcommit `91388c3b463f4dae4590cdf76251d531259d8a0a` bleibt erhalten.

## Quellstand und überprüfbarer Nutzen

Produktcommit `f4c32c5e46c90103160c584f35723a068af7320d`, eigener Arbeitsbranch
`computer/lumo-education-excellence-2026-10-11`, aufbauend auf dem gesicherten
Lernmodul-Stand `5f2f32f09abce3750c02d3a532217479329944a3`.
Die vorhandene PR-255-Entwicklung
`1dd6a3f7e1ea4b8b1258dd39ad64b91b95228ea4` bleibt die Grundlage der zentralen
Sulafat-Klasse und des Servers. Kein Main-Merge und keine neue KI-/Lerndatenbank.

- **Abgeschnittenes Feedback:** Vor der Reparatur stoppte ein nicht verfügbarer
  Folgesatz die gerade laufende Originalaufnahme. Der tatsächliche Vorher-Test
  erhielt einen zusätzlichen nativen `stop` und scheiterte. Die Verfügbarkeitsprüfung
  findet jetzt vor dem Austausch des spielenden Audiopfads statt; ein fehlender
  Satz bleibt sichtbar als Fehler, ohne Lob oder Begrüßung abzuschneiden.
- **Unveränderte Offline-Freigabe:** Ein erneutes Speichern von
  `cloudVoiceEnabled: false` beendet die Original-Stimmprobe nicht mehr.
  Eine wirkliche Rücknahme zuvor erteilter Online-Freigabe stoppt weiterhin.
- **Pause und Fortsetzung:** Der zentrale native Player pausiert dieselbe
  Quelle und setzt deren Position fort. Kein erneutes Laden, keine neue Synthese,
  kein Mikrofonstart. Das Zeitlimit zählt aktive Wiedergabe statt Pausenzeit;
  verzögerte native Rückmeldungen dürfen eine stummgeschaltete Quelle nicht
  wiederbeleben oder die nächste Aufnahme pausieren.
- **Sichtbare Bedienung:** Im vorhandenen Elternbereich unter „Ton und Stimme“
  sowie im bestehenden Lumo-Erklärungsblatt gibt es Pause, Fortsetzen und Stopp.
  Die neuen Tasten haben mindestens 48 logische Pixel Höhe. Fehlt die Stimme,
  bleibt der Text sichtbar und das Erklärungsblatt nennt den Zustand kindgerecht.
- **Keine fingierte Vollständigkeit:** Bestätigte native Starts und
  native Abschlussereignisse sind getrennte Zähler. Ein Watchdog-Abbruch
  zählt niemals als bestätigte vollständige Wiedergabe.
- **Kein Upload durch einen einfachen Schalter:** Auch bei eingeschaltetem
  `cloudVoiceEnabled` bleibt ein dynamischer Lerntext lokal, solange kein
  Elternsession-Anschluss vorhanden ist oder dieser keinen geeigneten
  Autorisierungstoken liefert. Der Client prüft vor Erstellung einer
  HTTP-Verbindung; die zentrale Stimme prüft außerdem vor dem Abschneiden
  bereits laufender Originalaufnahmen. Ein verzögert zurückgegebener Zugang
  nach Navigation darf keinen alten Lerntext senden.
  Tokens werden weder ins APK eingebaut noch in `AppSettings` gespeichert.
  Der neue Callback ist ausdrücklich noch keine echte Elternanmeldung;
  die serverseitige Prüfung von Identität, Gültigkeit, Zweckbindung und
  unabhängiger Sprachfreigabe bleibt zwingend.
- **Originaltreue:** Alle sechs ausgelieferten M4A-Dateien behalten ihren
  überprüften SHA-256. Die übrigen festen Lob-, Begrüßungs- und Trostformulierungen
  erhalten ausschließlich passende semantische Aliase auf diese Originale.
  Das sind keine neuen Aufnahmen und keine wörtliche Vertonung aller Textvarianten.
  Variable Unterrichtserklärungen werden ausdrücklich nicht durch allgemeines
  Lob als angeblich gesprochene Erklärung ersetzt.

## Tatsächlicher produktiver Serverzustand

Am 11. Oktober 2026 wurden ausschließlich unberechnete Proben ohne Kindertexte
ausgeführt. Nach einem fehlgeschlagenen öffentlichen Fetch wurde zulässig
mit HTTP direkt geprüft; keine gültige Synthese und keine Gebühren ausgelöst.

- **Health:** Die [Dienstdiagnose](https://lumo-ai-proxy.onrender.com/health) ergibt HTTP 200,
  Version `2026-10-02-restart`. Ein vorhandener OpenAI-Schlüssel ist keine
  Bestätigung einer funktionierenden Sulafat-Stimme.
- **Sprachdiagnose:** Der [Sulafat-Diagnosepfad](https://lumo-ai-proxy.onrender.com/speech/status)
  ergibt HTTP 404, Body `{"error":"not_found","path":"/speech/status"}`.
- **Sprachroute:** Die [Sprachschnittstelle](https://lumo-ai-proxy.onrender.com/speech) mit dem
  absichtlich ungültigen leeren Body `{}` ergibt HTTP 404,
  Body `{"error":"not_found","path":"/speech"}`.
- **Geschützter Zugriff:** Die Render-Verbindung wurde angefordert, ist aber
  bislang nicht verbunden. Keine Serverkonfiguration, Secrets, Zahlung oder
  produktive Bereitstellung wurden geändert.

Der vorhandene Quellserver benötigt zusätzlich eine wirkliche Elternautorisierung.
Flags und Provider-Schlüssel allein sind jetzt sicher gesperrt. Der neue
`authorizeSpeech`-Anschluss ist mit lokalen Fakes geprüft, aber ein realer
Identitätsverifizierer und Token-Ausstellung sind noch nicht vorhanden.
Der Flutter-Sessionanschluss wird ohne solchen Zugang nicht aktiviert.
Die übrigen bestehenden Chat-/Aufgabenpfade sind nicht durch
diese Änderung pauschal als abgesichert freigegeben.

## Sprachmatrix und echte Audiodateien

`test/lumo_speech_matrix_test.dart` führt 50 unterschiedliche Texte aus der
vorhandenen Phrasenbibliothek und vorhandenen Lernmodulen durch die tatsächliche
zentrale `LumoVoice`-Klasse. Native Audioantworten sind dabei ausdrücklich
MethodChannel-Mocks, nicht ein Android-Lautsprecher oder Decoder.

Das erste vollständige Matrixresultat enthält **34 Original-Routen** und
**16 fehlende passende Offline-Aufnahmen**, bei **null Netzwerkversuchen**.
Die 34 Routen verwenden wiederholt dieselben sechs Originalclips; die JSON-Matrix
nennt angeforderten Text, tatsächlich aufgezeichneten Text, wörtliche Gleichheit,
Asset, SHA und die fehlende Android-Hörabnahme. 50 bestandene Routingfälle
werden nicht als 50 erfolgreich gehörte Sprachsituationen ausgegeben.

Alle sechs echten M4A-Dateien wurden vollständig mit FFmpeg dekodiert.
Sie enthalten AAC, 96 kHz, einen Kanal und keine dekodierten Full-Scale-Samples.
Die lokale WAV-Hörprobe reiht deren unveränderte dekodierte Signale aneinander;
sie ist keine App-Aufnahme, keine neue Synthese und kein Beweis für Mobilwiedergabe.

| Original | Abschnitt der gemeinsamen Hörprobe | Aufgezeichneter Inhalt |
|---|---|---|
| `c3034465f7dd` | 0,000–6,379 s | Hallo! Schön, dass du da bist. Ich bin Lumo. Komm, wir entdecken zusammen etwas Neues! |
| `341f8117fda1` | 6,379–9,195 s | Super! Das hast du toll gemacht! |
| `a3e9510a5f01` | 9,195–11,296 s | Fast! Schau nochmal. |
| `19495758a130` | 11,296–15,189 s | Du schaffst das! Wir probieren es gemeinsam. |
| `06e26a73d0b4` | 15,189–19,851 s | Vier gewinnt! Du spielst mit Cyan, Lumo mit Gold. Du fängst an! |
| `b79005f3d3d8` | 19,851–23,989 s | Du bist dran! Schau mal, wo dein Stein am besten passt. |

Eine zusätzliche automatisierte Blindtranskription ohne erwarteten Text erkannte
alle sechs Inhalte. Sie ersetzt weder eine menschliche Qualitätsfreigabe noch
eine Android-Hörprüfung. Die ungefähren Zeitmarken des ersten, textgestützten
Audioevaluators waren ungenau; maßgeblich sind deshalb ausschließlich die oben
aus tatsächlichen PCM-Samplezahlen berechneten Abschnittsgrenzen.

## Tatsächlich bestandene Prüfungen

- **Gezielte Flutter-Prüfung:** 67 bestandene Fälle für Stimme, native
  Steuerung, HTTP-Fehler, keine alte TTS, Kontext/Gespräch und bestehenden
  Companion. Die Tests zur fehlenden Audioverfügbarkeit stammen aus einer
  echten zunächst roten Regression, nicht aus deaktivierten Prüfungen.
- **50er-Matrix:** 51 bestandene Testfälle einschließlich Matrix-Vollständigkeit;
  die 50 Szenarien enthalten ausdrücklich 16 absichtlich stumme fehlende
  Originaltexte. Zwei Diagnosefälle trennen fehlende Route und fehlende
  Elternautorisierung von einer Hörprüfung.
- **Backend:** 35 bestandene lokale Node-Fälle. Auch der Provider ist ein
  Fake mit Prüf-PCM; kein Live-Sulafat und keine echten Gebühren.
  Ungültige Identitäten, fehlende Sprachfreigabe, Premium statt Einwilligung,
  ungültige Headers, Verifiziererfehler und konkurrierende Budgetanfragen
  werden geprüft.
- **Inhaltsbaseline:** Das unveränderte vorhandene `scripts/audit_content.dart`
  prüfte 40.960 generierte Aufgaben erfolgreich auf seine bestehenden
  Rechen-, Auswahl-, Zahlenraum- und Qualitätsbedingungen. Das beweist keine
  vollständige Lehrplanabdeckung oder externe fachliche Begutachtung.
- **Sprachbedienung:** Vier aktuelle UI-Fälle bestanden. Der tatsächliche
  Elternknopf startet die Originalaufnahme, Pause und Fortsetzung bedienen
  dieselbe zentrale Playerquelle, die Fortsetzung erzeugt keinen neuen Start.
  Die sechs veröffentlichten Elternbilder zeigen Smartphone, Fold und Tablet
  in laufendem und pausiertem Zustand. Sämtliche Bedienknöpfe bleiben vollständig
  im geprüften Ausschnitt; die neuen Audio-Tasten sind mindestens 48 logische
  Pixel hoch. Der vierte Fall ist zusätzlich eine isolierte Layoutprüfung des
  fehlenden-Audio-Hinweises bei 320 Pixeln und doppelter Schrift, keine Aufnahme
  eines vollständigen Kinderbildschirms.
- **Vollständige Nachher-Suite:** 1.073 bestandene Flutter-Tests,
  107 unverändert übersprungene Fälle, null Fehler. Die Skips enthalten die
  bereits separat ausgeführten optionalen Lernbild-Capture-Cases; sie werden
  nicht als neue bestandene Sprach- oder Gerätetests gezählt.
- **Analyse:** Gesamtanalyse ohne Errors und Warnings; 17 bestehende
  Info-Lints bleiben sichtbar. Die erste vollständig bestandene Suite vor
  der zusätzlichen Client-Uploadsperre hatte 1.065 Erfolge; nur der erneute
  1.073er-Lauf wird als aktueller Nachher-Nachweis verwendet.
- **Unveränderte Speichergrenzen:** App-Zustand, Modul-Fortschrittsgrenze,
  Profil-/Einstellungsspeicher, Android-Dateien, Paket-/Versionskonfiguration
  und alle sechs Sprach-Binärdateien sind gegenüber dem gesicherten
  Lernmodul-Meilenstein unverändert. Kein Kinderprofil wurde zurückgesetzt.

Die früheren Fehlerprotokolle bleiben erhalten. Der erste Capture-Lauf
scheiterte an der Fixture mit zeitabhängiger nativer Initialisierung; diese
wurde im echten Test-Ereignisloop vorbereitet und der tatsächlich gespeicherte
Stimmenzustand eingerichtet. Ein erster Folgelauf deckte zusätzlich einen zu
früh geprüften asynchronen Hinweis auf. Ein späterer gezielter Aufruf nannte
drei nicht existierende Testpfade; der Fehler wurde am Aufruf repariert,
nicht durch Entfernen bestehender Tests. Die tatsächliche Nachher-Suite ist
danach vollständig erneut ausgeführt worden.

## Nachweise und weiterhin offene Abnahme

Die PNGs unter `screenshots/` stammen aus Flutter 3.44.9/Linux und dem
tatsächlichen bestehenden `SettingsContent`-Widget. Der native Audiovertrag
ist gemockt. Kein Screenshot beweist, dass ein Kind die Aufnahme auf einem
Android-Gerät gehört hat; die dort sichtbaren nativen Zähler sind Testwerte.
`LAUFZEIT-NACHWEIS.json` nennt Quellcommit, Dateihashes, Viewport und
Pixelabmessungen. Keine Retusche und keine generierten Beweisbilder.

Der physische Fold-Zielviewport ist 2.176 × 1.812 bei Dichte 2,25. Die
Testbilder verwenden Rasterfaktor 2 und sind deshalb nicht mit einem
Screenshot vom tatsächlichen Samsung-Gerät gleichzusetzen. Smartphone:
360 × 800 logische Pixel; Tablet: 1.024 × 768 logische Pixel.

| Vorhandener Elternbildschirm | Wiedergabe | Pause |
|---|---|---|
| Smartphone | [Laufender Originalclip](screenshots/sulafat-playing-phone-360x800.png) | [Fortsetzen sichtbar](screenshots/sulafat-paused-phone-360x800.png) |
| Fold-Zielviewport | [Laufender Originalclip](screenshots/sulafat-playing-fold-2176x1812-density-225.png) | [Fortsetzen sichtbar](screenshots/sulafat-paused-fold-2176x1812-density-225.png) |
| Tablet | [Laufender Originalclip](screenshots/sulafat-playing-tablet-1024x768.png) | [Fortsetzen sichtbar](screenshots/sulafat-paused-tablet-1024x768.png) |

`Sulafat-50-Situationen.json` unterscheidet für jede Zeile Originalroute,
aufgezeichneten Wortlaut, Alias statt wörtlicher Wiedergabe und fehlende
Android-/Online-Abnahme. `audio-files-audit.json` belegt Decoder, Samplezahlen,
SHA-256 und Abschnittsgrenzen der unveränderten Originale. Die Hörprobe
`Lumo-Sulafat-Originalaufnahmen-Hoerprobe.wav` enthält ausschließlich diese
sechs vorhandenen Aufnahmen; sie ist kein Mitschnitt des neuen App-Builds.

- **Serverzugang:** Render ist noch nicht verbunden. Keine produktive
  Konfiguration oder Bereitstellung vorgenommen.
- **Elternanmeldung:** Ein realer verifizierter Sessionanbieter einschließlich
  Token-Ausstellung, Gültigkeit, Zweck-/Serverbindung, Widerruf und eigenständiger
  Spracheinwilligung muss noch angeschlossen und interaktiv geprüft werden.
  Ein Premium-Abonnement ist ausdrücklich kein Ersatz dafür.
- **Sprachabnahme:** 50 tatsächlich erzeugte beziehungsweise passende lokal
  vorhandene und auf Android gehörte Situationen sind noch nicht abgenommen.
  Aktuell fehlen 16 passende Offline-Texte bereits in der Routingmatrix.
- **Android:** Keine neue APK/AAB, keine Installation dieses Commits, kein
  physischer Samsung-Lauf, kein erneuter Update-/Netzwechsel-/Langzeittest
  und keine gemessenen 60 FPS.
- **Gesamtprodukt:** Der neue aktive Lernbegleiter für die direkten Lernmodule,
  getrenntes Vorlernen, geführter Unterricht, vollständiger Lehrplan-/Inhaltsaudit,
  Datenschutz-/Play-Abnahme und externe österreichische Pädagogenprüfung
  sind durch diesen Sprach-Meilenstein nicht erledigt.

## Sofortige Fortsetzung

Zunächst GitHub-Checks des gesicherten Produkt-/Nachweisstandes prüfen.
Dann die geschützte Render-Konfiguration und die reale Elternautorisierung
prüfen, ohne eine kostenpflichtige Synthese oder öffentliche Bereitstellung
ohne spezifische Freigabe auszulösen. Offline-Lücken bleiben sichtbar.

Danach am vorhandenen Companion-Request-Bus tatsächliche Lernereignisse
anschließen und freiwilliges Vorlernen sowie geführten Unterricht in der
bestehenden Lern-App implementieren. Klassenfortschritt, Profile und
Belohnungspersistenz bleiben geschützt. Große neue Kart-Erweiterungen sind
weiter nachrangig; bestehender Godot-Pin und APK 1928 wurden hier nicht verändert.

## Reproduzierbare lokale Prüfung

```sh
flutter test --no-pub --reporter expanded
flutter analyze --no-pub --no-fatal-infos
(cd server/lumo-ai-proxy && node --test)

LUMO_AUDIT_SOURCE_COMMIT=f4c32c5e46c90103160c584f35723a068af7320d \
LUMO_SPEECH_AUDIT_DIR=/tmp/lumo-speech-matrix \
LUMO_POLISH_CAPTURES=/tmp/lumo-speech-images \
flutter test --no-pub --reporter expanded \
  test/lumo_speech_matrix_test.dart \
  test/lumo_speech_readiness_test.dart \
  test/design/lumo_sulafat_controls_capture_test.dart
```

Alle diese Testaufrufe verwenden Mocks beziehungsweise lokale Testserver,
keinen kostenpflichtigen Provider. Auf einem lokalen vollen Datenträger
zusätzlich einen ausreichenden `TMPDIR` für den Flutter-Compiler verwenden.

## Betroffene Produkt- und Testdateien

- **Zentrale Stimme:** `lib/core/lumo_voice.dart`,
  `lib/core/lumo_sulafat_client.dart`, `lib/core/lumo_speech_readiness.dart`,
  `lib/core/lumo_conversation_controller.dart`.
- **Bestehende Oberfläche:** `lib/features/settings/settings_content.dart`,
  `lib/features/settings/lumo_voice_diagnostics_card.dart`,
  `lib/widgets/fox/lumo_free_companion.dart`,
  neuer wiederverwendeter Baustein `lib/widgets/lumo_speech_controls.dart`.
- **Originalkatalog:** `assets/audio/voice/lumo/catalog.json`;
  ausschließlich zusätzliche semantische Aliase, keine geänderten Audiodateien.
- **Vorhandener Server:** `server/lumo-ai-proxy/src/server.js`,
  `server/lumo-ai-proxy/test/sulafatTts.test.js`,
  `server/lumo-ai-proxy/README.md`.
- **Flutter-Prüfung:** `test/lumo_voice_clips_test.dart`,
  `test/lumo_sulafat_client_test.dart`, `test/lumo_speech_readiness_test.dart`,
  `test/lumo_speech_matrix_test.dart`,
  `test/helpers/lumo_native_audio_harness.dart`,
  `test/design/lumo_sulafat_controls_capture_test.dart`.
- **Vorhandene CI:** `.github/workflows/lumo-sulafat-ci.yml`;
  eigener Branch ergänzt, bestehender Sulafat-Branch erhalten.
