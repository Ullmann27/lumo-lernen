"""Publication transport/identity fixtures; no Android or public-release claims."""
from __future__ import annotations

import copy
import hashlib
import io
import json
import os
from pathlib import Path
from types import SimpleNamespace
import tempfile
import unittest
from unittest.mock import patch, Mock
import urllib.error
import urllib.request

from tools.nextgen import public_learning_download as public


class Response(io.BytesIO):
    def __init__(self, data, status=200, url="https://release-assets.githubusercontent.com/fixture.apk"):
        super().__init__(data)
        self.status, self.url, self.read_sizes = status, url, []

    def geturl(self):
        return self.url

    def read(self, size=-1):
        self.read_sizes.append(size)
        return super().read(min(size, 17))


class PublicLearningDownloadTest(unittest.TestCase):
    def setUp(self):
        self.body = b"current-source APK transport fixture\n" * 12
        self.sha = hashlib.sha256(self.body).hexdigest()
        self.env = {"GITHUB_REPOSITORY": "Ullmann27/lumo-lernen", "GITHUB_SHA": "a" * 40,
                    "LUMO_EXPECTED_NATIVE": "b" * 40, "ARM64_SHA": self.sha,
                    "VERSION_NAME": "4.5.6", "VERSION_CODE": "6001", "GITHUB_RUN_ID": "12345",
                    "RELEASE_TAG": "lumo-nextgen-learning-4.5.6-6001",
                    "LUMO_CERTIFICATE": "c" * 64, "LUMO_PACKAGE": "dev.lumo.fixture"}
        self.delivery = {"schemaVersion": 1, "apkSourceCommit": "a" * 40,
                         "godotCommit": "b" * 40, "workflowRun": 12345,
                         "versionName": "4.5.6", "versionCode": 6001,
                         "package": "dev.lumo.fixture", "signingCertificateSha256": "c" * 64,
                         "arm64Sha256": self.sha, "arm64Bytes": len(self.body)}
        self.build = {"flutter_source_commit": "a" * 40, "tracked_source_clean": True,
                      "godot": {"revision": "b" * 40}, "abis": ["arm64-v8a"],
                      "versionName": "4.5.6", "versionCode": 6001,
                      "package": "dev.lumo.fixture", "signingCertificateSha256": "c" * 64,
                      "sha256": self.sha, "bytes": len(self.body)}
        self.expected = public.expected_candidate(self.delivery, self.build, self.env)
        self.metadata = {"tag_name": self.env["RELEASE_TAG"], "target_commitish": "a" * 40,
                         "name": "LUMO Lernwelt 4.5.6 (6001)", "draft": False, "prerelease": True,
                         "html_url": "https://github.com/Ullmann27/lumo-lernen/releases/tag/" + self.env["RELEASE_TAG"],
                         "assets": [{"id": 10, "name": self.expected["asset"], "state": "uploaded",
                                     "size": len(self.body), "browser_download_url": self.expected["url"]},
                                    {"id": 11, "name": "DELIVERY.json"}]}
        self.tag = {"ref": "refs/tags/" + self.env["RELEASE_TAG"],
                    "object": {"type": "commit", "sha": "a" * 40}}

    def test_expected_candidate_is_derived_from_current_verified_fields(self):
        self.assertEqual(self.expected["bytes"], len(self.body))
        self.assertEqual(self.expected["sha256"], self.sha)
        self.assertEqual(self.expected["source"], self.env["GITHUB_SHA"])
        for data in (self.delivery, self.build):
            data.update(versionName="7.8.9", versionCode=7002)
        self.env.update(VERSION_NAME="7.8.9", VERSION_CODE="7002",
                        RELEASE_TAG="lumo-nextgen-learning-7.8.9-7002")
        changed = public.expected_candidate(self.delivery, self.build, self.env)
        self.assertEqual(changed["asset"], "Lumo-Lernen-Neu-7.8.9-7002.apk")
        self.assertIn("/lumo-nextgen-learning-7.8.9-7002/", changed["url"])

    def test_wrong_delivery_source_native_run_or_schema_fails_closed(self):
        for field, value in (("schemaVersion", True), ("apkSourceCommit", "d" * 40),
                             ("godotCommit", "d" * 40), ("workflowRun", 12346), ("workflowRun", True)):
            with self.subTest(field=field, value=value), self.assertRaises(RuntimeError):
                public.expected_candidate({**self.delivery, field: value}, self.build, self.env)
        for field, value in (("flutter_source_commit", "d" * 40), ("tracked_source_clean", False),
                             ("godot", {"revision": "d" * 40}), ("abis", ["x86_64"])):
            with self.subTest(field=field), self.assertRaises(RuntimeError):
                public.expected_candidate(self.delivery, {**self.build, field: value}, self.env)

    def test_wrong_version_identity_digest_size_or_tag_is_not_published(self):
        for field, value in (("versionName", "4.5.5"), ("versionCode", 6000), ("versionCode", True),
                             ("package", "other"), ("signingCertificateSha256", "d" * 64)):
            for owner in ("delivery", "build"):
                delivery, build = copy.deepcopy(self.delivery), copy.deepcopy(self.build)
                (delivery if owner == "delivery" else build)[field] = value
                with self.subTest(owner=owner, field=field, value=value), self.assertRaises(RuntimeError):
                    public.expected_candidate(delivery, build, self.env)
        for field, value in (("arm64Sha256", "d" * 64), ("arm64Bytes", 0), ("arm64Bytes", True),
                             ("arm64Bytes", len(self.body) + 1)):
            with self.subTest(field=field, value=value), self.assertRaises(RuntimeError):
                public.expected_candidate({**self.delivery, field: value}, self.build, self.env)
        for field, value in (("sha256", "d" * 64), ("bytes", True), ("bytes", len(self.body) - 1)):
            with self.subTest(field=field), self.assertRaises(RuntimeError):
                public.expected_candidate(self.delivery, {**self.build, field: value}, self.env)
        for field, value in (("RELEASE_TAG", "older-release"), ("GITHUB_SHA", "unknown"),
                             ("GITHUB_REPOSITORY", "other/repository"), ("VERSION_CODE", "true")):
            with self.subTest(field=field), self.assertRaises(RuntimeError):
                public.expected_candidate(self.delivery, self.build, {**self.env, field: value})

    @staticmethod
    def api_result(status="404", code=1):
        return SimpleNamespace(returncode=code, stdout=f"HTTP/2.0 {status}\r\n\r\n{{}}",
                               stderr="gh: Not Found (HTTP 404)" if status == "404" else "")

    def test_absence_requires_two_actual_404_and_keeps_the_observations(self):
        with tempfile.TemporaryDirectory() as temporary, patch.object(public.subprocess, "run",
                return_value=self.api_result()) as run:
            path = Path(temporary) / "PUBLIC-ABSENCE.json"
            public.require_absent(self.expected, path)
            observations = json.loads(path.read_text())["observations"]
        self.assertEqual(len(observations), 2)
        self.assertEqual([x["httpStatuses"] for x in observations], [["404"], ["404"]])
        self.assertIn("/releases/tags/", run.call_args_list[0].args[0][-2])
        self.assertIn("/git/ref/tags/", run.call_args_list[1].args[0][-2])
        self.assertTrue(all(call.args[0][0:2] == ["gh", "api"] for call in run.call_args_list))

    def test_existing_release_auth_server_or_network_error_is_not_absence(self):
        cases = [self.api_result("200", 0), self.api_result("403"), self.api_result("500"),
                 self.api_result("404", 0), SimpleNamespace(returncode=1, stdout="", stderr="network error"),
                 SimpleNamespace(returncode=1, stdout="HTTP/2 403\nHTTP/2 404\n", stderr="")]
        for result in cases:
            with self.subTest(response=result.stdout), tempfile.TemporaryDirectory() as temporary, \
                    patch.object(public.subprocess, "run", return_value=result) as run:
                path = Path(temporary) / "PUBLIC-ABSENCE.json"
                with self.assertRaises(RuntimeError):
                    public.require_absent(self.expected, path)
                self.assertEqual(run.call_count, 1)
                self.assertEqual(json.loads(path.read_text())["observations"][0]["response"], result.stdout)

    def test_existing_tag_still_blocks_after_release_404(self):
        with tempfile.TemporaryDirectory() as temporary, patch.object(public.subprocess, "run",
                side_effect=[self.api_result(), self.api_result("200", 0)]) as run:
            with self.assertRaises(RuntimeError):
                public.require_absent(self.expected, Path(temporary) / "PUBLIC-ABSENCE.json")
            self.assertEqual(run.call_count, 2)

    def test_metadata_and_actual_tag_must_both_match_the_current_source(self):
        self.assertEqual(public.verify_release(self.metadata, self.tag, self.expected)["id"], 10)
        for field, value in (("tag_name", "other"), ("target_commitish", "d" * 40),
                             ("name", "LUMO Lernwelt 4.5.5 (6000)"), ("draft", True),
                             ("prerelease", False), ("html_url", "https://github.com/other")):
            with self.subTest(field=field), self.assertRaises(RuntimeError):
                public.verify_release({**self.metadata, field: value}, self.tag, self.expected)
        for tag in ({**self.tag, "ref": "refs/tags/other"},
                    {**self.tag, "object": {"type": "commit", "sha": "d" * 40}},
                    {**self.tag, "object": {"type": "tag", "sha": "a" * 40}}):
            with self.subTest(tag=tag), self.assertRaises(RuntimeError):
                public.verify_release(self.metadata, tag, self.expected)

    def test_only_the_exact_uploaded_single_apk_url_name_and_size_are_allowed(self):
        for field, value in (("name", "old.apk"), ("state", "new"), ("size", len(self.body) + 1),
                             ("size", True), ("id", True), ("id", 0),
                             ("browser_download_url", self.expected["url"] + "?access_token=wrong")):
            metadata = copy.deepcopy(self.metadata)
            metadata["assets"][0][field] = value
            with self.subTest(field=field, value=value), self.assertRaises(RuntimeError):
                public.verify_release(metadata, self.tag, self.expected)
        for assets in ([], self.metadata["assets"] + [self.metadata["assets"][0]]):
            with self.subTest(assets=assets), self.assertRaises(RuntimeError):
                public.verify_release({**self.metadata, "assets": assets}, self.tag, self.expected)

    def test_entire_stream_is_hashed_anonymously_even_with_ci_tokens_in_environment(self):
        response, opener = Response(self.body), Mock()
        opener.open.return_value = response
        with patch.dict(os.environ, {"GH_TOKEN": "fixture-secret", "GITHUB_TOKEN": "fixture-secret"}), \
                patch.object(public.urllib.request, "build_opener", return_value=opener) as factory:
            result = public.download_public(self.expected)
        request = opener.open.call_args.args[0]
        self.assertEqual(request.full_url, self.expected["url"])
        self.assertEqual(set(name.lower() for name, _ in request.header_items()),
                         {"user-agent", "accept-encoding"})
        self.assertNotIn("fixture-secret", repr(request.header_items()))
        self.assertIsNone(request.data)
        self.assertEqual(factory.call_args.args[0].proxies, {})
        self.assertIsInstance(factory.call_args.args[1], public.AnonymousRedirect)
        self.assertGreater(len(response.read_sizes), 2)
        self.assertTrue(all(size == 4 * 1024 * 1024 for size in response.read_sizes))
        self.assertEqual((result["bytes"], result["sha256"]), (len(self.body), self.sha))
        self.assertTrue(result["entireFileRead"])
        self.assertFalse(result["authorizationHeaderSent"])

    def test_anonymous_cdn_redirect_drops_credentials_and_refuses_http_or_url_credentials(self):
        handler = public.AnonymousRedirect()
        request = urllib.request.Request(self.expected["url"],
                                         headers={"Authorization": "secret", "Cookie": "session=secret"})
        redirected = handler.redirect_request(request, None, 302, "Found", {},
                                              "https://release-assets.githubusercontent.com/file")
        self.assertEqual(set(name.lower() for name, _ in redirected.header_items()),
                         {"user-agent", "accept-encoding"})
        for url in ("http://release-assets.githubusercontent.com/file", "https://user:password@example.com/file"):
            with self.subTest(url=url), self.assertRaises(RuntimeError):
                handler.redirect_request(request, None, 302, "Found", {}, url)

    def test_wrong_public_size_hash_partial_response_or_insecure_response_fails_without_retry(self):
        responses = [Response(self.body[:-1]), Response(self.body + b"extra"),
                     Response(b"x" * len(self.body)), Response(self.body, status=206),
                     Response(self.body, url="http://example.com/file")]
        for response in responses:
            opener = Mock()
            opener.open.return_value = response
            with self.subTest(response=response), patch.object(public.urllib.request, "build_opener",
                    return_value=opener), self.assertRaises(RuntimeError):
                public.download_public(self.expected)
            self.assertEqual(opener.open.call_count, 1)

    def test_transport_retry_restarts_full_download_and_never_accepts_repeated_error(self):
        opener = Mock()
        opener.open.side_effect = [urllib.error.URLError("reset"), Response(self.body)]
        with patch.object(public.urllib.request, "build_opener", return_value=opener), \
                patch.object(public.time, "sleep"):
            self.assertEqual(public.download_public(self.expected)["attempt"], 2)
        opener.open.side_effect = urllib.error.URLError("unavailable")
        opener.open.reset_mock()
        with patch.object(public.urllib.request, "build_opener", return_value=opener), \
                patch.object(public.time, "sleep"), self.assertRaises(urllib.error.URLError):
            public.download_public(self.expected)
        self.assertEqual(opener.open.call_count, 3)

    def test_verification_evidence_is_written_only_after_complete_matching_download(self):
        for succeeds in (False, True):
            with self.subTest(succeeds=succeeds), tempfile.TemporaryDirectory() as temporary, \
                    patch.dict(os.environ, self.env, clear=True):
                directory = Path(temporary)
                public.write_json(directory / "DELIVERY.json", self.delivery)
                public.write_json(directory / "BUILD-PROVENANCE.json", self.build)
                opener = Mock()
                opener.open.return_value = Response(self.body if succeeds else b"bad")
                with patch.object(public.subprocess, "check_output", side_effect=[
                        json.dumps(self.metadata), json.dumps(self.tag)]), \
                        patch.object(public.urllib.request, "build_opener", return_value=opener):
                    if succeeds:
                        public.main(["verify", "--release-dir", str(directory)])
                    else:
                        with self.assertRaises(RuntimeError):
                            public.main(["verify", "--release-dir", str(directory)])
                self.assertTrue((directory / "PUBLIC-DOWNLOAD.json").is_file())
                self.assertTrue((directory / "PUBLIC-TAG.json").is_file())
                verified = directory / "PUBLIC-DOWNLOAD-VERIFIED.json"
                self.assertEqual(verified.exists(), succeeds)
                self.assertFalse(list(directory.glob("*.apk")))
                if succeeds:
                    proof = json.loads(verified.read_text())
                    self.assertEqual(proof["candidate"], self.expected)
                    self.assertEqual(proof["publicMetadataSha256"], public.digest(directory / "PUBLIC-DOWNLOAD.json"))
                    with self.assertRaisesRegex(RuntimeError, "earlier public verification"):
                        public.main(["verify", "--release-dir", str(directory)])


if __name__ == "__main__":
    unittest.main()
