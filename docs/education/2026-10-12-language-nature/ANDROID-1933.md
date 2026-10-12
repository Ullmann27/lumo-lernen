# Android-Testversion 1933: genaue Zuordnung und Abnahme

Produkt: `65009c4115d6674e730f15b145671c9a87ae1de7`, Version `0.12.26+1933`,
PR [269](https://github.com/Ullmann27/lumo-lernen/pull/269), auf dem bereits
ausgelieferten 1932-Stand aufgebaut. Der Produktbaum bleibt für diese Abnahme
eingefroren. Die Änderungen dieses separaten Branches betreffen ausschließlich
Prüfhelfer, Auslieferung, Belegdokumentation und ihre Regressionstests.

Die vollständige Flutter-CI
[38193200119](https://github.com/Ullmann27/lumo-lernen/actions/runs/38193200119)
prüfte exakt die Produktquelle: 1338 bestanden, 117 optionale Aufnahmetests
übersprungen, Analyse ohne Fehler. Der separate lokale Inhaltsaudit prüfte
40982 Aufgaben und 22 geführte Antwortschritte. Backend-, native Sprach- und
Godot-Produktquellen sind gegenüber 1932 unverändert; diese Aussagen ersetzen
keine externe pädagogische Prüfung.

Der einmalige Bau
[38194565555](https://github.com/Ullmann27/lumo-lernen/actions/runs/38194565555)
checkt ausdrücklich die Produktquelle aus, nicht den späteren QA-Commit.
Version, Paket, ABI, Signatur, saubere Quelle, Godot-Revision und vorhandene
155 Sprachclips werden im Build nachgewiesen. Spätere Änderungen am Prüfhelfer
bauen die App nicht nochmals. Eine historische Zeile der ursprünglichen
Build-Scope-Datei fasst CI und lokale Inhalts-/Python-Prüfungen zu weit zusammen:
Die vollständige CI selbst umfasst Flutter-Tests und Analyse; Inhaltsaudit und
Python-Prüfungen haben separate Belege.

Die Android-Abnahme verwendet die tatsächlich gebaute x86_64-APK auf Android 16
mit Update von 1932. Sie behält die bisherigen Plus-, Minus-, Sprach-, Kart- und
Eltern-/Entdeckungsprüfungen und ergänzt vollständige Silben- und Pflanzenkurse.
Echte falsche Antwort, zwei verschiedene auf Wunsch geöffnete Hinweise,
selbstständige richtige Antworten, Rückmeldung und freigegebene Weiter-Taste
müssen beobachtet werden. Die fachbezogene richtige Rückmeldung wird ausdrücklich
angegeben; mathematische Texte bestehen diese neue Prüfung nicht.

Nach jedem neuen Kurs liest der Helfer die echten gespeicherten App-Daten:
genau zwei richtige Antworten, ein Fehlversuch und ein Hinweis; täglicher Zähler
plus zwei; genau drei neue eindeutige Versuche. Bisherige Fachfortschritte,
vorhandene andere Profile, Sterne/XP, Elternfreigaben und übrige Einstellungen
dürfen sich nicht verändern. Das beweist die Unverändertheit vorhandener Daten,
keinen zusätzlichen tatsächlichen A/B-Profilwechsel im Emulator. A/B/Neustart
der Kurse sind in den separaten Flutter-Laufzeittests geprüft.

Der bekannte Wartefehler aus 1932 bleibt repariert: vor der Suche nach dem
Hilfsangebot 18 Sekunden ohne Eingabe warten. Ununterbrochenes Scrollen würde
die echte Ruhefrist wieder zurücksetzen. Die Antwort-, Rückmeldungs- und
Weiter-Assertions bleiben bestehen. 106 lokale Python-Prüfungen einschließlich
der neuen Fehlerfälle bestanden; synthetische Prüffälle sind ausdrücklich keine
Android-Laufzeitbelege.

Nach erfolgreicher Android-Abnahme erfordert die ZIP-Paketierung beide neuen
Kurse und deren genauen Speicherbefund. Eine einzige vollständige ZIP erhält
die ARM64-APK im Hauptverzeichnis, Installationsanleitung, Prüfsumme,
Quellzuordnung, Testbericht und echte Emulatorbilder. Das endgültige
Actions-Artefakt wird erneut heruntergeladen, geöffnet, CRC-geprüft und auf die
identische eingebettete APK geprüft. Weder Store-Publikation noch Zahlungen
werden aktiviert.

Offen bleiben physische ARM64-/Fold-Laufzeit, menschliche Sprachqualität,
externe Fachprüfung und Play-Produktionsfreigabe. Der native Gesamtlauf und die
Dateiauslieferung werden erst nach tatsächlich fertigen Belegen bestätigt.

## Erster Android-Lauf: Prüfhelferfehler bewiesen

Run [38195153458](https://github.com/Ullmann27/lumo-lernen/actions/runs/38195153458)
bestand Update, lokale Stimme und Kart-Rückkehr, scheiterte anschließend im
Plus-Einstieg. Die gespeicherte echte Hierarchie zeigt drei gleich benannte
Startknöpfe: Der angeschnittene Silben-Knopf am unteren Rand ist kleiner als
der vollständig sichtbare Plus-Knopf und wurde deshalb fälschlich gewählt.
Der tatsächliche Android-Screenshot zeigt folgerichtig den Silben-Einstieg.

`school_course` verwendet jetzt dieselbe ausdrückliche Kurszuordnung wie die
anderen Kursprüfungen. Eine Regression mit der originalen Hierarchie
`android_1933_course_hub.xml` scheitert vor der Reparatur und besteht danach:
Der echte Plus-Knopf bei `[35,377][1165,433]` wird getroffen, nicht der Silben-Knopf
bei `[35,825][1165,872]`. 14 Navigationsprüfungen bestanden. Die unveränderte
APK wird erneut geprüft; es gibt weder Neubau noch abgeschwächte Abnahme.
