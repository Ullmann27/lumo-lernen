# Published Host followup integration evidence

The working base is fd0d777e6a8bdb489d58efd93d42d08cee0f65f2, tree86e6ed0f439b9ec8fda6d83d6f1e7d0c5e24b3b1, in the isolated integration/lumo-host-followups-20261113 worktree. Root owns commits, refs, the common full-suite gate and the separate Native review-contract edits.

## Implemented scope

PR469/a5e03117158c157ba3154083db25947724e67727 supplies the actual historical APK verifier, its15 tests and its workflow changes. The verifier and tests are byte-identical to that published source. The workflow adds immutable expectation files from commit c60bff1a9e7a6bdcb077b5f3d5886fcee8fe4eaf while retaining our existing exact repair-branch, repository and fork guard. Current signature, ABI, PCK, voice, alignment and resource checks remain active. Historical inputs are read from exact Git objects, not mutable checkout files or executed historical verifier code.

The explicit2020 wrapper is byte-identical to published PR468/1f47a96116e22a4c0c1fab655d0db165c461736e. Integration preserves the existing shared reviewed_migration_versions function and adds the strictly typed, mutually exclusive allow_2020/(2017,2020) option. The common runner forwards that flag;2018/2019 wrappers and their original2019 regression file remain byte-identical. The only previous negative pair replaced in the shared preservation tests is now-unreserved2020 with still-unreserved2021. The existing evidence, ownership, fields, rewards and later byte-preservation rules remain unchanged.

The new2020 tests run the unchanged original evidence invariants for the2020 pair, reject wrong pairs/types/multiple flags, and execute the real wrapper until a deliberately blocked Android boundary. Its happy-path metadata fixture uses a temporary copy of the actual policy code with an explicitly synthetic2020 entry. It does not modify production APPROVED. A separate case uses the real unchanged policy to reject an unreviewed2020 source. No2020 version/pin/receipt or incomplete release workflow is adopted.

## Actual validation

The focused preimplementation run records two real missing interfaces: the historical CLI arguments and allow_2020. The same two tests pass after implementation. An earlier dotted-module invocation omitted the sibling test-fixture import path; its untouched log is stored as initial-invocation.log.gz and is not presented as a product defect.

The complete affected gate ran86 tests in1.044s (1.250s subprocess), with exit0 and no failures/errors/skips. It includes the15 historical expectation tests, current APK signature/ABI/voice checks, the historical workflow scope, and existing2018/2019 plus new2020 preservation/wrapper checks. The24 exact consumed source/test/fixture files were unchanged before and after. actionlint on the one changed historical workflow returned0 with an empty log. The command, import-path environment and timestamps are in the result JSON files.

The original log retains eight ResourceWarning occurrences caused by the existing unchanged file_digest(path.open(...)) expression in the published APK verifier. Nothing was filtered or suppressed. These warnings did not fail any test; the exact prior source line is recorded in after.json.

## Ownership and evidence

Eight owned source paths, original/final blobs and SHA256 values are listed in before.json and after.json. Full original/final source snapshots and the exact complete integration patch are preserved. Root's four concurrently edited Studio/Nextgen-review files are explicitly outside this agent's source/test binding. All12 protected version, pin, receipt and2018/2019 paths are unchanged.

The sibling producer-pr469-a5e03117 directory preserves all24 original producer evidence files with their exact paths, blobs and hashes in a deterministic archive. Those historical producer results are separate from this integration gate. This directory contains the actual new integration logs and does not reinterpret producer results as current evidence.

All .gz files are lossless; the manifest records both stored and decoded-original hashes. No local APK build, Android device interaction, renderer review, visual receipt, version decision or release approval is claimed. No whole-repository test suite was run by this agent while Root's review-contract files were still changing.
