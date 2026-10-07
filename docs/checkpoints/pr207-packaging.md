# PR207 – geprüfte Android-Testversion und Entwicklungscheckpoint

Abschluss dieser abgegrenzten Etappe am 7. Oktober 2026. Dieser Nachtrag ersetzt alle APK-/Runtime-PENDING-Angaben in früheren Checkpoints. Kein Merge nach main, kein Produktionsrelease und keine Behauptung einer Weiterarbeit nach Ende der Sitzung.

## Identitäten und Isolation

- Repository: `Ullmann27/lumo-lernen`.
- Branch/PR: `chatgpt/3d-launch-lifecycle-2026-10-07` / #207, weiterhin Draft für unabhängige Gegenprüfung.
- BASE SHA: `35299467b7c2b9077b00160e4c7dba86c82f3d03` (PR202).
- APK / getesteter Produkt-RESULT SHA: **`35a7a0a56a9519fb6c33e35b5aad78cd6f589d08`**.
- Letzter erfolgreich ausgeführter Android-Prüfharness: **`29c73b9c5ff78f5b1cedc6cdc257d1600e0a1468`**.
- Build: **37566239982**, Job112614501634, alle Schritte erfolgreich.
- Android-Runtime: **37568866378**, Job112622748207, alle Schritte erfolgreich.
- Godot unverändert: `c650ff17a5b6a8016fccab0d9b530e0260c6c797`, Engine4.6.3.
- PR204 (Curriculum/UI) und PR206 (Cards) sind **nicht integriert**. Keine fremden Branches, Signierung, Secrets, Zahlungen, Spielregeln oder Godot-Pins verändert.
- Nach APK-SOURCE35a7a0a wurden nur Prüfharness und Dokumentation geändert. Aktueller Branch-HEAD ist deshalb nicht automatisch der APK-Quellstand.

## Tatsächliche Produktverbesserungen

### Start und Rückkehr des 3D-Spiels

`lib/features/lumo3d/lumo3d_launcher.dart` schützt Speichern und native Spielrückkehr gegen konkurrierende Startanforderungen – auch wenn die Spiele-Seite neu aufgebaut wurde. Verlassene/überdeckte Seiten und während des Speicherns gewechselte oder zurückgesetzte Profile starten kein verspätetes Spiel. Ein Speicherfehler verhindert den Start. Null-/fehlerhafte Rückgaben werden nicht als erfolgreicher Abschluss gewertet. Busy-, Plugin- und Speicherfehler haben passende Hinweise statt pauschaler Neustartaufforderung.

Native Channel-Argumente und Android-Host-Logik bleiben unverändert. Die 14 fokussierten Tests verwenden kontrollierte native Antworten, nicht einen vollständigen physischen Rennlauf.

### Reihenfolge von Levelergebnissen

`lib/core/game_progress_repository.dart` ordnet vollständige Read-modify-write-Operationen, Reads und Reset pro Kind über alle Repository-Instanzen desselben Dart-Isolates. Gleichzeitige Levelergebnisse überschreiben einander nicht mehr. Ein vor Reset angefordertes Ergebnis belebt die zurückgesetzten Daten nicht später wieder. `saveStars` kopiert die Eingabemap vor dem asynchronen Schritt. Bestehende Bestwert-/Unlock-Regeln bleiben erhalten.

Grenze: Das vorhandene Best-effort-Verhalten bei tatsächlichen Speicherfehlern wurde nicht verändert. Der Queue-Fix ist keine Garantie gegen Datenträgerfehler oder für mehrere Betriebssystemprozesse.

## Belegter Buildfehler und Korrektur

Der erste Kandidat aus4a50e01 war technisch signiert, enthielt aber das Flutter-Standardicon und `tracked_source_clean=false`. Er bleibt DIAGNOSE, nicht die aktuelle Testlieferung.

Run37565052146 protokollierte Git-Diffs nach jedem Vorbereitungsschritt. Bis einschließlich der Tests war der Quellstand unverändert. `flutter create` im Repository aktualisierte `pubspec.lock`: image_picker1.2.3→1.2.4, image_picker_platform_interface2.11.1→2.11.2, jni_flutter1.0.3→1.0.4+1 und shared_preferences2.5.5→2.5.6. Dieser nachträgliche Abhängigkeitsstand war nicht der vorher getestete.

Der erste Gegenversuch mit `flutter create --no-pub` im Projekt scheiterte in37565787830 an der abschließenden strikt gesperrten Paketauflösung. Keine erfolgreiche APK wurde ausgeliefert; acht Icon-Tests waren bereits grün.

Die endgültige Korrektur in `scripts/build_unified_apk.sh` erzeugt das Scaffold in einem eigenen temporären Verzeichnis und übernimmt nur dessen Android-Host. Locked-pub-get, APK-Build ohne erneute Paketauflösung und Integritätsprüfungen vor/nach dem Build verhindern unbemerkte Quellenänderungen. **Build37566239982 bestätigt `tracked_source_clean=true`.**

## Lumo-Icon wirklich in Android integriert

Quelle: bestehendes `assets/lumo_design/fox/fox_avatar.png`, 512×512 RGBA, SHA256 `8211f7347e8be4dc6f37acd3490bb6bc0976285cfef195a430b7480c6e53b53f`.

Echte Alphadaten wurden geprüft. Keine neue Figur, Hintergrundentfernung, Konzeptbild-als-Gameplay oder PNG-als-3D-Modell behauptet.

`prepare_launcher_icons.py` erzeugt 25 native Ressourcen: Legacy-/Round-Icons in fünf Dichten, adaptive Foreground-Layer, API26-/API33-XML und monochrome Varianten. Pillow12.3.0 ist nur im isolierten Build-venv vorhanden. Acht Tests prüfen Maße, Safe-Zone, Verweise, Alpha, Idempotenz und fehlerhafte Eingaben.

Die kompilierten APK-Verweise wurden unabhängig geprüft: `icon→mipmap/ic_lumo`, `roundIcon→mipmap/ic_lumo_round`. Zusätzlich wurde die installierte Android-Launcher-Darstellung anhand echter Screenshots kontrolliert: **Lumo-Fuchs sichtbar**, kein Flutter-Standardlogo. Andere Hersteller-Launcher und alle Theme-Modi sind nicht separat abgenommen.

## Erfolgreiche Prüfungen des APK-SOURCE35a7a0a

| Prüfung | Ergebnis |
|---|---|
| Vollständige Flutter-Suite | **641 PASS / 4 SKIP / 0 FAIL** |
| Darin enthaltene Launcher-Tests | 14 PASS |
| Darin enthaltene Fortschritts-/Spieltests | 15 PASS |
| Backend | 22 PASS / 0 FAIL |
| Bestehende Android-Vorbereitung | 5 PASS |
| Native Icon-Ressourcen | 8 PASS |
| Inhaltsaudit | 40.960 Aufgaben, PASS |
| Projektanalyse | Keine Compilerfehler, **144 Hinweise/Warnungen bleiben** |
| Signatur, Paket, arm64/x86_64, PCK, ELF-/Ressourcenalignment | PASS |
| Unveränderte getrackte Quellen, APK-Digest und ZIP-CRC | PASS |

Die 14+15 Zieltests sind in641 enthalten, nicht zusätzlich zu zählen. Das Inhaltsaudit prüft definierte automatische Regeln, keine vollständige pädagogische Abnahme aller Aufgaben.

Echte Negativbelege: Fortschritt37561184846 mit fünf fehlgeschlagenen Prüfungen; bereinigter Launcher-Test37561798868 mit zehn fehlgeschlagenen Prüfungen. Frühere Fehler im Testaufbau wurden gesondert korrigiert und nicht als Produktfehler gezählt.

## Tatsächlich vorhandene APK

- Anzeigename: **Lumo Lernen Neu**.
- Paket: `dev.ullmann.lumo.lumo_lernen.coachpreview`.
- Version: **0.10.5+280**.
- Größe: **169.227.348 Byte**.
- SHA256: **`dbd445466a49ed4e23a899f4a166c19d7f11cc4200a3835efc53f1937befd970`**.
- Unverändertes Testsignatur-Zertifikat: `a6b1ef61bf59db4e0794c742aeb3b5506d130f4d21175c9975140e6acdb80702`.
- Godot-PCK SHA256: `eb33e82a34b89339b34db6a544671a56613a7da2d0c9c3fb3bb98967b5eb9f6f`.
- APK-Artefakt **11458917531**, `lumo-pr207-apk-37566239982`, ZIP-SHA256 `07e89f0e31d6c6c70ab25351fd80f0f43ff892764cb475e60adbd595ebf671e3`.
- Buildbeleg **11458754761**, ZIP-SHA256 `76d1723b7ff120b4f7bb8084a40ad1e659e32fa5d17fd77e16900b2932f0fda7`.

Technischer Testkandidat, kein globales Update aller parallelen PRs. Bei bereits höher nummerierten Testversionen **keinen Downgrade durch Deinstallation oder Datenlöschung erzwingen**.

## Abgeschlossene Android-Runtime-Prüfung

**Run37568866378: PASS**, Android15/API35, x86_64-Emulator. Installiert wurde exakt obige APK mit geprüftem Digest, nicht ein neu gebauter oder veränderter Testcode.

Tatsächlich über die Bedienoberfläche durchgeführt:
1. Installation und Kontrolle der Launcher-Darstellung.
2. Offline-Erststart mit deaktiviertem WLAN/mobilen Daten und Flugmodus1.
3. Fünf Displaykonfigurationen: 1080×2400/480dpi, 1080×2520/480dpi, 2520×2220/480dpi, zurück1080×2520/480dpi, 1920×1200/240dpi. App-Prozess3644 blieb erhalten.
4. Beenden und erneuter Offline-Start.
5. Fiktives Profil **LumoTest** über Namensfeld, Weiter und Profil speichern angelegt. Profilname auf echter Home-Seite sichtbar.
6. Den tatsächlichen **Spielen**-Button geöffnet und die Spielewelt angezeigt.
7. Spielewelt über Außen-/Innen-/Außen-/Tabletgrößen verändert; App-Prozess4158 blieb erhalten.
8. Erneut beendet und offline gestartet: **LumoTest wurde wiederhergestellt**.
9. Kein Eintrag des Pakets im Android-Crashbuffer.

**14 echte PNG-Screenshots** plus XML-Bedienhierarchien, Geräte-/Prozessdaten und logcat sind im Originalartefakt **11460445734** enthalten. Größe30.007.422Byte; SHA256 **`291feaa37576b6bf30831bc89a20a75d55fd93bbe302611eaaf2740bdfa98ca5`**. Original-ZIP-Digest/CRC und die protokollierten Screenshot-Digests wurden lokal geprüft.

Harness-Fortschritt transparent:37567490735 scheiterte am CLI-UI-Dumper ohne XML-Datei;37568213986 erledigte Profilerstellung und Home, scheiterte dann an der falschen Fixture-Beschriftung `Spiele` statt tatsächlich `Spielen`. Adapter29c73b9 verwendet uiautomator2==3.7.0 ohne Idle-Warten und bindet diesen Schritt an das live nachgewiesene Label. Keine geratenen Bedienelementpositionen, keine Zugangs- oder Produktregeln umgangen; kein Produktfehler aus diesen zwei Testwerkzeugfehlern abgeleitet.

## Visuelle Prüfung und offene Grenzen

Die Originalframes für schmale Spielewelt, breite Spielewelt, Tablet und Profil nach Neustart wurden visuell betrachtet. Das ist keine vollständige Vergleichsabnahme aller Seiten gegen alle Referenztafeln.

**VISUAL_GAP / NOT FINISHED:** Auf schmalem Home werden Titel wie `Lumo ...` und `Tägliche A...` verkürzt; das schwebende Begleitericon überdeckt Teile einer unteren Spielkachel. Bei840dp Breite dominiert das große Spielewelt-Hero den sichtbaren Ausschnitt; Spielauswahl/Primäraktionen sind dort nicht gleichzeitig im ersten Frame sichtbar. Auf dem Tablet sind die Kacheln sichtbar. Das große Bild allein gilt nicht als vollständige Spielbarkeitsprüfung.

Die anfänglich schlecht sichtbare Onboarding-Schaltfläche war über den realen Ablauf/Scroll erreichbar: Profilerstellung bestand. Discoverability/Anordnung bleiben ein Designpunkt, keine Behauptung eines unbedienbaren Profils.

Nicht ausgeführt: vollständige Cards-Partien samt gespeicherter Match-Wiederaufnahme, komplette Godot-Rennen/Rennrückkehr, echte Loopingabnahme, physischer Fold-/Scharnierwechsel, reale Fold7-FPS. Emulatorgrößenwechsel und gleichbleibende PID sind **kein Beleg für 60FPS oder alle physischen Fold-Zustände**. Kartenregeln, Rennphysik, Strecken, Rigs und Konzeptbilder wurden in diesem Paket nicht neu gebaut.

## Nächste drei priorisierte Pakete

1. Unabhängige Gegenprüfung dieser Reparaturen und kontrollierte Gesamtintegration der getrennten #204/#206-Änderungen; gemeinsame Testversion erst mit frischem Gesamt-SHA und bewusst gewählter Update-Version. Nicht automatisch mergen.
2. Vollständige Cards-/Kart-Abläufe, Pausen, Rennrückkehr und gespeicherte Partie im akzeptierten Gesamtstand prüfen; Fehler im jeweiligen freien Arbeitsbereich beheben.
3. Belegte responsive Designlücken schließen und danach physische Fold-/Leistungs-/3D-Referenzprüfung durchführen.

## Wiederaufnahme

Vor Writes aktuelle #170-Claims sowie #202/#204/#206/#207 und Godot#18/#20 neu lesen. Keine fremden uncommitteten Änderungen oder Branches überschreiben. Ein möglicher separater Worktree:

```bash
git status --short
git fetch origin chatgpt/3d-launch-lifecycle-2026-10-07
git worktree add --detach ../lumo-pr207-check FETCH_HEAD
cd ../lumo-pr207-check
flutter pub get --enforce-lockfile
flutter analyze --no-fatal-infos --no-fatal-warnings
flutter test --no-pub --reporter=expanded --timeout=45s --concurrency=2
```

APK immer anhand Produkt-SHA35a7a0a und Digest identifizieren; Dokumentations-/Prüfharness-HEAD getrennt notieren. Keine zusätzliche laufende Arbeit nach Sitzungsende behaupten.
