# Englisch: konkreter Anschluss an die vorhandene 3D-Lernhilfe

Stand: 14. November 2026, während Run 43530667812 noch vor den Android-Zieljobs läuft. Dies ist eine reine Quellenprüfung; keine Produktänderung und kein neuer Testlauf.

Geprüfte Quellen: Host `4ab96666f954baf258422d6ed277fc297b7ddeef`, Native `803e7a626ea6ef0aeeda9c37010e844033d3a8e3`. Alle 23 im benachbarten `source-binding.json` aufgeführten lokalen Dateien stimmen als Git-Blobs mit den exakten veröffentlichten Trees überein. Der ältere lokale Git-HEAD wird nicht als Kandidatenquelle ausgegeben.

## Tatsächlicher Bestand und fehlende Verbindung

| Bereich | Konkreter vorhandener Pfad | Befund |
|---|---|---|
| Aktuelle Aufgaben | `lib/core/school_exercise_generator.dart`, `_english()` ab 1082, Grundwortschatz ab 1161 | Der Generator wählt ein Wort aus der tatsächlichen Klassenstufe und Einheit und erstellt eine Übersetzungsaufgabe mit überprüfbarer richtiger Antwort und Distraktoren. Beispiele: Klasse 1 `red → rot`; Klasse 2, Spielzeug, `ball → Ball`; Klasse 3, Wetter, `sun → Sonne` und `rain → Regen`. Die Einheiten fallen bei Wiederholung auf vorhandene frühere Klassen zurück. |
| Zusätzlicher Wortschatz | `lib/core/english_vocabulary_extensions.dart` | Lokale Erweiterungen pro Klasse; zum Beispiel zusätzliche Farben, Körperteile und Schulsachen. Keine native Objektkennung. |
| Offline-Rückfall | `lib/core/safe_fallback_pool.dart`, `_english` ab 139 | Eigene Englischaufgaben für alle vier Klassen; alternative Formulierung `Was heißt red auf Deutsch?`. Ein späterer Adapter darf nur ein geprüftes Wort und dieselbe tatsächliche Antwort übernehmen. |
| Gemeinsame Task-Daten | `lib/features/learning/adapters/legacy_lumo_task_adapter.dart`, `toTaskInstance()` und `_visualData()` ab 656 | Die geprüfte Aufgabe erhält den richtigen englischen Fachtyp, unveränderte Antwortoptionen, Kinder-ID und Seed. Es gibt keinen speziellen Englisch-Visual-Payload. |
| Native Zulassung | `lib/domain/tutoring/native_learning_activity.dart`, `fromTask()` | Enthält begrenzte Mathematik- und Silbenfälle. Für `LearningSubject.englisch` wird kein Deskriptor erzeugt. Daher erscheint der vorhandene 3D-Hilfeknopf für diese Aufgaben nicht. |
| Native Gegenprüfung | `tools/auto_install/MainActivity.kt:192`; Native `scripts/learning/learning_activity.gd:configure()` | Beide erlauben nur die neun vorhandenen Aktivitätstypen. Ein neuer Wort-Objekt-Typ benötigt beide streng validierenden Anschlüsse. |

## Kleinster konkret integrierbarer Pfad

Als erster begrenzter Objektfall eignet sich die **im vorhandenen Generator enthaltene Klasse-2-Aufgabe `Was bedeutet „ball“?` mit Antwort `Ball`**. Die neue Hilfe kann denselben realen 3D-Körper anfassen/verschieben und das englische Wort mit der deutschen Bezeichnung verbinden. Der normale Flutter-Aufgabenabschluss bleibt danach die einzige bewertete Antwort. Das ist ein kleiner tatsächlich erreichbarer Englischpfad, keine Behauptung eines vollständigen Vokabelspiels.

Für diesen Fall existiert bereits die echte geometrische Grundlage: `learning_world.gd:_sphere()` erzeugt eine `SphereMesh` mit 16 Segmenten und acht Ringen; `_text()` erzeugt extrudierte `TextMesh`-Geometrie. Material-, Kamera-, Touch- und Atelieraufbau sind im produktiven Lernraum vorhanden. Die Einheit Farben kann anschließend dieselben Körper verwenden, sofern der jeweilige aktuelle Wort-/Antwortkatalog ausdrücklich validiert wird. Dafür werden weder ein Bildsprite noch ein fremdes Charaktermodell benötigt.

Weitere **tatsächlich vorhandene** Modelle sind Sonne, Wassertropfen, Blätter und Blüte in `learning_world.gd:_build_plant()`. Sie passen zu einem späteren eng zugelassenen Wetter-/Naturwortschatz. Die Bücher im Blender-Studio sind dagegen nur Hintergrundgeometrie: `tools/art/build_learning_studio.py` erzeugt Deckel, Seiten und Rücken und vereinigt sie anschließend materialweise. `assets/learning/studio/learning_studio.glb` ist deshalb kein fertig getrenntes, auswählbares Buch-Asset. Ein eigenständiges Buch wäre eine kleine zusätzliche Geometriearbeit, kein bereits angeschlossenes Interaktionsobjekt.

Der schlanke Deskriptor sollte aus der **bereits qualitätsgeprüften Aufgabe** stammen: nur bekanntes Wort, verifizierte deutsche Entsprechung, explizite Objektkennung und gültige Einheit/Klasse. Eine unbekannte Kombination bleibt beim bestehenden Renderer. Kein freier Szenenpfad, keine beliebige Sprachzeichenfolge und keine aus einem Hilfeklick abgeleitete richtige Antwort. Vorhandene Generator- und Rückfallformulierungen müssen beide erkannt oder über explizite geprüfte Metadaten angebunden werden.

## Sprache: konkrete Grenze

Die heutige lokale Stimme unterstützt im Vertrag nur Deutsch. `LumoVoice.selectedLocale` ist `de-DE`; `LumoOfflineVoiceClient` akzeptiert ausschließlich Profil `lumo-free-supertonic-de-v1`, Preset `F2`, Sprache `de` und lokale 44.100-Hz-WAV-Daten. `LumoOfflineSpeechEngine.prepareGerman()` umschließt jeden Text mit `<de>…</de>`. Ein englisches Wort unverändert dorthin zu senden wäre kein belegter englischer Aussprachepfad.

Der bestehende native Anschluss ist dagegen gut wiederverwendbar: `learning_world.gd:_speak()` → `LumoHost.speakLearning()` in `LumoGameActivity.kt` → `LumoLearningSpeech.kt` → `LumoOfflineSpeechBridge.kt`. Er bietet echte Start-/Abschlusszustände, begrenzte Texte, Generation/Abbruch und lokale Wiedergabe. Die spätere englische Aussprache benötigt einen gesondert verifizierten englischen Sprachvertrag oder qualitätsgeprüfte lokale Wortaufnahmen. Die vorhandenen deutschen Wortclips sind kein Ersatz. Bis dahin kann die Objekt-Hilfe deutsche Erklärungen sprechen und das englische Wort sichtbar zeigen; englische Aussprache bleibt ausdrücklich offen.

## Bestandsschutz und Dateibesitz für eine spätere Freigabe

`learning_content.dart:_openNativeLearning()` markiert die angeforderte 3D-Hilfe **vor** dem Start als Hilfelevel mindestens 1, bindet Task-ID und Profilgeneration und schreibt bei der Rückkehr keine Antwort. `lumo3d_launcher.dart` hält die stabile Profil-Lease, Kinderschlüssel, Rückkehrprüfung und lokale Stimmfreigabe zusammen. Diese Schnittstellen sind zu verwenden, nicht zu ersetzen. Keine neue Speicherung, Migration oder Netzwerkabfrage ist für den ersten Objektfall erforderlich.

| Vorgeschlagener Besitzer nach Freigabe | Begrenzte Dateien/Arbeit |
|---|---|
| A, Lernintegration | `legacy_lumo_task_adapter.dart`, `native_learning_activity.dart`, begrenzter geprüfter Wort-/Objektkatalog; Native `learning_activity.gd` und `learning_world.gd`. Aktuelle Aufgabe und Kind müssen unverändert die Quelle bleiben. |
| Root, Hostintegration | `tools/auto_install/MainActivity.kt` für die neue enge Typzulassung und zugehöriger Bridge-Vertrag. Kein Eingriff in Rückkehr-/Profil-/Belohnungslogik. |
| Root bzw. eigener Sprachauftrag | Erst nach gesonderter Freigabe: `LumoOfflineVoiceClient`, `LumoLearningSpeech.kt`, `LumoOfflineSpeechBridge.kt`, `LumoOfflineSpeechEngine.java` oder geprüfter lokaler Wortkatalog. Deutschprofil und Elternfreigaben bleiben gültig. |
| Bestehende Prüfanschlüsse | `test/tutoring/native_learning_launch_test.dart`, `test/tutoring/native_sharing_activity_test.dart` für Hilfe/Rückkehr/Profilbindung; `test/academy_english_science_tap_navigation_test.dart` für den realen Englischweg; Native `scripts/tests/learning_world_regression.gd` plus tatsächliche Rendereraufnahme des neuen Objektfalls. Hier wurden keine Tests ausgeführt. |

Die laufenden API37-/Update-Abnahmen von 4ab/803e behalten Vorrang. Dieser Befund autorisiert keine Änderung am eingefrorenen Kandidaten.
