# Lumo Frei: kostenlose lokale Lern-App-Stimme

Stand: 11. Oktober 2026. Dies ist ein überprüfbarer Entwicklungsmeilenstein, keine Produktions- oder pädagogische Endfreigabe. Die frühere ausschließlich-Sulafat-Vorgabe wurde durch den neueren ausdrücklichen Nutzerauftrag ersetzt, eine kostenlose, lebendigere Stimme direkt in die bestehende App einzubauen. Die unveränderten Sulafat-Originalaufnahmen bleiben erhalten. Große Kart-Erweiterungen bleiben nachrangig.

## Tatsächlich implementiert

- **Stimmidentität:** „Lumo Frei“, deutsches Supertonic-3-Profil `lumo-free-supertonic-de-v1`, festes Preset F2, verifizierte Binärsprecherposition 1. Der Hersteller beschreibt F2 als hell, freundlich, lebhaft, verspielt und jugendlich; daraus wird keine fachliche Kinderfreigabe oder menschliche Hörabnahme abgeleitet ([offizielle Stimmbeschreibung](https://supertone-inc.github.io/supertonic-py/voices/)).
- **Lokale Lernaufnahmen:** 155 eigenständig erzeugte M4A-Aufnahmen aus vorhandenen öffentlichen App-Texten, einschließlich Begrüßung, Lob, Ermutigung, Mengenfragen, Mathematik, Deutsch, Sachunterricht und Schreibcoach. Jede Datei hat eine überprüfte SHA-256, vollständig dekodierte echte Audiodaten und eine aus dem Audio berechnete Mundbewegungskurve. Keine generischen Katalog-Aliase täuschen neue Aufnahmen vor.
- **Dynamische Texte:** Neuer privater Android-MethodChannel mit lokaler CPU-Inferenz der fest gepinnten vier ONNX-Modelle. Neue Texte benötigen die ausdrückliche Bestätigung der lokalen Modellbedingungen im Elternbereich. Die frühere Online-Stimmenpräferenz ist keine solche Bestätigung und löst im neuen Standardprofil keine kostenpflichtige Anfrage aus.
- **Bestehender Player:** Neue Aufnahmen und erzeugte WAVs werden durch denselben bereits vorhandenen zentralen AudioPlayer abgespielt. Pause, Fortsetzen, Stopp, Sprechtempo und echte native Abschlussmeldungen bleiben erhalten. Ein automatisch folgender Fragesatz wartet auf laufendes Lob, Ermutigung oder Begrüßung.
- **Abbruch und Ressourcen:** Laufende Synthesen sind abbrechbar; stummgeschaltete oder verlassene Seiten dürfen verspätete WAVs nicht starten. Der Synthesekanal wird beim Stoppen einer normalen Aufnahme nicht unnötig angesprochen. Modellgewichte werden beim Öffnen geprüft, nicht bei jedem Folgesatz erneut gehasht; native Modelle werden bei Hintergrund-Speicherdruck freigegeben.
- **Elternoberfläche:** „Ton und Stimme“ enthält „Stimme testen“, „Neue Sätze offline vorlesen“, einen vollständigen lokalen Lizenzdialog und „Neue Rechenhilfe anhören“. Letzterer erzwingt eine tatsächliche neue lokale Synthese der mathematisch richtigen öffentlichen Erklärung zu sieben plus fünf, nicht nur eine vorbereitete Aufnahme.
- **Identitätsdiagnose:** „App und lokale Stimme prüfen“ zeigt die tatsächliche installierte App-Identität und das Vorhandensein des lokalen Modells. Das Vorhandensein des Modells wird ausdrücklich nicht als hörbare Wiedergabe bezeichnet.

Diese Stimme ist nicht Sulafat und kein Klon der Originalstimme. Die neue Standardausgabe hat keinen automatischen Rückfall auf Google Gemini, eine andere Cloud-Stimme oder Android-System-TTS. Der bestehende Sulafat-Serverpfad bleibt als explizit ausgewählte, abgeschirmte Kompatibilitätsfunktion erhalten; seine Tests wurden nicht entfernt.

## Technische Zuordnung und Lizenz

Der Quellbranch ist `computer/lumo-education-excellence-2026-10-11`, Fortsetzung von `af4b1a340ffeb3cf1d9dca8e758edba85544e00b` und [Draft-PR #262](https://github.com/Ullmann27/lumo-lernen/pull/262). Grundlage ist die bereits gesicherte Lernmodulmodernisierung aus [PR #261](https://github.com/Ullmann27/lumo-lernen/pull/261), nicht der zurückliegende Main-Branch. Die neue Version ist als `0.12.22+1929` vorbereitet; allein die Versionsänderung beweist keinen erfolgreichen APK-Bau.

Die Sprachsoftware und Referenzimplementierung sind MIT-lizenziert. Die tatsächlichen Modellgewichte unterliegen dagegen BigScience Open RAIL-M, nicht einer uneingeschränkten MIT-Modelllizenz; das Konvertierungsarchiv enthält hierzu einen irreführend unvollständigen MIT-Hinweis ([Original-Modelllizenz mit Nutzungsbeschränkungen](https://huggingface.co/Supertone/supertonic-3/blob/main/LICENSE)). Die originale Modelllizenz ist unverändert sowohl bei den Flutter-Audios als auch beim nativen Modell enthalten. Die Implementierung zeigt KI-Erzeugung und vollständige Modellbedingungen an und verlangt eine ausdrückliche lokale Nutzungsbestätigung.

„Kostenlos“ bedeutet hier: keine kostenpflichtige Sprach-API, kein Sprachserver und keine Abrechnung pro vertontem Satz. Gerätearbeit, Speicherbedarf und die Bedingungen der Modelllizenz bleiben bestehen. Rechtliche Prüfung der Lizenzweitergabe, belastbare Erwachsenenprüfung und vollständige Google-Play-/Datenschutzfreigabe bleiben gesonderte Veröffentlichungsbedingungen.

Die exakten Modell-, Stil-, Archiv- und Lizenzprüfsummen, Quell-URLs, ONNX-Runtime-Version und echte Modellausgaberate von 44.100 Hz stehen in `config/lumo-offline-voice.json`. Die fertigen Lernaufnahmen werden für mobilen Speicher mit 24.000 Hz AAC ausgeliefert; die native neue Synthese erzeugt echte 44.100-Hz-Mono-PCM-WAVs. Ein Datenratenwechsel ist keine zweite Stimme.

## Schutz des vorhandenen Produktes

Die vorhandenen Aufgabenbewertungen, Lösungsberechnungen, Fortschrittsdatenbanken, Profile, Sterne, XP, Aufgabenhistorien, Schreibcoach und Lernmodul-Controller werden für diesen Sprachmeilenstein nicht ersetzt. Hinzu kommt nur eine sicher standardmäßig ausgeschaltete lokale Lizenzpräferenz im bestehenden Einstellungsformat. Alte Einstellungen erhalten keine implizite Online-, KI-, Mikrofon-, Kamera- oder Premium-Freigabe.

Der eingebettete Godot-Stand bleibt exakt `6063f56fd4ff13afef61509f52d1d4fdab012654`. Neue Java-/Kotlin-Quellen ergänzen den vorhandenen generierten Android-Host, nicht eine Ersatz-App. Die Paketvariante bleibt **Lumo Lernen Neu**, `dev.ullmann.lumo.lumo_lernen.coachpreview`, mit vorhandener Testsignatur. Eine neue Produktionssignatur, eine Änderung der normalen Lumo-Paketkennung oder eine unkontrollierte Main-Integration ist nicht Bestandteil dieses Meilensteins.

Die vorhandene Kart-Sprach-/Audioimplementierung wird nicht als bereits auf F2 umgestellt ausgegeben. Der Android-Test prüft die erhaltene Kart-Menüintegration und Rückkehr, nicht einen neuen kompletten Rennablauf.

## Prüfstand und klare Grenzen

Vor dem neuen APK-Lauf tatsächlich beobachtet:

- **Vollständige Flutter-Suite:** 1.140 bestanden, 107 bereits bestehende optionale Capture-Prüfungen übersprungen, keine Fehler. Der erste Gesamtlauf wurde vom äußeren 240-Sekunden-Prozesslimit beendet und wird nicht als bestanden gezählt. Der einzige anschließende vollständige Ersatzlauf beendete nach 3 Minuten 36 Sekunden mit Exit 0; kein Test wurde dafür entfernt oder abgeschwächt.
- **Routing und Kompatibilität:** 91 gezielte Flutter-Prüfungen bestanden. Dazu gehören 50 unterschiedliche vorhandene Sprachsituationen, die ihre jeweils eigene neue F2-Datei verwenden, sowie die erhaltenen Sulafat-, Pause-, Stopp-, Mute- und Navigationstests.
- **Native Player in Flutter-Tests:** MethodChannel-Mock, ausdrücklich keine hörbare Android-Wiedergabe. Die Dateien selbst sind real und vollständig dekodiert, aber gemockte Start-/Abschlussmeldungen ersetzen keinen Gerätehörtest.
- **Lokaler nativer Sprachmotor:** Java-Kompilierung, elf isolierte Java-Guards und ein tatsächlich abgeschlossener fünfzigteiliger nativer Inferenzlauf mit ONNX-Runtime 1.23.1. Alle 50 unterschiedlichen deutschen öffentlichen Testtexte erzeugten echte WAV-Dateien; der Probelauf beendete mit 62 bestandenen Prüfungen und Exit 0. Hinzu kommen vier frühere reale Smoke-WAVs. Dies sind JVM-Sprachdaten, kein Android-Lautsprecher und keine fünfzigteilige Android-Hörabnahme.
- **Lizenzdialog:** Vier tatsächliche Widget-Prüfungen bestanden, darunter 320 × 568 mit doppelter Schrift, Fold, Tablet und Ablehnung ohne Freigabe. Ursprüngliche Fehlerlogs für Überlauf, unnötige Synthese-Abbrüche und eine fehlerhafte Fake-Clock-Fixture bleiben erhalten; keine Tests wurden zur Grünmeldung deaktiviert.
- **Backend und Inhalt:** 35 bestehende Node-Backendtests, 55 Python-Paketierungs-/Signatur-/Hosttests und der unveränderte Inhaltsaudit mit 40.960 generierten Aufgaben bestanden. Die zusätzliche Hostprüfung kopiert die tatsächlichen Java-/Kotlin-Sprachquellen für zwei bestehende Namensräume idempotent und lässt fiktive gespeicherte Fortschrittsdateien bytegleich. Das ist keine vollständige österreichische Lehrplanabdeckung oder externe pädagogische Abnahme.
- **Analyse:** Keine Errors oder Warnings; die 17 bereits geerbten Info-Lints bleiben dokumentiert. Die sechs neu hinzugekommenen Lint-Hinweise wurden behoben.
- **Bibliotheksarchitektur:** Die tatsächlichen ARM64-ONNX-ELF-Dateien haben 16-KiB-LOAD-Ausrichtung. Erst die fertige APK-Verifikation beweist jedoch korrekte Paketierung zusammen mit Flutter, Godot, Signatur, Ressourcen und exakt erwarteten ABIs.
- **Automatische Verständlichkeitsprüfung:** Der ursprüngliche 155er-Katalog wurde lokal mit Whisper Base transkribiert. 90 Transkriptionen waren nach einfacher Wortnormalisierung exakt, 83 Wortabweichungen entfielen auf 911 erwartete Wörter. Eine gezielte zusätzliche Whisper-Small-Prüfung bestätigt unter anderem Begrüßung mit „Lumo“, Mengenfrage, Uhrzeit und die Zahl neun. Andere Abweichungen umfassen auch Schreibvarianten wie „gehts“/„geht's“, „Lern-Profi“/„Lernprofi“ und Minuszeichen anstelle des gesprochenen Wortes.
- **Tatsächliche Aussprachekorrekturen:** Die ursprünglichen Aufnahmen von „Probier es so“ und der Wortartenfrage wurden durch zwei real neu erzeugte F2-Dateien ersetzt, nicht umetikettiert. Die semantischen Sprechertexte lauten jetzt „Probiere es so.“ und „Ist das Wort Haus ein Nomen, ein Verb oder ein Adjektiv?“. Nur der Producer-/Sprachmotor-Eingang verwendet für das deutsche stimmhafte Wort „Verb“ die Aussprachehilfe „Werb“; sichtbare Aufgabe, Bewertung und gespeicherte Antworten bleiben unverändert. Die zwei neuen Aufnahmen benutzen 16 Inferenzschritte und Tempo 0,94 statt acht Schritten und 0,98; Original-/Nachher-Prüfsummen und Parameter stehen in `audio-production-manifest.json`. Whisper Small erkannte „probier es so“ und „Ist das Worthaus ein Nomen, ein Verb oder ein Adjektiv?“. Diese maschinelle Verbesserung ersetzt keine menschliche Hörfreigabe.
- **Nachweisformat:** Der lokale Transkriptprüfer erfasst jetzt den tatsächlich verwendeten ASR-Modellhash, Modellnamen und Audiorate, statt auch Small-Läufe irrtümlich als Base zu beschriften. Unveränderte Rohtranskriptionen und ursprüngliche Fehlermetadaten bleiben nachvollziehbar; aktuelle native Fünfzig-WAV-Transkriptionen werden nach Abschluss separat gesichert.

Die automatische Gegenprüfung übermittelt keine Audiodaten an eine fremde Analyse-API und benutzt keine Kindertexte. Sie beweist keine Natürlichkeit, Wärme, emotionale Wirkung, Verständlichkeit für ein konkretes Kind oder hörbare Wiedergabe auf ARM64.

## Build- und Android-Abnahme

Der eigene Workflow `lumo-free-voice-1929.yml` hat ausschließlich Lese- und Artefaktrechte. Er veröffentlicht keinen GitHub-Release, nichts im Play Store und keine Zahlungsfunktion. Er führt die vollständige Flutter-Suite, Inhalte, Backend und Paketierung aus und baut danach die vorhandene integrierte App getrennt für ARM64 und x86_64.

`verify_unified_apk.py` prüft zusätzlich die tatsächlich im APK enthaltenen Modellgewichte, beide Lizenzkopien, den vollständigen Audio-Katalog, jede der 155 Audio-Prüfsummen und beide nativen ONNX-Bibliotheken pro ABI. Fehlende oder geänderte Stimmen, Lizenzen und Gewichte werden abgewiesen.

Der Android-16-Emulatorlauf verwendet das unveränderte, zuvor erfolgreich verifizierte x86_64-APK 1928 als Updatebasis: SHA-256 `ce4a72cb2831067401799c7e15f0649057f487b89fb40a54c23db5f52b8d4dd7`, Quellcommit `8ba6b1fc9791ede5977d7b624fe692405fd44277`. Der Test installiert darüber 1929 ohne Deinstallation und überprüft UID, Erstinstallationszeit, fiktives Profil, Wallet, lokale Bestätigung, echte native Audiostarts/-abschlüsse, Pause/Fortsetzen, neue Synthese ohne Netzwerk, responsive Oberflächen und Kart-Rückkehr.

Dieser Emulator ist absichtlich ohne akustische Ausgabe gestartet. Ein erfolgreicher nativer Playerabschluss beweist deshalb keine wahrgenommene Klangfarbe. Auch ein erfolgreicher Build allein beweist keine Geräteinstallation. Ergebnisse und tatsächliche Dateien dürfen erst nach Abschluss des jeweiligen Laufs als vorhanden gemeldet werden.

## Reproduzierbare Fortsetzung

```bash
export PATH=/home/user/workspace/toolchains/flutter/bin:$PATH
export TMPDIR=/dev/shm/lumo-flutter-test-tmp
flutter analyze --no-pub --no-fatal-infos --no-fatal-warnings
flutter test --no-pub --reporter=expanded --concurrency=2 --timeout=75s
python3 -m unittest discover -s scripts/tests -v
node --test server/lumo-ai-proxy/test/*.test.js
dart scripts/audit_content.dart
```

Für einen sauberen, tatsächlich versionierten APK-Bau auf dem vorhandenen Android-Buildrunner:

```bash
LUMO_SPLIT_PER_ABI=1 bash scripts/build_unified_apk.sh
python3 scripts/verify_unified_apk.py dist/Lumo-Lernen-Neu.apk --abi arm64-v8a
```

Die native Modellproduktion liegt in `scripts/voice/produce_lumo_supertonic_voice.py`, die aktuelle öffentliche Textinventur in `scripts/voice/build_lumo_public_voice_inventory.dart`. Gewichte sind Build-Eingaben mit SHA-256, keine auf GitHub erfundenen Assets oder unkontrollierten Laufzeitdownloads. Modelle und reale Audios müssen aus den tatsächlich vorhandenen Dateien verwendet werden.

Nächste konkrete Schritte: eigenen Produktcommit sichern, den artefaktbasierten Android-Bau abschließen, echte Runtime-Ergebnisse und APK-Prüfsummen dokumentieren, Hörbeispiele und den tatsächlich gebauten Android-Teststand direkt bereitstellen. Die vollständige Suite und die Aussprachekorrekturen sind bereits abgeschlossen und werden nicht noch einmal neu entwickelt. Anschließend folgt der bestehende Lernbegleiter-Anschluss; keine neue KI-, Profil- oder Fortschrittsarchitektur.
