# Lumo Lernen + Kart – Integration 15.10.2026

This branch combines Flutter PR #308 (premium quiz), PR #309 (nine learning islands), PR #311 (real Android probe labels) and Godot Kart #67 + Bauwelt #68 via the verified integrated Godot revision `94c95e1d3a7de530744e998a505ce7792eb07fc5`.

All imported Flutter files are byte-identical to their explicitly named PR heads. Other files are inherited unchanged from `d43535f0e7a428a8386cfb072ac8499255b7bcd4`. The change replaces only the Godot source pin, adds a combined CI workflow and this audit. Story PR #306 and the alternative old quiz host #305 are deliberately not blindly imported; the current Quiz #308 is the selected newer visual implementation. External NVIDIA pilot #310 also remains out of this offline-safe integration.

Build is a technical candidate, not a release. Before calling the result complete: Flutter analysis and full tests, SHA-verified unified arm64 APK, Android API 35/36 emulator learning + Kart race, Fold surface transition, real screenshots, audible voice test, on-device install + privacy/parental checks.
