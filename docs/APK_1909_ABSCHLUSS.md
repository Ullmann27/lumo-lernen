# APK 0.12.6+1909 – Abschluss der Action-/Werkstatt-Etappe

Die signierte, installierbare APK ist gebaut und bereitgestellt. Sie enthält den integrierten Claude-Stand mit 14 Karts und Tuning sowie den fertig angeschlossenen kostenlosen Werkstatt-Prüfstand, Sonnenhafen-Aquarium mit animiertem Wasser/Fischen und sanfte Hütchen-Hindernisse.

## Unveränderliche APK-Identität

- App-Quellstand: `aa6519226fded77d5d5022dc6fe8c223e9dc82b8`
- Godot-Quellstand: `a377b9e2db3337ae46f9439200ef0af17af06cb5`
- Paket: `dev.ullmann.lumo.lumo_lernen.coachpreview` – Update der Variante **Lumo Lernen Neu**
- Version: `0.12.6+1909`; 203803554 Bytes; ARM64 und x86_64
- SHA256: `b58e055340595ac882fed47d0c11660f2420e41c1528ed2841c5100f13304fb7`
- Signatur, eingebetteter PCK, Quellstand und 16-KiB-Ausrichtung geprüft. Die ausgelieferte Datei wurde mit diesem Hash verifiziert.

## Tatsächlich ausgeführte Prüfungen

| Prüfung | Ergebnis | Nachweis |
| --- | --- | --- |
| APK-Build, 808 Flutter-Tests, 25 native Proben | PASS; 4 vorhandene Flutter-Skips, Analyse ohne Fehler mit vorhandenen Hinweisen | [Build](https://github.com/Ullmann27/lumo-lernen/actions/runs/37888592898/job/113684134979) |
| Android-Werkzeuge | 585 PASS lokal und CI nach den beiden Leserreparaturen | [QA](https://github.com/Ullmann27/lumo-lernen/actions/runs/37896765244/job/113709778539) |
| Bauwelt, Puzzle, Rhythmus, Schatzsuche API 35 | Update/Profilerhalt, Offline-Start, Rückkehr, Save-/Reward-Guards PASS | [ursprünglicher Lauf](https://github.com/Ullmann27/lumo-lernen/actions/runs/37888592898) |
| Kart Android 16 / API 36 | Updateprobe und vollständiges Zwei-Runden-Rennen PASS | [Job 113699324621](https://github.com/Ullmann27/lumo-lernen/actions/runs/37893374564/job/113699324621) |
| Kart Android 15 / API 35 | Updateprobe und vollständiges Zwei-Runden-Rennen PASS | [Job 113710020612](https://github.com/Ullmann27/lumo-lernen/actions/runs/37896765244/job/113710020612) |

Beide vollständigen Kart-Läufe prüfen 16 Checkpoints, Pause/Fortsetzen, Emulator-Größenwechsel und Rotation, echtes Ergebnis, Offline-Wiederaufnahme, sichtbare Rückkehr zur Flutter-App, Host-ACK und unveränderte Wallet bei erneut geöffnetem Ergebnis. Gefahren wurde mit der öffentlichen Automatikgas-Einstellung und bestehender Anfänger-Fahrhilfe.

Alle Nachläufe verwenden exakt dieselbe APK; nur die Testwerkzeuge unterscheiden sich: API 36 `7a570c1fc69b21f0e081ace208b082796bc30057`, API 35 `5e5316ce764e189e46fe15297c112141be0e7695`. Die APK wurde dadurch nicht verändert.

- API-36-Artefakt `11601316198`, SHA256 `4ad47d9efc18d1594e94297dedc6946b96cd2918f4c39ec613053168c2fbca40`; [ausgezogener tatsächlicher Ergebnisbericht](proof/2026-10-09-android16-kart/result-summary.json).
- API-35-Artefakt `11602981419`, SHA256 `387c42aed84481b28df937f20347f8017cf069fa7291e70e5c0d426fca2d32fd`; Logabschluss: `[CompleteKartAndroid] PASS: 16 checkpoints, pause, actual result, offline recovery, host ACK and reward deduplication`.

## Erhaltene Fehlläufe und Grenzen

Die Gesamt-Workflows sind **nicht durchgehend grün**: Die ursprünglichen Kart-Läufe stoppten am belegten DRIFT-Bildleser-Fehlnegativ. Der erste API-35-Nachlauf scheiterte an ADB-Screenshot-Exit 255 beim Größenwechsel; der zusätzliche API-36-Lauf an einem OCR-Zeitlimit vor dem Rennen. Beide Leserreparaturen und ihre Grenzen sind in [APK_1909_ANDROID_READER.md](APK_1909_ANDROID_READER.md) dokumentiert. Kein Fahr-, Touch-, Speicher- oder Belohnungsgate wurde entfernt. Die oben genannten erfolgreichen Jobs sind eigenständige echte Nachläufe.

Kein physisches Samsung/Fold, keine 60-FPS-/Framezeit-Abnahme, keine vollständige Referenzvideo-Gleichheit und keine umfassende manuelle Fahrgefühl-Abnahme. Die anderen vier Spiele haben hier Start-/Update-/Speicherschutzprüfungen, keine vollständigen Spielabschlüsse. Die bereitgestellten echten Android-Aufnahmesegmente sind stumm und belegen keine Musik-/Stimmenqualität. Frühere weitergehende Gestaltungsziele bleiben getrennte offene Qualitätsarbeit.

Quellen und Übergaben liegen in App-PR #223 und Godot-PR #32. Kein Main-Merge und kein Release. App-PR #223 ist ein Entwurf; ein bestehender Konflikt mit main in `lib/features/writing/writing_engine.dart` muss vor einem später beauftragten Merge aufgelöst und neu geprüft werden. Der geprüfte APK-Quellstand bleibt unverändert.
