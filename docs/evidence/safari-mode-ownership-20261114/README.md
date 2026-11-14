# Safari continuation ownership repair — source checkpoint, widgets not yet run

Base: `9c5a14d73679f68249d31db5401c489094ccf903`, tree `34506c87f4d66f97612caf95d345b4fa5186655f`. This isolated patch changes exactly one production method, its existing feature test harness, and that harness's strict workflow count. No central branch, Android binary, native source, Drawing, WritingCoach, Journal or Wallet implementation is changed.

## Observed source defect and minimal correction

`_handleSafariAnswer` previously waited 2200 ms after a correct answer or 2500 ms after a wrong answer, then checked only `mounted` and the profile lease. A mode switch leaves those checks true for the same child, allowing the old response to start another Safari question in the new mode. Returning to Safari before the timeout also creates a new interaction that must not be advanced by the old response. The same unguarded continuation already exists in parent `1e22`; it was not introduced by this merge.

The method now captures `_modeRevision` before its asynchronous continuation and checks the existing `_isCurrentInteraction(revision, owner)` after either delay. Reward amounts, the moment of their award, answer assessment, messages, delays and every other production byte remain identical to the exact base. The existing guard also retains profile generation/reset/session ownership.

## Eight new widget contracts

For both a correct and a wrong spoken answer, the tests cover:

1. Switching to Word Magic before the old timeout: its message and absence of a Safari animal must remain intact.
2. Leaving Safari and returning before the old timeout: the newly entered first round must not advance.
3. Staying in the same Safari with the same owner: the next round must still start exactly once.
4. Switching the active profile before the timeout: the old response must not start another question or award another reward.

The test taps the visible Safari and Speak controls, reads the actual displayed animal glyph, and feeds a final recognition event through Flutter's documented platform-message boundary. The real locked speech plugin, real `LumoSpeechListener` and real screen callbacks handle that event. No private screen state or handler is invoked. Correct-answer cases dismiss the actual reward route through its visible `+10 XP` content before tapping a mode. The transition occurs after 500 ms of explicit widget time, below both production delays. The tests then cross both deadlines, check the actual displayed result, flush the real wallet writes and require unchanged earned rewards.

The speech protocol was checked against the exact archive SHA256 values for locked `speech_to_text 7.5.0` and `speech_to_text_platform_interface 2.5.0`; `resultType=2` and `textRecognition` are defined in those sources. The test messenger API was read from Flutter `3.44.9`, Gitblob `996d3d8f339a2bf1baf32c1fdd816297f7d5e818`. These were small source downloads, not an SDK setup or runtime test.

## Actual verification and boundary

`source-check-original.log` and its executed driver prove that production changes consist solely of one revision capture and two delayed guards; every original feature test body remains byte-identical. The workflow changes only its descriptive label and the two required count literals, from 22 to 30. Its existing trigger, exact-source binding, zero-error/zero-skip checks, asset checks and before/after source preservation are unchanged. YAML and the changed embedded Python summary were parsed and compiled successfully.

The 30 required cases are 7 Diktat cases, 20 permission/Live cases (12 original plus 8 new), and 3 profile cases. This is a count derived from the source, not an executed result. No Dart compilation, widget RED/GREEN run, Flutter rendering or Android validation was available locally. The exact final CI must execute these tests before acceptance. The separate unchanged-APK Garage diagnosis is unrelated and remains on its own 1e22/e9a9 source binding.

## Host-union review preceding this repair

The three-way read-only review of all 846 `lib`/`test` paths in 9c5a, against parents 1e22 and 057 with common base aab09275, found no omitted one-sided change. Its three semantic conflicts are the retained producer Diktat screen, producer Diktat gesture tests plus explicit `dart:typed_data`, and producer Deutsch/Sach progress tests plus the existing `hitTestable` assertion. The shared Ink and legacy Letter canvas preserve the exact 1e22 blobs; original WritingCoach, word coach, 1236-line practice board, Journal, Wallet, module progress and their routes match both parents. This source-preservation result is not a new runtime acceptance.
