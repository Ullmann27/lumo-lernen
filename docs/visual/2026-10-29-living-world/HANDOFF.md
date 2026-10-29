# Übergabe: Operation Living World (Stand 29.10.2026)

Branch `claude/lumo-living-world-visual-20261029`. Offen für jede KI. Vor der
Arbeit `docs/audit/2026-10-29/LIVING-WORLD-VISUAL-CLAIM.md` lesen.

## Was läuft (geprüft)

- **Lebender Original-Lumo** (`lib/widgets/fox/living/`): 11 Zustände mit
  2D-Mesh-Rig auf den Original-Renderings. Ohren, Schweif, Kopf, Blick,
  Atmung und Blinzeln mit den Original-Lidern. Das ist keine 3D-Skelettanimation.
- **Lernszenen-Vertrag** (`lib/features/learning/scenes/learning_scene_contract.dart`)
  und `PlaceValueSceneDirector` mit Sols Regeln (unverändert übernommen).
- **Zehner-Werkstatt** (`scenes/place_value/zehner_werkstatt_view.dart`).
  `LumoPlaceValueWorkshop` ist jetzt eine dünne Hülle: Director plus View, mit
  gleicher API, gleichen Keys und gleichen Texten.
  - Lumo folgt der Absicht der Engine und schaut auf das Objekt im Fokus.
  - Die gezählte Stange zeigt ein Schild 10, 20, 30 …; ein Zählband läuft mit.
  - Beim Öffnen springen zehn Würfel aus der Stange; beim Bündeln fliegen zehn
    Würfel zusammen.
  - Lumo führt das Bündeln mit Lichtstrahl vor („Lumo zeigt es mir“, Key
    `lumo-place-value-demo`).
  - Weitere Teile: Zahlzerlegung mit Stellenwerttafel, Antwortkristalle bei
    „Erklär es Lumo“, Jubel nur bei selbstständigem Erfolg.
  - Bei Reduce-Motion gibt es keine Flüge und keine Schleifen; stattdessen eine
    stille Vorführung „10 Einer = 1 Zehner“.
- `lumo_place_value_blocks.dart` ist entfernt (Regel 8). Nur die alte
  Werkstatt hatte es benutzt.

### Tests

Sols Werkstatt- und Transfertests 8/8, Director-Tests 8/8,
`test/scenes/zehner_werkstatt_view_test.dart` 7/7, `test/fox_living` grün.

Abgedeckt sind:
- der animierte Durchlauf auf Handy 412, Fold außen 344 mit Schrift 2.0,
  Fold innen 690 und quer 882;
- Reduce-Motion ohne Endlosschleife;
- Touch-Ziele ≥ 48 dp.

`flutter analyze` zeigt keine Fehler; die Hinweise stehen nur in Sols
unveränderten Dateien. Renderings entstehen mit
`LUMO_SCENE_CAPTURES=<ordner> flutter test test/scenes/zehner_werkstatt_view_test.dart`.

## Nächste Schritte (aus der Bildprüfung, noch nicht umgesetzt)

1. **Layout:**
   - breit erst ab 800 dp (Lumo links, Werkbank und Bedienung rechts);
   - 600–799 dp (Fold innen): Lumo 132 dp über der vollen Werkbank;
   - unter 340 dp: Lumo 96 dp.
2. **Stangen:** gleich volle Reihen (8 = 4 + 4), Einer daneben, wenn Platz ist.
   Dazu im Build die Breite der Werkbank berechnen.
3. **Bündeln:**
   - `_hidden` und ein Flag `_landing` schon in `_send` setzen, damit nichts aufblitzt;
   - die Zerlegung erst nach der Landung zeigen.
4. **Vorführung:**
   - die zehn Quellwürfel während der Vorführung ausblenden (die Flieger sind diese Würfel);
   - die Säule neben den Würfelhaufen stellen, wenn Platz ist.
5. Zählband kompakter (Chips 12 px), damit „+ 4“ nicht umbricht.
6. Jubel mit Funken statt Punkten auf einem Ring.
7. **Test:** Einzelbilder in 50-ms-Schritten pumpen. Lumos Uhr begrenzt jeden
   Schritt auf 50 ms, sonst sieht man Überblendungs-Geister.
8. **Töne:** `sounds: st.settings.soundEnabled` am Aufruf in
   `learning_content.dart` ergänzen (eine Zeile). Vorher den Claim erweitern
   oder Sol fragen.
9. **Danach:**
   - M2: Begrüßung auf dem Home-Screen und Mini-Begleiter in Aufgaben;
   - M8: echte App-Route aufnehmen und Frame-Zeiten messen;
   - M9: Experimente A/B/C auf eigenen Branches;
   - Draft-PR mit Claim-Ergebnis für Sol.

Keine Fold7-Geräteprüfung behauptet: Alle Bilder sind Flutter-Test-Renderings.
