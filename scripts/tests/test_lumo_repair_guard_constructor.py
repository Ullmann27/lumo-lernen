"""Exercise the actual constructor guard against formatted and broken wiring."""
from pathlib import Path
import re
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[2]
GUARD = ROOT / 'scripts/lumo_repair_guard.sh'


class RepairGuardConstructorTests(unittest.TestCase):
    def setUp(self):
        directory = tempfile.TemporaryDirectory(prefix='lumo constructor guard ')
        self.addCleanup(directory.cleanup)
        self.directory = Path(directory.name)
        source = GUARD.read_text()
        functions = []
        for name in ('fail', 'require_constructor_argument', 'require_state_constructor'):
            match = re.search(r'(?ms)^' + name + r'\(\) \{\n.*?^\}', source)
            self.assertIsNotNone(match, 'Expected actual guard helper: ' + name)
            functions.append(match.group())
        self.fixture = self.directory / 'actual-helper.sh'
        self.fixture.write_text(
            'set -euo pipefail\n' + '\n\n'.join(functions) +
            '\nrequire_constructor_argument "$1" "$2" "$3" "$4"\n'
            'echo FIXTURE_CONSTRUCTOR_CONTINUED\n'
        )

    def check(self, source, constructor='AppShell', argument='profile', value='_profile'):
        dart = self.directory / 'main.dart'
        dart.write_text(source)
        return subprocess.run(
            ['/bin/bash', str(self.fixture), str(dart), constructor, argument, value],
            capture_output=True, text=True, timeout=10,
        )

    def test_original_single_line_connection_still_passes(self):
        result = self.check('home = AppShell(profile: _profile);')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('FIXTURE_CONSTRUCTOR_CONTINUED', result.stdout)

    def test_multiline_profile_after_another_argument_passes(self):
        result = self.check('''home = AppShell(
          key: ValueKey(navigationKey),
          profile: _profile,
          initialSection: _initialSection,
          deepLinkRequestId: _deepLinkRequestId,
        );''')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('FIXTURE_CONSTRUCTOR_CONTINUED', result.stdout)

    def test_wrong_profile_missing_profile_and_prefix_match_are_fatal(self):
        for source in (
            'home = AppShell(profile: otherProfile);',
            'home = AppShell(profile: _profileOther);',
            'home = AppShell(initialSection: _initialSection);',
        ):
            with self.subTest(source=source):
                result = self.check(source)
                self.assertNotEqual(result.returncode, 0)
                self.assertIn('Missing constructor connection:', result.stderr)
                self.assertNotIn('FIXTURE_CONSTRUCTOR_CONTINUED', result.stdout)

    def test_profile_outside_expected_constructor_cannot_satisfy_guard(self):
        for source in (
            'OtherShell(profile: _profile); AppShell(profile: wrongProfile);',
            'NotAppShell(profile: _profile);',
            'AppShell(); final profile = _profile;',
        ):
            with self.subTest(source=source):
                self.assertNotEqual(self.check(source).returncode, 0)

    def test_unclosed_constructor_is_fatal(self):
        self.assertNotEqual(self.check('AppShell(profile: _profile,').returncode, 0)

    def test_comments_and_strings_cannot_overwrite_a_wrong_profile(self):
        for decoration in (
            "key: ValueKey('profile: _profile'),",
            'key: ValueKey("profile: _profile"),',
            "key: ValueKey(r'profile: _profile'),",
            'key: ValueKey("""profile: _profile"""),',
            '// profile: _profile\n',
            '/* profile: _profile */',
            '/* outer /* profile: _profile */ comment */',
        ):
            with self.subTest(decoration=decoration):
                result = self.check('AppShell(' + decoration + 'profile: otherProfile);')
                self.assertNotEqual(result.returncode, 0)
                self.assertNotIn('FIXTURE_CONSTRUCTOR_CONTINUED', result.stdout)

    def test_nested_profile_argument_cannot_satisfy_direct_connection(self):
        for decoration in (
            'key: ProfileKey(profile: _profile),',
            'children: [ProfileKey(profile: _profile)],',
            'builder: () { return ProfileKey(profile: _profile); },',
        ):
            with self.subTest(decoration=decoration):
                result = self.check('AppShell(' + decoration + 'profile: otherProfile);')
                self.assertNotEqual(result.returncode, 0)
                self.assertNotIn('FIXTURE_CONSTRUCTOR_CONTINUED', result.stdout)

    def test_commented_or_quoted_constructor_is_not_live_wiring(self):
        for source in (
            '// AppShell(profile: _profile);',
            '/* AppShell(profile: _profile); */',
            "final text = 'AppShell(profile: _profile);';",
        ):
            with self.subTest(source=source):
                self.assertNotEqual(self.check(source).returncode, 0)

    def test_comments_between_actual_argument_tokens_are_allowed(self):
        result = self.check('AppShell( profile /* selected */ : /* restored */ _profile, );')
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_existing_state_argument_contract_remains(self):
        self.assertEqual(self.check(
            'HomeContent(\n key: ValueKey(1),\n appState: _appState,\n);',
            'HomeContent', 'appState', '_appState',
        ).returncode, 0)
        self.assertNotEqual(self.check(
            'HomeContent(appState: anotherState);',
            'HomeContent', 'appState', '_appState',
        ).returncode, 0)

    def test_actual_application_profile_connection_passes(self):
        result = self.check((ROOT / 'lib/main.dart').read_text())
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_guard_requires_profile_and_preserves_state_wrapper(self):
        source = GUARD.read_text()
        self.assertIn('require_constructor_argument lib/main.dart AppShell profile _profile', source)
        self.assertIn('require_constructor_argument "$1" "$2" appState _appState', source)
        self.assertNotIn('require_text lib/main.dart "AppShell(profile: _profile"', source)


if __name__ == '__main__':
    unittest.main()
