# Tatsächliche Host- und Speech-Abnahme b721

**Der Job android-host-compile 132517423515 ist im Run 43618076296 auf Host `b7210db3f53361987fd33592de438fd7984d991a` tatsächlich erfolgreich.** Der vollständige Originaljoblog und das kleine Compile-Artefakt wurden erst nach Jobabschluss jeweils einmal abgerufen. Alle 13 ZIP-Mitglieder sind CRC-geprüft; ihre originalen Bytes sind unverändert erhalten.

## Tatsächliche Ergebnisse dieses CI-Laufs

| Bereich | Ergebnis | Abnahmegrenze |
|---|---|---|
| Android-Hostcompile | 18 erforderliche Kotlin-/Java-Klassen erzeugt; Compile-Schritt erfolgreich um 16:58:40 UTC | Kein APK und kein laufendes Androidgerät |
| Java-Sprachverträge | 11/11 Fälle, 103 Assertions, 0 Skip, 2,247 s | Vollständige Enginequelle gegen ausdrückliche synthetische ONNX-Grenzen |
| Kotlin-Sprachverträge | 8/8 Fälle, 0 Skip, 22,170 s | Echte JVM-Ausführung mit deklarierten Android-/Bridge-Fixtures |
| Historische Kotlinverträge | Die ursprünglichen 23 Envelope- und 17 Lifecycle-Assertions wurden in diesem Lauf tatsächlich ausgeführt | Keine Übertragung alter lokaler Erfolge |
| Neue Kotlinfälle | Sechs EN/DE-Szenarien mit 79 Assertions | Keine Modellsynthese und keine gehörte Aussprache |
| Anschließender Table-Transport | 28/28 Fälle, 32,872 s | Bestehender JVM-Vertrag, keine Geräteabnahme |

## Quellen und Toolchain

Die 15 im Runner protokollierten Quellen sind vor und nach dem Lauf identisch an b721 gebunden. Ihr Gitblob-/SHA-Abgleich gegen die unveränderte 2e20-Basis sowie die finalen EN/DE- und Runner-Manifeste steht in `ci-source-comparison.json`. Die beiden Ergebnis-JSONs und ihre Originalprotokolle stimmen mit den eingebetteten Gruppenergebnissen und Loghashes im Runnerbericht überein.

Die tatsächlich beobachtete Toolchain ist Gradle 9.1.0, Kotlincompiler 2.2.0 und Temurin JDK 17.0.21. Der Runner benutzte die vorhandene Wrapper-Distribution mit `--offline`; deren Abfrage endete mit Exit 0. Das Originalresultat dokumentiert 181 Compiler-/Gradle-JARs.

## Warnungen und Abnahmegrenze

Der Compile ist erfolgreich, aber nicht warnungsfrei. Das Originalprotokoll enthält den Hinweis auf die Gradle-Kotlin-DSL-Version 2.2.0 gegenüber der angeforderten 2.2.20 sowie Android-DSL-/Plugin- und Nichtnull-Warnungen. Daraus wird weder ein Compilerfehler noch eine pauschale Unbedenklichkeit weiterer Toolchain-Upgrades abgeleitet. Es wurde kein Quellenpatch vorgenommen.

Dieser Nachweis belegt die tatsächliche Kompilation und die aktuelle JVM-Ausführung. Er belegt keine englische Aussprache mit geladenen Modelldaten, keine angehörte Audiodatei, keine Android-MediaPlayer-Wiedergabe, kein APK und keine Geräteleistung. Die vollständige Flutter-/Feature-Abnahme wird separat geführt.

## Originalbindungen

- Artefakt 14123441105: SHA256 `b7475b6099187a0562cd11b8471f19b755052829014b7c046d42f91a2cf3deeb`, 29.621 Bytes, 13 CRC-validierte Mitglieder.
- Vollständiger Originaljoblog: SHA256 `27a93b089b94a03f12849eb95ab8662440a73cc00a0d00033eef59e22e76d7fc`, 248.796 Bytes.
- Speechresultat: SHA256 `a3ac7e32c7433ca237b1d2102132d9ecae16703158c47b9443e3221965e11b35`.
- Hostcompileresultat: SHA256 `aec93cba646eebcb721714fcf7a4f94c5fce2513dabea228ae91798a827ec3e7`.
