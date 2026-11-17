# Build 2018: actual portrait-screen probe failure

The product remains Flutter `a31c0070a9c1e9dfbea08f123d7ed77e5f0a8ad9`,
Godot `51fb026f0b0e7a43b3aad30cc0fcdc144050c724`, version `0.13.6+2018`.
No APK source, learning function, native scene, asset, profile schema or release
validator is changed for this probe repair.

## What actually ran

Workflow `43381440720` built the new signed APK successfully. Its completed
`verify-and-build` job `131739877430` passed the complete Flutter suite
(2472 passed, zero failed/skipped), all 304 build/preservation and 684 Android
probe checks, and the actual pinned native acceptance. The independent
`android-host-compile` job `131739877829` also succeeded.

The ARM64 APK has 321298305 bytes and SHA-256
`e588eb822eee44ccc0ed6e0f9232cf6c61d449b65a63c9538949ba78a7b16899`.
The Android emulator APK has SHA-256
`768364f33ac3280f39da74db8f75f9d77fca0986050f2da6a0b831508266cf50`.
Both embed native pack
`e1bb847cb2410a8ce81fbcc319520ec823e27c38690aad123dff5513e329b2b2`.

Android job `131762099939` then passed all 21 original tour steps, with no fatal
crash. The corrected learning route opened the actual native 8 + 5 workshop.
The local speech log recorded `LumoLearningSpeech` process 7085 starting and
completing utterance 3. These callbacks do not prove audible output in the
no-audio emulator, completion of the lesson, or successful return.

The subsequent Nextgen probe failed before its first object touch:

```
TimeoutError: Current native surface/target did not settle before touch: Ein Objekt zeigen
```

The overall workflow remains failed. The update and publication jobs were
correctly skipped. This checkpoint is not an Android acceptance or release.

## Proven cause

The untouched Android artifact is `14019739556`, 101498893 bytes, SHA-256
`5fe39dc2d931b4b2f58a82446cb75770f0e761a6960957b6ecbacd4fa060bbf2`.
It contains `nextgen/learning-move-1-surface-readiness.json` and 37 original
screenshots `nextgen/learning-move-1-0.png` through `-36.png`.

Every frame is a complete 1080 by 2400 portrait workshop. Every measured left
and right blank edge is zero. The visible gold **Ein Objekt zeigen** button is
present. The sole rejection reason in every frame is:

```
native landscape surface has not arrived
```

The shared native surface helper was written for the landscape games. It
rejected the portrait learning route before OCR was called, so no object touch
was attempted. Increasing its timeout cannot fix this incorrect format contract.
The native Learning and Cards scenes support responsive layouts; this repair
makes that contract explicit only for their probe calls. The existing default
for Kart and the older creative-game probes remains landscape.

A subsequent replay of the untouched frames with the actual German and English
Tesseract models exposed a second probe defect. The six existing full-image OCR
variants did not recognize the dark teal (`#1d3540`) lettering on the gold
learning action. A seventh full-image colour mask now retains those ink pixels
and their antialiased edges. It runs after the existing variants and neither
assumes a button region nor substitutes a caption or coordinate.

The two original frames now pass real OCR and the stable-target check. Input is
intercepted in this replay: it is a regression of the test tool, not a claim that
Android received a touch. All 33 targeted Nextgen and 22 existing surface/OCR
checks passed without skips. The original 37 Android frames were additionally
hash-checked; their completeness does not itself prove interaction.

Blank-edge rejection, current original screenshots, exact OCR targets, valid
bounds, two stable observations, resize invalidation, elapsed deadlines and all
post-touch learning, speech, Cards, storage and return assertions remain
mandatory. A portrait frame alone is never an interaction pass.

## Exact-source recovery

A separate acceptance checkout supplies the narrowly changed probe code.
The product checkout and actual APK remain exactly `a31c0070`. A complete
Git-tree comparison rejects any application or release-validator change in that
acceptance checkout. Its own automation commit is recorded separately.

Only the successful build/Flutter/native/compile scopes of the original failed
workflow may be reused, after checking their source SHA, job outcomes, artifact
identities, ZIP hashes/CRC and test results. The failed native-surface result is
never promoted. The corrected Android tour, learning/Cards interactions and
2017-to-2018 update must run successfully on the same APK bytes. The unchanged
release validators must then pass before public delivery and verification of the
actual unauthenticated download.

Main and the already-built product branch remain unchanged. Source-preserving
acceptance fixes do not require another identical APK compilation.
