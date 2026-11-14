# English, Memory and Quiz feature integration

Status: source development on 14 November 2026. This branch starts at Studio Host ae1ba5e68438e0acc89b4df92650d28c9328bed4. Protected Main and the separate Studio 2020 candidate are unchanged. Neither this source branch nor its Native counterpart has an approved combined APK.

## Current product changes

English object activities reuse the existing learning entry point, per-child help record and return path. The Native gallery contains movable, real 3D objects for ten current vocabulary activities. The writing trainer, journal, speech data, child profiles and existing wallet data have no migration in this work. Pronunciation audio and installed Android behavior for the new gallery remain separate acceptance requirements.

Quiz retains the existing rules, question bank and milestone rewards. Its shared Dart controller persists each owned round before acknowledging Native input. Flutter and the new Godot scene render that authoritative round. Native preparation keeps Flutter answers usable; an unavailable optional renderer does not cover controls with a snackbar. The ordinary wallet limit remains unchanged; the dedicated Quiz settlement path validates the allowed round identifier and exact milestone amount, serializes the update and deduplicates retries.

The actual Memory screen now uses the shared persistent controller and attempts the real Android table entry. Optional Native preparation keeps Flutter cards usable; a real Flutter turn cancels a delayed automatic launch. Original visual widget sections, motif dealer, opponent behavior, reward formulas and per-child statistics keys are preserved. Unfinished rounds resume under their original identifier; confirmed completed and rewarded rounds start a fresh round with the same settings when reopened. An unsettled completed round is retained until its reward acknowledgement succeeds.

The Memory scheduler uses a monotonic Stopwatch in production, so a gap between Flutter frames cannot extend a visible-card delay. Tests can supply an explicit clock. Eight new widget scenarios cover absent Native support, delayed availability, unfinished-round resume, lifecycle pause, profile isolation and elapsed time without an intermediate frame, two immediate real card taps, and a delayed optional haptic reply. These new scenarios have not executed before this source checkpoint.

The private Android table channel binds game, token, child, round, revision and intent sequence. The renderer cannot supply rewards or choose the authoritative answer. Both new table sessions now invalidate pending setup on close, reject a parallel open, recheck ownership after asynchronous setup and clean up only their own token if native acceptance arrives late. Three additional real Completer-controlled cases per authority cover those close/open races. The 2,500 ms lease and persistence acknowledgement requirements are unchanged.

## Optional haptic reply correction

Host34386895dcc2d2d21f5d9223b7e8edb8753a6c0d passed the actual 30-case/1,694-check Memory authority contract, seven scheduler cases and Android compilation in run43602349929. The focused Memory widget group still failed: 20 passes and eight failures; the full suite did not run. The new board-loading and queue cases are not a full UI acceptance.

After a durably acknowledged card flip, optional haptic feedback is now detached from the action queue. A missing or delayed platform response cannot hold the next card or Pause; a later platform error is contained. The new eighth widget scenario deliberately leaves both actual HapticFeedback channel replies pending, requires two saved card selections and a saved pause, and then checks that completing the feedback cannot resume the game. This new delta still requires actual CI. No game timing, difficulty rule, assertion or existing test was weakened.

## Correction after the first actual Memory screen run

Exact Host ddc9d89ef1bb6fc37315fd4aff0da166ce213b67 failed its focused Memory UI step in run43600938811: 13 passes and 14 failures, then the complete Flutter suite was skipped. Its separate actual authority job passed Memory27 cases/1,675 checks, scheduler7 cases/13 checks and Quiz28 cases/1,786 checks. Actual Android compilation passed. These positive core results do not erase the widget failure.

The new correction releases an idle completed owner-queue tail without removing any newer pending write. It retains at most two actual card selections in order while each durable save finishes. An explicit screen setup may configure a never touched, unpaused round; normal reopen, begun rounds, deliberate pauses and unsettled rewards stay protected. Three additional pure contracts and one additional widget scenario cover these boundaries. Existing tests were not loosened or removed. The new 30-case Memory contract and seven new widget scenarios require fresh CI execution.

The real Memory Dart/Godot pair driver is now included. Its disk transport, deterministic clock, private test deck plan and award ledger are explicit QA adapters. It does not install Android or write a production child's save. Actual pair execution remains pending.

## Actual preceding evidence

| Exact source | Actual observation | Scope |
| --- | --- | --- |
| Host bdd86f289a165ea5140a01607d78fcf4c31c98c6 | [Run 43597316639](https://github.com/Ullmann27/lumo-lernen/actions/runs/43597316639) passed: 2,595 complete-suite Flutter tests, zero failures or skips; 546 generated PNGs; separate 46-test Quiz regression; Android class compilation and 28 transport contracts. | This predecessor does not certify the later Memory changes. Generated PNG count does not mean all images were manually reviewed. |
| Host 50f2a0edf87a0e22f24345d8504f4d83e803bf37 | [Run 43599036990](https://github.com/Ullmann27/lumo-lernen/actions/runs/43599036990) completed successfully in all three jobs. Its freshly read full Flutter log records 2,595 passes, zero failures/skips and 546 PNGs. The Memory round contract passed 24 cases/1,664 checks and the scheduler passed 7 cases/13 checks, zero skips. | These results precede the current UI hookup, monotonic clock and close/open corrections. They do not certify the new source delta. |
| Native e4e5ce03e644a2f23b01a96f1d340a882a1798c4 | [Run 43598637301](https://github.com/Ullmann27/lumo-godot/actions/runs/43598637301) produced 10 English renderer PNGs and 1,115 successful Godot checks using the actual Dart producer. All ten images were individually reviewed. | The complete job failed at the following Quiz pair step. Its valid paused initial round did not satisfy the immediate-play gate. A visible Resume interaction is being added to the test; no deadline is relaxed. |

The original Host bdd86 Flutter ZIP is 343,010,045 bytes, SHA256 22eebaca28f20260013060cf9d31503370b1f157c4bb075f2f94076bcae6adae; all 591 ZIP members passed local CRC verification. Independent event parsing distinguished 2,595 actual tests from loading and setup/teardown events. Host50f2 artifact metadata reports 343,097,020 bytes and SHA256 b3471a32a7eaed519fe2be1daceb7931cdfad89c0c4dcb917a3042c30c423869; those archive bytes have not yet been downloaded for local verification.

The earlier Host1a903 failure remains recorded: 17 Quiz-related Flutter failures. Later green runs do not replace that negative evidence. Native work is tracked in [draft PR182](https://github.com/Ullmann27/lumo-godot/pull/182); Host work is tracked in [draft PR503](https://github.com/Ullmann27/lumo-lernen/pull/503).

## Required validation for this delta

LUMO Nextgen feature source acceptance runs the exact checked-out source through the existing locked Flutter toolchain, all Flutter source analysis, focused Quiz and Memory widget regressions, the complete existing Flutter suite with captures, actual Android Kotlin/Java compilation and private transport contracts. A separate fast job executes both table authorities and the Memory scheduler, retaining each result even if another fails. This workflow does not export or publish an APK.

The Native source pin, new current renderer review, actual Dart/Godot pair, installed Android input and return, per-child persistence, update preservation and device measurements remain independent gates. Desktop file-transport roundtrips replace only the Android transport boundary; they do not prove installed-APK behavior, physical Fold7 frame rate, heat or input latency. The previous Native344 renderer receipt does not authorize these additions.

## Recovery and reproducibility

The local executor became unavailable around 12:30 UTC on 14 November. The first feature checkpoint preserved only 31 complete, read-back source files. The Native344 baseline was subsequently restored from an immutable source archive, with all 2,237 file bytes and Git blob identities checked. New Native and Memory work was reconstructed on that verified baseline. Earlier lost uncommitted implementations and tests are not represented as current evidence.

Local Flutter dependency recovery is not used. Flutter dependency resolution and execution take place in the explicitly scoped GitHub workflow. Every feature ref update uses an explicit file manifest, full text readback, recursive tree comparison and an expected-head lease. Main remains protected.
