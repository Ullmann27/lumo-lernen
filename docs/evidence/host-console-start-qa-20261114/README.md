# Isolated API37 console-start followup

Base: unchanged QA7e2ab20f6f323c66a1e02de3550d73ef31b2037e/treeb9d21ad6c3fd3588ea1906549afaa516a95874b4, plus the two separately frozen repair packs containing20 paths. This pack adds6 paths for the new `qa/lumo-console-start-7b16-20261114` branch and `.github/workflows/lumo-console-start-7b16.yml`.

Only host, swiftshader and swangle API37 jobs are scheduled after the contract gate. Their entire runtime body is inherited unchanged except exact new workflow/job/artifact names. The original7b16 APK, Native17f5, build43540111465 and artifact14093773196 remain fixed. CLI22, upstream Action a421e438,37.0 installation selector, AVD/emulator options, init-console channel and all original ANR/identity guards are preserved. Full original tour artifacts are retained on failure. There is no APK build, release, Creative/API35/Update repetition.

All86 existing Console cases remain mandatory, including the real AF_UNIX cases. The7 original-transcript parser and9 failure-only diagnostic cases have separate exact count plus plain OK gates, rejecting skips. Existing source/diagnostic modules are retained and the new9 workflow/metadata contracts are added. Only the exact new branch is excluded from the three existing broad legacy workflows; other branches retain their behavior.

Local verification:9/9 new contracts PASS, zero skips; actionlint is clean on all4 changed/new workflows. Sources remain hash-identical before/after. No device or original APK was executed here, no actual launch success is inferred, and no Git/PR/run mutation was performed. The genuine inner Console Exit1 remains a failure awaiting the next original diagnostic evidence.

`source-freeze.json` predates these checks. `preservation.json` binds byte equivalence; `handoff.json` lists all exact files and dependencies. The two previous repair stages and PR483 remain unchanged.
