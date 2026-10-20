#!/usr/bin/env python3
"""Checkpoint in-progress Lumo/Codex work to GitHub without touching main.

Run with: python3 tools/lumo_autosave.py once
Background in an authenticated development workspace:
  nohup python3 -u tools/lumo_autosave.py watch --interval 120 \
    > /tmp/lumo-autosave.log 2>&1 < /dev/null &

Important: a suspended/destroyed cloud workspace may stop the watcher.
The agent MUST checkpoint explicitly after each meaningful implementation unit.
"""
from __future__ import annotations

import argparse
import datetime as dt
import os
from pathlib import Path, PurePosixPath
import re
import subprocess
import sys
import time

ALLOWED_REPOS = re.compile(
    r"(^|[/:])Ullmann27/(lumo-lernen|lumo-godot)(\.git)?$",
    re.IGNORECASE,
)
ROOTS = {
    "lib", "test", "assets", "docs", "scripts", "tools", "android",
    "ios", "web", "config", ".github",
}
ROOT_FILES = {
    "pubspec.yaml", "pubspec.lock", "analysis_options.yaml",
    "project.godot", "AGENTS.md", "CLAUDE.md", "CODEX_START.md",
    "README.md",
}
SUFFIXES = {
    ".dart", ".gd", ".gdshader", ".tscn", ".tres", ".scn", ".cs",
    ".kt", ".java", ".xml", ".gradle", ".kts", ".yaml", ".yml",
    ".json", ".arb", ".md", ".txt", ".sh", ".py", ".js", ".mjs",
    ".ts", ".tsx", ".css", ".html", ".svg", ".png", ".jpg",
    ".jpeg", ".webp", ".glb", ".gltf", ".wav", ".ogg", ".mp3",
    ".ttf", ".otf", ".cfg", ".ini", ".toml", ".gitignore",
}
FORBIDDEN_PARTS = (
    ".env", "credentials", "credential", "secrets", "secret",
    "private_key", "service-account", "service_account",
    ".keystore", ".jks", ".pem", ".p12", ".pfx", "local.properties",
    "id_rsa", "id_ed25519", "google-services.json", "google-services",
    "firebase-adminsdk", "gradle-cache", "keychain",
)
DENIED_DIRS = {
    ".git", ".dart_tool", "build", ".gradle", ".idea", ".venv",
    "node_modules", "coverage", "dist", ".pytest_cache",
}
SECRET_PATTERNS = (
    re.compile(rb"\b(?:sk-proj-|sk_live_|gsk_|ghp_|gho_|github_pat_)[a-zA-Z0-9_-]{16,}\b"),
    re.compile(rb"-----BEGIN [A-Z ]*PRIVATE KEY-----"),
    re.compile(rb"\bAIza[a-zA-Z0-9_-]{25,}\b"),
    re.compile(
        rb"\b(?:OPENAI_API_KEY|GROQ_API_KEY|GITHUB_TOKEN|AWS_SECRET_ACCESS_KEY)"
        rb"\s*[:=]\s*['\"][^'\"\r\n]{12,}['\"]"
    ),
)
MAX_FILE_BYTES = 16 * 1024 * 1024
TEXT_SUFFIXES = {
    ".dart", ".gd", ".gdshader", ".tscn", ".tres", ".cs", ".kt",
    ".java", ".xml", ".gradle", ".kts", ".yaml", ".yml", ".json",
    ".arb", ".md", ".txt", ".sh", ".py", ".js", ".mjs", ".ts",
    ".tsx", ".css", ".html", ".svg", ".cfg", ".ini", ".toml",
}
GIT_ENV = os.environ.copy()
GIT_ENV["GIT_TERMINAL_PROMPT"] = "0"


def git(*args: str, check: bool = True) -> subprocess.CompletedProcess[bytes]:
    result = subprocess.run(
        ["git", *args], stdout=subprocess.PIPE, stderr=subprocess.PIPE,
        env=GIT_ENV, check=False,
    )
    if check and result.returncode:
        # Never echo an authenticated remote URL or secret-containing diff.
        raise RuntimeError(f"git {args[0]} failed with code {result.returncode}")
    return result


def log(message: str) -> None:
    print(f"[LUMO-CHECKPOINT] {message}", flush=True)


def safe_path(value: str) -> bool:
    if not value or value.startswith("/") or "\\" in value:
        return False
    p = PurePosixPath(value)
    if ".." in p.parts or not p.parts or any(part in DENIED_DIRS for part in p.parts):
        return False
    if p.parts[0] not in ROOTS and value not in ROOT_FILES:
        return False
    low = value.lower()
    if any(x in low for x in FORBIDDEN_PARTS):
        return False
    if p.suffix.lower() not in SUFFIXES and value not in ROOT_FILES:
        return False
    return True


def safe_content(value: str) -> bool:
    p = Path(value)
    if not p.exists():
        # Deletion of an already tracked safe-path source file is versioned.
        return True
    if p.is_symlink() or not p.is_file() or p.stat().st_size > MAX_FILE_BYTES:
        return False
    if p.suffix.lower() in TEXT_SUFFIXES or value in ROOT_FILES:
        data = p.read_bytes()
        if any(pattern.search(data) for pattern in SECRET_PATTERNS):
            return False
    return True


def null_paths(output: bytes) -> set[str]:
    return {os.fsdecode(x) for x in output.split(b"\0") if x}


def eligible_files() -> tuple[list[str], list[str]]:
    tracked = null_paths(git("diff", "--name-only", "-z", "HEAD", "--").stdout)
    untracked = null_paths(git("ls-files", "--others", "--exclude-standard", "-z").stdout)
    chosen, rejected = [], []
    for path in sorted(tracked | untracked):
        if safe_path(path) and safe_content(path):
            chosen.append(path)
        else:
            rejected.append(path)
    return chosen, rejected


def ensure_branch() -> str:
    origin = git("remote", "get-url", "origin").stdout.decode().strip()
    # No push to a different repository even if a token has wide permissions.
    if not ALLOWED_REPOS.search(origin):
        raise RuntimeError("origin is not one of the two authorized Lumo repositories")
    branch = git("branch", "--show-current").stdout.decode().strip()
    if branch in ("", "main", "master"):
        # This creates a NEW reversible working branch; main stays untouched.
        stamp = dt.datetime.now(dt.timezone.utc).strftime("%Y%m%d-%H%M%S")
        branch = f"checkpoint/lumo-cloud-{stamp}-{os.getpid()}"
        git("switch", "-c", branch)
        log(f"Created protected work branch: {branch}")
    return branch


def checkpoint() -> int:
    branch = ensure_branch()
    if git("diff", "--cached", "--quiet", check=False).returncode != 0:
        log("BLOCKED: already-staged changes exist. Commit or unstage them deliberately.")
        return 4
    approved, skipped = eligible_files()
    if skipped:
        log(f"Safety filter excluded {len(skipped)} paths; review manually.")
        for entry in skipped[:12]:
            log(f"  excluded: {entry}")
    if not approved:
        log(f"Nothing new to save on {branch}.")
        return 0
    # Allow deletion of tracked safe-path files; never add arbitrary new keys.
    for start in range(0, len(approved), 40):
        git("add", "-A", "--", *approved[start:start + 40])
    if git("diff", "--cached", "--quiet", check=False).returncode == 0:
        log("No changes after staging.")
        return 0
    timestamp = dt.datetime.now(dt.timezone.utc).strftime("%Y-%m-%d %H:%M UTC")
    git(
        "-c", "user.name=Lumo Cloud Checkpoint",
        "-c", "user.email=checkpoint@users.noreply.github.com",
        "commit", "-m", f"checkpoint(lumo): preserve cloud work at {timestamp} [skip ci]",
    )
    sha = git("rev-parse", "--short", "HEAD").stdout.decode().strip()
    log(f"LOCAL SAVED: commit {sha} ({len(approved)} paths) on {branch}")
    pushed = git("push", "origin", f"HEAD:refs/heads/{branch}", check=False)
    if pushed.returncode != 0:
        log("REMOTE NOT SAVED: push failed. Check GitHub authentication and retry.")
        return 3
    log(f"REMOTE SAVED: {branch}@{sha}. A new Codex session can resume from GitHub.")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("mode", choices=("once", "watch", "check"), nargs="?", default="once")
    parser.add_argument("--interval", type=int, default=120)
    args = parser.parse_args()
    os.chdir(Path(__file__).resolve().parents[1])
    if args.mode == "check":
        branch = git("branch", "--show-current").stdout.decode().strip() or "(detached)"
        log(f"Working branch: {branch}; no branch mutation in check mode.")
        approved, skipped = eligible_files()
        log(f"Allowed pending paths: {len(approved)}; filtered: {len(skipped)}")
        return 0
    if args.mode == "once":
        return checkpoint()
    if args.interval < 60:
        parser.error("--interval must be at least 60 seconds")
    log(f"Watch mode active; checking at most once every {args.interval}s.")
    try:
        while True:
            try:
                result = checkpoint()
                if result:
                    log(f"Checkpoint returned {result}; retrying after interval.")
            except Exception as exc:
                log(f"Checkpoint blocked: {type(exc).__name__}: {exc}")
            time.sleep(args.interval)
    except KeyboardInterrupt:
        log("Watch stopped; run 'once' for a final explicit checkpoint.")
        return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except (RuntimeError, OSError, ValueError) as error:
        log(f"FAILED: {type(error).__name__}: {error}")
        sys.exit(2)
