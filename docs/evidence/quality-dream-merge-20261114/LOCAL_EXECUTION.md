# Actual committed-source checks

Executed on Host `dc966e8e4e4f69c5cb19e53822625025bb0fe766`, tree `883461f7827d92eb4175b191bb66202a98251f60`, pinned Native `e2d15dbc5f3709306decb139eeb70a1cf30c0b73`.

The ten relevant Python modules actually ran: **237 tests, zero failures/errors/skips**, reported duration **26.816 seconds**. The original combined log is `execution/combined-contracts.log`, SHA-256 `f2e2f2f530e0b2eae293c2fdaea9ba8432c21a1dea11d516814defd1364f2ec4` (49,160 bytes). Actionlint passed on the complete merged C4 workflow. Bash syntax checks passed on the four preserved native run blocks and the additional Dream block extracted from the actual YAML. Exit codes, exact commands and original log identities are in `execution/result.json`; the original executable driver is `run_committed_source_checks.py`.

The original HEAD/tree, tracked status and Git-index digest are identical before and after. The Android test sibling directory is explicitly placed on PYTHONPATH as in normal discovery; this correct invocation follows the documented earlier dfc3 setup mistake without changing any assertion.

This final activation commit adds only documentation and original evidence to the tested merge tree. Product, test, policy and workflow blobs are unchanged. Full Flutter/rendered Native/APK/Android/update/delivery acceptance on the actual final PR head is still mandatory. The targeted Python run and syntax checks do not supply rendered, device, performance or publication proof.
