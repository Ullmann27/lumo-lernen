# Complete integration verification before producer publication

The combined graphics/native verifier originally lived inside the producer-only
publication job. That branch boundary correctly blocked APK publication from
our integration PR, but also skipped its final acceptance of the original native
archives and both Android platform tours.

The graphics 2019 workflow now has an independent `verify-reviewed-2019` job.
It accepts the two internal candidate PR branches and requires successful build,
host compile, Android API 35/37 matrix and 2017-to-2019 preservation update jobs.
It checks out the exact PR head and runs the complete existing verifier, with
fresh source-bound original native evidence and the separate graphics and native
visual reviews. Its GitHub token has read permissions only.

Only a successful final verification can upload the verified delivery artifact.
The separate producer-only publisher depends on that job and all four original
jobs, downloads that exact same-run artifact and rechecks APK bytes, digest,
Host SHA, Native SHA and version before its existing create-or-verify release
path. Our integration branch cannot enter that publication job.

The existing immutable-release and public-download verification remains in the
publisher. The original review proofs and both visual receipts are retained in
the independent acceptance artifact even when the publisher is skipped.
Manual workflow dispatch remains ineligible for final review/publication; the
automatic internal integration PR is the intended complete verification path.

## Checks and current limits

Seventeen focused delivery/workflow tests and seven published graphics-review
tests pass with no skips. The delivery tests evaluate both successful branch
conditions and their failed-job, foreign-fork, main-branch and manual-event
rejections. Actionlint also passes. The exact files and losslessly compressed
raw logs are in `docs/evidence/integration-20261113/independent-final-verification/`.
These local parser and workflow checks are not Android or renderer evidence.

The latest completed Host Studio evidence (`a0e860211e49d2571b89291e637e0444e0bf3d8d`)
and graphics contract (`71bd9ec7f3cbdc07dc2cd708c682c6dbf041cf65`) are integrated.
Studio's measured workshop targets below 48 dp remain an open producer finding.
The stricter graphics review requires the original `preview-resolution.log` and
`winter-visibility.log`; older archives without those logs cannot satisfy it.
No source pin, visual approval or release is granted by this workflow repair.
