# Original native and APK-build evidence for 9de

This is a separate evidence checkpoint. It changes no application, test, workflow or release source.

## Exact original execution

- Host: `9deaa3f24561bc65caba898585c0c00f1c77162b`, tree `c0a9e29c831113ea8e49e632bc7959a15079bc94`.
- Native: `bebf7bba48f09afc834469db0ea3c5541a184f55`, tree `35492eec16cac6774bc546b6e57628900bef61cb`.
- [Original main run43622379532, attempt1](https://github.com/Ullmann27/lumo-lernen/actions/runs/43622379532), completed build job132532172676.
- [Read-only native-original audit43627942888](https://github.com/Ullmann27/lumo-lernen/actions/runs/43627942888).
- Original native archive14126752152:176634268 bytes, SHA256 `36654c49962023cdf24a1bf9eb2bf8a6329e80f2714d96ee25bdb94433adfa63`.

The native audit checked the entire original ZIP and all member CRCs, replayed the existing pinned-source evidence reader, and verified source/member immutability. It did not run product tests or authorize a release.

## Preserved originals and review scope

`originals/native/` contains unmodified selected original reports, rosters and three actual PNGs. `originals/audit/` preserves the audit's original receipt and API responses. All26 preserved native/audit/inventory files were independently hashed again by the coordinating reviewer. The three images (teacher scene, paused C4 and landscape-cutout treasure title) were actually viewed.

`review/` contains explicitly NEW review documents and the NEW archive member inventory; these are not producer originals. The unchanged existing semantic reader checked52 nextgen modes and their raster/movie rosters. The original results table independently contains52 PASS rows. The C4 visual report has303 checks,0 errors and30 input events; treasure-title report has3351 checks and0 failures. The facial report contains144 frames at24 recording FPS. That is not a device FPS measurement.

The original project log reports117 PASS,7 WARN and0 FAIL. Six warnings concern missing legacy catalog GLBs with documented placeholder fallback; another concerns a non-executable web-bundle helper. They are retained explicitly. This checkpoint makes no zero-warning or complete-device-quality claim.

`originals/build/job.log` is the complete decoded original build log,1817266 UTF-8 bytes, SHA256 `9790637089174a1f89456e8f2c88556934d034d08d591a573ee472cda637e9be`. The two package JSON files were losslessly extracted by removing only GitHub timestamp prefixes; both build and subsequent verification blocks agree byte-for-byte. Exact original line references and hashes are in the new build review index. Root independently re-extracted all four blocks from the complete original.

The package JSON originals do not contain `flutter_source_commit`. The build script separately adds it to BUILD-PROVENANCE, and the Android identity reader checks that file against the actual APK and checkout. No field has been inserted into the saved package originals. Candidate/ARM64 ZIP digests in the build index remain API metadata: this review did not download those APK ZIPs again.

## Boundary

The9de Android-C4 job passed, but its separate in-place update tour failed at the Gecko-Velo observation deadline. Therefore9de did not pass the entire seven-job acceptance and was not published. The newer candidate198dd3 must pass its own full run; these originals are historical evidence only. No physical ARM64/Fold7,60-FPS,audible playback or Play Store approval is claimed here.
