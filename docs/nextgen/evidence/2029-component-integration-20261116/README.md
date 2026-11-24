# Tatsächlich übernommene Korrekturen vor Kandidat 2029

Der in Android beobachtete Rückkehrfehler ist mit drei unveränderten Regressionen gegen die fc5-Produktdatei reproduziert: normale eigene Gesprächsrückkehr, Unterbrechung innerhalb des Gesprächs sowie sichtbares Resume ohne Resize. Die minimale Produktkorrektur in Lab._publish baut lokale Bedienelemente nach einer neu erhaltenen eigenen Aufgabenidentität neu auf. Alle drei neuen und 24 bestehenden Lab-Prüfungen bestehen, ebenso die Analyse der beiden Dartdateien. Alte Callbacks und fremde Besitzer erhalten keine neue Berechtigung. Original-RED/GREEN samt Quellhashes liegen unter `../lab_route_return_20261116/`.

Der getrennte normale Veröffentlichungshelfer verlangt vor Neuerstellung konkret HTTP404 für Release und Tag. Nach der Erstellung prüft er aktuellen Quellcommit, Version, Paket, Signatur, Bytezahl, Tagziel und genau eine hochgeladene öffentliche APK. Der vollständige anschließende anonyme Download muss denselben SHA-256 und dieselbe Bytezahl haben. 13 synthetische Hostprüfungen bestehen. Dieser Beleg ist keine bereits ausgeführte öffentliche Veröffentlichung.

`components.json` nennt jeweils ursprünglichen lokalen Produzentencommit, tatsächlich veröffentlichten GitHub-Commit und identischen vollständigen Tree. Die Produkt- und Gate-Dateihashes des integrierten Root stimmen mit den geprüften Komponenten überein. Unterschiedliche Commitkennungen werden nicht verwechselt.

Die Abdeckungserzeugung führt den neuen Lab-Regressionsnachweis mit aufgezeichneten Quellhashes und ohne erfundenen sauberen Test-HEAD. Der folgende Katalogexport, sämtliche Quellenhashes, der neue vollständige CI-Lauf und die tatsächliche Androidtour bleiben nötig. Die Version2028 bleibt unfreigegeben, main bleibt geschützt.
