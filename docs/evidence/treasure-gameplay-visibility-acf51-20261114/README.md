# Schatzsuche: freie Figur und lesbare Hinweise

## Stand und tatsächlicher Ausgangsbefund

Dieses isolierte Paket baut auf `Ullmann27/lumo-godot` Commit `acf51d3bd2997c4b731e9a48e1791e05e756a132`, Tree `625d501c8517fa88787a0a415cd5d5b2e75ac845`, auf. Es verändert genau zwei Dateien: das bestehende Schatzsuche-HUD und dessen bereits verpflichtende Titelregression. Es wurde kein Gitref, Pin, Host-Receipt oder gemeinsamer CI-Harness verändert.

Der veröffentlichte Ausgangsstand hatte einen vollständigen erfolgreichen Native-CI-Lauf, war aber wegen eines tatsächlich sichtbaren Fehlers noch nicht bildlich abgenommen. Das aktuelle Originalbild `mobile_safe_area_regression/treasure-landscape-cutout.png` verdeckte die Spielfigur im 2400×1080-Querformat durch das große Aufgabenfeld. Im aktuellen Originalbild `treasure_title_contrast_regression/treasure-title-compact.png` war derselbe Fehler bei 640×320 sichtbar. Die zusätzliche weiße Erkundungszeile verlor vor der hellen Burg ihren Kontrast. Beide Originale wurden tatsächlich geöffnet; ihre Archiv-, Pfad- und Hashbindung steht in `original-blocker-binding.json`. Die Originalbilder bleiben im bereits gesicherten acf51-Belegpaket erhalten.

## Enge Produktkorrektur

In kurzen Querformaten ersetzt ein echter, mindestens 48 dp hoher **Hinweis**-Knopf das dauerhaft große Aufgabenfeld. Er öffnet den vorhandenen begrenzten, scrollbaren Dialog mit dem vollständigen unveränderten `clue_label.text`. Das Öffnen pausiert wie die übrigen vorhandenen Dialoge; **Weiter erkunden** schließt denselben Dialog. Ein Tipp auf den Hintergrundknopf während eines bereits offenen Dialogs wird abgewiesen. Hohe Formate behalten das sichtbare Aufgabenfeld.

Die Erkundungszeile erhält das vorhandene dunkle Panelmaterial. Ihre Position wird aus den tatsächlichen UI-Größen bestimmt: in kurzen Querformaten als Informationszeile unter dem Header, in breiten hohen Ansichten zwischen den unteren Steuerflächen und im schmalen Hochformat mit Abstand vor dem tatsächlichen Beginn der Sprung-/Joystickflächen. Der vorhandene verzögerte Layoutaufruf berücksichtigt späteren Textumbruch.

Geändert sind nur `_ui`, `_layout`, das neue Feld `clue_button` und die neue Methode `_show_clue`. Die 22 anderen Produktmethoden bleiben textgleich. Kamera, Weltgeometrie, Bewegung, Antworten, Questzustände, Speicherformat, Belohnungen und Rückkehrpfad bleiben unverändert. `evidence/product-function-preservation-final.json` und `implementation-against-acf51.patch` binden diesen Umfang an die tatsächlichen Quellbytes.

## Tatsächlich ausgeführte Prüfungen

| Lauf | Produkt/Test | Ergebnis | Dauer |
|---|---|---:|---:|
| Sauberer Gegenlauf mit ursprünglichem acf51-Produkt und finaler neuer Regression | `ce7c7df9…` / `ea6087ef…` | 3.221 Prüfungen, 40 gezielte Fehler, Exit 1 | 17,955 s |
| Finale neue Regression ohne Renderer | `e68fc854…` / `ea6087ef…` | 3.341 PASS, 0 Fehler, Exit 0 | 19,988 s |
| Unveränderte bestehende Dichte-/Touchregression | `e68fc854…` / `b3be76fa…` | 1.085 PASS, 0 Fehler, Exit 0 | 30,107 s |
| Finaler echter Godot-X11-Renderlauf | `e68fc854…` / `ea6087ef…` | 3.351 PASS, 0 Fehler, Exit 0; fünf PNGs | 259,674 s einschließlich Launcher |

Die Zahlen sind getrennte Prüfläufe, keine zusammengezählte Geräte- oder Releaseabnahme. Der finale Rendererlog enthält keine Engine- oder Scriptfehler. Die zwei vorgeschlagenen Dateien waren vor und nach diesem Lauf bytegleich. Die private Runtime bindet zusätzlich 353 unveränderte veröffentlichte Dateien an den frisch gelesenen acf51-Gitbaum; die lokale Importmetadatenliste ist ausdrücklich getrennt.

Die fünf Formate werden jeweils mit leerem Spielstand und mit der vorhandenen ursprünglichen 86445-Baumfund-Fixture ausgeführt. Die finalen zehn Rohbeobachtungen binden echte Kamera-Projektionen aller sichtbaren Fuchsmesh-Ecken, semantisch zugeordnete HUD-Rechtecke, tatsächliche Schnittflächen, Kontrastwerte und deklarierte Dichte-/Insetwerte. Tatsächliche `ScreenTouch`-Ereignisse öffnen und schließen den Hinweisdialog. Der Test kontrolliert vollständig erhaltenen Hinweistext, Pause und Wiederaufnahme, sichtbare mindestens 48-dp-Touchflächen unter Scroll-Clipping sowie unveränderte Quest- und Belohnungsidentität. Die bestehende Dichteprüfung erhält ihre ursprünglichen Spiel-, Scroll-, Rotations- und Speicherprüfungen.

## Neue echte Bilder und Sichtprüfung

Alle fünf PNGs in `final-render/` stammen aus genau dem finalen unveränderten Lauf. Sie wurden einzeln tatsächlich geöffnet; `visual-review.json` enthält ihre Größen, SHA-256-Werte und begrenzten Befunde.

| Bild | Auflösung | Sichtbefund |
|---|---:|---|
| `treasure-title-compact.png` | 640×320 | Figur frei; Hinweisbutton und kontrastfeste Zeile statt verdeckendem Aufgabenfeld. |
| `treasure-title-landscape-cutout.png` | 2400×1080 | Figur am Start vollständig frei, aktuelle Inset-Fixture mit linker Aussparung; alle vorhandenen Steuerflächen getrennt. |
| `treasure-title-landscape.png` | 1920×1080 | Sichtbares bestehendes Aufgabenfeld; Figur und Steuerflächen frei. |
| `treasure-title-portrait.png` | 1080×2400 | Figur frei; Toast endet mit sichtbarem Abstand vor Springen. Der bestehende schmale Header kürzt den Titel weiterhin mit Auslassung. |
| `treasure-title-fold.png` | 2176×1812 | Aufgabenfeld erhalten; Toast liegt zwischen den unteren Steuerflächen, Figur frei. |

Die Bildschirmbilder zeigen das Erkundungs-HUD. Der tatsächliche Dialog-Öffnen-/Schließen-Nachweis stammt aus dem ausgeführten Eingabetest; es wird keine zusätzliche, nicht aufgenommene Dialogansicht als gesichtet ausgegeben.

## Bewahrte Zwischenfehler

Die ersten privaten Runtimeversuche fehlten an einer neuen Facial-Preload-Abhängigkeit. Ihre Compilefehler sind unverändert erhalten und werden **nicht** als sauberer Produktgegenlauf gewertet. Nach Ergänzen der exakt an acf51 gebundenen Dateien folgte der saubere Rot-/Grünlauf.

Der erste echte Renderer mit Zwischenquelle `36004959…` bestand 3.283 Prüfungen, zeigte aber eine schmale Überlappung zwischen Toast und Sprungfläche im Hochformat. Dieses Bild und sein Rohbericht bleiben unter `evidence/rejected-first-render/` erhalten. Die endgültige Regression reproduzierte daran vier gezielte Fehler; erst die tatsächliche Größenbegrenzung im finalen Produkt schloss sie. Weder diese Aufnahme noch die früheren 3.273-Prüfungsprotokolle werden als finaler Nachweis ausgegeben.

## Integration und Grenzen

`source-upload-manifest.json` enthält ausschließlich die zwei vorgeschlagenen Native-Dateien mit Original- und neuen Hashes. `evidence-upload-manifest.json` enthält ausschließlich explizite Dokumentziele für die nachvollziehbaren Belege. Der gemeinsame Harness wird getrennt vom zuständigen Agenten angepasst: derselbe Renderaufruf und Marker bleiben erhalten, die alten vier PNGs bleiben Pflicht und `treasure-title-landscape-cutout.png` kommt als fünftes Bild hinzu. Damit wächst der gemeinsame Native-Bildbestand von 53 auf 54; eine neue vollständige CI und erneute quellengebundene Sichtabnahme bleiben Aufgabe der Integration.

Dies ist echte lokale Godot-Grafik und tatsächlich ausgeführte Eingabelogik mit deklarierter Android-Rand-Fixture. Es ist kein neuer Android-Installationslauf, kein physischer Fold7-Nachweis und kein 60-FPS-Beleg. Der bestehende vereinfachte Schatzsuche-Avatar und die vorhandene Umgebung werden durch diese HUD-Korrektur nicht als neu entwickelt oder als vollständiger Original-Lumo-Gesichtsstandard ausgegeben. Die bisherige acf51-Gesamtfreigabe bleibt verworfen, bis der integrierte neue Stand seine Pflichtprüfungen und Sichtkontrolle besteht.
