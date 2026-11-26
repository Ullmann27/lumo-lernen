# Intelligence 2.0 – Build 2083, Integrationskandidat

Basis: geprüfte 2082 (Flutter 6574b19f92abb4f6421fd3074cec09738dc0974a; Godot 62108c0355f860ab9a0a020ecb5f3f941f1032e9). Die auf GitHub gesicherten Opus-Quellen werden in einem getrennten Integrationszweig kombiniert. Kein Merge nach main und keine Änderung an den Agentenzweigen.

## Flutter
- Opus-Hauptstand A1–A3/A6: 7d017df62f78db96f0125eeb572c87675f7cf414.
- A4 Lehrplan/Expertenwelt: 70fd2386a81576bf5a70b7fb0c5945532ca6983f.
- A5 Verständnis/Nachhilfe und Hausaufgaben WIP: 7c22d00e3d2230ae2e7813a373ba8c788f86c487.
- A6 echte Android-Kennzahlenprobe: b374b534d7355988e4395d0d9f5a1b998f5d4a58.
- B3 Lernspiele: 0bf1e525e0d0391f80bfc80beceb96109ffcd52e.

Konfliktentscheidungen: LearningGuidance vereint den neuen Profilfilter mit Vergleichsaufgaben und Verständnisnachweisen; A6 übernimmt Dashboard-Semantik und Probe auf identischem Elternkennzahlenstand. Die A4-Prüfmatrix behält die Spalte Ebene, sieben Lernspiel-Zeilen erhalten die tatsächlich in B3 geänderte Klasseneinstufung und Schwierigkeit. Die Matrix muss erneut durch den bestehenden Test bestätigt werden.

## Godot
Exakter Pin 94477ade6339133bb15125d719b50af80d615ea0. Drei neue Strecken, neun neue stehende Tiermodelle, WIP-Karosserien und Fahrgefühl, neue Tischbewegungen, Sternenjagd-Pause, Sonnenhafen mit 71 Modulen/14 Bewohnern und fünf Missionen sowie acht wiederkehrenden Lieferaufträgen. Die bestehenden 16 Produktions-Meshy-GLBs und ihr Manifest wurden mit dem 2082-Git-Baum verglichen und sind byteidentisch. Import-Cleanup bleibt unverändert hashgesichert. Neue Figuren-/Stadt-/Strecken-JSON-Dateien sind in den Exportfiltern und werden zusätzlich im aus der ARM64-APK extrahierten PCK geprüft.

WIP-Zweige sind bewusst als Prüfstand übernommen, nicht als fertig erklärt. Alle früheren Schutzprüfungen bleiben aktiv; zusätzliche Regressionen für neue Inhalte sowie Android-Elternkennzahlen. Die Versionsnummer 0.14.10+2083 und Original-Testsignatur werden genutzt; keine neue Paketkennung. Die separate native CI läuft auf dem neuen Pin.

Offen: tatsächliche gemeinsame Testergebnisse, APK-Bau und physische ARM64-Prüfung. Noch keine vollständig entwickelten weiteren Städte bzw. 30 neuen Missionen; Sitz- und Stehmodelle der Hafenbewohner müssen weiterhin passend geprüft werden. Öffentliche Release-Tag-Berechtigung bisher HTTP 403; geprüfte APK soll als GitHub-Artefakt verfügbar werden.
