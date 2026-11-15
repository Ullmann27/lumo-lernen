# LUMO Next Generation — Chat 2: Lernaufgaben

## Laufender, noch nicht abgenommener Arbeitsstand

- Bereich: vorhandene Lernaufgaben, fachliche Logik, Lernobjekte, Hilfen und Lernpfade.
- Branch: `feature/lumo-nextgen-learning-chat2-20261115`.
- Vorläufige gemeinsame Ausgangsquelle: `6f4a8c4753f4d06d0b392da0789b8162b2faa71b` (`delivery/lumo-2023-complete-update-20261115`). Der endgültig von Chat 1 bestätigte Anschlussvertrag wird vor Übergabe übernommen.
- Lokaler Arbeitsbaum: `/workspace/scratch/2f607e7664ce/lumo-lernen`.
- Godot bleibt auf dem vorhandenen Pin. Keine Änderungen an Kart, Dschungel, geschützten Schreibtrainer-/Journal-Innereien, Sprach- oder Figurdateien.
- APK-Versionierung, Zusammenführung von Chat 3/4 und gemeinsame Android-Auslieferung liegen laut aktuellem Auftrag bei Chat 1.

## Zuständigkeiten dieser drei tatsächlich gestarteten Agents

1. Aufgabenlogik: Legacy-Adapter, überprüfte Werte/Antworten, Lernlabor-Katalog und Muster, Inventar.
2. Lernansichten: kontrollierte Lernobjekte, allgemeiner Aufgabenrenderer, Zehnerfeld, Silben und Formmuster.
3. Lernbegleitung: Lernlabor-/Lektionen-Lebenszyklus, lernseitiger Adapter für Hilfe, Wiederholung, langsamer, andere Erklärung, Stopp und selbst versuchen.

Der Koordinator ergänzt die verbleibenden Lernpfade, praktische Aufgaben, Integrationsprüfungen und tatsächliche Laufzeitaufnahmen. Es werden keine Agents unterhalb dieser drei gestartet.

## Verifizierter Ausgangsbefund

- Zehn allgemeine `TaskType`-Werte, 28 visuelle Typen, 20 registrierte Fachmodule, Lernatelier und geführte Lektionen.
- Die vorhandenen Aufgaben `bridge-8-5` und `word-banane` werden erhalten und interaktiv angebunden.
- Der bisherige Adapter entfernt in einem Antwortpfad alle Nicht-Ziffern; dadurch können unterschiedliche Geld-/Dezimal-/Zeitantworten kollidieren.
- Der Lernatelier-Kontext ist noch nicht an `LumoCompanionRequests` angebunden.
- Praktische Aktivitäten sind bisher ausschließlich Karten ohne eigenen Bearbeitungs-/Speicherabschluss.
- Neue Tests und Aufnahmen gelten erst nach tatsächlicher Ausführung. Historische Tests werden nicht als Ergebnis dieses Branches ausgegeben.

## Anschluss für Chat 1/3/4

Bestehender Aufgabenbus: `lib/widgets/fox/lumo_companion_requests.dart`.
Ein lernseitiger Adapter wird unter `lib/features/learning/nextgen/` ergänzt. Er komponiert die bestehenden APIs; gemeinsame Sprach-/Figurdateien und Verträge bleiben außerhalb dieses Teilauftrags. Die aktuelle Aufgabe, Profilgeneration, Revision, sichtbarer Lernschritt und Zielobjekt werden vor jedem Befehl geprüft.

Diese Datei wird bei Übergabe mit den tatsächlichen Commits, Prüfungen, Aufnahmen und verbleibenden Grenzen ergänzt.
