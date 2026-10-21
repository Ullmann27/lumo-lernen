# Direkt weiterarbeiten

Branch `design/lumo-nextgen-home-math-20261021`; neuesten Remote-SHA prüfen.
Basis enthält #395, #396, #397. Nicht auf ältere Home-/Rechentrickstände wechseln.

Home-Code und Render sind gesichert. Nächstes Paket: gemeinsame Antwortkristalle
mit neutralem Ausgangszustand und echte Mathe-Szene, zuerst Zahlen bis 100 und
Cross-Grade-Mathe mit unverändertem zweiten Lernversuch. Generator, Bewertung,
Speicherung und Belohnungswerte bleiben außerhalb der Grafikkomponenten.

Wichtig: Der direkte Zahlen-bis-100-Modus hat in dieser Basis einen bewerteten
Versuch pro Aufgabe; der zweite Versuch existiert im Cross-Grade-Modus.
Keine stillschweigende Änderung dieser vorhandenen Lernlogik.
Rechentrick-Werkstatt aus #397 erhalten und nur passende Hilfe verknüpfen.

Dateien Home: `lumo_home_hero.dart`, `lumo_character_stage.dart`,
`lumo_adventure_card.dart`, `home_content.dart`, `lumo_design_system.dart`.
Belege und Einschränkungen stehen in STATUS.md. Vor langen Tests und zum Ende
`python3 tools/lumo_autosave.py once`, Remote-SHA prüfen. Watcher in diesem
Cloud-Executor als verwaltete laufende Session starten; nohup allein genügte nicht.
