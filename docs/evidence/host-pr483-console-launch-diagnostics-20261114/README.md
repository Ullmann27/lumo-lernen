# PR483 failure-only launch diagnostics

This is a separate follow-up to the frozen LF parser repair. It changes only the failed `CONSOLE.start` handling in the existing start function and adds bounded read helpers. All 27 other existing top-level definitions, including both device launch scripts and every acceptance gate, remain AST-identical.

Six fixed read-only ADB commands inspect the same validated private session: launch.stdout, launch.stderr, session.stdout, session.stderr, logcat.stderr and a small current UID/init/executable/PID/ready/exit observation. The command budget is 8 seconds total, at most 2 seconds per command, with 0.2 seconds reserved inside the overall deadline for cleanup. Raw stdout plus stderr is capped at 64 KiB per command and 256 KiB overall. Receipt serialization is local and follows the external-command budget.

Every attempted command records original separate stdout/stderr, real return code (or null if unavailable), timeout, byte-limit and collection-error status. Limited output is an explicitly incomplete original prefix. Failed collection never converts a launch to success or replaces the original start exception. No root, reconnect, clear, retry, cgroup mutation or new launch is performed by this attachment.

The original framework lacks all three diagnostic reports (three preserved KeyError errors). The new nine targeted local contracts pass with zero skips. Their Python subprocesses explicitly simulate adb output for capture-limit tests; no Android/console success is claimed. The original three Exit1 observations are reused byte-for-byte from the separately frozen parser fixtures.

The exact failed command inside the real launch remains unknown until a new device attempt supplies these missing originals. `source-freeze-v1.json`, `validation/`, and `handoff.json` bind the source, original red and focused green. The first parser stage and all active QA sources remain unchanged.
