# Lumo 1927: Sulafat, Aufgaben-Kontext und sichere Dialoge

Technische Testversion, kein Nachweis einer vollständig freigeschalteten
Online-Stimme. Sie baut auf der ausgelieferten Version 1926 und dem geprüften
Grafik-Grundgerüst auf; bestehende Lern-, Schreib-, Cards- und Kart-Funktionen
werden nicht neu implementiert.

## Ausgangsstand und überprüfbare Grenzen

Der [Test-Release 1926](https://github.com/Ullmann27/lumo-lernen/releases/tag/lumo-0.12.19-1926-sulafat-test)
enthält sechs Sulafat-Originalaufnahmen; dynamische Sprachausgabe und die
52 neuen Godot-Aufnahmen waren dort ausdrücklich noch nicht fertig aktiviert.
Die vorbereiteten Änderungen aus [PR 255](https://github.com/Ullmann27/lumo-lernen/pull/255)
und [Godot PR 48](https://github.com/Ullmann27/lumo-godot/pull/48) sind keine
Bestätigung einer erfolgreich deployten oder akustisch geprüften Stimme.

Der unabhängig untersuchte Release-APK 1926 hat:

- Paket: `dev.ullmann.lumo.lumo_lernen.coachpreview`.
- Version: `0.12.19`, versionCode `1926`, targetSdk `36`.
- Gültige APK-v2-Signatur, Zertifikat SHA-256:
  `a6b1ef61bf59db4e0794c742aeb3b5506d130f4d21175c9975140e6acdb80702`.
- APK SHA-256:
  `9dfd5f58a8879b3fa95b505ad92bc9cb20ee433298c92797404d3f588c38b1f4`.
- Stimmprobe `c3034465f7dd.m4a` SHA-256:
  `ac64224d3db9cfb34130606ec737a17dd0107debd80182c33c1bc641809929ef`.

Die Original-Stimmprobe im aktuellen Quellcode ist bytegleich mit dieser
Datei im Release-APK. Das ist ein Dateivergleich, kein Hörerlebnis-Nachweis.
Es wurde nicht festgestellt, welche App auf einem physischen Samsung
tatsächlich installiert oder geöffnet ist.

## Tatsächlich implementiert

- **Voice Provider:** Feste Sulafat-Sprecheridentität, festes Referenzprofil und
  Referenzmodell `gemini-2.5-pro-preview-tts`, unveränderte Original-Stimmprobe.
  Keine Android-TTS-Auswahl, keine alternative Stimme bei Ausfall.
- **Audio:** Strikte RIFF-/PCM-Validierung einschließlich Metadaten-Chunks,
  begrenzte Antwortgröße, echte HTTP-Abbrüche und serialisierte native
  Wiedergabevorbereitung ohne blockierendes Stummschalten.
- **Animation:** Mundöffnung aus tatsächlichem Audiopegel und nativer
  Wiedergabeposition; keine erfundenen Wortereignisse oder Sinuskurve für
  dynamische Sprachausgabe. Vorhandene Lumo-Figur und Ausdruckssteuerung bleiben.
- **Context Engine:** Adapter über bestehenden App-Zustand und Aufgaben-Bus.
  Sichtbarer Aufgabentext, echte Versuche, letzte geprüfte Eingabe, Ergebnis,
  Hilfestufe, vorherige Hilfe und aktueller Lesesatz werden übernommen.
  Richtige Lösung, Profilidentität und Touch-Koordinaten sind keine Cloud-Felder.
- **Interaction Bus:** Bestehender `LumoCompanionRequests` wird weiterverwendet.
  Maximal zwölf semantische Ereignisse bleiben lokal im RAM; keine Übertragung
  jeder Berührung.
- **Conversation Controller:** Vier Dialogwechsel im RAM, kontextbezogene
  lokale Hilfe über vorhandene Pädagogik, unterbrechbare Online-Anfrage,
  Abbruch bei Aufgaben-, Profil-, Bildschirm- oder Freigabewechsel sowie Pause.
  Kein Zugriff auf Sterne, XP, Lernabschluss oder automatische Navigation.
- **Privacy:** Bestehende differenzierte Elternfreigaben gelten weiterhin.
  Chat-only gibt keine Aufgabeninhalte frei. Tests/Schularbeiten erlauben
  keine Cloud-Hilfe. Private und zu lange Fragen werden nicht im Dialog gespeichert.
- **Mikrofon:** Gemeinsame explizit gestartete Spracheingabe für Dialog und
  Live-Modul. Auf Android ist lokale Erkennung Voraussetzung; fehlt sie,
  startet kein stiller Cloud-Ersatz. Das Mikrofon wird nicht nach Antworten
  automatisch geöffnet.
- **Eltern-Diagnose:** Paket, Build, Android-API und Zertifikatsfingerabdruck
  werden aus der aktuell laufenden Android-App gelesen. Eine separate,
  kostenfreie Sulafat-Konfigurationsprüfung verwechselt KI-Erreichbarkeit
  nicht mit erfolgreich hörbarer Sprache. Ein RAM-Zähler bestätigt neue native
  Wiedergabestarts, damit eine historische Quellenanzeige keinen fehlgeschlagenen
  Stimmentest kaschiert. Tempo zwischen 0,70 und 1,60 wird an den Player übergeben.
- **Backend:** `/speech/status`, festes Profil, strenge PCM-Prüfung,
  Provider-Abbruch bei Client-Abbruch und minimaler Aufgaben-Kontext. Eine
  konfigurierte API wird ausdrücklich nicht als akustisch verifiziert bezeichnet.

## Noch offene Freigabe- und Abnahmeschritte

- Sichere Bereitstellung des Gemini-TTS-Zugangs; Schlüssel niemals in APK,
  Repository, Build-Log oder Dokument.
- Render verbinden, tatsächlichen Deploy-Stand und Secret-Konfiguration
  prüfen; öffentliche kostenpflichtige Route benötigt Missbrauchsschutz.
- Die 52 Godot-Aufnahmen tatsächlich erzeugen, anhören, vollständig
  ersetzen und Manifest/Hashes prüfen. Vorbereitungstests erzeugen nur
  synthetische Testdaten, keine echten Sulafat-Aufnahmen.
- Online-Antwort und Lern-/Spielausgabe akustisch mit der unveränderten
  Referenz vergleichen. Ein passender Modellname oder grüner Unit-Test
  ersetzt diesen Vergleich nicht.
- Tatsächliche Android-Runtime-Abnahme einschließlich Update ohne
  Datenverlust und Galaxy Z Fold / Android 16 geschlossen und geöffnet.
- Vollständige bidirektionale Kart-/Godot-Dialogbrücke und zusätzliche
  situationsbezogene Module erst nach geprüftem Sprachdienst verbinden.

## Prüfpfad und Bildschirmnachweise

Gezielte Flutter-Tests decken Sprachabbruch, WAV-Validierung, unveränderte
Stimmprobe, lokale Kontext-Hilfe, Elternfreigaben, Prüfungsmodus, Navigation,
kurze Dialogspeicherung und ausbleibende Belohnungsänderungen ab.
Backend-Tests verwenden ausschließlich simulierte Providerantworten.
Der vollständige Buildpfad muss zusätzlich Analyse, die gesamte Flutter-Suite,
Backend-/Android-Vorbereitung, Godot-Integration und APK-Verifikation bestehen.

Der Android-16-Probe aktualisiert die SHA-festgelegte Version 1926 ohne
Neuinstallation, prüft Paket-/Installationsidentität, Profil und Wallet und
betätigt die tatsächlich sichtbaren Eltern-Sprachcontrols. Er darf einen
Stimmentest nur bestätigen, wenn die Originalquelle genau einen neuen nativen
Wiedergabestart erzeugt. Display-Resize ist kein Test eines physischen Fold-Gelenks;
der stumme Emulator bestätigt ausdrücklich keine hörbare Sprecheridentität.

Vorher-/Nachher-Bilder der Spracheinstellungen sind echte Flutter-Renderings
bei 360 × 800, keine generierten Designbilder und kein Samsung-Runtime-Nachweis.
Der aktuelle Sulafat-Dienst darf erst nach tatsächlicher Abnahme als fertig
bezeichnet werden; dieser Entwicklungsstand behauptet das nicht.
