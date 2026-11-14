# Console and joystick follow-up status

The final workflow source is checkpointed at `5ed1016ba18e2646bb13d31b29e4c3b3bcebc9b4` (tree `d213657d83e82faa66ad9b83f8a246aa9e645fb8`). The committed-source preflight and final workflow contracts completed with **12 passing tests and zero skips**. Actionlint accepted all four affected workflows.

The first local preflight failed because two already-published helper modules were absent from the sparse checkout. Its original log is retained. Materializing the exact Git blobs under `scripts/probes` made the same source and tests pass; no code or test was changed for this environment repair.

This evidence-only commit activates the isolated follow-up on the original 7b16/17f5 version 2019 APK. Actual API37 console continuity and API35 joystick movement remain pending the new device run. Existing PR481 and PR482 failures and successes retain their original meaning.
