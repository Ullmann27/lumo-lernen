# LUMO 2082: actual completed APK build evidence

Source: `6574b19f92abb4f6421fd3074cec09738dc0974a`; native pin: `62108c0355f860ab9a0a020ecb5f3f941f1032e9`.
Original run: https://github.com/Ullmann27/lumo-lernen/actions/runs/45569841812
APK job: `139054345083`, observed `completed/success`.
Android job: `139080694208`, still in progress in this snapshot.

## Executed results

- Full Flutter suite: **3,669 passed, 193 skipped**.
- Focused Intelligence suite: **114 passed**.
- Full analyzer: **0 errors, 5 warnings, 299 infos**.
- JVM speech/dialog/backup contracts: **39 Python tests passed**, with original synthetic-boundary disclaimers preserved in the full job log.
- Godot export contracts: **47 tests passed**.
- Temporal flow: **133 checks, 0 failures**.
- Card rules: **212,968 checks, 148,154 moves, 0 failures**.
- Chess rules: **238 checks, 0 failures**.
- Card scene: **632 checks, 0 failures** in this exact shared APK run. The separate native run had 634; these counts must not be substituted.
- Chess scene: **919 checks, 0 failures**.
- World seven probes: **201, 134, 51, 183, 63, 124, 57 checks**, all passed.
- All **31 native probe completion records** are retained verbatim in the JSON result and excerpt file.
- The actual exported PCK asset/race probes emitted **201 PASS assertion lines**, retained separately. This is not added to a synthetic aggregate test total.

## APK/PCK identity reported by the actual build

- ARM64 APK: **653020163 bytes**; SHA256 `0ab02c4f1d3b3a625be42f5f974d1592ec993af27e5ed56135245dfee4996243`.
- PCK: **394388252 bytes**; SHA256 `fbd0d7c1155dac14be5913d5ee57eb9d0cc1fe586bfff0350459746eaf6097ab`.
- Package: `dev.ullmann.lumo.lumo_lernen.coachpreview`.
- Version: `0.14.9+2082`; minSdk 24, targetSdk 36.
- Certificate SHA256: `a6b1ef61bf59db4e0794c742aeb3b5506d130f4d21175c9975140e6acdb80702`.
- Split identity states `same_pck:true`; ARM64 and x86_64 PCK hashes/sizes match.
- ARM64 artifact: ID `15004539062`, **662435961 ZIP bytes**, digest `sha256:c186795be0f83ab20a4510b8a67b870b18686a52660f86b8137667a80bb52e75`.

## Files

- `BUILD-45569841812-RESULT.json`: results, original log hashes and line references, full native completion records, artifact metadata and job snapshot.
- `BUILD-45569841812-ORIGINAL-EXCERPTS.txt`: unchanged original timestamped log lines with source line numbers.
- `BUILD-45569841812-PACKAGE-METADATA.json`: decoded original ARM64, x86_64 and split JSON records with source line boundaries.
- `BUILD-45569841812-PCK-PASS-LINES.txt`: all original packaged PCK PASS assertions.

This extraction downloaded no artifact ZIP and made no external mutation. The values above are evidence from the real build log; root independently verifies downloaded APK/PCK bytes. Android-tour success and public release are not claimed. No physical Fold7/ARM64 performance or 60 FPS claim.
