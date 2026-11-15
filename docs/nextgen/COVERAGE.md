# Lernabdeckung – belegter integrierter Quellstand

**Produkt-Snapshot: `31e5ba4fce462e7f38018cecfb351c932e3382b9`. `fullModernizationComplete` bleibt `false`.**
Diese Matrix inventarisiert den ausgeführten Dart-Katalog, Einstiegsketten, fachliche Antwortgrenzen und vorhandene Testprotokolle. Ihre Einträge umfassen aktive und bedingte Lernwege, Navigation, Verträge, geschützte sowie inaktive Legacy-Pfade; ihre Gesamtzahl ist keine Zahl aktuell erreichbarer bewerteter Aufgaben. Sie ist keine Geräte- oder Releasefreigabe. [COVERAGE.json](COVERAGE.json) enthält IDs, Quellenhashes, klassifizierte Einträge, Typen, Adapter und Nachweisgrenzen.

## Tatsächlich erfasster Umfang

| Bestand | Umfang |
|---|---:|
| Geprüfte Inventareinträge / Screen-Dateien | 61 / 55 |
| Klassen-/Fach-/Einheitskombinationen | 236 |
| Mathe- / Deutsch-Templates | 60 / 32 |
| Akademie-Themen | 79 |
| Registry / aktive Modul-Einstiege / aktive Modul-Screens | 20 / 19 / 18 |
| Praktische Aktivitäten | 60 |
| Lernlabor-Modi / feste Problem-IDs | 6 / 35 |
| Geführte Lektionen | 7 |
| Lernspielkatalog / MiniGame-Level / abschließendes Quiz-Level | 50 / 49 / 1 |
| Reading-Buddy-Texte / feste Quests | 24 / 4 |
| Kognitive Fragen / deklarierte Quiz-IDs / Kartenbank-Einträge | 200 / 108 / 200 |
| Native Adapter-Kinds / bytegleiche geschützte Dateien | 12 / 18 |

Die sechs Labormodi sind **bridge, word, english, nature, fraction, pattern**. `d1_woerter` bleibt durch den geschützten Wort-Schreibcoach überlagert; die zwei Einmaleins-Einstiege teilen einen Screen. Level 50 öffnet gemäß `GamesContent` das Quiz und ist kein MiniGame-Level. Dynamische Aufgabenvarianten und gespeicherte Geschichten haben keine vollständige endliche ID-Liste; `routeRef` und `sourceIndex` sind Dokumentationsschlüssel.

Die acht Fächer der 236 Katalogfamilien sind im aktuellen Hub vorhanden, einschließlich **Lesen und Rechtschreibung**. Themenkarten rufen die exakte Einheit über `_beginClearLearningTask` auf; passende Spezial-/Schreibmodule haben Vorrang, danach folgen Core oder freiwilliges CrossGrade. Aktives Vorlesen ist ein zusätzlicher Einstieg. Für eine im Core geladene Übungsaufgabe bestehen gemeinsamer Coach und sichtbarer Native-Einstieg, soweit Hilfe erlaubt ist. Daraus folgt weder eine fehlende Anbindung aller Familien noch eine vollständige spezialisierte 3D-/Geräteabnahme jeder Variante.

## Anschlüsse und ihre Grenzen

| Lernfläche | Aktueller Quellstand und belegte Grenze |
|---|---|
| Reguläre Aufgaben | Kanonischer Kontext, gestufte Hilfe, bearbeitbarer Sprachkandidat und explizite Prüfung; sichtbarer Native-Einstieg mit `forTask` und begrenzter `task_card`-Rückfallebene. Prüfungsmodi sperren Hilfe und Vorschläge. |
| 18 Fachmodule / 19 Einstiege | 17 `ModuleTaskScope`-Screens plus Plus10; fachlicher bestehender Antwortcallback, Bestätigung der aktuellen Aufgabe, native `task_card`-Schaltfläche. Alle Screen-Hashes stimmen mit der 134-Test-Lieferung überein. Das ist kein eigener räumlicher Fachmodell-Nachweis für jedes Modul. |
| Lernlabor | Alle sechs Modi besitzen `lab-open-3d` für die exakte aktuelle native `task_card`. 24 Tests prüfen unter anderem sechs Einstiege, Hilfe vor I/O, native Pause/Rückkehr, ungewerteten Kandidaten, Stop und unverdeckte Schrittbindung. Die vorhandenen Lab-Modelle bleiben die Fachautorität; kein eigener nativer Manipulativ-Renderer je Modus. |
| Geführte Lektionen | Aktueller Schritt, gestufte Hilfe, bestätigungspflichtiger Kandidat, native spezielle Szene oder `task_card`. Native-Rückkehr, Pause und veraltete Bestätigungen sind im gezielten Lauf enthalten. |
| Lesen / Reading Buddy | Gemeinsamer `ReadingLessonCompanion`, native Lernschaltfläche, getrennte Lese-/Verständnisbewertung; ein früherer 25-Test-Lauf und separat 23 Tests zum aktuellen Audio-Owner-Nachtrag. Überlappende Tests werden nicht addiert. Echtes Mikrofon und Gerät bleiben offen. |
| Foto-Lernheft | OCR führt in `PhotoLessonPracticeScreen`; echte Antworten, bestätigte Vorschläge und `PhotoLessonSession`. Anzeigen/Scannen allein vergibt keine richtige Antwort. Der direkte Native-Einstieg gehört zum aufgezeichneten gemeinsamen 35-Test-Lauf. |
| Story / Quiz / Cards / 49 MiniGame-Level | Eigene Fach-/Controllergrenzen bleiben bestehen. Die direkten Story-/MiniGame-Native-Einstiege sind im 35-Test-Lauf enthalten. Der integrierte Quiz-/Cards-Coach hat einen sichtbaren nativen Aufgaben-Einstieg; Coach-Auswahl, bestehende Fachprüfung und Belohnungsgrenzen werden im separaten 56-Test-Lauf geprüft. |
| IQ / kognitives Profil | `ExamCompanionScope`: begrenzte Wiederholen/Langsamer/Stopp-Aktionen; keine Lösungshilfe oder KI-Antwortvorgabe im Test. Keine diagnostische Standardisierung behauptet. |
| Praxisaufträge | 60 vorhandene Aktivitäten mit erreichbarem Einstieg „Beobachtung im Journal festhalten“, teilweise ergänzter digitaler Übung oder Werkstatt. Die menschliche Beobachtung wird bewusst nicht automatisch gewertet; ein eigener formaler Lehrer-Abgabeablauf wird nicht behauptet. |
| Live / 2D Flame | Gelieferter gemeinsamer Coach mit nativer Aufgabenkarte und bestätigungspflichtigen Vorschlägen. Der 56-Test-Lauf umfasst echte Flame-Frage-/Truhen-Callbacks sowie Live-Finaltranskript, Stop, Modus-/Profilwechsel und Berechtigungsgrenzen. Teilnahme-/Safari-Bewertung bleibt von geprüfter Fachleistung getrennt; keine neue Physik- oder reale Mikrofontour behauptet. |

Die **12 nativen Kinds** lauten: `addition`, `bridge_hundred`, `bridge_ten`, `english_objects`, `equal_groups`, `equal_sharing`, `fraction_parts`, `pattern`, `plant_parts`, `subtract_ten`, `syllables`, `task_card`.
`pattern` verwendet den geprüften `period/sequence/choices`-Vertrag. Die generische `task_card` trägt begrenzten Prompt und Auswahlmöglichkeiten ohne Lösungs-/Belohnungsfeld. Eine Factory, eine importierte Klasse oder der eigene native Spieltisch beweist keinen erreichbaren Lernbutton. `capabilityMatrix` verlangt passende Verbraucher, sichtbare Steuerung und `scene: 'learning'`; eine getrennte optionale Activity beweist außerdem keine vollständige aufgabengebundene 3D-Modernisierung.

## Bedeutung der klassifizierten Befunde

- **Implementiert:** Der kanonische Bus prüft Aufgabenidentität, erlaubte Aktionen, Prüfungsgrenzen und Objektkennungen. Ein Sprachvorschlag bleibt bis zur Owner-Bestätigung ungewertet. Dass bestehende deterministische Vergleiche teilweise in Renderer-/Screen-Dateien stehen, bedeutet keine fehlende Autoritätsgrenze.
- **Architektur und Spezialisierung:** Das alleinige `placeValue` im älteren Flutter-Director begrenzt nicht die zwölf aktuellen nativen Descriptor-Kinds. Exakte generische Karten, spezialisierte Manipulative und vollständige Gerätebelege sind getrennte Aussagen.
- **Inaktiver Teacher-Restfallback:** Die einzige Konstruktion von `LumoTeacherScreen` steht am Ende von `_openTopic`. Der aktuelle Unit-Caller ruft ihn nur nach vorhandener Einheitszuordnung auf; die aktuellen Atelier-Werkzeuge werden vorher durch Schreibcoach, Buchstabenschreiben, Wortcoach/Registry, Artikel oder Aufsatz abgefangen. Dieser Themenchat besitzt keinen lokalen TaskResult-/Antwort-/Belohnungspfad und ist kein aktuell erreichbarer bewerteter Lernweg ohne kanonische Bindung.
- **Schutz und Nachweisgrenzen:** Geschützte Schreib-/Journalinternas, eingeschränkte Prüfungshilfe sowie die Trennung von Live-Teilnahme und Fachleistung sind beabsichtigt. Noch nicht durchgespielte Varianten oder nicht physisch gemessene Geräteabläufe sind keine allein aus dem Inventar ableitbaren Funktionsfehler. JSON-Feld `gaps` bleibt aus Kompatibilität bestehen; `classification` und `status` bestimmen seine Bedeutung.

## Aufgezeichnete Prüfungen

Die folgenden Zahlen stammen aus den eingecheckten oder mit dieser Matrix neu erzeugten Protokollen. Unterschiedliche Quellstände und überlappende Suiten werden nicht zu einer vermeintlichen Gesamtsumme addiert. `logStorageCommit` ist getrennt vom ausdrücklich bekannten Ausführungsstand erfasst.

| Lauf | Ergebnis | Ausführungsumfang | Protokoll |
|---|---:|---|---|
| `module_connections` | 134 bestanden / 0 fehlgeschlagen | `owner_sources_integrated` | [module_tests.log](evidence/chat2_completion_20261115/module_tests.log) |
| `core_guided` | 59 bestanden / 0 fehlgeschlagen | `owner_sources_integrated` | [core_tests.log](evidence/chat2_completion_20261115/core_tests.log) |
| `lab_core` | 198 bestanden / 0 fehlgeschlagen | `earlier_targeted_integration` | [core_tests.log](evidence/chat2_core_20261115/core_tests.log) |
| `reading` | 25 bestanden / 0 fehlgeschlagen | `root_targeted_integration` | [tests.log](evidence/reading_integration_20261115/tests.log) |
| `reading_audio_owner` | 23 bestanden / 0 fehlgeschlagen | `owner_sources_integrated` | [tests.log](evidence/reading_audio_owner_20261115/tests.log) |
| `photo_thinking` | 64 bestanden / 0 fehlgeschlagen | `root_targeted_integration` | [root-photo-thinking-integrated-tests.log](evidence/root_joined_20261115/root-photo-thinking-integrated-tests.log) |
| `speech_boundary` | 19 bestanden / 0 fehlgeschlagen | `root_targeted_integration` | [root-integrated-stt-check.log](evidence/root_joined_20261115/root-integrated-stt-check.log) |
| `native_boundary` | 25 bestanden / 0 fehlgeschlagen | `root_targeted_integration` | [joined-native-boundary-tests-final.log](evidence/root_joined_20261115/joined-native-boundary-tests-final.log) |
| `assessment` | 11 bestanden / 0 fehlgeschlagen | `earlier_targeted_integration` | [flutter-tests.log](evidence/assessment-contract/flutter-tests.log) |
| `pattern_navigation` | 4 bestanden / 0 fehlgeschlagen | `earlier_targeted_integration` | [integration_tests.log](evidence/c5_integration_20261115/integration_tests.log) |
| `minigame_original_routes` | 6 bestanden / 0 fehlgeschlagen | `root_original_routes_before_native_followup` | [mini_game_routes_initial.log](evidence/remaining_integration_20261115/mini_game_routes_initial.log) |
| `lab_native` | 24 bestanden / 0 fehlgeschlagen | `owner_sources_integrated` | [tests.log](evidence/lab_native_20261115/tests.log) |
| `remaining_native_joined` | 35 bestanden / 0 fehlgeschlagen | `root_targeted_integration_before_final_narrowing` | [remaining_native_joined.log](evidence/remaining_integration_20261115/remaining_native_joined.log) |
| `game_question_coach` | 56 bestanden / 0 fehlgeschlagen | `owner_sources_integrated` | [focused-tests.log](../evidence/lumo-nextgen-game-questions/focused-tests.log) |
| `ci_mini_games` | 27 bestanden / 0 fehlgeschlagen | `targeted_full_suite_failure_correction` | [mini-games-tests.log](evidence/ci_retry_20261115/mini-games-tests.log) |
| `ci_contracts` | 12 bestanden / 0 fehlgeschlagen | `targeted_full_suite_failure_correction` | [contracts-tests.log](evidence/ci_retry_20261115/contracts-tests.log) |
| `ci_learning` | 43 bestanden / 0 fehlgeschlagen | `targeted_full_suite_failure_correction` | [tests.log](evidence/ci_learning_20261115/tests.log) |
| `mini_audio_owner` | 12 bestanden / 0 fehlgeschlagen | `owner_sources_integrated` | [mini-audio-tests.log](evidence/ci_retry_20261115/mini-audio-tests.log) |
| `story_audio_owner` | 35 bestanden / 0 fehlgeschlagen | `owner_sources_integrated` | [story-audio-tests.log](evidence/ci_retry_20261115/story-audio-tests.log) |
| `core_guided_audio_owner` | 54 bestanden / 0 fehlgeschlagen | `owner_sources_integrated` | [tests.log](evidence/learning_audio_owner_20261115/tests.log) |
| `catalog_export` | 1 bestanden / 0 fehlgeschlagen | `current_inventory_snapshot` | [catalog_export.log](evidence/coverage_refresh_20261115/catalog_export.log) |
| `sentence_privacy` | 3 bestanden / 0 fehlgeschlagen | `current_inventory_snapshot` | [sentence_privacy.log](evidence/coverage_refresh_20261115/sentence_privacy.log) |

Die Satz-Privacy-Neuprüfung ersetzt die alte Behauptung eines offenen Lösungslecks. Unverknüpfte Testdateien tragen `present_no_recorded_run_matched`; verknüpfte Dateien `passed_in_recorded_targeted_run`. Beide Zustände sind von einem frischen vollständigen Root-Lauf getrennt.

## Sichtbar offene Freigaben

- Der frühere C5-Lauf 44/5 und die abgebrochene erste native Fixture bleiben Fehlerhistorie. Der korrigierte gemeinsame Native-Lauf hat **35/35**, der gelieferte Frage-Coach **56/56**, der neue Lab-Anschluss **24/24** aufgezeichnete Erfolge. Sie ersetzen die alten Pending-Aussagen für diese gezielten Bereiche, ergeben zusammen aber keinen vollständigen aktuellen Root-Testlauf.
- Die 35-Test-Lieferung `b193899565110e5c7a26f73520a943b261887e63` enthält nach diesem Lauf noch eine enge Ablehnung mehrdeutiger normalisierter Auswahlwerte. Die finale CI muss deshalb den exakten integrierten Quellstand einschließlich dieser Verschärfung prüfen. Live, 2D Flame und der Quiz-/Cards-Coach sind in `3123d3247775fcdc42a16c2bcc5c51e1ab98c4c9` integriert; ihre Producer-/Test-Provenienz ist im JSON getrennt erfasst.
- Der veröffentlichte native Quell-Pin lautet **`332307fafa2f68a1aa3667d81b7c90d3683c5c45`**. Dieser Flutter-Bestand allein belegt nicht die finale Banane-/Kartenoptik auf einem Gerät. Die gemeldete Desktopmessung beträgt **8 FPS**; sie belegt keine 60 FPS. Physischer Fold, Rotation/Größenwechsel, reale Mikrofon-/Audioabläufe und die vollständige Android-Tour sind offen.
- Die alten Deutsch-Lückensätze bleiben ohne App-Einstieg, weil mehrdeutiger Inhalt und direkte Belohnungsbuchung noch überprüft werden müssen. Exakte UI-Auswahl aller 236 Generatorfamilien und jede generierte Variante sind nicht durchgespielt.
- **18 geschützte Schreib-/Journaldateien sind bytegleich** zu `6f4a8c4753f4d06d0b392da0789b8162b2faa71b`; Einzelhashes stehen in JSON. Kart und nativer Dschungel bleiben ausgeschlossen. Der eigenständige 2D-Flame-Lernpfad bleibt im Inventar.
- Finaler Release-SHA, signierte APK-Provenienz, CI-Ergebnis und Download werden von Root nach Integration ergänzt. Aus dieser Bestandsaufnahme folgt keine neue APK-Freigabe.

## Reproduktion

```bash
flock --close /workspace/scratch/c5a7dadab95f/toolchain/lumo-flutter.lock \
  /workspace/scratch/c5a7dadab95f/toolchain/flutter/bin/flutter test --no-pub \
  tools/nextgen/export_learning_catalog_test.dart \
  --dart-define=LUMO_CATALOG_OUTPUT=/tmp/lumo-learning-catalog.json
python3 tools/nextgen/build_coverage.py /tmp/lumo-learning-catalog.json
```

Der Builder verweigert einen Katalog mit abweichendem HEAD, uncommittete Produktquellen und veränderte verifizierte Modul-Screen-Hashes. Der neue Produktstand muss daher zuerst integriert und erneut exportiert werden. Quellen, Testprotokolle und Teamberichte haben bewusst unterschiedliche Evidenzstufen.
