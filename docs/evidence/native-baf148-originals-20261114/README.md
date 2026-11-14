# Native baf: compact documentary checkpoint

This checkpoint preserves already frozen, actual Native CI evidence for `baf148b03a7a32c6ad9f737d731f900eb9113ea1`,
tree `0c18a0ca5200ade267cfedb4c12d5c4b0a761a00`, run **43600806315**, attempt **1**, job **132464933411**.
It does not change a Native or Host pin and performs no publication.

## Two separate archives

| Archive | Exact contents | Compressed bytes |
|---|---|---:|
| `native-baf148b-documentary-originals.tar.gz` | 203 original files: complete job log, every saved API original, source binding, complete CRC/SHA and image catalogs, frozen readers, replay reports, plus all 126 original non-image/non-cache artifact files | 5258971 |
| `native-baf148b-root-reviewed-15.tar.gz` | Exactly 15 original PNGs actually viewed by Root, the unchanged original selection catalog, and the unchanged Root review: 17 members | 25465892 |

Every member was fully read back and compared directly with its original bytes. No image was
decoded again, transformed, recompressed as an image, or substituted. Gzip is a lossless transport
wrapper; tar headers use a fixed time and numeric owner, preserving each member's bytes and mode.
The complete member results are in `roundtrip-verification.json`.

## Original retention and exclusions

The complete original ZIP remains at:

`/workspace/scratch/b3485b7bb989/native-discovery-baf148b-ci-evidence-20261114/artifacts/14116698243/native-baf148b-14116698243.zip`

It has **66,871,509 bytes**, SHA256 `cc04dd13121a2663cf5c6ae3f21e0da8f1105c566fa13fe59fd9c66f038d49db`.
All **1,516** extracted originals also remain unchanged under `/workspace/scratch/b3485b7bb989/native-discovery-baf148b-ci-evidence-20261114/verification/originals`.
No original source-pack file was created, removed, rewritten, or renamed. Before/after verification
binds all **1,594** source-pack files, their bytes, modes and modification times, plus Root's review.

The documentary archive excludes only the complete ZIP, 60 PNG payloads, and 1,330 original
Mesa/Godot shader-cache files. All excluded member identities and original locations are listed
in `documentary-exclusion.json`. The 15 selected PNGs are copied only into the separate visual
archive; the other 45 remain in the original pack. All original technical logs, JSON reports,
source inventories, raw index/tree snapshots, TSV results and archived reader sources are included.
No full extraction tree or staging copy was created for this transport checkpoint.

Inside the documentary archive, `native-evidence/manifest.json` and `native-evidence/SHA256SUMS`
are the **unchanged original full-pack inventories**. They deliberately still enumerate separately
retained payloads. They are not a claim that the compact archive contains the entire original pack.
Use this checkpoint's inclusion files to identify compact archive members. A full raster replay
still needs the separately retained original payloads; this archive operation did not rerun it.

## Preserved findings and limits

The previous frozen technical verification records actual SUCCESS for 47 Python methods,
Return21/Wisp14/Treasure92/Learning5347, Dream5/7/2, Discovery10/38/2,
Village339/42/46 with two PNGs, and Mobile **rendered428** with four safe-area and nine minimap PNGs.
It records 60 fully decoded original PNGs and all 1,516 original ZIP members verified by CRC/SHA.
The earlier local Mobile380 headless result remains a separate historical result.

The unchanged Root review covers **exactly 15** images: nine minimap, four mobile safe-area and
two Village images. Its concrete observations include clipping, ellipses and scroll limitations.
Its conclusion and limitations remain verbatim in the separate review member. The unchanged
catalog predates that review and correctly makes no visual-review assertion itself.
No new visual assessment is asserted by this packaging step. This is not an Android, physical
device, FPS, complete52/17, Host build, APK, release or publication acceptance.

The original Actions artifact is `14116698243` in `Ullmann27/lumo-godot`, with recorded
expiry 2026-12-14T14:01:59Z. Both full local retention and that external expiry are explicit;
this checkpoint performs no new remote fetch. No signed transport URL is published in these
selected originals. All selected source bytes and the review were unchanged after packaging.
