# Schatzsuche: begrenzte Rückmeldung aus tatsächlichen Spielständen

## Originalbefund

Der Android-Job **132269951369** aus Run **43530667812** prüfte die unveränderte Hostquelle `4ab96666f954baf258422d6ed277fc297b7ddeef` mit Nativequelle `803e7a626ea6ef0aeeda9c37010e844033d3a8e3`. Sein Originalartefakt **14092241868** bleibt ein fehlgeschlagener Lauf.

Die Schatzsuche wurde tatsächlich gestartet. Zwölf protokollierte Eingaben am erkannten Originalstick bewegten die Figur; dreizehn originale Spielstände zeigen eine stetige Annäherung an den ersten Baumhinweis. Der horizontale Abstand sank von **18,4391** auf **8,4775** Welteinheiten. Jede Einzelbewegung betrug **0,6942 bis 1,5135** Einheiten. Die ersten acht angeforderten Haltezeiten waren 1.500 ms, danach folgten 1.455, 1.339, 1.224 und 1.108 ms.

Die ursprüngliche Probe errechnete die Eingabedauer aus verbleibender Strecke geteilt durch sechs. Die Spielquelle verwendet diese Geschwindigkeit jedoch in `_physics_process(delta)`, während die Android-Eingabe nach verstrichener Realzeit endet. Die Originalbelege zeigen, dass diese Umrechnung für den beobachteten Lauf nicht trägt. Sie beweisen weder eine Kollision am Ziel noch einen unerreichbaren Hinweis. Das Log nennt `llvmpipe`; konkrete Render- oder Physikzeiten dieser Bewegung wurden nicht gemessen.

Die drei Originalbilder `0121-entered-schatzsuche.png`, `0192-observe-original-stick.png` und `0198-treasure-failure.png` wurden einzeln geöffnet. Sie zeigen die aktive Aufgabe, sichtbare Bedienelemente und den veränderten Standort. Am Ende wurde der Hinweis noch nicht erreicht. Die ausgewählten Bild-, Eingabe- und Savebytes wurden unabhängig mit ihren Mitgliedern im einzigen Original-ZIP verglichen; SHA-Bindungen stehen in `original-observations.json`.

## Enger Reparaturzuschnitt

Nur die getrennte Prüfkopie unter `qa/creative-repair-4ab/treasure` wurde geändert. Die App, die Nativequelle und die aktiven gemeinsamen Probe-Dateien blieben unverändert.

Der neue Controller behält **höchstens zwölf Segmente** und die bisherige Fundvoraussetzung **Abstand < 3,4**. Die erste angeforderte Haltezeit bleibt 1.500 ms. Weitere Haltezeiten folgen dem tatsächlich zurückgelesenen Fortschritt zum Ziel. Für jede Eingabe gilt eine Grenze von **220 bis 6.000 ms**, für alle angeforderten Haltezeiten zusammen **60.000 ms**. Die Bewegungsphase einschließlich ihrer Beobachtungen wird zusätzlich durch einen **900-Sekunden-Timer** begrenzt. Dieser Linux-Timer unterbricht auch eine blockierte Beobachtung und stellt danach den vorherigen Signalhandler wieder her; ein schon aktiver Timer wird nicht ersetzt.

Die nächste Eingabe kommt weiterhin aus dem gerade erkannten Originalstick. Es gibt keine festen Bildschirmkoordinaten und keine Änderungen an Spielständen. Stillstand, Bewegung vom Ziel weg, ungültige Koordinaten, veränderte Rundenzuordnung oder unverdiente Hinweisdaten führen zum Fehler. Der zuletzt zulässige Bewegungsschritt wird vor dem Budgetfehler tatsächlich ausgewertet.

Der vollständige ursprüngliche Folgepfad bleibt erhalten: echte Bewegung, `ANSEHEN`, tatsächliche Frage, Antwort `Ein Tropfen Wasser`, gespeicherter erster Baumfund, sichtbarer `Blattschlüssel`, Rückkehr, erneutes Öffnen und Vergleich des wiederaufgenommenen Zustands. Die erfolgreiche Bewegungsphase allein wird als `TARGET_REACHED` protokolliert und ist keine Spielabnahme.

## Ausgeführte lokale Gegenfälle

Zwei unveränderte Vertragsfälle scheiterten zuerst am Originalcode: langsamer, fortlaufender Fortschritt und ein Ziel, das erst nach der zwölften Eingabe erreicht wird. Danach bestanden **20 von 20 Prüfungen ohne Skip**: elf gezielte neue Fälle und neun unveränderte bestehende Probeverträge. Die protokollierte Laufzeit beträgt **0,243 Sekunden**; `ResourceWarning` wurde als Fehler behandelt.

Die neuen Fälle prüfen insbesondere Budgetabbruch, ausbleibenden Fortschritt, Bewegung vom Ziel weg, veränderte Rundenzuordnung oder Hinweisdaten, ungültige Koordinaten, Timerunterbrechung und Wiederherstellung sowie das unveränderte Weiterprüfen von Fund, Rucksack und Wiederaufnahme. Die dreizehn echten Originalreadbacks bleiben auch im neuen Controller ausdrücklich ein Fehler. Der positive lokale Bewegungsfall ist ein **synthetisches Modell mit aus den Originalen abgeleiteten Raten**, kein neuer Android-Nachweis.

Der erste grüne Integrationsversuch enthielt einen zu engen erwarteten Fehlertext im Negativtest: Die kumulierte Haltegrenze griff vor der Segmentgrenze. Dieser rote Zwischenstand bleibt als `controller-green-v1.log` erhalten. Der Negativtest verlangt weiterhin einen Budgetfehler, unveränderte Originalreadbacks und keinerlei Fundaktion.

**42 bestehende Definitionen** sind AST-identisch. Nur `Tour.treasure` wurde geändert; drei neue Definitionen ergänzen den Controller. Der vollständige ursprüngliche Prüfblock ab der Bewegungsbehauptung bis einschließlich Rückgabe ist AST-identisch. Die genaue Gegenüberstellung und sämtliche Quellhashes stehen in `source-preservation.json` und `source-freeze.json`.

## Offene Abnahme

Es wurde kein weiterer Android- oder Godot-Lauf gestartet. Erst ein neuer ausdrücklich gebundener Androidlauf kann zeigen, ob die begrenzte Rückmeldung das Ziel tatsächlich erreicht und anschließend alle unveränderten Fund- und Speicherprüfungen besteht.

Diese Androidprobe umfasst weiterhin nur den ersten Baumfund, den Rucksack und die Wiederaufnahme. Beide späteren Verzweigungen und der Abschluss der gesamten Schatzreise werden hier weder neu geprüft noch als bestanden dargestellt. Aus den lokalen Verträgen folgen keine Geräte-FPS- oder Fold7-Aussagen.
