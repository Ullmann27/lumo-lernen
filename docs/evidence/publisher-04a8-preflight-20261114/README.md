# Inactive publisher preparation for Host 04a8e850

This is a prepared workflow and read-only preflight, not a publication or release approval.

## Exact binding

- Host: `04a8e850d4c198e16ff758df614ce6e53eab4524`, tree `80a797c2b547ed72fc496600f7959f6ac4f5f9e6`.
- Complete C4 acceptance: `43628840534`, attempt `1`; still running when this preparation was checked.
- Feature acceptance: `43628830465`, attempt `1`, job `132550661600`, artifact `14126808268` (1,169,894 bytes; SHA-256 `a6ae2c6ae9e4b0e8b600bdd54687288ec6d229ae2cf20b28df128c28658de805`). Fresh original API metadata are retained here.
- Native binding remains exactly `84789d0c2c6fb4b6ecd2897ce1951b89f958b604`, Discovery run `43613299144`, attempt `1`, job `132502826135`, artifact `14122180486` and its unchanged digest. Fresh metadata were checked against the existing binding.

## Preservation

Reference: publisher commit `361f409f4bded479858e392aff8494863c4c0b1a`, workflow blob `c4a901a649f49b80cd16e22ece3c40b1a3cbd12d`.

Only the exact Host source, main run and Feature source/run/job/artifact bindings were replaced. BINDINGS field order and every Native value remain unchanged. Reversing those explicit substitutions produces the complete original workflow and helper byte for byte. The 51-contract test file is unchanged. `binding-only.diff` and `source-binding-and-preservation.json` record the exact delta.

All existing publication gates remain, including the exact seven successful Host jobs, eleven assets, unchanged bundle and source checks, a fresh original-APK verification using the actual Android tools, test-certificate/version/provenance checks, fresh additional Native/Feature metadata before delivery handling and immediately before publication, fresh release/tag vacancy, uploaded-draft checks and unauthenticated public-byte verification.

## Actually executed

- The existing 51 positive/negative metadata contracts passed, zero skips.
- The exact new embedded helper replayed the freshly read original metadata from an actual clean sparse checkout at Host04. Only `config/godot-source.json` was materialized; existing Git objects were shared without modifying their owner.
- YAML duplicate-key checks, eight Bash run blocks, four Python heredocs and actionlint passed.
- The source HEAD, tree, Native pin and clean status were identical before and after.

The raw logs, exact test/helper/driver source, syntax blocks and fresh original API metadata are included. No workflow command, APK/emulator run, tag, release or delivery branch was executed by these local checks. The complete current Host acceptance and the separate original-artifact replay remain mandatory before Root may activate publication. Older 6b acceptance is not substituted.
