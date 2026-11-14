# Next candidate: approved C4 return retry source

This source checkpoint extends the separately merged integration state `81289b390f1aacf49a888e2055aac94d98d0697e`. It does not move the live candidate branch or change the ongoing 803a run.

The native source changes from `0e26153f0e58cc05739e72923b4c563a4cf380b8` to its direct child `f0c19f9eb69ea330ac5d2b8f9948cb029ca218aa`. The latter has two functional changes (17-line production delta and the new regression) plus two evidence documents. Root reviewed the exact Git comparison and opened both new original regression logs. Independent execution used identical test bytes: baseline exit1 /20 checks /3 failures; corrected source exit0 /21 checks /0 failures. The count differs because the unchanged final loop inspects actual return attempts. The test uses real native scene/action/polling with an explicit Android-host fixture; it is not a device or renderer acceptance.

The [complete independent evidence](https://github.com/Ullmann27/lumo-godot/tree/556faff3076baa93bcaf33980d11c99077a50d33/docs/evidence/native-c4-return-independent-20261114) retains both raw logs, provenance and the actual isolated import log.

Only the current unreleased 2020 native identity is updated. All historical identities remain unchanged; a new negative case rejects the previous 2020 source. The existing full native workflow gains a mandatory bounded execution of the original 21-check regression, with fresh separate user-data/config/cache paths, exact PASS marker and engine-error rejection. Existing project/legacy/2014/technical-art/action-stage/52-mode commands, original artifact preservation, APK, actual Android and update gates remain unchanged.

Host policy/workflow contract verification is pending on this committed checkpoint. It still requires its own complete Flutter, native, APK, Android and update acceptance before delivery. The successful native overall step in the ongoing run43578509499 belongs exclusively to host803a/native0e261.
