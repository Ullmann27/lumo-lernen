# Living Intelligence: erster verifizierbarer Tutor-Kern

Basis: `9fdfc3f17e640ade0912411167d4af2f73be8720`, Tutor-/Werkstatt-/Journey-
Implementierung wird weiterverwendet. Eigenständiger Branch, kein Überschreiben
von Sol-/Opus-Branches, main, Releases, Signaturen oder komplexen Schreibmodulen.

## Ziel und Entscheidung
Deterministische lokale Szenenwahl besitzt Vorrang vor einem zusätzlichen LLM.
Vorhandene Ressourcen geprüft: TutorCoordinationEngine, TaskHintService,
LearningJourney/ProgressRepository, GuidedLessonCatalog, lokale Sprachclients
und diagnostizierte on-device Spracheingabe. Kein neuer Modell-Download,
Cloud-Aufruf oder Mikrofonzugriff für diesen Meilenstein.

Die Engine unterscheidet Beobachtungen, mögliche fehlende Teilkonzepte und
bestätigte Evidenz. Ein erster Fehler ist keine Diagnose. Nach ausdrücklich
geäußertem Nichtverstehen wählt sie eine noch nicht versuchte Darstellung.
Zählen/Lesen/Animation allein sind kein Verständnisnachweis. Nur eine andere,
unabhängig konstruierte und korrekt erklärte Aufgabe erzeugt Transferevidenz.

## Bausteine
- Versionierter Konzeptkatalog: kleiner gerichteter azyklischer Graph mit
  exakten Zuordnungen zu vorhandenen Aufgaben und Klassen. Voraussetzungen
  sind Planungsregeln; sie behaupten keine bereits geprüften Fähigkeiten.
- Versionierter Learning Scene Contract: Lernziel, Methode, Objekte, Geste,
  Stimmung, erlaubte Eingabe, prüfbare Bedingung, nächste Alternative,
  Animationszustand, Reduce Motion und zugängliche Beschriftungen.
- LessonSceneEngine: vier feste Verfahren (sprachlich, bildlich, interaktiv,
  schrittweise). Eine vollständige Zehner/Einer-Referenzscene mit lokalem
  Lösungsschlüssel, frischer Folgeaufgabe und getrennter Ergebnis-/Prozessprüfung.
- LumoIntelligenceEngine: verständliche Entscheidungen, Methodengedächtnis,
  Nachdenkzeit ohne Unterbrechen, Grenzen nach erfolglosen Verfahren.
- Szene-/Methodenbelege als additive Erweiterung im vorhandenen
  ProgressRepository-Namespace. LearningJourney bleibt kompatibel und ist
  weiterhin der Ort für Kompetenzevidenz. Unbekannte/defekte Bytes werden
  weder überschrieben noch als erfolgreiche Speicherung angezeigt.
- Tatsächlicher Anschluss an LearningContent und bestehende Werkstatt;
  Opus bekommt eine dokumentierte, getestete Render-Schnittstelle ohne
  Schreibzugriff auf Kompetenzen. Eltern sehen den Empfehlungsgrund.

## Tagesplanung
Drei kurze Schritte; bekannte Voraussetzungen, Fälligkeit und verfügbare
Unterrichtsstufe berücksichtigen. Verschiedene Themen bevorzugen; bei nur
einem belegten Thema nicht dreimal am selben Problem festhalten. Keine
ungeprüfte neue Kompetenz als Stärke darstellen. Pausen bleiben freiwillig.

## Grenzen
Der erste komplette Durchlauf ist Stellenwert. Lesen/Silben/Satzbausteine
bekommen konkrete geprüfte Scene-Verträge und Validierer; vollständige
Lehrplan-/Tiefenflächenabdeckung wird erst nach weiterer Integration behauptet.
Die bestehende APK 2000 ist veröffentlicht und bleibt unverändert.
Android-Kandidaten und neue Releases bleiben durch bestehende Volltests,
Signatur-/Datenerhaltungs-/native Gates geschützt.
