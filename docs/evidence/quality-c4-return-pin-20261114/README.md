# Next candidate: approved C4 return retry source

This source checkpoint extends the separately merged integration state `81289b390f1aacf49a888e2055aac94d98d0697e`. It does not move the live candidate branch or change the ongoing 803a run.

The native source changes from `0e26153f0e58cc05739e72923b4c563a4cf380b8` to its direct child `f0c19f9eb69ea330ac5d2b8f9948cb029ca218aa`. The latter has two functional changes (17-line production delta and the new regression) plus two evidence documents. Root reviewed the exact Git comparison and opened both new original regression logs. Independent execution used identical test bytes: baseline exit1 /20 checks /3 failures; corrected source exit0 /21 checks /0 failures. The count differs because the unchanged final loop inspects actual return attempts. The test uses real native scene/action/polling with an explicit Android-host fixture; it is not a device or renderer acceptance.

The [complete independent evidence](https://github.com/Ullmann27/lumo-godot/tree/556faff3076baa93bcaf33980d11c99077a50d33/docs/evidence/native-c4-return-independent-20261114) retains both raw logs, provenance and the actual isolated import log.

Only the current unreleased 2020 native identity is updated. All historical identities remain unchanged; a new negative case rejects the previous 2020 source. The existing full native workflow gains a mandatory bounded execution of the original 21-check regression, with fresh separate user-data/config/cache paths, exact PASS marker and engine-error rejection. Existing project/legacy/2014/technical-art/action-stage/52-mode commands, original artifact preservation, APK, actual Android and update gates remain unchanged.

Host policy/workflow contract verification is pending on this committed checkpoint. It still requires its own complete Flutter, native, APK, Android and update acceptance before delivery. The successful native overall step in the ongoing run43578509499 belongs exclusively to host803a/native0e261.

## Initial host integration verification and narrow correction

On committed source `1f7b5d2bbbd63690f6511432fa893e8876818eb8`, 119 targeted policy/workflow/delivery tests ran. Exactly one strict workflow-preservation comparison failed because the new command had been inserted into the historical native-step body. Actionlint and Bash syntax passed. The original failing log and result are retained in `initial-contracts/`.

The correction restores that entire historical step body byte-for-byte and adds a separately named mandatory step immediately afterward. Delivery metadata now explicitly requires that new step to have succeeded. The new step binds the checked-out native SHA, rejects tracked source changes, uses separate user-data/config/cache directories, requires one exact 21-check PASS marker and rejects engine/script/parse errors. No existing preservation assertion is removed or weakened. Verification of this corrected source follows on its own committed checkpoint.

## Actual corrected host contracts and subsequent shell counterexamples

On committed checkpoint `968e59d947efae8bfb36d86f0ecf48475d741714`, all 119 focused policy/workflow/delivery tests passed in 0.904 seconds. Actionlint and syntax checks of both the unchanged historical native step and separate return step passed. The source index was unchanged and tracked files were clean. The original logs and exact shell bodies are preserved in `corrected-contracts-968e/`.

A separate, independently reviewed regression then executed the actual new shell body using real Bash, Git, timeout, tee, grep and Python. Only Godot was replaced by an explicitly labeled process fixture. The identical test executes 11 methods / 24 shell invocations. On 968e it exposed three failing negative cases: a clean source HEAD change during the process, PASS21 together with FAIL21, and PASS21 together with PASS20. Those original red records are retained under `../c4-return-shell-contract-20261114/`. These are host guard counterexamples, not observed native-engine behavior.

This checkpoint adds exactly two guard statements to that separate step: it requires exactly one return-result marker in total, and it re-binds the final native HEAD to the configured revision. The historical full-native step and existing source-diff checks remain unchanged. The new regression is committed with its original bytes; its successful execution against this correction is still pending. No full Flutter, native, APK, Android or Play approval is inferred from these host contracts.
