# C4: vorhandene Deadlines auch nach Beobachtung und Auswertung durchsetzen

Dieser eigenständige Folgepack ändert ausschließlich die tatsächliche C4-Androidprobe und einen neuen gezielten Test. Basis ist Host `8dd2ad1fc2f04a8a116c15147436da3c15102b87`, unveränderte Probe SHA256 `4249de4352a32694f28bb45786b73437eb2d32f360fb754a4ab48c9d5212f77c`. Der vorherige Deliverypack bleibt vollständig eingefroren. Es wurde kein Worktree, Index, Ref, Workflow, Pin, Produkt- oder Androidzustand geändert.

## Nachgewiesene Grenze und enger Patch

`wait_observation` begrenzte nur den Beginn eines Versuchs auf die lokale 90-Sekunden-Frist. Eine langsame tatsächliche Beobachtung oder nachfolgende Condition konnte danach dennoch als Ergebnis zurückkehren, solange die 900-Sekunden-Gesamtfrist noch lief. Jetzt wird dieselbe lokale Deadline unmittelbar vor der Rückgabe erneut geprüft. Ein verspätetes Ergebnis wird in der vorhandenen Fehlersammlung protokolliert und ergibt den bestehenden Timeoutpfad.

`return_to_flutter` prüft die unveränderte lokale 45-Sekunden-Frist nochmals nach den tatsächlichen PID-/Activity-Abfragen vor dem erfolgreichen Verlassen der Schleife. Eine erst danach beobachtete Rückkehr wird nicht mehr akzeptiert.

`observation` prüft die bestehende 900-Sekunden-Gesamtfrist nach letzter Geräteabfrage, Pixel-/Ziel-/Hashauswertung sowie nochmals nach dem Schreiben der Originalbeobachtung. Erst danach gelangt das Ergebnis in die Liste erfolgreich übernommener Beobachtungen. Eine vorhandene spät geschriebene JSON-Datei bleibt ein Originalbefund, erteilt aber keine erfolgreiche Rückgabe.

Keine Frist wurde verlängert. Alle übrigen Modul-/Funktions-ASTs sind identisch. Die bestehenden Pixel-, Layout-, Owner-, Source-, Save-, Pause-, Rückweg- und tatsächlichen Gerätebedingungen bleiben erhalten.

## Tatsächliches Red/Green

Die unveränderte Ausgangsprobe wurde mit elf tatsächlichen Testmethoden ausgeführt. Zehn Grenzassertionen scheiterten exakt mit `TimeoutError not raised`; es gab keine Import- oder Fixture-Errors. Die neuen Tests verschieben eine ausdrücklich synthetische monotone Uhr nach letzter Beobachtung, Condition, PID-/Activity-Lektüre, Pixel-/Targetauswertung und Belegschreiben. Es werden die tatsächlichen Probe-Methoden ausgeführt; Geräte-/Pixelgrenzen sind explizite Stubs. Positive Fälle knapp vor der Frist sowie weiterhin fehlende Pause/unvollständige Oberfläche bleiben enthalten.

Derselbe unveränderte Testcode ergibt mit dem engen Patch **11 PASS, 0 Fehler, 0 Skips**. Quellenhashes vor/nach beiden Läufen sind identisch. Vollständige rohe Logs und Befehle liegen getrennt in `evidence/red/` und `evidence/green/`. Es wurde kein ADB-, Android-, Flutter- oder Godotlauf gestartet. Die synthetischen 4×4-Testbilder sind keine echten Spielbilder.

## Producer-Herkunft

Ausgangspunkt des Anschlusschecks war der veröffentlichte PR477-Nachtrag `e423df58117c8f49bcd03c634e438392dc79c3ef` → `20fbe81804d91e2fc4270a83cfa3038e8557b71d`. Der unveränderte ursprüngliche API-Compare ist im Root-Inkrementalpack gesichert; dessen Pfad, SHA und relevante originale Dateiobjekte sind hier gebunden. Der Producer verwendet einen anderen Probeaufbau. Dessen Implementierung wurde nicht blind übernommen: die drei tatsächlich vorhandenen Rückgabegrenzen dieser eigenen Probe wurden separat gelesen, rot reproduziert und minimal geschlossen.

Maßgeblich: `source-freeze.json`, `deadline.patch`, `evidence/ast-preservation.json` und `handoff.json`. Root übernimmt allein die spätere Quellveröffentlichung und echte Androidabnahme.
