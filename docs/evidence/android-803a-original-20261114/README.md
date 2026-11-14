# Original Android outcomes for frozen candidate 803a

Recorded at 2026-11-14 10:43:23 UTC. Host `803a4e960ffb804a46b6d09417731c031f00f680`, tree `744986f046f6ec65ebe314f62243187a8a0a64c0`, Native `0e26153f0e58cc05739e72923b4c563a4cf380b8`, [run 43578509499](https://github.com/Ullmann27/lumo-lernen/actions/runs/43578509499), attempt 1.

## Final outcome

The overall run is **failure**. Android host compilation, desktop Dart/Godot execution, the complete verify-and-build job, and the in-place upgrade job succeeded. The Android C4 job failed in its metadata preflight. Final candidate verification and delivery preparation were skipped. No final delivery or Play approval follows from the successful component jobs.

Both Android jobs used the genuine x86_64 APK with SHA256 `fc66e87274173c6c8440bc0dcdcb6e4b7f838dfa168a07e392ec305c15ee566a`. They ran on an API 35 emulator with a Pixel 5 configuration and explicitly changed viewport dimensions, not physical ARM64 or Fold hardware. The separately downloaded ARM64 APK and its original verification remain documented in [the main evidence](../quality-803a-ci-20261114/README.md).

## Actual successful 2017 to 2020 upgrade

Job **132415120397** completed successfully at 10:30:47 UTC. The whole original job log is retained unchanged. Artifact **14110561328** is 118,394,487 bytes, ZIP SHA256 `45091d74d0fd3f91a94f006475214af322fe75d453cafe19ee247f9e2984669d`. Root downloaded and checked the size, digest, every entry's CRC, path safety and all 760 extracted files (132,354,023 bytes).

The original journey created a grade-1 test profile, solved **3 + 2 = 5**, earned **one star and five XP**, saved the result and restored it. It then installed 2020 over genuine 2017 with `install -r`, preserving the package UID and first-install time. Seven existing learning keys, profile identity, the correct answer and rewards survived the update, an actual offline Kart session, restart, and the three emulated Fold dimensions.

The one explicitly reviewed migration adds `independentEvidence-v1` to the existing primary skill record. The original guard checks its exact schema, namespace, field types and derived values while preserving all previous fields. Later snapshots must also match the post-update learning state exactly. It does not silently disregard arbitrary migration differences.

Root independently reran the exact two 803a preservation modules against the original package dumps and all six preserved states. Every result matched the original `update-result.json`; all 760 original files remained byte-identical. The original modules, actual replay script, generated result, package records and seven preference XML files are retained here. This was a read-only evidence replay, not another Android run.

Root opened seven of the 225 original PNGs. Four selected unchanged originals are retained here and checked against their independently computed Git object hashes as well as SHA256. Home retains the original fox, grade, star and XP; the return image visibly reaches the Flutter games page. The later race image shows the original fox in the selected kart, track, lap/position/speed and labeled controls. It also reveals a minimap extending beyond the right edge and overlapping part of the SPEED control; this is a concrete visual observation sent for source triage, not an inferred touch failure. The landscape Home image's Mathe 82% score is separately marked for meaning review rather than declared an incorrect calculation.

The archive and original report explicitly exclude physical hardware, measured frame rate, audible output, complete two-lap race rewards, every subject/grade, and every learning history. The baseline report's optional German/English navigation misses remain in the original report; they do not become successful subject-coverage claims. This selected checkpoint is not a mirror of all 760 archive files.

## Actual C4 preflight failure

Job **132415120342** failed at 10:32:46 UTC. Artifact **14110022118** is 117,735,339 bytes, ZIP SHA256 `0778cfc6961e8b11bd0be0e714e3e160397e2ea23ebe301b33561366c8df292a`. Root verified the download and all 846 extracted entries (134,929,506 bytes). Its complete original job log and key original JSONs are retained unchanged.

The preceding general Android tour reported **PASS, 21 steps, zero fatal crashes**. The subsequent C4 identity check confirmed all eight APK/source/pin/version/signature checks, then failed with:

```
ValueError: Candidate source/event/workflow differs
```

There were **zero C4 observations, transitions or returns**. The exact source guard requires `run.head_branch == 'integration/lumo-c4-connections-20261114'`. The original API metadata instead correctly binds this run to the other intended quality branch:

| Field | Original value |
| --- | --- |
| head_sha | `803a4e960ffb804a46b6d09417731c031f00f680` |
| head_branch | `work/lumo-play-quality-20261114` |
| event | `pull_request` |
| path | `.github/workflows/lumo-connect-four-2020.yml` |

The actual failure occurs before the probe starts C4 or sends its first input. It therefore does not demonstrate the separately reproduced native return-retry bug, nor does it supply C4 Android gameplay acceptance. The repair must admit only the two intended branches while retaining every exact source, artifact, job, version and final PR/run binding. Its own red/green tests and subsequent full Android run belong to a newer source, not this failed run.

## Preservation and source boundaries

`original-blob-entries.json` records the 29 text and four image blobs whose uploaded Git object hashes were independently checked against the original local bytes. The two full job logs and original job metadata were separately captured by the release lead and retained by their Git blob identities. The final job snapshot is saved in the main evidence directory. All source changes remain on the separate prepared next-candidate branch; the failed 803a source and its evidence are not rewritten.
