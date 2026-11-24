#!/usr/bin/env python3
"""Check a new current-build release and its entire anonymous public APK.

The source/Android acceptance remains in prepare_current_learning_release.py.
This helper consumes its DELIVERY plus the independently checked build proof;
it never creates, updates or deletes a release/tag, and never stores APK bytes.
"""
from __future__ import annotations

import argparse
import hashlib
import http.client
import json
import os
from pathlib import Path
import re
import subprocess
import time
import urllib.error
import urllib.parse
import urllib.request


def require(condition, message):
    if not condition:
        raise RuntimeError(message)


def write_json(path, value):
    path.write_text(json.dumps(value, indent=2) + "\n", encoding="utf-8")


def digest(path):
    with path.open("rb") as stream:
        return hashlib.file_digest(stream, "sha256").hexdigest()


def expected_candidate(delivery, build, env):
    """Use this run's verified fields, with no historical candidate constants."""
    repository, source = env["GITHUB_REPOSITORY"], env["GITHUB_SHA"]
    native, sha = env["LUMO_EXPECTED_NATIVE"], env["ARM64_SHA"]
    name, code, run = env["VERSION_NAME"], env["VERSION_CODE"], env["GITHUB_RUN_ID"]
    certificate, package = env["LUMO_CERTIFICATE"], env["LUMO_PACKAGE"]
    require(repository == "Ullmann27/lumo-lernen", "Wrong publication repository")
    require(all(re.fullmatch(r"[0-9a-f]{40}", value) for value in (source, native)) and
            all(re.fullmatch(r"[0-9a-f]{64}", value) for value in (sha, certificate)),
            "Invalid source or digest in current workflow environment")
    require(re.fullmatch(r"[0-9]+\.[0-9]+\.[0-9]+", name) and
            re.fullmatch(r"[1-9][0-9]*", code) and re.fullmatch(r"[1-9][0-9]*", run),
            "Invalid current version or workflow run")
    code, run = int(code), int(run)
    tag = f"lumo-nextgen-learning-{name}-{code}"
    require(env["RELEASE_TAG"] == tag, "Release tag differs from the current version")
    require(type(delivery.get("schemaVersion")) is int and delivery["schemaVersion"] == 1 and
            type(delivery.get("workflowRun")) is int and delivery["workflowRun"] == run and
            delivery.get("apkSourceCommit") == source == build.get("flutter_source_commit") and
            delivery.get("godotCommit") == native == build.get("godot", {}).get("revision") and
            build.get("tracked_source_clean") is True and build.get("abis") == ["arm64-v8a"],
            "Delivery/build source or current workflow binding differs")
    require(all(record.get("versionName") == name and type(record.get("versionCode")) is int and
                record["versionCode"] == code and record.get("package") == package and
                record.get("signingCertificateSha256") == certificate for record in (delivery, build)),
            "Delivery/build version, package or signing identity differs")
    require(delivery.get("arm64Sha256") == sha == build.get("sha256") and
            type(delivery.get("arm64Bytes")) is int and delivery["arm64Bytes"] > 0 and
            type(build.get("bytes")) is int and build["bytes"] == delivery["arm64Bytes"],
            "Delivery/build APK digest or byte count differs")
    asset = f"Lumo-Lernen-Neu-{name}-{code}.apk"
    return {"repository": repository, "source": source, "native": native,
            "workflowRun": run, "versionName": name, "versionCode": code,
            "package": package, "signingCertificateSha256": certificate,
            "tag": tag, "asset": asset, "sha256": sha, "bytes": build["bytes"],
            "url": f"https://github.com/{repository}/releases/download/{tag}/{asset}"}


def github_command(expected, path):
    return ["gh", "api", "--hostname", "github.com", "--method", "GET",
            "repos/" + expected["repository"] + "/" + path]


def require_absent(expected, evidence):
    """Only observed HTTP 404 permits creation; auth/network errors never do."""
    observations = []
    for path in ("releases/tags/" + expected["tag"], "git/ref/tags/" + expected["tag"]):
        result = subprocess.run(github_command(expected, path) + ["--include"],
                                capture_output=True, text=True, timeout=60)
        statuses = re.findall(r"^HTTP/\S+\s+(\d{3})\b", result.stdout, re.MULTILINE)
        observations.append({"path": path, "httpStatuses": statuses,
                             "exitCode": result.returncode,
                             "response": result.stdout, "error": result.stderr})
        # Save the actual failed observation too, before judging it.
        write_json(evidence, {"candidate": expected, "observations": observations})
        require(statuses == ["404"] and result.returncode != 0,
                "Release/tag exists or absence is unverified: " + path)


def verify_release(metadata, tag, expected):
    require(metadata.get("tag_name") == expected["tag"] and
            metadata.get("target_commitish") == expected["source"] and
            metadata.get("name") == f"LUMO Lernwelt {expected['versionName']} ({expected['versionCode']})" and
            metadata.get("draft") is False and metadata.get("prerelease") is True and
            metadata.get("html_url") == f"https://github.com/{expected['repository']}/releases/tag/{expected['tag']}",
            "Published release version/source/public prerelease metadata differs")
    require(tag.get("ref") == "refs/tags/" + expected["tag"] and
            tag.get("object", {}).get("type") == "commit" and
            tag["object"].get("sha") == expected["source"],
            "Published tag does not point directly at the checked source")
    assets = metadata.get("assets")
    require(isinstance(assets, list) and all(isinstance(asset, dict) for asset in assets),
            "Published release has no valid asset list")
    apks = [asset for asset in assets if str(asset.get("name", "")).lower().endswith(".apk")]
    require(len(apks) == 1, "Release must contain exactly one APK")
    asset = apks[0]
    require(asset.get("name") == expected["asset"] and asset.get("state") == "uploaded" and
            type(asset.get("id")) is int and asset["id"] > 0 and
            type(asset.get("size")) is int and asset["size"] == expected["bytes"] and
            asset.get("browser_download_url") == expected["url"],
            "Published APK name, upload state, size or exact public URL differs")
    return asset


ANONYMOUS_HEADERS = {"User-Agent": "lumo-public-apk-verification", "Accept-Encoding": "identity"}


def require_https(url):
    parsed = urllib.parse.urlsplit(url)
    require(parsed.scheme == "https" and parsed.hostname and
            parsed.username is None and parsed.password is None,
            "Anonymous APK request/redirect must remain credential-free HTTPS")


class AnonymousRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, request, response, code, message, headers, url):
        require_https(url)
        redirected = super().redirect_request(request, response, code, message, headers, url)
        if redirected is not None:
            # Retain no ambient or cross-host credentials/cookies on CDN redirects.
            redirected.headers = dict(urllib.request.Request(url, headers=ANONYMOUS_HEADERS).headers)
            redirected.unredirected_hdrs = {}
        return redirected


def download_public(expected):
    require_https(expected["url"])
    # A fresh opener has no auth/cookie handlers and ignores the global opener.
    # Disable ambient authenticated proxies; GH_TOKEN is used only by gh above.
    opener = urllib.request.build_opener(urllib.request.ProxyHandler({}), AnonymousRedirect())
    for attempt in range(1, 4):
        try:
            request = urllib.request.Request(expected["url"], headers=ANONYMOUS_HEADERS)
            size, sha = 0, hashlib.sha256()
            with opener.open(request, timeout=60) as response:
                require(response.status == 200, "Public APK response is not HTTP 200")
                require_https(response.geturl())
                while block := response.read(4 * 1024 * 1024):
                    size += len(block)
                    require(size <= expected["bytes"], "Public APK exceeds the checked byte count")
                    sha.update(block)
            require(size == expected["bytes"], "Public APK byte count differs")
            require(sha.hexdigest() == expected["sha256"], "Public APK SHA-256 differs")
            return {"url": expected["url"], "bytes": size, "sha256": sha.hexdigest(),
                    "httpStatus": 200, "authorizationHeaderSent": False,
                    "entireFileRead": True, "attempt": attempt,
                    "verifiedUtc": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())}
        except (urllib.error.URLError, OSError, http.client.IncompleteRead):
            if attempt == 3:
                raise
            time.sleep(3)


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("command", choices=("absent", "verify"))
    parser.add_argument("--release-dir", type=Path, default=Path("release"))
    args = parser.parse_args(argv)
    directory = args.release_dir
    delivery_path, build_path = directory / "DELIVERY.json", directory / "BUILD-PROVENANCE.json"
    expected = expected_candidate(json.loads(delivery_path.read_text()),
                                  json.loads(build_path.read_text()), os.environ)
    verified_path = directory / "PUBLIC-DOWNLOAD-VERIFIED.json"
    require(not verified_path.exists(), "Refusing to reuse an earlier public verification")
    if args.command == "absent":
        path = directory / "PUBLIC-ABSENCE.json"
        require(not path.exists(), "Refusing to reuse an earlier absence check")
        require_absent(expected, path)
        return
    evidence = {}
    for name, endpoint in (("PUBLIC-DOWNLOAD.json", "releases/tags/"),
                           ("PUBLIC-TAG.json", "git/ref/tags/")):
        path = directory / name
        require(not path.exists(), "Refusing to replace earlier public metadata")
        value = json.loads(subprocess.check_output(
            github_command(expected, endpoint + expected["tag"]), text=True, timeout=60))
        write_json(path, value)
        evidence[name] = value
    asset = verify_release(evidence["PUBLIC-DOWNLOAD.json"], evidence["PUBLIC-TAG.json"], expected)
    result = download_public(expected)
    write_json(verified_path, {"schemaVersion": 1, "candidate": expected, "assetId": asset["id"],
                              "deliverySha256": digest(delivery_path),
                              "buildProvenanceSha256": digest(build_path),
                              "publicMetadataSha256": digest(directory / "PUBLIC-DOWNLOAD.json"),
                              "publicTagSha256": digest(directory / "PUBLIC-TAG.json"), **result})


if __name__ == "__main__":
    main()
