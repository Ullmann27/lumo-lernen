# Original partial CI evidence for host 01575aaf — 2026-11-14

This record refers only to host `01575aafc3f5b9032900bb57520ee65e98d7546c`, tree `7c5d36998ebcd1a78740b26f8a6c587976806e4b`, native pin `0e26153f0e58cc05739e72923b4c563a4cf380b8`.

Run: https://github.com/Ullmann27/lumo-lernen/actions/runs/43576227541

- Android host compile job 132390953974 completed successfully.
- Actual Dart/native rendered C4 job 132390954119 completed successfully. Artifact 14106378584 contains 22,143,515 bytes, archive SHA-256 `6b0d92bedcec17726c68092b8f5a173221e7d5addabe8f80f63a322088a5d173`. Root rechecked all 259 recorded image byte lengths and hashes, the identical before/after source identity, and seven original screenshots. The 250-frame recording uses fixed 24 FPS; it is not a measured Android frame rate.
- In build job 132391949339, the full Flutter/capture step succeeded. Artifact 14106691339 contains 332,514,398 bytes, archive SHA-256 `b31e19e2b132bf8441026831214f656499bef0672d0c414858cbfbbd327fc42a`. It has 548 members: the original machine log, the unmodified acceptance summary copied here, and 546 PNGs. Summary: 2,564 passed, zero failed/skipped, zero capture errors and exit 0.
- Root opened six actual Flutter originals identified in `flutter-root-visual-review.json`. This is a selected inspection, not a claim to have visually reviewed all captures. The observed missing-glyph rectangle in the Schreibcoach badge is retained explicitly.
- The complete build-contract step passed 872 tests in 237.077 seconds. The subsequent Android-probe code regression ran 928 tests in 73.704 seconds and failed with 11 errors, all from one valid and ten invalid fixture invocations in the two `StudioUpdateWrapperExecutionTests` methods. The historical 2019 wrapper read the current 2020 pubspec/config and correctly rejected that wrong version before reaching the intended synthetic artifact validators. `original-build-job-132391949339.log` preserves the complete decoded original GitHub job log. The build job and overall run failed; actual APK build, Android C4, update preservation and delivery were not reached. No failed or skipped later gate is relabelled as a pass.

The independent core workflow on this host passed 2,368 Flutter tests with 196 explicit skips, plus 48 scene tests. Analysis had 138 diagnostics under the existing nonfatal-warning/info settings; it was not a zero-warning run. The separate Astra run failed due to missing FFmpeg; its complete original failure is preserved in `../astra-ffmpeg-20261114/`.

The Orange privacy and Astra prerequisite follow-ups change the source. Their combined candidate requires its own complete source-bound CI. This predecessor's partial successes and artifacts cannot be used as a new candidate's APK acceptance.
