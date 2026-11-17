# Current-goal contract followup — 2026-11-13

This pack binds the next combined host acceptance contract to published Native `76980a941fa05d047574d8cc386d3249d93ffca3`, tree `8df22766bd0dbae31aacaa26c0228811c027686e`.

The published build-density probe retains eight template screenshots and adds four `current-goal` screenshots at 2400×1080, 1080×2400, 2176×1812 and 640×360. The explicit Nextgen profile therefore requires twelve build screenshots and thirty-two touch screenshots in total. The thirty-seven core probe/mode pairs, twenty-four core Studio images, six independent touch PASS pairs, all source stamps, ZIP/image hashes, full PNG decoding and actual review requirements remain in force.

The producer's default Studio profile has no fixed eight-image build roster; it is unchanged. Host producer `76d15fa6dae9959e75f56ef724e41d07e3c08c14` updates only its identity files and evidence outside the product runtime, and supplies no replacement delivery verifier.

## Source and test evidence

`capture-contract.json` lists the four exact artifact paths, dimensions and published source blobs. The immutable probe and runner copies under `published-source/` were fetched from the named commit and independently checked against those Git blobs. Their SHA-256 values are also recorded.

`roster-contract-red.log.gz` reproduces two failures with the old eight/twenty-eight contract. `roster-contract-green.log.gz` passes the same focused checks after the correction, including rejection of the complete old eight-image build roster and each individually absent current-goal original. `focused-contracts.log.gz` is the full subsequent log: **66 tests passed in 36.045 seconds, zero skipped** (35 Studio, 14 Nextgen, 17 graphics delivery/workflow tests).

The complete patch is stored losslessly as `nextgen-current-goal.patch.gz`. `source-before.json`, `focused-source-before.json`, `focused-source-after.json` and `source-final.json` bind the integration base, exact tested sources and protected identity/receipt files. Only the two authorized code/test files and the associated handoff document changed. The verifier differs from its base solely in the Nextgen view tuple and its count docstring.

`manifest.json` records original and stored sizes and SHA-256 values for every archived object, including all three final source hashes. Every gzip was decompressed after writing and compared byte for byte with its source. No binary screenshots or toolchain binaries are included.

These synthetic contract checks issue no renderer or visual approval, no receipt and no native pin. The completed `703a8f3` evidence remains its separate historical 37/24 + 6/28 checkpoint, checked with the frozen earlier verifier. It cannot be relabeled as evidence for the new combined source or the 32-touch-image requirement.
