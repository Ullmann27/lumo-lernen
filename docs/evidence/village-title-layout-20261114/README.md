# Responsive village title width

## Verified original defect

The original `village-fold-open.png` was inspected directly. At 690 × 829 logical pixels it shows “Dorfwirtschaf” followed by an isolated “t”. The original image is not edited or regenerated in this evidence record.

- Producer source: `99f04bff80f82a3ee4963aaf29f970a7f79ba0cc`.
- Run/attempt: `43577377587/1`.
- Artifact: `14107710171`.
- ZIP SHA-256: `1ed819cd79d631737ebeb5e5c4dc252b8931236c89dd27f5affe8f27745ade76`.
- Fold-open PNG: 690 × 829, 595307 bytes, SHA-256 `e1157f86a5d97cacb2b23a92bdae8315cfff9441ab1932ce5724607abcf93eca`.
- The accompanying original manifest records all four original captures.

The repair is prepared against combined host `445094a101f1a3176c5ef7ae03c1e44c07d3c3d4`. Its hub source blob is `4bbfd9ebd2d10618cf2e815b0613984aa924116a`; its capture-test source blob is `9fda7e157d2403d337457b53d99eb0494d591099`.

## Cause and bounded correction

At 690 dp, the existing wide layout leaves 445.18 dp for the grid beside the companion. Three columns and two 12 dp gaps produce 140.3933 dp tiles. The ordinary border and two 9 dp inner insets reduce the title width to approximately 119.7933 dp.

Only the village tile receives 5 dp horizontal insets. A padding change alone is insufficient at the existing 640 dp wide-layout boundary: there the three-column tiles are only 128 dp wide.

For a grid containing the village portal, a short-lived `TextPainter` now measures the actual unbroken-word width. It uses the title's same resolved Nunito 17/w900 style, including the Material body's inherited letter spacing, the current `TextScaler`, locale, and direction. The calculation reserves the maximum focused border width of 2 dp on each side. The original column count remains the upper bound; columns decrease only when the complete word would not fit. Grids without the village portal retain their original column count.

The measured style is also passed to the actual title. Font size and text scaling are preserved. The title remains “Dorfwirtschaft”, and the native route and all portal callbacks stay intact. Each measurement painter is disposed immediately; no listener, timer, or animation controller is added.

## Strengthened actual-widget capture contract

The existing capture test still loads the original fonts and renders the real `GamesContent`. It now verifies the complete village label in one rendered text box, no truncated line, horizontal glyph bounds within the text layout, all glyph bounds within the card, the unchanged 17 dp base font and requested text scale, and a hit-testable card at least 48 × 48 dp.

After each untouched screenshot, a real tile tap must issue exactly one `launch3D` request with `scene='settlement'`, `livingVillage=true`, and `settlementMode='settlement'`.

The four original capture names remain. Two targeted cases are added:

- `village-fold-wide-min.png`: 640 × 829 at text scale 1.0.
- `village-fold-open-large-text.png`: 690 × 829 at text scale 1.2.

The final CI run must set `LUMO_VILLAGE_CAPTURES` and inspect the newly rendered images.

## Checkpoint validation

Both changed Dart files were parsed successfully with the existing Dart formatter. No new Flutter or visual pass is claimed for this checkpoint. The old producer run's successful exit did not detect the visible title defect; the added glyph assertions must pass on the final combined source before acceptance.
