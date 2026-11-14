# Preserving Host/Dream merge – 2026-11-14

This checkpoint joins Host `38c2fe8cb9e1b1021842e886c1a7cfa199e687ca` and `3d91bd8355a539c3c2413760959684cd3fee985a`; their actual common ancestor is `32e7efbff427fef64e90b3a1fcecd3b52f00af42`. Both parents are retained in the new commit. The source is frozen on these inputs for the next full candidate run.

The three current-2020 policies bind Native `e2d15dbc5f3709306decb139eeb70a1cf30c0b73`, an independently checked two-parent merge of `bd0712259bb64908a5649ee1999638826c9eb597` and the tested minimap source `6ecc560ea16202b935c4f1d32b08b93cda358e02`. Every pre-2020 policy remains unchanged. See `native-binding.json` and the original Native evidence directory referenced there.

The actual git merge-file output has five expected add/add conflicts: two independent gate insertions and the three differing current native pins. Both complete workflow blocks and both required-step entries survive. The actual 52-mode block, early return/wisp blocks and existing native artifact upload are unchanged. All 47 existing delivery tests and 11 additional Dream tests remain. The already-corrected Continue tuple is identical in both parents. No app functionality is deleted.

The incoming Dream documents and their original files are incorporated with their exact Git blobs. Math production/tests, prior protected host sources and the host assets tree are unchanged from the quality checkpoint because no entries under those paths are changed in this merge. The two local static-review helper mistakes and their corrections are explicitly recorded in `static-review-iterations.json`; neither required a production/test change.

`source-records.json` binds all seven compared source paths. `resolution-record.json` records the actually executed static preservation assertions. The corresponding scripts are included for review. The independent Host and Native-reader reviews are under `../c4-dream-connection-recovery-20261114/`.

The old dfc3 226-test pass and 38c2 65-pin-test pass retain their original source scope. A new committed-source focused run and the full exact-candidate CI remain required. This checkpoint does not approve a new APK, Android tour, visual receipt, public URL, physical frame rate or Play release.
