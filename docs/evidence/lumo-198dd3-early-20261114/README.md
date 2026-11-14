# Current early evidence for candidate 198dd3

This is a separate evidence checkpoint for host commit `198dd3d1a5862797a37f0d1d638ea929009b8848`, tree `e17540fd0c9d047d72a67fa05c0ca5d2edfe70a6`, and native pin `bebf7bba48f09afc834469db0ea3c5541a184f55`.

The current producer is [main run 43630328343, attempt 1](https://github.com/Ullmann27/lumo-lernen/actions/runs/43630328343). Its compile job is 132555275587, desktop runtime job 132555275830, and main build job 132556738917. The two additional original focused logs come from [run 43630322241, attempt 1](https://github.com/Ullmann27/lumo-lernen/actions/runs/43630322241) on the same host commit.

## Original bytes and new reviews

Everything under `originals/` retains the producer's exact bytes. This includes the complete Flutter machine log, all 7,552 learning sample records, the original compile and desktop reports, original build-contract log, both focused job logs, and the three specific Flutter PNGs named below. There are 34 original paths.

Everything under `reviews/`, this README, and `review-index.json` is a newly written review or index, not a producer output. The index records exact byte lengths, SHA-256 values and Git blob IDs for the other 52 checkpoint files. The complete five archives remain bound through their full archive digests and all 961 original member hashes in the integrity manifests. The large archive files themselves are not copied into this checkpoint.

All five archives were downloaded once each. Their full byte lengths and SHA-256 values matched the current GitHub artifact metadata. Every archive member was fully read with its CRC checked. After the read-only review, all 961 extracted original files were hashed again and remained unchanged.

| Original archive | Artifact ID | ZIP bytes | Original files | Full ZIP SHA-256 |
| --- | ---: | ---: | ---: | --- |
| Android host compile | 14128226184 | 6,283 | 6 | `252f1f4adebe25b0779a9e1a3de2d24d6bd6c5e871d25f9ff05f20a3239a319f` |
| Desktop C4 runtime | 14128445002 | 22,145,116 | 399 | `2dd59cc48c1d64b2623cac9dfbd91b42ed0600805beae40990ae2c3152b31691` |
| Learning audit | 14127483896 | 212,133 | 7 | `d55ec4eb2c147de836b162357ac50ea73325c153eed7c5baecc290a1c0476f7a` |
| Complete Flutter suite | 14128122934 | 332,356,829 | 548 | `4a6390212b19401565b7848d9e3883ca0c3d5217624d9bc3aa07bed905060fae` |
| Build contracts | 14128931138 | 26,370 | 1 | `717ef69bd55303adc81448f4877f972dc5b15fa50f2a3d2d33390bb31473ce6b` |

## Actual current results and their limits

- **Complete Flutter:** 2,576 visible passes, no failures, no skipped tests; 3,141 started and completed records, including 565 hidden records. The original log has 8,232 lines, 385 process notifications, 323 print events and one successful final `done` event. Exit code is zero. The original summary and the current canonical summarizer agree. All 546 actual PNG entries agree with the original capture counts. Root independently hashed and strictly recounted the same complete JSONL. No new Flutter tests or rendering were run for this review.
- **Learning:** the unchanged `checked_learning_audit` reader checked all 236 families and 7,552 samples, with zero structural issues, against a genuine clean sparse Git checkout of the exact current host. It executed the real HEAD/tree/diff and six source-file checks. The source tree is not fully materialized. This sample audit does not certify an official curriculum, every variant, all existing tasks, semantic correctness, Android behavior or 3D behavior.
- **Desktop C4:** the unchanged production reader replayed the original reports: 170 native checks, 250 recorded frames, 90 moving frames and 43 winning frames. It decoded all 259 original desktop PNGs and confirmed equal before/after source snapshots. Return recovery reports 21 checks and Treasure Wisp reports 14. The recorded 24 fps describes the recording format, not measured device performance. The original backend uses the production Dart controller with test SharedPreferences and local file transport; this is not an Android Binder or disk proof.
- **Android host compile:** the original log says `BUILD SUCCESSFUL in 3m 29s`. Original reports bind nine core class groups and three C4 class groups. The registry log records 10 tests in 19.531 seconds, OK, with four actual window-authority markers. The archive contains original class hash reports, not class binaries for a separate local bytecode hash check. Original compiler/deprecation warnings are retained in the review. No local rebuild or APK/runtime acceptance is asserted.
- **Build contracts:** the original log records 845 tests in 302.249 seconds, OK, with no skipped tests. The unchanged `checked_pcm_log` reader verified the three actual PCM/JVM markers totaling 70 assertions. Their scope is the synthetic JVM boundary compiled from current Kotlin source; this is not an Android audio playback proof.
- **Focused learning and C4:** the original current logs report learning groups of 9, 7 and 7 passes, and C4 groups of 2 and 6 passes. The latter command includes the five visual layouts and Fold test; the expanded concurrent reporter does not print a distinct Fold test title in the retained completion line. Focus artifact IDs and upload digests are recorded, but those separate ZIPs were not downloaded for this review.

The desktop replay first used nine exact API-byte-verified candidate files, before the genuine sparse checkout was created. Its original review preserves that limitation. The later learning, Flutter and contracts replays use the actual clean current checkout; no reader was given a fabricated Git identity. Local read-only analysis used Python 3.12.14 and Pillow 13.0.0. The existing CI environment and its dependencies were not changed.

## Limited visual review

Root personally viewed these three current Flutter PNGs and independently confirmed their exact ZIP-member bytes:

| Original member | Bytes | SHA-256 |
| --- | ---: | --- |
| `modernization/trainer_B_phone_geuebt.png` | 558,344 | `b29974e44e52d0055de6d9dd17bacbab02ecefa546ccfcfe13d5c505b4060fc6` |
| `reading/retry-fold-cover.png` | 658,882 | `3d86e91d39ce0a6abdadd3dd013e1cbb68457d1c843846d6d0921e37fd744db0` |
| `modernization/journal_fold-open.png` | 2,348,916 | `21f03e9387a686d1d3b9623d74b23ffca9a42b34c4792fb8f4fbd0b9e32979c3` |

The journal image shows the existing empty state and a readable call to action. It does not prove journal data persistence. This visual review covers only these three named images; it does not claim that all 546 Flutter PNGs were personally inspected. Automated archive hashing, desktop image decoding and Flutter capture counting are distinct from that visual review.

## Acceptance boundary

At the metadata snapshot recorded in the new index, the main run was still in progress. This checkpoint preserves completed early evidence; it does not approve the APK, native overall suite, either Android tour, final candidate verifier, delivery bundle or publication. The seven required jobs on this exact candidate must still be checked through their own completed current originals. Historical success or failure from earlier candidates is not substituted.

This commit has only evidence additions under this directory, has the exact current candidate as its sole parent, and is placed on a separate checkpoint branch with `[skip ci]`. It changes no candidate, QA, main or delivery branch.
