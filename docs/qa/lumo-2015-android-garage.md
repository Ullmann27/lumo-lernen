# Supplemental Android Garage acceptance of the existing 2015 APK

This branch adds only a workflow, probe, negative guard tests and this document.
It does not change app or game code, existing QA helpers, baseline gates, package
identity, version or signature. It builds no APK and publishes no release.

## Immutable subject

| Field | Fixed value |
| --- | --- |
| Built Flutter source | `2718f405e69c193d0121c6f6447fe53769d7c803` |
| Embedded Godot source | `b357b2f8decb4b11b0cc45e9fde2b8df5ec9cbe1` |
| Build run | `43024454590` |
| Artifact | `lumo-lernen-kart-unified-2026-candidate`, ID `13858046311` |
| Artifact archive digest | `sha256:f45fbeee373a339654d35d395065055aa9f1c2e4156697f9926a1f4706625d2a` |
| APK SHA-256, x86_64 | `b863bc25bc07a7ca3fb78ad4fd56a6f816d091f821c5b9af27bfb0a7aecbcb4e` |
| App | `dev.ullmann.lumo.lumo_lernen.coachpreview`, `0.13.3+2015` |
| Signing certificate SHA-256 | `a6b1ef61bf59db4e0794c742aeb3b5506d130f4d21175c9975140e6acdb80702` |

The job checks the real run/event/workflow/head, latest successful build job and
the original artifact ID/digest before downloading. Existing tour and update
jobs remain independent required evidence. The original source is checked out
separately from the supplemental QA branch. Its unmodified signature/package/
embedded-PCK verifier runs before installation. The helpers' source identity
therefore remains the source that actually produced the APK.

## Mandatory runtime claims

| Case | Evidence required |
| --- | --- |
| Phone native Garage | Actual premium-menu `Garage` touch and rendered selection title |
| Cancel/back | Select Gecko; `Weiter` to world; visible `Zurück` to Kart; Android Back through driver/mode to landing; no new world-ready marker |
| Comet selection/confirmation | Actual Comet touch, world/tempo confirmation, race start; new race ID with `selected_kart=comet`, original fox, Cup/Sonnenhafen, rendered running HUD |
| First drive | Original real GAS-hold helper; unchanged minimum 8 m/2.5 s, same native race ID and changing rendered world |
| Pause/continue | Visible pause, two unchanged app-persisted samples 3 wall seconds apart; actual `Weiterfahren` touch; running HUD and another 8 m/2.5 s measured from the paused state in the same race |
| Pause/Android Back | Second real pause then Back returns to a fresh Flutter frame |
| Gecko selection/confirmation | Second real Garage journey and distinct race ID with `selected_kart=gecko_velo`; actual drive, then visible `Rennen abbrechen` returns to Flutter |
| Fold cover/open | Real `wm size` and density changes; open actual native Garage, observe Comet and reveal/select Gecko with guarded list scrolling when needed, confirm selection, visible/Android back and Flutter return; screenshot dimensions and foreground activity recorded |
| Preservation | Original profile/learning comparison and no fatal native/host crash |

Comet and Gecko Velo are original `unlock=0` cars. No stars, unlocks, configuration,
pose, session or profile are injected. The fictional profile is created through
the normal onboarding UI. Only app-generated native sessions and preferences
are read. All actions use real current accessibility/OCR bounds. OCR glyph bounds
are not asserted to be 48 dp hit areas.

Compact landscapes may require scrolling to Gecko. The probe derives a bounded
drag from the current Garage title/footer and a visible card's own glyph bounds,
requires a second matching surface and only then gestures inside the left vehicle
list. The desired caption and final two-frame touch gate remain mandatory.
The original guarded pause-modal scrolling reveals `Rennen abbrechen` when it is
offscreen. Race-marker and fatal-event reads require a successful, nonempty ADB
logcat command and archive that exact read; a transport error is a hard failure.

The pause samples prove the stored values did not change in their observation
window; they are not a continuous trace of frozen physics. The post-continue
distance/time and changing-world gates independently require actual new driving.
Each drive/pause keeps its own original screenshot/session directory. The second
pause cannot overwrite the first. The mode page accepts the two source-defined
responsive titles `Dein Abenteuer` and `Dein nächstes Abenteuer`, while requiring
the same actual Kart → driver → mode → landing navigation sequence.
At the final tempo step, the source-defined captions `Rennen starten` and
`Losfahren` identify the same start action. Premium `START` and saved-race resume
are excluded from this selection journey. During the second world build, the
old Comet save may remain on disk until Godot writes the new Gecko race. The
bounded wait therefore requires the expected kart, a new result ID and a running
clock together. Reversion to the old ID after observing the new one, another new
ID, or the wrong car in a new race remains a hard failure.

The test step has a 35-minute limit, including emulator startup; the probe has a
28-minute internal deadline. Setup and evidence upload have a separate job limit.
The `lumo-2015-existing-apk-garage-android-proof` artifact retains actual PNGs,
native saves, touch readiness/OCR records, API metadata, verification, logs and
`runtime/garage-result.json`, including failure evidence. A missing or failing
phone/Fold step cannot produce overall PASS.

## Deliberate limits and current status

This additional test does not prove full Android laps/loops/ramps, real Fold
hardware, audio/haptics, GPU frame times, temperatures, memory usage or 60 FPS.
Fold coverage here is the native Garage and navigation; the two actual races
run on the phone layout. Existing complete-route native gates remain unchanged.

Local validation command:

```sh
python3 -m unittest discover -v -s scripts/tests -p test_lumo_2015_garage_android_probe.py
```

Implementation and local guard tests are reviewable in this QA branch. Android
acceptance is pending until the actual workflow artifact reports PASS. The draft
PR targets `chatgpt/lumo-technical-art-host-20261111`; it neither merges main nor
rebuilds, signs or releases an APK.

The initial runtime attempt `43030964099` passed the source/artifact/APK-byte
guards but stopped before emulator execution because setup-android v3 requested
the retired SDK package `tools`. The workflow now explicitly requests only
`platform-tools`; APK inspection still uses pinned build-tools 36.0.0. No runtime
PASS is inferred from that failed infrastructure attempt.

Run `43032732151`, job `130563709345`, later passed source/artifact/APK-byte and
SDK setup but failed before emulator startup. The original job log at
`2026-11-11T13:54:11Z` reports `Temporary failure resolving
'azure.archive.ubuntu.com'` for all Ubuntu pockets. The subsequent required
package downloads did not resolve that host; the setup step reached its existing
8-minute limit at `13:59:17Z`. Its failure artifact is `13862217221`.

The setup now checks that particular Azure mirror's DNS first. Only if that
resolution fails, it verifies resolution of the official `archive.ubuntu.com`
and changes the Azure mirror URL to `https://archive.ubuntu.com/ubuntu` on the
disposable CI runner. Existing Ubuntu signing keys, normal APT signature checks,
package requirements, test deadlines and all runtime assertions remain intact.
The actual DNS result and changed source filenames are archived. The new test
must still execute; this infrastructure correction is not a gameplay PASS.
