# Kart observer regression evidence — 14 November 2026

This folder preserves the separate Python-only regression proof from [run 43628848768, attempt 1](https://github.com/Ullmann27/lumo-lernen/actions/runs/43628848768), [job 132550717683](https://github.com/Ullmann27/lumo-lernen/actions/runs/43628848768/job/132550717683). The tested QA source is `1af7db2f53853709258e117f0326c15c035987d3`, tree `3588fd081f5c245a48f9792ab1064e923ecbdf69`; its unchanged baseline is `9deaa3f24561bc65caba898585c0c00f1c77162b`. Native source remains `bebf7bba48f09afc834469db0ea3c5541a184f55`.

## Actual results

The baseline ran **one test method with two subcases**, not two test methods. Against the real unchanged baseline caller, the 150-second controlled case failed with `AssertionError: 6 != 4` at the full-image-analysis count. The 5-second controlled case raised `TimeoutError: Current complete kart caption was not observed twice inside the list: Comet`. The original unittest summary reports 2.055 seconds; the actual child process exited **1**. This exact failure shape was required; import or API mismatches were not accepted as the red proof.

The proposed checkout then ran both `test_kart_garage*.py` modules in a fresh process: **54 tests in 20.552 seconds, OK, exit 0**. The original log contains 25 successful evidence-module tests and 29 successful recovery-module tests, with no skips, expected failures, unexpected successes, failures or errors. Python was 3.12.3 and Pillow 12.3.0. Both real checkouts, their checked source files and nine original fixture files were unchanged before and after execution.

## Original files and review index

The eight original evidence paths retain their recorded bytes. `original-job.log` is the full once-retrieved timestamped GitHub job log; `original-receipt-line.log` is its exact receipt line with its line ending. The two child logs were recovered by removing only GitHub timestamp prefixes and matched to the runner's original byte counts, SHA256 and Git blob hashes. The two phase JSON files were reconstructed from their original printed values and likewise matched to all three recorded identities. The API files are the original response content.

`independent-review-index.json` is an explicitly **new derived review index**, not an original CI report. It contains the complete evidence hash list, actual source and run bindings, independent test-line recount and verification limits. This README is also new explanatory text.

The original upload and current API agree on artifact `14126829767`, 17,690 bytes, SHA256 `8462364638b25d97a920319216d7576e9fe074d7bf7ac734c2f4111315f6b75b`. The reviewer did not additionally download this ZIP and makes no independent ZIP CRC claim.

## Acceptance boundary and current blocker

This controlled Python regression executed real QA source and original pixel fixtures. It did **not** run an APK, emulator or Android tour and does not establish candidate or release acceptance.

At checkpoint preparation, the unchanged 9de main run `43622379532` had a [failed update job 132547863799](https://github.com/Ullmann27/lumo-lernen/actions/runs/43622379532/job/132547863799): its original conclusion at 18:51:48 UTC reported a Tesseract timeout in `21_stage_select_gecko_velo-9-ocr-navy-latin-1x`. That separate failure remains a release blocker regardless of this green Python check. All seven current delivery gates must succeed on the finally selected source before publication.

This checkpoint adds evidence only. It does not update the active QA branch, candidate integration branch, main branch, publisher or release.
