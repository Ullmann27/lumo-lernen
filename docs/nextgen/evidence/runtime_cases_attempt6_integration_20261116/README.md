# Zusatzlauf 6 — ein frischer Lauf mit unveränderten Gates

Nur `caseAttempt` wurde von5 auf6 erhöht. Alle übrigen Bytes entsprechen QA59ab8cd000d4cca1c9c414920ccebf9fc5d1c7ba; alle31Publisherquellen plus17weitere Vollreplay-Fixtures bleiben unverändert. Vorheriger Zusatzlauf5 ist vollständig als FAIL erhalten.

Die [begründete Entscheidung](../ci-2031-runtime-cases-onboarding-transfer-failure/bounded-fresh-run-decision.json) erlaubt genau einen frischen unveränderten Lauf nach dem belegten Onboarding-Transportabbruch. Keine erweiterte ADB-Ausnahme, keine gelockerte Beobachtbarkeit und kein wiederverwendeter alter Android-PASS.

[QA-Handoff](qa-preparation-handoff.json), [Root-Quellenprüfung](preactivation-source-binding.json). Der noch ausstehende echte Lauf muss alle vier Fälle selbst beobachten.

## Tatsächliche Aktivierung

[Run **43828196598**](https://github.com/Ullmann27/lumo-lernen/actions/runs/43828196598), Job **133166913493**, wurde am **16.11.2026 um08:03:13UTC** auf QA **1c84838538f79100f660fefc776d8ba7472a61a2**, Tree **d98ca3f9ec556ad39867cc7cacd0804382eaa8d3**, gestartet. Quelle/identischer APK-Download und vorgeschaltete Hostprüfer sind bestanden; Androidfälle laufen, kein Ergebnis vorweggenommen. Die Root-Voraktivierung ist öffentlich **5facfac37bd0920b9168e0192bf350856648cce8**. [Aktivierungsmetadaten](activation.json), [QA-Quelle](published-qa.json).

## Tatsächliches Ergebnis

Der Lauf endete um **08:20:01UTC mit FAIL**. Drei Teilfälle sind im Original abgeschlossen; der native Stopp scheiterte vor dem Tastendruck an der begrenzten OCR-Beobachtung trotz zuvor aktiverPlayerID13/PID7013. Alle1674Originale/ZIP undRohlog sind im [gesonderten Archiv](../ci-2031-runtime-cases-active-stop-observation-failure/README.md) erhalten. Keine weitere unveränderte Wiederholung und kein zusammengesetzter Gesamt-PASS.
