#!/usr/bin/env python3
"""Read original signature output from the failed setup job; no test or APK mutation."""
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
RUN = 37987154620
APP = "5b40528b19023ec83e0696d836766f71e7f5cea4"
GODOT = "d140e5b05cb5afacfe675559b78da4254cb1daed"
APK_SHA = "8e2ea31fed333fd8e89becd073b100c53ce9449017badb43ab4bc28022cc51aa"
API = "https://api.github.com"
OUT = Path("audit-output")
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



artifact = api_json("/actions/artifacts/11643567447")
require(artifact["size_in_bytes"] == 8912041 and artifact["digest"] ==
        "sha256:8747cb54a5f370ee34c4b4abdf76c8cc386fb884284d72562c733cc536d259bd",
        "Expected exact signature setup failure artifact")
records = []
with archive(artifact) as z:
    names = [n for n in z.namelist() if n.endswith("-signature.txt")]
    require(names, "No original signature output was saved")
    for name in names:
        raw = z.read(name)
        require(0 < len(raw) < 100000, "Unexpected signature output size")
        target = OUT / PurePosixPath(name).name
        target.write_bytes(raw)
        record = {"file": name, "bytes": len(raw), "sha256": sha(raw), "text": raw.decode("utf-8")}
        records.append(record)
        print("LUMO_SIGNATURE_RAW " + json.dumps(record), flush=True)
    for name in ("original.json", "candidate.json", "HARNESS-BINDING.json"):
        raw = z.read(member(z, name))
        require(len(raw) < 500000, "Replay report size")
        (OUT / name).write_bytes(raw)
        print("LUMO_REPLAY_REPORT " + json.dumps({"file": name, "sha256": sha(raw),
              "data": json.loads(raw)}), flush=True)
(OUT / "SIGNATURE-INSPECTION.json").write_text(json.dumps({
    "status": "ORIGINAL_SETUP_FAILURE_INSPECTED", "run": RUN,
    "harness": APP, "archive": ARTIFACTS[0], "signatures": records,
    "scope": "No emulator run or signature acceptance claimed"}, indent=2) + "\n")
