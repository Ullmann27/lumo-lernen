# English, Memory and Quiz feature integration

This development branch starts at `ae1ba5e68438e0acc89b4df92650d28c9328bed4`.
It is separate from the Studio 2020 candidate and does not change protected Main.

## Product scope

- English object activities reuse the current learning entry point, current per-child help record and existing return path.
- Quiz retains the existing rules and rewards. Its shared Dart controller persists each owned round before acknowledging native input; the prepared Godot scene and Flutter are designed to render that same saved round.
- The Memory Android transport and existing-rule wallet adapter are included. The new Memory controller, Flutter UI and native table remain outside this commit because their final source bytes could not be retrieved after the local executor disconnected.
- The private Android table channel binds game, token, child, round, revision and intent sequence. The renderer cannot submit rewards or answers on behalf of the authoritative game engine.
- The existing writing trainer, journal, speech data, child profiles and previously stored wallet data have no migration in this change.

## Acceptance boundary

The previous Native344 images and receipt do not cover these additions. The receipt is deliberately pending on this branch. It must not authorize an APK export or publication.

`LUMO Nextgen feature source acceptance` runs the actual locked Flutter toolchain, the complete existing Flutter suite with captures, the new English/Quiz Dart contracts, genuine Android Kotlin/Java compilation and table transport contracts. It does not build or publish an APK.

Native scenes and their exact source pin, current renderer review, installed Android interaction, update preservation and physical-device performance are separate required acceptance steps. Local disk-transport roundtrips replace only the Android transport boundary and do not constitute an installed-APK or measured-Fold7 result.

No local dependency recovery is used. Flutter dependency resolution and Flutter execution take place in the explicitly scoped GitHub workflow.

## Executor outage boundary

At 2026-11-14 approximately 12:30 UTC the local development environment became unavailable. This Git commit contains only the 31 source files whose complete UTF-8 contents were uploaded and read back through GitHub. It does not contain the local English/Memory/Quiz native additions or the new Memory host implementation. The unfinished local Quiz renderer is unconfirmed. English render review and Memory roundtrip observations remain scoped to their recorded local source hashes and are not relabeled as current-commit acceptance. Native integration and current APK acceptance remain blocked until the exact source files can be recovered and verified.
