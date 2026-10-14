# Lumo 0.12.32+1939: visual integration candidate

Includes exact verified PR heads #292 `d5f9ae597a2a4fc9a338749bf797fdabf942b48a` and #293 `b256c915917746dc195a40f5c15e30bfc3124eab`, with 1938 curriculum commit `de7bcd0a` in ancestry. Integration branch only; no main merge or public release.

Visible work:
- Original Lumo hero in the existing floating-island scene with a light plinth.
- Shared Hologlas cards: reflected skylight and edge bevel without an added blur, timer or repaint loop.
- Original illustrated library background, dimensional covers, adaptive shelf layout, large-text and landscape scrolling, contrasting search field.
- Read-only “Lesefenster”: previews the actual saved first page; opening/closing a preview does not add reading counts, rewards or rewrite storage. Opening the reader remains the existing flow.
- Pinned Godot `d8d004141cdd606357aa1348691a39854e3af3c7`: three authored Sonnenhafen wave pavilions, editable Blender, real GLBs, PBR/UV, LODs and colliders.

Comparable-product check: interactive book previews/illustrated children's libraries are established patterns (e.g. Bookful). This implementation combines the existing Lumo art, local saved text and a read-only preview. No claim of worldwide novelty. The attempted web search did not yield usable search output; no unverifiable novelty claim is based on it.

Local evidence before build: 15 navigation/integration tests passed; library render and actual preview taps at 360×800, 967×805, 280×700 at 1.6 text, 640×360 passed. Existing original before screenshots and new after screenshots are actual Flutter renderer output. They are not Android/physical Fold screenshots. Full suite, Android acceptance and exact APK/run/hash are recorded by the new workflow, not assumed here.

All generated model provenance is in the Godot repo. Existing original voice recordings, progress formats and app package/signing pipeline remain in use. No microphone, paid service or public release is activated. Any failed native run remains a failure; downloadable APK is a test candidate until all required source-matched evidence passes.

## Immutable built APK and follow-up checks

- Actual Flutter APK source: `dcc70f583f7362141811365b41dc45bf110b4e1e` (product identical to `083857f6`, plus an offscreen test-fixture scroll repair).
- Unified build job **passed**: run [38493854824](https://github.com/Ullmann27/lumo-lernen/actions/runs/38493854824), job 115625031231. 1,485 Flutter tests passed; 117 skipped. Godot Stage2 run 38492503611 and video-reference run 38492503605 both passed.
- ARM64 artifact [11863523402](https://github.com/Ullmann27/lumo-lernen/actions/runs/38493854824/artifacts/11863523402); actual APK SHA256 `c108c61c7d0000155ac41438ef1ad85b4e8cff44fdb01204734459390e979fc7`. Downloaded locally; ZIP/APK CRC, actual hash, stable signature, ARM64 Flutter/Godot libraries and embedded PCK independently verified.
- Original Android job failed on a stale QA caption (`Mathematik` vs actual `Mathe`). Recheck 38496012811 failed because the QA caller did not scroll to the offscreen Gas setting. Both remain failed runs, not passes.
- QA-only repair `ec41f589cbc8c4589fa06c032f3336ccf08d9a26` reuses the complete-race observed pause-menu navigation, keeps exact captions/stable-frame guards, and verifies no product-source changes. Two actual-OCR replay regressions plus 33 existing recovery regressions passed locally. Run [38513649599](https://github.com/Ullmann27/lumo-lernen/actions/runs/38513649599) reuses the same immutable x86 APK; its actual result is authoritative.
- The delivery packaging job is gated on that successful Android run, actual moving race state, all 11 source-matched Android screenshot hashes and unchanged ARM64 APK bytes. It performs no APK rebuild or renaming. The delivered test report explicitly retains physical-device, complete-race, speech-quality and performance limitations.
- Before/after source and runtime distinctions: [before/README.md](before/README.md).

- Follow-up 38513649599 failed earlier in the Flutter More sheet: its real accessibility bounds were still moving after a scroll, so a coordinate tap hit “Lumo” instead of “Elternbereich”. Product callbacks select their actual item correctly. QA-only `51fa60a23f6bb4c842b0a61c3991e179c13bed00` now requires current enabled bounds to stay within 2 pixels for at least 0.8 seconds before tapping. Motion-replay regression passed; current unchanged-APK recheck is [38514350116](https://github.com/Ullmann27/lumo-lernen/actions/runs/38514350116).
- Additional visible backlog found in that real failed-run capture: legacy “Lumo hilft lokal” assistance screen has pale text on light cards and a different older fox illustration. This surface is **not** claimed modernized in 1939. It needs a separate product change and new version, with original-Lumo artwork and corrected contrast/responsiveness.
