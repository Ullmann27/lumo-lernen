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
