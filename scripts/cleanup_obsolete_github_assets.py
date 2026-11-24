#!/usr/bin/env python3
"""Conservative post-release cleanup. Never runs before a verified APK release.

Only six individually reviewed October 3 draft releases may be deleted.
Only old, reproducible APK/Android-tour Actions artifacts may be pruned.
Real published releases, Git history, source code, screenshots and open PRs
are never deleted. All API mutations require the explicit --execute flag.
"""
from __future__ import annotations

import argparse
from datetime import datetime, timedelta, timezone
import json
import os
import re
from urllib import error, request

REPO = "Ullmann27/lumo-lernen"
SAFE_DRAFT_TAGS = frozenset(f"unified-build-{n}" for n in range(275, 281))
MIN_DRAFT_AGE_DAYS = 14
MIN_ARTIFACT_AGE_DAYS = 21
MAX_ARTIFACT_DELETES = 250

SAFE_ARTIFACT_PATTERNS = (
    re.compile(r"^lumo-[0-9]{4}-arm64-verified$"),
    re.compile(r"^lumo-[0-9]{4}-android-tour$"),
    re.compile(r"^lumo-lernen-kart-unified-2026-candidate$"),
)

def _date(raw: str) -> datetime:
    return datetime.fromisoformat(raw.replace("Z", "+00:00"))

def deletable_draft(release: dict, now: datetime) -> bool:
    return (
        release.get("draft") is True
        and release.get("tag_name") in SAFE_DRAFT_TAGS
        and bool(release.get("created_at"))
        and _date(release["created_at"]) < now - timedelta(days=MIN_DRAFT_AGE_DAYS)
    )

def deletable_artifact(artifact: dict, now: datetime) -> bool:
    name = artifact.get("name", "")
    return (
        artifact.get("expired") is False
        and isinstance(artifact.get("id"), int)
        and bool(artifact.get("created_at"))
        and _date(artifact["created_at"]) < now - timedelta(days=MIN_ARTIFACT_AGE_DAYS)
        and any(pattern.fullmatch(name) for pattern in SAFE_ARTIFACT_PATTERNS)
    )

def api(method: str, endpoint: str, token: str):
    if not endpoint.startswith("/repos/" + REPO + "/"):
        raise ValueError("Unrecognized GitHub scope")
    url = "https://api.github.com" + endpoint
    headers = {
        "Authorization": "Bearer " + token,
        "Accept": "application/vnd.github+json",
        "X-GitHub-Api-Version": "2022-11-28",
        "User-Agent": "lumo-post-release-cleanup-1986",
    }
    req = request.Request(url, headers=headers, method=method)
    with request.urlopen(req, timeout=35) as resp:
        data = resp.read()
        return json.loads(data) if data else None

def paged(endpoint: str, token: str, *, key: str | None = None):
    entries = []
    for page in range(1, 51):
        sep = "&" if "?" in endpoint else "?"
        data = api("GET", f"{endpoint}{sep}per_page=100&page={page}", token)
        values = data[key] if key else data
        if not isinstance(values, list):
            raise RuntimeError("Unexpected GitHub list response")
        entries.extend(values)
        if len(values) < 100:
            return entries
    raise RuntimeError("Pagination exceeds safe audit limit; no deletes")

def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--execute", action="store_true")
    args = parser.parse_args()
    token = os.environ.get("GH_TOKEN", "")
    if not token:
        raise RuntimeError("Required GH_TOKEN is missing")
    now = datetime.now(timezone.utc)
    releases = paged(f"/repos/{REPO}/releases", token)
    artifacts = paged(f"/repos/{REPO}/actions/artifacts", token, key="artifacts")
    obsolete_drafts = [r for r in releases if deletable_draft(r, now)]
    obsolete_artifacts = [a for a in artifacts if deletable_artifact(a, now)]
    if len(obsolete_artifacts) > MAX_ARTIFACT_DELETES:
        obsolete_artifacts = sorted(
            obsolete_artifacts, key=lambda a: a["created_at"]
        )[:MAX_ARTIFACT_DELETES]
    report = {
        "execution": args.execute,
        "protected_releases": ["1983", "1984", "1985", "1986"],
        "draft_tags": [r["tag_name"] for r in obsolete_drafts],
        "draft_bytes": sum(a.get("size", 0) for r in obsolete_drafts for a in r.get("assets", [])),
        "artifact_count": len(obsolete_artifacts),
        "artifact_bytes": sum(a.get("size_in_bytes", 0) for a in obsolete_artifacts),
        "errors": [],
    }
    print(json.dumps(report, ensure_ascii=False, indent=2), flush=True)
    if not args.execute:
        return
    # Any tagged, published or still-recent release can NEVER reach deletion.
    for r in obsolete_drafts:
        try:
            api("DELETE", f"/repos/{REPO}/releases/{r['id']}", token)
            print("Removed old draft release:", r["tag_name"], flush=True)
        except (error.HTTPError, error.URLError, OSError) as exc:
            report["errors"].append(f"release {r['tag_name']}: {exc}")
    for a in obsolete_artifacts:
        try:
            api("DELETE", f"/repos/{REPO}/actions/artifacts/{a['id']}", token)
            print("Removed expired-candidate artifact:", a["id"], a["name"], flush=True)
        except (error.HTTPError, error.URLError, OSError) as exc:
            report["errors"].append(f"artifact {a['id']}: {exc}")
    print("LUMO_CLEANUP_RESULT=" + json.dumps(report, ensure_ascii=False), flush=True)
    if report["errors"]:
        raise RuntimeError("Some scoped cleanup actions failed; details above")

if __name__ == "__main__":
    main()
