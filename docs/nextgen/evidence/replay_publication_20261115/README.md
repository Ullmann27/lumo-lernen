# Veröffentlichung nach vollständiger Android-Wiederholung

Die vorbereitete Veröffentlichung bleibt inaktiv, solange kein konkreter grüner QA-Lauf samt unveränderlichem Artefakt in `config/nextgen-replay-publish.json` gebunden ist. Der Auslösezweig ist ausschließlich `delivery/lumo-nextgen-2027-replay-20261115`. Ein Hinzufügen der Workflowdatei auf dem Integrationszweig veröffentlicht nichts.

Der Prüfer bindet die bereits gebaute Appquelle 72a7914059d10152604b877cfeaf8bd1d2155810, den originalen erfolgreichen Validate-/Buildjob, das konkrete ARM64-Artefakt mit ZIP- und APK-Prüfsummen, den vollständigen neuen Androidlauf und seine zusätzliche native Banane-/Musterprüfung. Quell- und Gerätetests behalten ihre getrennten Identitäten. Alle bisherigen Audio-/Figur-/Effekt-Messgates bleiben verbindlich. 60 FPS oder vollständige Modernisierung werden daraus nicht abgeleitet.

Sechs reine Gegenbeispiel-Prüfungen bestehen: fehlgeschlagene/unvollständige Touren, falsche bzw. neu gebaute APK, fehlende echte Messfenster, fehlende Zusatzszene, fremde Installationsbindung und falsche/abgelaufene Artefakte werden zurückgewiesen. Diese Unit-Fixtures sind keine Gerätebelege. Ein erfolgreicher Veröffentlichungs- oder Downloadnachweis ist mit diesem Vorbereitungscommit nicht behauptet.
