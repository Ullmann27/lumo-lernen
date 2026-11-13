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
passed the worlds renderer gate (67 checks, 6072 road-clearance triangle tests)
and the feedback renderer gate (52 checks). The original archives and all 18
world/effect PNG hashes were verified. The real images show distinct ice-gallery
and mineral-arch sections, unobstructed racing corridors, small nozzle-bound
boost pulses and a separately readable ground landing ring.

That source is not final: the separate full Stage 2 run `43433490455` exposed
feedback anchors retained after an actual vehicle variant rebuild. The original
production regression remains unchanged while the product lifetime fix and a
targeted rebuild regression are prepared. The winter overview also needs a
better diagnostic camera to show the whole cable-car line; the actual driving
views already show the new gallery. No scenery is hidden to manufacture proof.

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
