# Original review: separate unchanged-6b API35 diagnostic

**Main tour passed; the direct Village roundtrip passed; the complete C4 diagnostic failed.** The independent offline replay preserves that failure. This is evidence for the separate diagnostic on the unchanged old 6b APK, not the new Host04 acceptance, not a successful seven-job run and not publication approval.

## Exact source and artifact binding

| Item | Exact identity |
| --- | --- |
| Repository | Ullmann27/lumo-lernen |
| Diagnostic QA source | `91b5aece4060cd625b27e4cfa967122b5d4b5b92` |
| Diagnostic QA tree | `b3fecc83c5e58471fb2be25dc1d1015937505961` |
| Diagnostic run / attempt | `43629575654 / 1` |
| Contract job | `132552989547`, success |
| Android job | `132553315080`, failure |
| APK Host source | `6b3047b7979dfb86d837e74a21b0fd890e4f9e66` |
| APK Host tree | `8b0c31a26207068c28658e14c6535c39a51cf95b` |
| Native source | `84789d0c2c6fb4b6ecd2897ce1951b89f958b604` |
| Original APK build | `43616038272 / 1`, job `132512734271` |
| Original x86 APK | 334,516,947 bytes; SHA256 `9c64ae2f866c1eee832a96baba56d8d3dc314cec79c69c7c1781bb803111a765` |
| Diagnostic artifact | `14128089386`, `lumo-6b-roundtrip-diagnostic-main-api35` |
| Original diagnostic ZIP | 156,330,306 bytes; SHA256 `2d8a5cae6ebe67d5cce2c488d6304bd1b9e3a36618eff66a541e3335f25b1614` |

The diagnostic artifact was downloaded once. Its actual API size/digest, every member path/type, duplicate/collision constraints, complete ZIP CRC and every extracted file's size/SHA256/Gitblob were checked before replay. The complete original inventory is [artifact-manifest.json](artifact-manifest.json): **2,262 files, 190,145,700 expanded bytes, 341 PNGs**. Available storage was checked before download and extraction; the archive was placed in a private workspace directory instead of the then-small `/tmp` volume.

The unchanged binding reader independently recomputed candidate-build and diagnostic-QA bindings from the original run/job/artifact metadata. Preflight and postflight source/APK binding reports are identical. The complete 79-file QA observer inventory matches the full untruncated QA91 Git tree. Eleven locally materialized reader/source files were individually checked against their exact QA91 blobs and modes. Two candidate configuration files were independently fetched at exact 6b and checked against their original receipt hashes. The local materialization's actual Git HEAD is `3251373a871d83efa2e8fd33c794486d57312858`; it is never represented as a QA91 checkout.

The existing APK/PCK/certificate receipts are cross-bound to the known exact old 6b binary. This review did not download the large APK again or run a new `apksigner` check. QA source and APK source remain explicitly different throughout.

## Independent unchanged readers

The private replay [script](replay/replay_original_diagnostic.py) imports the byte-identical existing Village/C4 readers and performs no ADB, engine, emulator, new capture or OCR execution. Its actual [result](replay/independent-reader-result.json), stdout and stderr are retained. Runtime: **Python 3.12.14, Pillow 13.0.0**, versus CI Pillow 12.3.0. Elapsed time: **21.476376215 seconds**, exit 0.

| Evidence | Actual replay outcome |
| --- | --- |
| Main tour | Original PASS, all 18 mandatory steps present and successful; 21/21 total reported steps successful; original fatal-crash count 0 |
| Village full existing reader | PASS on the original report, actual PNG/OCR/XML/commands, process identities, ready marker, profile/learning preservation and same-PID return acknowledgment |
| C4 full existing reader | Correctly rejected the original failed report: `ValueError: C4 report is missing, failed or bound to a different candidate` |
| C4 reached prefix | All 19 original observations and five actual acknowledged transitions replayed successfully; this does not constitute full C4 acceptance |

Before/after snapshots show all 2,262 original files and modes unchanged, all private reader bytes/modes unchanged, and the parent materialization's relevant source files, HEAD/tree/status and raw Git index unchanged. These are recorded separately from the original CI receipts.

### Actual Village return

The ready marker comes from actual native PID6449 while Host PID6072 remains alive. It names `res://scenes/creative/build_settlement_world.tscn`, `host_entry=true`, `living_village=true`, `return_scene=games`, slot 1, and actual initial counts 9 plots/2 population/2 visible residents/9 initialized plot nodes. Its save path is bound by the unchanged reader to the original native-profile-v2 registry/child identity. The actual native process ends and the original log establishes its fresh `[LumoHost] return: games` acknowledgment.

The corrected observer retains two different return observations. Attempt1 still shows native LUMO DORFWELT; the original reader rejected it because its actual pixels/TSV did not establish `Spielen`. Attempt2 shows the real Flutter Spielewelt and its active `Spielen` tab; the unchanged reader accepts that original. The observation journal completes after 22.453468156 seconds. No exact earlier moment of surface replacement is inferred.

### Exact C4 failure and proof boundary

The five reached acknowledged actions are **drop, pause, resume, drop, pause**. They preserve Host PID6072, Native PID6826 and the current session. The final proved state has revision 9, ACK5, paused=true and columns `[3,3,2,3]`. The original pause holds the same state for 2.871517702 seconds while its native heartbeat continues. The actual visible `Zurück` target and single dispatched touch were also replayed.

The next original command is:

```text
adb shell find /data/user/0/dev.ullmann.lumo.lumo_lernen.coachpreview/files/lumo_connect_four_session_v1 -maxdepth 2 -type f -name state.json
```

It returns code 0, empty stderr and this exact 134-byte stdout:

```text
/data/user/0/dev.ullmann.lumo.lumo_lernen.coachpreview/files/lumo_connect_four_session_v1/d96363b690dac4869acde2c8d4e832b7/state.json
```

That token is **the current C4 session**, not an unrelated token. The preceding original `pidof` already returned no native PID, and the following Activity snapshot identifies MainActivity. The observer immediately fails with **`ValueError: Closed C4 mailbox still exists`** before recording a full return, Flutter-return PNG/XML, reopen or second return.

Original all-buffer log lines record app-request finish at 19:22:35.314, MainActivity activity-result at 19:22:35.629/resume at 19:22:35.630, Native6826 self-SIG9 at 19:22:35.818 and process death at 19:22:36.166. Exact selected lines and their source hash are in [the timeline](replay/c4-return-original-timeline.json). Command metadata records duration, not absolute start; ZIP timestamps have only two-second resolution. It would be incorrect to assign a precise wall-clock timestamp to this `find` from those records.

There is **one post-return find and no later original deletion observation**. Therefore same-session file existence at that observation is established; neither a persistent leak nor later successful cleanup is established. The known Dart/Host asynchronous cleanup order makes an early observation plausible, but source analysis cannot supply the missing later device evidence. There is no post-touch state.json capture proving an additional ACK or exit-state update.

## Four personally viewed original images

All four unchanged PNGs are archived individually; hashes and precise visual scope are in [visual-review.json](replay/visual-review.json).

- [Rejected first Village return](originals/village/returned-flutter-observations/attempt-1/returned-flutter-frame.png): native landscape HUD, still LUMO DORFWELT.
- [Accepted second Village return](originals/village/returned-flutter-frame.png): actual portrait Flutter Spielewelt with visible `Spielen` tab and game cards.
- [C4 after two child/bot pairs](originals/c4/child-second-confirmed-003.png): complete 7×6 board, two cyan/two yellow stones, free back/pause and seven column buttons; no win claimed.
- [Actual Kart driving frame](originals/main/21_race_driving_late_2.png): visible fox driver, track, minimap and controls. The original main report separately records distance gain 125.3 and elapsed gain 5.02; this single image is not a performance measurement or completed race.

## Subsequent observer source review

The independent [patch review](replay/c4-observer-patch-review.json) covers QA checkpoint `d04ac2596fdd383dc49b1a111d9f6d699bd7cb76`, probe blob `836cf90f170545ce6d6393d5034dc149f5f6cf8c` and deadline-test blob `da877b93d3ae61c54b1743f8aba006bac614cdea`. Only `original()` and `return_to_flutter()` change; eleven existing tests are AST-identical and nine cases are additive. The unchanged evidence-reader blob remains `091e250702b41c8ff0a1eef2eaa554a83c2cff68`.

No concrete integration blocker was found: one back touch remains, each round journals fresh PID/activity/find originals, and acceptance requires the same native absence/MainActivity/empty successful session-root find within the existing 45-second budget. Subprocesses receive remaining time, late results cannot pass, and existing preferences/visible Flutter/reopen/two-return gates remain mandatory. No force-stop or file deletion is introduced as a test action. QA's already-run original 42-test log was read (42 PASS, 137.145 seconds); this reviewer did not run it again. A new successful device cleanup remains necessary.

## Durable original coverage

[all-original-non-png-files.zip](archive/all-original-non-png-files.zip) losslessly contains **all 1,921 non-PNG original files**, 37,888,364 expanded bytes, including complete original C4/Village command logs and reports. This compact evidence package is explicitly a new container, not the original GitHub ZIP. Every contained byte was rechecked against the original artifact index after packaging and all CRCs pass. Its manifest records the complete mapping. Critical reports/commands are also exposed individually for direct reading. The 341 original PNGs are all hashed in the full index; four personally viewed originals are archived individually. The complete original 156 MB GitHub ZIP and all extracted originals remain in the private local review directory.

Parent downloaded the terminal diagnostic job log exactly once and preserved it independently at commit `877dcec44c11da5ec50793be763be261e5566d44`, path `docs/evidence/current-host04-review-20261114/diagnostic-132553315080.original.log`, blob `31463029aa9d3284c0ceec5a32393e7b83a85bed`. This review did not duplicate that download.

No product source, central ref, Host/Native pin, workflow activation or publication was changed. No physical-device, 60 FPS, audio, completed C4 win, full update acceptance or seven-job release claim follows from this separate diagnostic.
