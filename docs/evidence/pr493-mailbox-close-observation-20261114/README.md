# C4 mailbox closure observation — PR493 integration

This pack contains the exact 27 published producer paths from
9deaa3f24561bc65caba898585c0c00f1c77162b on the independently verified preimage
f8d4ae7cdd3c38f0240a2bc20c4d78b6108f9f5d. The only production change moves the
strict complete-mailbox query into the existing return observation loop.

After one unchanged actual Back touch, each retry reads native process and
resumed Activity afresh. Acceptance still requires native exit, the expected
MainActivity and an entirely empty session-root listing. The same 45-second
local deadline and 900-second overall deadline reject late acceptance.
The original writer, state/owner/round/ACK checks, XML handling, persisted
round checks, paused Flutter UI, games readiness and subsequent fresh touch
observations are unchanged. Failed command/stderr is not empty-mailbox proof.

The source was frozen before exactly one local run:
9 new Return tests + 9 existing Preferences + 17 Evidence + 11 Deadlines
+ 8 Navigation = 54 tests. Complete unmodified stdout/stderr, actual process
exit/timestamps, source/index inventories and the exact recorder are included.
The existing Pillow deprecation warning is retained verbatim in stderr.
No test was skipped and no device, engine, CI run or ref was changed.

The original fixture provenance is upstream diagnostic run 43616584326/1,
job 132512855551, artifact 14122019894. Its actual last query returned the
current state.json path; the old diagnostic remains FAIL. All 25 fixture
Git blobs were fetched and byte/SHA256/OID verified independently. The complete
140,850,732-byte original diagnostic ZIP was not re-exported by this task:
its CRC/SHA claims remain explicitly attributed to the producer source.json.
There was no later empty query or completed return in that diagnostic.
All later empty/repeated responses and reused pre-touch preferences in tests
are explicitly controlled synthetic data, never a real Android recovery.

The execution directory is a private plain source view, not a new Git checkout.
Its 40 files are exactly the 27 final paths plus 13 unchanged dependencies
copied from clean published 36274db2941963c59b1f819ad7bc2358470d3a76.
The reference checkout, all 14 physically materialized tracked files, index,
stage/flags and status are bound before and after and remained unchanged.
Original index/stage/flags/commit bytes are included.

production.patch is the minimal existing-file hunk. integration.patch also
shows the nonempty new text paths; all empty fixture additions are explicitly
listed in source-freeze.json and publication-mapping.json. Root owns the
later source checkpoint and device qualification. Historical 5ad failure and
the separate Village return repair are untouched.
