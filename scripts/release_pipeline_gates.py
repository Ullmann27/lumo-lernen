#!/usr/bin/env python3
"""Release gates for the family preview APK download channel.

These checks keep a later coachpreview-build-N update installable over the
already-published family app (same package, same signing certificate, newer
versionCode, ARM64 present). They do not publish a GitHub release.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import re
import sys
from pathlib import Path

PACKAGE_ID = "dev.ullmann.lumo.lumo_lernen.coachpreview"
EXPECTED_CERT_SHA256 = "a6b1ef61bf59db4e0794c742aeb3b5506d130f4d21175c9975140e6acdb80702"
APK_ASSET_NAME = "Lumo-Lernen-Neu.apk"
SHA256_ASSET_NAME = "Lumo-Lernen-Neu.apk.sha256"
TAG_PREFIX = "coachpreview-build-"
# Last published family prerelease at the time this pipeline was repaired.
# A live GitHub query or --last-published may raise this floor, never lower it.
KNOWN_LAST_PUBLISHED = 2004
ARM64_ABI = "arm64-v8a"


def parse_pubspec_version(text: str) -> tuple[str, int]:
    match = re.search(r"^version:\s*([^\s+]+)\+(\d+)\s*$", text, re.MULTILINE)
    if match is None:
        raise ValueError("pubspec.yaml must declare version: name+build")
    return match.group(1), int(match.group(2))


def family_tag(version_code: int) -> str:
    if version_code <= 0:
        raise ValueError("versionCode must be a positive integer")
    return f"{TAG_PREFIX}{version_code}"


def family_apk_download_url(tag: str) -> str:
    if not re.fullmatch(rf"{re.escape(TAG_PREFIX)}\d+", tag):
        raise ValueError(f"Refusing unexpected family tag: {tag}")
    return f"https://github.com/Ullmann27/lumo-lernen/releases/download/{tag}/{APK_ASSET_NAME}"


def published_family_builds(releases: list) -> list[int]:
    """Mirror the installed app: only published prereleases with the exact tag."""
    builds: list[int] = []
    for raw in releases:
        if not isinstance(raw, dict):
            continue
        if raw.get("draft") is not False or raw.get("prerelease") is not True:
            continue
        tag = str(raw.get("tag_name") or "")
        if not tag.startswith(TAG_PREFIX):
            continue
        digits = tag[len(TAG_PREFIX):]
        if not digits.isdigit():
            continue
        assets = raw.get("assets") or []
        names = {
            asset.get("name")
            for asset in assets
            if isinstance(asset, dict)
        }
        if APK_ASSET_NAME not in names:
            continue
        builds.append(int(digits))
    return sorted(set(builds))


def newest_published_family_build(releases: list) -> int:
    builds = published_family_builds(releases)
    return max(builds) if builds else 0


def effective_last_published(live_or_override: int | None) -> int:
    candidate = KNOWN_LAST_PUBLISHED if live_or_override is None else int(live_or_override)
    return max(KNOWN_LAST_PUBLISHED, candidate)


def assert_newer_than_published(version_code: int, last_published: int) -> None:
    floor = effective_last_published(last_published)
    if version_code <= floor:
        raise ValueError(
            f"versionCode {version_code} is not newer than last published "
            f"family build {floor}"
        )


def assert_package(package: str) -> None:
    if package != PACKAGE_ID:
        raise ValueError(f"Wrong package id {package!r}; expected {PACKAGE_ID}")


def assert_cert(certificate_sha256: str) -> None:
    digest = str(certificate_sha256 or "").strip().lower()
    if digest != EXPECTED_CERT_SHA256:
        raise ValueError(
            "Signing certificate SHA-256 does not match the installed family app "
            f"({EXPECTED_CERT_SHA256})"
        )


def assert_arm64(abis) -> None:
    actual = set(abis or [])
    if ARM64_ABI not in actual:
        raise ValueError(f"ARM64 ({ARM64_ABI}) missing from APK abis: {sorted(actual)}")


def sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def write_sha256_sidecar(apk: Path, destination: Path | None = None) -> Path:
    if not apk.is_file():
        raise ValueError(f"APK not found: {apk}")
    target = destination or (apk.parent / SHA256_ASSET_NAME)
    digest = sha256_file(apk)
    target.write_text(f"{digest}  {apk.name}\n", encoding="utf-8")
    return target


def evaluate_verification(info: dict, *, version_name: str, version_code: int) -> dict:
    assert_package(info.get("package", ""))
    assert_cert(str(info.get("signingCertificateSha256", "")))
    if int(info.get("versionCode", -1)) != version_code:
        raise ValueError(
            f"APK versionCode {info.get('versionCode')} does not match "
            f"declared {version_code}"
        )
    if str(info.get("versionName", "")) != version_name:
        raise ValueError(
            f"APK versionName {info.get('versionName')!r} does not match "
            f"declared {version_name!r}"
        )
    assert_arm64(info.get("abis"))
    digest = str(info.get("sha256") or "").strip().lower()
    if not re.fullmatch(r"[0-9a-f]{64}", digest):
        raise ValueError("APK verification is missing a SHA-256 digest")
    return {
        "package": PACKAGE_ID,
        "versionName": version_name,
        "versionCode": version_code,
        "signingCertificateSha256": EXPECTED_CERT_SHA256,
        "abis": list(info.get("abis") or []),
        "sha256": digest,
        "tag": family_tag(version_code),
        "apkAsset": APK_ASSET_NAME,
        "downloadUrl": family_apk_download_url(family_tag(version_code)),
    }


def evaluate_source(*, pubspec_text: str, last_published: int | None) -> dict:
    version_name, version_code = parse_pubspec_version(pubspec_text)
    floor = effective_last_published(last_published)
    assert_newer_than_published(version_code, floor)
    return {
        "versionName": version_name,
        "versionCode": version_code,
        "lastPublishedFamilyBuild": floor,
        "tag": family_tag(version_code),
        "package": PACKAGE_ID,
        "expectedCertificateSha256": EXPECTED_CERT_SHA256,
        "apkAsset": APK_ASSET_NAME,
        "downloadUrl": family_apk_download_url(family_tag(version_code)),
    }


def draft_release_notes(version_name: str, version_code: int, source_sha: str) -> str:
    tag = family_tag(version_code)
    return (
        f"Draft family update {version_name}+{version_code} ({tag}).\n"
        f"Source: {source_sha or 'unknown'}.\n\n"
        "This GitHub release is a DRAFT. The installed family app ignores drafts "
        "on purpose. Do not uninstall the existing app.\n\n"
        "When Heinz approves publication, convert this draft to a public "
        "prerelease (not Latest/stable). Required asset name remains "
        f"{APK_ASSET_NAME}. The in-app button then downloads:\n"
        f"{family_apk_download_url(tag)}\n\n"
        "Install as an update over the current family package "
        f"{PACKAGE_ID} without uninstalling, so profiles, learning progress "
        "and wallet data stay in place. Android will refuse the update if the "
        "signing certificate is not "
        f"{EXPECTED_CERT_SHA256}.\n"
    )


def _load_json(path: Path) -> dict | list:
    return json.loads(path.read_text(encoding="utf-8"))


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--pubspec", type=Path, default=Path("pubspec.yaml"))
    parser.add_argument("--verification", type=Path)
    parser.add_argument("--apk", type=Path)
    parser.add_argument("--releases-json", type=Path)
    parser.add_argument("--last-published", type=int)
    parser.add_argument("--write-sha256", type=Path)
    parser.add_argument("--source-sha", default="")
    args = parser.parse_args(argv)

    last_published = args.last_published
    if args.releases_json is not None:
        catalog = _load_json(args.releases_json)
        if not isinstance(catalog, list):
            raise SystemExit("releases JSON must be a list")
        last_published = max(
            effective_last_published(last_published),
            newest_published_family_build(catalog),
        )

    report = evaluate_source(
        pubspec_text=args.pubspec.read_text(encoding="utf-8"),
        last_published=last_published,
    )
    if args.verification is not None:
        info = _load_json(args.verification)
        if not isinstance(info, dict):
            raise SystemExit("verification JSON must be an object")
        report.update(
            evaluate_verification(
                info,
                version_name=report["versionName"],
                version_code=report["versionCode"],
            )
        )
        if args.apk is not None:
            actual = sha256_file(args.apk)
            if actual != report["sha256"]:
                raise SystemExit(
                    f"APK digest {actual} does not match verification {report['sha256']}"
                )
            report["apk"] = str(args.apk)
    elif args.apk is not None:
        raise SystemExit("Refusing to skip verify_unified_apk: pass --verification with --apk")

    if args.write_sha256 is not None:
        if args.apk is None:
            raise SystemExit("--write-sha256 requires --apk")
        sidecar = write_sha256_sidecar(args.apk, args.write_sha256)
        report["sha256File"] = str(sidecar)

    report["releaseNotes"] = draft_release_notes(
        report["versionName"], report["versionCode"], args.source_sha
    )
    json.dump(report, sys.stdout, indent=2)
    sys.stdout.write("\n")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except (OSError, ValueError, json.JSONDecodeError) as error:
        raise SystemExit(f"Release pipeline gate failed: {error}") from error
