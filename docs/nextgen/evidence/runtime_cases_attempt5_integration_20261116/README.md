# Zusatzlauf 5 — vor Aktivierung genau gebundene Sequenzkorrektur

Der Originalfehler aus Lauf 43822740773 bleibt FAIL. Die eng begrenzte Supplemental-Korrektur folgt ausschließlich der belegten Diskrepanz zwischen gleichzeitigem Video und Wallpaper-Standbildern; tiefere Surfaceursache offen.

Owner `8aae320664ac3d39fdea80150b794aaaac89bd0a`, API `8c0158ee29d0628238bcc300e33d2883e2c44ba2`, Tree `3e09895a4374c26dbcf19b130f3227a21a3611c4`. Root und Learning prüften den konkreten Diff und die Originalbindung ohne Blocker. Die vorhandenen 27/27 fokussierten Hostprüfungen sind kein Android-PASS.

[Komponenten-Handoff](component-handoff.json), [QA-Vorbereitung](qa-preparation-handoff.json), [Root-Voraktivierungsprüfung](preactivation-source-binding.json). Alle 15 Ownerdateien sind exakt; alle 31 Publisherdateien plus 17 Vollreplay-Fixtures bleiben bytegleich zur erfolgreichen QA ae6c27c81d41342179a0bf6e60fedbcafacb63a4. Nur die tatsächliche bestehende Supplemental-Config wurde von caseAttempt4 auf5 erhöht.

Die APK und öffentliche Veröffentlichung bleiben unverändert. Ein neuer Androidlauf und dessen Ergebnis müssen getrennt beobachtet und hier ergänzt werden; diese Vorprüfung behauptet keinen Laufzeiterfolg.

## Tatsächlich gestarteter Lauf

[Zusatzlauf 43826704611](https://github.com/Ullmann27/lumo-lernen/actions/runs/43826704611), Job **133162141099**, wurde am **16.11.2026 um 07:51:03 UTC** auf API-QA **59ab8cd000d4cca1c9c414920ccebf9fc5d1c7ba**, Tree **79f623d398e7c64275d8f3b894f169c2d29b54c4**, tatsächlich gestartet. APK-Quellgrenze und exakter APK-Download sind erfolgreich; Laufzeitergebnis noch offen. [Aktivierung](activation.json), [exakte QA-Veröffentlichung](published-qa.json).

Die vorab integrierte Rootquelle ist öffentlich **c86ad8475a597b55a865b52f58c9925fe3f098e3**, Tree **b95f81261665ef5fb07d9ed679562833d98b9fda**. Die vollständigen Android-/Publikations-/Fehlerarchive sind bereits in ihrem Parentcheckpoint **a38ee5b9037b33b75c988e19c74bc346918ec174** gesichert. Kein Main-Merge und keine neue APK.
