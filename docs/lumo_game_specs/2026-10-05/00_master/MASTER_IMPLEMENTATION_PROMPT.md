# VERBINDLICHER LUMO 3D-/GAME-PRODUCTION-AUFTRAG

## Oberste Regel
Die Bilder in `docs/lumo_game_specs/2026-10-05/` sind die verbindliche visuelle und funktionale Produktionsspezifikation. Nicht eigenmächtig modernisieren, vereinfachen oder stilistisch neu interpretieren. Wenn Bild und bestehende App abweichen, hat das Bild Vorrang, solange keine bestehende Produktregel verletzt wird.

## Vor jedem Schreibschritt
1. Aktuelle `main`- und Arbeitsbranch-SHAs lesen.
2. #170, aktive CLAIMs, offene PRs und tatsächliche Übernahmen prüfen.
3. Keine Datei bearbeiten, die ein anderer aktiver Writer beansprucht.
4. Exakten CLAIM mit Basis-SHA und Dateiliste setzen.
5. Kleine überprüfbare Schritte; keine Full-Rewrites.

## Lumo ist ein echter 3D-Charakter
Für frei drehbare Kamera und echte 3D-Spiele muss Lumo als geriggtes 3D-Modell vorliegen, bevorzugt GLB/glTF 2.0 mit Skeleton, Skinned Mesh, Material Slots, Animation Clips, optional Morph Targets und LODs.

Pflichtzustände/Animationen: idle, breathe, blink, look, walk, run, jump_start, jump_air, fall, land, turn, point, wave, celebrate, think, surprised, dance, card_hold/play/throw, puzzle_pick/place, compass_check, treasure_open, build_pick/place/rotate.

Secondary Motion: Schwanz, Ohren, Halstuch, ggf. Rucksack. Weiche Übergänge via AnimationTree/StateMachine/BlendSpace. Keine Foot-Sliding-Freigabe.

Fehlt ein produktionsfähiges Modell: `BLOCKED_3D_CHARACTER_ASSET` melden und zuerst Character-, Rig-, Material-, Animation- und Export-Spec erstellen. Kein primitiver Platzhalter als fertiger Lumo.

## Kamera & Welt
- Hub: echte Orbit-/Soft-Follow-Kamera, Touch-Drag, sanfter Zoom, Camera Collision.
- Jump & Run: Follow mit Look-Ahead, Coyote Time, Jump Buffer, Floor Snap, stabile Landung.
- 3D-Welt: reale Geometrie/Kollisionen; Parallax nur ergänzend.
- Licht: kaltes Mondlicht, warme Laternen/Fenster, Cyan-Magie, Gold-Rewards.
- Wasserfälle performant mit Mesh/UV-Scroll/Noise/Mist; keine Videotextur-Fakes.

## Spiele
- Spielwelt: zentraler Hub mit Memory, Cards, Puzzle, Jump & Run, Rhythm, Schatzsuche, Bauwelt.
- Memory: echte Karten, Flip/Match/Mismatch/Reward.
- Cards: eigenes farb-/zahlenbasiertes Kartenspiel, kein fremdes Markendesign.
- Puzzle: einzelne Drag/Drop-Pieces mit Lift/Snap/Success VFX.
- Jump & Run: echte Physik, Plattformen, Sterne, Checkpoints, Gegner, mobile Controls.
- Rhythm: Tap/Hold/Slide/Special, Timingfeedback, Combo, beat-synchrone Stage.
- Schatzsuche: Hinweis -> Erkunden -> Rätsel -> Fund -> Belohnung.
- Bauwelt: Place/Rotate/Snap/Delete/Undo, Orbit/Zoom/Pan, Save/Templates.

## Performance
Primärziel Samsung Galaxy Z Fold7. 60 FPS nur nach Messung behaupten. LOD, Object Pooling, Frustum/Occlusion Culling, Material Sharing, MultiMesh/Instancing und angemessene Texturgrößen einsetzen. Keine unnötigen 4K-Texturen, Transparenzlayer oder Echtzeitlichter.

## Flutter/Godot
Bestehende Architektur erhalten. Flutter bleibt App-Shell/Lernen/Profile/Progress/Settings. Godot für echte Echtzeit-3D-Spiele, wenn technisch sinnvoll. Keine parallelen Progress-Systeme. Godot-Pin/PCK-Provenienz immer belegen.

## Visual QA
Für jeden Screen: Referenzbild vs. echter Runtime-Screenshot. Vergleichen: Lumo-Proportion, Perspektive, Welt, Licht, Material, UI, Typografie, Abstände, Glow, Objektdichte, Tiefe. `VISUAL_GAP` dokumentieren, statt Abweichungen als fertig zu deklarieren.

## Ausgabe pro Phase
PHASE / BASE SHA / RESULT SHA / GEÄNDERTE DATEIEN / PASS / FAIL / SKIP / REFERENCE / RUNTIME / VISUAL DIFFERENCES / PERFORMANCE / NOT EXECUTED / BLOCKER / NEXT STEP.

## Start
Noch nicht codieren. Zuerst `LUMO IMPLEMENTATION INTAKE` mit aktuellem Flutter-SHA, Godot-SHA, Branch, Claims, PRs, Referenzboards, 3D-Modell/Rig/Animation-Status, Spielstatus und Top-10-Gaps. Danach kleinsten konfliktfreien Claim bilden.
