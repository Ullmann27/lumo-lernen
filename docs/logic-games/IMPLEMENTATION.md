# Lumo World und Logikspiele

Arbeitsstand: 23. November 2026. Beide Repository-Zweige heißen
`feature/logic-world-20261123`. Grundlage sind Flutter
`da66baeed50be33bc13d750a846a9eced33aa3dc` und Godot
`c9619c589e3a9faa0b56f190fb38a61bf44bb1d6`. Die alte Hauptlinie und vorhandene
Veröffentlichungen werden durch diesen Arbeitszweig nicht verändert.

## Spielidee und tatsächlich angeschlossene Bereiche

Die Spielewelt erhält die beiden Einstiege **Logikspiele** und **Lumo World**.
Die Welt wächst aus den vorhandenen Modellen und der Landschaft der Schatzsuche.
Die eigenständige Schatzsuche bleibt zugänglich. Der vorhandene orange-weiße
Lumo mit blauer Fliegerbrille und dunkelblauer Jacke bleibt die Spielfigur.

Die spielbare Fläche verbindet die Schatzinsel, Sonnendorf, Schule,
Gemeinschaftsgarten, Sternenstadt mit Park und das bereits gebaute eigene Dorf.
Das aktuelle Weltrechteck umfasst 992 × 476 Szenenmeter. Diese Zahl bezeichnet
die räumliche Ausdehnung, keine Behauptung vollständig gefüllter Großstädte.
Die erste zusammenhängende Geschichte enthält sechs Missionen:

| Mission | Handlung und Lerninhalt |
| --- | --- |
| Ein neues Zuhause | Nelli vor ihrem Haus besuchen und ansprechen. |
| Gemeinsam zur Schule | Zu Fuß an der Ampel warten und bei Grün die Straße überqueren. |
| Der Plan für den Garten | In der Lern-App drei bewertete Matheaufgaben der aktuellen Schulstufe lösen. |
| Der Garten erwacht | Pflanzen für den Gemeinschaftsgarten berechnen, mit je einer eigenen Aufgabe für die Schulstufen 1–4. |
| Post für Sternenstadt | Einen Lieferhinweis lesen und sein Ziel bzw. seine Reihenfolge verstehen. |
| Ein Platz für alle | Bei einem Picknick eine rücksichtsvolle Einladung auswählen; Nelli selbst entscheiden lassen. |

Lumo kann gehen, laufen und sein bestehendes Kart benutzen. Der Bewegungsablauf
verwendet das vorhandene Lumo-Modell; Blickrichtung, Beschleunigung, Bremsen,
Gangwechsel und Kamera werden im Weltcontroller geführt. Die Bedienung umfasst
Joystick, Interaktion, Laufen, Ein-/Aussteigen und Übersicht. Eine Einstellung
für verringerte Bewegung wird berücksichtigt. Auto und Schulbus bewegen sich
auf der Straße und halten für die Fußgängerphase. Fahrrad und Scooter sind
bereits als 3D-Modelle sichtbar; die Fahrzeugsteuerung dieses Kapitels ist das
Kart. Eine vollständige österreichische Straßenverkehrsausbildung wird durch
die erste Ampelmission nicht behauptet.

### Ein Dorfspielstand für Strategie und Erkunden

`lumo_world_village.gd` lädt den vorhandenen Dorfspielstand für dasselbe Kind
und denselben Bauplatz. Gelände, Gebäude, Positionen und Einwohner stammen aus
der bestehenden Dorfstrategie. Die Weltansicht verändert weder diese Datei
noch ihre Wirtschaft oder ihren Tagesfortschritt.

Am Bauplatz öffnet sich die ursprüngliche Dorfstrategie. Nach der Rückkehr
wird der aktuelle Dorfstand neu eingelesen. Die Rennstrecken und der
Kartensalon öffnen ebenfalls die vorhandenen Spiele und kehren an den
Weltursprung des Besuchs zurück. Der normale Einstieg in diese Spiele behält
seinen bisherigen Rückweg. Der Kinderschlüssel und die Bauplatznummer werden
durch die Übergänge weitergegeben; eine zweite Dorfkopie wird nicht angelegt.

### Die Schule ist mit echten Lernaufgaben verbunden

Der native Auftrag enthält eine dauerhafte Request-ID, Schulstufe und genau
einen unterstützten Missionstyp. Flutter öffnet `WorldSchoolLessonScreen`
mit drei Aufgaben aus `ExerciseFactory` und dem vorhandenen Aufgabenrenderer.
Richtige und falsche Antworten nutzen die bestehende Lernfortschrittslogik.
Erst drei gespeicherte richtige Antworten erzeugen die passende Rückmeldung.

Ein Abbruch öffnet die Welt wieder mit noch offener Mission. Ein fremdes Kind,
eine andere Schulstufe, eine falsche Request-ID oder eine wiederholte alte
Rückmeldung kann den Auftrag nicht abschließen. Wird das Schuljahr während
einer offenen Mission geändert, erhält die Schule eine neue passende Anfrage.
Der Native- und Dart-Transport validiert das begrenzte Schema in beiden
Richtungen. Eine School-Rückmeldung ist kein frei übertragbarer Belohnungscode.

## Drei Logikspiele mit nachvollziehbarem Fortschritt

Es gibt 3 Spiele × 4 Schulstufen × 12 Level, insgesamt 144 unterschiedliche
Rätsel. Alle Aufgaben und Lösungen sind reproduzierbar. Fortschritt entsteht
durch richtige Eingaben. Es gibt keine neuen Würfel-, Einsatz- oder
Zufallsgewinnmechaniken.

| Spiel | Inhalt und Steigerung |
| --- | --- |
| Sudoku-Insel | 4×4- und 6×6-Raster; eindeutige Lösungen, mit einfachen Schlussfolgerungen lösbar; schrittweise weniger Vorgaben. |
| Wörterwerkstatt | Zusammenhängende Kreuzworträtsel mit drei bis sechs Wörtern, echten Hinweisen und sich kreuzenden Buchstaben. |
| Zahlenbrücken | Mathekreuzworträtsel mit exakten ganzzahligen Lösungen; Addition/Subtraktion bis zu Multiplikation und Division. |

Die Oberfläche folgt der dunklen Glas-/Neon-Gestaltung der bestehenden
Knobelbereiche. Die Vorschauen zeigen jeweils ein tatsächlich aus den
Aufgabendaten gezeichnetes Raster. Richtige Eingaben erhalten eine grüne
Umrandung und ein Häkchen, falsche Eingaben eine ruhige Rückmeldung. Die
vorhandenen Sound- und Bewegungseinstellungen gelten auch hier. Die Rätsel
besitzen eigene gespeicherte Entwürfe; nach Verlassen oder Neustart können sie
fortgesetzt werden. Ein gelöstes Rätsel schaltet das nächste Level frei.

Die Eingaben bleiben pro Kinderprofil getrennt. Hilfen und Fehler werden beim
Fortsetzen erhalten. Eine Wiederholung überschreibt keine frühere selbständige
Erstbeobachtung. Speichervorgänge werden abgewartet; ein Speicherfehler zeigt
eine Wiederholungsmöglichkeit statt einen nicht gespeicherten Erfolg.

## Stärkenprofil mit fachlich klarer Bedeutung

Das neue Profil beschreibt **logisches Kombinieren**, **Wörter und
Rechtschreiben** sowie **Rechnen und Prüfen** anhand der konkreten Rätsel.
Es nutzt keine Geschwindigkeit, Rangliste oder erfundene Normwerte. Hinweise
auf selbständiges Lösen höherer Stufen werden ausdrücklich auf diese Aufgaben
bezogen. Als nächster Schritt werden passende Übungen vorgeschlagen.

Die fachlichen Quellen, die dokumentierten Produktregeln und die Grenzen der
Interpretation stehen in [LEARNING_PROFILE.md](LEARNING_PROFILE.md). Der
bestehende Knobelprofil-Bereich bleibt erreichbar. Sudoku oder einzelne soziale
Missionen werden nicht als normierter IQ-, EQ-, AQ- oder Persönlichkeitstest
ausgegeben.

## Datenerhalt und lokale Nutzung

Die Logikstände werden nach stabiler Schüleridentität gespeichert und in die
bestehende Datensicherung, Wiederherstellung und gezielte Profilzurücksetzung
eingebunden. Auch die eigene World-Datei ist Teil der nativen Sicherung.
Bestehende Lernmodule, Schreibtrainer und Journal werden modular aufgerufen
und nicht ersetzt. Die neuen Spiel- und Missionsregeln benötigen keine
kostenpflichtige Cloud-KI. Einwohner und Verkehr folgen lokalen Spielregeln.

Die Welt nutzt vorhandene Ressourcen sowie vier kleine neue GLB-Modelle.
Eine künstliche Vergrößerung auf 1,5 oder 2 GB verbessert die Qualität nicht.
Der Aufbau erlaubt weiteren Inhalt über zusätzliche Regionen und Missionen,
während Sichtweiten und entfernte Dorfmodelle die gleichzeitig gezeichnete
Menge begrenzen. Die tatsächliche Paketgröße wird aus der gebauten APK
abgelesen. 60 FPS auf einem konkreten Android-Gerät werden erst nach einer
Gerätemessung bestätigt.

## Prüfung und Auslieferung

Die dedizierte Pipeline `.github/workflows/lumo-logic-world-apk.yml` bindet die
APK an exakt die gepinnte Godot-Revision und den Flutter-Commit. Sie prüft
Rätselinhalt, Fortschritt, Profile, Rückkehrwege, Datensicherung und echte
Native-Verträge. Godot prüft die Welt, HostBridge, ursprüngliche Schatzsuche
und den Kartentisch. Der echte Renderer erzeugt fünf Spielansichten.

Anschließend werden signierte ARM64- und x86_64-Testpakete gebaut. Die
Paketprüfung verlangt identische eingebettete Spielressourcen und prüft die
Welt erneut aus dem tatsächlich im APK enthaltenen PCK. Der Android-Rundgang
installiert diesen Kandidaten, beobachtet die echten UI-Spielstarts
einschließlich World und führt den SAF-Backup-Rundlauf aus. Erst danach darf
der Veröffentlichungsjob ein neues Release anlegen.

Die lokalen Screenshots sind Flutter-Widget- bzw. Blender-Belege und dürfen
nicht als Aufnahme eines echten Telefons bezeichnet werden. Der vollständige
lokale Flutter-Analyseprozess wurde in der gemeinsam genutzten Laufzeit einmal
mit Signal 9 beendet; ein erfolgreicher kompletter Lauf wird erst anhand der
CI bestätigt. Aktuelle Prüfergebnisse und gegebenenfalls Blockaden gehören
in `STATUS.md` und `CONTINUE.md`.
