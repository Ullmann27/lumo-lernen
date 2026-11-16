# Zusatzlauf 6 — ein frischer Lauf mit unveränderten Gates

Nur `caseAttempt` wurde von5 auf6 erhöht. Alle übrigen Bytes entsprechen QA59ab8cd000d4cca1c9c414920ccebf9fc5d1c7ba; alle31Publisherquellen plus17weitere Vollreplay-Fixtures bleiben unverändert. Vorheriger Zusatzlauf5 ist vollständig als FAIL erhalten.

Die [begründete Entscheidung](../ci-2031-runtime-cases-onboarding-transfer-failure/bounded-fresh-run-decision.json) erlaubt genau einen frischen unveränderten Lauf nach dem belegten Onboarding-Transportabbruch. Keine erweiterte ADB-Ausnahme, keine gelockerte Beobachtbarkeit und kein wiederverwendeter alter Android-PASS.

[QA-Handoff](qa-preparation-handoff.json), [Root-Quellenprüfung](preactivation-source-binding.json). Der noch ausstehende echte Lauf muss alle vier Fälle selbst beobachten.
