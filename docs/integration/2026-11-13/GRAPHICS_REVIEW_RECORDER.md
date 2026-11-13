# Original graphics review recorder

`scripts/record_kart_graphics_review.py` connects explicitly inspected original
images to the existing Graphics 2019 delivery verifier. The CLI does not inspect
art or infer findings. The reviewer supplies findings only for images they have
actually opened, after the exact final native workflow succeeds.

## Inputs and output

| Argument | Required input |
| --- | --- |
| `--root` | The host checkout receiving the reviewed originals |
| `--proofs` | Original `run.json`, `jobs.json`, `home-artifact.json`, `worlds-artifact.json` and `feedback-artifact.json` |
| `--home-archive` | Original Home artifact ZIP |
| `--worlds-archive` | Original Worlds artifact ZIP |
| `--feedback-archive` | Original Feedback artifact ZIP |
| `--selection` | JSON list with exactly `area`, `artifact_entry` and actual `findings` for each inspected image |
| `--reviewer` | The actual reviewer |
| `--notes` | The actual overall review findings and limitations |

The existing verifier requires Home in both orientations, Winter, Crystal and
Feedback. The three artifacts must belong to one completely successful exact
native workflow. Native revision, run/artifact identities, digests and physical
image dimensions are derived from the original inputs rather than supplied by
the reviewer. Previous-source images cannot approve the current candidate.

The tool checks the three complete ZIP digests, regular unique archive members,
CRC integrity, every manifested PNG's bytes and hashes, and full decoding of
the selected images. It stages the unchanged source/log/API metadata and calls
the unchanged `verify_kart_graphics_review.verify_visual_review` before touching
the destination. The output includes all 33 required original metadata files
and content-addressed PNGs under `docs/evidence/kart-graphics-2019-reviewed/`.

All file replacements and any required backups are prepared before installation.
The receipt `config/kart-graphics-2019-visual-review.json` is atomically replaced
last. A caught installation failure restores already replaced originals. If a
rollback itself fails, transaction backups are retained and the error names the
affected paths. A different file at a content-addressed image path is rejected
before any target is changed.

## Focused verification

The implementation passes 12 new recorder tests and all seven unchanged
graphics verifier tests: 19 tests, no skips, 1.810 seconds. Cases cover the actual
CLI, missing/wrong original sources, damaged images and unselected ZIP members,
duplicate/path-escaping/symlink members, content-address collisions, and an I/O
failure after metadata installation has begun. The rollback case preserves the
previous receipt and original metadata byte-for-byte.

The archive readers were also checked read-only against the actual cf039 Home,
Worlds and Feedback artifacts: 44, six and six manifested PNGs respectively.
That source's full workflow failed; these structural checks do not approve it.
No actual review receipt was created when implementing or testing this tool.

Original logs, exact file hashes and the read-only archive check are retained in
`docs/evidence/integration-20261113/graphics-review-recorder/`. The separate
Nextgen 2019 receipt, nine modules, three Touch groups, exact Android APK/PCK and
the two Android platform runs remain required by the combined delivery path.
