#!/usr/bin/env python3
"""Use the declared app version and reject stale build-workflow overrides."""
import os
from pathlib import Path
import re


def resolve_version(pubspec: str, environment: dict) -> tuple[str, int]:
    match = re.search(r"^version:\s*([^\s+]+)\+(\d+)\s*$", pubspec, re.MULTILINE)
    if match is None:
        raise ValueError("pubspec.yaml must declare version: name+build")
    declared_name, declared_number = match.group(1), int(match.group(2))
    number = int(environment.get("LUMO_BUILD_NUMBER", declared_number))
    name = environment.get("LUMO_VERSION_NAME", declared_name)
    if number < declared_number:
        raise ValueError(f"Build {number} is older than declared app build {declared_number}")
    if not re.fullmatch(r"[0-9A-Za-z][0-9A-Za-z.+_-]*", name):
        raise ValueError("Invalid Android version name")
    return name, number


if __name__ == "__main__":
    try:
        print(*resolve_version(Path("pubspec.yaml").read_text(), os.environ))
    except ValueError as error:
        raise SystemExit(f"Build version rejected: {error}") from error
