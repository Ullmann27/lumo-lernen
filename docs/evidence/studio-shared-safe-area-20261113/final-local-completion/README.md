# Shared safe area: completed local follow-up

This Host-only evidence follow-up completes the two local runs that were pending in the immutable Native checkpoint. All 21 source files remain byte-, Git-blob- and mode-identical to freeze `f19731f1814dab3a6e4dabc5f9cfca0dbfee233db607d6e26ebe707e06417a21`, published by Root as Native `20fd2880494c10f8f7d3a266956995e97f9011df`. No source or historical test log was rewritten.

## Actual results

- Workshop: **4129 assertions, eight formats, exit 0**, 181.073 s. Real drags on buttons retain zero unintended actions.
- Cards software renderer: **671 assertions, five formats, three PNGs, exit 0**, 136.326 s measured inside the renderer launcher. All three new images were opened individually.
- The previous **13 completed local gates include two new Cards contracts**; they are not 13 old gates. Their original logs remain in the Native initial checkpoint.
- Shared cache and consumers: **112 headless / 124 rendered**, 15 measured targets and four actual images. The same original 15 controls change from 9 unsafe to 0; the smallest exposed side is 48.0000058 dp.

## Files

`review.json` binds results and individually viewed images, separates the interrupted attempts, and retains renderer warnings. `source-current-verification.json` rereads all 21 frozen files. `measurements/` contains unchanged input, target and projection reports. `captures/cards/` contains the three final Cards frames and exact settled JSON sidecars; `captures/shared/` contains the four previously reviewed shared-cache frames. `executions/` and `logs/` preserve completed process records and original output. No APK or unrelated directory is included.

## Scope

These are real local X11/Mesa software-rendered images and scripted production-scene inputs, using isolated QA data and explicit platform-boundary fixtures. The 136/63 portrait fixture is based on earlier Android system observations; it is not a new Android measurement. The JNI adapter boundary contract is not a device test. New Native CI, real API35/API37 APK tests and publication gates must complete separately. Physical Fold7 performance, temperature and 60 FPS remain unmeasured.

The original pending checkpoint remains historically correct. This follow-up does not move the Native head or restart CI.
