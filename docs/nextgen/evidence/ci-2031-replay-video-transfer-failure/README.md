# Second complete 2031 replay: video transfer failed

Workflow `43811505799`, job `133113968910`, QA `c2518e4bad105fcc3d867ae54a5fc93744e03842`, immutable APK source `e05a96a52aaf57e466e79831f15aaffd144284ee`.

The complete original Android tour again reports `PASS_WITH_LIMITATIONS` (05:40:42–05:49:58 UTC). The reference tour subsequently reached the Flutter Ba–na–ne lesson step, then failed while collecting its guided-navigation video. `adb pull` returned exit 1 and its captured combined output contains a **7% transfer progress line**. The original recorder output is empty. The recording error reports no primary task-body exception. A missing recorder start, missing remote file, app crash or specific transport root cause is **not established** by these records. The new Banane wrapped-status reader was not reached by this reference run.

The original reference result remains `FAIL`; this replay is not eligible for publication. Its failure image, original result and recording-error JSON are retained unchanged. All 1,118 original artifact entries are preserved in the complete byte-identical ZIP parts, including files not separately extracted here.

Artifact `14201128406`: **74,671,895 bytes**, SHA-256 `cbd6a659a292804df4c81928c6c4b942c94a67c969055f05b556393788253609`. Every member's path, size, CRC and SHA-256 was checked before selected extraction. `archive-retention.json` specifies the ordered nine parts required to reconstruct the exact original ZIP. `artifact-verification.json` inventories all originals. `selected-originals-additional.json` records further verified extracts. `job-log/` contains the complete decoded job log, lossless gzip and their byte/hash manifest.

The shared recorder must continue to require a completed valid video of positive duration and retain any task-body failure. Any transfer recovery must concern the same already completed recording, preserve the first failed transfer evidence and require complete byte/hash equality; a fresh task replay must not substitute for the failed recording.
