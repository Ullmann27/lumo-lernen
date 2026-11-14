# Kart: Prozessende-Meldungen — unabhängiger Lesebefund

Die drei Ressourcen-ERRORs und vier ObjectDB-Warnungen des acf51-Gameplayjobs bleiben **ungeklärt**. Die vorhandenen Funktionsprüfungen bestanden; daraus folgt keine fehlerfreie Ressourcenfreigabe. Es wurde kein zusätzlicher konkreter Gameplayfehler und kein absichtlich offen gelassenes Testobjekt belegt. Keine Tests oder Produktänderungen wurden ausgeführt.

| Prozess im Original-acf51-Log | Originalzeilen | Ressourcenmeldung | Unmittelbarer Prüfabschluss |
|---|---:|---:|---|
| KartAI |3817–3821|4|PASS, dann ObjectDB/ResourceCache|
| KartRacecraft |3905–3910|4|reale Kegelumfahrung und PASS, dann ObjectDB/ResourceCache|
| KartFullField |4231–4235|2|kontinuierlicher Zwei-Runden-Lauf PASS, dann ObjectDB/ResourceCache|
| HarborRaceHook |4408–4410|keine Ressourcenanzahl|Physik/Pause/Resume/Finish PASS, dann ObjectDB|

Der effektive Exit 0 folgt aus der unverdeckten `set -euo pipefail`-Pipeline, dem folgenden Prüflauf und erfolgreicher Originaljobmetadaten; im Log steht kein eigener numerischer Exitdatensatz. Die bestehenden Harnessfilter tolerieren ausdrücklich die Ressourcenmeldung. Das erklärt die grüne CI, nicht ihre Harmlosigkeit.

## Quellen und Einordnung

14 gelesene Test-/Produkt-/Harnessdateien sind anhand ihrer veröffentlichten Gitblobs und Modi zwischen Native 803e, acf51 und 785413 identisch. Alle vier Tests rufen `game.queue_free()` auf. Racecraft, FullField und Harbor warten danach einen Prozessframe; AI beendet unmittelbar. Die offizielle Godot 4.6.3-Quelle zeigt aber, dass `SceneTree::finalize()` die Löschwarteschlange selbst leert. Ein ausgelassenes Free ist aus diesem Unterschied allein nicht ableitbar.

Die Kart-Audioquellen stoppen die Player und lösen Streamreferenzen beim Szenenaustritt. Ein bewusst langlebiger Skycache existiert, aber die unbenannten 4/4/2 ResourceCache-Einträge lassen sich ihm nicht zuordnen. Die Originale enthalten keine `--verbose`-Ressourcenpfade oder Instanzklassen.

Im früheren 803e-Originalbeleg ist AI ebenfalls mit 4 Ressourcen betroffen. Racecraft/FullField enthalten dort keine entsprechende Meldung; Harbor meldet in seiner ersten Ausführung 4 Ressourcen und in der zweiten keine. Die unterschiedliche Verteilung bei identischen relevanten Quellen ist kein Nachweis, dass die Warnung harmlos wäre.

## Enges empfohlenes Gate

Nur die vier bestehenden Prüfläufe am finalen SHA mit `--verbose` und unveränderten Deadlines ausführen, vollständige Ressourcenpfade/Klassen sowie Exitcodes erhalten und danach den konkreten Eigentümer beim Szenenaustritt prüfen. Keine globale Warnungsunterdrückung, keine breite neue Matrix. **Dieses Gate wurde hier weder hinzugefügt noch ausgeführt.**

`review.json` bindet Originalmetadaten, Logzeilen, SHA256/Gitblobs, den früheren 803e-Artefaktbeleg und die offiziellen Engineauszüge. Die laufende 785413-CI und ihre noch ausstehenden Originalbilder werden durch diese Diagnose nicht vorweggenommen.
