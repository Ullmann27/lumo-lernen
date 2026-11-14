# C4 return observer: original evidence and bounded fix

Candidate: `9deaa3f24561bc65caba898585c0c00f1c77162b` (tree `c0a9e29c831113ea8e49e632bc7959a15079bc94`).
Current full acceptance: [run43622379532, attempt1](https://github.com/Ullmann27/lumo-lernen/actions/runs/43622379532), still pending at this checkpoint.

Parent candidate: `7c5bef2bc39024fc2c1018523cabc651820cf76b`.
Native source remains `bebf7bba48f09afc834469db0ea3c5541a184f55`.
The candidate changes the Android C4 observer and adds one regression module plus 25 fixture/provenance files. It does not change application or native gameplay code.

## Actual failed diagnostic

Run [43616584326, attempt 1](https://github.com/Ullmann27/lumo-lernen/actions/runs/43616584326), job 132512855551, used diagnostic source `cd03e1e2da22efa2e982795cddc12217f821b14b`, unchanged app `51ec0ac43f3e2aaac065e285e13cf5db5b5875d2` and observer `7c5bef2bc39024fc2c1018523cabc651820cf76b`.

Original artifact 14122019894 is 140850732 bytes, SHA256 `03dbde65dba65c00d3b36f0283d3d66fee7778d9bd176005c66e470c16eeaaaa`. The original archive was fully hashed and all ZIP CRCs checked. All 1335 C4 inventory files matched their original recorded bytes and SHA256. The separate live xvfb.log was longer than its inventory snapshot: its first 3522 bytes matched that snapshot; the archived file had 4696 bytes. That discrepancy is recorded separately and is not asserted to cause the C4 failure.

All 21 main-tour steps passed. The diagnostic contains 25 complete C4 observations, six strict transitions, one completed return, and reopening of the same round with a new native process/session. All 28 actual preferences reads were valid XML. Thus this run does not demonstrate recovery from the earlier missing-XML observation.

During the final second return, a single stationary 120 ms Back touch was followed by native PID absence and a resumed/focused MainActivity. The next original full mailbox find still returned the current session's state.json. The run failed with `ValueError: Closed C4 mailbox still exists`. There was no later mailbox read. Neither eventual deletion nor permanent survival is established by this original.

## Source reason and narrowly bounded change

The reviewed product lifecycle closes the C4 mailbox in a later Dart session.close -> Android MethodChannel close callback. Native process exit and MainActivity resumption do not themselves prove that callback has finished. The close operation and late state writers share authority/locking checks. A successful close is protected from late recreation; a failed close can still leave a mailbox, so permanent remainder must fail.

The observer now checks native PID exit, the correct resumed/focused Flutter activity and the unchanged full mailbox search together within its existing 45-second local and 900-second global limits. Each attempt has fresh raw PID/activity/find evidence. Exactly one Back input remains. There is no mailbox deletion, additional input, increased timeout or relaxation of the final state/preferences/round/UI checks.

## Actual local regression and recovery limits

The unchanged 7c5 baseline was executed against the original final-return boundary and failed with the original mailbox ValueError after one input. The full red log was read before the executor failed; its then-recorded SHA256 was `c94635003d91dc3aa703c168bb87bff8cf843cdbed2013e7d7377e9ff9109040`. Its complete bytes were not recovered after the outage and are not recreated in this checkpoint.

The frozen corrected files completed 56 tests in 59.129 seconds: 47 existing cases and nine new return-observation cases. The completed command returned 0 with OK and no skips. The full local file had 11076 bytes and SHA256 `7a234316cb69c4a2ef1ae1ca5dfb96dfc74de09ea62597b20dbe64fa3c64c09b`, as recorded by the actual tool output before the outage.

Only the exact final 6500-byte output excerpt and the original 528-byte metadata line were recovered. The excerpt begins in the middle of a line. The stored full-log size/hash belong to the former complete local file, not to this excerpt. Missing leading lines are not reconstructed. Fresh CI remains required on the final candidate.

The new tests execute the real native_touch/original/return_to_flutter boundaries with controlled ADB and clock responses. Any later empty mailbox response and reused post-return preferences in the replay are explicitly synthetic; they are not Android runtime acceptance.

The 27 source entries in frozen-source-manifest.json were recorded before that successful test run. The completed [recovery43622102571, attempt1](https://github.com/Ullmann27/lumo-lernen/actions/runs/43622102571) matched every frozen Git blob before creating exactly15 missing unique blobs. Root then independently read all recovered immutable contents and recomputed all27 UTF-8 byte lengths and SHA256 values against the frozen table. The remote parent comparison contains exactly27 files; the complete app51ec-to-observer9de comparison contains exactly35 QA-only paths and no product changes. The recovery and candidate source bindings were independently reviewed.

The manifest in this checkpoint is a new JSON serialization of the path/byte/hash fields recorded before the local test, not a claimed byte copy of the lost local manifest file. The complete original recovery joblog and its exact receipt line are preserved here. The full device gates and publication requirements remain open.
