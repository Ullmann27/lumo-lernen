# Original native acceptance for frozen Host 803a

## Result and exact source

The native gate in [run 43578509499](https://github.com/Ullmann27/lumo-lernen/actions/runs/43578509499), attempt 1, completed successfully on 2026-11-14 at 10:06:29 UTC. Its independent read-only evidence replay completed with exit code 0 at 10:10:26 UTC. This record applies exclusively to:

| Component | Exact identity |
| --- | --- |
| Host | `803a4e960ffb804a46b6d09417731c031f00f680` |
| Host tree | `744986f046f6ec65ebe314f62243187a8a0a64c0` |
| Pinned Native | `0e26153f0e58cc05739e72923b4c563a4cf380b8` |
| Native tree | `5b5992487e60ae805d708965f1500954c6b0556d` |
| Original engine stamp | `4.6.3.stable.official.7d41c59c4` |
| Artifact | `14109232711`, `lumo-candidate-pinned-native-gameplay` |
| Original ZIP | 175,744,828 bytes |
| Original ZIP SHA256 | `286d623267d1eb59de9ed5933e3308a29a5868c8beff1323b037e64f2ed357f9` |

The ZIP size and SHA256 match the GitHub artifact metadata. Extraction checked every entry's CRC and rejected unsafe paths, duplicate names, and symlinks. The archive contains 4,289 files totaling 455,213,200 uncompressed bytes. Its original expiry is 2026-12-14; this checkpoint preserves the selected original logs, manifests, and reports independently of the artifact URL. The separate visual-review checkpoint preserves the original Studio images and identifies which binary movie files were also retained.

## What was actually checked

The exact Host verifier `scripts/verify_connect_four_delivery.py` at 803a was loaded unchanged. Its three functions `checked_native_results`, `checked_native_runner_log`, and `checked_native_extension` were executed against the downloaded originals. Their source blobs and the exact Native verifier/helper/runner blobs were checked before loading; see `verifier-source/source-blobs.json`.

The results are:

- All 52 ordered mode rows exactly match the actual runner roster and are PASS. Each bound original mode log contains its required success marker and no error matched by the original verifier.
- The complete original runner log contains the mandatory 17-raster, full 52-mode, and final native success endings.
- The exact Native `verify_studio_2020_rasters.py` was invoked through the Host helper with `write=False`. It recomputed the original 17 PNG entries, three sidecar reports, and one facial movie proof record, including bound AVI/MP4/encoding/decoding/ffprobe evidence, and required equality with the untouched original manifest.
- The original source, tree, clean-tree, and engine stamps match the exact source identity above. The Host pin file and actual Native Git commit object are retained under `source-identity/`.
- A complete SHA256 inventory taken before and after replay was identical for all 4,289 originals. The canonical inventory digest is `b73cf77d2d25d72ba91b9e745b118f53f31321972a5ce99a5248fa7988bfe24b`. The pretty-printed inventory JSON has its own ordinary file hash; it is not the same serialization as that canonical digest.

The original Treasure rendered report records **3,351 checks, zero failures, ten observations**: five declared viewport/density profiles, each with fresh and restored state. Five original captures are bound to that report. These are production-scene fixtures rendered under Linux/X11/Mesa llvmpipe. The report itself states that its Android boundary is a fixture and not device execution. Its 48-dp and contrast assertions use the declared fixture geometry/density.

## Independent original-image review

The existing touch reviewer opened all 17 original PNGs and independently matched their byte lengths, dimensions, and SHA256 to the original Studio manifest: five Treasure, four Connect Four, and eight facial captures. See the [separate full image review](../native-803a-original-visual-review-20261114/visual-review.md) and its JSON for per-image observations and hashes.

No additional visible functional obstruction was identified in those static images. Two real Treasure readability details remain visible and are recorded without altering the images or source:

- In the portrait capture, the title is abbreviated to “LUMOS STER…”.
- In the landscape, fold, and portrait captures, “Entdeckungen 0 / 3” wraps before the final “3”.

The visible hint text, avatar, and controls did not overlap or clip in the reviewed Treasure captures. These observations are limited to the captured states. Static images cannot prove animation timing, audio/jaw synchrony, device responsiveness, or every navigation transition.

## Limits of this acceptance

This was a read-only replay of genuine existing CI evidence, not a fresh engine run. It did not execute Godot, Flutter, Android, an APK, a device benchmark, or new video decoding. The movie check revalidated the original bytes and the original decoder/probe proof records. The original logs include software-renderer capability warnings; “no error” does not mean “no warning”.

The full Host `checked_native` entry point, its full-checkout Git checks, and its older legacy raster helpers were not executed again locally. The completed genuine CI native step supplies that broader original gate result; this independent replay specifically covers the current 52-mode roster and additive 17-raster/report/movie contract, with separate exact commit/tree and checker-blob verification. No preexisting test was weakened or rerun.

The APK build and overall workflow were still in progress when the native artifact was collected, as recorded in `artifact-binding.json`. Their later status belongs to separate acceptance records. This evidence does not establish Google Play readiness, a signed Play AAB, Android-device behavior, 60-fps device performance, or an audio-quality judgment.

The candidate remained frozen throughout this review. No product file, test, pin, branch, or ref was changed. Newer native C4-return commit f0c19 and newer PR-base commits are outside this acceptance.

## Files

`read-only-replay.log` is the actual raw stdout/stderr of the completed replay; `read-only-replay.json` carries its exact timestamps, checker identities, all mode/image/report/movie hashes, and before/after preservation proof. `read-only-replay.py` is the script that was actually executed with Python 3.12.14 in the isolated evidence directory. It retains the original absolute local replay path as an execution record.

The `original/` subtree contains byte-identical selected files from artifact 14109232711. `original-file-inventory.json` inventories all extracted originals, including files not duplicated into this selected checkpoint. The original full ZIP remains an independent artifact identified above; this checkpoint is not represented as a full 175-MB archive mirror.

