# Actual before / after captures

- `flutter-phone-home.png`, `flutter-library-fold.png`: actual Flutter widget rendering at integration merge `ceea04377c59f49dbd01e4c0f2f6aee8c66f74ba`, before the 1939 visual changes. Fictional local test profile and story fixtures; no physical-device claim.
- Matching after views: build-evidence artifact 11863463420, run 38493854824, `screenshots/flutter/phone_home.png` and `library-fold.png`, Flutter `dcc70f583f7362141811365b41dc45bf110b4e1e`.
- `godot-race-059.png`: original Godot `ec96515a2e359d21e9591120fc81dfd15116e81e`.
- `godot-after-race-059.png`: Godot `d8d004141cdd606357aa1348691a39854e3af3c7`, identical running-race checkpoint, real touch gas input and physics; no teleport. The new wave pavilion is visible.
- Godot comparison is actual Linux desktop runtime, software OpenGL with Dummy audio, not Android or device FPS. An external evidence-only capture script retains all 600 physics steps and renders every 30 instead of every 3 steps; details in `GODOT-CAPTURE-METHOD.json`.
- Source-matched Android screenshots are separately supplied by the actual installed-APK recheck. Desktop/Flutter test screenshots are never relabeled as Android screenshots.
