# Garage scroll regression: original red checkpoint

Source: 1e22d2455937e2640d1e44e153d290746f3afe49, native e9a9f60f20403ffa6b2b26d1437f958b2704d2aa, run 43596913210 attempt 1.

This checkpoint preserves unchanged failure PNG/OCR/TSV fixtures from jobs 132484382995 and 132484382954, with their artifact provenance. The new offline regression is intentionally RED against the original helper: both recorded gestures leave the actual observed Comet caption and cross above the visible list into the tab region. Original failure logs and reports were independently preserved by Android QA in b979e7f435d1e131863bcad56df07855c43b2a38.

No helper, product, workflow, APK or central branch is changed by this checkpoint. No Android, ADB, Flutter or OCR engine was executed by the offline test. A later source fix must retain exact target captions, current-frame geometry, two-frame stability, image digest binding, the existing five-gesture/150-second limits, and actual saved-race validation. This checkpoint is not a successful device acceptance.
