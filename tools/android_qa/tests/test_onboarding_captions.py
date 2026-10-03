"""Real-caption harness regressions; no Android usage proof or app-state edits."""
from pathlib import Path
import sys
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from run_ui_checks import complete_first_run_ui, LEARNING_SELECTION_CAPTION


class OnboardingCaptionTests(unittest.TestCase):
    def test_all_four_screens_use_visible_headings_without_name_field_hint(self):
        # Name captions are the exact actual UI labels from failed CI run
        # 37110344120; 'Dein Name' was absent on that real Android screen.
        screens = [
            ['Hallo! Ich bin Lumo.', 'Willkommen 👋', "Los geht's!"],
            ['Wie darf ich dich nennen?', '2', 'Wie heißt du?',
             'Lumo spricht dich dann persönlich an.', 'Weiter'],
            ['Ich passe die Erklärung an dich an.', '3', 'Wie alt bist du?',
             '7 Jahre', 'Weiter'],
            ['Jetzt wähle ich den richtigen Stoff.', '4', 'In welche Klasse gehst du?',
             '1. Klasse', '2. Klasse', '3. Klasse', '4. Klasse', 'Profil speichern'],
            ['Hallo, Kind!', 'Dein Lumo-Tag · 1. Klasse', 'Lernen', 'Spielen'],
        ]
        stage, taps, waits, captures = 0, [], [], []

        def wait_for(phrases):
            waits.append(phrases)
            self.assertTrue(any(phrase in value for phrase in phrases for value in screens[stage]),
                            f'Expected {phrases} but actual captions are {screens[stage]}')
            return screens[stage]

        def click(phrase, **options):
            nonlocal stage
            self.assertIn(phrase, screens[stage])
            self.assertTrue(options.get('scroll'))
            taps.append(phrase)
            if phrase != '1. Klasse':
                stage += 1

        complete_first_run_ui(wait_for, click, captures.append, lambda values: values)
        self.assertEqual(stage, 4)
        self.assertEqual(taps, ["Los geht's!", 'Weiter', 'Weiter', '1. Klasse', 'Profil speichern'])
        self.assertNotIn(['Dein Name'], waits)
        self.assertIn(['Wie heißt du?'], waits)
        self.assertIn(['Wie alt bist du?'], waits)
        self.assertIn(['In welche Klasse gehst du?'], waits)
        self.assertIn('onboarding-age', captures)

    def test_existing_home_is_not_changed_or_reprofiled(self):
        def no_input(*args, **kwargs):
            self.fail('Existing home must receive no onboarding input')
        complete_first_run_ui(lambda phrases: ['Hallo, Kind!', 'Spielen'],
                              no_input, no_input, lambda root: root)

    def test_partial_name_age_and_grade_are_reported_instead_of_assumed_home(self):
        for caption in ('Wie heißt du?', 'Wie alt bist du?', 'In welche Klasse gehst du?'):
            with self.subTest(caption=caption), self.assertRaisesRegex(RuntimeError, 'partial onboarding'):
                complete_first_run_ui(lambda phrases: [caption],
                                      lambda *args, **kwargs: self.fail('Unexpected onboarding tap'),
                                      lambda label: None, lambda root: root)

    def test_learning_return_caption_matches_the_akademie_actually_wired_in_shell(self):
        source = Path(__file__).resolve().parents[3]/'lib'
        shell = (source/'app/app_shell.dart').read_text()
        screen = (source/'features/teacher_mode/lumo_akademie_screen.dart').read_text()
        self.assertRegex(shell, r'case LumoSection\.learn:\s*return LumoAkademieScreen\(appState: _appState\)')
        self.assertIn("Text('"+LEARNING_SELECTION_CAPTION+"'", screen)


if __name__ == '__main__':
    unittest.main()
