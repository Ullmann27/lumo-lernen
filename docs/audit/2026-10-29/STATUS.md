# Living Intelligence · geprüfter Tutor-Kern

Ausgangspunkt: `9fdfc3f17e640ade0912411167d4af2f73be8720`.
Eigener Branch: `feat/lumo-living-intelligence-20261029`.
Produktionscode nach Review-Korrekturen: `6ac7ba9bf1ecef3a61ee91c3567628c519584780`.
`main`, die ursprüngliche 2001-Arbeit, PR #411–413 und veröffentlichte APKs
werden durch diesen Branch nicht verändert.

Der erste vollständige Durchlauf ist an echte Aufgaben angeschlossen:
angeforderte Erklärung → Nichtverstehen → anderes Verfahren → eine neue Zahl
selbst bauen → Einer-Rückfrage → profilgebundener dauerhafter Prozessbeleg.
Eine falsche Zerlegung trotz richtigem Gesamtwert besteht die Prozessprüfung
nicht. Raten, Korrektur oder zusätzliche Hilfe während der Folgeaufgabe bleiben
unterstützte Übung. Einführung, Animation und „verstanden“ allein bestätigen
keine Kompetenz. Wiederholte Übertragung und spätere Erinnerung werden
konservativ getrennt.

## Neue Bausteine

- Deterministische Offline-Entscheidungen mit vier Erklärverfahren, begrenztem
  Methodengedächtnis, Denkzeit und freiwilligem Aufgaben-/Pausenwechsel.
- Partieller Graph aus 14 Lernzielen; alle Knoten besitzen mindestens einen
  aktuellen Curriculum-Link. Übungslinks sind keine Prozessbestätigung.
- [Learning Scene Contract v1](../../LUMO_LEARNING_SCENE_CONTRACT_V1.md) mit
  echten Codec-/Prüfregeltests und erzeugter Zehner/Einer-Referenz.
- Dauerhafter Zwischenbeleg für Journal + Szenengedächtnis: Wiederanlauf und
  Retry ohne doppelte Evidenz; unbekannte Speicherstände bleiben erhalten.
- Profilgetrennte Elternbegründungen und drei abwechslungsreiche tägliche
  Einstiege in vorhandene Aufgaben unter Berücksichtigung der realen Schulstufe.

## Prüfung

43 fokussierte Unit-, Widget-, Speicher- und echte Routenfälle bestanden.
Vollanalyse: 0 Fehler, 6 bestehende Warnungen, 106 Hinweise; Warnungen werden
nicht verschwiegen. Die abschließende lokale Vollregression bestand mit 1.952 Tests und 171
übersprungenen Fällen. Die erweiterte durchgehende Alternativ-/Transfer-/
Neustart-Route bestand zusätzlich. [Lokale Prüfdaten und Bild-Hashes](../../evidence/living-intelligence/local-verification.json).
Die tatsächlichen GitHub-Prüfungen des finalen PR-Heads stehen noch aus.

Die synthetische Vergleichsbank enthält zehn Fälle gegen die eingefrorene
9fdf-Tutorlogik: drei geänderte, sieben unveränderte Entscheidungen. Das belegt
Softwareverhalten innerhalb dieser Fälle, keine empirische Lernwirksamkeit.
[Ergebnisse](../../evidence/living-intelligence/synthetic-trajectories.json).

Echte Flutter-Aufnahmen: 360×820, 280×740 mit 2× Schrift, 880×1000.
[Alternative Darstellung](../../evidence/living-intelligence/actual-alternative-pictorial-phone.png),
[Fold-Werkstatt](../../evidence/living-intelligence/fold-open-workshop.png),
[große Schrift](../../evidence/living-intelligence/small-large-text-transfer-confirmed.png).
Die Eingaben laufen durch produktive Widgets und den tatsächlichen Speicher;
dies sind keine Mockups und kein Nachweis für physische Fold7-Bildraten.

## Unabhängiger Review und Entscheidungen

Ein frischer lesender Review von 9fdfc3f1 bis 0bc1f4af fand keine kritischen,
drei wichtige und zwei kleinere Befunde. Alle fünf wurden bearbeitet:

| Befund | Korrektur und Nachweis |
|---|---|
| Hilfe während der Folgeaufgabe fälschlich selbstständig | Companion- und Alternativkartenpfad markieren aktive Konstruktion/Rückfrage; beide echten Routen bleiben unterstützt |
| Beliebiger Unit-Erfolg bestätigt ein Prozesskonzept | Ohne konzeptspezifischen Validatorbeleg höchstens Beobachtung; verknüpfte Belegidentität, unabhängige Vielfalt und aktuelle Fehlerlage werden geprüft |
| Fremde explizite Profil-Lease akzeptiert einen Abschluss | Beleggeneration muss auch zur expliziten Lease passen; ursprüngliche Lease bleibt nach Auswahlwechsel verwendbar |
| Erschöpfte Alternativen überschreiben die Methode | Nur tatsächlich gewählte Szene bestimmt die gespeicherte Methode; guided bleibt auch nach offerPause erhalten |
| Bündelziel ohne erreichbare Aufgabe | Aktuelle Zehner/Einer-Werkstatt verknüpft; Test prüft Erreichbarkeit jedes Katalogknotens |

19 gezielte Regressionstests bestätigen die Korrekturen. Keine dieser fünf
Korrekturen wurde vertagt. Lesen-/Silben-/Satzbau-Werkstätten, breitere
Lehrplanprüfung, zusätzliche Original-Lumo-Animationen und nachgewiesene lokale
Spracheingabe bleiben spätere Meilensteine. Schreibtrainer, Journal, Wallet
und native Kart-Implementierungen bleiben erhalten.

## Android

Neueste veröffentlichte Haupt-App: `lumo-0.12.88-2000`, 317.118.938 Bytes,
veröffentlicht am 28.10.2026. Echter 1999→2000-Update-Lauf `40731470609`,
Gesamt-APK-Lauf `40731470822` und Veröffentlichung `40731470774`: erfolgreich.
Godot bleibt unverändert auf `adcce3093caa42bf3da47262f70bdf03cdefa347`.

Der Tutor-Kern ist keine neue APK-Veröffentlichung. Ein nächster separater
Android-Kandidat muss denselben Paketnamen und dieselbe Signatur behalten,
vollständige Sicherheits-/Speichertests, Android-Tour und echtes Update bestehen.
Build 2001 bleibt für den unveränderten vorherigen Branch reserviert.
