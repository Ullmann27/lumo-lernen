# LUMO Kart graphics expansion: Android 2019 acceptance

## Scope and source isolation

Heinz requested a more substantial original Kart presentation after studying
Mario Kart World and other Kart menus: an inhabited home scene, more distinct
track sections and clear driving feedback. Three coordinated native work areas
cover the home scene, Winter Sprint / Crystal Canyon and driving effects.
External reference images are research only and are not application assets.

The host delivery branch is `chatgpt/lumo-kart-graphics-apk-20261113`, based on
the existing host recovery `8eab228433f124c1e2332e3d3c2ecf462ec8b136`.
The native graphics branch is `chatgpt/lumo-graphics-expansion-20261113`, PR #159,
based on `ada5ed81ad62339f15289da62670c0a4f9f7f2b9` from PR #157.
This separate candidate preserves the ongoing 2018 delivery and existing saves.
Main and earlier public releases remain unchanged.

## Measured implementation checkpoints

The host implementation checkpoint
`cb015dc943b18f261f2c4aee92c1ac7bc9c3a7d7`, tree
`7924c230def91c99c245eeb3f7469222fcaa9ebe`, includes the complete dedicated
2019 workflow, publisher, original graphics transfer verifier and explicit
2017-to-2019 update entry point. Its full local suites passed:

| Contract suite | Actual result |
| --- | --- |
| Build / release Python contracts | 332 passed, 61.019 seconds |
| Android probe contracts | 740 passed, 42.158 seconds |

These are local implementation checks, not a built APK or Android device result.
The independent module reviewer also reproduced rejection of four missing or
incorrect ARM64 PCK digests, checked preservation boundaries, and inspected the
workflow shell and embedded Python programs. The existing 2018 workflow,
dedicated update wrapper, publisher and visual receipt were preserved.

## Actual renderer review and corrections

Native run `43430078141` on `01cf063a7c11681b0060430cdb72c16d56a0b061`
produced real before/after images but failed overall. Its home capture retained
a freed garage reference after actual race start; both current and baseline
Canyon captures exposed asynchronous audio cleanup. These failures were
reproduced and repaired; their partial images do not approve publication.

Second run `43433485068` on `b83437ce50b6fc395f56bdcb698aab17e80818f7`
completed all three jobs successfully. Home passed 251 headless and 324 actual
renderer checks in four formats, plus the original 554 Spatial and 93 Garage
checks. Worlds passed 67 checks and 6072 road-clearance triangle tests; feedback
passed 52 renderer checks. The original archives and all 62
home/world/effect PNG hashes were verified. The real images show distinct ice-gallery
and mineral-arch sections, unobstructed racing corridors, small nozzle-bound
boost pulses and a separately readable ground landing ring.

That source is not final: the separate full Stage 2 run `43433490455` exposed
feedback anchors retained after an actual vehicle variant rebuild. The product
fix automatically rebinds current tyre/nozzle nodes before sampling and direct
events, including paused rebuilds. The unchanged original production regression
passed 2069 checks on the integrated correction. A new actual rebuild regression
passed 42 local logic checks; the final rendered path remains required.

Real image review and mesh inspection also exposed the new winter station
overlapping an existing snow mountain. The correction repositions only the new
station/cable structures and checks their continuous cabin paths against the
actual submitted decoration, road geometry and production camera. No scenery is
hidden to manufacture proof.

The menu's inherited logical canvas also requested up to 9.65 times the displayed
3D pixel area. The correction keeps logical UI/input/camera coordinates and
antialiasing quality while setting `scaling_3d_scale` from actual displayed
pixels. Its 52-case resolution gate includes a same-aspect window resize and is
mandatory in the final Home job and transferred original logs. This is not a
physical device frame-rate measurement.

## Inherited Android blocker found before the 2019 build

Existing 2018 run `43428626135`, on host `8eab228433f124c1e2332e3d3c2ecf462ec8b136`,
passed compilation, complete Flutter/native gates, signed APK construction and
the real 2017-to-2018 update. Its Android tour failed in the Cards face capture.
Four byte-identical actual images showed Android status icons over the Pause
button and the clock over Back. The strict OCR precondition therefore rejected
the unpaused table before examining card-face pixels, eventually exhausting the
capture budget. The original archive digest is
`60b1397d3fb5ef9a35c83fdd5adca26bd81ab3c10a5daba19aa91ebbbf5a646b`.

Root and two module reviewers opened these originals. The card fronts were
visible; the header lacked the native Android safe-area placement used elsewhere
in the project. The native correction now positions only the header from mobile
and actual display insets, refreshing on resize, focus/resume and the existing
0.20-second poll. The unchanged table and footer keep their geometry. Its
295-check runtime regression passes, including physical 1080x2400 / 2.625-density
touch bounds and actual pause/resume/return actions. The final Home artifact
must preserve the original `cards-header.log`. The existing
OCR, pixel, same-revision and two-frame checks remain mandatory. Extra timeout
or weaker acceptance would not fix this actual interface overlap.

The old Android log contains only MobileRuntime's 32/48-pixel fallback. It did
not record the additional DisplayServer safe-area return; the new APK's actual
Android tour must confirm the corrected header and readable Pause caption.

## Final native verification in progress

The combined source is `ea72b244cd279057255476a1f6103d29520a6ec5`, exact tree
`3b5eaabe2e8488eec646c6b949efee08b8c75252`. Native graphics run `43441307548`
repeats all real home/world/feedback captures on this source. It additionally
requires the physical preview-resolution gate, the Cards header regression,
and the winter visibility/lifecycle check. Visibility exceptions now bind to
actual submitted station parts; a foreign 10-cm obstruction is a permanent
negative case. Its local lifecycle passes 50 geometry checks and completes
audio teardown without errors. These geometry results do not replace images.

Attempt 1 completed the new Home capture (324 checks in all four formats),
Home 251, preview resolution 52, Cards 295, promenade 11, Spatial 554 and
Garage 93. Worlds completed 72 rendered checks / 6072 triangles plus the
50-check visibility lifecycle; feedback completed 61 rendered checks.
However, the unmodified prior source's separate headless editor import
segfaulted at CSV reimport, exit 139. The complete attempt therefore failed.
The old source had passed its previous comparison run; no new product defect
has been identified from this native importer crash. Root retried the exact
failed Home job on unchanged source. The original failure excerpt is retained
under `docs/evidence/kart-graphics-2019-reviewed/diagnostics/`.

No final visual receipt is approved at this checkpoint. The retry and complete
run must succeed. Original final artifact identities and PNGs must be checked
again before approval; successful partial outputs do not bypass this boundary.

## Final acceptance boundary

Final publication requires the final exact native source, three successful
graphics jobs from one successful run, actually inspected original PNGs in all
four review areas, a dated source-bound review, the incremented host version,
fresh signed ARM64 and x86 APKs, the full Android tour, real learning/Cards
interactions and offline speech callbacks, the real in-place update, and a
verified immutable public APK download. The transfer format is documented in
`KART_GRAPHICS_2019_DELIVERY.md`.

At this checkpoint no 2019 APK or final visual approval is claimed. Desktop
software rendering and Android emulation cannot establish physical Fold7 frame
rate, temperature, audible speech quality or hardware input latency.
