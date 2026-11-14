# Original C4 preferences-read failure and bounded QA correction

Candidate: 7c5bef2bc39024fc2c1018523cabc651820cf76b
Tree: 10af7af91d03e2c768e574fd0b79be3f3011a8d4
Direct parent: 51ec0ac43f3e2aaac065e285e13cf5db5b5875d2

## Actual observed failure

The original Android run 43605863655, attempt 1, failed in C4 job 132499595540 after its main tour passed. Artifact 14121596843 has 128234694 bytes and SHA256 6b55e5424b4177b8daa5b342d8ac5c64e3b7b802bfdd84805cec3974b1f0506c.

After one real 120ms touch, the saved ADB command returned a 129-byte missing-file message on stdout, with return code 0 and empty stderr. The strict preferences XML parser raised ET.ParseError. Three preceding observations had valid preferences, ack 0 and an empty board. No confirmed move or later recovery is observed in that failed original.

The six raw files and their provenance are preserved byte-for-byte in tools/android_qa/tests/fixtures/c4-preferences-read-51ec.

## Exact correction and review

Only Probe.read_preferences normalizes ET.ParseError into an existing ValueError observation error. The saved original path and chained exception remain available. The existing fresh-observation loop can retry inside its unchanged deadlines; the touch is sent once. The strict parser, owner/round/ACK/durable-state/layout/frame checks and all production/native code remain unchanged.

The candidate differs from its direct parent in exactly the nine paths and blobs in source-files.json. Root and all three agents reviewed the relevant originals and source; learning and gameplay independently reviewed the final test file.

## Local evidence and limits

The unchanged 51ec probe fails the behavioral replay with the original ET.ParseError, after exactly one touch. The corrected probe passes 38 existing plus nine new tests: 47 tests, 46.119 seconds, OK, exit 0, no skips.

The ADB process, clock, frame producer and surface-readiness boundary in the new tests are controlled synthetic boundaries. Later valid XML and ACK values are explicitly derived test data. These tests are not a real Android recovery claim.

After that test run, only the test-module docstring was clarified to name the synthetic surface-readiness boundary. The executable AST is independently verified identical. Final test blob: ba828cee6be0fd740dbef412afa9e1a263871227. The exact final file is tested again by the new complete CI run.

Local runtime was Python 3.12.14 and Pillow 13.0.0. The complete current CI still pins Pillow 12.3.0.

## Current acceptance

Full main run: https://github.com/Ullmann27/lumo-lernen/actions/runs/43616126710

This checkpoint preserves source and local evidence only. It is not a successful Android or delivery acceptance. All seven exact-candidate jobs, original artifacts, a data-preserving update, and public APK verification remain required. Any separate 51ec APK / 7c5 QA diagnostic is explicitly diagnostic-only and cannot substitute for those gates.

Evidence documents are isolated on this checkpoint; the candidate tree remains unchanged.
