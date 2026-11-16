# Ursprüngliche Androidprüfung 2032: Launcher-Dialog blockiert den Start

Run **43837592237**, **Versuch 1**, Androidjob **133211685356 FAIL**; Veröffentlichung **SKIPPED**. APK-/QA-Quelle **9b38360ca5f21919dce4a2b99e605ee39bbbf454**, Native **9d6ef1d704a0e54098a8f8f0818f36deae0e3789**. Probe **83b3ac99f0144bd3b2ef334a357b1d53**, 16.11.2026 **09:44:57–09:46:04 UTC**.

## Tatsächlicher Abbruch

Die frische Installation und die installierten x86-Bytes sind identitätsgeprüft. Beim ersten Onboarding-Schritt fand der Reader keinen erlaubten Lumo-Knoten für „Los geht's!“. Alle **22** Original-XMLs zeigen den Android-Systemdialog **„Pixel Launcher isn't responding“** mit `aerr_close` und `aerr_wait`, jeweils null Lumo-Knoten. Die beiden XML-Varianten unterscheiden sich ausschließlich durch die Uhrzeit. Das echte [Fehlerbild](original/original-android/0025-failure-current-screen.png) zeigt den gerenderten Lumo-Willkommensbildschirm samt Startknopf hinter diesem Systemmodal.

Das Suchjournal enthält **21** weitere Nicht-Scroll-Beobachtungen, **keine Gesten und keinen Touchbeleg**. Der Reader hat fremde Systemcontrols korrekt ausgeschlossen. Der vorhandene Onboardingfilm ist übertragen und decodierbar: **28,598056 Sekunden, 1080×2340, ohne Ton**, SHA-256 `e6f8fdcb611375cb536ce996a73d3e2ef14854141f8a299c047e48db881e5fa1`. Keine Lernszene und kein Onboarding wurden abgeschlossen.

Die genaue Ursache des Launcher-Hängers ist aus diesen Originalen **nicht festgestellt**: Es gibt keinen zugehörigen Logcat-/ANR-Trace. Kein Lumo-ANR, fehlender Button, falsches Label oder notwendiger Produktpatch wird daraus abgeleitet. Die libunwind-Warnungen allein erlauben keine kausale Zuordnung. [Root-Befund](root-original-review.json), [unabhängiger Lesereview](independent-readonly-review.json).

## Vollständig erhalten

Artefakt **14213881427**, **924.212 Bytes**, SHA-256 `9afa0569f8dd18ec34e651ce38e29441c7cc8d6e738fb205c841a1fa4d5d49a6`. **Alle 42 Originalmitglieder** einschließlich Video, Screenshot, XMLs, Installationsdaten und Resultat sind als vollständiges ZIP und entpackte bytegleiche Dateien erhalten. Rohjoblog **392.898 Bytes**, SHA-256 `56d7d5d734bb6377ea7e58b80111ad22165c5f6c8935d1082be5aa89cea32371`; vollständige verlustfreie GZIP-Kopie **62.518 Bytes**, SHA-256 `38e5cf6e9e82e398f04c0046cc3a1a16671b44a2257dfb29599126daf08dc412`.

## Eng begrenzte Folgeentscheidung

Nach Sicherung dieser Originale wird genau **ein** unveränderter frischer Androidversuch erwogen. Die vorhandenen signierten APKs, sämtliche Probe-/Publisherquellen, Besitzer-, Zeit-, Medien- und Bewertungsbedingungen bleiben unverändert. Es wird kein Dialog unsichtbar geschlossen und kein FAIL in einen PASS umetikettiert. Ein neuer Versuch erhält seine eigene tatsächliche Attempt-/Job-/Artefaktbindung. Falls er erneut scheitert, folgt zuerst die Diagnose seiner neuen Originale.
