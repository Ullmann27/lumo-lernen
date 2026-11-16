from __future__ import annotations
from pathlib import Path
import datetime
import hashlib
import json
import sys
import zipfile
import inspect_selected_artifact_in_memory as reader


def main():
    spec = json.load(sys.stdin)
    expected = spec["expected"]
    reader.require(expected["source"] == "9b38360ca5f21919dce4a2b99e605ee39bbbf454", "Unexpected source")
    reader.require(expected["native"] == "9d6ef1d704a0e54098a8f8f0818f36deae0e3789", "Unexpected native pin")
    reader.require(spec["run_id"] == 43837592237 and spec["artifact_id"] == 14213570777, "Unexpected artifact identity")
    reader.require(spec["bytes"] == 535040568, "Unexpected archive size")
    reader.require(spec["sha256"] == "1782ece5bf30a32165f87f6f6d435d4d5d3467036060fe46c3ce6120cdaa12bd", "Unexpected archive SHA")
    started = datetime.datetime.now(datetime.timezone.utc).isoformat()
    with reader.download_to_memory(spec) as memory:
        with zipfile.ZipFile(memory) as archive:
            names = archive.namelist()
            required = {"Lumo-Lernen-Neu.apk", "BUILD-PROVENANCE.json", "APK-VERIFICATION.json", "SHA256SUMS.txt"}
            reader.require(len(names) == 4 and set(names) == required, "Unexpected archive members")
        report = reader.inspect_archive(memory, spec)
    destination = Path(spec["destination"])
    members = {row["path"]: row for row in report["members"]}
    actual = members["Lumo-Lernen-Neu.apk"]
    reader.require(actual["bytes"] == expected["apk_bytes"] == 535026462, "APK size differs")
    reader.require(actual["sha256"] == expected["apk_sha256"] == "cfa6709547ed82ffe6f081568c3bc454e1cc41afbfea2ecf9c85f534a6ea42de", "APK SHA differs")
    provenance = json.loads((destination / "original/BUILD-PROVENANCE.json").read_bytes())
    verification = json.loads((destination / "original/APK-VERIFICATION.json").read_bytes())
    reader.require(provenance["flutter_source_commit"] == expected["source"] and provenance["tracked_source_clean"] is True, "Unbound source")
    for proof in (provenance, verification):
        reader.require(proof["bytes"] == actual["bytes"] and proof["sha256"] == actual["sha256"], "Metadata differs from APK bytes")
        reader.require(proof["package"] == "dev.ullmann.lumo.lumo_lernen.coachpreview", "Package differs")
        reader.require(proof["versionCode"] == 2032 and proof["versionName"] == "0.13.20", "Version differs")
        reader.require(proof["signingCertificateSha256"] == "a6b1ef61bf59db4e0794c742aeb3b5506d130f4d21175c9975140e6acdb80702", "Certificate differs")
        reader.require(proof["abis"] == ["arm64-v8a"] and proof["elf16KiBAligned"] is True and proof["resourcesArscAligned"] is True, "ABI/alignment differs")
        reader.require(proof["minSdk"] == 24 and proof["targetSdk"] == 36, "Android SDK metadata differs")
        native = proof["godot"]
        reader.require(native["revision"] == expected["native"] and native["engine"] == "4.6.3", "Native source differs")
        reader.require(native["bytes"] == expected["pck_bytes"] == 278589884, "PCK size differs")
        reader.require(native["pck_sha256"] == expected["pck_sha256"] == "e7313f1cd28dd00ee324e6798aec6be65e91b28a09bb2b5d2a012a45de5953e7", "PCK SHA differs")
    reader.require(actual["sha256"] in (destination / "original/SHA256SUMS.txt").read_text(), "Checksum file differs")
    proof = {"status": "PASS", "startedAtUtc": started, "completedAtUtc": datetime.datetime.now(datetime.timezone.utc).isoformat(),
             "artifactId": spec["artifact_id"], "runId": spec["run_id"], "source": expected["source"], "native": expected["native"],
             "archiveBytes": report["archiveBytes"], "archiveSha256": report["archiveSha256"],
             "apkBytes": actual["bytes"], "apkSha256": actual["sha256"], "pckBytes": expected["pck_bytes"], "pckSha256": expected["pck_sha256"],
             "allFourArchiveMemberSizesCrcsAndShaVerified": True, "completeArchiveSha256Verified": True,
             "completeApkSha256Verified": True, "metadataMatchedActualApkBytes": True,
             "apkKeptOnDisk": False, "apkArchiveKeptOnDisk": False,
             "verifierSha256": hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),
             "readerSha256": hashlib.sha256(Path(reader.__file__).read_bytes()).hexdigest(),
             "scope": "Complete local artifact/APK byte verification and exact metadata binding. Signature, PCK and ELF checks are original CI verifier results bound to these APK bytes; apksigner and inner APK verification were not rerun locally. No Android execution or public download claim."}
    (destination / "artifact-byte-verification.json").write_text(json.dumps(proof, indent=2) + "\n")
    print(json.dumps({k: proof[k] for k in ("status", "artifactId", "archiveBytes", "archiveSha256", "apkBytes", "apkSha256")}))
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except reader.ArtifactError as error:
        print(json.dumps({"status": "FAIL", "error": str(error)}), file=sys.stderr)
        raise SystemExit(1)
    except Exception as error:
        print(json.dumps({"status": "FAIL", "errorClass": type(error).__name__}), file=sys.stderr)
        raise SystemExit(1)
