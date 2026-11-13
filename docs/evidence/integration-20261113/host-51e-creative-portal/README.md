# Exact 51e creative portal recognition repair

The actual API 35 creative run 43513179062 (job 132188311296, attempt 1)
failed before any of the four game portals was touched. QA source was
6dcc5f5de7b313a387fce7654d73f620fae4a746; the installed APK remained Host
51e92fb5afab232a29850ffefef5637359af08f7 with Native
993c145304c3e5f8aa947e1c7a949a8ef8685415. Installation, original APK/PCK
identity, onboarding, offline mode and the visible games hub were reached.
No native entry, game manipulation, save/resume or Jump video was reached.

The actual four game cards were visible enabled/focusable Android Button nodes
with their complete source-matched captions, but clickable=false. The existing
Flutter _GameTile has button Semantics with excludeSemantics above its physical
InkWell. The QA incorrectly rejected those targets before issuing any touch.

The additional recognition path accepts only the four exact observed captions,
explicit false clickability, Button class, visibility and focusability. Existing
package, enabled, bounds, minimum size and ambiguity checks remain. The ordinary
Android click-action path is preserved. Each event records the actual clickability
and physical-target basis. This does not establish screenreader accessibility.
The workflow, APK/PCK constants and all native-entry/gameplay/save/video gates
remain unchanged. No main integration source is modified by this separate QA.

Four original XML fixtures replay the actual Tour.portal method. The original
code fails four portal cases plus the ambiguity counterexample; the correction
passes all seven new cases and all 23 cases in the affected module without skips.
The 16 previous test bodies remain byte-identical. These local transport-stubbed
checks do not prove an actual Android touch. Root and independent source reviews
are preserved; a fresh push run must establish the real result.

The archive keeps the frozen original failure report, full job log, source and
artifact metadata, exact fixtures, Root-viewed original PNG, complete repair and
red/green logs. Every included member is byte-verified. archive-index.json binds
the separately retained original 276,006,399-byte ZIP and two additional PNGs.
Original failure status and the different QA/APK/Native identities remain explicit.
Earlier motif/toolbar repairs and producer history remain in host-51e-creative-qa.

## Original XML line endings

The complete staged default whitespace check reports only 424 original CRLF
terminators across the four exact XML fixtures. The earlier unstaged check did
not include these then-untracked files. Their bytes remain unchanged. All other
paths pass the standard check; only these four original XMLs are separately
checked with cr-at-eol plus the normal whitespace rules. The original diagnostic
and Root correction are preserved in the archive. No global Git setting changed.
