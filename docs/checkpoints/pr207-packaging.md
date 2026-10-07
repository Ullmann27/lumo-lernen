# PR207 – Android-Paketprüfung und Fortsetzung

Dieser Nachtrag ersetzt den alten APK-PENDING-Abschnitt in `3d-launch-lifecycle-2026-10-07.md`. Die dort dokumentierten Launcher-/Fortschrittsreparaturen bleiben enthalten. Kein Merge nach main und kein Produktionsrelease.

## Identitäten

- BASE: `35299467b7c2b9077b00160e4c7dba86c82f3d03` (PR202).
- Repository/Branch: `Ullmann27/lumo-lernen` / `chatgpt/3d-launch-lifecycle-2026-10-07`.
- Getesteter und gebauter APK-SOURCE: **`35a7a0a56a9519fb6c33e35b5aad78cd6f589d08`**.
- Build: **Run37566239982**, Job112614501634, sämtliche Schritte erfolgreich.
- Godot unverändert: `c650ff17a5b6a8016fccab0d9b530e0260c6c797`, Engine4.6.3.
- PR204 und PR206 sind NICHT integriert; deren Arbeitsbereiche bleiben unabhängig.
- Danach nur Prüfharness-Commits69a1652 und99f2746; APK-SOURCE bleibt35a7a0a.

## Belegter Verpackungsfehler und Korrektur

Der erste tatsächlich gebaute Kandidat aus4a50e01 war technisch signiert und lauffähig, enthielt aber das Flutter-Standardicon und `tracked_source_clean=false`. Er bleibt DIAGNOSE, nicht die freigegebene aktuelle Lieferung.

Run37565052146 protokollierte Git-Diffs nach jedem Vorbereitungsschritt. Bis einschließlich aller Tests waren getrackte Quellen unverändert. `flutter create` im Repository aktualisierte `pubspec.lock`: image_picker1.2.3→1.2.4, image_picker_platform_interface2.11.1→2.11.2, jni_flutter1.0.3→1.0.4+1 und shared_preferences2.5.5→2.5.6. Ein Paket mit dieser nachträglichen Auflösung ist nicht mehr genau der zuvor getestete Abhängigkeitsstand.

Der erste Gegenversuch mit `flutter create --no-pub` im Projekt und strikt gesperrter Paketauflösung scheiterte in Run37565787830 an der abschließenden locked-Paketauflösung; der Build lieferte richtigerweise keine erfolgreiche APK. Acht Icon-Tests waren bereits grün. Dieser Fehler wird nicht verschwiegen oder als Erfolg gewertet.

Die tatsächliche Korrektur in `scripts/build_unified_apk.sh` erzeugt das Flutter-Scaffold in einem eigenen temporären Verzeichnis und übernimmt ausschließlich dessen Android-Host. Im Quellprojekt bleiben die getrackten Pakete unverändert. Locked-pub-get, Build ohne erneute Paketauflösung und Git-Integritätsprüfungen vor/nach Build verhindern unbemerkte Änderungen. **Der erfolgreiche Build37566239982 bestätigt `tracked_source_clean=true`.**

## Native Lumo-Icons

Quelle ist das bestehende `assets/lumo_design/fox/fox_avatar.png`, 512×512 RGBA, SHA256:
`8211f7347e8be4dc6f37acd3490bb6bc0976285cfef195a430b7480c6e53b53f`.

Vorhandene echte Alphadaten wurden geprüft. Keine Hintergrundentfernung behauptet, keine neue Figur erfunden und keine Grafik aus einem Konzeptbild als 3D-Modell ausgegeben.

Buildhelper `scripts/prepare_launcher_icons.py` erzeugt 25 native Ressourcen: Legacy-/Round-Icons in fünf Dichten, adaptive Foreground-Layer, API26-/API33-XML und monochrome Varianten. Die Abhängigkeit Pillow12.3.0 liegt nur im isolierten Build-venv, nicht in der App. Acht Tests prüfen Maße, Safe-Zone, Manifest-Verweise, Alphadaten, Idempotenz und fehlerhafte Eingaben.

APK-Prüfung bestätigt die kompilierten Manifest-IDs `icon→mipmap/ic_lumo` und `roundIcon→mipmap/ic_lumo_round`. Die installierte Launcher-Darstellung wurde zusätzlich in Run37567490735 visuell kontrolliert: **Lumo-Fuchs sichtbar**. Das ist mehr als eine unbenutzte PNG-Datei im Repository, aber keine Prüfung aller realen Hersteller-Launcher oder Theme-Modi.

## Abgeschlossene Prüfungen des APK-SOURCE35a7a0a

- Vollständige Flutter-Suite: **641 PASS /4 SKIP /0 FAIL**.
- Darin enthalten: 14 Launcher- und15 Fortschritts-/Spielprüfungen, nicht doppelt addieren.
- Backend: **22 PASS /0 FAIL**.
- Bestehende Android-Vorbereitung: **5 PASS**.
- Neue native Icons: **8 PASS**.
- Inhaltsaudit: **40.960 Aufgaben geprüft, PASS**.
- Projektanalyse: keine Compilerfehler, **144 Hinweise/Warnungen bleiben**.
- Signatur, Paket-ID, arm64/x86_64, eingebettetes PCK, ELF-/Ressourcenalignment: PASS.
- Exakte Quellen-/APK-Digest-Prüfung und ZIP-CRC: PASS.

## Tatsächlich vorhandene APK

- Name: `Lumo Lernen Neu`.
- Paket: `dev.ullmann.lumo.lumo_lernen.coachpreview`.
- Version: `0.10.5+280`.
- Größe: **169227348 Byte**.
- SHA256: **`dbd445466a49ed4e23a899f4a166c19d7f11cc4200a3835efc53f1937befd970`**.
- Unverändertes Testsignatur-Zertifikat: `a6b1ef61bf59db4e0794c742aeb3b5506d130f4d21175c9975140e6acdb80702`.
- Godot-PCK SHA256: `eb33e82a34b89339b34db6a544671a56613a7da2d0c9c3fb3bb98967b5eb9f6f`.
- APK-Artefakt11458917531, `lumo-pr207-apk-37566239982`, ZIP-SHA256 `07e89f0e31d6c6c70ab25351fd80f0f43ff892764cb475e60adbd595ebf671e3`.
- Buildbeleg11458754761, ZIP-SHA256 `76d1723b7ff120b4f7bb8084a40ad1e659e32fa5d17fd77e16900b2932f0fda7`.

Dies ist eine technische Testversion und kein globales Update aller parallelen PRs. Bei bereits höher nummerierten Testversionen keinen Downgrade durch Deinstallation oder Datenlöschung erzwingen.

## Android-Runtime: getrennt von Build-Erfolg bewerten

Baseline-Run37564720942 bestand Installation, Offline-Start, fünf Auflösungswechsel mit gleichem App-Prozess und Offline-Neustart, allerdings auf dem ursprünglichen Diagnosepaket.

Auf der korrigierten APK bestätigte Run37567490735 dieselben vorbereitenden Schritte, die gleiche PID3479 über die fünf Größen und den Offline-Neustart mit PID3971. Der Gesamt-Lauf scheiterte anschließend am **Prüfwerkzeug**, nicht an einem beobachteten Profilspeicherfehler: Android-CLI `uiautomator dump` lieferte keine XML-Datei; der Reader versuchte den `cat: ... No such file`-Fehltext als XML zu parsen. Originalartefakt11458948898, SHA256 `8bbe58f2e8a83dbfd849114c120cc3a35468af9229b1b6718d6b3d3b07ac5e66`.

Der korrigierte Testadapter99f2746 verwendet isoliert uiautomator2==3.7.0 mit deaktiviertem UI-Idle-Warten. Er liest echte Accessibility-Labels und Bounds, um ohne geratenes Antippen ein fiktives Profil LumoTest anzulegen, den Spielebereich zu öffnen, dessen Größe zu wechseln und nach Offline-Neustart das Profil wiederzusehen. Die APK wird dabei nicht verändert. **Run37568213986 ist beim Schreiben dieses Checkpoints noch in Arbeit: Ergebnis muss gelesen werden, kein PASS vorwegnehmen.**

## Offene Grenzen / nächste Abnahme

Keine vollständige Cards-Partie, kein kompletter Kart-Rennlauf, kein physischer Fold-/Scharnierwechsel, keine 60-FPS-Messung und keine globale visuelle Abnahme. Auf der schmalen Onboarding-Ansicht ist die primäre Schaltfläche am unteren Rand schlecht sichtbar; Erreichbarkeit und visuelle Abweichung separat prüfen. Keine unabhängige Fremd-Codeprüfung behauptet; PR bleibt Draft.

Nächste Schritte: (1) aktuellen Runtime-Run einschließlich XML/Screenshots tatsächlich auswerten und Checkpoint ergänzen; (2) freigegebene Gesamtintegration mit getrennten #204/#206-Lanes koordinieren, ohne automatisch zu mergen; (3) vollständige Cards-/Kart-Abläufe, Rückkehr/Speichern und physische Geräte-/Grafikprüfung fortsetzen.

Wiederaufnahme: zuerst HEAD und #170-Claims neu lesen. `git fetch origin chatgpt/3d-launch-lifecycle-2026-10-07`, separater Worktree, locked Flutter-Analyse/-Tests. Bereits gebaute APK immer über SOURCE35a7a0a und Digest identifizieren; aktueller Dokumentations-/Harness-HEAD ist nicht automatisch der APK-SOURCE.
