> **Later verified result:** The identical test passed on committed Host `faaf9d906bd72c2ffe9ab677c76355fe538cddfe`: 11/11 methods, 24 actual shell calls, exit 0. See [GREEN.md](GREEN.md) and the original `green-faaf/` records. The 968e red evidence below is historical and remains unchanged.

# Actual C4 return gate counterexamples on Host 968e

This is an execution record for the new Host shell-step regression. It does not claim Native, game, APK, or Android acceptance.

## Exact source and execution

- Host source: `968e59d947efae8bfb36d86f0ecf48475d741714`, tree `bb8a36f40622cabde90a0814d03852b12ab40762`.
- Unchanged workflow blob: `5d9a4fdff77320be466fa8a777ab0c13502c0b86`.
- Unchanged Host Native-pin blob: `3f24f85434618cf26af87ed977c884dae8bd064a`, which pins `f0c19f9eb69ea330ac5d2b8f9948cb029ca218aa`.
- New test: `scripts/tests/test_connect_four_return_gate.py`, blob `a3a76bcc9949af22d9be8abdce2e30065b97dddc`, SHA256 `c7253c73f4c56d38dafcef150223ff340518e2ae819db8c03614f924f63f827f`.

Only exact source files needed for this test were copied into an isolated directory. This was not represented as a full checkout. The workflow, pin, and test bytes were hash-checked before and after the actual execution and remained unchanged.

The test extracts the actual literal shell body of “Require acknowledged Connect Four return retry” from that workflow and executes it via real Bash. Git, timeout, tee, grep, and Python are actual installed programs. Only the `godot` executable is replaced by an explicitly labeled private-path Python fake; its invocation arguments and XDG directories are captured and checked.

Each case uses a genuinely initialized and committed temporary Git repository with the two protected tracked paths. Its synthetic pin JSON names that fixture's real Git HEAD. These fixtures test Host source binding and process handling; they do not execute the Native f0c19 game code. Fixture paths contain spaces to exercise the actual shell quoting.

## Actual red result

The original result is **11 unittest methods, 24 real shell invocations, 1.499 seconds, three failure cases, zero errors/skips, process exit 1**. The raw report and all invocation records are retained without editing.

All requested ordinary cases behave correctly: exact successful marker and target invocation/XDG paths; missing, wrong, or duplicated success marker; an old successful log that must be overwritten; engine error on stderr after an otherwise correct success marker; nonzero engine exit despite that marker; incorrect pinned revision or native HEAD; and staged/unstaged edits of either protected file before or during the fake engine run.

Three negative cases reveal two actual acceptance gaps in the unchanged step:

1. The fake engine changes a protected source file and commits it. The resulting Git checkout is clean and has a different HEAD. The original step nevertheless returns 0 because its final check compares the two files only with the new HEAD, without checking that HEAD against the configured pin again.
2. A correct `CONNECT_FOUR_RETURN_PASS checks=21` line together with `CONNECT_FOUR_RETURN_FAIL checks=21` returns 0.
3. A correct `CONNECT_FOUR_RETURN_PASS checks=21` line together with `CONNECT_FOUR_RETURN_PASS checks=20` also returns 0.

The latter two cases show that counting exactly one correct marker does not reject additional contradictory return-result markers. They are synthetic Host counterexamples, not evidence that the real Native regression produced such contradictory output.

The test deliberately requires rejection and remains red against 968e. No expectation was weakened, no production workflow was patched by this agent, and no quality branch or ref was changed. Root has the results for a narrow step-only guard improvement. A later successful execution must identify its own corrected workflow source; this red record remains historical evidence.

## Original records

- `red-968e/unittest.log`: original unittest output.
- `red-968e/execution.json`: actual source hashes, executable locations, timestamps, command, and all 24 shell return codes/stdout/stderr/logs/fake invocations.
- `run-targeted.py`: the executed recording runner. It records results without replacing or rewriting the tested workflow step or test assertions.
