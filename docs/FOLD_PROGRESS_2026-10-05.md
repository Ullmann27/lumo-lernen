# Fold progress – 2026-10-05

## Android host
- Commit `c2f6f5e0f7f83e8be898db93cedc3eb5df4c5a92`: embedded LumoGameActivity orientation changed from portrait to `sensorLandscape`, while keeping `resizeableActivity=true` and the existing resize-related `configChanges`.
- Commit `0b32f1b6f432eb4acfed01bdec4450c311317adc`: regression test added for the orientation/resize contract.
- GitHub Actions run `37339768209` on SHA `0b32f1b6f432eb4acfed01bdec4450c311317adc`: Flutter analysis PASS; full Flutter test suite PASS with 613 passed and 4 skipped.
- Physical Fold/device/FPS test: SKIP, not executed.

## Coordination
- Lumo Kart PR #17 has an explicit Copilot claim on Fold/resize files and track-arrow files. Do not duplicate those Godot changes from this branch.
- PR #197 remains mergeable. Its base branch advanced after the onboarding merge, so the branch is currently behind the base and must be reconciled before final integration without force-push.
