# Erste geprüfte c5-Lernübernahme

Stand: 15.11.2026. Diese Teilübernahme ist keine vollständige Lern- oder
3D-Freigabe. Die Abdeckungsmatrix bleibt unter `COVERAGE.json` bestehen;
dieses Dokument beschreibt ausschließlich den danach geprüften Delta.

## Reproduzierbare Quellen

| Bestandteil | Verwendete Quelle |
|---|---|
| Root-Basis einschließlich Coverage | `c47ee4e4db4f58df53c29d9a5ebbfbe976a5f5b2` |
| Kanonischer Session-Vertrag, Bus und native Pattern-Factory | `f08ac9012caf9255185a213a5db7205d1965e3a1`; Dateien bytegleich beibehalten |
| c5-Aufgabenlogik und Lernpräsentation | lokaler Commit `dd0eb439bf278a476b3669deb5b0316b19b66e1f`, Tree `db0dfed2e7b9e1ec5d90dbb01aff583b613b023d` |
| Notwendige Manipulatives-Abhängigkeit | ausschließlich `lib/features/learning/lab/learning_manipulatives.dart` aus 2f-Commit `573eb1a14045eb2e7071f250107d6b9a4fb3bf96` |
| Separater Abhängigkeitscommit im Integrations-Worktree | `0a2a4584d72fb797fa140d83d46d5267d78cbf8b` |

Der c5-Kerncommit enthält die Manipulatives-Datei nicht erneut. Vor seinem
Testlauf muss die oben genannte 2f-Version oder ein nachweislich kompatibler
Nachfolger integriert sein. Die alte Version erzeugte beim Token-Anordnen
im ruhigen Modus einen `RenderAnimatedSize`-Layoutfehler; mit der exakt
übernommenen 2f-Datei besteht derselbe Test.

## Übernommener Umfang

- Geprüfte Form- und Zahlenmuster, fachlicher Qualitätsfilter,
  eingeschränkte Fallback-Erzeugung und aufgabengenaue Hinweise.
- `LegacyLumoTaskAdapter`: gültige Aufgaben einschließlich Kennung bleiben
  erhalten; Dezimalzahlen, Brüche, Uhrzeiten und Einheiten behalten
  unterschiedliche Antwortwerte. Muster liefern `sequence`, `period` und
  `group`; die native Factory erhält die vorhandenen Antwortoptionen.
- `AdaptiveTaskRenderer`, `LumoPremiumVisuals` und der neue
  `InteractiveTaskWorkspace`: interaktive Mengen, Zehnerübergang,
  Wegnehmen, Gruppen, Zahlenstrahl, Stellenwerte, Brüche, Silben,
  Muster und weitere begrenzte Arbeitsmodelle. Exploration und
  Präsentationsereignisse vergeben keine Wertung.
- Satz-bauen-Fallback zeigt die gegebene Aufgabe statt der versteckten
  Lösung. Die fachliche Antwortauswahl bleibt der Wertungsweg.
- Cross-Grade nutzt den gemeinsamen Lernbus, überprüft Aufgabenbindung
  und bestätigt Sprachvorschläge erst durch die bestehende Kindereingabe.
  Sein Übungsstand bleibt von Schulstufe, Sternen und XP getrennt.
- Gemeinsamer Modulrahmen bietet methodische Hilfen und kennzeichnet
  deren Verwendung über vorhandene Felder. Dafür ergänzt
  `LearningModuleProgress` zwei flüchtige Präsentationsmethoden; es
  entsteht kein neues Speicherformat.
- Praktische Aktivitäten erhalten äußere Übungseinstiege. Bestehende
  Home- und Akademie-Routen reichen ihren tatsächlichen `appState`
  durch; die bereits integrierten Farben-/Sprachaktivitätswege bleiben.

Eigene Integrationsdeltas gegenüber dem committed c5-Stand: vier
`appState`-Anschlüsse in der bereits erweiterten Akademie, zwei
Analyzer-Klammerkorrekturen, Generator–Adapter–Native-Pattern-Regression,
Prüfung der tatsächlichen Session-Bindung an den Aktivitätsrouten sowie
dieser Quellen-/Prüfbericht. Fremde Working-Tree-Änderungen wurden nicht
als fertige c5-Lieferung übernommen.

## Tatsächlich gelaufene Prüfungen

1. `sentence_prompt_privacy_test`, `interactive_task_workspace_test` und
   Roots `native_pattern_activity_test`: **35/35 bestanden** nach
   Integration der 2f-Abhängigkeit. Der vorherige Lauf mit alten
   Manipulatives bestand 34/35 und belegte den oben genannten Fehler.
2. Aufgabenqualität, Antwortpayloads, Hinweisgenauigkeit, Fallback-Pool,
   Cross-Grade-Vertrag und Speicherung, Modulfortschritt, registrierte
   Routen und vorhandene Modul-Layouts: **141/141 bestanden**.
   Der Qualitätsfall erzeugt mindestens **7.152** Varianten aus allen
   dort auswählbaren kumulativen Klassen-/Fach-/Themenkombinationen und
   16 festen Seeds. Das ist keine Behauptung über sämtliche Zufallswerte.
3. Zusätzliche Integrationsprüfung: **4/4 bestanden**. Sie führt 24 echte Musteraufgaben aus dem
   Generator über den c5-Adapter in Roots native Pattern-Factory und
   prüft die tatsächlich gebundene Session an den praktischen Routen.
4. Die bestandenen Widgetprüfungen verwenden die reale interaktive Flutter-Oberfläche
   nach Eingaben: 8 + 5 nach zweimaligem Verschieben, Banane nach
   Silbenanzeige und Muster nach Gruppenhinweis. Größen: 320 × 800,
   Fold-Außenformat 344 × 882 mit Textfaktor 1,4, Fold-Innenformat
   840 × 900. Die geprüften Aktionsziele messen mindestens 48 × 48 dp.

Der abschließende Analyzer über 27 geänderte Dart-Dateien ist ohne Befund.
Die ausführbaren Befehle und aktuellen kleinen Abschlusslogs liegen in
`evidence/c5_integration_20261115/`. Ein separater Aufnahmelauf wartet beim
Kern-Commit auf den gemeinsam genutzten SDK-Lock; deshalb enthält dieser
Commit noch keine PNGs. Die bisherigen Prüfungen sind kein Android-Geräte-,
physischer Fold-, Audio- oder 60-FPS-Beleg.

## Bewusst offen und getrennt zu übernehmen

- 2f besitzt LabScreen, Guided, die einzelnen Fachmodule und LearningContent.
  Diese UI-Dateien wurden nicht aus c5 überschrieben. Ihre gemeinsame
  Host-/Session-Verkabelung ist separat zu integrieren und zu prüfen.
- Die Oberflächen dieser Übernahme sind Flutter-2D. Ein akzeptierter
  `NativeLearningActivity`-Payload belegt einen begrenzten optionalen
  Activity-Einstieg, keine dauerhafte 3D-Figur auf jeder Aufgabe und
  keinen nachgewiesenen kompletten Godot-Ablauf.
- Im danach gelesenen c5-Working-Tree stehen weitere Fallback-Härtungen:
  keine Rechenoperation aus bloß zwei Zahlen ableiten; Wort-/Lautmodelle
  nur aus einer gegebenen Vorlage bilden; Zehner nicht auf neun kappen.
  Diese uncommitteten Änderungen und ihre Regressionen gehören noch
  nicht zu dieser ersten Übernahme.
- Weitere c5-Arbeit betrifft schnelle Token-Änderungen, explizite
  Mustergruppen, genauer begrenzte Kunst-Übungslinks sowie IQ, Foto und
  Minispiele. Die Folgeübernahme benötigt einen konkreten committed Stand.
- Schreibtrainer und Journal bleiben intern unverändert. Es wurde kein
  APK-Build, Android-Emulatorlauf oder öffentliches Release in diesem
  Teilauftrag ausgeführt; das übernimmt die Hauptintegration.
