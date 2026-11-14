# Originale zusätzliche Android-Spielprüfung: 4ab / 803e

**Der verpflichtende Creative-Job ist fehlgeschlagen. Eine von vier Spielprüfungen ist belegt bestanden.** Die separaten Prüferkorrekturen ändern dieses historische Ergebnis nicht.

| Bindung | Tatsächlich geprüft |
|---|---|
| Host / Probe | `4ab96666f954baf258422d6ed277fc297b7ddeef` |
| Native | `803e7a626ea6ef0aeeda9c37010e844033d3a8e3` |
| Run / Versuch / Job | `43530667812` / 1 / `132269951369` |
| Originalartefakt | `14092241868`, `lumo-studio-2019-creative-android` |
| Original-ZIP | 526.570.745 Bytes, 1.713 Einträge, vollständige CRC-Prüfung bestanden |
| ZIP-SHA256 | `bd1660a6032c9adba051f209ab3979ea1888d03ffeb902bd0403d3f813a61d40` |
| Tatsächliche Laufzeit | Emulator API 35, Android 15, `sdk_gphone64_x86_64` |
| APK-SHA256 laut echtem CI-Identitätsprüfer | `7c647296c57ffce9950e117889685360ec024407dead35486eecc1331db3f9b6` |
| Direkt im CI aus dem APK gelesene PCK | 66.234.596 Bytes; `28032ec5f08db510d5baa1e10b7cbf8cade072081c5d8be8f40181c65d7aa01e` |

APK- und PCK-Identitäten stimmen mit dem abgeschlossenen Buildbericht überein. Der Reviewer hat keine zweite APK heruntergeladen oder lokal erneut binär gehasht. Das gesamte Original-ZIP wurde einmal gespeichert und geprüft; nur ausgewählte Belege wurden entpackt. Die vollständigen Shader-Caches wurden nicht zusätzlich extrahiert.

## Tatsächlich erreichte Bedienung

Die vier aktuellen Flutter-Portale wurden über echte aktivierte und anklickbare Semantics-Knoten erreicht: Jump & Run, Bauwelt, Puzzle und Schatzsuche. Der Originalbericht enthält fünf solche Eintritte, weil die Bauwelt später erneut geöffnet wurde. XML, beobachtete Bounds, Bildbezug und reale Eingaben sind im Original-Eingabejournal enthalten. Damit ist der frühere fehlende Android-Semantics-Tap in diesem Lauf überwunden. Das allein erfüllt noch keinen Spielvertrag.

| Modul | Originaler Ablauf und Ergebnis | Nachweisgrenze |
|---|---|---|
| Jump & Run | Szene läuft im Hochformat. Alle 28 vollständigen 1080 × 1920-Bilder werden vom Prüfer vor OCR wegen seines falschen Querformatzwangs verworfen. Pause wird nicht angetippt. | Keine reale Stick-/Sprungeingabe, kein Jump-Checkpoint und kein Video im vollständigen Artefakt. Keine nachträgliche Video-Abnahme möglich. |
| Bauwelt | **Bestanden:** Ein neuer Sandstein mit UID 198 bei `(-3, 0, 2)` wird durch eine echte, anhand aktueller Kamera und Bild begründete Bodenberührung hinzugefügt. 197 → 198 Teile; alle vorherigen Teile bleiben erhalten. Undo stellt exakt die ursprünglichen `pieces` her, Redo exakt die neue Menge. | Ein einzelner nachgewiesener Bauvorgang, keine neu errichtete Gesamtwelt. Die 3 Sterne / 24 XP beziehen sich ausdrücklich auf das vorhandene Starterhaus. |
| Puzzle | Menüwechsel und Start erfolgen. Der echte Originalstand beginnt mit Motiv 3; ein Bildtipp führt korrekt zu Motiv 4. Gespeichert sind sechs Teile, Motiv 4 und Drehmodus. Die alte Probe hatte Motiv 0 angenommen und verlangt nach einem Tipp Motiv 1. | Die spätere manuelle Vierteldrehung und Wiederaufnahme werden wegen dieser falschen Vorbedingung nicht erreicht. Kein Saveverlust und kein fehlerhafter Motiveingabepfad ist damit belegt. |
| Schatzsuche | Zwölf echte Sticksegmente und 13 gelesene Spielstände zeigen fortlaufende Annäherung an den ersten Baum: Abstand etwa 18,439 → 8,478. Das feste Eingabebudget endet vor dem unveränderten Zielradius 3,4. | Noch kein erreichter erster Hinweis, keine beantwortete Frage, kein neuer Inventarfund und keine bewiesene Wiederaufnahme. Kein nachgewiesener Joystick- oder Kollisionsfehler. |

## Eigenständige Gegenprüfung der Bauwelt

Die sechs Originalspielstände wurden unabhängig miteinander verglichen. Die Objektzahlen lauten **197, 198, 197, 198, 198, 198**. Die ursprünglichen Objekte bleiben unverändert. Die beiden `pieces`-Vergleiche für Undo und Redo sind exakt; der komplette gespeicherte Abschlussstand stimmt mit dem später eingelesenen Wiederaufnahmestand überein. Der fortlaufende `next_id`-Zähler wird richtigerweise nicht als rückgängig zu machendes Bauobjekt behandelt.

Drei Original-Wallets zeigen 0 → 3 → 3 Sterne und 0 → 24 → 24 XP. Der zweite Start verdoppelt die Starterhaus-Belohnung nicht. Die tatsächlich geöffnete Rückkehraufnahme zeigt die neu dargestellte Flutter-Spielewelt und die drei Sterne; sie ist kein stehen gebliebener Godot-Puffer.

## Sichtprüfung und Zuordnung

Agent B hat neun Originalbilder aus der kuratierten Auswahl tatsächlich geöffnet: die Flutter-Spielewelt, vier Jump-Bilder und vier Bauwelt-/Rückkehrbilder. Für den engen Jump-Gegenlauf wurde zusätzlich ein zweiter unveränderter Original-Pauseframe geöffnet und mit echter OCR gelesen. Original-Lumo und die vollständigen Jump-Touchflächen sind sichtbar. Die kurze obere Bedienhilfe liegt teilweise über der Kopfzeile; dieses Bild ist keine pauschale Layout- oder Bewegungsfreigabe.

Agent A hat genau drei ursprüngliche Puzzle-Bilder geöffnet und sie mit der exakten Native-Quelle und dem tatsächlichen Spielstand verknüpft. Agent C hat genau drei ursprüngliche Schatzsuche-Bilder geöffnet und die 13 Positionen mit den zwölf Eingaben verbunden. Die quellengebundenen Einzelberichte sind im JSON-Review genannt. Weitere selektiv aufbewahrte Bilder werden nicht als persönlich geprüft ausgegeben.

Der Originalbericht zählt keine fatalen App-Abstürze; der gespeicherte Trefferbericht für native Enginefehler ist leer. Dies ersetzt weder die gescheiterten Spielverträge noch eine allgemeine Stabilitätsabnahme.

## Reparatur und weiterhin offene Abnahme

Die drei Fehler werden in getrennten QA-Patches behandelt: Jump verwendet die bereits vorhandene responsive-Prüfrichtlinie; Puzzle wählt das Zielmotiv anhand tatsächlich sichtbarer vollständiger Beschriftungen; Schatzsuche nutzt weiterhin begrenzte echte Eingaben mit Rückmeldung aus gelesenen Spielständen. Bestehende Save-, Video-, Profil-, Rückkehr- und nachfolgende Spielbedingungen bleiben bestehen. Diese lokalen Gegenfälle sind keine neue Androidausführung.

Der nächste echte Lauf muss die fehlenden Spielaktionen erneut am exakt gebundenen Kandidaten durchführen. Ein dann entstandenes Jump-Video muss vollständig dekodiert und inhaltlich gesichtet werden, bevor `RECORDED_REVIEW_REQUIRED` aufgelöst werden kann. Medien-Framerate ist keine gemessene Geräte-Framerate. Physische Fold7-Leistung, Android 17, thermische Belastung, native CPU-/GPU-Zeiten, Eingabelatenz, gleichzeitiger Multitouch und komplette Spielreisen werden durch diesen API-35-Lauf nicht nachgewiesen.
