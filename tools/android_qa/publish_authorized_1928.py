#!/usr/bin/env python3
"""Deliver exactly the authorized existing 1928 artifacts, without any rebuild."""
import hashlib
import json
from pathlib import Path
import subprocess
import tempfile
import zipfile


REPO = "Ullmann27/lumo-lernen"
BRANCH = "computer/lumo-kart-android-1928-2026-10-11"
RELEASE_ID = 409396093
TAG = "lumo-0.12.21-1928-kart-technical-test"
TITLE = "Lumo Lernen Neu 0.12.21 (1928): Kart-Techniktest"
SOURCE = "8ba6b1fc9791ede5977d7b624fe692405fd44277"
HARNESS = "241f0ea2f7be5aca79493995ee4db35a033d2046"
GODOT = "6063f56fd4ff13afef61509f52d1d4fdab012654"
APK_SHA = "1eae04ebaba428f70c1bc35651658edd049ace96538a982e6a44075eda3cf16a"
EMULATOR_SHA = "ce4a72cb2831067401799c7e15f0649057f487b89fb40a54c23db5f52b8d4dd7"
BODY_SHA = "d34b57edf398dca6f219fc869906034129909b1f746f8f0fb833e76953b28828"
CERT = "a6b1ef61bf59db4e0794c742aeb3b5506d130f4d21175c9975140e6acdb80702"
FILES = ("Lumo-Lernen-Neu.apk", "SHA256SUMS.txt", "APK-VERIFICATION.json",
         "BUILD-PROVENANCE.json", "TEST-RESULTS.txt")


def require(condition, message):
    if not condition:
        raise ValueError(message)


def api(endpoint, *args):
    return json.loads(subprocess.check_output(
        ["gh", "api", endpoint, *args], text=True, timeout=90))


def digest(path):
    with path.open("rb") as stream:
        return hashlib.file_digest(stream, "sha256").hexdigest()


def member(archive, name):
    matches = [item for item in archive.infolist()
               if not item.is_dir() and Path(item.filename).name == name]
    require(len(matches) == 1, f"Ambiguous or missing artifact member: {name}")
    return matches[0]


def check_release(release):
    require(release["id"] == RELEASE_ID and release["draft"] is True
            and release["prerelease"] is True
            and release["tag_name"] == TAG and release["name"] == TITLE
            and release["target_commitish"] == SOURCE,
            "Only the exact authorized unpublished technical prerelease is allowed")
    require(hashlib.sha256(release["body"].rstrip().encode()).hexdigest() == BODY_SHA,
            "Release description differs from the complete approved payload")
    names = [asset["name"] for asset in release["assets"]]
    require(len(set(names)) == len(names) and set(names).issubset(FILES),
            "Unexpected or duplicate release assets; no overwrite or deletion allowed")


def check_return(result):
    require(result.get("status") == "PASS" and result.get("source") == SOURCE
            and result.get("harness") == HARNESS
            and result.get("apk_sha256") == EMULATOR_SHA,
            "Successful exact-source Android runtime proof is required")
    require(result["kart"].get("flutter_return_frame_confirmed") is True
            and result["kart"].get("pause_return") is True
            and result["update"].get("profile_retained") is True,
            "Actual Flutter return and profile-preserving update must pass")


def check_apk(info, provenance, apk):
    require(digest(apk) == APK_SHA and apk.stat().st_size == 167153075,
            "APK differs from the exact authorized bytes")
    require(info.get("sha256") == APK_SHA and info.get("bytes") == 167153075
            and info.get("package") == "dev.ullmann.lumo.lumo_lernen.coachpreview"
            and info.get("versionCode") == 1928 and info.get("versionName") == "0.12.21"
            and info.get("abis") == ["arm64-v8a"]
            and info.get("signingCertificateSha256") == CERT
            and info.get("elf16KiBAligned") is True
            and info.get("resourcesArscAligned") is True
            and info.get("godot", {}).get("revision") == GODOT,
            "Verified package, ABI, signing or native-source identity differs")
    require(all(provenance.get(key) == value for key, value in info.items())
            and provenance.get("flutter_source_commit") == SOURCE
            and provenance.get("tracked_source_clean") is True,
            "Build provenance does not match the verified APK")


def download_artifact(run_id, artifact_id, expected_name, expected_head, destination):
    run = api(f"repos/{REPO}/actions/runs/{run_id}")
    require(run["status"] == "completed" and run["conclusion"] == "success"
            and run["head_sha"] == expected_head and run["head_branch"] == BRANCH
            and run["path"] == ".github/workflows/release-apk.yml",
            "Artifact run is not the exact successful reviewed workflow")
    artifact = api(f"repos/{REPO}/actions/artifacts/{artifact_id}")
    require(artifact["name"] == expected_name and artifact["expired"] is False
            and artifact["workflow_run"]["id"] == run_id,
            "Artifact is expired or does not belong to the exact approved run")
    with destination.open("wb") as stream:
        subprocess.run(["gh", "api", "--allow-escape-sequences",
                        f"repos/{REPO}/actions/artifacts/{artifact_id}/zip"],
                       stdout=stream, check=True, timeout=300)


def main():
    check_release(api(f"repos/{REPO}/releases/{RELEASE_ID}"))
    with tempfile.TemporaryDirectory() as directory:
        root = Path(directory)
        download_artifact(38097768063, 11686318870,
                          "lumo-probe-apk-38097768063-1", SOURCE, root / "apk.zip")
        download_artifact(38099853608, 11687337488,
                          "lumo-1928-android16-kart-proof-38099853608",
                          HARNESS, root / "runtime.zip")
        with zipfile.ZipFile(root / "runtime.zip") as archive:
            result = json.loads(archive.read(member(archive, "result.json")))
            check_return(result)
            frame = json.loads(archive.read(
                member(archive, "16_kart_returned_to_app-flutter-return.json")))
            require(frame["status"] == "PASS" and frame["exact_visible_caption"] == "Spielen",
                    "Current visible Flutter frame proof is missing")
            picture = archive.read(member(archive, "16_kart_returned_to_app.png"))
            require(hashlib.sha256(picture).hexdigest() ==
                    result["kart"]["flutter_return_capture"]["sha256"] ==
                    frame["capture"]["sha256"],
                    "Actual return picture differs from its independent proof")
        with zipfile.ZipFile(root / "apk.zip") as archive:
            for name in FILES:
                (root / name).write_bytes(archive.read(member(archive, name)))
        info = json.loads((root / "APK-VERIFICATION.json").read_text())
        provenance = json.loads((root / "BUILD-PROVENANCE.json").read_text())
        check_apk(info, provenance, root / FILES[0])
        require((root / "SHA256SUMS.txt").read_text().strip() ==
                f"{APK_SHA}  Lumo-Lernen-Neu.apk", "Checksum filename or value differs")
        expected = {name: {"size": (root / name).stat().st_size,
                           "sha256": digest(root / name)} for name in FILES}
        release = api(f"repos/{REPO}/releases/{RELEASE_ID}")
        check_release(release)
        present = {asset["name"] for asset in release["assets"]}
        missing = [str(root / name) for name in FILES if name not in present]
        if missing:
            subprocess.run(["gh", "release", "upload", TAG, "--repo", REPO, *missing],
                           check=True, timeout=600)
        release = api(f"repos/{REPO}/releases/{RELEASE_ID}")
        check_release(release)
        require({asset["name"] for asset in release["assets"]} == set(FILES),
                "All five authorized assets must be present before publication")
        for asset in release["assets"]:
            value = expected[asset["name"]]
            require(asset["state"] == "uploaded" and asset["size"] == value["size"],
                    "Uploaded asset state or size differs")
            if asset.get("digest"):
                require(asset["digest"] == "sha256:" + value["sha256"],
                        "GitHub's uploaded asset checksum differs")
            downloaded = root / ("downloaded-" + asset["name"])
            with downloaded.open("wb") as stream:
                subprocess.run(["gh", "api", "--allow-escape-sequences",
                                "-H", "Accept: application/octet-stream", asset["url"]],
                               stdout=stream, check=True, timeout=300)
            require(digest(downloaded) == value["sha256"],
                    "Downloaded uploaded bytes differ; publication refused")
            downloaded.unlink()
        published = api(f"repos/{REPO}/releases/{RELEASE_ID}", "--method", "PATCH",
                        "-F", "draft=false", "-F", "prerelease=true",
                        "-f", "make_latest=false")
        require(published["draft"] is False and published["prerelease"] is True,
                "Technical prerelease publication was not confirmed")
        Path("delivery-proof").mkdir(exist_ok=True)
        proof = {"release": published, "authorized_files": expected,
                 "apk_source": SOURCE, "qa_source": HARNESS, "godot_source": GODOT,
                 "runtime_run": 38099853608, "apk_run": 38097768063,
                 "rebuilt": False, "all_uploaded_downloads_verified": True}
        Path("delivery-proof/PUBLICATION-PROOF.json").write_text(
            json.dumps(proof, indent=2) + "\n")
        print(json.dumps({"release": published["html_url"], "files": expected,
                          "rebuilt": False, "prerelease": True}, indent=2))


if __name__ == "__main__":
    main()
