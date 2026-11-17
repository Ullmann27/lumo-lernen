# Isolated diagnostic of the unchanged 7b16 APK

The original graphics build succeeded; API35 and in-place update probes failed
at the visible Lumo driver card. API37 recorded a real GMS broadcast ANR before
installation and exposed missing Android17 observation fields in the old
parser. Its full original run has now failed, including separate Creative
failures under investigation. No failure is relabelled as success.

The preceding repair checkpoint is remote commit
`fd3076eaf4fd0342d81cffd0219a60ea788a46ae`, based on Host
`7b16f2f5ab16f3d913ee170aefd9807c87216260`. This commit adds a separate QA
workflow, exact candidate/probe binding and continuous runtime ANR observation.
It builds no APK and publishes no release.

## Four distinct actual cases

- API35: complete existing tour followed by mandatory Studio surfaces.
- Update: original 2017 baseline through complete in-place 2019 preservation.
- API37 host: original emulator graphics option with repaired observers.
- API37 SwiftShader: identical observers/configuration except the GPU option.

Both source checkouts are real and separate. Absolute repaired probes run with
the original candidate checkout as working directory. Original API metadata,
successful build job, artifact, APK and actual PCK bytes remain strictly bound.
The preflight reports BOUND only.

The same monitor starts before boot, spans installation and both tours, and
stops only after final original system dumps. Late ANRs, earlier streamed ANRs
followed by empty event buffers, unknown input state, reader termination,
budget exhaustion and failed tours remain failures. Its explicit QA recording
budget is 3600 seconds; the existing default remains 450 seconds and the
framework deadline remains 120 seconds. No GMS exclusion is introduced.

API37 compares original package descriptors/properties, Android fingerprint,
five effective hardware fields and actual GLES renderer. The image descriptor
revision 8 remains distinct from bundled properties revision 7; requested heap
512 MB remains distinct from observed VM heap 576 MB. Startup/Vulkan logs and
gameplay still require their actual separate review.

## Validation and limits

Seven focused contract modules pass **112 tests, zero skips**, with all nine
changed source files stable. The first combined invocation exposed missing
test-sibling imports; its original failed log is retained. A test-only
PYTHONPATH matches existing discovery behavior and fixes that invocation.
Actionlint, shell syntax and embedded Python syntax pass.

Independent reviews cover bindings, runtime observation and workflow. The
workflow review predates only the final test-step PYTHONPATH line; Root
reviewed that change and reran the exact combined gate. Original observations
and explicitly synthetic counterexamples are distinguished in the tests.
No local test substitutes for an actual new Android result.

Production Main and current integration remain protected. This diagnostic
workflow accepts only its named QA branch and integration PR base. Each
renderer control retains its own actual conclusion, including failures.
