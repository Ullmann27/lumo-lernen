# Vollständiger CI-Lauf und gezielte Korrekturen

Der erste Android-Integrationslauf [43750469368](https://github.com/Ullmann27/lumo-lernen/actions/runs/43750469368) prüfte den veröffentlichten Flutter-Commit `aea9f63e5ea7a85a2d0a67d3b0e8988b0b0eb1fa`. Analyse, Quell-/Schutzprüfung und Toolchainbereitstellung bestanden. Der vollständige Flutter-Lauf endete nach 2.809 bestandenen, 27 fehlgeschlagenen und 202 bereits vorhandenen übersprungenen Tests. Es wurde keine APK gebaut oder veröffentlicht. Das unveränderte vollständige Testprotokoll liegt hier als `first-full-tests.log`.

Die 27 Fehlschläge verteilen sich auf zwölf MiniGame-/Darstellungsfälle, vier Vertrag-/Hilfebedienfälle und elf Lernfixture-/Dispose-Fälle. Die gezielten Nachprüfungen ersetzen weder den vollständigen Wiederholungslauf noch Android-Laufzeitbelege. Keine Qualitätsgrenze oder Prüfungsbeschränkung wurde entfernt, kein neuer Skip hinzugefügt.

Die Anpassungen testen die tatsächlichen neuen Bedienelemente, explizite Antwortbestätigung, lesbaren Kontrast, 48-dp-Ziele, ruhigen Modus, bestehende Originalbelohnungen, fehlgeschlagenes Speichern und genau einmaliges Nachholen. Lernfixtures enthalten weiterhin fachlich gültige, vorab nicht verratene Antworten. Zusätzlich wurde ein tatsächlich veröffentlichter alter Aufgabenkontext beim Dispose korrekt freigegeben.

Neue Audio-Regressionen prüfen außerdem, dass ein ausgeschiedener Besitzer keinen neueren Wiedergabeauftrag stoppt und dass ein verzögerter Stop keinen veralteten Sprachstart mehr auslöst. Sie bedienen die tatsächlichen Flutter-Widgets mit kontrollierten Wiedergabeabschlüssen; sie belegen keine hörbare Gerätewiedergabe.

`runs.json` nennt Produzenten-/Integrationscommits und Protokollhashes. Testmengen überlappen und dürfen nicht als unabhängige Gesamtzahl addiert werden. Der nächste vollständige Lauf wird separat durch seinen GitHub-Actions-Run und die endgültige APK-Provenienz belegt.
