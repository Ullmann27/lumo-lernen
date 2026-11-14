# Current source-change review originals

Run `43616314410`, attempt `1`, source checkout `6b3047b7979dfb86d837e74a21b0fd890e4f9e66`: all three jobs succeeded. Three original decoded job logs are archived unchanged. API metadata is parsed and reserialized, not raw HTTP bytes.

The actual analyzer reports **0 errors, 4 warnings and 149 informational lints (153 total)**. All four warning-bearing files are byte-identical to producer `057a4e8d067872c4f3514b126aa04c3706d2e5b5`; their exact blob comparison is recorded in `independent-review.json`. Nothing is suppressed or described as warning-free.

The auxiliary ordinary Flutter run reports **2,449 passed and 202 skipped**. It does not substitute for the separate authoritative current full capture-enabled suite: **2,651 passed, zero failed/skipped, 566 PNG**.

These additions preserve the live accepted source and the earlier nine auxiliary originals. No new run, source change, main update or release is triggered by this evidence-only checkpoint.
