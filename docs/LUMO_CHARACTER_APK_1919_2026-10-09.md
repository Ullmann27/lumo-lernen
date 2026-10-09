# Lumo Lernen 0.12.12+1919 — development candidate

## Exact sources

- Application base: `ab21b2295ca5307bae5e07c0c8a01c3017ee91a3`, the source of APK 1918 in [PR 240](https://github.com/Ullmann27/lumo-lernen/pull/240).
- Embedded Godot: [`40c8ec4aad83f73a1bdc1a9feb488a50d17e5e96`](https://github.com/Ullmann27/lumo-godot/commit/40c8ec4aad83f73a1bdc1a9feb488a50d17e5e96), [Godot PR 42](https://github.com/Ullmann27/lumo-godot/pull/42), engine 4.6.3.
- Version: `0.12.12+1919`. This file describes the candidate and its gates; it does not assert that a build or Android test has already passed.

The source selection was checked live on GitHub. APK run [37961627110](https://github.com/Ullmann27/lumo-lernen/actions/runs/37961627110) succeeded on the application base. Full workflow [37956116041](https://github.com/Ullmann27/lumo-lernen/actions/runs/37956116041) succeeded on `4b2f837a3475c14033806c13f25e1a77b89a307a`, a different source. Those historical results must not be substituted for this candidate's checks.

## User-visible changes

The existing Flutter learning app continues to launch the integrated native kart game. The reviewed Godot integration preserves the tested de91 code and selectively ports and repairs the Lumo face work from PRs 38–41. Real geometry now places the iris against the eye, supports the smiling mouth with a continuous cream chin, and keeps authored ear/jaw proportions during animation. Existing driver and kart choices remain.

The existing start menu gains a direct **Spielen** action using the selected setup and a live 3D Lumo presentation. Portrait modes remain independently scrollable. The saved-race case at 320×568 retains reachable mode selection, play and resume actions. Garage inspection, setup steps and working modes remain available.

The existing Sonnenhafen aquarium passage gains animated shared-mesh fish, reef clusters, water-light shading and entrance portals. Road geometry, gates, ramp gap, physics, race progression and rewards retain their existing contracts. This is one bounded improvement to the reference course, not a claim that all requested tracks or a new shortcut system are complete.

## Profile attribution

One pending learning answer now retains the student identity captured before delayed progress load/save. The identical regression test is required to fail twice for the precise A-versus-B ownership error on the immutable original file, then pass all three cases on the candidate. Existing storage, module, school and wallet tests and the complete Flutter suite follow.

This does **not** complete [issue 233](https://github.com/Ullmann27/lumo-lernen/issues/233). Global progress/Cosmos storage, profile-switch leases and ownership-safe legacy migration remain open. See [PROFILE_IDENTITY_AUDIT_2026-10-09.md](PROFILE_IDENTITY_AUDIT_2026-10-09.md). No storage keys or schema are migrated by this change.

## Executed desktop evidence before CI

The official Godot 4.6.3 release archive was checksum-verified. Actual captures use X11/OpenGL Compatibility and Mesa llvmpipe; they are desktop runtime images, not Android or physical Fold7 captures.

- Character pose: 2,325 checks, zero failures. Face depth/contact: 23 checks, zero failures.
- Eye proportions, face studio, vehicle geometry/detail, steering grip and 8,640 arm-contact checks passed.
- Start menu: 66 headless checks and 69 real-GL checks passed; four unretouched viewport PNGs, including the small saved-race case.
- Aquarium clearance passed headless and with actual GPU instance transforms. LOW/HIGH: 292/324 static props and 12/40 fish. Six chase-camera fixtures captured after approximately 6.25 m of actual physics-driven travel each.
- All 12 existing track contracts and the real-GL action-workshop regression passed.

The local Flutter bootstrap was blocked by automatic approval review after unexpected cloud-metadata access. It was stopped and not retried. No local Flutter result is claimed. The safe, existing GitHub-hosted workflow supplies the required RED/GREEN and full integration evidence.

## Build and acceptance contract

The existing full runtime workflow retains all 26 native probes and the Android kart API 35/API 36 plus build/puzzle/rhythm/treasure matrix. Added character and aquarium probes use the exact committed Godot pin. Their manifest includes source hashes, actual image dimensions and SHA-256 values for 20 PNGs, and explicitly marks physical hardware as not executed.

Only after the build and all six Android jobs complete successfully does the final job publish the named test artifact `LUMO-Lernen-0.12.12-1919-Android-APK`. It verifies the actual APK checksum, version, source pin and job source identities and includes `QA-RESULTS.json`, build provenance, profile RED/GREEN evidence and character evidence. A successful APK compilation alone cannot satisfy this gate.

Candidate workflow URLs, APK bytes/checksum/certificate and Android outcomes must be read from the completed run and its artifacts. They are intentionally not fabricated here. A draft PR records those outcomes after execution.

No main merge, public release, paid service, child-data migration or online activation is included. Physical Fold7 installation, thermal/frame-time sessions, complete profile isolation and two-client online verification remain separate acceptance work.
