#!/usr/bin/env python3
"""Publish only the reviewed original 2078 APK using the provisioned owner secret."""
from __future__ import annotations

import argparse
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
from urllib.error import HTTPError, URLError
from urllib.request import HTTPRedirectHandler, ProxyHandler, Request, build_opener

from lumo_team_b_reviewed_publish import decode, digest, read, require, same, save

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "tools/nextgen"))
from public_learning_download import download_public

REPOSITORY = "Ullmann27/lumo-lernen"
BRANCH = "support/lumo-2078-reviewed-publish"
SOURCE = "94cabcff7f6c568eddfe6805801f49a00ad58312"
NATIVE = "c3f459eca88f659da1a9e4af1c990c804e715528"
RUN = 45365478105
ARTIFACT = 14908418202
TAG = "lumo-0.14.6-2078-45365478105"
APK = "Lumo-Lernen-0.14.6-2078.apk"
APK_SHA = "3e49c99c22d05f7003e4477911d0f72e20fd3447cf6f9d55f6ab805c5fbc8198"
APK_BYTES = 701640419
CERT = "a6b1ef61bf59db4e0794c742aeb3b5506d130f4d21175c9975140e6acdb80702"
PACKAGE = "dev.ullmann.lumo.lumo_lernen.coachpreview"
ROOT = Path("reviewed-2078")
EVIDENCE = Path("docs/releases/lumo-2078-original-evidence")
REQUEST = Path("config/lumo-2078-reviewed-publish.json")
EXPECTED = {
    "schema": 1, "repository": REPOSITORY, "source": SOURCE, "source_run": RUN,
    "artifact_id": ARTIFACT, "apk_sha256": APK_SHA, "release_tag": TAG,
    "publisher_login": "Ullmann27", "publisher_user_id": 64243701,
}
QUALITY = {
    138346148805: "Verify the repaired game and render actual device layouts",
    138357008376: "Build the complete signed APK from the exact repaired source",
    138363355593: "Install the same APK and exercise Android return paths and backup",
}
PUBLISHER_NAME = "Publish the verified APK as a new immutable test release"
ORIGINAL_FILES = {'APK-SHA256.txt': {'bytes': 91, 'sha256': '8abac85d4b88c68da61b492db218800d49594f9aa2e19be0edee13884625e665'}, 'SHA256SUMS.txt': {'bytes': 86, 'sha256': '0251b9d8403ab568903fa1082e9a9c5db69c56ad0904c4e7035445d9087a1769'}, 'APK-VERIFICATION.json': {'bytes': 3848, 'sha256': '28edee73cb07f0e0d9473bd0269d34dbbc00464e8e0f017b2fa8b79fa6a31a9a'}, 'BUILD-PROVENANCE.json': {'bytes': 9658, 'sha256': '337ad2aa251ab18feb8d72573ac185daf9a1474b46169b87498d3aae0de25161'}, 'GODOT-SOURCE.json': {'bytes': 145, 'sha256': 'cc318a5869b6168c0d3b3d9a9bf69c6c1fa6d78126fd639f5e0203f492126e45'}, 'APP-VERSION.txt': {'bytes': 21, 'sha256': '12f6dadf3cdffee7789479f8fe80f3e9fb302c6de4a5d4fc9c3bb605442c87f9'}, 'KART-DRIVER-PACKAGE.json': {'bytes': 54148, 'sha256': 'dd9083c3e549203e6642d931c6a2bdd34e6e47cd19bd05652444766e69bbcc01'}, 'KART-DRIVER-PACKAGE.log': {'bytes': 565, 'sha256': '4af2ed3aefc6925564381754b583199288dfe5713341050adc79bb5d09eb3a12'}, 'Lumo-Lernen-Neu.apk': {'bytes': 701640419, 'sha256': '3e49c99c22d05f7003e4477911d0f72e20fd3447cf6f9d55f6ab805c5fbc8198'}}
EVIDENCE_FILES = {'ANDROID-AUDIT.json': {'bytes': 7892, 'sha256': 'c4e432b7c31d2235cd9775c9545995e4d1fc327a72315f35b86b9bf1deba7c1f'}, 'tour-result.json': {'bytes': 10029, 'sha256': '531eddbe7c5ca83b5ab965c6b6cd621a9632bd8768bbfcd6e6850e795ede5674'}, 'backup-result.json': {'bytes': 14266, 'sha256': '404ff66821367b9de2b9c9afcf8e10e9125eaa977db69ba38766ae218d0277ba'}, 'NATIVE-GAME-STARTS.json': {'bytes': 2622, 'sha256': '5980457dd1a1ddff6d6df1a4da836e7976c395b123244a7140d27120d60c648b'}, 'publisher-original.log': {'bytes': 24796, 'sha256': '8f9e6a064f1bb6131b764ed21157c89aef64cc816698aebd676187e5d12b8607'}, 'publisher-retry-original.log': {'bytes': 25292, 'sha256': 'f1d59086bbffc988afa721809d4ef0e199afcff43517d353f684052ea69e9635'}, 'RELEASE-NOTES-READY.md': {'bytes': 2670, 'sha256': '51fb507b43d314b7bcfa030a9aaf74008881b0e634a7321b623b5f520d4dc311'}}


class NoRedirects(HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        return None


API_OPENER = build_opener(ProxyHandler({}), NoRedirects())


def github_json(path, token, *, absent_ok=False):
    require(bool(token), "Required GitHub credential is unavailable")
    require(path == "user" or path == "repos/" + REPOSITORY or path.startswith("repos/" + REPOSITORY + "/"),
            "GitHub API path is outside the fixed repository")
    request = Request("https://api.github.com/" + path, headers={
        "Authorization": "Bearer " + token, "Accept": "application/vnd.github+json",
        "X-GitHub-Api-Version": "2022-11-28", "User-Agent": "lumo-2078-reviewed-publisher"})
    try:
        with API_OPENER.open(request, timeout=60) as response:
            data = response.read(8 * 1024 * 1024 + 1)
        require(len(data) <= 8 * 1024 * 1024, "GitHub API response exceeds the metadata limit")
        return decode(data)
    except HTTPError as error:
        if absent_ok and error.code == 404:
            return None
        raise ValueError("GitHub GET failed: HTTP " + str(error.code) + "; no redirect or fallback") from None
    except (URLError, OSError) as error:
        raise ValueError("GitHub GET failed: " + type(error).__name__) from None


def validate_order(order):
    same(set(order), set(EXPECTED), "Publication request fields")
    for key, value in EXPECTED.items():
        same(order[key], value, "Publication request " + key)
    return order


def verify_owner(identity):
    same(identity.get("login"), "Ullmann27", "Approved publisher login")
    same(identity.get("id"), 64243701, "Approved publisher ID")


def verify_gates(evidence):
    run = evidence["run"]
    for key, value in {
        "id": RUN, "head_sha": SOURCE, "run_attempt": 2, "status": "completed",
        "conclusion": "failure", "head_branch": "repair/lumo-device-bugs-2078",
        "path": ".github/workflows/lumo-2078-device-repair.yml", "event": "push",
    }.items():
        same(run.get(key), value, "Original run " + key)
    for key in ("repository", "head_repository"):
        same(run[key]["full_name"], REPOSITORY, "Original repository")
        same(run[key]["id"], 1222433959, "Original repository ID")
    same(run["repository"]["private"], False, "Public repository")
    for attempt, failed_id in ((1, 138384742953), (2, 138386118647)):
        listing = evidence["attempts"][str(attempt)]
        same(listing["total_count"], len(listing["jobs"]), "Complete job list")
        same(len(listing["jobs"]), 4, "Original job count")
        for job in listing["jobs"]:
            for key, value in {"run_id": RUN, "head_sha": SOURCE, "run_attempt": attempt,
                               "status": "completed"}.items():
                same(job.get(key), value, "Original job " + key)
        failed = [j for j in listing["jobs"] if j["id"] == failed_id]
        require(len(failed) == 1, "Original failed publisher is missing")
        same(failed[0]["name"], PUBLISHER_NAME, "Failed publisher name")
        same(failed[0]["conclusion"], "failure", "Original publisher failure")
    for job_id, name in QUALITY.items():
        found = [j for j in evidence["attempts"]["1"]["jobs"] if j["id"] == job_id]
        require(len(found) == 1, "Original quality job is missing")
        same(found[0]["name"], name, "Original quality job name")
        same(found[0]["conclusion"], "success", "Original quality gate")
    artifact = evidence["artifact"]
    for key, value in {
        "id": ARTIFACT, "name": "LUMO-2078-APK-45365478105", "expired": False,
        "size_in_bytes": 701710167,
        "digest": "sha256:1b52eac413a54f1f8406a76f2880cccec3294c5e16b6ee0705f38e0b4dc2e97e",
    }.items():
        same(artifact.get(key), value, "Original artifact " + key)
    for key, value in {"id": RUN, "head_sha": SOURCE, "repository_id": 1222433959,
                       "head_repository_id": 1222433959,
                       "head_branch": "repair/lumo-device-bugs-2078"}.items():
        same(artifact["workflow_run"].get(key), value, "Artifact owner " + key)


def verify_files(directory, expected, exact=True):
    actual = {str(p.relative_to(directory)) for p in directory.rglob("*") if p.is_file()}
    require(actual == set(expected) if exact else set(expected) <= actual, "Unexpected or missing proof files")
    for name, entry in expected.items():
        path = directory / name
        require(path.is_file() and not path.is_symlink(), "Proof file is not a regular file")
        same(path.stat().st_size, entry["bytes"], "Original file size: " + name)
        same(digest(path), entry["sha256"], "Original file SHA256: " + name)


def prepare(order):
    same(os.environ.get("GITHUB_REPOSITORY"), REPOSITORY, "Workflow repository")
    same(os.environ.get("GITHUB_REF"), "refs/heads/" + BRANCH, "Isolated publisher branch")
    changed = subprocess.check_output(
        ["git", "diff", "--name-status", "HEAD^", "HEAD", "--", str(REQUEST)], text=True
    ).strip()
    same(changed, "A\t" + str(REQUEST), "Request must be newly added in this commit")
    token = os.environ.get("GH_TOKEN", "")
    base = "repos/" + REPOSITORY
    evidence = {
        "run": github_json(f"{base}/actions/runs/{RUN}/attempts/2", token),
        "attempts": {str(n): github_json(f"{base}/actions/runs/{RUN}/attempts/{n}/jobs?per_page=100", token)
                     for n in (1, 2)},
        "artifact": github_json(f"{base}/actions/artifacts/{ARTIFACT}", token),
    }
    verify_gates(evidence)
    verify_files(EVIDENCE, EVIDENCE_FILES, exact=False)
    save(ROOT / "proof/ORIGINAL-GATES.json", evidence)
    save(ROOT / "proof/PUBLICATION-ORDER.json", order)


def verify(order):
    verify_gates(read(ROOT / "proof/ORIGINAL-GATES.json"))
    same(read(ROOT / "proof/PUBLICATION-ORDER.json"), order, "Prepared publication order")
    verify_files(ROOT / "source", ORIGINAL_FILES)
    verify_files(EVIDENCE, EVIDENCE_FILES, exact=False)
    shared = {"package": PACKAGE, "versionName": "0.14.6", "versionCode": 2078,
              "bytes": APK_BYTES, "sha256": APK_SHA, "abis": ["arm64-v8a", "x86_64"],
              "signingCertificateSha256": CERT}
    for name in ("BUILD-PROVENANCE.json", "APK-VERIFICATION.json"):
        doc = read(ROOT / "source" / name)
        for key, value in shared.items():
            same(doc.get(key), value, "Original APK metadata " + key)
        same(doc["godot"]["revision"], NATIVE, "Original Godot source")
    provenance = read(ROOT / "source/BUILD-PROVENANCE.json")
    same(provenance.get("flutter_source_commit"), SOURCE, "Clean source commit")
    same(provenance.get("tracked_source_clean"), True, "Clean source")
    tour = read(EVIDENCE / "tour-result.json")
    backup = read(EVIDENCE / "backup-result.json")
    native = read(EVIDENCE / "NATIVE-GAME-STARTS.json")
    for doc, count in ((tour, 23), (backup, 8)):
        same(doc["status"], "PASS", "Original Android/SAF status")
        same(len(doc["steps"]), count, "Original Android/SAF step count")
        require(all(step["ok"] is True for step in doc["steps"]), "Original Android/SAF step failed")
    same(tour["apk_sha256"], APK_SHA, "Android original APK")
    same(backup["identity"]["apk_sha256"], APK_SHA, "SAF original APK")
    same(native["status"], "PASS", "Required native starts")
    same(set(native["required_scenes"]), {"run", "quiz", "memory", "chess", "kart", "cards", "world"}, "Seven required native starts")
    release = ROOT / "release"
    release.mkdir(parents=True, exist_ok=False)
    os.link(ROOT / "source/Lumo-Lernen-Neu.apk", release / APK)
    for name in ORIGINAL_FILES:
        if name == "Lumo-Lernen-Neu.apk":
            continue
        target = "SHA256SUMS-original.txt" if name == "SHA256SUMS.txt" else name
        shutil.copyfile(ROOT / "source" / name, release / target)
    for name in EVIDENCE_FILES:
        shutil.copyfile(EVIDENCE / name, release / name)
    for name in ("ORIGINAL-GATES.json", "PUBLICATION-ORDER.json"):
        shutil.copyfile(ROOT / "proof" / name, release / name)
    (release / "SHA256SUMS.txt").write_text(APK_SHA + "  " + APK + "\n")
    assets = {p.name: {"bytes": p.stat().st_size, "sha256": digest(p)} for p in release.iterdir()}
    proof = {"status": "PASS", "order": order, "assets": assets,
             "artifact_archive_binding": "Exact API size/digest pinned; all extracted original file hashes matched.",
             "original_quality_attempt": 1, "failed_automatic_publishers": [138384742953, 138386118647]}
    save(ROOT / "proof/PREPUBLICATION-VERIFICATION.json", proof)


def publisher_cli(token, arguments, payload=None):
    environment = {k: v for k, v in os.environ.items()
                   if not k.startswith("GH_") and not k.lower().endswith("_proxy")
                   and k not in ("GITHUB_TOKEN", "GITHUB_ENTERPRISE_TOKEN", "LUMO_RELEASE_PUBLISH_TOKEN")}
    client_config = ROOT / "gh-client"
    client_config.mkdir(parents=True, exist_ok=True, mode=0o700)
    environment.update({"GH_TOKEN": token, "GH_HOST": "github.com", "GH_PROMPT_DISABLED": "1",
                        "GH_CONFIG_DIR": str(client_config.resolve()), "GH_NO_UPDATE_NOTIFIER": "1"})
    completed = subprocess.run(["gh", *arguments], input=json.dumps(payload) if payload is not None else None,
                               text=True, capture_output=True, env=environment, timeout=900)
    require(completed.returncode == 0, "Publisher command failed; no automatic retry, deletion or credential fallback")
    return decode(completed.stdout) if payload is not None else None


def verify_release(release, ref, assets, draft):
    same(ref["ref"], "refs/tags/" + TAG, "Actual tag")
    same(ref["object"]["type"], "commit", "Lightweight tag")
    same(ref["object"]["sha"], SOURCE, "Actual tag source")
    same(release["tag_name"], TAG, "Release tag")
    same(release["draft"], draft, "Release draft state")
    same(release["prerelease"], True, "Prerelease classification")
    verify_owner(release["author"])
    if not draft:
        same(release["html_url"], f"https://github.com/{REPOSITORY}/releases/tag/{TAG}", "Release URL")
    same({a["name"] for a in release["assets"]}, set(assets), "Exact release asset set")
    same(len(release["assets"]), len(assets), "No duplicate release assets")
    for asset in release["assets"]:
        expected = assets[asset["name"]]
        verify_owner(asset["uploader"])
        same(asset["state"], "uploaded", "Uploaded asset")
        same(asset["size"], expected["bytes"], "Uploaded asset size")
        if not draft:
            same(asset["browser_download_url"],
                 f"https://github.com/{REPOSITORY}/releases/download/{TAG}/{asset['name']}", "Actual asset URL")
        same(asset.get("digest"), "sha256:" + expected["sha256"], "Uploaded asset digest")
    return next(a for a in release["assets"] if a["name"] == APK)


def publish(order):
    token = os.environ.get("LUMO_RELEASE_PUBLISH_TOKEN", "")
    require(bool(token), "LUMO_RELEASE_PUBLISH_TOKEN is missing; no GITHUB_TOKEN fallback")
    verify_owner(github_json("user", token))
    base = "repos/" + REPOSITORY
    repository = github_json(base, token)
    same(repository["full_name"], REPOSITORY, "Publisher repository")
    same(repository.get("private"), False, "Public publication repository")
    verify_owner(repository["owner"])
    proof = read(ROOT / "proof/PREPUBLICATION-VERIFICATION.json")
    same(proof["status"], "PASS", "Prepublication gate")
    same(proof["order"], order, "Reviewed publication order")
    assets = proof["assets"]
    verify_files(ROOT / "release", assets)
    same(assets[APK], {"bytes": APK_BYTES, "sha256": APK_SHA}, "Verified APK")
    for endpoint in ("releases/tags/" + TAG, "git/ref/tags/" + TAG):
        require(github_json(base + "/" + endpoint, token, absent_ok=True) is None,
                "Release or tag already exists; it will not be overwritten")
    # Creating a new ref is atomic; no update-ref, force, delete or overwrite path exists.
    publisher_cli(token, ["api", "--method", "POST", base + "/git/refs", "--input", "-"],
                  {"ref": "refs/tags/" + TAG, "sha": SOURCE})
    ref = github_json(base + "/git/ref/tags/" + TAG, token)
    same(ref["object"]["sha"], SOURCE, "New tag source")
    created = publisher_cli(token, ["api", "--method", "POST", base + "/releases", "--input", "-"], {
        "tag_name": TAG, "target_commitish": SOURCE, "name": "Lumo 0.14.6+2078 — signierte Android-Testversion",
        "body": (ROOT / "release/RELEASE-NOTES-READY.md").read_text(), "draft": True,
        "prerelease": True, "make_latest": "false",
    })
    require(type(created["id"]) is int and created["id"] > 0, "Created release ID")
    same(created["draft"], True, "New release must remain draft while uploading")
    verify_owner(created["author"])
    save(ROOT / "proof/CREATED-RELEASE.json", created)
    publisher_cli(token, ["release", "upload", TAG, "--repo", REPOSITORY,
                          *[str(ROOT / "release" / name) for name in sorted(assets)]])
    release = github_json(base + "/releases/" + str(created["id"]), token)
    ref = github_json(base + "/git/ref/tags/" + TAG, token)
    verify_release(release, ref, assets, draft=True)
    publisher_cli(token, ["api", "--method", "PATCH", base + "/releases/" + str(created["id"]), "--input", "-"],
                  {"draft": False, "prerelease": True, "make_latest": "false"})
    release = github_json(base + "/releases/" + str(created["id"]), token)
    ref = github_json(base + "/git/ref/tags/" + TAG, token)
    asset = verify_release(release, ref, assets, draft=False)
    save(ROOT / "proof/PUBLISHED-RELEASE.json", release)
    save(ROOT / "proof/PUBLISHED-TAG.json", ref)
    # This helper uses a fresh anonymous opener, no cookies and no ambient proxy.
    observation = download_public({"url": asset["browser_download_url"], "bytes": APK_BYTES, "sha256": APK_SHA})
    result = {"status": "PASS", "source": SOURCE, "source_run": RUN, "artifact_id": ARTIFACT,
              "release_id": release["id"], "asset_id": asset["id"], "publisher": {"login": "Ullmann27", "id": 64243701},
              "release_url": release["html_url"], "download": observation,
              "server_immutable_observed": release.get("immutable"),
              "scope": "Original tested bytes published and read anonymously; both old publisher failures remain failures."}
    save(ROOT / "proof/PUBLIC-DOWNLOAD-VERIFICATION.json", result)
    print(json.dumps(result, indent=2))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("mode", choices=("prepare", "verify", "publish", "template"))
    args = parser.parse_args()
    if args.mode == "template":
        print(json.dumps(EXPECTED, indent=2))
        return
    order = validate_order(read(REQUEST))
    {"prepare": prepare, "verify": verify, "publish": publish}[args.mode](order)


if __name__ == "__main__":
    try:
        main()
    except Exception as error:
        # Never print API response bodies, subprocess output, tokens or CDN/SAS URLs.
        print("2078 publication stopped: " + type(error).__name__, file=sys.stderr)
        raise SystemExit(1) from None
