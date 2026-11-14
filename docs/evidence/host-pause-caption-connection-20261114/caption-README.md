# PR486: observed Continue target repair

This is a source checkpoint, not a test result or Android acceptance. Exactly nine proposed paths are in `final-source/`: two narrowly changed probe files, one nine-method test, and six original-fixture/provenance files. No tests have been executed for this patch. Root must checkpoint the source before the targeted replay.

## Original failure

Run 43574161418, attempt 1, job 132384862551 and artifact 14106471875 belong to QA 08e63bd32917a6672ae99b66a17c3fa57c83977a. The original archive is 116,961,715 bytes with SHA256 e044ba0959d2099a5b2b498f1ca31d9f6ac7f9fbad4fabffb2d0d00c92dfc3f3. Its previous complete CRC/SHA inventory remains in the separate original checkpoint. A necessary second RAM read checked the identical archive and extracted only the two exact PNGs and three small original reports. No archive was retained here and no image was re-encoded.

Both original PNGs were actually viewed. The explanatory sentence contains a `weiterfahren` word span at [1540,264,1848,300], while the independent `Weiterfahren` button caption is at [1093,388,1430,427]. The failed readiness report recorded two observations of the sentence word and a touch at [1694,282]. The subsequent HUD check correctly rejected the remaining pause screen. The frozen original report and both original images remain unchanged.

## Narrow change

Only Continue opts in. Its exact caption candidates are compared with complete longer OCR lines from the same variant. Embedded word spans remain recorded as negative role evidence. Distinct independent controls remain ambiguous; duplicate observations must have pairwise IoU of at least 0.6. The selected rectangle is an original observation, never a fixed screen coordinate. Existing callers keep their original defaults and forwarded arguments.

The complete OCR reader, target stability checks, screenshot hashes, surface dimensions, all deadlines, physical touch and following HUD/drive/save conditions remain intact. `source-preservation.json` records structural and byte comparisons without importing or running the probes.

## Prepared replay and limits

The nine methods exercise the actual Continue/native-text/native-tap methods with the two original PNG/OCR pairs. Capture delivery, OCR delivery, ADB and clocks are explicit test boundaries. The positive test stops at the existing mandatory HUD call and claims neither a resumed race nor an Android run. Negative cases cover sentence-only text, two independent controls, offscreen bounds, changed PNG bytes, late OCR and non-exact text; ordering and existing-call defaults are also covered. No execution log or PASS is invented.

The two production sources are based on the published 0d7ea79cd02b921ed685abc79b27df8a5f6b4ccb, tree 863c4b45bcd6a564070ca128565688bde7e1ed11. Their before bytes are identical to those bound by the failed 08e job. `source-text.patch` covers every text path; `binary-original-mapping.json` binds the two accompanying PNGs. `source-freeze.json` provides exact SHA256 and Git blob identities for all nine paths.

The interrupted test-file write had not completed. After the environment returned, absence was checked and the full source was restored byte-for-byte from the retained function store. Original logs were not recreated. The historical full run, actual GMS ANRs and pure SwiftShader shader failures remain failures independent of this target-selection repair.
