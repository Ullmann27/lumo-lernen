# LUMO 2082: completed build, internal transport and actual local byte verification

Evidence snapshot: **2026-11-25 09:03:41 UTC**. The signed APK build and the actual local APK/PCK byte verification passed. **Android job 139080694208 is still in progress in the available snapshot. No public release or public APK delivery is claimed.** Subsequent Android acceptance and any public delivery will be documented separately.

## Exact candidate

| Identity | Value |
| --- | --- |
| Host source | `6574b19f92abb4f6421fd3074cec09738dc0974a` |
| Native source | `62108c0355f860ab9a0a020ecb5f3f941f1032e9` |
| Original build run / attempt | `45569841812` / `1` |
| Successful APK build job | `139054345083` |
| Android job, not yet accepted | `139080694208` |
| Package | `dev.ullmann.lumo.lumo_lernen.coachpreview` |
| Version / ABI | `0.14.9+2082` / `arm64-v8a` |
| APK bytes | `653020163` |
| APK SHA256 | `0ab02c4f1d3b3a625be42f5f974d1592ec993af27e5ed56135245dfee4996243` |
| Actual embedded PCK bytes | `394388252` |
| Actual embedded PCK SHA256 | `fbd0d7c1155dac14be5913d5ee57eb9d0cc1fe586bfff0350459746eaf6097ab` |
| Build-verified certificate SHA256 | `a6b1ef61bf59db4e0794c742aeb3b5506d130f4d21175c9975140e6acdb80702` |

The [original build job](https://github.com/Ullmann27/lumo-lernen/actions/runs/45569841812/job/139054345083) successfully completed APK creation, Android build-tools verification and the certificate/package comparison. [Root's local verification](local/APK-LOCAL-VERIFICATION.json) subsequently hashed the complete received APK and the actual PCK inside it; both matched the original evidence. The local result does not claim a new local signature-tool invocation or re-signing.

## Actually executed checks

| Check in original run 45569841812 | Observed result |
| --- | --- |
| Complete Flutter suite | **3,669 passed, 193 skipped, 0 failed** |
| Focused Intelligence suite | 114 passed |
| Complete analyzer | 0 errors, 5 warnings, 299 infos |
| Temporal card/chess flow | 133 checks, 0 failures |
| Card rules | 212,968 checks across 148,154 moves, 0 failures |
| Chess rules | 238 checks, 0 failures |
| Integrated card scene | **632 checks, 0 failures** |
| Integrated chess scene | 919 checks, 0 failures |
| World probes | 201 / 134 / 51 / 183 / 63 / 124 / 57 checks, all passed |

These are results from this exact integrated build. The separate native source-validation run reported **634** card-scene checks; that count is not substituted for the integrated run's **632**. [The original result](build/BUILD-45569841812-RESULT.json) retains all 31 native completion records. [All 201 exported-PCK PASS assertion lines](build/BUILD-45569841812-PCK-PASS-LINES.txt) are preserved as their own evidence scope and are not added to a synthetic total. Original synthetic-boundary qualifications for the JVM contract probes remain in the build evidence.

## Original-byte transport and recipient verification

The original [APK artifact 15004539062](https://github.com/Ullmann27/lumo-lernen/actions/runs/45569841812/artifacts/15004539062) contains **662435961 ZIP bytes** with SHA256 `c186795be0f83ab20a4510b8a67b870b18686a52660f86b8137667a80bb52e75`. Its size exceeded the connector's 512 MiB single-transfer limit. The authorized internal [transport run 45579662500](https://github.com/Ullmann27/lumo-lernen/actions/runs/45579662500) therefore verified that exact original ZIP and APK, then partitioned the original APK bytes without rebuilding or signing.

| Part | APK byte offset | APK part bytes | Transport artifact |
| --- | ---: | ---: | --- |
| 1 | 0 | 268435456 | [15005572927](https://github.com/Ullmann27/lumo-lernen/actions/runs/45579662500/artifacts/15005572927) |
| 2 | 268435456 | 268435456 | [15005947276](https://github.com/Ullmann27/lumo-lernen/actions/runs/45579662500/artifacts/15005947276) |
| 3 | 536870912 | 116149251 | [15006371375](https://github.com/Ullmann27/lumo-lernen/actions/runs/45579662500/artifacts/15006371375) |

The [transport result](transfer/TRANSFER-RESULT.json), [original transport manifest](transfer/MANIFEST.json), [artifact metadata](transfer/TRANSFER-ARTIFACTS.json), and [recipient receipts](local/TRANSFER-RECEIPTS.json) distinguish raw APK part sizes from each part's ZIP size. Root received the parts, verified the archive/part identities, reassembled the full APK and independently hashed its embedded PCK. The copied [recipient manifest](local/TRANSFER-MANIFEST.json) is byte-identical to the original transport manifest: SHA256 **`a8e487bf2a275ea60c552ab2103b0bcaa527c660955fe572e68eba5d8ed17ac8`**. The four [original release metadata files](local/original-release-metadata/) also match their manifest sizes and hashes byte-for-byte.

## Historical snapshots are preserved

Every source file listed in [ORIGINAL-FILES.json](ORIGINAL-FILES.json) is an exact byte copy; its provenance, size and SHA256 are retained. [SHA256SUMS.txt](SHA256SUMS.txt) covers all evidence files except itself. No APK, ZIP, binary payload, credential or signed temporary URL is committed.

- `build/` is the earlier successful-build extraction. Its README and result say root still needs to verify downloaded bytes. That was the true scope when recorded; those originals have not been retroactively edited.
- `transfer/` is the completed transport snapshot. Its scope says the recipient must verify APK/PCK. That remains the original transfer scope, while the later actual verification is independently recorded in `local/APK-LOCAL-VERIFICATION.json`.
- `local/original-release-metadata/` contains the original build-generated reports with their original limitations. Packaged voice assets do not prove audible playback; generated launcher resources do not prove an installed-device launcher inspection. The split identity's x86_64 emulator scope does not claim a physical ARM64 device test.
- `STATUS.json` and this README describe the combined state of these snapshots: build and local bytes passed, Android pending, no public release.

This evidence-only commit is a direct child of the tested host source. It adds only files below `docs/evidence/intelligence-2082-build-20261125/` and carries `[skip ci]`. Product pins, source code, workflows, integration and main branches are unchanged. No Fold7/physical-device performance or 60 FPS claim is made. The linked Actions artifacts retain their own expiry dates in the preserved metadata; the text and hashes in this Git commit remain inspectable independently.
