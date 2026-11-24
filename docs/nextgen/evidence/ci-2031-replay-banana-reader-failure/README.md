# Immutable 2031 replay: original tour passed, native Banane reader failed

- Workflow: https://github.com/Ullmann27/lumo-lernen/actions/runs/43806736020
- QA source: `51a3bfdedf4d6a745fb574ae9186c1094eb11abf`.
- Unchanged APK source: `e05a96a52aaf57e466e79831f15aaffd144284ee`, version `0.13.19+2031`.
- Job `133099128390` failed. The original Android tour reports `PASS_WITH_LIMITATIONS`; the following reference tour reports `FAIL`. Neither status has been rewritten. This run cannot authorize publication.
- The native Banane scene shows all three syllables and the complete sentence “Das Wort hat 3 Silben.” The sentence wraps after “3”. Its current probe dispatch still used the historical single-line reader for this label. The failure image and original OCR are retained for a narrowly scoped reader regression test.
- Native repeat and the later native pattern route were not reached in this reference run. Real spoken recognition remains unverified. No full-modernization or physical-device acceptance claim follows from the passed original tour.

## Complete evidence retention

Actions artifact `14199706359` contains 3,356 original files. The complete ZIP is 113,034,986 bytes with SHA-256 `0b36fdffcd68b4855591b4662b5282eb40e8e615c4d0c647dd6f2e440f08637f`. All entry paths, sizes, CRCs and SHA-256 values were verified before extracting selected originals. `artifact-verification.json` is the complete member inventory. Concatenating the ordered parts in `archive-retention.json` reconstructs the entire original ZIP byte for byte; no source file or failed observation is omitted from that archive.

`original/` contains selected byte-identical reports, screenshots, videos, OCR, source binding, download identity and checker logs. The two extraction manifests identify which originals were extracted. The raw job log and its lossless gzip are in `job-log/`; SHA-256 values and byte counts are in its manifest. `provenance/` retains the observed MCP job/artifact records and the earlier activation record, whose then-current status is historical. The archive readers used are retained without transport URLs or credentials.

## What the performance data establishes

`interpretation.json` derives its statistics from the unchanged original result. The 46 measured Godot process intervals across seven complete windows average about 813 ms (about 1.23 process frames/s); every interval exceeds 16.7 ms. This API-35 x86_64 emulator uses llvmpipe software rendering. The data does not establish presentation FPS, CPU utilization or a physical phone's performance. Joint accepted speech, usable fox and active effect samples are counted explicitly; they do not cover the whole measurement. The original videos contain no audio track. The 60-FPS goal remains unmet in this environment and unverified on physical hardware.
