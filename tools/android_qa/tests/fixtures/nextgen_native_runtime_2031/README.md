# Kleine Originalfixtures für die zusätzlichen nativen Laufzeitfälle

Die vier unveränderten Dateien stammen aus Run `43790709991`, Job
`133048238970`, Artefakt `14193300868`. Das war die getrennte **2029**-Bridge-
Diagnose, nicht die neue 2031-Prüfung. Die native Quelle `678cb38…` ist identisch.
Alle ZIP-Teile und der zusammengesetzte ZIP wurden anhand des bestehenden
Archivmanifests auf Bytezahl und SHA-256 geprüft. Nur diese vier Mitglieder
wurden gelesen und kopiert; ihre CRC wurde dabei durch den ZIP-Leser geprüft.
`manifest.json` enthält ihre exakten Originalpfade und Hashes.

- `0143-native-speech.txt`: echter gestarteter, noch nicht abgeschlossener
  Auftrag 3 in PID 4999.
- `0148-native-speech.txt`: späterer Originaldump mit Abschluss desselben
  Auftrags. Er darf keinen aktiven Stop-Fall erfüllen.
- Die beiden OCR-JSONs enthalten tatsächlich gelesene Beschriftungen
  „Schritt anhören“ und „Stimme stoppen“. Es wird keine historische Koordinate
  als neuer Live-Tappunkt verwendet.

`source-contract.json` enthält getrennt exakte Quellzeilen und Dateihashes aus
APK-Quelle `e05a96a…` und Native `678cb38…`, einschließlich „Langsamer“ und der
Rateformel. Diese Quellzeilen sind keine Androidbeobachtungen. Die übrigen
Profil-, Zeit- und Geometriegegentests sind ausdrücklich konstruierte lokale
Hostfälle. Hieraus folgt kein bestandener 2031-Lauf und keine akustische Messung.
