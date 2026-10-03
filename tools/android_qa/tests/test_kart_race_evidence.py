"""Reject a result-only claim of a full race; inspect captured HUD text."""
import sys
from pathlib import Path
import unittest
import hashlib
import importlib.util
import json
import shutil

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from kart_android_race import (race_state, second_round_in_progress, require_second_round,
                              wait_for_frame, marker, restart_visible, local_hint_visible,
                              lesson_closed_or_changed, action_marker, lightweight_pause_visible,
                              answer_for, simple_calculation, lesson_visible, maths_value, read_frame)


def frame(*captions):
    return {'lines': [{'text': text} for text in captions], 'text': '\n'.join(captions)}


class KartRaceEvidenceTests(unittest.TestCase):
    def test_real_desktop_ocr_round_one_cannot_prove_round_two(self):
        # Actual read_frame output of docs/screenshots/sonnenhafen-learning.png.
        observed = frame('RUNDE1/2 -', 'PLATZ 6/6', '- Okm/h',
                         'LERN-BOOST - 1. KLASSE - Mathematik')
        self.assertEqual(race_state(observed), {'round': [1, 2], 'place': [6, 6]})
        self.assertFalse(second_round_in_progress(observed))

    def test_combined_hud_round_two_is_read_without_using_speed_or_crystals(self):
        observed = frame('RUNDE 2 / 2 · PLATZ 4 / 6 · 58 km/h · ◆ 9')
        self.assertEqual(race_state(observed), {'round': [2, 2], 'place': [4, 6]})
        self.assertTrue(second_round_in_progress(observed))

    def test_result_hud_round_two_is_insufficient_even_when_button_ocr_fails(self):
        result = frame('RUNDE2/2', 'PLATZ6/6', 'Sonnenhafen-Cup geschafft!')
        self.assertFalse(second_round_in_progress(result))
        with self.assertRaisesRegex(RuntimeError, 'before the result screen'):
            require_second_round(None)
        self.assertFalse(second_round_in_progress(frame('RUNDE2/2', 'PLATZ6/6', 'Noch ein Rennen')))

    def test_unreadable_or_inconsistent_hud_does_not_prove_the_required_round(self):
        for observed in [frame('RUNDE2/2'), frame('RUNDE2/3', 'PLATZ4/6'),
                         frame('RUNDE?/2', 'PLATZ4/6'), frame('PLATZ4/6')]:
            with self.subTest(frame=observed):
                self.assertFalse(second_round_in_progress(observed))

    def test_valid_later_hud_crop_is_read_and_conflicting_values_are_rejected(self):
        observed = frame('RUNDE2/2', 'PLATZ1l/6', 'RUNDE 2/2 · PLATZ 1/6')
        self.assertEqual(race_state(observed), {'round': [2, 2], 'place': [1, 6]})
        for captions in [('RUNDE1/2', 'RUNDE2/2', 'PLATZ1/6'),
                         ('RUNDE2/2', 'PLATZ1/6', 'PLATZ2/6'),
                         ('RUNDE3/2', 'PLATZ1/6')]:
            with self.subTest(captions=captions):
                with self.assertRaises(RuntimeError):
                    race_state(frame(*captions))

    def test_measured_hud_ignores_captions_outside_its_real_panel(self):
        observed = {'hud_panel': {'top': 45, 'height': 39},
                    'hud_lines': [{'text': 'RUNDE2/2 · PLATZ1/6'}], 'lines': [
                        {'text': 'RUNDE1/2', 'top': 150, 'height': 12},
                        {'text': 'PLATZ1l/6', 'top': 58, 'height': 14}]}
        self.assertEqual(race_state(observed), {'round': [2, 2], 'place': [1, 6]})

    def test_success_keeps_reference_to_the_actual_prior_capture(self):
        require_second_round(23)


class KartTransitionEvidenceTests(unittest.TestCase):
    def test_stale_hud_frames_are_retained_until_pause_is_actually_visible(self):
        observations = [frame('RUNDE 1/2', '0 km/h', '4'),
                        frame('RUNDE 1/2', '0 km/h', '3'),
                        frame('RUNDE 1/2', 'Kleine Pause im Sonnenhafen', 'Weiterfahren')]
        captured = []
        now = [0.0]
        def capture(label):
            observed = observations[len(captured)]
            captured.append((label, observed))
            now[0] += 1.4  # Realistic slow render/OCR observations, not game time.
            return observed
        result = wait_for_frame(capture, 'android-back-pause',
                                lambda observed: bool(action_marker(observed, 'Weiterfahren')),
                                'Android Back did not open the Godot pause screen.',
                                clock=lambda: now[0], sleep=lambda seconds: now.__setitem__(0, now[0]+seconds))
        self.assertIs(result, observations[2])
        self.assertEqual([observed for _, observed in captured], observations)
        self.assertGreater(now[0], 2)

    def test_stale_hud_alone_times_out_and_keeps_its_actual_ocr_in_failure(self):
        stale = frame('RUNDE 1/2', '0 km/h', '3')
        now = [0.0]
        captured = []
        def capture(label):
            captured.append(label)
            now[0] += 1
            return stale
        with self.assertRaisesRegex(RuntimeError, 'pause screen.*within 3s.*RUNDE'):
            wait_for_frame(capture, 'android-back-pause',
                           lambda observed: bool(action_marker(observed, 'Weiterfahren')),
                           'Android Back did not open the Godot pause screen.', timeout=3,
                           clock=lambda: now[0], sleep=lambda seconds: now.__setitem__(0, now[0]+seconds))
        self.assertGreater(len(captured), 1)
        self.assertEqual(now[0], 3)

    def test_one_capture_over_the_deadline_cannot_turn_into_late_success(self):
        now = [0.0]
        def slow_capture(_):
            now[0] = 31
            return frame('Weiterfahren')
        with self.assertRaisesRegex(RuntimeError, 'within 30s'):
            wait_for_frame(slow_capture, 'android-back-pause',
                           lambda observed: bool(action_marker(observed, 'Weiterfahren')),
                           'Pause did not appear.', timeout=30,
                           clock=lambda: now[0], sleep=lambda _: None)

    def test_real_slow_answer_observations_fit_the_bounded_native_processing_budget(self):
        # Run37123614635 actual 025/026-answered PNGs and action timestamps:
        # 025 still shows 9-5 with 0km/h; 026 shows closed lesson/Richtig/57km/h.
        # Full capture+OCR observations took 15.5s and20s, with no repeated input.
        pending = {'height': 480, 'lines': [
            {'text': 'RUNDE1/2 - PLATZ1/6 - 0km/h', 'top': 58, 'height': 14},
            {'text': 'LERN-BOOST · 1. KLASSE · Mathematik', 'top': 122, 'height': 9},
            {'text': '9−5=?', 'top': 154, 'height': 12}],
            'words': [{'text': '4', 'left': 538, 'top': 190, 'width': 6, 'height': 9}]}
        pending['text'] = '\n'.join(line['text'] for line in pending['lines'])
        resumed = frame('RUNDE1/2 - PLATZ1/6', '57 km/h', 'Richtig!')
        observations = [(15.5, pending), (20.0, resumed)]
        now, captured = [0.0], []
        def capture(label):
            seconds, observed = observations[len(captured)]
            captured.append((label, observed))
            now[0] += seconds
            return observed
        result = wait_for_frame(capture, 'answered',
                                lambda observed: lesson_closed_or_changed(observed, '9−5=?'),
                                'Answer touch did not close the real learning pause.',
                                clock=lambda: now[0], sleep=lambda seconds: now.__setitem__(0, now[0]+seconds))
        self.assertIs(result, resumed)
        self.assertEqual(len(captured), 2)
        self.assertGreater(now[0], 30)
        self.assertLess(now[0], 90)

    def test_default_native_deadline_rejects_late_success_and_slow_stale_panels(self):
        now = [0.0]
        def too_late(_):
            now[0] = 91
            return frame('Weiterfahren')
        with self.assertRaisesRegex(RuntimeError, 'within 90s'):
            wait_for_frame(too_late, 'android-back-pause',
                           lambda observed: bool(action_marker(observed, 'Weiterfahren')),
                           'Pause did not appear.', clock=lambda: now[0], sleep=lambda _: None)
        now[0] = 0
        captured = []
        stale = {'height': 480, 'words': [], 'text': 'RUNDE1/2 - PLATZ1/6\nLERN-BOOST',
                 'lines': [{'text': 'RUNDE1/2 - PLATZ1/6', 'top': 58, 'height': 14},
                           {'text': 'LERN-BOOST', 'top': 122, 'height': 9}]}
        def slow_stale(label):
            captured.append(label)
            now[0] += 20
            return stale
        with self.assertRaisesRegex(RuntimeError, 'within 90s.*LERN-BOOST'):
            wait_for_frame(slow_stale, 'answered', lesson_closed_or_changed,
                           'Answer touch did not close the real learning pause.',
                           clock=lambda: now[0], sleep=lambda seconds: now.__setitem__(0, now[0]+seconds))
        self.assertEqual(len(captured), 5)

    def test_restart_requires_round_one_and_cannot_accept_stale_result_or_hud(self):
        self.assertFalse(restart_visible(frame('RUNDE 2/2', 'PLATZ 1/6', 'Noch ein Rennen')))
        self.assertFalse(restart_visible(frame('RUNDE 2/2', 'PLATZ 1/6')))
        self.assertFalse(restart_visible(frame('RUNDE 1/2', 'PLATZ 1/6', 'Weiterfahren')))
        self.assertTrue(restart_visible(frame('RUNDE 1/2', 'PLATZ 1/6', '3')))

    def test_hint_must_replace_the_waiting_caption_while_the_lesson_remains(self):
        # Measured multiline-panel geometry can put a hint below the old
        # arbitrary 0.52*480=249 cutoff. No world caption can supply this ROI.
        geometry = {'height': 480, 'lines': [{'text': 'LERN-BOOST', 'top': 121}],
                    'lesson_panel': {'top': 100, 'height': 180},
                    'answer_buttons': [{'top': 200, 'height': 36}]}
        original = {**geometry, 'lesson_hint': {'text': 'Alle Karts warten. Nimm dir Zeit.',
                                              'top': 254, 'height': 11}}
        explanation = {**geometry, 'lesson_hint': {'text': 'Zähle die beiden Gruppen gemeinsam.',
                                                 'top': 254, 'height': 11}}
        self.assertFalse(local_hint_visible(original))
        self.assertTrue(local_hint_visible(explanation))
        self.assertFalse(local_hint_visible({**explanation, 'lesson_hint': {
            **explanation['lesson_hint'], 'top': 200}}))
        self.assertFalse(local_hint_visible({**explanation, 'lesson_hint': {
            **explanation['lesson_hint'], 'top': 290}}))
        self.assertFalse(local_hint_visible({'height': 480, 'lines': [
            {'text': 'LERN-BOOST', 'top': 121},
            {'text': 'Zähle die beiden Gruppen gemeinsam.', 'top': 254}]}))
        self.assertFalse(local_hint_visible(frame('RUNDE 1/2')))

    def test_answer_transition_requires_a_real_hud_after_the_lesson_disappears(self):
        self.assertFalse(lesson_closed_or_changed(frame('unreadable frame')))
        self.assertFalse(lesson_closed_or_changed(frame('RUNDE 1/2', 'Weiterfahren')))
        self.assertTrue(lesson_closed_or_changed(frame('RUNDE 1/2', 'PLATZ 1/6')))

    def test_real_world_skip_caption_does_not_leave_a_phantom_learning_pause(self):
        observed = frame('RUNDE 1/2', 'PLATZ 1/6',
                         "Weiter geht's. Die nächste Lernfrage kommt später.")
        self.assertIsNotNone(marker(observed, 'SPATER'))
        self.assertFalse(lesson_visible(observed))
        self.assertTrue(lesson_closed_or_changed(observed))
        self.assertTrue(lesson_visible(frame('RUNDE 1/2', 'LERN-BOOST · 1. KLASSE · Mathematik')))
        self.assertTrue(lesson_visible(frame('RUNDE 1/2', 'Spater >')))


class KartActionCaptionTests(unittest.TestCase):
    def test_real_kvm_pause_ocr_clicks_resume_button_instead_of_explanation(self):
        # read_frame output of run 37118471725, raw 003-android-back-pause.png.
        explanation = {'text': 'Dein Rennen wartet. Du kannst spater hier weiterfahren.',
                       'left': 193, 'top': 112, 'width': 325, 'height': 13}
        cropped_explanation = {'text': 'n Rennen wartet. Du kannst spater hier weiterfahren.',
                               'left': 212, 'top': 110, 'width': 306, 'height': 17}
        button = {'text': 'Weiterfahren', 'left': 332, 'top': 145, 'width': 83, 'height': 10}
        observed = {'lines': [explanation, cropped_explanation, button]}
        self.assertIs(marker(observed, 'Weiterfahren'), explanation)
        self.assertIs(action_marker(observed, 'Weiterfahren'), button)
        self.assertEqual((button['left']+button['width']//2, button['top']+button['height']//2), (373, 150))
        self.assertIsNone(action_marker({'lines': [explanation, cropped_explanation]}, 'Weiterfahren'))

    def test_return_buttons_accept_real_caption_suffixes_but_not_explanations(self):
        for caption in ('Zur Spieleauswahl : Rennen behalten',
                        'Zur Spieleauswahl - Rennen behalten',
                        'Zur Spieleauswahl · Rennen behalten', 'Zur Spieleauswahl'):
            with self.subTest(caption=caption):
                self.assertIsNotNone(action_marker(frame(caption), 'Zur Spieleauswahl'))
        self.assertIsNotNone(action_marker(frame('Zum Lernen · Rennen behalten'), 'Zum Lernen'))
        self.assertIsNone(action_marker(frame('Du kannst zur Spieleauswahl zurückgehen.'), 'Zur Spieleauswahl'))
        self.assertIsNone(action_marker(frame('Zum Lernen später weiterfahren.'), 'Zum Lernen'))
        self.assertIsNotNone(action_marker(frame('Später ›'), 'SPATER'))

    def test_lightweight_reload_needs_both_actual_enabled_setting_and_resume_buttons(self):
        self.assertFalse(lightweight_pause_visible(frame('Leichte Grafik: aus', 'Weiterfahren')))
        self.assertFalse(lightweight_pause_visible(frame('Leichte Grafik: an')))
        self.assertFalse(lightweight_pause_visible(frame('Leichte Grafik: an',
                         'Dein Rennen wartet. Du kannst spater hier weiterfahren.')))
        self.assertTrue(lightweight_pause_visible(frame('Leichte Grafik: an', 'Weiterfahren')))

    def test_real_kvm_learning_header_targets_observed_skip_caption_inside_its_button(self):
        # Enlarged header OCR from unchanged 013/021 PNGs, run 37119121430.
        heading = {'text': 'LERN-BOOST- 1, KLASSE - Mathematik',
                   'left': 135, 'top': 112, 'width': 192, 'height': 28}
        skip = {'text': 'Spater >', 'left': 563, 'top': 122, 'width': 47, 'height': 11}
        for image in ('013-race.png', '021-wrong-local-hint.png'):
            with self.subTest(image=image):
                observed = {'lines': [heading, skip]}
                self.assertIs(action_marker(observed, 'SPATER'), skip)
                x, y = skip['left']+skip['width']//2, skip['top']+skip['height']//2
                self.assertEqual((x, y), (586, 127))
                self.assertTrue(553 <= x <= 620)
        self.assertIsNone(action_marker({'lines': [heading]}, 'SPATER'))
        self.assertIsNone(action_marker(frame('Die nächste Lernfrage kommt später.'), 'SPATER'))


class KartAnswerTargetTests(unittest.TestCase):
    def test_complete_known_story_prompts_are_computed_but_partial_noise_is_rejected(self):
        self.assertEqual(maths_value('Im Regal liegen 2 Bücher. 7 neue kommen dazu. Wie viele sind es jetzt?'), 9)
        self.assertEqual(maths_value('Im Garten stehen 2 Blumen. Lumo pflanzt 1 dazu. Wie viele wachsen jetzt?'), 3)
        self.assertEqual(maths_value('Auf dem Fest sind 2 Kinder. 3 kommen noch. Wie viele feiern zusammen?'), 5)
        for caption in ('Im Regal liegen 2 Bücher. 7 neue kommen dazu.',
                        'Zähle 2 Bücher und 7 neue zusammen.',
                        'Lure sammelt 2 Muscheln. 4 kommen dazu. Wie viele sind es?'):
            self.assertIsNone(maths_value(caption))

    def test_second_real_kvm_question_is_answerable_when_skip_caption_is_not_readable(self):
        # Actual second learning stop: 023-race.png, run 37120532906.
        observed = {'height': 480, 'lines': [
            {'text': 'LERN-BOOST- 1, KLASSE - Mathematik', 'top': 112, 'height': 28},
            {'text': '9+1=?', 'left': 135, 'top': 155, 'width': 57, 'height': 11}],
            'words': [{'left': 207, 'top': 190, 'width': 11, 'height': 9, 'text': '11'},
                      {'left': 370, 'top': 190, 'width': 13, 'height': 9, 'text': '10'},
                      {'left': 538, 'top': 190, 'width': 6, 'height': 9, 'text': '9'}]}
        self.assertTrue(lesson_visible(observed))
        self.assertIsNone(action_marker(observed, 'SPATER'))
        answer = answer_for(observed)
        self.assertEqual(answer['expected'], 10)
        self.assertIs(answer['option'], observed['words'][1])
        self.assertEqual((answer['option']['left']+answer['option']['width']//2,
                          answer['option']['top']+answer['option']['height']//2), (376, 194))

    def test_real_kvm_arithmetic_without_ocr_equals_uses_the_observed_eight_button(self):
        # Actual 014-race.png OCR, run 37119973383. '=' is absent from OCR.
        prompt = {'text': '7+1', 'left': 134, 'top': 154, 'width': 31, 'height': 12}
        eight = {'left': 210, 'top': 190, 'width': 6, 'height': 9, 'text': '8'}
        seven = {'left': 538, 'top': 190, 'width': 6, 'height': 9, 'text': '7'}
        observed = {'height': 480, 'lines': [prompt], 'words': [eight, seven]}
        answer = answer_for(observed)
        self.assertEqual(answer['expected'], 8)
        self.assertIs(answer['option'], eight)
        self.assertEqual(answer['options'], [eight, seven])
        for caption in ('7+1', '7 + 1 =', '7 + 1 = ?'):
            self.assertIsNotNone(simple_calculation(caption))

    def test_explanation_with_numbers_is_not_an_arithmetic_prompt(self):
        for caption in ('Rechne zum Beispiel 7+1.', 'Bei 7+1 kommen 8 heraus.',
                        'Zähle 7 Muscheln und 1 Muschel dazu.', '7+1=8'):
            with self.subTest(caption=caption):
                self.assertIsNone(simple_calculation(caption))
                observed = {'height': 480,
                            'lines': [{'text': caption, 'top': 154, 'height': 12}],
                            'words': [{'text': '8', 'top': 190}]}
                self.assertIsNone(answer_for(observed))

    def test_real_kvm_answer_strip_excludes_prompt_digits_for_both_answer_choices(self):
        # Actual OCR positions from run 37119121430: 013-race.png and
        # 021-wrong-local-hint.png show the same unanswered maths question.
        prompt = {'text': 'Lumo sammelt 2 Muscheln. 4 kommen dazu. Wie viele sind es?',
                  'left': 135, 'top': 154, 'width': 470, 'height': 12}
        prompt_digits = [{'left': 251, 'top': 154, 'width': 8, 'height': 12, 'text': '2'},
                         {'left': 345, 'top': 154, 'width': 9, 'height': 12, 'text': '4'}]
        options = [{'left': 210, 'top': 190, 'width': 6, 'height': 9, 'text': '5'},
                   {'left': 373, 'top': 190, 'width': 7, 'height': 9, 'text': '6'},
                   {'left': 538, 'top': 190, 'width': 6, 'height': 9, 'text': '7'}]
        for image_name, clock_text in [('013-race.png', '11200'), ('021-wrong-local-hint.png', '1210')]:
            with self.subTest(image=image_name):
                observed = {'height': 480, 'lines': [prompt], 'words': [
                    {'left': 67, 'top': 8, 'width': 49, 'height': 10, 'text': clock_text},
                    *prompt_digits, {'left': 26, 'top': 311, 'width': 14, 'height': 54, 'text': '7'},
                    *options]}
                answer = answer_for(observed)
                self.assertEqual(answer['expected'], 6)
                self.assertIs(answer['option'], options[1])
                self.assertEqual(answer['options'], options)
                wrong = next(word for word in answer['options'] if int(word['text']) != answer['expected'])
                self.assertIs(wrong, options[0])
                self.assertEqual((wrong['left']+wrong['width']//2, wrong['top']+wrong['height']//2), (213, 194))
                self.assertTrue(all(word['top'] > prompt['top']+prompt['height'] for word in answer['options']))


@unittest.skipUnless(shutil.which('tesseract') and importlib.util.find_spec('PIL'),
                     'Actual screenshot OCR requires tesseract and Pillow')
class KartActualScreenshotTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.directory = Path(__file__).parent/'fixtures'/'kart-37121358107'
        cls.provenance = json.loads((cls.directory/'provenance.json').read_text())
        cls.frames = {name: read_frame(cls.directory/name) for name in cls.provenance['files']}

    def test_raw_fixtures_are_the_unmodified_actual_android_frames(self):
        for name, record in self.provenance['files'].items():
            raw = (self.directory/name).read_bytes()
            self.assertEqual(len(raw), record['bytes'])
            self.assertEqual(hashlib.sha256(raw).hexdigest(), record['sha256'])

    def test_all_real_skip_captions_are_read_inside_their_actual_blue_buttons(self):
        for name, observed in self.frames.items():
            with self.subTest(image=name):
                button = action_marker(observed, 'SPATER')
                self.assertIsNotNone(button)
                x, y = button['left']+button['width']//2, button['top']+button['height']//2
                self.assertTrue(553 <= x <= 620 and 108 <= y <= 145)
        self.assertIsNone(action_marker(frame('spacer', 'Die nächste Frage kommt später.'), 'SPATER'))

    def test_complete_wrapped_book_prompt_and_all_real_answer_fields_are_read(self):
        observed = self.frames['033-race.png']
        answer = answer_for(observed)
        self.assertEqual(answer['expected'], 9)
        self.assertEqual([int(word['text']) for word in answer['options']], [9, 6, 12])
        self.assertGreater(answer['option']['top'], .44*observed['height'])
        self.assertTrue(134 <= answer['option']['left'] <= 291)
        self.assertTrue(200 <= answer['option']['top'] <= 236)
        self.assertFalse(local_hint_visible(observed))

    def test_wrapped_garden_task_uses_observed_three_instead_of_prompt_digits(self):
        observed = self.frames['022-race.png']
        answer = answer_for(observed)
        self.assertEqual(answer['expected'], 3)
        self.assertEqual([int(word['text']) for word in answer['options']], [6, 0, 3])
        self.assertTrue(462 <= answer['option']['left'] <= 620)
        self.assertTrue(200 <= answer['option']['top'] <= 236)
        self.assertFalse(local_hint_visible(observed))

    def test_real_wrong_hint_is_contextual_and_correct_eight_remains_readable(self):
        observed = self.frames['016-wrong-local-hint.png']
        self.assertTrue(local_hint_visible(observed))
        self.assertIn('Starte bei 6', observed['lesson_hint']['text'])
        answer = answer_for(observed)
        self.assertEqual(answer['expected'], 8)
        self.assertEqual([int(word['text']) for word in answer['options']], [8, 10, 6])
        self.assertTrue(134 <= answer['option']['left'] <= 291)
        self.assertTrue(176 <= answer['option']['top'] <= 212)

    def test_real_frame_with_missing_base_place_still_proves_round_two_before_result(self):
        observed = self.frames['033-race.png']
        self.assertEqual(race_state(observed), {'round': [2, 2], 'place': [1, 6]})
        self.assertTrue(second_round_in_progress(observed))
        result = {**observed, 'lines': observed['lines']+[{'text': 'Sonnenhafen-Cup geschafft!'}]}
        self.assertFalse(second_round_in_progress(result))


if __name__ == '__main__':
    unittest.main()
