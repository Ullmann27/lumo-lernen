# Eng begrenztes Zeitbudget für den Treasure-Titel-Renderer

## Grundlage und Änderung

Basis ist Native `785413d395292a243eaa0a0748671eb15d3f80ff`. Genau der Aufruf
`treasure_title_contrast_regression / rendered` in `tools/validate_studio.sh`
erhält **900 statt 600 Sekunden**. Die beiden bestehenden wörtlichen
Vertragserwartungen in `tools/tests/test_nextgen_runner.py` werden entsprechend
angepasst; drei Kommentarzeilen halten die Messbegründung fest.

Alle übrigen **19 Aufrufe und ihre Budgets**, die fünf Profile mit jeweils
Frischstart und Wiederaufnahme, die fünf Treasure-PNGs, der gesamte
**54-PNG-Vertrag**, echte ScreenTouch-Eingaben, Geometrie-/Kontrastprüfungen und
der Abschlussmarker bleiben unverändert. Produkt-, Szenen- und GDScript-Proben
werden nicht verändert. Es gibt keinen globalen Timeout-Override.

## Tatsächlicher Messanlass

Der erfolgreiche Native-Lauf **43570887024**, Studiojob **132374803908**,
benötigte vom Enginebanner bis zum vollständigen
`[TreasureTitleContrast] PASS checks=3351 failures=0` **584,700 Sekunden**.
Damit blieben nur **15,300 Sekunden** bis zur bisherigen Grenze.

Im späteren Hostlauf **43580228966**, Builder **132403166536**, mit demselben
Native-Stand erreichte die Probe fortlaufend alle fünf Profilgrößen. Das letzte
Profil begann nach **432,874 Sekunden**, gegenüber **416,813 Sekunden** im
erfolgreichen Native-Lauf: **16,061 Sekunden später**. Der Hostlauf wurde bei
600 Sekunden beendet und besitzt keinen abschließenden Treasure-PASS. Diese
Beobachtung begründet mehr Reserve für genau diesen Software-Renderer-Test;
sie beweist nicht, dass der abgebrochene Lauf ansonsten erfolgreich geendet hätte.

Die vollständigen Originaljoblogs wurden gelesen und gehasht:

- Native: SHA256 `4943ffc5da3738255342a248e73dc0005f05159ebd1e68e8e91f3ed01e18d266`.
- Host: SHA256 `c922c2df3400fa97bbaa4f00ab8e2d046d3a326a872a36ac16022bac01a3210c`.

Der separate Hostfehler `FileNotFoundError: ffmpeg` trat nach abgeschlossenem
Facial-Godotlauf beim Start des Encoders auf. Ein laufender ffmpeg-Prozess wurde
dabei nicht gestartet. Der fehlende Host-Paketvertrag wird getrennt korrigiert;
dieser Native-Patch verändert weder Encoder noch Cleanup.

## Prüfung und ehrliche Grenze

`bash -n` für den neuen Harness wurde tatsächlich mit Exitcode 0 ausgeführt.
Die 13 bestehenden `StudioPuzzleMenuContractTests` wurden gestartet, aber der
lokale Ausführungstransport fiel währenddessen aus. Der erhaltene Rohlog hat
keinen Abschluss und es liegt kein abschließendes Execution-JSON vor.
**Der lokale 13er-Abschluss bleibt UNCONFIRMED; kein PASS wird behauptet und
kein weiterer lokaler Lauf wurde gestartet.**

Die zwei neuen Quelltexte wurden vollständig gegen die zuletzt lokal
gemessenen SHA256-Werte rekonstruiert, als unveränderliche Gitblobs angelegt
und vollständig zurückgelesen. Entfernt man ausschließlich die drei
Kommentarzeilen und kehrt die drei Zahlenänderungen um, ergeben sich die
ursprünglichen vollständigen 785-Dateien.

Ein neuer echter Native-CI-Lauf muss die bestehenden Verträge und die
vollständige Rendererabnahme erneut erfüllen. Das größere Testzeitbudget
belegt keine Gerätegeschwindigkeit, keine Android-Freigabe und keine 60 FPS.
Es wurde hier kein neuer Renderer- oder Androidlauf ausgeführt.
