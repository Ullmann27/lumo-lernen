# LUMO Vollintegration · 22. November 2026

## Auftrag und abgegrenzter Stand

Heinz beauftragt die vollständige Zusammenführung vorhandener LUMO-Entwicklungen mit drei zusätzlichen Agenten und anschließend eine neue installierbare APK. Ausgangsstände sind Flutter `52c2c57016813566bc258df35ccba1d14e9009b2` und Godot `25fc4ff1f43c0adeb2c56b67ad4a9611922aac8a`. Beide isolierten Integrationszweige heißen `integration/lumo-complete-20261122`. Main bleibt erhalten.

Die Inventur erfasst 797 Flutter- und 301 Godot-Zweige mit ihren exakten HEADs. Sie kombiniert vollständige Git-Abstammung mit der bestehenden inhaltlichen Familieninventur und prüft neue oder zuvor nicht zugeordnete Reste separat. Historische Belege und überholte, gegenseitig ausschließende Implementierungen verbleiben in ihren ursprünglichen Zweigen. Ihr offener PR-Status bedeutet nicht, dass die jeweilige Funktion in der aktuellen App fehlt.

- [Flutter-Inventur](flutter-branch-inventory.json)
- Godot-Inventur im gleichen Verzeichnis des Spielrepositories: `godot-branch-inventory.json`.
- Die beiden zusätzlichen Flutter-Zweige `agent/sprache` und `agent/tutor3d` enthalten keine fehlenden Nicht-Merge-Patches gegenüber dem Ausgangsstand.
- Die zusätzlichen sechs historischen Flutter-Reste wurden einzeln abgeglichen: Flame-Teststeuerung, Duck-/Roll-Physik, Antwortmischung und Aufgaben-Deduplizierung sind bereits vorhanden; die übrigen enthalten nur historische Dokumentation beziehungsweise einen alten Workflow.

## Neu zusammengeführte Anschlüsse

1. **Lokale englische Aussprache in der nativen Lernszene:** Die vorhandene Implementierung aus `3a5b2241b7a329a8b36ee655bceedd874ae50268` wurde auf aktuelle Sprach-Lifecycle-, Fehler- und Tempologik angepasst. Das englische Wort bleibt an die echte Lernaufgabe und den aktuellen Katalog mit 20 Wörtern gebunden. Deutsche Erklärung und lokale F2-Stimme bleiben erhalten.
2. **Aufgabenbezogene Dialogformulierungen:** Fehlende Formulierungen aus der älteren Chat4-Fassung werden in die vorhandene Dialogsteuerung übernommen. Dazu gehören „nicht so schnell“, „anders zeigen“ und „Schritt zwei“. Es wird keine zweite konkurrierende Dialogimplementierung eingeführt.
3. **Borin und Yuki:** Fertige Dachs-/Katze-Modelle und Menübilder sind regulär an Fahrerauswahl, Speicherung und Rennstart angeschlossen; bestehende Fahrer, Fahrzeuge und Fortschritte bleiben erhalten. 79 Laufzeitprüfungen bestätigen Auswahl, Rennstart, sichtbares Produktionsmodell und Wiederaufnahme. Ein dabei entdeckter Zugriff auf eine bereits freigegebene Vorschaufigur wurde behoben.
4. **Lumo-Lauf-Baublocker:** Die unveränderte Anforderung von 8 Metern misst die tatsächliche Flugstrecke statt Bildframes mal einer veralteten Geschwindigkeit. Ein zusätzlicher Nachweis verlangt Landung. Exakte Godot-4.6.3-Reproduktion: alte Schätzung 7,583 Meter, tatsächliche Strecke 11,375 Meter. Die vollständige korrigierte Laufprüfung bestand 510 Checks einschließlich 30 Dschungeldurchläufen.
5. **3D-Nachhilfe und Holo-Aufgaben auf Android:** Flutter und Godot unterstützten die drei Lernarten `tutor`, `holo_word_problem` und `holo_sentence` bereits; der erzeugte Android-Host wies sie jedoch ab. Seine Zulassungsliste wurde an die vorhandenen validierten Lernpfade angeschlossen. Der echte Android-Generatorvertrag prüft alle 15 angebotenen Lernarten. 41 zusätzliche Prüfungen durchlaufen den produktiven Godot-Boot mit echten Aufgaben, Szenenressourcen und unverändertem Kind-, Aufgaben- und Sitzungskontext.
6. **Vollständige relevante Kandidatenprüfung:** Neue Lernfilm-, Sprachbeispiel-, Nachhilfe- und Dialogtests sowie neue Godot-Spielpfade werden im regulären APK-Workflow ausgeführt. Bereits bestehende Prüfungen bleiben bestehen. Der lokale Flutter-Lauf bestand alle 216 Prüfungen aus 27 Dateien einschließlich der zusätzlichen Chat2-/Coach-Verträge. Native Android-Spielstarts erhalten ein eigenes verbindliches Gate mit tatsächlichen UI-, Router- und Prozessbeobachtungen.
7. **Paketidentität:** Der Bau vergleicht Quellcommit, Version, Godot-Pin, Signatur und tatsächlichen PCK-Inhalt zwischen ARM64 und Emulator-APK. Die Paketprobe startet den aus der fertigen ARM64-APK extrahierten PCK. Dadurch wird der geprüfte Spielinhalt an die tatsächlich ausgelieferte Datei gebunden.
8. **Vorhandene Dorfstimme:** Die Dorf-Einführung initialisierte ihren Sprecher bereits, wurde aber durch dessen Modusprüfung abgewiesen. Der explizit gewählte Dorfmodus ist jetzt zusätzlich angeschlossen; Eltern- und Lizenzfreigabe sowie Abbruch beim Verlassen bleiben erforderlich. Der gezielte Vertrag bestätigt 19 Eigenschaften. Der abschließende native Vertragslauf besteht insgesamt 24 Tests.

## Bereits enthaltene gemeinsame Funktionsbasis

15 Rennstrecken, 14 Fahrzeuge, 19 Items, drei Abenteuer-Parcours, beide Arena-Regeln, lokales Zwei-Geräte-Zeitfahren, Schach mit 22 Lernstationen, vier Kartenspiele einschließlich Punktlandung, Sternenpost, zwölf Memory-Motive, Lernfilme und die angebundene 3D-Nachhilfe bleiben Bestandteil der gemeinsamen Quelle. Die eigene Nachhilfe ist weiterhin auf die dafür entwickelten Aufgaben beschränkt; die Integration erweitert sie nicht ohne neue Inhalte auf sämtliche Fächer.

## Prüfstand und Lieferung

Der Kandidat ist `0.13.54+2066`. Dieses Dokument ist ein Arbeitsnachweis vor der endgültigen APK-Prüfung. Neue APK, öffentliche Downloadadresse und Android-Abschluss werden erst nach dem jeweiligen tatsächlichen Ergebnis ergänzt. Der vorherige 2065-Bau war wegen der beschriebenen Sprungweitenmessung gescheitert und wird nicht als Lieferung ausgegeben.

Der integrierte Godot-Quellstand ist `04613baa8e4e3e597d3ed8c683aa1778eefc4c07`. Einzelne lokale Originalprotokolle und ihre SHA-256-Werte stehen in [local-proof/manifest.json](local-proof/manifest.json). Der separate [Lern- und Dialogbericht](LEARNING-INTEGRATION.md) nennt die tatsächlich geprüften Verträge und ihre jeweiligen Grenzen.

Lokale Werkzeuge werden in den offiziellen Versionen Flutter 3.44.9, Godot 4.6.3, JDK 17 und Gradle 9.1.0 geprüft. Einzelne bestandene Quell-/JVM-/Engine-Prüfungen ersetzen den anschließenden Android-Lauf nicht. Ein physischer Fold7-/60-FPS-Nachweis wird nicht aus Emulator- oder Desktopprüfungen abgeleitet.

## Dauerhafte Sicherung

Die Shell besitzt keine GitHub-Push-Anmeldung. Der vorgeschriebene Checkpoint-Wächter wurde versucht und meldete fehlgeschlagene Pushes. Die Arbeit wird deshalb nach abgeschlossenen Paketen über die autorisierten GitHub-Blob-/Tree-/Commit-/Ref-Werkzeuge auf den beiden isolierten Zweigen gesichert. Die ursprünglichen lokalen Checkpoints bleiben erhalten; es gibt keinen Force-Push und keinen Main-Merge.
