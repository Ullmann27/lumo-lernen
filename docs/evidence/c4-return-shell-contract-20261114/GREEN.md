# Actual green countercheck on Host faaf

The unchanged test file from the red 968e execution was run against the committed correction `faaf9d906bd72c2ffe9ab677c76355fe538cddfe` (tree `2a45b222762e2bb5c7b5be74d6eaefb7d71ff657`). The actual result is **11/11 unittest methods, 24 shell invocations, 1.432 seconds, zero failures/errors/skips, exit 0**.

## Exact binding

| File | Git blob |
| --- | --- |
| Corrected workflow | `6d281c42e2997a8a421721e9b80ff5d8e6439570` |
| Identical test used for both red and green | `a3a76bcc9949af22d9be8abdce2e30065b97dddc` |
| Unchanged Native pin | `3f24f85434618cf26af87ed977c884dae8bd064a` |

The test SHA256 remains `c7253c73f4c56d38dafcef150223ff340518e2ae819db8c03614f924f63f827f`. The actual recording runner verified workflow, pin, and test identities before and after execution. No source bytes changed during the run. The exact Host commit and tree were separately read from GitHub before staging the isolated source copies.

## What changed and what passed

The entire workflow diff from 968e consists of two additional guard lines:

1. Require exactly one line beginning `CONNECT_FOUR_RETURN_`, in addition to the existing exact PASS21 requirement.
2. Compare final Native HEAD to the configured revision again before the existing final source-file diff.

An independent second agent compared the complete committed workflow text and found exactly these two additions, with the original native aggregate step, timeout, pipeline error handling, source-file checks, artifact steps, and build steps unchanged.

All three historical false-accept cases now reject: a newly committed clean source during the fake engine call; PASS21 together with FAIL21; and PASS21 together with PASS20. The original successful case still invokes the intended script with the exact arguments and isolated data/config/cache paths. All other stale-log, missing/wrong/duplicate-marker, stderr-engine-error, nonzero-exit, wrong-revision, and staged/unstaged protected-source cases continue to behave as required.

The historical red files under `red-968e/` are untouched. `green-faaf/unittest.log` and `green-faaf/execution.json` are the original new execution output and all 24 detailed invocation records.

## Scope and reproduction

Only the actual workflow shell step was exercised. Its Bash, Git, timeout, tee, grep, and Python commands were real; Godot was explicitly replaced at the executable boundary. Temporary Git commits are synthetic source-binding fixtures, not the production Native game. There was no new engine, gameplay, Android, APK, or device-performance execution.

For normal reproduction from a checkout containing the corrected workflow and unchanged test, run:

```sh
python3 -m unittest discover -s scripts/tests -p test_connect_four_return_gate.py -v
```

The archived `run-targeted.py` records the actual local instrumentation run in its original staging layout; it is not an alternative production gate. The 119 preexisting contracts and actionlint are owned by Root and were not redundantly rerun by this test worker.
