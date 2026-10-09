#!/usr/bin/env python3
"""Verify original API35 Android race evidence; never rebuild or rerun the game."""
from __future__ import annotations
import base64
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
APK_BYTES = 205316096
PCK_SHA = "71920fb7f5c9ec798032fe2317ca22bf4eecd91b08699daa22ed360e0b45a7f8"
API = "https://api.github.com"
OUT = Path("audit-output")
OUT.mkdir()
TOKEN = os.environ["LUMO_READ_TOKEN"]
HEADERS = {"Authorization": "Bearer " + TOKEN, "Accept": "application/vnd.github+json",
           "X-GitHub-Api-Version": "2022-11-28"}
EXPECTED_JOBS = {
    "verify-and-build": 113974160562, "android (build, 35)": 113988997747,
    "android (puzzle, 35)": 113988997645, "android (rhythm, 35)": 113988997663,
    "android (treasure, 35)": 113988998247, "android (kart, 35)": 113988997714,
    "android (kart, 36)": 113988997647,
}
ARTIFACTS = []
FILES = []
IMAGES = []
ANDROID = {}

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

def read_json(z, suffix):
    return json.loads(z.read(member(z, suffix)))

def write_file(relative, raw, artifact_id, original):
    target = OUT / relative
    target.parent.mkdir(parents=True, exist_ok=True)
    require(not target.exists(), "Duplicate output path")
    target.write_bytes(raw)
    FILES.append({"file": relative, "bytes": len(raw), "sha256": sha(raw),
                  "artifact_id": artifact_id, "archive_member": original})

def png(z, suffix, relative, artifact_id, display=False):
    name = member(z, suffix)
    raw = z.read(name)
    with Image.open(io.BytesIO(raw)) as im:
        require(im.format == "PNG", "PNG format")
        im.load()
        width, height = im.size
        extrema = im.convert("RGB").getextrema()
    # Diagnostic captures remain evidence even if blank, tiny or visually broken.
    write_file(relative, raw, artifact_id, name)
    meta = {"file": relative, "width": width, "height": height, "bytes": len(raw),
            "sha256": sha(raw), "artifact_id": artifact_id, "archive_member": name}
    IMAGES.append(meta)
    if display:
        require(len(raw) < 4000000, "Visual transfer budget")
        encoded = base64.b64encode(raw).decode("ascii")
        key = "frame" + str(len(IMAGES))
        count = (len(encoded) + 49999) // 50000
        print("LUMO_PNG_BEGIN " + json.dumps(dict(meta, key=key, chunks=count)), flush=True)
        for number in range(count):
            print(f"LUMO_PNG_CHUNK {key} {number} " + encoded[number*50000:(number+1)*50000],
                  flush=True)
        print("LUMO_PNG_END " + key, flush=True)
    return meta

def copy_small_reports(z, prefix, artifact_id):
    for entry in z.infolist():
        if (entry.is_dir() or PurePosixPath(entry.filename).suffix.lower()
                not in (".json", ".jsonl", ".log", ".txt", ".md")
                or entry.file_size > 5000000):
            continue
        write_file(prefix + "/" + entry.filename, z.read(entry.filename),
                   artifact_id, entry.filename)

def validate_identity(result, game, sdk):
    require(result["status"] == "PASS", "Android result not PASS")
    require(result["source"] == APP and result["godot"] == GODOT and
            result["apk_sha256"] == APK_SHA and result["android_sdk"] == sdk,
            "Android result identity mismatch")
    require(result["harness"] == APP and result["tested_games"] == [game],
            "Android harness or scope mismatch")
    require(result["update"]["status"] == "PASS" and result["update"]["profile_retained"]
            and result["update"]["offline"], "Android update evidence incomplete")


jobset = api_json(f"/actions/runs/{RUN}/jobs?filter=latest&per_page=100")["jobs"]
selected = [j for j in jobset if j["id"] == 113988997714]
require(len(selected) == 1 and selected[0]["head_sha"] == APP
        and selected[0]["status"] == "completed" and selected[0]["conclusion"] == "success",
        "Expected exact successful original API35 Kart job")
artifact = api_json("/actions/artifacts/11641449935")
require(artifact["size_in_bytes"] == 266654314 and artifact["digest"] ==
        "sha256:e02a93fb191c9cb2173b3566c272599cb8fd50976f69adf3f8f27d363d32ca31",
        "Expected exact original API35 Kart archive")
with archive(artifact) as z:
    result = read_json(z, "full-race/result.json")
    require(result["status"] == "PASS" and result["source"] == APP
            and result["harness"] == APP and result["godot"] == GODOT
            and result["apk_sha256"] == APK_SHA and result["android_sdk"] == 35,
            "Expected matching successful API35 race evidence")
    require(result["installed_apk"] == {"sha256": APK_SHA, "bytes": APK_BYTES, "matches_candidate": True},
            "Installed APK readback differs")
    require(result["native_result"]["checkpoints"] == 16
            and result["pause_resume"]["status"] == "PASS"
            and result["offline_result_recovery"]["status"] == "PASS"
            and result["replay_deduplication"]["status"] == "PASS"
            and result["video"]["status"] == "PASS",
            "Actual completion evidence is incomplete")
    copy_small_reports(z, "original-reports", artifact["id"])
    print("LUMO_API35_PNG_INDEX " + json.dumps([n for n in z.namelist()
          if n.endswith(".png") and "full-race/" in n]), flush=True)
    print("LUMO_API35_RESULT " + json.dumps(result, ensure_ascii=False), flush=True)
    for name in ("01-garage-resize-outer-before.png", "02-fresh-race-phone.png",
                 "04-driving-060.png", "06-completed-result-phone.png",
                 "07-finished-result-resize-inner.png", "14-final-offline-restart-home.png"):
        png(z, "full-race/" + name, "android-api35/" + name, artifact["id"], display=True)
summary = {"status": "ORIGINAL_API35_RACE_EVIDENCE_VERIFIED", "parent_run": RUN,
           "parent_run_conclusion": "failure", "job_id": selected[0]["id"],
           "source_app": APP, "source_godot": GODOT, "apk_sha256": APK_SHA,
           "audit_commit": os.environ["GITHUB_SHA"], "audit_run": int(os.environ["GITHUB_RUN_ID"]),
           "archives": ARTIFACTS, "files": FILES, "images": IMAGES, "original_result": result,
           "scope": "Read-only exact-byte audit of the original API35 success; API36 failure remains"}
(OUT / "API35-ORIGINAL-AUDIT.json").write_text(json.dumps(summary, ensure_ascii=False, indent=2) + "\n")
print("[Lumo1919Api35Evidence] Original successful Android race bytes and unchanged screenshots verified",
      flush=True)
