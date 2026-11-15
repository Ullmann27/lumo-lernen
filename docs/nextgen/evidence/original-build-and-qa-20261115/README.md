# Originale Validierungs-, Build- und QA-Belege

Diese unveränderte historische Sammlung bindet die Quellen und getrennten Ergebnisse an Flutter `72a7914059d10152604b877cfeaf8bd1d2155810` und Godot `ec702dad29def7ea3db6f62f2ead7b8ca6bca2bb`. Sie wurde vor dem nächsten Android-Replay abgeschlossen. Ihre Aussagen über noch fehlende Laufzeitbelege gehören zu diesem Zeitpunkt; spätere Ergebnisse ersetzen diese Originale nicht.

Das Archiv enthält die vollständige Chronologie, Herkunft und Prüfsummen sowie sechs originale Actions-ZIPs, die ursprünglichen Logs, Paketprüfungen und die Korrekturbelege für Signaturleser, Shellaufruf und Installationspfad. Alle 122 Archivdateien wurden erneut bytegenau gegen die gesicherten Quellen verglichen; siehe `archive-verification.json`.

**Belegt:** 2.870 bestandene Flutter-Tests bei 202 übersprungenen; 55 bestandene Host-Prüfungen; elf native Prüfläufe mit zusammen 55.509 gemeldeten Prüfaussagen, keine entsprechend große Zahl unabhängiger Tests; erfolgreicher ARM64-/x86-Build und Paketprüfung. Die dokumentierten Androidversuche brachen vor dem Lerndurchlauf ab.

**Nicht belegt durch diese Sammlung:** bestandene Android-Lernszene, physisches Gerät, Mikrofonverständnis, hörbare Sprachqualität, vollständige Modernisierung oder erreichte 60 FPS. Die APK selbst ist nicht im Archiv. `fullModernizationComplete` bleibt `false`.
