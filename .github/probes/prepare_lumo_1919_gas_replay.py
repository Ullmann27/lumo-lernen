#!/usr/bin/env python3
"""Extract immutable original Android failure inputs for an offline harness replay."""
from __future__ import annotations
import hashlib
import io
import json
import os
from pathlib import Path, PurePosixPath
import re
import tempfile
import urllib.error
import urllib.parse
import urllib.request
import zipfile
from PIL import Image

REPO = "Ullmann27/lumo-lernen"
RUN = 37975946198
APP = "d07b2b48593b939a2a0446fcb83a25a2b2a59db6"
GODOT = "d140e5b05cb5afacfe675559b78da4254cb1daed"
APK_SHA = "8e2ea31fed333fd8e89becd073b100c53ce9449017badb43ab4bc28022cc51aa"
API = "https://api.github.com"
OUT = Path("gas-replay-fixture")
OUT.mkdir()
TOKEN = os.environ["LUMO_READ_TOKEN"]
HEADERS = {"Authorization": "Bearer " + TOKEN, "Accept": "application/vnd.github+json",
           "X-GitHub-Api-Version": "2022-11-28"}
ARTIFACTS = []

def require(value, message):
    if not value:
        raise RuntimeError(message)

def sha(raw):
    return hashlib.sha256(raw).hexdigest()

def api_json(path):
    req = urllib.request.Request(API + "/repos/" + REPO + path, headers=HEADERS)
    with urllib.request.urlopen(req, timeout=45) as response:
        return json.load(response)

class NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        return None

def archive(artifact):
    require(not artifact["expired"], "Expired artifact")
    require(artifact["workflow_run"]["id"] == RUN and
            artifact["workflow_run"]["head_sha"] == APP, "Artifact source mismatch")
    require(0 < artifact["size_in_bytes"] < 1500000000, "Artifact size budget")
    expected = artifact["digest"]
    require(re.fullmatch(r"sha256:[0-9a-f]{64}", expected or ""), "Missing archive digest")
    req = urllib.request.Request(
        API + f"/repos/{REPO}/actions/artifacts/{artifact['id']}/zip", headers=HEADERS)
    try:
        urllib.request.build_opener(NoRedirect).open(req, timeout=45)
    except urllib.error.HTTPError as response:
        require(response.code in (302, 303, 307), "Artifact API did not redirect")
        location = response.headers.get("Location", "")
    else:
        raise RuntimeError("Expected artifact redirect")
    require(urllib.parse.urlsplit(location).scheme == "https", "Non-HTTPS artifact transfer")
    # The signed cross-host request deliberately contains no GitHub Authorization header.
    path = Path(tempfile.gettempdir()) / ("lumo-audit-" + str(artifact["id"]) + ".zip")
    digest = hashlib.sha256()
    count = 0
    with urllib.request.urlopen(location, timeout=120) as response, path.open("wb") as dest:
        while True:
            chunk = response.read(1024 * 1024)
            if not chunk:
                break
            count += len(chunk)
            require(count <= artifact["size_in_bytes"], "Archive exceeds declared size")
            digest.update(chunk)
            dest.write(chunk)
    require(count == artifact["size_in_bytes"] and "sha256:" + digest.hexdigest() == expected,
            "Archive bytes or hash differ")
    z = zipfile.ZipFile(path)
    require(len(z.infolist()) <= 5000, "Archive entry budget")
    require(sum(i.file_size for i in z.infolist()) <= 4000000000, "Expanded archive budget")
    require(len(z.namelist()) == len(set(z.namelist())), "Duplicate archive names")
    for item in z.infolist():
        p = PurePosixPath(item.filename)
        require(not p.is_absolute() and ".." not in p.parts and "\\" not in item.filename,
                "Unsafe archive path")
        require(not item.flag_bits & 1, "Encrypted archive")
        require((item.external_attr >> 16) & 0o170000 != 0o120000, "Symlink archive entry")
    ARTIFACTS.append({"id": artifact["id"], "name": artifact["name"], "bytes": count,
                      "sha256": digest.hexdigest(), "entries": len(z.infolist())})
    return z

def member(z, suffix):
    matches = [n for n in z.namelist() if n == suffix or n.endswith("/" + suffix)]
    require(len(matches) == 1, "Expected one archive member: " + suffix)
    return matches[0]


artifact = api_json("/actions/artifacts/11641916981")
require(artifact["size_in_bytes"] == 136961576 and artifact["digest"] ==
        "sha256:a1543a51c0d5782f011b6ca6fb944d22c9efc33000299c3f21470f8602e4df2e",
        "Expected exact original API36 failure archive")
fixture_files = {}
with archive(artifact) as z:
    raw_result = z.read(member(z, "full-race/result.json"))
    result = json.loads(raw_result)
    require(result["status"] == "FAIL" and result["source"] == APP
            and result["harness"] == APP and result["godot"] == GODOT
            and result["apk_sha256"] == APK_SHA and result["android_sdk"] == 36,
            "Failure source identity differs")
    names = []
    for index in range(9):
        names += [f"enable-public-auto-gas-{index}.png",
                  f"enable-public-auto-gas-{index}-ocr.json"]
    names += [f"enable-public-auto-gas-{index}-observed-scroll.json" for index in range(1, 9)]
    names += ["result.json"]
    for name in names:
        entry = member(z, "full-race/" + name)
        raw = z.read(entry)
        require(0 < len(raw) <= 6000000, "Fixture file exceeds budget")
        if name.endswith(".png"):
            with Image.open(io.BytesIO(raw)) as im:
                require(im.format == "PNG" and im.size == (1920, 1080), "Unexpected original frame")
                im.load()
        else:
            json.loads(raw)
        (OUT / name).write_bytes(raw)
        fixture_files[name] = sha(raw)
manifest = {"status": "ORIGINAL_FAILURE_INPUTS_ONLY", "source_app": APP,
            "source_godot": GODOT, "source_harness": APP, "apk_sha256": APK_SHA,
            "original_run": RUN, "original_job": 113988997647,
            "archive": ARTIFACTS[0], "files": fixture_files,
            "scope": "Original screenshot/OCR bytes for reader replay, not a new Android run"}
(OUT / "MANIFEST.json").write_text(json.dumps(manifest, indent=2) + "\n")
print("LUMO_REPLAY_FIXTURE " + json.dumps(manifest), flush=True)
