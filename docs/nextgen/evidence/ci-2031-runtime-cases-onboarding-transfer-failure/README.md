# Zusatzlauf 5 — Geräteverbindung beim ersten Videotransfer nicht beobachtbar

[Run 43826704611](https://github.com/Ullmann27/lumo-lernen/actions/runs/43826704611), Job **133162141099**, QA **59ab8cd000d4cca1c9c414920ccebf9fc5d1c7ba**, Tree **79f623d398e7c64275d8f3b894f169c2d29b54c4**, `caseAttempt=5`. Workflow **FAIL**, Abschluss **16.11.2026, 07:55:52 UTC**. Tatsächlicher Probezeitraum **07:53:57–07:55:37 UTC**. Die exakte APK-/Quellgrenze und alle vorgeschalteten Hostprüfungen sind bestanden; die eigentlichen vier Zusatzfälle wurden noch nicht begonnen.

## Exakter ursprünglicher Ablauf

Der frische fiktive Kinderprofilweg erreichte die App-Startseite. Bei Finalisierung des allerersten Videos `0001-onboarding` waren vor dem Transfer keine `screenrecord`-PIDs vorhanden. Die aktuelle Identität war Serial **emulator-5554**, Kernel-Boot-ID **e7c3aaa4-db01-41b6-adc6-797e3d3ad50f**. Die beendete Remote-Datei meldete **2.556.373 Bytes**, SHA-256 **060f6cc129b997041c78992ce71f18f43467760c20e2f20e9138a366e50e9457**.

Der erste `adb pull` scheiterte mit Exit 1 und leerem Ausgabetext. Die erste Zustandsabfrage danach lieferte exakt **`adb: device offline`**; der vorhandene enge Leser beobachtete diesen Zustand passiv bei 0,438 Sekunden. Die nächste Antwort lautete jedoch **`adb: device 'emulator-5554' not found`**. Das bestehende harte Gate wertet dies nicht als nachgewiesen beendeten Recorder. Es brach mit **`Owned recorder is still running or its state is unobservable`** ab, nach insgesamt **0,691 Sekunden**. Keine zweite Kopie, kein als gültig ausgegebenes MP4, keine wiederholte Aufnahme oder Lernhandlung. [Originaler Transferbericht](original/android/runtime-cases/0001-onboarding-video-transfer.json), [ursprünglicher Recorderfehler](original/android/runtime-cases/0001-onboarding-recording-error.json).

Auch der erste Fehler-screencap meldete Exit 255 und `device not found`; danach liegt ein tatsächliches Startseiten-PNG vor. [Unverändertes screencap-Protokoll](original/android/runtime-cases/0024-runtime-failure-current-screen-screencap-recovery.json), [späteres Fehlerbild](original/android/runtime-cases/0024-runtime-failure-current-screen.png). Das belegt weder die genaue Ursache/Dauer der Unterbrechung noch dieselbe Kernel-Boot-ID nach Rückkehr. Der erwartete Remote-Dateihash ist keine vollständige Video-Bewahrung; die Videobytes konnten in diesem Lauf nicht erfolgreich übertragen werden.

Das [Originalresultat](original/android/runtime-cases/runtime-cases-result.json) bleibt **FAIL**, `release_eligible=false`, `fullModernizationComplete=false`. Zahlenfehler/Korrektur, aktiver Wortwechsel, Langsamer und Stopp sind in diesem Lauf nicht erreicht. Auch die neue Numeric-Capture-Sequenz wurde noch nicht ausgeführt. Ein späterer neuer Lauf darf diesen Fehler nicht ersetzen oder als bestanden umdeuten.

## Vollständige tatsächlich vorhandene Belege

Artefakt **14206892378**, **6.127.681 Bytes**, SHA-256 **006babb5945723d051b4bc10c3fc55dcf3cf3481a5d6309a4e6ef6850779bf3e**. Alle **57 Originalmitglieder / 6.735.172 unkomprimierte Bytes** wurden nach Pfad, Größe, CRC und SHA geprüft. Das vollständige ZIP ist bytegenau in einem Archivteil und alle 57 Originale zusätzlich unverändert entpackt erhalten: [Archivmanifest](archive-retention.json), [Mitgliederprüfung](artifact-verification.json), [Originalbindungen](all-originals.json).

Das vollständige Rohjoblog liegt unter [job-log](job-log/job-log-manifest.json): **556.082 Bytes**, SHA-256 **e720987d9202c7303bddf04c60b8991d69284f9cd07ab3e10917f0df480ee9e2**, zusätzlich verlustfrei gzip-komprimiert. Run-, Job- und Artefaktmetadaten sind separat gespeichert.

Die bereits veröffentlichte APK und der vollständige erfolgreiche Replay bleiben unverändert. Ein weiterer frischer Zusatzlauf wird ausschließlich anhand dieser konkreten Transportbeobachtung geprüft; gemeinsame Gates werden dafür nicht abgeschwächt. Noch kein weiterer Lauf oder aktiver Stopp-PASS ist in diesem Archiv behauptet.
