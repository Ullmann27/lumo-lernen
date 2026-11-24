# Lumo Gesamtmatrix – dauerhaft gepflegte Produktübersicht

Angelegt am 17.11.2026 im Auftrag von Heinz („Gesamtprodukt – alles bedeutet alles").
Diese Datei ist die verbindliche Liste aller Produktbereiche mit Status und Nachweis.
Sie ersetzt keine Übergaben, sondern sagt je Bereich: was gibt es, was fehlt, was ist geprüft.

**Regeln für diese Datei**

- Kein pauschales „Rest fertig". Jeder Bereich hat einen eigenen Status.
- Status: `OFFEN` · `IN ARBEIT` · `TEILWEISE` · `PASS (lokal)` · `PASS (Android-Emulator)` · `PASS (Gerät)` · `NOT_RUN`.
- „PASS (lokal)" heißt: Test in dieser Sitzung auf Linux mit Godot 4.6.3 bzw. Flutter 3.44.9 selbst ausgeführt. Das ist keine Geräteprüfung.
- Wer etwas ändert, trägt Datum, Commit und Nachweis ein.

## 1. Quellstand (17.11.2026)

| Repo | Arbeitsbranch | Basis | Bemerkung |
|---|---|---|---|
| lumo-lernen (Flutter) | `ccr-54af69f2-4uged4` | `lumo-nullpunkt/integration-20261117` @ `d7930240` | Version 0.13.25+2037, Godot-Pin `bb478880` (noch alt) |
| lumo-godot (Godot 4.6.3) | `ccr-54af69f2-4uged4` | `lumo-nullpunkt/integration-20261117` @ `ebd3401` | plus 2 Kart-Reparaturen und 6 Streams (Integration‑2), siehe Abschnitt 6 |

`main` steht in beiden Repos auf dem Stand vom 16.10.2026 (1951) und ist nicht die Arbeitsgrundlage.
Zuletzt öffentlich belegte APK laut Repo-Dokumenten: 0.13.19+2031 (16.11.). Stände 2032–2037 sind gebaut bzw. vorbereitet, deren Abnahme habe ich nicht selbst geprüft.

## 2. Entscheidungen von Heinz am 17.11.2026

1. **UNO ist raus.** „Lumo Cards" ist im Code UNO mit umbenannten Karten (siehe 4.2). Es wird durch 2–3 eigene Lumo-Kartenspiele ersetzt.
2. **Kartenspiele am echten 3D-Tisch:** runder Tisch, Lumo-Figuren sitzen rundherum, Karten werden sichtbar auf den Tisch gelegt.
3. **Lumo Kart bleibt 3D und hat höchste Priorität:** alle Strecken, Landschaft, Pausenmenü; lange, aufregende Strecken mit Sprüngen, Fallen, Abkürzungen.
4. **Jump‑and‑Run in 3D** mit Lumo von hinten gesehen, sauber animiert, lange aufwendige Strecken mit Aufgaben, mehrere Welten.
5. **Bauwelt / Dorf:** klug ausgearbeitet, schöne Grafik, lange und sinnvolle Kampagne.
6. **Lern-App:** jede Sparte, 1.–4. Klasse Volksschule, jedes Fach, jede Aufgabe ansehen und modernisieren.
7. **Messlatte:** Eltern sollen 14,99 €/Monat als gerechtfertigt empfinden.

8. **Zielbilder sind verbindlich** („genau diese Gestaltung, genau dieses Layout"): `docs/design_targets/2026-11-17/` in beiden Repos (Kart-Menü hoch/quer, Zieleinlauf Platz 1–3, Profil, Startseite auf dem Fold, dazu Boards für Spielwelt, Jump & Run, Schatzsuche, Bauwelt, Memory, Rhythm Party, Puzzle, Cards). Gewünscht sind in Blender gerenderte Knöpfe, Rahmen und Symbole.
9. **Umsetzung mit mehreren Agenten parallel.**

10. **Freischalten durch Lernen, Werkstatt wie in einem Rennspiel mit Bauteilen:** Wer lernt, schaltet schnellere Karts und Bauteile frei. Bestand: 14 Karts mit Sternschwellen (`kart_fleet.gd`), Tuning-Werkstatt mit Motor, Bremsen, Reifen, Turbo (je Stufe 0–5), Lacken, Felgen und Neon, bezahlt mit Lern-Sternen (`kart_tuning.gd`). Ziel: mehr und sichtbare Bauteile, Werkstatt als eigener hochwertiger Bereich, freigeschaltete Karts auch im Profil-Regal der App.
11. **Dorf-/Strategiemodus:** sehr große Karte mit Hügeln und Bergen (dort kann man nicht bauen), Kampagne mit Logik, Freibau, KI-Gegner, die eigene Städte sichtbar auf derselben Karte aufbauen und denen man zusehen kann. Kindgerecht, mit deutlich besserer Grafik. Bestand: `build_settlement_*` (Wirtschaft, Bewohner, sichtbare KI, 22-Tage-Kampagne) auf flachem Gelände.
12. **Jump & Run als 3D-Lauf von hinten gesehen** (wie Lumo Kart, nur dass Lumo läuft): lange Strecken durch Wald, Dschungel und andere Welten, Tempo, Sprünge, Sammeln. Eigene Figuren, Strecken und Gestaltung; kein Nachbau eines bestehenden Spiels. Bestand: `jump_islands.gd` (12 kleine schwebende Inseln, 3 Kurse, Blick von hinten oben) und ein 2D-Spiel in Flutter.

13. **Freie Hand (17.11.2026, abends):** Heinz erteilt ausdrücklich die Einwilligung für alles, was zum Fertigstellen nötig ist, einschließlich des Vereinfachens der selbst auferlegten Build- und Versions-Sperren. Arbeitsweise: autonom, erst die Spiele, dann die Lern-App auf demselben Niveau; jede Lösung zweimal durchdenken.

14. **Echter Lumo überall (18.11.2026, zweimal gesagt):** „Das ist aber nicht unser Lumo. … Die Gegner kannst du verändern, aber unseren Lumo kannst du maximal noch verbessern." Lumo ist überall das geriggte 3D-Modell; die im Code gebaute Ersatzfigur darf nirgends als Lumo erscheinen.
15. **Jump & Run wie Donkey Kong (18.11.2026):** „wirklich spannend", Umgebung „dicht und verbaut und aufregend, mit Musik, mit allem drum und dran … Spiel aus dem Jahre 2027".
16. **Kart-Item-System (18.11.2026):** Raketen links und rechts am Kart, beim Aktivieren mit Feuer, Zielerfassung „wie so ein Kampfjet", Abfeuern auf Knopfdruck; Schild-Abwehr grafisch verbessern; Grafik, Mitspieler und Spielerlebnis „auf das Maximum", Spaß ist wichtig.

17. **Grafik auf PC-/Konsolen-Niveau in ALLEN Spielen (18.11.2026):** Kart, Bauwelt, Dorf-Aufbaumodus („wie eine eigene, länger fassende Geschichte", Grafik und obere Leiste „wie ein PlayStation-/PC-Spiel"), Kartenspiele. Kart: Leitplanke mit Funken und Geräuschen, Bremsspuren, neu gerenderte Knöpfe für Gas und Bremse, Bäume mit Struktur statt vollflächig grün, Straßenbeleuchtung, Straßengrafik, Partikel – „fordere jeden Chip heraus … ich sage nicht, dass du es schaffen musst, ich sage, dass du es wenigstens versuchst."
18. **Figuren neben Lumo wie im Animationsfilm (18.11.2026):** „Ein Hase soll wie ein Hase ausschauen, ein Löwe wie ein Löwe … wie Paw Patrol. Mit den Figuren, die du jetzt produziert hast, würde ich nicht einmal eine Sekunde anfangen aufzunehmen." Befund: Die fünf Mitspieler teilen sich einen Körper und eine Kopf-Schablone; die Zielbilder liegen unter `assets/characters/rivals/reference/` im Spiele-Repo.
19. **APK erst bei sehr gutem Stand (18.11.2026):** volle Konzentration auf die Spiele; die nächste APK kommt, wenn Claude sie guten Gewissens übergeben würde.

20. **Details machen das Spiel (18.11.2026):** eigene Helfer nur für Kleinigkeiten – „Häuser haben Risse, Fassadenrisse … Nebensachen, auf die man nicht aktiv schaut, aber wenn man sie sieht, ist man verwundert." Maßstab für Android: Spiele wie Call of Duty Mobile oder Rome Total War auf „Ultra". Ziel ist der Wow-Effekt: Die Spiele sollen fast als eigenständige Spiele gelten können.
21. **Geschäftsmodell und Lernbezug (18.11.2026, bekräftigt):** ein Abo von 15 € im Monat für die ganze App, keine Käufe im Spiel. Sterne aus dem Lernen sind die Währung in den Spielen („Ihr Wissen ist ihr Geld"); Lernerfolge schalten Items und Verbesserungen frei. Lumo als Nachhilfelehrer und Freund: Versteht das Kind etwas nicht, erklärt Lumo es in der 3D-Lernwerkstatt spielerisch und schlägt einen anderen Weg vor, wenn es noch nicht sitzt.
22. **APK jetzt, danach erweitern (18.11.2026, mittags):** „Ich will jetzt die APK haben, ausprobieren und dann die Strecken erweitern.“ Alles, was die Helfer entwickelt haben, wird zusammengeführt; die Streckenwahl im Kart muss stimmen (Vulkan → Vulkan, Dschungel → Dschungel), von Claude selbst im Menü durchgetestet, samt Items. Ersetzt für diese APK Entscheidung 19.
23. **Gemeinsam spielen (18.11.2026):** Geschwister (Zoe und Alina) wählen im Kart je einen Fahrer und fahren zusammen; in Bauwelt/Dorf bauen sie gemeinsam – „verbunden, wenn man will, oder allein weiter“. Profil = Profil der Lern-App. OFFEN, nach der APK; Entscheidung von Heinz nötig: ein Gerät, gleiches WLAN ohne Server oder Internet mit Server (Datenschutz Kinder).
24. **Dorf/Aufbau/Strategie groß (18.11.2026):** KI-Gegner, die mit aufbauen und mit Sinn angreifen („wie bei Rome“), Tutorial, das ins laufende Spiel übergeht, Umfang für „Wochen oder Monate“. OFFEN, Auftrag geschrieben, Start nach der APK.
25. **Jump & Run schneller und flüssiger (18.11.2026):** Maßstab Sonic (Tempo, Aufgaben), Lumos Bewegungen flüssiger, mehr Action; Lumo Kart mit Mario Kart vergleichen. TEIL ERLEDIGT am 18.11. nachmittags (Tempo, siehe 4.6); offen: fließende Übergänge, Aufgaben je Abschnitt, Gegner mit Charakter, Kart-Gefühl.
26. **Lumo in der Lern-App lebendig, voller Nachhilfelehrer (18.11.2026, nachmittags):** bessere Visualisierungen, Darstellungen und Hilfestellungen; Lumo bewegt sich am Bildschirm, „rennt zu den Zahlen, wenn das Kind ihn braucht, wieder zurück auf seinen Standardplatz“, redet mit dem Kind und hört zu; der virtuelle Nachhilfelehrer soll einen Nachhilfelehrer voll ersetzen. Heinz: wenn zu aufwendig für jetzt, zuerst die APK mit den verbesserten Spielen. OFFEN – eigenes Paket, NICHT in 0.13.32+2044.
27. **Schach für Kinder (18.11.2026, nachmittags):** eigene Option „Schach lernen“ für ein Kind ohne jedes Vorwissen (Alina), Stück für Stück über ein geführtes Probespiel; auch ein Weg für Erwachsene; Brett und Figuren „wirklich top“. OFFEN – Auftrag geschrieben, Helfer wurde durch eine Unterbrechung gestoppt und wird neu gestartet.
28. **Werkzeuge nutzen (18.11.2026, nachmittags):** Blender und Renderer für die Spiele einsetzen, „an Realismus und Schärfe der Grafik so nah wie möglich“. Gilt für alle Grafikpakete.
29. **Kart-Menüführung und Präsentation (18.11.2026, abends):** Das bunte Kart-Hauptmenü ist die gestalterische Referenz für jeden Weg dahinter. Höchste Priorität: Streckenauswahl als Bühne (großes nahes Bild der gewählten Rennwelt, 5–7-s-Vorschau zuerst für Winter-Sprint und Dschungelherz, bebilderte Karten mit Fortschritt, kein Garagenpodest) und Garage als Rennwerkstatt (Kart groß in Dreiviertelansicht, Lumo daneben, „Teile wechseln“ beim Kart ab 0 Sternen, Karten mit höchstens zwei beschrifteten Werten, zwei vollständige Steckplätze Radaufsätze/Auspuffblenden, Speicherung je Kind und Kart, sichtbar im Rennen). Danach Fahrer, Tempo & Gegner, Turniere, Ergebnis („Noch einmal“, „Zur Streckenwahl“). Prüfwege A und B, Touch-Ziele ≥ 48 dp, Messwerte nur wenn gemessen.
30. **Mehr Erlebnis im Rennen (18.11.2026, abends, gesprochen):** Raketen sichtbar verfolgen (Flugbahn, Rauch, Treffer wirbelt den Gegner hoch); mehr Action auf manchen Strecken (Engpass in der Höhe, Lavastrom, der nur mit genug Tempo zu überqueren ist; wer fällt, steigt kurz davor wieder ein; gemessen und mit normalem Tempo machbar). Vorbilder nur als Ideenquelle, nichts nachbauen. Dasselbe gilt für Jump & Run, das außerdem nochmals schneller werden soll. Jedes Spiel bekommt beim ersten Einstieg ein Tutorial. Schach: Lernprogramm für Kinder und Spiel für Erwachsene mit den Stufen Anfänger, Fortgeschritten, Meister, Militärschachspieler (die schwierigste).
31. **Anschlussauftrag Kart und Dorfwelt (18.11.2026, abends, schriftlich):** Teil 1 jede Rennstrecke ein eigenes Fahrerlebnis (zuerst Winter-Sprint mit Eisbrücke und Dschungelherz mit Kronenbrücke und Lianenaffe; Präzisionslinie ≥ 1,6 × breitestes Kart; bewegte Hindernisse lassen auch das langsamste Kart nach vollem Halt durch; Kollision, KI, Checkpoints, Minikarte, Rücksetzpunkte mitziehen). Teil 2 Gegner fairer (neues Kind startet auf „Entdecken“, gewählte Stufe bleibt gespeichert, bei Bedarf Rivalenfaktor 0,93 statt 0,96 auf „Abenteuer“, Vergleich mit gleichen Seeds). Teil 3 Dorf mit verständlichem Anfang (Luftblick, Lumo am Bauplatz, Haus → Hof → Tageswechsel → erste Ernte; vier Bereiche Bauen/Versorgen/Nachbarn/Schützen). Teil 4 größere bebaubare Welt und ausgebaute Nachbarstädte. Teil 5 Anbaufläche berechnen (Höfe = aufrunden((Zivil + Wachen) × 1,20 / Tagesertrag); Entwurfswert 2.415 nutzbare Zellen; 30-Tage-Simulation). Teil 6 Herausforderung wächst mit dem Kind (erste Begegnung frühestens Tag 8, Ankündigung ≥ 2 Spieltage, bis 1.000 Wachen in Verbänden). Übergabe mit drei durchgehenden Spielaufnahmen und getrennten Mess- und Entwurfswerten.
32. **Soldaten im Dorf dürfen echte Menschen sein (18.11.2026, nachts, gesprochen):** nicht kindlich; die Kinderfassung soll auch für Erwachsene interessant sein, später evtl. ein eigenes, richtiges Strategiespiel in der Lumo-Spielewelt. STAND: Soldaten als Menschenfiguren und Truppen-Tafel im Godot-Stand `47ea7d2` (lokal getestet); Skelett/Bewegung und Räuberfiguren OFFEN.
33. **„Entdecken“ behält volles Tempo, nur die Rivalen sind schwächer (18.11.2026, nachts):** Eigentempo auf allen Stufen 1,17; Rivalen 0,86 / 0,96 / 1,00. STAND: in Godot `47ea7d2`, `kart_start_level_regression` 27 Prüfungen (lokal). Ob 0,93 statt 0,96 gemessen besser wäre, ist NICHT belegt.
34. **Strecken, Leistungsteile, Freunde, Lumo Lauf (19.11.2026, nachts):** Kart-Strecken spannender (nur umbauen, wenn es besser wird), mehr tauschbare Teile mit echtem Leistungsunterschied, Online/Verbinden mit Freunden, Lumo Lauf: „nur eine Strecke funktioniert, Lumo zu langsam, nicht aufregend“. STAND: vier Helferstände vom Nutzungslimit gestoppt und ungeprüft gesichert (Godot-Zweige `agent/kart-strecken2`, `agent/kart-teile`, `agent/jumprun4`, `agent/verbinden`); Internet-Modus braucht eine Entscheidung von Heinz über einen Server.
35. **Mitspieler neben Lumo neu bauen (19.11.2026, gesprochen):** Die Rivalen im Kart und die Spieler am Kartentisch sehen nicht wie ihre Tiere aus; sie sollen so detailgetreu und so aufgebaut sein wie Lumo (Skelett usw.). IN ARBEIT ab 19.11. 07:15 UTC (Godot-Zweig `agent/figuren2`).
36. **Auftrag an Fable 5.2 nach der Codex-Übernahme (19.11.2026, schriftlich; Wortlaut `docs/handoffs/FABLE_5_2_LUMO_PARALLELAUF.md` auf `repair/lumo-quiz-run-kart-20261119`):** Codex führt den Kandidaten 0.13.40+2052 (Flutter `e06bff96`, Godot `065c43f`) und die Android-Tests weiter. Eigener Zweig `fable/lumo-holos-und-strecken-20261119` in beiden Repos ab diesen Ständen. Zuerst drei vollständige Beispiele: Mathe-Textaufgabe (8 + 5 mit 3D-Äpfeln und Zehnerfeld), Deutschaufgabe (Wortkarten, Verb, Satzbau), früher abwechslungsreicher Abschnitt im Jump & Run; danach Jump & Run/Kart-Spielgefühl und eine Qualitätsrunde durch alle Spiele. Später Übernahme auf den Codex-Zweig und ein höher versionierter signierter Kandidat. `main`, frühere APKs, Signatur und Kinderprofile bleiben unberührt. IN ARBEIT.
37. **Master-Auftrag „LUMO Next Generation“ (19.11.2026, mittags, schriftlich):** alle getrennten Entwicklungen zu einer funktionierenden APK zusammenführen; Android-Fehler von 2052 nach Ursache einordnen (App / Engine / Emulator / Testautomatisierung / Integration); Lern-Hologramme, Tiermodelle, Kart-Strecken, Jump & Run und alle übrigen Spiele; Berichte getrennt nach PASS LOKAL · PASS CI · PASS EMULATOR · PASS GERÄT · FEHLER · NICHT GETESTET. STAND 19.11. nachmittags: Godot-Linien zusammengeführt (PR lumo-godot #208), 2052-Emulatorfehler eingeordnet (Ursache SwiftShader, Tour auf Mesa umgestellt, App `8c985af9`), sechs Mitspieler neu gebaut (Godot `9b411b0`), Lernräume und Lumo Lauf in Arbeit.
38. **Gerätefund Winter-Sprint (19.11.2026, Fold):** „Gegner hängen fest und man stürzt am Anfang mitten auf dem Weg herab.“ Ursache: Eisbrücke ohne Geländer 100 m hinter der Startlinie in einer Kurve. BEHOBEN lokal und in CI (Godot `12b5210`, `9ead50d`): Eisbrücke 766–790 m, Vulkan-Lavapuls 1040 m, Holo-City-Lichtweiche 974 m, Lenkhilfe früher, Hinweiszeile blendet aus. Regel seither: keine Sturz-, Warte- oder Treffer-Passage in den ersten ~350 m; Passage und Rettungspunkt im selben Streckenabschnitt. Am Gerät NICHT GETESTET.
39. **Erweiterungsauftrag Kart (19.11.2026, nachmittags, schriftlich im Chat; gleichlautende Kommentare auf lumo-godot #208 und lumo-lernen #535):** 5–8 Itemzonen je Runde, „LUMO Sternenkompass“ (Ziehung ca. 3,5 s, Ergebnis einmal beim Einsammeln), häufigere Sternraketen mit Messung, zehn neue Items mit echtem Gameplay und logisch berechneten Effekten („Blitz kommt von oben auf den Gegner“), Fahrspaß-Analyse aller 13 Strecken, neuer Modus „LUMO Abenteuer-Parcours“ (Wolkenwerkstatt, Eis-Turm, Dschungel-Tempel), Mehrspieler-Unterbau mit privaten Räumen (Internet erst nach geklärtem Server/Datenschutz und Test auf zwei Geräten). Die nächste APK soll diese Pakete enthalten. IN ARBEIT ab 19.11. 13:00 UTC.

Dazu am 18.11.2026 gestartet (noch nichts zusammengeführt): Detail-Schicht der Kart-Strecken (Verwitterung, Risse, Kleinteile, Zuschauer, Start/Ziel-Bühne), Kartentisch und Tischspiele (Raum, Karten, Memory, Vier gewinnt, Quiz), Schatzsuche/Rhythmus/Puzzle/Spielewelt.

Stand zu 17–19 am 18.11.2026: sechs Arbeitspakete in Arbeit, noch nichts davon zusammengeführt – Kart-Effekte, Kart-Knöpfe/HUD, Kart-Strecken (Bäume, Laternen, Fahrbahn, Partikel), Jump-&-Run-Grafik mit Blender-Modellen, Figuren-Neubau nach den Zielbildern, Dorf-Aufbaumodus (Gelände mit Höhen, Gebäude aus Blender, Licht, HUD). Erledigt und im Spiele-Stand `ddf5bc7`: Item-System (Raketenhalter, Zielerfassung, Schild-Kuppel; 138 Prüfungen), echter Lumo in Schatzsuche, Rhythmus-Spiel, Home und Lernszenen (344 Prüfungen). Test-APK 0.13.29+2041 (App `3e582bc3`, Spiele `39150db`) enthält Kartentisch und Lumo Lauf, aber noch nicht Item-System und die Grafik-Pakete.

Stand zu 14–16 am 18.11.2026:
- Kart: echter Lumo in Rennen, Garage, Werkstatt, Startbild, Vorspann, als Geist und als Rivale (Godot-Test `kart_real_lumo_regression`, 13 Prüfungen); die 14 Regal-Bilder der App zeigen den echten Lumo. Schatzsuche und Rhythmus-Spiel zeigten noch die Ersatzfigur – Umbau in Arbeit.
- Jump & Run: neuer Level „Dschungelherz" (1,6 km, sechs Abschnitte, Fässer, Lianen, Lore, Felsball-Verfolgung, eigene Musik) in Godot zusammengeführt (`lumo_run_regression`: 490 Prüfungen, 30/30 Testläufe im Ziel). Grafik-Durchgang mit in Blender gebauten Modellen in Arbeit. App-Anschluss (Route `run`) in Arbeit.
- Item-System: Zweig `lumo-kart/gameplay-items-20261117` wird zusammengeführt und um Raketenhalter, Zielerfassung und Schild-Kuppel erweitert – in Arbeit.

Daraus von Claude entschieden (kein weiteres Nachfragen):
- **Kart-Items:** Das Katalog-System des Streams `lumo-kart/gameplay-items` (Rakete, Falle, Schild, Glück nach Platz) wird das einzige Item-System; die Resonanz-Ringe werden darin aufgehen.
- **Memory:** Der Flutter-Look ist die Untergrenze; der Optik-Commit `5a79c14c` bleibt draußen.
- **Kartenspiele:** UNO entfällt. Drei eigene Spiele am 3D-Tisch mit traditionellen, gemeinfreien Grundregeln und eigener Lumo-Gestaltung: ein Stichspiel („Sternenstich"), ein Anlegespiel („Sternenleiter") und ein Sammel-Fragespiel („Lumo-Quartett").
- **Profil-Regal:** zeigt die durch Lernen freigeschalteten Karts.
- **Test-APK:** Die Pin-Sperre verlangt keinen handgeschriebenen Eintrag je Buildnummer mehr; Version 0.13.27+2039, Godot-Pin `2b1fd30`; Bau über `.github/workflows/lumo-test-apk.yml`, ausgelöst durch `config/test-apk-request.json`.

Bewusst beibehalten, weil es Kinder schützt und nichts blockiert: Kamera, Mikrofon und Datenweitergabe bleiben standardmäßig aus und hinter der Elternfreigabe; keine Käufe, keine fremde Kommunikation.

Einschränkungen zu den Zielbildern, damit nichts vorgetäuscht wird:
- Es sind Konzeptbilder. Übernommen werden Aufbau und Aussehen; gezeigt werden nur echte Funktionen und echte Zahlen.
- Mehrspieler, Münzen mit „+", Saisonpass Premium, tägliche Challenges, Lokal-Koop und Teilen gibt es im Produkt nicht. Sie werden nicht als Attrappe gebaut.
- Das Cards-Board zeigt UNO-Kartentypen. Wegen Entscheidung 1 wird nur die Tischszene übernommen.

Grenze, offen ausgesprochen: Fotorealismus wie in Konsolen-Großproduktionen ist auf Android mit dieser Engine nicht erreichbar. Ziel ist ein hochwertiger, stilisierter 3D-Look.

## 2a. Abnahmeschwelle für jedes Spiel (Heinz, 17.11.2026)

Ein Spiel gilt erst als fertig, wenn man es grafisch, spielerisch und in Sinn und Logik
guten Gewissens einem Haus wie Nintendo vorlegen **könnte**. Das wird nicht behauptet,
sondern je Spiel an acht Punkten geprüft. Jeder Punkt bekommt 1 bis 5 und einen Nachweis.
Fertig heißt: alle acht mindestens 4, Punkt 8 auf einem echten Gerät gemessen.

| Nr. | Punkt | Woran es geprüft wird |
|---|---|---|
| 1 | Sofort verständlich | Ein Kind versteht in 30 Sekunden ohne Lesen, was zu tun ist |
| 2 | Steuerung | Direkt, präzise, verzeiht kleine Fehler; nichts fühlt sich träge oder zufällig an |
| 3 | Spieltiefe | Echte Entscheidungen, sichtbares Besserwerden, Grund zum Wiederkommen |
| 4 | Inhalt | Genug unterschiedliche Strecken, Level oder Aufgaben; keine umgefärbten Kopien |
| 5 | Grafik und Animation | Einheitlicher Stil, Tiefe, Licht, lebendige Figuren, auf einen Blick lesbar |
| 6 | Feinschliff | Jede Aktion hat Rückmeldung in Bild und Ton; saubere Übergänge; nichts ruckt oder überlappt |
| 7 | Zuverlässigkeit | Pause, Wiederaufnahme, Speichern, Fehlerfälle; keine Sackgassen; Belohnung genau einmal |
| 8 | Leistung | Flüssig auf dem Zielgerät, gemessen (Bildzeiten, Speicher, Wärme) |

Zusätzlich für ein Lernprodukt: Der Lernbezug muss Sinn ergeben und darf den Spielfluss nicht zerstören.

### Ausgangslage am 17.11.2026 – nur Punkt 5, nur aus Renderbildern

Bewertet ist ausschließlich, was ich an echten Engine-Bildern gesehen habe (Software-Renderer,
kein Gerät). Steuerung, Spieltiefe, Ton und Leistung sind **nicht bewertet**, weil ich die Spiele
nicht gespielt und nicht auf einem Gerät gemessen habe.

| Bereich | Punkt 5 heute | Begründung |
|---|---|---|
| Lumo Kart, Rennen (Stand 18.11.: 3–4 für Kart, Figuren und Beläge; Streckenkulisse weiter 2–3) | 2–3 | Echtes 3D, brauchbare Karts und Fahrer. Fahrbahn kahl und grau, Licht flach (Vulkan fast schwarz), Streckenrand dünn, kaum Effekte, eine Tastatur-Hilfezeile im Bild |
| Lumo Kart, Hauptmenü | 3 | Aufbau nach Zielbild, lebender Lumo im Kart; Kacheln noch flach gezeichnet (Blender-Kit wird gerade eingebaut) |
| Memory, 3D-Tisch | 2 | Flaches Brett von oben, Lumo klein am Rand; das Flutter-Memory wirkt moderner |
| Jump & Run (Inseln) | 2 | Kleine schwebende Inseln, einfache Bäume, viel Text im Bild; kein langer Lauf |
| Bauwelt | 2–3 | Echtes Bauen in 3D, aber flaches Gelände und schlichte Blöcke |
| Profil (App) | 3–4 | Nach Zielbild neu gebaut; Belohnungs-Regal mangels echter Sammelstücke dünn |

Schatzsuche, Rhythmus, Puzzle, Cards-Tisch, 4 Gewinnt, Quiz, Lernszenen: nicht angesehen, nicht bewertet.

## 3. Navigation und App-Rahmen (Flutter)

| Bereich | Einstieg | Stand | Lücken | Status |
|---|---|---|---|---|
| Start / Onboarding | `lib/main.dart`, `features/onboarding/lumo_onboarding_holo_screen.dart`, `features/home/home_content.dart` | vorhanden | 12 Funktionen stecken in einer eingeklappten Kachel „Mehr mit Lumo entdecken" | OFFEN |
| Shell, 14 Sektionen | `app/app_shell.dart`, `widgets/shell/left_navigation.dart` | vorhanden | Telefonleiste zeigt 5, Rest unter „Mehr" | OFFEN |
| Profil / Belohnungen | `widgets/profile_screen.dart`, `features/rewards/` | vorhanden | Wallet ist ein globaler Schlüssel, nicht je Profil (siehe 5.3) | OFFEN |
| Einstellungen / Elternbereich | `features/settings/settings_content.dart` | vorhanden | Ohne PIN und ohne Rechenfrage direkt erreichbar – ausdrückliche Entscheidung von Heinz vom 3.10.2026 (`docs/PIN_FREI_2026-10-03.md`), kein Mangel. Kamera, Mikrofon und Online-KI sind in frischen Einstellungen aus. Datenschutz nur als Infokarte | ENTSCHIEDEN (PIN-frei); Datenschutzdarstellung OFFEN |
| Lehrerbereich | `features/teacher/*` | vorhanden | ungeprüft | NOT_RUN |

`flutter analyze` auf `d7930240`: 0 Fehler, 278 Hinweise (17.11., selbst ausgeführt). Volle `flutter test`-Suite: NOT_RUN.

## 4. Spiele

Start in der App über `features/games/games_content.dart` und `features/games/spielwelt/spielwelt_routes.dart`.
Godot-Spiele starten über `features/lumo3d/lumo3d_launcher.dart` (nur Android), Ziele in `scripts/app/scene_router.gd`.

### 4.1 Lumo Kart (Godot, `scenes/games/kart_island.tscn`, `scripts/games/kart_*.gd`)

- Stand: 3D, 13 Strecken, 5 Modi (Einzelrennen, Sternen-Cup, Zeitfahren, Training, Kristall-Arena), 14 Karts, Speichern/Fortsetzen, Rückgabe an die App mit einmaliger Belohnung.
- Ziel: Heinz' Punkt 3. Abnahme je Strecke: Orientierungspunkte, Sprung/Falle/Abkürzung, lesbare Fahrbahn, Landschaft mit Tiefe, Pausen- und Ergebnismenü vollständig bedienbar.

| Punkt | Status | Nachweis |
|---|---|---|
| Vollständiger Rennablauf (Menü, 16 Checkpoints, Speichern, Ergebnis, Rückgabe) | PASS (lokal) | `kart_complete_flow_regression.gd` grün nach `8eb2493`; vorher rot |
| Ergebnisdialog: alle 4 Aktionen ohne Scrollen erreichbar | PASS (lokal) | neu `kart_result_reachability_regression.gd`, 5 Displaygrößen; ohne Korrektur rot |
| Himmelsinseln-Sprung | PASS (lokal) | `kart_jump_regression.gd` grün nach `a5061c7`, Flug 0,75 s (vorher 0,48 s) |
| Fahrphysik, Wände, Drift | PASS (lokal) | `kart_physics_regression.gd`, `kart_regression.gd` |
| Rivalen-Flug, Stunt-Kontinuität, Sonnenhafen-Stunt | PASS (lokal) | drei Tests grün unter echtem Renderer (Xvfb, Software-GL); im reinen Headless-Modus verweigern sie den Start absichtlich |
| Items | PASS (lokal), 18.11. | Ein Item-System als alleinige Quelle (Godot `ddf5bc7`, Korrekturen `a3ddf7e`): Sternraketen in Haltern links/rechts mit Zündfeuer, Zielerfassung, Abschuss auf Knopfdruck; Schildkuppel; Falle; Glücksstern. `kart_gameplay_items_regression` 139 Prüfungen. Die Item-Anzeige im Rennen passt optisch noch nicht zum neuen HUD – in Arbeit. Am Gerät NICHT geprüft |
| Renn-Knöpfe und HUD | PASS (lokal), 18.11. | In Blender gerenderte Knöpfe (Gas, Bremse, Drift, Turbo, Item, Lenk-Stick), Renn-Leiste, Meldungstafel, Minikarte (Godot `4e632df`). `kart_hud_controls_regression` 978 Prüfungen, Layout-Tests mit Renderer grün. Offen: Linkshänder-Schalter (in Arbeit) |
| Fahr-Effekte (Leitplanke, Bremsen, Gas, Drift, Untergrund) | TEILWEISE, 18.11. | Erste Runde übernommen (Godot `8ec2910`): Funken und Schleifspur an der Planke, Bremsspur/-rauch, Turbo-Strahl mit Geschwindigkeitslinien, Drift-Funken in vier Farben, Staub je Belag, Landung, Motor-Klang in Schichten. `kart_drive_fx_regression` 120 Prüfungen, zwei Strecken komplett gefahren. Nach Sicht der Bilder noch zu schwach: Bremsspur (Leiter-Muster), Bremsrauch, Staub auf Sand/Wald, Turbo-Flamme; Fotofinish-Zeitlupe fehlt. Zweite Runde läuft. Klänge nicht angehört |
| Echter Lumo überall | PASS (lokal), 18.11. | Kart-Intro, Geist, Rivale Fuchs, Garage, Werkstatt (`kart_real_lumo_regression` 13); Schatzsuche, Rhythmus, Home, Lernszenen (`real_lumo_everywhere_regression` 344) |
| Streckenwahl (Godot-Issue #204) | BEHOBEN (lokal belegt), 18.11. – am Gerät NICHT geprüft | Ursache: angetipptes Streckenbild wurde nur hervorgehoben, „Rennen“ startete Sonnenhafen; die Strecken-Kachel startete den Cup auf Strecke 1. Godot `932b33f`. `kart_track_selection_regression`: vorher 18 Fehler, nachher 150 Prüfungen / 0 Fehler, 29 Starts, alle 13 Strecken, 71 echte Touch-Eingaben; 14 Bildbelege. Abnahme erst nach Heinz' Gerätetest |
| Items und Fahr-Effekte auf allen 13 Strecken (Godot-Issue #205) | PASS (lokal), 18.11. – am Gerät NICHT geprüft | `kart_items_all_courses_regression` 634 Prüfungen: je Strecke 6 Überraschungsboxen fair platziert, Einsammeln durch echtes Fahren, Sternraketen mit Zielerfassung und Treffer, Schild, Schonzeit ohne Trefferschleife, Rivalen-KI mit Warnung, Drift-Effekte, Belag je Strecke (Dschungelherz jetzt Waldboden statt Asphalt). Balance über ganze Rennen nicht bewertet |
| Menü/Strecken-Dramaturgie (Stream `lumo-kart/menu-strecken`) | PASS (lokal) | Merge `9f5e30b`; `kart_neon_home_regression` (38), `kart_neon_readability_regression` (1180), `kart_adventure_drama_regression` (874 Prüfungen) grün |
| Streckenbauteile (Stream `lumo-2040/kart`) | PASS (lokal) | Merge `a1587ff`; `kart_track_pieces_regression`, `kart_loop_seam_regression` grün |
| Karts und Sitzposition | PASS (lokal), 18.11. | Die drei Produktions-Karts in Blender neu gebaut (Sitzwanne, Frontverkleidung mit leuchtendem L, Frontflügel und Seitenkästen mit Leuchtbändern, Motorheck); Lumo – unverändertes Modell – sitzt im Kart statt auf der Haube, Hände am echten Lenkrad, Schweif hinter der Lehne. Radpunkte unverändert. Godot `ed7978f`: Reifen/Karosserie ohne Berührung bei vollem Lenkeinschlag (BVH), Exportprüfung 9/9, Sitz 225, Schweif 148, Fahrzeug 492 Prüfungen. **Offen:** die übrigen 11 Karts der Flotte nutzen noch die alte, im Code gebaute Karosserie mit hohem Sitz |
| Gegner | PASS (lokal), 18.11. | Eine veraltete Pfadregel wies alle fünf fertigen 3D-Figuren (Löwe, Eule, Hase, Eichhörnchen, Schildkröte) ab; Rennen zeigten Ersatzfiguren. Behoben in `ed7978f`; Figuren sitzen im Kart |
| Fahr-Animation Lumo | PASS (lokal), 18.11. | Kurvenlage (stärker im Drift), Blick in die Kurve, Ducken bei Tempo, Boost-Druck; Handkontakt-Tests grün (`2e36949`) |
| Zieleinlauf nach Zielbild | PASS (lokal), 18.11. | Platz-Abzeichen, Wertzeilen, Ergebniskamera, Jubel (`301ea2b`, Korrekturen `064eba9`); 11 Displaygrößen |
| Hauptmenü aus dem 3D-Kit | PASS (lokal), 17.11. | Merge `2b1fd30`; Draw-Calls je nach Fläche 333–371 (vorher 362–395) |
| Fahrbahn je Strecke | PASS (lokal), 17.11. | Sieben eigene Beläge (Waldweg, Steinplatten, Sand, Schnee/Eis, Basalt mit Lavarissen, Sternenglas, Laborfliesen), `5dfc8e9`; 114 Prüfungen |
| Dschungel-Licht, Zauberwald-Bäume | PASS (lokal), 17./18.11. | eigenes Tageslicht (`7b4a374`), Baumreihe an der Strecke (`4cf3032`) |
| Grafikqualität aus Rennkamera, alle 13 Strecken | TEILWEISE | 39 Bilder (13 Strecken × 3 Stellen) angesehen; Beläge und zwei Kulissen verbessert. Offen: Streckenrand der übrigen Welten, Licht Vulkan/Bergwelt, Effekte; auf dem Gerät nicht gemessen |
| Alle 13 Strecken im Hauptmenü | PASS (lokal), 18.11. nachmittags | Heinz: „es werden nur 4 Strecken darin enthalten“. Ursache: Die Strecken-Leiste des Hauptmenüs hatte vier fest eingetragene Strecken, die übrigen neun gab es nur in der Liste hinter „Strecken“. Jetzt jede Katalogstrecke mit eigenem, aus der echten Strecke gerendertem Bild; Pfeile auf dem großen Bild gehen durch alle 13 (Godot `808d167`). `kart_neon_home` 114, `kart_track_selection` 150 (29 Starts, 13 Strecken) grün; Menübild gesichtet. In APK 0.13.33+2045. Am Gerät NICHT geprüft |
| Detailschicht der Strecken | PASS (lokal), 18.11. nachmittags | Abrieb, Bremsspuren, Kleinteile, Publikum, Streckennamen-Banner, Zielbühne auf 13 Strecken in drei Profilen (Godot `fbd6a60`); 16 Tests grün. Aus der Rennkamera zurückhaltend (Holo City kaum sichtbar) – zweite Runde offen. In APK 0.13.32+2044 |
| CI im Spiele-Repository | IN ARBEIT, 18.11. | Seit den Merges vom Vormittag rot: Himmel-Objekt der neuen Kulisse hinterließ beim Beenden zwei Texturen (behoben, `cea266b`); Lade-Test endete bei laufender Menümusik (behoben, `5734d01`). Weitere Schritte dahinter erst mit dem nächsten CI-Lauf belegt |
| Framezeiten auf Zielgerät | NOT_RUN | kein Gerät |

| Gegnerstufe beim Start (Entscheidung 31, Teil 2) | PASS (lokal), 18.11. abends; Gerät NOT_RUN | Godot `67e44b1`: neues Kind startet auf „Entdecken“, gefahrene/eingestellte Stufe je Kind gespeichert (vorher bei jedem Start „Extrem“). `kart_start_level_regression` 17 Prüfungen PASS; Streckenwahl 150, Hauptmenü 114, Rennarten 125 PASS. Offen: Vergleichsmessung 0,96 ↔ 0,93, Eigentempo auf „Entdecken“ (Katalog 0,83) als Entscheidung für Heinz |
| Quizshow startet auf Android nicht (Gerätemeldung 18.11.) | Behoben, PASS (lokal); Gerät NOT_RUN | Ursache: Quizstudio prüfte Host-Methoden über `has_method` (auf Android für JNI-Singletons immer falsch) → blieb bei „Die Spielverbindung wird geprüft …“. Behoben in Godot `d5dcdf1`; Tests `table_android_host_capability_regression` 10 und Quiz-Fixture 195 Prüfungen PASS |
| Jump & Run startet auf Android nicht (Gerätemeldung 18.11.) | OFFEN | Ursache offen. Am Desktop startet `run` fehlerfrei. Diagnose-Abschnitt „native-starts“ im Emulator-Rundgang (`native_start_diagnostics.py`) startet alle Spiele und sichert das Gerätelog; erster CI-Lauf steht aus |

### 4.2 Kartenspiele

- Bestand: `lib/features/games/lumo_cards/` (Regeln in Dart), 3D-Tisch `scripts/games/cards/cards_table.gd` (zeigt die Dart-Partie an, keine eigenen Regeln).
- Befund: 112 Karten, 4 Farben, Aussetzen/+2/Richtungswechsel/Farbwahl/+4, 7 Startkarten, „LUMO!"-Ruf bei ≤ 2 Karten. Eigen ist nur die Denkpause-Karte. Nur 2 Spieler.
- Weiteres Kartenspiel: „Sternenpfad" (`features/games/star_trail/`), kooperativ, eigene Regeln, bleibt.
- Ziel: Heinz' Punkte 1 und 2. Konzept für 2–3 eigene Spiele steht noch aus und braucht Heinz' Zustimmung, bevor UNO entfernt wird (laufende Partien, Cup-Fortschritt `lumo.cards.cup.v1.*`).

- Zielbild: `board_cards.jpg` (runder Steintisch, Tierfreunde rundherum, eigene Hand unten).

| Punkt | Status |
|---|---|
| UNO-Regeln entfernen | Godot: ERLEDIGT (18.11., Merge `e80a4cb`). App: UNO-Dart-Spiel und nativer Kartendienst werden entfernt – in Arbeit |
| Drei eigene Spiele (Sternenstich, Sternenleiter, Lumo-Quartett; 2–4 Spieler, KI in drei Stärken ohne Blick in fremde Karten) | Godot: GETESTET (`cards_rules_regression` 212 968 Prüfungen, `cards_table_regression` 595, `cards_safe_area_regression` 2 176 auf 9 Bildschirmformen). App-Anschluss in Arbeit; am Gerät NICHT geprüft |
| 3D-Tisch mit sitzenden Figuren und Kartenwurf | Godot: ERLEDIGT, 32 Engine-Bilder gesichtet. Offen: Lumo hält am Tisch noch die Kart-Sitzhaltung statt Karten; im Hochformat ist er am Rand angeschnitten |
| Spielzimmer (Raum, Möbel, Texturen) | Godot: ZUSAMMENGEFÜHRT 18.11. (`fbac669`): Bücherregale, Eichentisch mit Filz, Pflanzen, Punktetafel; `cards_table` 591, `cards_safe_area` 2176, `cards_rules` 212 968. In APK 0.13.31+2043. Offen: 3D-Memory-Tisch (Lumo im Querformat angeschnitten), 4 Gewinnt und Quiz nicht gesichtet; Titelbild der Spielewelt zeigt jetzt den echten Kartentisch |
| Namensschilder am Tisch | Godot: ERLEDIGT 18.11. nachmittags (`6fd3e4c`, `aef4dca`): stehen neben dem Kopf, wenn darüber kein Platz ist, und weichen einander aus; `cards_safe_area` 2176/0. In APK 0.13.32+2044. Nicht übernommen: Umbau des 3D-Memory-Tischs (Test mit Renderer rot) |

### 4.3 Memory

- Flutter `features/games/memory/`, 3D-Tisch `scripts/games/memory/memory_table.gd`.
- **Zwei Fassungen nebeneinander.** Das Flutter-Memory (nachtblaue Welt, großer Lumo) ist das, was Heinz kennt, und der Maßstab. Der Godot-3D-Tisch ist eine zweite, schlichtere Fassung (flaches Brett von oben, Lumo klein am Rand) und derzeit nur optional.
- Integriert am 17.11.: Godot-Stream `lumo-2040/memory-godot` (Tisch-Look mit Qualitätsstufen), `memory_table_regression` grün mit CI-Parametern (7.020 Prüfungen, 8 Renderbilder).
- App: Fehler-Fix `b93aef5b` aus `lumo-2040/memory-20261117` übernommen; `memory_result_frame_test.dart` wieder grün.
- **Bewusst nicht übernommen:** `5a79c14c` „align Flutter board … with the 3D table". Er gleicht das Flutter-Memory optisch an den schlichteren 3D-Tisch an. Heinz hat am 17.11. gesagt, das bekannte Memory sei moderner – Übernahme nur nach seiner Sichtprüfung.
- Ziel: ein Memory, in echtem 3D mit dem Flutter-Look als Untergrenze. Status OFFEN.

### 4.4 Bauwelt und Dorf

- Godot `scripts/creative/build_world.gd` (Bauen), `build_settlement_world.gd` (Dorfwirtschaft).
- Integriert am 17.11.: Stream `lumo-2040/bauwelt` (Kampagnenkarte, Dorfverteidigung, HUD). 9 Bauwelt-/Dorf-Tests grün (lokal), u. a. `build_defense_regression` (162), `build_campaign_map_regression` (54), `build_village_economy_regression` (339 Prüfungen).
- Befund App: „Dorfwirtschaft" (`settlement`) steht nicht in der Belohnungsliste von `core/embedded_game_service.dart` – Ergebnisse werden in Flutter nicht gebucht.
- Ziel: Heinz' Punkte 5 und 11. Gelände mit Höhen (Hügel und Berge unbebaubar), große Karte, Kampagne, Freibau, sichtbar bauende KI-Städte. Heute ist das Gelände flach. Status OFFEN.
- **18.11.2026, mittags:** Dorfwelt mit Höhenkarten-Gelände, Fluss, Fachwerkhäusern, Blattbüschel-Bäumen, Gründerlager, Kapitel 1/12 und neuem HUD zusammengeführt (Godot `cbeb7c0`; 17 Tests grün, 14 Bilder gesichtet). In APK 0.13.31+2043. Die Dorfwelt meldet der App weiterhin keine Ergebnisse (kein `reward`-Aufruf). Offen laut Heinz (Entscheidung 24): KI-Gegner, Angriffe mit Sinn, Tutorial, Langzeit-Kampagne; Bauwelt-Grafik als eigenes Paket danach.
- **18.11.2026, nachmittags:** Strategie Teil 1 und 2 zusammengeführt (Godot `e36799c`): Lumos Einführung in neun Schritten, die ins laufende Spiel übergeht (überspringbar, später je Thema abrufbar), und KI-Nachbardörfer, die nach denselben Regeln sichtbar mit aufbauen. 12 Tests grün (u. a. `build_village_tutorial` 49, `build_village_neighbors` 31); frische Bilder gesichtet. In APK 0.13.32+2044. Offen: Angriffe mit Sinn (Teil 3), Langzeit-Kampagne (Teil 4), Sterne ausgeben/einbringen über die App (`settlement` wird in Flutter weiter nicht gebucht).
- **18.11.2026, nachmittags (2):** Strategie Teil 3 zusammengeführt (Godot `4dc2ad0`) – Heinz: „Sie muss ihr Dorf beschützen und dafür Leute ausbilden … ein richtiges Strategiespiel“. Das Kind bildet eigene Wachen aus (Helm und Schild), baut Mauer in drei Stufen, Wachtürme, Tor/Zugbrücke, Graben und Netzfallen, ruft Bündnispartner, verhandelt, schickt Kundschafter. Drei Gegner mit Grund und drei Tagen Vorwarnung (Räuber, verärgerter Nachbar, kleiner Drache); niemand wird verletzt, Gebäude werden beschädigt und repariert. `build_village_raids` 137 und elf weitere Dorf-Tests grün; zwei Bilder gesichtet. In APK 0.13.34+2046. Offen: Mauern frei setzen (heute ein Ring in Stufen), Langzeit-Kampagne (Teil 4), Sterne über die App. Am Gerät NICHT geprüft.

### 4.5 Schatzsuche, Rhythmus, Puzzle

- Godot `scripts/creative/treasure_world.gd`, `rhythm_world.gd`, `puzzle_world.gd`.
- Integriert am 17.11.: Stream `lumo-2040/kreativ` (Schatzsuche mit Karte/Kompass, Rhythmus-UI). 4 Schatzsuche- und 3 Rhythmus-Tests grün (lokal). Puzzle: NOT_RUN.
- **18.11.2026, mittags:** Schatzinsel, Konzertbühne, Puzzle-Atelier und Spielewelt mit eigenen Modellen, Texturen und Shadern zusammengeführt (Godot `5a3747d`; 14 Tests grün). In APK 0.13.30+2042. Offen: Puzzle-Teile ohne Fase/Karton-Kante (zweite Runde des Helfers steht aus).

### 4.6 Jump‑and‑Run

- 3D: `scripts/games/jump_islands.gd` („Wolkeninseln", in der App nur unter „Zusätzliche Spielmodi").
- 2D: `lib/features/games/flame/lumo_jump_game.dart` („Lumos Jump Adventure 2D"), bucht Belohnung ohne Ergebnis-ID.
- Ziel: Heinz' Punkte 4 und 12. Das 2D-Spiel entspricht nicht dem Ziel; das 3D-Spiel ist ein kurzer Insel-Parcours, kein langer Lauf. Geplant: Lauf-Modus auf den vorhandenen langen Kart-Welten (Streckenbau, Landschaft und Lumo-Laufanimation sind vorhanden). Status OFFEN.

- **18.11.2026:** „Lumo Lauf" (Godot `scripts/games/run/`, Route `run`) mit Level „Dschungelherz" zusammengeführt – siehe Stand zu Entscheidung 15. Zauberwald und Sonnenhafen laufen noch auf den Kart-Strecken. Am Gerät NICHT geprüft.
- **18.11.2026, mittags:** neue Dschungelkulisse aus eigenen Blender-Modellen zusammengeführt (Godot `abbc3f3`; `lumo_run_regression` 496 Prüfungen; 24 Bilder aus dem gespielten Lauf gesichtet). In APK 0.13.31+2043. Offen laut Heinz (Entscheidung 25): schneller, flüssiger, mehr Action – Maßstab Sonic.
- **18.11.2026, nachmittags:** Tempo (Godot `40d5f08`): der Dschungelpfad läuft 1,3-fach, dazu Sprint aus freiem Lauf, zwei Tempo-Felder, großzügigere Sprungfenster; Lumos Laufstil mit weitem Schritt und Kniehub (`9636a3c`). Gemessen mit dem automatischen Spieler (30 Läufe): Durchlauf im Schnitt 113 s statt rund 180 s; am Bildschirm Grundtempo 11,1 m/s (vorher 8,5), Sprint 15,0 m/s. `lumo_run_regression` 496, `lumo_run_flow_regression` 13, `jump_nextgen` 84 grün. Ein Laufzeitfehler der Kulisse (ERROR-Zeile je Bild, auch in 0.13.31) ist behoben (`94ca0af`). In APK 0.13.32+2044. Am Gerät NICHT geprüft (Eingabegefühl, Bildrate).

### 4.7 Weitere Spiele

| Spiel | Ort | Status |
|---|---|---|
| 4 Gewinnt | Flutter `connect_four/`, 3D `connect_four_table.gd` | NOT_RUN |
| Quiz „Wer wird Lumo-Meister?" | Flutter `features/quiz/`, 3D `quiz_studio.gd` | NOT_RUN |
| Würfel-Wettlauf | Flutter `dice_race/` | NOT_RUN; bucht Sterne und XP in zwei Schritten ohne ID |
| Sternenpfad | Flutter `star_trail/` | NOT_RUN; Doppelbuchung nur bildschirmlokal verhindert |
| 50-Level-Karte (5 Minispiele) | Flutter `mini_games/` | NOT_RUN |
| Sterne sammeln | Godot `star_collect_game.gd` | NOT_RUN |

### 4.8 Klang (alle Spiele)

- **18.11.2026:** Klangwelt zusammengeführt (Godot `b594543`): selbst komponierte Musik, Atmosphären und Ereignistöne, `AudioManager` mit echten Samples, `GameSoundscape`. `game_soundscape_regression` 308 Prüfungen. In APK 0.13.31+2043. **Nicht angehört** – nur rechnerisch geprüft (Pegel, Schleifen); Urteil nach Gehör steht aus.

## 5. Lernen, Tutor, Daten

**Stand 18.11.:** Lernpaket L1 „Ehrlich üben“ ist zusammengeführt (`69775b5e`): Rückmeldung passend zum Fehler, nach dem zweiten Fehler gemeinsamer Lösungsweg in Schritten, danach eine ähnliche Aufgabe zum Allein-Lösen, „allein gelöst“ nur beim ersten Versuch ohne Hilfe, Können nur mit Beleg („Am Anfang“, „In Übung“, „Sicher“ erst nach genug allein gelösten Aufgaben an zwei Tagen), kein Sternabzug, lange Module in Runden mit Wiedereinstieg. Geprüft: Analyse 0 Fehler, ganze Suite auf dem L1-Zweig (zwei Alt-Tests an den neuen Vertrag angepasst), 352 Lern-Tests nach dem Zusammenführen. Nicht geprüft: mit echten Kindern, auf dem Gerät. Fachkorrekturen Mathematik und Deutsch/Sachunterricht/Englisch laufen.

### 5.1 Lerninhalte (Flutter)

Katalog in `core/school_exercise_generator.dart` mit Vorlagen in `math_task_templates.dart`, `german_task_templates.dart`, Sachunterricht und Englisch. Gezählte Generator-Einheiten je Klasse (Code-Inventur 17.11., per Suche gezählt, nicht fachlich geprüft):

| Fach | Kl. 1 | Kl. 2 | Kl. 3 | Kl. 4 |
|---|---|---|---|---|
| Mathematik | 13 | 14 | 13 | 16 |
| Deutsch | 8 | 8 | 8 | 8 |
| Sachunterricht | 9 | 9 | 11 | 6 |
| Englisch | 7 | 4 | 5 | 5 |
| Logik | 2 | 1 | 1 | 1 |

- Dünn: Logik ab Kl. 2, Englisch Kl. 2–4, Sachunterricht Kl. 4. Musik, Kunst, Technik, Sport haben keine Aufgaben.
- Fachliche Durchsicht (Heinz' Punkt 6): **durchgeführt am 17.11. am Code, nicht am Gerät**; Berichte in `docs/fachpruefung/`. Mathematik/Logik: 49 800 erzeugte Aufgaben, 43 800 unabhängig nachgerechnet, 0 falsche Lösungen; 65 Befunde im Umfeld der Aufgaben (12 schwer: u. a. richtige Antwort immer an zweitkleinster Stelle, Bilder verraten die Lösung, falsche Rechentricks bei Brüchen/Dezimalzahlen). Deutsch/Sachunterricht/Englisch: 84 Befunde (6 schwer: u. a. Reim-Ablenker, die selbst reimen; Endlaut „Hund → T“; Geschichten ohne Umlaute). Korrektur läuft (Pakete L4a Mathematik, L4b Deutsch/Sach/Englisch). Kein Abgleich mit dem amtlichen Lehrplantext; es wird keine Lehrplanabdeckung behauptet.
- **Korrekturen eingearbeitet am 18.11.2026** (Merges `d8362dc8` Mathematik/Logik und Deutsch/Sachunterricht/Englisch, Stand `b4730556`): alle 12 schweren Mathe-Befunde und alle 6 schweren Deutsch/Sach-Befunde behoben, die mittleren und leichten großteils. Neu u. a.: 96 Schlussfolgerungsfragen zum Lesen, Wortarten im Satz (Kl. 3), Schreiben steigt mit der Klasse, 72 Sachunterricht-Fragen Kl. 2, Englisch in Gegenrichtung ab Kl. 3, Rechengeschichten Kl. 4 bis zur Million, österreichische Wörter (Erdapfel, Zwetschke). Geprüft: `flutter analyze` 0 Fehler; gesamte Testsuite auf dem zusammengeführten Stand einmal gelaufen, ein Fehlschlag (8 oder 9 Äpfel schoben auf 360-dp-Handys die Antworten unter die Navigation) – behoben und mit eigenem Test abgesichert; danach nur die betroffenen Testdateien erneut ausgeführt, kein zweiter Gesamtlauf. Am Gerät NICHT geprüft.
- **Offen aus der Fachprüfung:** Stufen innerhalb einer Einheit (Einmaleins-Reihen nacheinander), Zahlenmauer und Figuren als Bild, einheitliches Mal-/Minuszeichen, drei Fragen je Lesetext, Englisch mit Hör- und Bildaufgaben, Beispielsätze zu den Englisch-Wörtern, Satzzeichen-Frage verrät die Satzart.
- Lücken laut Prüfung: Sachunterricht Kl. 2 (fünf Einheiten mit nur 1–5 eigenen Fragen), Englisch nur „Wort lesen → Bedeutung antippen“, Musik/Kunst/Technik/Sport ohne überprüfbare Aufgaben (je 8 offene Aktivitätskarten).
- 3D-Lernszene: Godot `scripts/learning/learning_world.gd`. Nachhilfe-Szene (Stream `lumo-2040/tutor-godot`, WIP ohne Test): Quelltext integriert (Merge `55c0135`), nur über einen Lern-Aufruf mit `kind: tutor` erreichbar; der Einstieg in der App bleibt verborgen. Status: NOT_RUN.

### 5.2 Lumo als Tutor, Sprache, Kamera

| Teil | Dateien | Stand |
|---|---|---|
| Gespräch lokal | `core/lumo_conversation_controller.dart`, `lumo_brain.dart` | lokal lauffähig; KI-Proxy nur bei `aiProxyEnabled` |
| Sprachausgabe | `core/lumo_voice.dart`, Offline-Stimme nach Elternfreigabe | Cloud-Stimme im Code vorhanden, aber fest abgeschaltet |
| Spracherkennung | `core/lumo_speech_listener.dart` (auf dem Gerät) | Mikrofon standardmäßig aus |
| Kamera / OCR | `widgets/scan_screen.dart`, `features/photo_lesson/` | standardmäßig aus, Auswertung lokal |
| Bilder vom KI-Lehrer | `core/lumo_image_generator.dart` | **sendet bei aktivem KI-Modus an einen Drittanbieter (pollinations.ai)** – gehört vor Freigabe in den Elternbereich erklärt oder entfernt |

Abnahme laut Auftrag (Begrüßung → Aufgabe → falsche Antwort → Hinweis → Unterbrechung → andere Erklärung → Fortschritt): NOT_RUN.

### 5.3 Fortschritt und Belohnungen

- Wallet `core/reward_wallet_repository.dart`, Schlüssel `lumo_reward_wallet_v1`, serialisierte Schreibfolge, Ergebnis-IDs gegen Doppelbuchung bei Godot-Spielen, Memory, Cards, Quiz.
- Lücken: Wallet global statt je Kind; Lernaufgaben, 2D-Jump, Würfel, Sternenpfad, LIVE, Geschichte, Schreiben und IQ buchen ohne Ergebnis-ID.

## 6. Integration (Abschnitt 5 des Auftrags)

Grundlage ist Groks Inventur `docs/handover/BRANCH-INVENTUR-20261117.md` (784 Branches: 321 enthalten, 25 gemergt, 300 nicht gemergt mit Grund, 137 ersetzt). Darauf aufbauend:

| Entwicklung | Einordnung | Stand |
|---|---|---|
| Godot `lumo-2040/memory-godot` @ `e10b74f` | jetzt integriert | Merge `90f0c4e` |
| Godot `lumo-2040/kreativ` @ `27265b1` | jetzt integriert | Merge `f6a2b44` |
| Godot `lumo-2040/bauwelt` @ `e47f05a` | jetzt integriert | Merge `6005586` |
| Godot `lumo-2040/tutor-godot` @ `24bcb48` | jetzt integriert, bewusst experimentell (WIP ohne Test, in der App nicht erreichbar) | Merge `55c0135` |
| Godot `lumo-2040/kart` @ `f957466` | jetzt integriert | Merge `a1587ff` |
| Godot `lumo-kart/menu-strecken` @ `b5956d3` | jetzt integriert; 2 Konflikte gelöst (`kart_world.gd` beide Seiten, `kart_neon_layout.gd` neue Fassung) | Merge `9f5e30b` |
| Godot `lumo-kart/gameplay-items` @ `17b63b4` | blockiert: zweites Item-System neben dem vorhandenen, siehe 4.1 | Merge abgebrochen, nichts übernommen |
| App `lumo-2040/memory` @ `e5dbe5ca` | teilweise übernommen: nur Fix `b93aef5b`, Optik-Commit `5a79c14c` nicht | Cherry-Pick auf dem Arbeitsbranch |
| App `lumo-2040/tutor` @ `58549eae` | WIP, Einstieg verborgen | offen |
| App `delivery/lumo-2037-memory-werkstatt` @ `e2a8e9fe` | 11 Commits nicht im Nullpunkt | offen, prüfen |
| Godot-Pin in `config/godot-source.json` | umgestellt auf `a363de2` (Importabsturz behoben; Godot-CI auf `2e1aed6` vollständig grün, auf `a363de2` noch offen) | Commit `b39d8ec9` |

Die unveränderten Testberichte der Streams liegen im Godot-Repo unter `docs/integration-2/`.

## 7. Technik und Abnahme

| Punkt | Status |
|---|---|
| Godot-Import ohne Fehler | PASS (lokal), 17.11. |
| Vollständige Godot-Testsuite (ca. 350 Skripte) | NOT_RUN |
| `flutter analyze` | PASS (lokal), 0 Fehler |
| `flutter test` vollständig | NOT_RUN |
| Gemeinsame APK (Flutter + Godot) | GEBAUT und signiert (CI, nicht auf einem Gerät geprüft): Lauf 4 von `lumo-test-apk.yml` (44207725478) auf `287bc29c`, Version 0.13.27+2039, Godot `2b1fd30`, nur ARM64, rund 539 MB. Download als Entwurf-Release „Lumo Test-APK 0.13.27+2039 (Entwurf)“ (GitHub verweigert dem Lauf-Token eine öffentliche Vorabversion, HTTP 403) oder als Actions-Artefakt `LUMO-TEST-APK-44207725478`. Vorher: Läufe 1–2 Godot-Importabsturz (Ursache behoben in Godot `a363de2`), Lauf 3 gebaut (0.13.26+2038, 588 MB Universal). Offen: Größe (Spielpaket allein 282 MB), Installation und Bedienung auf dem Gerät |
| Größe des Spielpakets | 281,8 MB → 117,9 MB (Godot `a73fa33`): Tunnel-Texturen lagen je Strecke bis zu 14-fach eingebettet und unkomprimiert im Paket; jetzt je Strecke einmal. Gleichheit belegt (Fingerabdruck aller 385 Bauteile identisch, Tunnelbilder praktisch pixelgleich). Wirkt ab der nächsten APK |
| App-Skripttests (`scripts/tests`, 1006 Tests) | PASS in CI auf `0315c801` (`full-app-script-regression`); lokal 1005 PASS, 1 nur mit Android-SDK lauffähig |
| Android-Emulator, echtes Gerät, Fold | NOT_RUN |
| Framezeiten, Speicher, Akku | NOT_RUN |

Keine Signierung, keine Veröffentlichung, kein Merge nach `main` ohne Heinz.
