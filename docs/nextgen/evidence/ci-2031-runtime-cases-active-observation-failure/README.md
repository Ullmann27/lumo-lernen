# Additional 2031 cases: graded correction passed; active-switch observation failed

Workflow `43812538819`, job `133117191626`, QA `e4c9b16751b4db2b1486fd58361000954f89fa11`, immutable APK source `e05a96a52aaf57e466e79831f15aaffd144284ee`. The original overall result is **FAIL** and remains unchanged.

## Actually observed numeric case

The real UI submitted **15** to the current **9+7** recall task, then submitted **16**. The persisted records confirm a distinct incorrect first attempt and correct supported second attempt. The second record contains `hint: true`; the journey adds one assisted correct answer, with earlier attempt records preserved. The case-level `numeric_wrong_then_correct.status` is `PASS`. Both actual result screenshots and the full result are retained. This is typed input and does not prove recognition or correction of a spoken number.

## Actual observation failure

The next case completed Banane construction and requested syllable repeat, but found no fresh hierarchy showing both an active syllable and enabled Next within its unchanged 45-second search window. The original result retains that exception and the case-level `RUNNING` marker; it has not been rewritten to PASS.

The full archive contains all **270** observed hierarchies `0213` through `0482-switch-live-active-and-next.xml`. Independent inspection found enabled Next in these frames but no individual syllable nodes in the visible viewport. The final actual screenshot and unchanged first/last XMLs are retained separately. The visible scroll position, rather than an established audio failure, explains why this observation condition could not be met. Any follow-up must preserve the complete same-frame active-syllable/Next requirement and the one-second capture-to-requested-touch budget, and explicitly identify its actual emulator viewport. The two subsequent native cases were not reached in this run.

## Complete evidence

Artifact `14201531176`: **15,469,393 bytes**, SHA-256 `8290ce1dfcd5779df8e2de1c3900fb8eada31ed6f48cf7236c23ad666da1dac8`, **539 original entries**. All entries were checked for size, CRC and SHA-256; two retained parts reconstruct the complete original ZIP. The manifests distinguish complete archived originals from selected extracted copies. `job-log/` retains the exact decoded log and lossless gzip. Initial activation metadata reflects its observation time; it is not a final outcome record.

These additional cases do not satisfy or replace the original/reference replay or grant APK publication. The original result's `release_eligible=false` remains authoritative.
