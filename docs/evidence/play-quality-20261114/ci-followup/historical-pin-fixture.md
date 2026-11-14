# CI follow-up: historical native-pin fixture

Source under test: `4564ad40c4d000b764e67719d19bd2445c04c870`.

## Observed failure

The complete app-script inventory ran 799 tests and ended with one error in
`test_full_preflight_keeps_qa_run_and_apk_source_separate`:
`RuntimeError: Source checkout native pin differs`.

Original run: https://github.com/Ullmann27/lumo-lernen/actions/runs/43572640389
Original job: https://github.com/Ullmann27/lumo-lernen/actions/runs/43572640389/job/132380123774

The historical diagnostic verifier deliberately binds the original 2019 APK to
native revision `17f5b9d4a14c70050d4a125a8bd6bd8c68ee7845`.
The synthetic preflight test mocked its QA Git identity but read the QA pin from
the current repository, whose native revision is
`504c8ba70d02702cbccc370d0d96c36a292c5d27`.
This made the test dependent on unrelated later integration pin changes.

## Change and scope

The test supplies an explicit historical QA JSON fixture. Its synthetic
committed-file metadata and the real JSON reader use the same fixture bytes.
All other JSON inputs, original helper-byte checks and actual synthetic ZIP
reads remain in place. The production diagnostic verifier is unchanged.

The existing positive test still requires separate QA and APK source identities.
A new negative test changes the revision and repository independently in each
QA/candidate fixture and requires the original native-pin rejection.

These are synthetic offline tests. They do not establish Android execution,
a new APK, release acceptance or Play readiness.

## Verification status when prepared

The original failure is reproduced in the complete remote suite above.
The local executor disconnected before the repaired test could run; no local
passing result is claimed. The next quality-branch CI must verify the repair.

The separate full Flutter run also found three Connect Four failures:
https://github.com/Ullmann27/lumo-lernen/actions/runs/43572640431
Those are tracked independently and are not concealed by this test repair.
