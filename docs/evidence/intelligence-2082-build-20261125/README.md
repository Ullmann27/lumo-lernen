# LUMO 2082: completed build, internal transport and actual local byte verification

Evidence snapshot: **2026-11-25 09:29:54 UTC**. Build, actual local APK/PCK byte verification and Android artifact-content acceptance passed. **The automatic publisher then failed at `create-tag` with HTTP 403 / `permission`. Both the exact intended tag and release returned 404 after the failure. No verified public APK download is available for this intended release in this snapshot.** Seven original files are prepared for a legitimate authenticated browser publication, but login/upload/publication have not occurred. Earlier combined snapshots remain byte-identical under [history](history/).

## Exact candidate

| Identity | Value |
| --- | --- |
| Host source | `6574b19f92abb4f6421fd3074cec09738dc0974a` |
| Native source | `62108c0355f860ab9a0a020ecb5f3f941f1032e9` |
| Original build run / attempt | `45569841812` / `1` |
| Successful APK build job | `139054345083` |
| Android job, original artifact content verified | `139080694208` |
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

## Completed Android evidence, checked from the actual artifact

The [original Android job](https://github.com/Ullmann27/lumo-lernen/actions/runs/45569841812/job/139080694208) completed successfully. Root then downloaded [artifact 15007906728](https://github.com/Ullmann27/lumo-lernen/actions/runs/45569841812/artifacts/15007906728) and independently verified **170350580 bytes**, SHA256 **`2f808087899ae0a0d7d4b1d249ebfdab6f0260865879d205b1f27cb21463be2b`**. Root checked the actual original reports and their nested evidence copies with the unchanged publisher validators. [ROOT-ANDROID-VERIFICATION.json](android/original-run-45569841812-job-139080694208/ROOT-ANDROID-VERIFICATION.json) records that content verification separately from the successful job status.

| Original Android evidence | Observed result |
| --- | --- |
| [Tour result](android/original-run-45569841812-job-139080694208/tour/tour-result.json) | 23 passed steps; 0 fatal crashes |
| [Real backup/restore roundtrip](android/original-run-45569841812-job-139080694208/tour/local-backup/backup-result.json) | 8 passed steps, including actual SAF export/review, process close, restore and preservation |
| [Mandatory native-start gate](android/original-run-45569841812-job-139080694208/tour/NATIVE-GAME-STARTS.json) | `run`, `quiz`, `memory`, `chess`, `kart`, `cards`, `world`: actual UI start and surviving game process |
| Installed package | UID `10209`, versionCode `2082`, versionName `0.14.9` |
| Installed emulator APK SHA256 | `3e89e180f15d03f0484c87f210a3181d1d8175f916baf37abfe86217d8a34d3e` |
| [Split identity](android/original-run-45569841812-job-139080694208/tour/SPLIT-APK-IDENTITY.json) | Byte-identical to the original release split report; ARM64 and x86_64 contain the same PCK hash and size |

The complete [additional native-start diagnostic report](android/original-run-45569841812-job-139080694208/tour/native-starts.json) is preserved. **The additional UI searches for `settlement`, `build` and `treasure` did not find an enabled matching Flutter control; those routes were not started or accepted by these attempts.** They are not counted among the seven required successful starts and are not described as passing gameplay checks. The original failed search lines also remain in [the exact log excerpts](android/original-run-45569841812-job-139080694208/ANDROID-ORIGINAL-EXCERPTS.txt).

The nested `LUMO-ANDROID-PRUEFBELEGE.zip` is represented by its original identity only: **85466965 bytes**, SHA256 **`1868b88b1ffcb1dba423f50250180d096c8fa4c73dcfb3497f44a066bf083bcd`**. Neither archive nor an APK is committed. [Raw final run](android/original-run-45569841812-job-139080694208/FINAL-RUN-RAW.json), [raw final jobs](android/original-run-45569841812-job-139080694208/FINAL-JOBS-RAW.json), and [original artifact metadata](android/original-run-45569841812-job-139080694208/FINAL-ARTIFACTS.json) bind the evidence to host `6574b19`, native `62108`, original run `45569841812`, attempt 1. [The log-source manifest](android/original-run-45569841812-job-139080694208/ANDROID-LOG-SOURCE.json) records the full original log hash and exact selected line ranges.

This establishes the recorded Android emulator UI/runtime and backup acceptance. It does not claim complete gameplay for every launched game, physical Fold7/ARM64 performance, audible playback acceptance or 60 FPS. The actual publication attempt and permission failure are documented separately below; no successful public download follows from Android acceptance.

## Actual publication attempt and observed permission failure

The [original publisher run 45584568855](https://github.com/Ullmann27/lumo-lernen/actions/runs/45584568855) executed from `8223c723c63ec361c887a905d833c5bd078946e9` on `support/lumo-2082-reviewed-publication` against the unchanged accepted host/native candidate. The read-only original-artifact verification job **139102772508 passed**, and the second job's exact stage re-verification also passed. The real write attempt in job **139103963328 failed at 2026-11-25T09:25:11.9764227Z**:

```json
{"status":"FAIL","phase":"create-tag","exception":"PublicationOperationError","reason":"permission","http_status":403,"exit_code":1}
```

This is the observed GitHub permission rejection. No additional token-scope diagnosis is inferred. [The original failure file](publication/failed-run-45584568855/publish/PUBLICATION-FAILURE.json) is **158 bytes**, SHA256 **`33ccfda1737445f8aa840ab049c4a627d955eaecc157d32fe84d249465749c6d`**. Root independently downloaded and hashed both small proof ZIPs; [the receipts](publication/failed-run-45584568855/DOWNLOAD-RECEIPTS.json) retain their identities and every original file hash. The [checks](publication/failed-run-45584568855/checks/PREPUBLICATION-VERIFICATION.json) and [publish](publication/failed-run-45584568855/publish/PREPUBLICATION-VERIFICATION.json) copies of the successful prepublication report are byte-identical: **3595 bytes**, SHA256 **`dcc739178e0d5ad8fa547b5cfdcc0c14d46541ae9d2cb9bc4972c6f8207f163e`**.

At **09:28:40 UTC**, subsequent GET requests for exact tag/release `lumo-0.14.9-2082-45569841812` both returned **404**, recorded unchanged in [POST-FAILURE-TAG-RELEASE-READS.json](publication/failed-run-45584568855/POST-FAILURE-TAG-RELEASE-READS.json). There is therefore no verified public APK download in this snapshot.

Both full original text job logs and [raw final job statuses](publication/failed-run-45584568855/PUBLISHER-FINAL-JOBS-RAW.json) are retained. **The verification log contains simulated `create-tag`, `complete` and other phases from the publication-guard contract tests around 09:21:55. Those test messages are not actual tag creation, release publication or anonymous download.** The real publication job is [PUBLISHER-JOB-139103963328.log](publication/failed-run-45584568855/PUBLISHER-JOB-139103963328.log), whose actual write phase stops at the recorded 403.

The [pending browser manifest](publication/failed-run-45584568855/pending-browser/BROWSER-RELEASE-PREPARED.json) records seven exact prepared assets and their hashes; its status is `PREPARED_NOT_UPLOADED`. The prepared APK is a hard link to the independently hashed original APK, not a rebuilt or re-signed file. [The pending LIESMICH text](publication/failed-run-45584568855/pending-browser/LIESMICH.md) is archived as a prepared asset, not a published release. No browser authentication data, APK or ZIP is included in this evidence commit. A later legitimate authenticated publication and public-download verification need a new observed result; this failure and all historical originals remain preserved.

## Historical snapshots are preserved

Every source file listed in [ORIGINAL-FILES.json](ORIGINAL-FILES.json) is an exact byte copy; its provenance, size and SHA256 are retained. [SHA256SUMS.txt](SHA256SUMS.txt) covers all evidence files except itself. No APK, ZIP, binary payload, credential or signed temporary URL is committed.

- `build/` is the earlier successful-build extraction. Its README and result say root still needs to verify downloaded bytes. That was the true scope when recorded; those originals have not been retroactively edited.
- `transfer/` is the completed transport snapshot. Its scope says the recipient must verify APK/PCK. That remains the original transfer scope, while the later actual verification is independently recorded in `local/APK-LOCAL-VERIFICATION.json`.
- `local/original-release-metadata/` contains the original build-generated reports with their original limitations. Packaged voice assets do not prove audible playback; generated launcher resources do not prove an installed-device launcher inspection. The split identity's x86_64 emulator scope does not claim a physical ARM64 device test.
- `history/build-and-bytes-8edd474/` preserves the earlier top-level README, STATUS and manifests byte-for-byte, including their then-accurate pending Android status.
- `android/` contains the later completed original job/API evidence and root's separate actual artifact-content verification.
- `history/android-accepted-dec46cfa/` preserves the Android-accepted, publication-pending top-level snapshot byte-for-byte.
- `publication/failed-run-45584568855/` preserves the later successful prepublication checks, actual create-tag permission failure, post-failure 404 reads and pending browser assets.
- `STATUS.json` and this README describe the combined state now documented: technical acceptance passed; the real automatic publication failed; authenticated browser publication remains prepared and not uploaded.

The evidence branch starts with a direct child of the tested host source; this publication-outcome update follows evidence commit `dec46cfa0b9100d1b8014c8b6df42a9f90d81106`. It changes only evidence files below `docs/evidence/intelligence-2082-build-20261125/` and carries `[skip ci]`. Product pins, source code, workflows, integration and main branches are unchanged. No Fold7/physical-device performance or 60 FPS claim is made. The linked Actions artifacts retain their own expiry dates in the preserved metadata; the text and hashes in this Git commit remain inspectable independently.
