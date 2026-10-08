# Lumo app reference candidate 1901

Based on Claude’s complete 1f280b9 handoff, including home/rewards improvements, IQ groundwork, native lifetime star progress and profile-reset cleanup. The native source pin identifies the matching reference-design commit. Version 0.12.0+1901 uses the existing package and stable signing certificate.

The games entry includes Heinz’s generated rear-view illustration and an actual rendered Sonnenhafen backdrop. Learning-game companions use the bundled Lumo portrait instead of platform emoji; reduce-animation/accessibility preferences stop their looping motion. The race still uses a fully three-dimensional animated model.

The rendered card backdrop has no nested gameplay HUD. Exact-source QA also covers the full pause/return/display matrix, driver framing, boot/pedal/bonnet clearance and three worlds driven through the actual touch controls. Source analysis and the 739-test Flutter suite gate APK production; screenshots distinguish Flutter page renders, native model views and Android emulator gameplay.

The stopped chase camera now retains the complete rear tyres and bumper. Wide cover screens keep the baseline vertical field of view and reveal more road at either side. The runtime regression projects the actual model mesh bounds with a three-percent frame margin on phone, cover and inner surfaces at rest, speed and reduced motion. Android captures wait for the actual race HUD rather than taking the racing screenshot during the track flyover.

The stage-2 workflow builds the combined Flutter/Godot APK, performs source/tests/content checks, renders the full app at phone/Fold dimensions, and runs exact-source install/upgrade and native gameplay probes on API 35 and 36. No release/main merge is part of this candidate. Results must be read from the new run, not inherited from an older APK.

The previous treasure/API35 failure occurred before the native game: an unconditional Back after typing the onboarding name exited Flutter when the IME was already dismissed. The probe now closes only a keyboard observed in a fresh accessibility tree. It still types the full name, saves the profile, verifies it after update, and exercises all game launches and persistence.
