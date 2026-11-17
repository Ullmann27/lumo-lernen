# Zusatzlauf 3: abgeschlossene Teilfälle, erneuter Akademie-Toggle fehlgeschlagen

Der tatsächliche Run [43819768114](https://github.com/Ullmann27/lumo-lernen/actions/runs/43819768114), Job **133139916176**, bleibt insgesamt **FAIL**. Er verwendete QA **ae6c27c81d41342179a0bf6e60fedbcafacb63a4** und die unveränderte APK **0.13.19+2031**, Produktquelle **e05a96a52aaf57e466e79831f15aaffd144284ee**, Native **678cb38fea3a83a7f5841e71fba9bb2f3bfa2eef**. Die eigentlichen Zusatzfälle liefen von **06:56:32 bis 07:04:59 UTC** am 16. November 2026.

## Unveränderte Originale

- Artefakt **14204766749**, **37.623.671 Bytes**, SHA-256 **660794dab77f440a7af869e60e51bfd310c014706570f37344a3a40447736ee0**.
- Alle **1.234 Mitglieder** mit **46.108.606 unkomprimierten Bytes** wurden auf Pfade, Größen, CRC und SHA geprüft. Fünf geordnete Archivteile erhalten das vollständige Original-ZIP; `archive-retention.json` beschreibt seine verlustfreie Rekonstruktion.
- `original/` enthält ausgewählte bytegleiche Ergebnis-, Bild-, Video-, UI-, Sprach- und Checkerdateien. Alle übrigen Originale sind ebenfalls in den Archivteilen enthalten.
- Das vollständige Joblog ist ohne Normalisierung erhalten: **591.241 Bytes**, SHA-256 **1f589a76c054d27dce45c923ecf8860e8170ce3c97de6f4f1d09f67d94a40b2b**. Die zusätzliche verlustfreie Gzip-Kopie besitzt **87.725 Bytes**, SHA-256 **60e80600cda5962d064a8c4d6e0cc6b9efa1802a7e9188aedc2cc1c9e8bd4899**.

## Tatsächlich abgeschlossene Teilfälle

Die numerische Abgabe **15 falsch → 16 richtig** zu **9+7** und der Wechsel während einer als aktiv beobachteten Silbe von **Banane** zur unbeantworteten **Rakete** melden PASS. Root hat deren vorhandene reine Prüffunktionen an den Originalresultaten und exakt gebundenen QA-Quellen erneut ausgeführt. Die Korrektur bleibt ein unterstützter richtiger Versuch nach vorherigem Fehler; sie wird nicht als unabhängiger Erstversuch ausgegeben.

Der native Banane-Fall meldet **PASS_WITH_LIMITATIONS**: tatsächlich betätigtes **Frag Lumo / Langsamer**, vier neue geordnete MediaPlayer-Start-/Endepaare **7, 8, 9, 10** im Native-Prozess **6407**, sichtbares Modell vor/nachher **0 / 3 bewegt**, Rückkehr zur Akademie. Die vier Paare wurden zusätzlich aus dem erhaltenen Rohsprachlog nachgerechnet; vier referenzierte Originalmedien wurden gegen ihre SHA geprüft. Das Video `0346-runtime-banana-four-slower-segments.mp4` ist **64,066222 Sekunden** lang und besitzt **keine Tonspur**. Wörter und Tempo werden dadurch nicht akustisch nachgewiesen. Die aufgezeichnete Profil-/Lerndatenerhaltung stammt aus dem Androidfall; sie wurde in dieser zusätzlichen Root-Teilprüfung nicht nochmals aus allen Preferences rekonstruiert.

Der Ableitungsnachweis ist `verified-completed-subcases.json`. Ein erster lokaler Auswertungsversuch verwendete einen nicht vorhandenen Python-Modulattributnamen und ist in `subset-verifier-first-run.txt` dokumentiert; die korrigierte Auswertung importiert die tatsächliche Referenzprobe direkt. Dies ist kein Androidfehler und verändert keine Originaldatei oder Abnahmebedingung.

## Konkreter Abbruch vor dem Stoppfall

Originalfehler: **`Current visible Flutter text missing: Dein Lernatelier`**. Aufrufkette: `run_native_cases` → `bridge_active_stop` → `probe.academy()` → Suche nach dem Lernatelier.

Die Original-XMLs **0399/0400** zeigen das bereits geöffnete Lernatelier. **0409** protokolliert den erneuten Tap auf **Lernwerkzeuge & Geschichten**; in **0410** fehlt das Atelier. Die tatsächliche Endaufnahme **0418** zeigt den geschlossenen Bereich. Der Produktcode des festgelegten APK-Stands schaltet `_showTools` beim Drücken um. Der zusätzliche Testeinstieg wiederholte somit einen Toggle nach bereits geprüftem Akademierückweg.

Der aktive native Stoppfall hat **nicht begonnen**; sein Ergebnisobjekt fehlt. Gesamtstatus und Native-Sammelstatus bleiben FAIL. Diese Teilnachweise ersetzen keine vollständige Androidtour, keine Publikationsfreigabe und keinen neuen erfolgreichen Zusatzlauf. Ein korrigierter Supplemental-Einstieg wird getrennt geprüft; gemeinsame Original-/Referenzproben und APK bleiben unverändert.
