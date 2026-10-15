import copy
import hashlib
import importlib.util
import io
from pathlib import Path
import unittest
from unittest.mock import patch
import zipfile


SOURCE = Path(__file__).resolve().parents[1] / "publish_authorized_1928.py"
SPEC = importlib.util.spec_from_file_location("publish_1928", SOURCE)
MODULE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MODULE)


class AuthorizedPublicationTests(unittest.TestCase):
    def test_root_app_proof_is_distinct_from_nested_system_result(self):
        stream = io.BytesIO()
        with zipfile.ZipFile(stream, "w") as archive:
            archive.writestr("result.json", '{"status":"PASS"}')
            archive.writestr("system-image/other/result.json", '{"status":"other"}')
        stream.seek(0)
        with zipfile.ZipFile(stream) as archive:
            with self.assertRaises(ValueError):
                MODULE.member(archive, "result.json")
            item = MODULE.member(archive, "result.json", exact=True)
            self.assertEqual(item.filename, "result.json")
            self.assertEqual(archive.read(item), b'{"status":"PASS"}')
            with self.assertRaises(ValueError):
                MODULE.member(archive, "missing.json", exact=True)

    def release(self):
        return {"id": MODULE.RELEASE_ID, "draft": True, "prerelease": True,
                "tag_name": MODULE.TAG, "name": MODULE.TITLE,
                "target_commitish": MODULE.SOURCE, "body": "approved", "assets": []}

    def test_exact_unpublished_release_is_required(self):
        release = self.release()
        with patch.object(MODULE, "BODY_SHA", hashlib.sha256(b"approved").hexdigest()):
            MODULE.check_release(release)
            for key, value in (("draft", False), ("prerelease", False),
                               ("id", 123), ("target_commitish", "other"),
                               ("tag_name", "other"), ("body", "changed")):
                invalid = copy.deepcopy(release)
                invalid[key] = value
                with self.subTest(key=key), self.assertRaises(ValueError):
                    MODULE.check_release(invalid)

    def test_unapproved_or_duplicate_assets_are_rejected(self):
        with patch.object(MODULE, "BODY_SHA", hashlib.sha256(b"approved").hexdigest()):
            for names in (["private-preferences.xml"],
                          ["Lumo-Lernen-Neu.apk", "Lumo-Lernen-Neu.apk"]):
                release = self.release()
                release["assets"] = [{"name": name} for name in names]
                with self.subTest(names=names), self.assertRaises(ValueError):
                    MODULE.check_release(release)

    def test_actual_flutter_frame_and_exact_apk_source_are_required(self):
        result = {"status": "PASS", "source": MODULE.SOURCE,
                  "harness": MODULE.HARNESS, "apk_sha256": MODULE.EMULATOR_SHA,
                  "kart": {"flutter_return_frame_confirmed": True, "pause_return": True},
                  "update": {"profile_retained": True}}
        MODULE.check_return(result)
        for key in ("source", "harness", "apk_sha256"):
            invalid = copy.deepcopy(result)
            invalid[key] = "different"
            with self.subTest(key=key), self.assertRaises(ValueError):
                MODULE.check_return(invalid)
        invalid = copy.deepcopy(result)
        invalid["kart"]["flutter_return_frame_confirmed"] = False
        with self.assertRaises(ValueError):
            MODULE.check_return(invalid)
        invalid = copy.deepcopy(result)
        invalid["update"]["profile_retained"] = False
        with self.assertRaises(ValueError):
            MODULE.check_return(invalid)


if __name__ == "__main__":
    unittest.main()
