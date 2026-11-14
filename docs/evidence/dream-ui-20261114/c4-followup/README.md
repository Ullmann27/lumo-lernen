# Independent Connect Four follow-up

The original full CI and the original local failure are retained. The same three failures reproduced on dream-UI source `f3a79f01`: 5/8 targeted tests passed, 3 failed. Its Connect Four production and test files were byte-identical to parent `4564ad40`.

The concurrent upstream PR491 `95f12c71` already repaired the actual layout: the board and its minimum-48dp drop buttons now scroll together and share the same inset. Its Flutter fallback fixtures explicitly report a missing native plugin and wait for asynchronous initialization. Those production and test changes were used unchanged for this independent run; no competing replacement was written.

## Results

- 29/29 targeted tests passed, exit 0, with no missed-tap warnings. This includes the three originally failing cases, five real visual layouts, scroll alignment and correct-column actions, the native bridge return/resume test, full game/restart flows, and seven atmosphere tests.
- 2/2 new real Navigator tests passed at 320×740 and 640×360. They push the game from a selection route, make a real far-column move, pause and pop back, reopen the same saved board and make Gold's next move. Hit-test warnings are fatal; the state and persisted turn are asserted.
- The added test's Dart analysis reports no issues.
- Two locally rendered PNGs were actually opened. Their bytes are identical to the corresponding existing upstream evidence blobs. They show six actual stones from the scripted game, not generated artwork.

The checked Dart composition is `95f12c71` plus the four dream-UI files from `f3a79f01` plus the new navigation test. This evidence-only follow-up does not copy upstream production changes into the feature branch: the final integration must include PR491 and PR492. `manifest.json` binds every result to its exact files, hashes and scope. The original failing logs are not edited or relabelled as passing.

The full final integrated suite, APK, Android device tour and sustained 60-FPS measurement remain separate gates.
