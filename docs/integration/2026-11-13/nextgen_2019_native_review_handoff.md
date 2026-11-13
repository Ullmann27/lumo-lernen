# Separate native acceptance for the combined 2019 candidate

This repair reuses the published Studio verifier and recorder from Host
`d189cdfce88058e3e681b129b01fd36000f9e741`, integrated at
`732056af52826920e4228fc9e68e188cc8f27a82`, and adopted the published touch
contract from Host `5e07d7d6cb5d3b127d15b819e97dbe67c0ad4864` and Native
`24fb85800dfb58ec11dd409449e276299aa72b06`. The explicit `nextgen-2019` roster now
also requires the four current-goal captures published in Native
`76980a941fa05d047574d8cc386d3249d93ffca3` (tree
`8df22766bd0dbae31aacaa26c0228811c027686e`). It does not record visual approval or
publish an APK. The fixed `studio-2019` default retains the producer's eight
native jobs, five capture-source stamps, three explicitly reviewed touch groups
and separate Studio paths.
Host `76d15fa6dae9959e75f56ef724e41d07e3c08c14` (tree
`f5f261c75e73703589cf48cf07ed70f3701fd3e6`) leaves that producer verifier unchanged;
its default contract does not contain an eight- or twelve-image build roster.
Only our stricter, explicitly selected Nextgen profile has this fixed roster.
The historical 2018 recorder, verifier, receipt and reviewed PNGs are unchanged.

## Fixed combined-run contract

The existing `record_studio_visual_review.py` accepts the explicit option
`--native-profile nextgen-2019`. Only the two named profiles are supported;
callers cannot replace workflow names, required jobs, modules or evidence roots.

| Item | Required combined evidence |
| --- | --- |
| Native workflow | `.github/workflows/lumo-nextgen-2018.yml` |
| Original artifact | `lumo-nextgen-2018-native-evidence` |
| Successful jobs at the exact SHA/run | `gameplay`, `new-worlds`, `learning-preview`, `touch-workshop`, `touch-treasure`, `touch-build`, `bundle-evidence` |
| Original ZIP prefixes | `nextgen-evidence/nextgen/` plus `touch-evidence/workshop/`, `touch-evidence/treasure/`, `touch-evidence/build/` |
| Source metadata | Matching `source-sha.txt`, empty `source-dirty.txt`, `source-tree.txt` matching the fresh workflow's `head_commit.tree_id`, engine `4.6.3.stable.*` |
| Original runner result | All 37 explicitly named probe/mode pairs exactly once, all `PASS`, in `results.tsv` |
| Original raster roster | `renderer-images.json`: six sharing, eight motion, seven puzzle and three treasure PNGs; exact declared paths, hashes, byte counts and decoded dimensions |
| Independent touch results | Each touch prefix has its own `results.tsv`: the actual density probe in both `headless` and `rendered` mode exactly once, all six `PASS` |
| Independent touch source integrity | Each touch prefix has matching original SHA/tree/engine stamps and both `source-dirty.txt` and `source-dirty-after.txt` present and empty |
| Additional touch rasters | Three original `renderer-images.json` files require all six workshop, fourteen treasure and twelve build PNGs (32 total) with exact filenames, physical dimensions, byte counts and SHA-256; every PNG is fully decoded |
| Actual reviewed product modules | `learning`, `jump`, `build`, `settlement`, `garage`, `cards`, `rhythm`, `puzzle`, `treasure`; portrait and landscape required |
| Actual reviewed touch groups | At least one inspected original PNG from each `kart_workshop_density_regression`, `treasure_density_regression` and `build_dialog_density_regression` capture directory; older module views cannot replace them |
| New receipt | `config/nextgen-2019-visual-review.json`, with `native_profile: nextgen-2019` |
| Reviewed original PNGs | `docs/evidence/nextgen-2019-reviewed/`, addressed by full SHA-256 and actual module |
| Fresh publisher proof files | `proofs/native-nextgen/artifact.json`, `run.json`, `jobs.json`, `native-evidence.zip` |

The archive is hashed against both the receipt and the current GitHub artifact
digest. Every selected committed PNG must equal its original ZIP member byte
for byte. The module comes from a fixed production capture directory. Pose-studio
frames are required additional archive evidence and cannot satisfy a product
module. Missing, duplicated, mislabeled, corrupt or differently sourced evidence
fails before the recorder writes any destination files.

The 37 pairs and 24 filenames were checked against the actual combined runner
and capture source contract, not inferred from a count alone. At implementation
time these were the followup source contract, not a completed 37-gate renderer
result. The earlier successful PR160 source `2eb6c9ae388b1d79e4ac970088f9235a6aab59f7`
has only 32 runner results and cannot approve this new package.

The initial three independent touch probes and their 28 physical-size filenames
were read from the exact published Native `24fb8580` source. The subsequent
`76980a94` build probe retains those eight template views and adds the following
four current-goal views, bringing the independent touch roster to 32 images.
Each entry is under
`touch-evidence/build/captures/build_dialog_density_regression/` in the original ZIP.

| Additional original filename | Physical dimensions |
| --- | --- |
| `build-dialog-2400x1080-current-goal.png` | 2400 × 1080 |
| `build-dialog-1080x2400-current-goal.png` | 1080 × 2400 |
| `build-dialog-2176x1812-current-goal.png` | 2176 × 1812 |
| `build-dialog-640x360-current-goal.png` | 640 × 360 |

The published probe blob is `9dba35338e6dde89c51760f20eda3f45e4932a1b` and the
`tools/validate_studio_touch.sh` blob is `7adda6cc0e8682bb6f9c89507343ea6e998b0ed8`.
The probe captures `current-goal` through the actual goal dialog, retains the
four physical-size profiles and explicitly requires twelve build images. The
640 × 320 profile remains input/layout evidence without a capture. Both source
blobs were fetched from the immutable published commit and independently hashed.

The six touch probe/mode pairs and 37/24 core stay unchanged; the existing
`learning_studio_regression` core probe also receives the producer's new
extruded-equality assertions. The old eight-image build roster is rejected,
as is each individually missing current-goal original. The 703a8f3 source's
37/24 + 6/28 evidence remains a historical source checkpoint, independently
checkable with its frozen earlier verifier; it cannot approve this new combined
source or be relabeled as a 32-touch-image result.

Headless input fixtures and desktop renderer captures do
not claim a physical Android/Fold7 run, performance measurement or final visual
approval. A new combined-source ZIP and actual review remain necessary.

## Publisher and Android connection

`verify_kart_graphics_delivery.py` now requires the existing four-area graphics
review **and** this separate nine-module native review. It also calls the
producer's `verify_android_platforms` for separate original API 35 and API 37
datasets, preserving the graphics verifier's stricter independent PCK check
across all three ARM64 provenance/reinspection records. API 35 results, reused
APK identities or missing Android 17 PNGs cannot replace API 37 acceptance.

The workflow's immutable original ZIP archive location is
`integration-evidence-{native SHA}-{original artifact ID}/native-evidence.zip`
in the native repository's release assets. This is a CI evidence archive. Our
integration branch is allowed to build, compile and run the complete final
read-only acceptance job; the separate APK publisher continues to reject it.
Workflow routing and archival are owned by the coordinating agent.

The launcher's new `NativeProfileKeyRepository` remains the owner of persistent
child-to-native-save identities. The verifier's `--native-profile` option selects
a CI evidence contract; it does not create or replace a child profile key.

The original imported Studio delivery set `0.13.7+2019` and native
`b5bc6e7cdb03b190cb46f886301cf7bf3cb02928`. The producer's `24fb8580` and `76980a94` pins are
not approval of our combined native source. This repair does not change the
integration's identity files or `APPROVED`; the coordinator retains the current
values until exact-source CI and visual acceptance. The old ada5/2018 receipt remains historical evidence;
it does not approve either the new native followup or the combined 2019 package.

## Verification

The original adapter checkpoint's focused suites `test_studio_delivery`,
`test_nextgen_2019_review` and `test_kart_graphics_delivery` passed
**57 tests in 23.243 seconds, no skips**.
They include default Studio compatibility, missing puzzle/treasure selections,
other source SHAs, incomplete 37-result sets, missing or corrupt unreviewed
rasters, exact original ZIP binding, Android 17 isolation, triple ARM64 PCK
checks and explicit integration-branch publication rejection.

Raw log:
`/workspace/scratch/b3485b7bb989/nextgen-2019-adapter-evidence/recorder-delivery-contracts.log`

SHA-256: `e2d9c4d62b846c70cc2060a1fb8f9e600537ca85c9c93a3b03c0ffde441d46c2`.
These are synthetic parser/regression tests. They do not assert a new renderer,
Android device run, visual approval, APK release or measured device performance.

After the published touch-contract merge, the same targeted suites passed
**66 tests in 35.896 seconds, no skips**: 35 producer Studio tests, 14 combined
Nextgen tests and 17 graphics delivery/workflow tests. New negative cases cover
each missing/current touch selection, every touch source and clean end stamp,
each independent probe mode, all three original raster rosters, corrupt
unreviewed PNGs, substituted physical dimensions and missing or differently
sourced touch/bundle jobs. The previous 37/24, puzzle/treasure, API 35/37 and
triple-ARM64-PCK requirements remain covered.

Raw log of that initial touch-contract checkpoint:
`/workspace/scratch/b3485b7bb989/studio-touch-adapter-evidence/recorder-delivery-contracts.log`

SHA-256: `30792be8541cdef75b92efe1088cb2bf1013bf2850eb1af3076cb59873d0de91`.

### Published current-goal followup

On integration base `042f4c716c4f19d7ed366d58ea78834e33d0b6aa`, the two focused
contract tests first reproduced the old 8-build/28-touch mismatch. After the
explicit Nextgen roster was extended, both passed, including rejection of the
old eight-image build archive and each of the four individually absent
current-goal originals. The existing 35 Studio, 14 Nextgen and 17 graphics
delivery/workflow tests then passed again: **66 tests in 36.045 seconds, no
skips**. The strict source, ZIP digest, full PNG decoding, module review,
API 35/37 and triple-ARM64-PCK requirements remain unchanged.

The immutable source-contract copies, their Git blobs and SHA-256 values,
targeted Red/Green logs and complete focused-suite log are archived under
`docs/evidence/integration-20261113/studio-current-goal-contract/`.
The complete log is stored losslessly as `focused-contracts.log.gz`; its
uncompressed SHA-256 is
`aac34bf5cdc89b5f1b3d6c5a3a453345b5d5d596173b855aaf6f239d21e994e1`.
These are synthetic parser contracts for the new source requirements, not a
fresh combined renderer result, visual receipt or source-pin approval.
