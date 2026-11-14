# Kart-Vorschau: konkreter Android-OCR-Fehler und enger Leserfix

Stand: 14. November 2026. Basis Host 28462a7547048b75fa114e6f5832248e54c94faa, Native 29080ef8cd1a5b385eeeec97976fbefd31280427.

## Tatsächlich fehlgeschlagener Android-Lauf

Der separate Unified-Lauf 43626348513, Job 132548884489, ist fehlgeschlagen. Er ist nicht der Studio-Freigabelauf. Das Originalprotokoll und das vollständige Artefakt 14127109230 wurden einmal geladen; alle 171 ZIP-Mitglieder wurden per CRC geprüft. Das 49.066.838-Byte-Archiv hat SHA256 f3a4f2272c4af921e4831a8b34b733ddaa4794175a3bc9c8bc4f0cd6c7c0c8bf.

Die APK-Identität wurde im Originaljob bestätigt; kein Freigabeclaim wird daraus abgeleitet. Der Fehler ist ein Timeout der Texterkennung am optionalen Vorschau-Überspringen. Die eigentlichen Fahr-, HUD-, Rennuhr- und Pause-Abnahmen wurden danach nicht erreicht. Der Lauf bleibt negativ.

Das erste neue Originalbild zeigt eine noch verblasste Beschriftung, deren vollständiger Wortlaut vom bisherigen Leser nicht erkannt wird. Allgemeine Masken-, Komponenten- und Kachelversuche verbrauchen den Rest des unveränderten 55-Sekunden-Budgets. Das zweite Bild wird erst nach 26,714 Sekunden aufgenommen; bei dessen zweitem OCR-Versuch bleiben nur 1,782 Sekunden. Beide Originalbilder wurden einzeln von Root und B gesehen und bytegleich erhalten.

## Änderung

Nur der ausdrücklich exakt angeforderte Hinweis „Tippen zum Überspringen“ verwendet zwei schnelle Ganzbild-Lesevarianten: die tatsächlich beobachtete gedämpfte blaue Textfarbe und das unbearbeitete Bild in Originalgröße. Ein negativer Befund kehrt früh zum unveränderten Touch-Wächter zurück, damit dieser ein neues Bild aufnehmen kann.

Keine angenommene Position, kein hergestellter Text und kein Eingriff in Spielzustand oder Countdown. Zwei unterschiedliche aktuelle Vollbilder mit vollständiger erkannter Beschriftung, gültigen stabilen Grenzen, realem Eingabeereignis und dem bisherigen Gesamtzeitlimit bleiben Voraussetzung. Alle bisherigen Renn-/Save-/Rückkehrprüfungen bleiben unverändert.

## Tatsächlich ausgeführte Prüfung

Die 25 Pythonfälle (23 unverändert plus zwei neue) liefen lokal erfolgreich. Sie prüfen den wirklichen Leser-/Touch-Controller mit ersetzten I/O-Grenzen; sie sind kein Androidlauf.

Zusätzlich lief der wirkliche neue image_lines-Leser mit Tesseract 5.5.0 auf den unveränderten Originalbildern: Bild 0 wird nach 3,204 Sekunden weiterhin korrekt ohne vollständigen Treffer zurückgegeben; Bild 1 liefert nach 1,964 Sekunden den tatsächlichen vollständigen OCR-Text und dessen Grenzen. Die beiden gleichen Einträge für Bild 1 sind zwei Zeilen aus demselben Bild, keine zwei unabhängigen Bildbelege. Kein Touch wurde bei dieser Offline-Wiederholung gesendet.

Die lokale OCR-Zeit ist kein Nachweis der Android-Latenz. Ein neuer vollständiger Androidlauf und alle Studio-Gates bleiben erforderlich. Die Flutter-Korrekturen und der Native-Pin werden durch dieses Evidenzpaket nicht freigegeben.
