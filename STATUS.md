# LUMO 2032 — Quellvalidierung bestanden, APK-Build läuft

Stand: **16. November 2026, 09:37 UTC**. Der vollständige Lauf [43837592237](https://github.com/Ullmann27/lumo-lernen/actions/runs/43837592237) hat die Validierung abgeschlossen. **Buildjob 133206155437 kompiliert derzeit die integrierte Android-App. Androidtour und Veröffentlichung sind noch nicht abgeschlossen.**

## Exakte Identität

| Teil | Tatsächlicher Stand |
|---|---|
| Aktivierte APK-/QA-Quelle | `9b38360ca5f21919dce4a2b99e605ee39bbbf454` |
| Quellbaum | `1c572ff37dde942229e8ae8b1f141ec95df50545` |
| Gepinnte native Quelle | `9d6ef1d704a0e54098a8f8f0818f36deae0e3789` |
| Native Tree | `26b6e5301372d4ade91ca8955f7c1ccf5d0dee78` |
| Version | `0.13.20+2032` |
| Branch in beiden Repositories | `integration/lumo-nextgen-learning-20261115` |
| Paket | `dev.ullmann.lumo.lumo_lernen.coachpreview` |
| Bestehendes Testzertifikat | `a6b1ef61bf59db4e0794c742aeb3b5506d130f4d21175c9975140e6acdb80702` |

Nachfolgende Dokumentationscommits verändern nicht die Quelle des laufenden Builds. Es wurde kein Merge nach `main` vorgenommen.

## Tatsächlich abgeschlossene neue Validierung

Job **133197989015: SUCCESS**. [Unveränderte Originale und Auswertung](docs/nextgen/evidence/ci-2032-validation/README.md), [Root-Integritätsprüfung](docs/nextgen/evidence/ci-2032-validation/root-integration-review.json).

| Prüfebene | Ergebnis |
|---|---:|
| Vollständige Flutter-Suite | **2.896 PASS / 202 SKIP / 0 FAIL** |
| Analyzer | **0 Fehler / 4 Warnungen / 274 Infos** |
| Host-unittest | **174/174 Methoden PASS**, darin alle 11 neuen aktuellen Stoppfälle |
| Tatsächlicher Godot-Import | **SUCCESS**, Godot `4.6.3.stable.official.7d41c59c4` |
| Native Regressionen | **13 Programme / 55.631 Prüfaussagen**, darin 79 Kontrastchecks |
| Separater Projektvalidator | **118 PASS / 0 WARN / 0 FAIL** |
| Quellbindung | **364** Coverage-Quellhashes und **18** bytegleiche Schutzdateien |

Die 202 Skips bleiben Skips; individuelle Gründe sind aus dem parallelen expanded-Original nicht zuverlässig zuzuordnen. Die vier Analyzerwarnungen betreffen ungenutzte Importe/Felder. Der isolierte Avatarprüfer enthält weiterhin eine erhaltene ObjectDB-Warnung beim Beenden. Keine warnungsfreie Gesamtprüfung behauptet. Native Headless-/Hostprüfungen sind keine neuen Android-, Mikrofon- oder Akustiknachweise.

Artefakt **14212363195**, vollständiges ZIP **264.077 Bytes**, SHA-256 `167bed7006a1fcad952685f92f9583f6158a5f5bc1434a9c153484e24b3d41cd`. Alle **58 Originalmitglieder** und der vollständige Rohjoblog sind erhalten. Root hat das gesamte Übergabepaket, ZIP/Originalbytes, Schlussresultate und Quellbindungen unabhängig nachgeprüft.

## Inhalt und Abdeckung

Die integrierte Lernwelt besitzt den versionierten Aufgaben-/Gesprächsvertrag, den ursprünglichen weiterbearbeiteten Lumo-Fuchs und aufgabenbezogene native Erklärwege. Die konkrete neue Produktänderung für 2032 korrigiert die Schriftfarben interaktiver nativer Lernbuttons. Der neue aktuelle Stoppfall gehört verpflichtend zur Referenztour und zur Veröffentlichungsprüfung.

Der [aktuelle Katalog](docs/nextgen/COVERAGE.md) erfasst **61 Inventareinträge, 55 Screen-Dateien und 236 Lehrplanfamilien**. Das sind keine 236 spezialisierten, gerätegeprüften 3D-Szenen. Zahlreiche Einstiege nutzen die allgemeine native Aufgabenkarte; Godot bleibt die bestehende separate Activity. **`fullModernizationComplete=false` bleibt zutreffend.** Physischer Fold7/ARM64, deutsche STT, alle Varianten, durchgängige 48-dp-Abnahme, gemeinsame akustische Mund-/Gesten-Stoppmessung und 60 FPS sind nicht nachgewiesen.

Der [Bericht 2032](docs/nextgen/ANDROID_DELIVERY_2032.md) bleibt **DRAFT_PENDING_CURRENT_ANDROID_AND_PUBLICATION**. Frischer Katalogexport: Run **43836322226**, Quelle `a5ea7422b1152576b34cf80519856129ff264ac1`, tatsächlicher Exporttest **1 PASS**, 480 geprüfte Exportquellen. [Originalbelege](docs/nextgen/evidence/ci-2032-catalog-export/README.md).

## Nächster Schritt und Historie

Den laufenden Build, beide tatsächlichen Androidtouren samt aktivem Stopp und den vollständigen anonymen Download begleiten. Neue APK-/PCK-Hashes, Paket-/Signaturprüfung und echte Medien ausschließlich aus dem aktuellen Lauf ergänzen. [Konkrete Wiederaufnahme](CONTINUE.md).

Die bereits veröffentlichte [APK 2031 und ihre Befunde](docs/nextgen/ANDROID_DELIVERY_2031.md) bleiben historisch; sie ersetzen keine Abnahme der korrigierten 2032-Bytes. Alle alten Originalfehler und Archive bleiben in Git/remote erhalten. Die zuvor langen laufenden Statusnotizen sind vollständig im [gesicherten Statusstand vor dieser Kürzung](https://github.com/Ullmann27/lumo-lernen/blob/7b2cabc89ace083eb7f30d9d06f19c7d840406e5/STATUS.md) nachlesbar.
