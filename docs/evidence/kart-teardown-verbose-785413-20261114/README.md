# Gezielte Kart-Teardown-Diagnose auf Native 785413

**Vier unveränderte lokale Probes bestanden. Die CI-Ressourcen- und ObjectDB-Meldungen wurden nicht reproduziert und bleiben offen.** Kein Produktfix und keine zusätzliche Testserie.

Quelle: [`785413d395292a243eaa0a0748671eb15d3f80ff`](https://github.com/Ullmann27/lumo-godot/commit/785413d395292a243eaa0a0748671eb15d3f80ff), Tree `635cf3d68631ed62ba3b3ce6f2c1fc5448768787`. Die ursprünglichen Prozessmetadaten nennen 14.11.2026, 07:40:58 bis 07:41:45 UTC. Sie enthalten vollständige Befehle und Exitcodes.

| Unveränderte Probe | Modus | Godot-Budget | Dauer | Ergebnis |
|---|---|---:|---:|---|
| Kart AI | Headless | 180 s | 4,111 s | Exit 0, Original-PASS |
| Kart Racecraft | Headless, Dummy-Audio | 240 s | 3,141 s | Exit 0, Original-PASS |
| Kart Full Field | Headless, Dummy-Audio | 240 s | 32,731 s | Exit 0, Original-PASS |
| Harbor Race Hook | Isolierter Xorg106, Software/Compatibility, Dummy-Audio | 240 s | 6,418 s einschließlich Launcher | Exit 0, Original-PASS |

Der Harbor-Launcher hatte ein äußeres 252-Sekunden-Budget für Xorg-Start und -Aufräumen; das Godot-Budget blieb 240 Sekunden. Keine Ausführung erreichte ihre Frist. Der notwendige private Editorimport dauerte 4,975 Sekunden bei Budget 120 Sekunden und Exit 0. Er ist Vorbereitung, kein weiterer Gameplaytest.

## Quellenbindung

Die zuvor beendete private Laufzeit `/tmp/lumo-attention-8be3-20261114/runtime` war ein **Teilquellgraph**, kein vollständiger Checkout. Alle 1.186 versionierten Dateien aus `scripts/`, `scenes/`, `assets/`, Projekt und Icon wurden vor Import, nach Import, nach jeder Probe und am Ende gegen die Gitblobs von 785413 geprüft. Alle sieben ursprünglichen Dateilisten sind identisch. Fünf nötige Synchronisierungen betrafen ausschließlich diese private Kopie; ihre Vorher-/Nachherhashes stehen in `private-runtime-scope.json`. Die eingefrorenen Produktquellen blieben unverändert.

457 Import-Quell-MD5-Stempel stimmten mit den tatsächlichen Assetbytes überein; der normale private Import lief anschließend erfolgreich. Die vollständigen Quellbindungen vor und nach den Läufen liegen bei. Die fünf Zwischenaufzeichnungen sind gehasht und lokal unverändert erhalten. `loaded-resources.json` nennt die tatsächlich protokollierten Ressourcenpfade und bindet deren versionierte Quellen zusätzlich. Es werden keine Caches oder Assetkopien hochgeladen.

**Umgebungsgrenze:** Während der anschließenden Berichtserstellung brach der Ausführungstransport ab. Nach seiner Wiederherstellung fehlte der private `/tmp`-Laufzeitbaum. Die originalen Rohlogs und alle sieben Quellenaufzeichnungen im Workspace blieben erhalten und wurden erneut gehasht. Es gab keine Rekonstruktion und keine erneute Probe. Zusätzliche nachträgliche Hashes der generierten Cachebytes sind deshalb nicht verfügbar und werden nicht behauptet.

## Befund und Grenzen

Die historischen acf51-CI-Prozesse hatten 4/4/2 noch verwendete Ressourcen bei AI/Racecraft/Full Field sowie vier ObjectDB-Warnungen einschließlich Harbor. Die neuen lokalen Verboseprotokolle enthalten diese Meldungen nicht. Somit stehen weiterhin **keine identifizierten betroffenen Klassen, Ressourcenpfade oder Eigentümer** zur Verfügung. Ein nicht reproduzierter Befund ist weder behoben noch als harmlos nachgewiesen. Die [frühere Analyse](../kart-teardown-readonly-acf51-785413-20261114/review.json) bleibt unverändert; auch die separat gesicherten neuen CI-Meldungen auf 785413 werden durch diese lokalen Erfolge nicht aufgehoben.

Harbor meldet fehlende V-Sync-Umschaltung sowie nicht verfügbare Bildschirm-Antialiasing- und volumetrische Nebelfunktionen in Compatibility; hinzu kommt eine Cursor-Thememeldung. Alle vier Verboseprotokolle enthalten je vier `misc2`-Controller-Mappingmeldungen. Genaue Zeilen und Kontext stehen in `review.json`. Die Protokolle werden nicht pauschal als warnungsfrei bezeichnet.

Godot 4.6.3 lief mit eigenen frischen QA-Daten. Das ist kein Android-, Audio-Hardware-, Geräte-FPS- oder Dauerspeichertest. Cache und Umgebung unterscheiden sich vom ursprünglichen GitHub-Lauf; daraus wird keine Ursache abgeleitet. Die funktionalen Gates bleiben unverändert. Eine Zuordnung oder Teardown-Korrektur benötigt die tatsächlichen Verbose-Objekt-/Ressourcenzeilen des wieder betroffenen CI-Aufrufs. Es wird keine weitere lokale Testserie begonnen.

## Belegumfang

Die vier vollständigen Rohlogs, ursprünglichen Ausführungsmetadaten sowie Import- und Rendererprotokolle sind unverändert aufgenommen. `run_four_probes.py` dokumentiert den ausgeführten privaten Aufruf und gehört ausschließlich zu diesem Belegpfad; es ist kein neuer Produkt- oder CI-Test. Das große anfängliche Inventar bleibt lokal erhalten und ist im Setupbericht gehasht. Der neue Upload umfasst ausschließlich explizite Dokumentationsziele.
