# Learning and navigation quality pass — 14 November 2026

Base: `682f5991feb49d3a73ab7e2b42e23af725857ea9` (host PR #485).

## Sidebar respects the family's animation preferences

The active navigation pill previously repeated its animation forever, including
when the app's reduced-animation setting, calm mode or Android's disabled-animation
preference was selected. Four real widget cases reproduced these ignored
preferences; the baseline log also preserves an unrelated compiler-process error.
The normal-mode control passed.

The same sidebar now stops its actual animation ticker for those preferences and
uses immediate selection transitions. Turning the setting off restarts the normal
glow. All destinations remain tappable. The existing two navigation cases still
reach all 14 destinations in both full and compact rails with targets at least
48 by 48 logical pixels.

## Recovered exact-selection and generator audit work

The useful `ExerciseFactory.nextExact` API, tests and sample-audit script from
[PR #484](https://github.com/Ullmann27/lumo-lernen/pull/484), source
`f536ecf86bfece11786a9a76ac0d3fdb16123093`, are integrated with this newer host.
The existing `next` generation API and its callers remain unchanged. The audit
script's unused variable was removed and the current-grade test now also rejects
a real earlier-grade-only topic. The branch-specific old workflow is not copied.

The exact final audit produced 7,552 task rows across 236 current-grade topic
families for grades 1–4. It found zero violations of the sampled structural
contracts (identity, required text, answer presence and distinct choices).
All generated sample rows are retained in `task-samples.jsonl.gz`; the manifest
contains the uncompressed SHA-256. These checks are not a teacher's review of
curriculum accuracy and do not enumerate every possible question.

## Verification

The final focused Flutter run passed all **14 tests**, exit 0: five new motion
and interaction cases, two existing full/compact navigation cases, and seven
exact-selection cases. Full commands, source hashes and raw logs accompany the
manifest. Tests used `--no-test-assets`; missing image fallback diagnostics are
preserved. No image quality, APK, physical Fold7 performance, Play readiness or
Nintendo-level quality is asserted from these results.
