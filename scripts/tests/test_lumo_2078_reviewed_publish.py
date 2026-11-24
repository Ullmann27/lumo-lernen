"""Local publication guard tests; these fixtures are not runtime acceptance."""
import copy
import hashlib
import importlib.util
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import Mock, patch
from urllib.error import HTTPError
from urllib.request import Request

SCRIPTS = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(SCRIPTS))
spec = importlib.util.spec_from_file_location("publisher2078", SCRIPTS / "lumo_2078_reviewed_publish.py")
p = importlib.util.module_from_spec(spec)
spec.loader.exec_module(p)


def gates():
    repository = {"id": 1222433959, "full_name": p.REPOSITORY, "private": False}
    run = {"id": p.RUN, "head_sha": p.SOURCE, "run_attempt": 2, "status": "completed",
           "conclusion": "failure", "head_branch": "repair/lumo-device-bugs-2078",
           "path": ".github/workflows/lumo-2078-device-repair.yml", "event": "push",
           "repository": repository, "head_repository": repository.copy()}
    attempts = {}
    for attempt, failed_id in ((1, 138384742953), (2, 138386118647)):
        jobs = [{"id": job_id if attempt == 1 else job_id + 1000, "name": name,
                 "run_id": p.RUN, "head_sha": p.SOURCE, "run_attempt": attempt,
                 "status": "completed", "conclusion": "success"} for job_id, name in p.QUALITY.items()]
        jobs.append({"id": failed_id, "name": p.PUBLISHER_NAME, "run_id": p.RUN,
                     "head_sha": p.SOURCE, "run_attempt": attempt,
                     "status": "completed", "conclusion": "failure"})
        attempts[str(attempt)] = {"total_count": 4, "jobs": jobs}
    artifact = {"id": p.ARTIFACT, "name": "LUMO-2078-APK-45365478105", "expired": False,
                "size_in_bytes": 701710167,
                "digest": "sha256:1b52eac413a54f1f8406a76f2880cccec3294c5e16b6ee0705f38e0b4dc2e97e",
                "workflow_run": {"id": p.RUN, "head_sha": p.SOURCE,
                    "repository_id": 1222433959, "head_repository_id": 1222433959,
                    "head_branch": "repair/lumo-device-bugs-2078"}}
    return {"run": run, "attempts": attempts, "artifact": artifact}


def release_fixture(draft):
    owner = {"login": "Ullmann27", "id": 64243701}
    assets = {p.APK: {"bytes": p.APK_BYTES, "sha256": p.APK_SHA}}
    release = {"id": 200, "tag_name": p.TAG, "draft": draft, "prerelease": True,
               "author": owner, "html_url": "https://github.com/" + p.REPOSITORY + "/releases/tag/" + p.TAG,
               "assets": [{"id": 201, "name": p.APK, "state": "uploaded", "size": p.APK_BYTES,
                           "digest": "sha256:" + p.APK_SHA, "uploader": owner,
                           "browser_download_url": "https://github.com/" + p.REPOSITORY + "/releases/download/" + p.TAG + "/" + p.APK}]}
    ref = {"ref": "refs/tags/" + p.TAG, "object": {"type": "commit", "sha": p.SOURCE}}
    return release, ref, assets


class Guards(unittest.TestCase):
    def test_exact_request_rejects_wrong_source_owner_and_extra_field(self):
        p.validate_order(dict(p.EXPECTED))
        for change in ({"source": "0" * 40}, {"publisher_user_id": True},
                       {"publisher_login": "other"}, {"unexpected": "value"}):
            with self.subTest(change=change), self.assertRaises(ValueError):
                p.validate_order({**p.EXPECTED, **change})

    def test_original_quality_passes_keep_both_publishers_failed(self):
        p.verify_gates(gates())
        for section in ("1", "2"):
            data = gates()
            data["attempts"][section]["jobs"][-1]["conclusion"] = "success"
            with self.subTest(attempt=section), self.assertRaises(ValueError):
                p.verify_gates(data)

    def test_wrong_source_or_failed_quality_is_rejected(self):
        for mutation in ("source", "quality", "missing"):
            data = gates()
            if mutation == "source":
                data["run"]["head_sha"] = "0" * 40
            elif mutation == "quality":
                data["attempts"]["1"]["jobs"][0]["conclusion"] = "failure"
            else:
                data["attempts"]["1"]["jobs"][0]["id"] = 999
            with self.subTest(mutation=mutation), self.assertRaises(ValueError):
                p.verify_gates(data)

    def test_wrong_artifact_digest_size_or_owner_is_rejected(self):
        for key, value in (("digest", "sha256:" + "0" * 64), ("size_in_bytes", 1), ("id", 1)):
            data = gates()
            data["artifact"][key] = value
            with self.subTest(key=key), self.assertRaises(ValueError):
                p.verify_gates(data)
        data = gates()
        data["artifact"]["workflow_run"]["head_repository_id"] = 1
        with self.assertRaises(ValueError):
            p.verify_gates(data)

    def test_same_size_changed_bytes_are_rejected(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            path = root / "candidate.apk"
            path.write_bytes(b"original")
            expected = {path.name: {"bytes": 8, "sha256": hashlib.sha256(b"original").hexdigest()}}
            p.verify_files(root, expected)
            path.write_bytes(b"tampered")
            with self.assertRaises(ValueError):
                p.verify_files(root, expected)

    def test_no_builtin_token_fallback_or_network_call(self):
        with patch.dict("os.environ", {"GH_TOKEN": "unit-only", "GITHUB_TOKEN": "unit-only"}, clear=True), \
             patch.object(p, "github_json") as api, patch.object(p, "publisher_cli") as writes:
            with self.assertRaises(ValueError):
                p.publish(dict(p.EXPECTED))
            api.assert_not_called()
            writes.assert_not_called()

    def test_wrong_owner_stops_before_writes(self):
        for identity in ({"login": "other", "id": 64243701}, {"login": "Ullmann27", "id": 1}):
            with patch.dict("os.environ", {"LUMO_RELEASE_PUBLISH_TOKEN": "unit-only"}, clear=True), \
                 patch.object(p, "github_json", return_value=identity), patch.object(p, "publisher_cli") as writes:
                with self.assertRaises(ValueError):
                    p.publish(dict(p.EXPECTED))
                writes.assert_not_called()

    def test_existing_tag_or_release_never_reaches_mutation(self):
        owner = {"login": "Ullmann27", "id": 64243701}
        proof = {"status": "PASS", "order": dict(p.EXPECTED),
                 "assets": {p.APK: {"bytes": p.APK_BYTES, "sha256": p.APK_SHA}}}
        for responses in ([owner, {"full_name": p.REPOSITORY, "private": False, "owner": owner}, {"id": 99}],
                          [owner, {"full_name": p.REPOSITORY, "private": False, "owner": owner}, None, {"ref": "existing"}]):
            with patch.dict("os.environ", {"LUMO_RELEASE_PUBLISH_TOKEN": "unit-only"}, clear=True), \
                 patch.object(p, "github_json", side_effect=responses), patch.object(p, "read", return_value=proof), \
                 patch.object(p, "verify_files"), patch.object(p, "publisher_cli") as writes:
                with self.assertRaises(ValueError):
                    p.publish(dict(p.EXPECTED))
                writes.assert_not_called()

    def test_draft_urls_need_not_be_public_but_published_urls_must_match(self):
        release, ref, assets = release_fixture(True)
        release["html_url"] = "https://github.com/Ullmann27/lumo-lernen/releases/untagged-example"
        release["assets"][0]["browser_download_url"] = "https://github.com/Ullmann27/lumo-lernen/releases/download/untagged-example/file.apk"
        p.verify_release(release, ref, assets, draft=True)
        release["draft"] = False
        with self.assertRaises(ValueError):
            p.verify_release(release, ref, assets, draft=False)

    def test_wrong_tag_or_asset_uploader_is_rejected_before_publication(self):
        for mutation in ("tag", "uploader", "digest", "missing_digest"):
            release, ref, assets = release_fixture(True)
            if mutation == "tag":
                ref["object"]["sha"] = "0" * 40
            elif mutation == "uploader":
                release["assets"][0]["uploader"] = {"login": "Ullmann27", "id": 1}
            elif mutation == "missing_digest":
                release["assets"][0]["digest"] = None
            else:
                release["assets"][0]["digest"] = "sha256:" + "0" * 64
            with self.subTest(mutation=mutation), self.assertRaises(ValueError):
                p.verify_release(release, ref, assets, draft=True)


    def test_authenticated_get_does_not_follow_or_expose_redirect(self):
        request = Request("https://api.github.com/user")
        self.assertIsNone(p.NoRedirects().redirect_request(request, None, 302, "Found", {}, "https://example.invalid/?sig=hidden"))
        error = HTTPError(request.full_url, 302, "Found", {"Location": "https://example.invalid/?sig=hidden"}, None)
        with patch.object(p.API_OPENER, "open", side_effect=error):
            with self.assertRaisesRegex(ValueError, "HTTP 302") as caught:
                p.github_json("user", "unit-only")
            self.assertNotIn("hidden", str(caught.exception))

    def test_cli_strips_ambient_auth_and_proxy_and_pins_github_host(self):
        with tempfile.TemporaryDirectory() as folder, patch.object(p, "ROOT", Path(folder)), \
             patch.dict("os.environ", {"GH_HOST": "enterprise.invalid", "GH_ENTERPRISE_TOKEN": "ambient", "GITHUB_TOKEN": "ambient", "HTTPS_PROXY": "https://proxy.invalid", "GH_DEBUG": "api"}, clear=True), \
             patch.object(p.subprocess, "run", return_value=Mock(returncode=0, stdout="{}")) as call:
            p.publisher_cli("unit-owner-token", ["api", "--method", "POST", "repos/" + p.REPOSITORY + "/git/refs", "--input", "-"], {})
            environment = call.call_args.kwargs["env"]
            self.assertEqual(environment["GH_HOST"], "github.com")
            self.assertEqual(environment["GH_TOKEN"], "unit-owner-token")
            for key in ("GH_ENTERPRISE_TOKEN", "GITHUB_TOKEN", "HTTPS_PROXY", "GH_DEBUG"):
                self.assertNotIn(key, environment)
            self.assertNotIn("unit-owner-token", str(call.call_args.args[0]))


if __name__ == "__main__":
    unittest.main()
