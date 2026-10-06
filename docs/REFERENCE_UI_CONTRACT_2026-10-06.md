# Lumo Reference UI Contract – 2026-10-06

Diese Datei ist die verbindliche Art-Direction für die aktuelle Lumo-Lern-App. Sie basiert auf den fünf von Heinz freigegebenen Referenzbildern dieser Runde:

1. Mathe-Abenteuer in der Himmelsstadt
2. Rechen-Geschichte / Lernabenteuer mit Lumo
3. Willkommen-bei-Lumo Onboarding
4. Lumo Character Animation Reference
5. Crystal Canyon / Kristall-Canyon als Kart-Referenz

## 1. Visuelle Sprache der Lern-App

Ziel ist nicht „eine normale App mit blauem Theme“, sondern der gleiche Eindruck wie in den Referenzbildern:
- gestochen scharfe, leuchtende Himmels-/Lernwelt im Hintergrund,
- dunkelblaues transluzentes Hologlas,
- Cyan/Neonblau als primäre Leuchtfarbe,
- Orange/Gold nur für aktive Auswahl, Belohnung, wichtigen CTA und Erfolg,
- starke Tiefenstaffelung mit Schatten und Glow,
- große, runde, eindeutig berührbare Antwortflächen,
- Nunito/vergleichbare runde, schwere UI-Typografie,
- keine cremefarbenen Papierkarten,
- keine flachen weißen Standard-Buttons,
- keine statischen Texte im Hintergrundbild: alle Inhalte bleiben echte Widgets.

## 2. Aufgabenbildschirm

Der Aufgabenbildschirm folgt dem Mathe-Abenteuer-Referenzaufbau:
- Logo / Level / Sterne / XP bleiben im App-Shell,
- eine große Abenteuer-Überschrift pro Fach/Modus,
- sichtbarer Aufgabenfortschritt,
- zentrale Aufgabenkarte im Hologlas,
- bei Mathematik sichtbare Visualisierung (Mengen, Äpfel, Sterne, Zahlenstrahl, Geometrie usw.),
- vier große Antwortfelder,
- aktive/richtige Auswahl orange-gold bzw. grün,
- Hilfe als eigener blau leuchtender Bereich,
- Lumo als Tutorfigur sichtbar neben der Aufgabe,
- Fortschritt/Belohnung als Stern/XP-Rückmeldung.

Titel:
- Mathematik: Mathe-Abenteuer, bei längeren Sachaufgaben Rechen-Geschichte
- Deutsch: Wort-Abenteuer
- Lesen: Lese-Abenteuer
- Englisch: English Adventure
- Sachunterricht: Entdecker-Abenteuer
- Logik: Denk-Abenteuer
- Test/Schularbeit: fachbezogene Test-/Schularbeitsbezeichnung statt Abenteuer-Label.

## 3. Schularbeit/Test

Schularbeit ist kein anders aussehender Altbereich. Er verwendet dieselbe hochwertige Oberfläche, jedoch:
- keine Hilfe während Test/Schularbeit,
- 30 Aufgaben im Schularbeitsmodus,
- klare Konzentrationsansprache,
- Endauswertung erst nach Abschluss,
- fachbezogene Karten für Mathematik und Deutsch,
- eigener Sachunterricht-Lerncheck,
- ab Grundstufe II eigener Englisch-Lerncheck,
- gemischter Lerncheck berücksichtigt die für die Klassenstufe geeigneten Kernbereiche.

## 4. Lumo-Bewegung

Lumo darf nicht als statisches PNG wirken.

Bestehende Pose-Assets werden als Animationsphasen genutzt:
- Idle: Atmung, Schwanken, gelegentliche Pose-Wechsel,
- Blink/Wink: thumbWink,
- Talk/Explain: teacherStick,
- Point: pointSide,
- Think: bookPoint,
- Welcome/Wave: armsOpen,
- Celebrate: cheer / trophyWink.

Bewegungsregeln:
- Pose-Wechsel per kurzer Cross-Fade,
- Körperbewegung bleibt eine eigene Transform-Ebene,
- TTS triggert Talk,
- Hilfe triggert Think,
- Antippen triggert Wave/Wiggle,
- richtige Antwort triggert Celebrate,
- falsche Antwort triggert Comfort,
- Animationen reduzieren deaktiviert Dauerbewegung, ohne Inhalt zu verlieren.

Echtes rig-basiertes 3D-Lipsync bleibt ein eigener späterer Produktionsschritt; bis dahin darf die App nicht behaupten, ein vorhandenes Skelett-/Mund-Rig zu besitzen.

## 5. Curriculum

Rechtliche Grundlage: aktueller österreichischer Volksschul-Lehrplan / § 10 SchOG.

Lumo trennt:
- echte Pflicht-/Übungsfächer im Schulrahmen,
- automatisch prüfbare digitale Kernaufgaben,
- Aktivitäts-/Projektfächer.

Keine Musik-, Kunst-, Technik- oder Sport-Schularbeit als künstliches Multiple Choice, solange dafür kein passendes didaktisches Aktivitätsformat existiert.

## 6. Fold / Tablet

Alle Referenz-Screens sind Art-Direction, keine starren 9:16-Screenshots.
- Phone/Fold-Cover: vertikale Anordnung.
- Fold innen/Tablet: Lumo und Erklärung dürfen links stehen, Aufgabe rechts.
- Hinge/Falz bleibt frei von primären Controls.
- UI-Texte, Antworten und Navigation bleiben echte responsive Flutter-Widgets.

## 7. Kart-Bezug

Die gleiche visuelle Welt setzt sich in Lumo Kart fort:
- exakt dieselbe Lumo-Markenidentität,
- scharfe Leuchteffekte,
- Cyan-/Orange-Fahrbahnmarkierung,
- starke räumliche Tiefe,
- Loopings, Rampen, Wasserfälle, Brücken und Landmarken,
- keine fremden Franchise-Assets oder exakten Layout-Kopien.

Crystal Canyon dient als Track-5-Art-Direction und wird im Godot-Repo separat umgesetzt und getestet.
