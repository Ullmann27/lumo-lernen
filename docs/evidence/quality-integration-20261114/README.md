# Current integration merge verification — 2026-11-14

The preserved source is `c1fef2d548ceaf42ccde8c8d8553d81f8400c349`,
tree `a2c9c60f56d536241ccc6ac84d8bf90b26734044`. Its parents are the actual
quality candidate `95f12c7173e6ee718b03dce67ca2d7c6543fe716` and concurrent
integration `729585db3f49ecff7f0632439f90edb882f09454`.

- All 123 focused Python methods passed on that committed source.
- Both changed workflow files passed actionlint.
- The actual Dart audit generated 7,552 rows in 236 families. The production
  `checked_learning_outputs` reread every row and passed without modifying it.
- `original-learning-audit.tar.gz` contains all six original outputs, including
  the unabridged JSONL rows. Their original byte identities are in `review.json`.
- These checks occurred locally. No CI run ID, Android result, curriculum
  approval, Play acceptance or physical-device performance is implied.

The first contract invocation occurred while the merged index was already
updated but local HEAD was still the previous candidate. The immutable-helper
check correctly rejected that source mismatch. It produced one error and four
failing subcases from one test method. Both its log/result and the subsequent
unchanged-code committed-source pass are preserved. No production gate was
relaxed to obtain the pass.

The autosave helper could not switch branches during the pending merge
(exit 2). The exact complete index was instead preserved through Git Data on
`checkpoint/lumo-quality-integrated-20261114-2708` before the final checks.
