# SDK- und Manifestprüfung – Host 01575

**Prüfbasis:** `Ullmann27/lumo-lernen`, `01575aafc3f5b9032900bb57520ee65e98d7546c`, 14. November 2026. Quelltexte wurden mit `git show`/`git grep` dieser Revision gelesen; der abweichende Checkout-HEAD ist keine Prüfgrundlage.

## Ergebnis und Grenzen

Die Quellen bestätigen lokale OCR und den normalen lokalen Android-Spracherkennungspfad. Eine uneingeschränkte Zusage, dass sämtliche Daten ausschließlich auf dem Gerät bleiben, ist damit nicht belegt: Ein konditionaler Speech-Plugin-Rückfall bleibt, Backup ist in den geprüften Vorlagen/Ausgängen nicht eingeschränkt, und Google dokumentiert separate ML-Kit-Metriken und SDK-Verbindungen.

**Kein finaler merged Manifest-/AAB-Nachweis.** Kein signiertes Bundle, Gradle-Merge oder aufgelöster nativer Dependency-Report; keine Geräte-/Emulator-, Mikrofon-, Scanner-, Netzwerkverkehrs-, Backend- oder Play-Console-Prüfung. Keine Produkt-/SDK-Änderung, kein Refwechsel, keine Schlüssel oder Bilddienst-Anfragen. Kein zusätzlicher Flutter-/Android-Testlauf.

## Tatsächlich ausgeführte Vorbereitung

Die unveränderten Funktionen `prepare_android.prepare(distribution='play')` und danach `prepare_embedded_games.prepare` aus 01575 liefen erfolgreich in einem isolierten Fixture. Eingaben: gerenderte installierte Flutter-3.44.9-Vorlagen, Frameworkrevision `6b182d2c7585eba26d4edce0f97630effd256c33`. Flutter wurde nicht gestartet.

Eine ausdrücklich **inerte Textdatei außerhalb des Fixture-Hosts** und Dummywerte dienten dem Existenzcheck der Vorbereitungsfunktion. Dies war kein Keystore und kein Signiernachweis. Keine Schlüssel wurden erzeugt.

| Ausgang | SHA256 |
| --- | --- |
| `prepare-play-manifest.xml` | `c3f9395f080354fe88e84c33fe2922cfb37066873c4643c51d287cd60ade63e9` |
| `prepare-play-embedded-manifest.xml` | `013757e7adcc1e5dc2d59b3988ade7e8f773892d888224f14acaab7e156e1d10` |
| `prepare-manifest.log` | `10befe474309e9b8dd50cd04d8b2f74e54a96e023d23e2657c24533e8e2d5545` |

Die tatsächlich erzeugten Ausgänge enthalten INTERNET, CAMERA und RECORD_AUDIO. REQUEST_INSTALL_PACKAGES steht in beiden Permission-Tagformen mit **tools:node=remove**; das ist eine Merge-Anweisung, keine finale angeforderte Berechtigung. Der Merge im Releaseartefakt bleibt zu bestätigen. Game-Activities und Authority-Services sind privat. Die Speech-Service-Abfrage steuert Paket-Sichtbarkeit.

Offline-Voice-/Icon-Vorbereitung wurde nicht ausgeführt. Die genaue Icon-Funktion ändert nur icon/roundIcon am Application-Element; Offline-Voice prüft das Manifest und bündelt Assets. Beide enthalten keine Backupregel.

Die Umgebung wurde nach erfolgreicher Fixture-Erzeugung unerreichbar. Dieser Bericht und sein JSON wurden aus vollständig empfangenen Toolausgaben gesichert. Das ursprüngliche `manifest-generation.json` wurde nicht vollständig gerettet; dessen aufgezeichneter Hash ist kein Ersatz für die fehlenden Bytes.

## 1. Sprache: lokaler Normalpfad, präziser konditionaler Restpfad

`lib/core/lumo_speech_listener.dart:33–48` prüft lokale Verfügbarkeit. `tools/auto_install/MainActivity.kt:49–54` verlangt API31+ und `isOnDeviceRecognitionAvailable`; Dart setzt beim Listen explizit onDevice:true (:130–139). Das native speech_to_text **7.5.0** erzeugt bei Verfügbarkeit tatsächlich `createOnDeviceSpeechRecognizer` (`SpeechToTextPlugin.kt:623–629)); Android beschreibt diese Factory als lokalen Erkenner [D1].

Dart cached jedoch den Initialisierungsstatus (:35). Ist lokale Erkennung dort verfügbar, aber bei der späteren Erzeugung eines **frischen** nativen Recognizers nicht mehr verfügbar, lässt das Plugin den Recognizer leer und wählt :632–635 den Standard-`createSpeechRecognizer`. Wiederverwendung eines bestehenden lokalen Recognizers ist nicht dieser Pfad; eine Exception der lokalen Factory ist ebenfalls nicht die nachgewiesene Rückfallbedingung. Lumo aktiviert intentLookup nicht; dessen Plugin-Default ist false (:115).

Auch **EXTRA_PREFER_OFFLINE ist nicht in jedem Pfad gesetzt**. Native startListening (:292) ruft createRecognizer; :650 erstellt das Intent zunächst mit Gerätesprache, partial=true und onDevice=false. Danach erhält setupRecognizerIntent (:298) onDevice=true. Der Cachevergleich (:656–659) berücksichtigt Sprache, partial, Modus und Pause, aber nicht onDevice. Bei gewählter Sprache gleich Gerätesprache und gleichen übrigen Werten kann der zweite Aufruf entfallen und der Extra fehlen. Ist er vorhanden (:687–688), kann ihn eine Recognizer-Implementierung laut Android trotzdem ignorieren [D2].

Das beweist **keine Audioübertragung**. Dienstwahl, Auftreten des Verfügbarkeitswechsels, Extra-Behandlung und Netzwerkverkehr wurden nicht gemessen. Der Befund begrenzt eine uneingeschränkte Lokalgarantie.

Das offizielle Pub-Archiv 7.5.0 entspricht dem exakten Lockfile-SHA256 `f2fabd017b5cb07f4e06d496b2d4b957e39534bc848f92b1e6acac80a10f4967`. Der native Quelltext stimmt bytegenau mit dem Archiv überein, SHA256 `2cd94b5a09917965784f7128fe0fd2e9642eb8e7f5a2abd2ae92450ea63b577f`. Kein Speech-Plugin-Patch in den geprüften Prepare-/Build-Skripten.

## 2. Backup: lokale Speicherung reicht für eine Nur-Gerät-Aussage nicht aus

Die exakte Basis hat kein getracktes android/. In scripts/tools/lib/.github wurde keine allowBackup-, dataExtractionRules-, fullBackupContent- oder backupInForeground-Regel gefunden. Flutter-Eingabe und beide generierten Ausgänge lassen allowBackup, dataExtractionRules, fullBackupContent, backupAgent und fullBackupOnly ungesetzt; der Bundle-Verifier prüft Backup-Policy nicht.

Android dokumentiert allowBackup=true als Standard; SharedPreferences und interne Dateien sind grundsätzlich backupfähig [D3, D4]. Das bedeutet **mögliche Backup-Eignung, keinen beobachteten Upload**. Finale Merge-Attribute, Geräteeinstellungen, Backuptransport, OEM-Verhalten und tatsächlich gesicherte Dateien bleiben unbekannt. Eine Nur-Gerät-Aussage benötigt explizite Regeln und entsprechende Artefakt-/Geräteprüfung.

## 3. OCR: lokale Bilder und separate SDK-Metriken

Gelockt: google_mlkit_text_recognition **0.13.1**, google_mlkit_commons **0.8.1**. Ihre Android-Dateien deklarieren com.google.mlkit:text-recognition:**16.0.1** (gebündeltes Latin-Modell) und vision-common:**17.3.0** [D7]. Die Java-Brücke wandelt einen lokalen Dateipfad in InputImage um und ruft textRecognizer.process auf. Geprüfte Gradle-, Manifest- und Java-Dateien stimmen mit frischen, lockfile-hashbestätigten Pub-Archiven überein; Einzelhashes stehen im JSON.

Google beschreibt lokale Verarbeitung der Eingaben/Ergebnisse, zugleich Update-/Kompatibilitätskontakte und Performance-/Nutzungsmetriken [D5]. Die Offenlegungsseite beschreibt Geräte-/Appinformationen, Installationskennungen und technische Metriken, gilt ausdrücklich nur für aktuelle SDK-Versionen [D6]. Sie beweist deshalb nicht die exakten historischen Übertragungsfelder dieser eingebundenen Versionen.

Bereits konkret aus offiziellem Google Maven geprüfte deklarierte Abhängigkeiten:

| Artefakt | Manifestbefund |
| --- | --- |
| common:18.11.0 | Privater MlKitInitProvider und Component-Discovery-Service |
| transport-runtime:2.2.6 | ACCESS_NETWORK_STATE; private Job-/Alarm-/Backend-Komponenten |
| transport-backend-cct:2.3.3 | ACCESS_NETWORK_STATE, INTERNET; CCT-Backend-Metadatum |

Dies sind deklarierte POM-Versionen, keine finale Gradle-Auflösung. Eine Providerdeklaration beweist keinen Start-Netzwerkrequest. Die Prepare-Ausgänge und die selbst berechtigungslosen Dart-Wrapper-Manifeste enthalten nicht automatisch alle transitiven SDK-Berechtigungen.

## 4. Fotoauswahl und Defaults

Das hashbestätigte image_picker_android **0.8.13+25** deklariert einen privaten FileProvider und die ModuleDependencies-Metadaten photopicker_activity:0:required. Android beschreibt dies als Aktivierung der automatischen Play-Dienste-Installation des rückportierten Fotoauswahlmoduls auf geeigneten Geräten [D8]. Es ist mögliche Modulbereitstellung, kein Beleg eines Foto-Uploads.

Die geprüften AppSettings-Defaults für Cloudvoice, Mikrofon, Scanner und AI-Proxy sind false. App-Feature-Schalter beweisen keinen systemweiten Netzwerkstopp und keine Abschaltung aller Drittanbieter-Metriken. Vollständige geprüfte Wrapper- und Versionslisten stehen im JSON.

## 5. Gesondertes Orange-Review

Commit `7c1d1bbf10a3ea7006fa86ead5469ebb329ac555` auf 01575: kein Blocker im begrenzten Whitelist-/null-Fallback-Fix. Vorhandene Logs rot5pass/2fail und grün7/7 wurden geprüft, nicht erneut ausgeführt. **Ein** roter Fall belegt Freitextoffenlegung; der zweite eine Fruchtdarstellungs-Abweichung. Es sind nicht zwei getrennte Lecks.

## Primärquellen

- **D1:** https://developer.android.com/reference/android/speech/SpeechRecognizer
- **D2:** https://developer.android.com/reference/android/speech/RecognizerIntent#EXTRA_PREFER_OFFLINE
- **D3:** https://developer.android.com/guide/topics/manifest/application-element#allowbackup
- **D4:** https://developer.android.com/identity/data/autobackup
- **D5:** https://developers.google.com/ml-kit/terms
- **D6:** https://developers.google.com/ml-kit/android-data-disclosure
- **D7:** https://developers.google.com/ml-kit/vision/text-recognition/v2/android
- **D8:** https://developer.android.com/training/data-storage/shared/photo-picker

Offizielle Pub-Archiv-/Google-Maven-URLs und Prüfsummen stehen im JSON. Abruf 14. November 2026. Dies ist ein begrenzter statischer Audit-/Prepare-Nachweis, keine Play-Freigabe oder vollständige Datenschutz-/Gerätevalidierung.
