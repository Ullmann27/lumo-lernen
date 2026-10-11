# Lumo Nachhilfe: echte Lernwege und sichere Fortschritte

Dieser Meilenstein repariert die bestehende Nachhilfe-Anbindung und schützt vorhandene Lerndaten beim Laden. Er ersetzt weder die Lern-App noch das Sprachsystem und ist keine Fertigmeldung für das Gesamtprodukt.

## Android 1929: tatsächlicher Fehler und bestandene Wiederholungsprüfung

Der neueste gespeicherte Android-Fehler lag in der Prüfnavigation: Sie suchte nach „Lumo Kart spielen“ beziehungsweise „Zur Spielewelt“, obwohl die beobachteten Bedienelemente „Losfahren“ und „Zum Lernen“ heißen. Die unveränderte APK wurde anschließend erfolgreich nachgeprüft, ohne einen weiteren vollständigen Build ([tatsächliche Android-Laufzeitprüfung](https://github.com/Ullmann27/lumo-lernen/actions/runs/38138064509)).

- **APK-Zuordnung:** Flutter-Quelle `e4756bbcb6890d5054b5eb14ac4ef3ecd2cafa94`, Version `0.12.22+1929`, Paket `dev.ullmann.lumo.lumo_lernen.coachpreview`, separate Variante „Lumo Lernen Neu“.
- **Geprüfte Laufzeit:** Android 16/API 36, x86_64-Emulator, tatsächlicher Elterneinstieg, lokale Sprachsynthese ohne Netzwerk, native Wiedergabestarts und Abschluss, Pause/Fortsetzen/Stopp, Godot-Menü und Rückkehr zu Flutter.
- **Bestandsschutz:** Update ohne Deinstallation, unveränderte Installationsidentität und Erhalt der tatsächlich über die App erstellten fiktiven Testprofile, Einstellungen und Belohnungsdaten.
- **Grenzen:** Kein physisches Samsung, kein ARM64-Hörtest, keine menschliche Freigabe der emotionalen Klangqualität und kein vollständiges Rennen. Die neuen Nachhilfeänderungen dieses Meilensteins sind nicht in der alten APK enthalten.

## Reproduzierte Produktfehler und tatsächliche Reparaturen

- **Erfundene Nachhilfeauswertung:** Die alte Karte behauptete bei einem neuen Profil bereits, Lumo habe Schwierigkeiten ausgewertet. Der neue Einstieg nennt fehlende gespeicherte Antworten offen.
- **Ignorierte Antworten:** Fünf tatsächlich gespeicherte Antworten wurden von der alten Nachhilfe-Karte nicht als Grundlage verwendet. Die neue Karte nutzt das vorhandene `ProgressRecommendationService` und die aktuell gültige `LearningProfileLease`.
- **Falsches Fach:** Eine Silben-Empfehlung startete früher eine Sitzung mit Fach „Alle“. Die tatsächliche Schaltfläche startet jetzt das empfohlene Fach und Thema, zum Beispiel Deutsch → Silben.
- **Asynchroner Seitenwechsel:** Der tatsächliche Flutter-Seitenwechsel wird abgewartet, bevor der bestehende Unterrichtskurs öffnet. Ein Profilwechsel währenddessen verwirft den alten Kursauftrag.
- **Doppeltippen:** Zwei schnelle reale Taps lösten zwei Navigationswechsel aus. Während des tatsächlichen Kursstarts werden weitere Starts gesperrt.
- **Navigationsfehler:** Ein fehlgeschlagener Kurswechsel wird verständlich und erneut bedienbar angezeigt, statt eine unbehandelte asynchrone Ausnahme zu hinterlassen.
- **Einmaleins-Verlauf:** Der bestehende Kurs speichert „Kleines 1×1“, der Aufgabengenerator erwartet „Einmaleins“. Eine explizite, nur lesende Zuordnung berücksichtigt diese echten Antworten; gespeicherte IDs, Zähler und Klassengrenzen bleiben unverändert.
- **Beschädigte Speicherfelder:** Der alte Loader ersetzte ungültige JSON-Daten oder unbekannte Zeilen tatsächlich durch `{}` oder teilweise umgeschriebene Daten. Die Reparatur meldet das unlesbare Format, ohne die ursprünglichen Bytes zu überschreiben.

Für die Speicherdaten wurden ausschließlich fiktive, lokale Testprofile eingesetzt. Es wurden keine echten Kinderprofile verändert, gelöscht oder zurückgesetzt.

## Tatsächlicher Lernablauf

Die vorhandene Nachhilfe-Karte zeigt Fach, Thema und nachvollziehbare Antwortzahlen. Das Kind kann die echte Begründung freiwillig aufklappen und jederzeit ein anderes Thema wählen.

- **Passender Mathematikkurs:** „Plus bis 20“ öffnet den bestehenden vollständigen Kurs „Über den Zehner“. „Einmaleins“ öffnet die verfügbare Einführung „Das Einmaleins entdecken“, sofern sie zum regulären Schulstoff gehört.
- **Andere Fächer:** Deutsch- und Sachunterrichtsempfehlungen bleiben beim eigenen Fach. Die zusätzlichen Mathematik-Bildkurse sind ausdrücklich als Mathematik gekennzeichnet und werden nicht als passende Deutsch-Nachhilfe ausgegeben.
- **Aufgabenereignisse:** Der tatsächliche Kurs veröffentlicht weiterhin seinen Kontext für den bestehenden `LumoCompanionHost`. Es gibt keine zweite Lernarchitektur, Datenbank, KI-Plattform oder dauerhafte Mikrofonüberwachung.
- **Freiwilliges Vorlernen:** Die bereits implementierte Elternfreigabe und der getrennte Entdeckungsfortschritt bleiben erhalten. Die normale Nachhilfe schaltet keine höheren Klassen oder Online-Funktionen heimlich frei.
- **Speicherwiederholung:** Ein noch nicht gesicherter Lernstand wird als vorläufig angezeigt. „Speichern erneut versuchen“ sichert dieselben akzeptierten Antworten, ohne sie erneut zu zählen.
- **Kinderprofile:** An die sichtbare Empfehlung gebundene Aktionen eines alten Profils können nicht für das neu ausgewählte Kind ausgeführt werden. Unlesbare Daten eines Kindes erzeugen einen verständlichen Fehler und überschreiben weder dieses Kind noch ein anderes Profil.

## Grafik und Bedienbarkeit

Die reale Nachhilfe-Oberfläche nutzt die vorhandene Lumo-Figur, Nunito, dunkle Hologlas-Flächen, Cyan-Kanten und große goldene Lernaktionen. Die Originalreferenz `51024.jpg` dient als Gestaltungsmaßstab; die Inhalte der Referenz und der Nachhilfe sind nicht identisch.

- **Smartphone:** Beide eigentlichen Lernaktionen stehen vor der optionalen Begründung. Die neue Karte nutzt große, mehrzeilig lesbare Texte statt eines winzigen Pflichtschemas.
- **Fold-Zielviewport:** Empfehlung und nachvollziehbare Datengrundlage stehen links; der tatsächlich verfügbare Bildkurs und seine beiden Aktionen stehen rechts.
- **Touchflächen:** Kursstart, Übung und Begründung werden in fünf Viewports einschließlich kurzem Querformat und zweifacher Textskalierung auf mindestens 48 logische Pixel und reale Hit-Tests geprüft. Die neuen Schaltflächen haben 56 Pixel Mindesthöhe.
- **Originalgrafiken:** Das vorher als Emoji angezeigte Buch der Lesekarte wird durch das bereits vorhandene originale `book_open.png` ersetzt.
- **Ruhemodus:** Die vorhandenen Einstellungen für reduzierte Animationen und ruhige Darstellung werden respektiert. Es werden keine zufälligen Daueranimationen oder Lippenbewegungen als implementierte 3D-Lippensynchronisation ausgegeben.

## Tatsächliche Prüfungen dieses Meilensteins

| Prüfung | Beobachtetes Ergebnis | Abgrenzung |
|---|---|---|
| Nachhilfe-, Kurs-, Profil-, Discovery-, Speicher-, Host- und Navigationsregressionen | 121 bestanden, 2 optionale Aufnahmefälle separat | Echte Flutter-Interaktionen mit fiktiven Profilen |
| Gezielte Analyse der acht bearbeiteten Dart-Dateien | Keine Probleme | Die vollständige CI prüft den veröffentlichten Branch zusätzlich |
| Bestehende Backend-Tests | 35 bestanden, 0 fehlgeschlagen | Keine produktive `/speech`-Anfrage oder neue Cloudfreigabe |
| Inhaltsaudit | 40.969 Aufgaben, darunter 9 geführte Antwortschritte, bestanden | Deterministische Prüfungen, keine vollständige externe Fachabnahme |
| Speicherkorruption vor der Reparatur | 16 reproduzierte Fehlfälle | Tatsächlich beobachtete Änderung der Test-Speicherbytes |
| CI-Upload-Vertrag | 3 bestandene Python-Prüfungen | Der tatsächliche Remote-Artefaktupload muss zusätzlich beobachtet werden |

Die Rohaufnahmen werden durch die optionalen Aufnahmefälle separat erzeugt. Sie umfassen für Smartphone und Fold jeweils die reale Nachhilfe-Karte, die aufgeklappte Begründung nach tatsächlichem Tap und den nach tatsächlichem Tap geöffneten Kurs.

Die zwei Aufnahmeabläufe bestehen nach einer gezielten Reparatur des Prüfhelfers. Nach `ensureVisible` wird der tatsächliche Layoutframe abgewartet und das Ziel ausdrücklich auf Bedienbarkeit geprüft, bevor der reale Tap erfolgt. Die ursprüngliche Ausnahme wegen einer veralteten Bildschirmposition bleibt im Fehlerprotokoll erhalten; Trefferwarnungen wurden weder abgeschaltet noch übersprungen. Die anschließende gezielte Navigations-, Speicher-, Empfehlungs- und Katalogprüfung besteht mit 55 Tests und zwei separat geprüften Aufnahmefällen.

Die neue komplette Flutter-CI wird für den tatsächlich veröffentlichten Quellcommit gesondert beobachtet. Die bereits bestandene vollständige CI des Vorgängers darf nicht als Prüfung dieser neuen Änderungen ausgegeben werden ([Vorgängerprüfung](https://github.com/Ullmann27/lumo-lernen/actions/runs/38143393481)).

## CI-Beweissicherung

Der bisherige grüne Lauf hatte keinen herunterladbaren Prüfprotokoll-Artefakt, obwohl die Protokolle existierten. `upload-artifact` ignoriert Dateien in versteckten Ordnern standardmäßig; deshalb wird nur das ausdrücklich erzeugte Verzeichnis `.ci-results/` eingeschlossen und ein leerer Upload künftig als Fehler behandelt ([offizielle Dokumentation von upload-artifact](https://github.com/actions/upload-artifact)).

Die Laufprotokolle und Quellzuordnung werden zusammen mit den echten Bildern im Projektordner gesichert. Der zusätzliche Uploadvertrag ersetzt nicht die abschließende Kontrolle des tatsächlich erzeugten Remote-Artefakts.

## Geschützte Bestandteile und Fortsetzung

Die Dateien `lumo_voice.dart`, `lumo_sulafat_client.dart`, `app_settings.dart`, `config/godot-source.json` und `pubspec.yaml` bleiben gegenüber `9b8b7c86b4b4137c625d2e4fa727a9669a4962f5` unverändert. Es gibt keinen neuen Sprachprovider, keine kostenpflichtige API-Anfrage, keinen Main-Merge und keine Änderung an parallel bearbeiteten Cards- oder Godot-Dateien.

Entwicklungsbranch: `computer/lumo-learning-companion-discovery-2026-10-11`. Integration erfolgt weiterhin über [Draft-PR #265](https://github.com/Ullmann27/lumo-lernen/pull/265), nicht über einen unkontrollierten Merge nach `main`.

Die genaue Bild- und Quellzuordnung wird nach dem Codecommit mit `tools/package_tutoring_evidence.mjs` erzeugt. Dieses Werkzeug verweigert uncommittierte Produktdateien und prüft die geschützten Bestandteile bytegenau.

### Sofort ausführbare nächste Schritte

- **Vollständige CI:** Den exakten PR-Head, Analyseausgang, gesamte Testzahl und tatsächlichen Prüfprotokollupload beobachten. Bei einem Fehler nur die nachgewiesene Ursache bearbeiten.
- **Android-Integration:** Die neuen Lernfunktionen in eine einmalig gebaute, eindeutig versionierte nächste Test-APK übernehmen und den echten Kursstart, Profilwechsel, Speicherung und Offline-Sprachablauf darin nachweisen.
- **Pädagogik:** Weitere vorhandene Lernbereiche systematisch prüfen und geführte Einführungen ergänzen. Externe österreichische Volksschulpädagogen müssen die vorgesehenen Release-Inhalte fachlich freigeben.
- **Veröffentlichung:** ARM64-Hardware, echte Fold-Ereignisse, menschliche Hörabnahme, Datenschutz- und Sprachmodell-Lizenzfreigabe sowie Google-Play-Voraussetzungen bleiben eigenständige Abnahmepunkte.

Die Lern-App ist damit nicht insgesamt produktionsbereit. Eine neue APK, ein fertiger Google-Play-Release oder abgeschlossene physische Fold-Tests werden durch diesen Meilenstein nicht behauptet.
