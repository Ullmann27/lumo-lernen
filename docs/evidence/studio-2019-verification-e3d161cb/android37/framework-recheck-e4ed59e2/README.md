# Android 17 framework diagnostic: original e4ed failure

Run 43489065730 / job 132105094062 failed before the original unlock and before LUMO installation. The current guard correctly detected a system-server identity change; it was not relaxed.

`original-artifact.zip` is the complete unchanged GitHub artifact 14068108901, 2,516,134 bytes, SHA256 `8489c35f3ed4619d9fb2c37a9854e8e757f1baf94a01e71b978df874ab5ac71d`. Its 241 entries passed CRC and match the local extraction. `archive-inventory.json` binds every original member. `original-job.log` preserves the complete decoded GitHub job log.

`failure-review.json` records actual API 37 / release 17 identity, the successful unchanged-APK preflight, six readiness observations, the first graphics assertion, eight SurfaceFlinger aborts and nine system-server starts. It also records ENOSPC before the first graphics abort and explicitly leaves the unmeasured AVD target/tool version/partition size open. `curated/` contains byte-identical selected original reports and clearly labeled source-line excerpts.

The 17.8 MB full uncompressed Logcat remains unchanged in `original-artifact/` locally and is completely recoverable from the versioned original ZIP. The unpacked directory is deliberately excluded from the Git upload list; no full-Logcat bytes were discarded or rewritten.

This is infrastructure-failure evidence, not a passed Android tour, not a new APK build and not a physical Fold7 or 60 FPS result. No automatic rerun or configuration change was made.
