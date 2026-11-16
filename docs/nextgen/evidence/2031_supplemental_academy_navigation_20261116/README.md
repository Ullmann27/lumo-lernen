# Supplemental 2031: preserve the observed open academy tools

## Original evidence and concrete cause

The original supplemental run **43819768114**, job **133139916176**, QA commit
`ae6c27c81d41342179a0bf6e60fedbcafacb63a4` remains **FAIL**. Its APK is unchanged
source `e05a96a52aaf57e466e79831f15aaffd144284ee` / native
`678cb38fea3a83a7f5841e71fba9bb2f3bfa2eef`.

Artifact **14204766749** is 37,623,671 bytes with SHA-256
`660794dab77f440a7af869e60e51bfd310c014706570f37344a3a40447736ee0`.
Root retains all 1,234 original members in five verified archive parts under
`docs/nextgen/evidence/ci-2031-runtime-cases-academy-navigation-failure/`.
Five small records are copied byte-for-byte into
`tools/android_qa/tests/fixtures/nextgen_academy_return_43819768114/`; their
manifest identifies the original members, byte counts and SHA-256 values.

The actual recorded order is decisive:

- `0399-academy-open.xml` already contains `LUMO AKADEMIE`, `Dein Lernatelier`
  and the enabled `Lumo erklärt es mir` control at `[96,1410][984,1564]`.
- The second `academy()` call nevertheless searches for the tools toggle.
  `0407-academy-tools.xml` shows the still-open tools panel and the toggle at
  `[94,786][987,929]`; `0409-academy-tools-touch.json` records that exact input.
- `0410-academy-tools-open.xml` no longer contains the tools panel.
  `0417-academy-tools-open-scroll-search.json` records the failed search after
  both observed scroll boundaries. Root's original `0418` PNG was viewed and
  shows the closed academy tools with the toggle still available.

The pinned APK source confirms the operation: in
`lib/features/teacher_mode/lumo_akademie_screen.dart`, `onAdvanced` executes
`setState(() => _showTools = !_showTools)`, and `tools` is conditional on
`_showTools`. This is an observed QA navigation error, not evidence that the
application lost the guided course or learning data.

The original result has a completed `banana_slower` subcase:
`PASS_WITH_LIMITATIONS`, actual native PID 6407, ordered MediaPlayer IDs
7, 8, 9, 10, and unchanged `0 / 3 bewegt`. There is no
`bridge_active_stop` object. This partial evidence does not change the original
overall FAIL and does not establish an acoustic speed measurement.

## Minimal correction

Only the supplemental helper's `bridge_active_stop()` entry changes. It now
observes the current exact `LUMO AKADEMIE` label and the open exact
`Dein Lernatelier` label, then invokes the existing guided-course path.
It does not call `academy()` again or touch the tools toggle.

Missing/closed tools or a different current screen still fail. The existing
guided entry still requires a unique enabled real control. No coordinates,
automatic reopening, extra navigation fallback, private state, playback deadline,
native stop gate, video gate, result validator, original/reference helper,
workflow, config or publisher is changed.

## Actual host checks and their boundary

`navigation-original-red.log` records one focused test against unchanged
production bytes: the original `academy()` call raises exactly
`Current visible Flutter text missing: Dein Lernatelier`.
`navigation-original-red-provenance.json` binds the base, production and test
hashes. The final test bytes are the same as at this RED.

`navigation-runtime-green.log` records **45/45 PASS**, zero failures/errors/skips:

```text
python3 -m unittest test_nextgen_2031_native_runtime_cases test_nextgen_2031_runtime_cases -v
```

This includes five new checks for the original toggle sequence, direct entry
from the still-open return, closed tools, a foreign current screen, and
disabled/ambiguous current guided controls. The harness parses actual original
XML with ElementTree and uses the real unchanged selectors. Delivery of those
frames, scrolling and clock values is explicitly simulated; execution stops at
the accepted guided entry, before any unexecuted course/native operation.

An earlier combined run had five fixture-loading errors because the sparse
checkout omitted an existing active-syllable fixture directory. Its untouched
log remains `navigation-runtime-sparse-fixture-setup-failure.log`. It is not the
navigation RED. Adding that already tracked fixture directory corrected the
test setup; no source/test expectation changed between those two combined runs.

**Android with this correction: NOT_RUN.** No status of a newer Android run,
no native Stop success and no release eligibility is inferred from these tests.
