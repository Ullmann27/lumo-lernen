# Originaler CI-Vertragsnachweis auf QA 3e08

Run **43546627017**, Attempt **1**, QA-Commit **3e08c7953b84aed6fff30e9e55665de75f79ec77**. Der Vorprüfungsjob **132299378978** ist tatsächlich erfolgreich abgeschlossen: 14. November 2026, 02:29:57 bis 02:31:03 UTC.

| Tatsächliche CI-Gruppe | Ergebnis | Laufzeit laut unittest |
|---|---:|---:|
| Originale OCR-Bilder und Erkennungsgrenzen | 12 PASS, 0 Skip | 19,292 s |
| Cards-Bereitschaftsverträge | 6 PASS, 0 Skip | 1,281 s |
| Quellen-/APK-Binderverträge | 18 PASS, 0 Skip | 0,926 s |

Die Originaldateien bestätigen Tesseract **5.3.4**, installierte Sprachen **deu**, **eng**, **osd** und Pillow **12.3.0**. Die drei ausgegebenen FAIL-JSONs gehören zu absichtlich ablehnenden synthetischen Binderfällen; die zugehörigen Tests bestehen. Node-Warnungen DEP0040 und DEP0169 beim Upload sind im vollständigen Rohlog erhalten.

Originalartefakt **14093674287**: **3.121 Bytes**, SHA256 `528eb10497b0d5b97cf99f34361db7073ecd42db69b341f00c40f32b64683658`. Der vollständige ZIP-Digest stimmt mit GitHub überein; CRC und alle fünf extrahierten Dateien sind geprüft.

Dies ist ausschließlich der abgeschlossene Vertragsjob. Die nachfolgenden Androidjobs waren beim Abschluss dieses Pakets noch offen. Ihre unveränderte Binärquelle bleibt **Host 4ab96666f954baf258422d6ed277fc297b7ddeef / Native 803e7a626ea6ef0aeeda9c37010e844033d3a8e3**. Die vorliegenden Tests belegen weder den neuen Produktkandidaten c081 noch einen Fold7-Gerätelauf.

Die Rohlogs wurden unverändert übernommen. Der Screenshot-/Layoutbezug der Cards-Verträge beruht auf historischen Originalfixtures und synthetischem Transport/Zeitgeber; hier wurde kein neuer Android-Ziehvorgang ausgeführt. Keine APK ist Bestandteil dieses Pakets.
