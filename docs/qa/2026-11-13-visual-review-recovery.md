# Immutable visual-review recovery

## Scope

Support branch `chatgpt/lumo-2018-review-recovery-20261113` is based on host `a31c0070a9c1e9dfbea08f123d7ed77e5f0a8ad9`. It does not change the app, original assets, child profiles, version, native pin, release validator, committed visual approval, or active APK workflows. Main and the concurrent product integration remain untouched.

## Reproduced problem

`record_nextgen_visual_review.py` used a review-position prefix for copied screenshots. A corrected capture with the same basename then hit the intended no-overwrite guard; changing selection order also renamed unchanged images. Historical original files must not be deleted to work around this.

Actual red source: `019cefec085ea39215c8891e39b07202830abaf9`.
Actual CI run: https://github.com/Ullmann27/lumo-lernen/actions/runs/43406783909
Job `131822933804`: 22 tests, 1 assertion failure and 3 ValueError errors reproducing filename collisions; 0 skipped. All fourteen pre-existing Nextgen delivery/workflow tests passed. Original log artifact `14027971482`, SHA256 `97676a83d45df64c69ce6716300c2b985209364b15c1fc0fe4f6a6a7fdcdb633`.

## Minimal repair

Commit `b82ad63627919323c5bfbdcfecd0b8b94ab741f7` names each copied PNG using its module, full SHA256 and original basename. Corrected bytes get a new path, unchanged bytes have stable paths regardless of selection order. Historical ordinal-named originals stay untouched. All original exact-source, clean-source, archive digest, CI status, image/dimension, coverage and destination integrity checks remain.

Actual green CI run: https://github.com/Ullmann27/lumo-lernen/actions/runs/43407405933
The GitHub run reports success at exactly `b82ad63627919323c5bfbdcfecd0b8b94ab741f7`; the full script-contract suite is a separate follow-up scope and must be reported from its actual log.

Eight new regression methods cover changed-source captures, same-source rerenders, reordered selections, historical files, idempotence, corrupted destination bytes, invalid evidence and incomplete module sets. The PNGs and CI JSON in these tests are explicitly synthetic storage fixtures, not app screenshots or Android evidence.

## Limits and handoff

Local container execution became unavailable; tests are executed on GitHub-hosted runners. Native `ada5ed81ad62339f15289da62670c0a4f9f7f2b9` run `43399721309` completed successfully. The original native archive `14026025798` was downloaded and independently checked for SHA256 and ZIP CRC before the local tool failure. Only the portrait Cards screenshot was visually inspected in this support session; no complete new visual approval is claimed.

The product team still owns incorporation of the corrected native pin, complete visual review, new signed APK, real Android surface/lifecycle checks and the 2017-to-2018 upgrade. This support repair does not revive or publish the withdrawn a31/51fb APK. Review and incorporate the recorder/test changes without replacing newer product files. No merge to main is authorized by this patch.
