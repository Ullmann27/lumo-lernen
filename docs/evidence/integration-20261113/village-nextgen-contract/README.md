# Village / Nextgen contract integration evidence

This identical pack is stored in both the Native and Host repositories. It records the narrowly scoped runner and delivery-verifier changes owned by `/root/flutter_integration`. Root owns staging, commits, publication and every actual visual approval.

## Contract implemented

The fixed Nextgen-2019 core now requires **41 unique passing probe/mode pairs**: all previous 37 plus Village economy/headless, art/headless, scene/headless and scene/rendered. The rendered scene receives `--capture` and `LUMO_CAPTURE_DIR=$LOG_DIR/captures/build_village_scene_regression`. The art probe uses its real existing `checks / 0 failures` marker. The existing runner still requires clean process exit and strict engine-error checks.

The existing Studio raster set remains **24**. The three independent touch trees remain **six probe/mode pairs and 32 original PNGs**. The Studio default profile and historical2018 verifier remain unchanged. Source SHA, tree, clean-source stamps, original ZIP, artifact, run and job checks remain required.

The new independent original roster is `nextgen-evidence/nextgen/village-images.json`. It must describe exactly these four original files below `captures/build_village_scene_regression/`:

| File | Physical pixels |
| --- | --- |
| `village-overview-1280x720.png` | 1280 × 720 |
| `village-chapters-412x915.png` | 412 × 915 |
| `village-trader-2176x1812.png` | 2176 × 1812 |
| `village-treasury-640x360.png` | 640 × 360 |

Both sides require the complete fixed set, real PNG decoding, exact physical dimensions, byte counts and SHA256. The Native helper also rejects file/directory symlinks. The Host compares the exact original ZIP members and roster; neither a missing unselected original nor a substituted/renamed image can pass. Images must contain visible pixel variation after alpha composition. This is a structural image check, not a judgement of visual quality.

The nine production module families remain `learning`, `jump`, `build`, `settlement`, `garage`, `cards`, `rhythm`, `puzzle`, `treasure`. Village belongs to `settlement`, but an actual review selection must additionally contain an inspected original from `nextgen-evidence/nextgen/captures/build_village_scene_regression`. An older settlement selection cannot replace this Village group. The three required touch-review groups remain separately required.

## Verification performed

| Run | Result | Test-framework duration |
| --- | --- | --- |
| Native focused gap reproduction | 2 tests, 2 expected failures | 7.226 s |
| Native focused after implementation | 2 tests passed | 10.231 s |
| Host focused gap reproduction | 2 tests, 2 expected failures | 1.205 s |
| Host focused after implementation | 2 tests passed | 1.930 s |
| Complete affected Native contract suite | 13 passed, no failures/errors/skips | 33.252 s |
| Complete affected Host contract suites | 71 passed, no failures/errors/skips | 53.060 s |

The red runs prove the newly required contract was missing: the old shell executed only37 pairs and accepted missing Village pixels; the old Host accepted37 pairs and nine-module review without a Village selection. They are not reclassifications of historical releases. The green negative cases cover incomplete or corrupt original evidence, wrong physical dimensions, missing images, duplicate/extra/renamed entries, incorrect hashes/bytes, transparent or uniform images, and omission of the additional Village review.

Full Native command, from the Native repository:

```sh
python3 -m unittest discover -s tools/tests -p test_nextgen_runner.py -v
```

Full Host command, from the Host repository:

```sh
python3 -m unittest scripts.tests.test_studio_delivery scripts.tests.test_nextgen_2019_review scripts.tests.test_kart_graphics_delivery -v
```

The full raw logs are preserved losslessly. The result JSON files bind each full run to its exact before/after owned-source SHA256 values. `contract.json` records an independent read-only comparison of actual shell calls, Host constants and both PNG mappings; the shell and Host agree on all41 unique pairs, and the previous37 remain present. No additional test run was started while packaging this evidence.

## Ownership and source provenance

`before.json` identifies the original working-source bytes and their Git blobs; `after.json` identifies the six final source files. The new Native raster helper has no original snapshot because it is newly added. Every original/final source snapshot is archived losslessly. The two patches contain the complete changes to the three owned Native files and three owned Host files respectively; the patches were derived from the archived exact source bytes.

Native owned code:

- `tools/validate_nextgen.sh`
- `tools/verify_village_rasters.py` (new)
- `tools/tests/test_nextgen_runner.py`

Host owned code:

- `scripts/verify_studio_delivery.py`
- `scripts/tests/test_nextgen_2019_review.py`
- `scripts/tests/test_kart_graphics_delivery.py`

The only concurrently changed protected Host file was Root's `scripts/record_studio_visual_review.py` help text. Its exact diff is included separately; the executable AST is identical before/after removal of the module docstring. That file is outside this agent's owned code patch. The historical verifier, all three identity files and existing/absent review receipts retain their captured values. Root separately owns the published Village merge, the actual scene/capture probe, product toolbar repair, workflow dependency declarations and the full414-test Host gate. Those changes or test runs are not represented as this agent's code or tests.

## Evidence limits and integrity

The runner tests use controlled engine output and generated fixture PNGs; the parser tests decode actual fixture PNG bytes. These tests establish contract enforcement. They are not renderer captures, Android execution, subjective image approval or a release receipt. The older4f/37-pair evidence remains a separate historical checkpoint and cannot approve the additional Village source or images.

All `.gz` files contain complete original bytes. `manifest.json` records every stored object's byte count/SHA256 and, for gzip files, the decoded original byte count/SHA256. Gzip timestamps are deterministic where created by this pack. The two repository copies must have the same manifest and file hashes. No binaries, screenshots, toolchains, caches or UID files are included.
