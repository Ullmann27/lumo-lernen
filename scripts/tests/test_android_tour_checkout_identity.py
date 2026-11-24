"""A PR's synthetic GITHUB_SHA must not reject its exact checked-out APK."""
from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[2]
PROBE = ROOT / '.github/probes/modernization_android_tour.py'
WORKFLOW = ROOT / '.github/workflows/lumo-unified-integration-2026.yml'


class AndroidTourCheckoutIdentityTests(unittest.TestCase):
    def test_tour_compares_build_provenance_with_the_real_checked_out_head(self):
        text = PROBE.read_text(encoding='utf-8')
        self.assertIn(
            "expected_source = base.command('git', 'rev-parse', 'HEAD').strip()",
            text,
        )
        self.assertIn(
            "'flutter_source_is_this_commit': provenance.get('flutter_source_commit') == expected_source",
            text,
        )
        self.assertNotIn("os.environ.get('GITHUB_SHA') or", text)
        self.assertIn("'sha256_matches_provenance'", text)
        self.assertIn("'signing_certificate'", text)
        self.assertIn("'godot_revision_is_pinned'", text)

    def test_both_actions_jobs_checkout_the_same_pinned_pull_request_head(self):
        text = WORKFLOW.read_text(encoding='utf-8')
        self.assertIn('  verify-and-build:', text)
        self.assertIn('  android-tour:', text)
        checkout = 'ref: ${{ github.event.pull_request.head.sha || github.sha }}'
        build = text.split('  verify-and-build:', 1)[1].split('  android-tour:', 1)[0]
        tour = text.split('  android-tour:', 1)[1].split(
            '  publish-reading-adventure-prerelease:', 1)[0]
        self.assertIn(checkout, build)
        self.assertIn(checkout, tour)


if __name__ == '__main__':
    unittest.main()
