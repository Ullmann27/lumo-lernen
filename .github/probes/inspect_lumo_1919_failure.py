#!/usr/bin/env python3
"""Read existing source-pinned 1919 artifacts; never build or run the game."""
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
    require(width >= 320 and height >= 300, "Unexpected image size")
    require(any(high - low > 30 for low, high in extrema), "Image lacks visible variation")
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
failed = [j for j in jobset if j["id"] == 113988997647]
require(len(failed) == 1 and failed[0]["head_sha"] == APP
        and failed[0]["status"] == "completed" and failed[0]["conclusion"] == "failure",
        "Expected the exact failed API36 job")
artifact = api_json("/actions/artifacts/11641916981")
require(artifact["size_in_bytes"] == 136961576 and artifact["digest"] ==
        "sha256:a1543a51c0d5782f011b6ca6fb944d22c9efc33000299c3f21470f8602e4df2e",
        "Expected exact failed-run archive")
with archive(artifact) as z:
    result = read_json(z, "full-race/result.json")
    require(result["status"] == "FAIL" and result["source"] == APP
            and result["godot"] == GODOT and result["apk_sha256"] == APK_SHA,
            "Expected matching failed race evidence")
    copy_small_reports(z, "original-reports", artifact["id"])
    inventory = [n for n in z.namelist() if n.endswith(".png") and "full-race/" in n]
    print("LUMO_DIAG_PNG_INDEX " + json.dumps(inventory), flush=True)
    print("LUMO_DIAG_RESULT " + json.dumps(result, ensure_ascii=False), flush=True)
    for suffix in ("enable-public-auto-gas-0.png", "enable-public-auto-gas-3.png",
                   "enable-public-auto-gas-6.png", "enable-public-auto-gas-9.png", "failure.png"):
        png(z, "full-race/" + suffix, "android-api36/" + suffix, artifact["id"], display=True)
summary = {"status": "INSPECTION_OF_FAILED_ANDROID_JOB", "parent_run": RUN,
           "job_id": failed[0]["id"], "source_app": APP, "source_godot": GODOT,
           "apk_sha256": APK_SHA, "audit_commit": os.environ["GITHUB_SHA"],
           "audit_run": int(os.environ["GITHUB_RUN_ID"]), "archives": ARTIFACTS,
           "files": FILES, "images": IMAGES, "original_result": result,
           "scope": "Read-only extraction of exact original failure evidence; no rerun, repair or approval"}
(OUT / "DIAGNOSTIC-AUDIT.json").write_text(json.dumps(summary, ensure_ascii=False, indent=2) + "\n")
print("[Lumo1919Diagnostic] Original failed-job bytes and five unchanged screenshots verified", flush=True)
