# Mustergruppe aus dem tatsächlichen nativen Kontext

Producer `d5a40d4eadad30f8a4e6665271eb23c314ab8b30` korrigiert genau die Kotlin-Gesprächsbridge und ihren vorhandenen JVM-Integrationstest. Flutter startet Muster mit `sequence`, `choices`, `period`; Godot überträgt die geprüfte Gruppe in `parameters.patternUnit`. Die alte Bridge las stattdessen ein fehlendes `lesson.patternUnit`.

Die vorhandene Produktions-Kotlin-/Java-Kompilierung reproduzierte den Fehler tatsächlich. Nach dem Fix bestehen 81 Integrationsprüfungen und die unveränderten 26 Java-Dialogprüfungen in zwei Python-Testmethoden. Geprüft werden gültige Gruppe, kleinste Periode, fehlerhafte/fehlende Werte, eingeschränkte erlaubte Aktionen, zurückgezogene Objektregistrierung, verspätete Antwort und JSON-null-Erhalt von `stepId`.

Die Gruppe wird gegen die unveränderliche Startsequenz geprüft. Die Bridge vergibt keine Richtigkeit oder Belohnung; `pattern_group` ist nur bei tatsächlicher aktueller Registrierung ein erlaubtes Ziel. Die Original-RED-/GREEN-Logs bleiben unverändert; `handoff.json` enthält Quell-/Loghashes und genaue Grenzen. Android-Systemklassen sind im JVM-Test simuliert. Das ist kein Android-Sprach- oder APK-PASS.
