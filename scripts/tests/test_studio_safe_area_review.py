"""Synthetic archive/parser contracts, never renderer or Android acceptance."""
from __future__ import annotations

import copy
from functools import lru_cache
import hashlib
from io import BytesIO
import json
from pathlib import Path
import sys
import unittest
import zipfile

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import verify_studio_delivery as delivery


SAFE_AREA_PNGS = {
    'captures/cards_safe_area_regression/android35_portrait-playing.png': (1080, 2400),
    'captures/cards_safe_area_regression/android35_portrait-paused.png': (1080, 2400),
    'captures/cards_safe_area_regression/landscape_cutout_fixture-playing.png': (2400, 1080),
    'captures/mobile_safe_area_regression/jump-landscape-cutout.png': (2400, 1080),
    'captures/mobile_safe_area_regression/build-landscape-cutout.png': (2400, 1080),
    'captures/mobile_safe_area_regression/puzzle-landscape-cutout.png': (2400, 1080),
    'captures/mobile_safe_area_regression/treasure-landscape-cutout.png': (2400, 1080),
}
PROFILES = {
    'android35_portrait': ((1080, 2400), 2.625, [0, 136, 1080, 2201]),
    'android35_portrait_earlier_inset': ((1080, 2400), 2.625, [0, 145, 1080, 2192]),
    'landscape_cutout_fixture': ((2400, 1080), 2.625, [136, 63, 2264, 954]),
    'short_landscape_fixture': ((640, 360), 1.0, [0, 32, 640, 304]),
    'desktop_without_insets': ((1280, 720), 1.0, [0, 0, 1280, 720]),
}
MOBILE_TARGETS = (
    ('jump', '‹ Spiele'), ('jump', 'Pause'), ('jump', 'MovementStick'), ('jump', 'JumpAction'),
    ('build', '‹ Spiele'), ('build', 'Ⅱ'), ('build', 'Verschieben'),
    ('puzzle', '‹ Spiele'), ('puzzle', 'Ⅱ'),
    ('treasure', '‹ Spiele'), ('treasure', 'Rucksack'), ('treasure', 'Ⅱ'),
    ('treasure', 'Springen'), ('treasure', 'MovementStick'), ('treasure', 'ANSEHEN'),
)
CARDS_REPORT = 'captures/cards_safe_area_regression/cards-safe-area.json'
MOBILE_REPORT = 'captures/mobile_safe_area_regression/mobile-safe-area.json'


@lru_cache(maxsize=10)
def two_color_png(width: int, height: int, color: int) -> bytes:
    from PIL import Image
    image = Image.new('RGB', (width, height), (color, 45, 80))
    image.paste((20, 45, color), (width // 2, 0, width, height))
    output = BytesIO()
    image.save(output, format='PNG')
    return output.getvalue()


def synthetic_layout(profile: str, *, paused: bool = False) -> dict:
    size, density, bounds = PROFILES[profile]
    return {
        'schema': 1, 'settled': True, 'ui_visible': True, 'pending': 0,
        'observation_source': 'fixture', 'paused': paused, 'window_px': list(size),
        'layout_sequence': 2 if paused else 1, 'token': 'synthetic-parser-token',
        'roundId': 'synthetic-parser-round', 'density': density, 'ui_rect': list(bounds),
        'hand': [{'id': 'hand-a', 'quad': [[200, 160], [240, 160], [240, 240], [200, 240]]},
                 {'id': 'hand-b', 'quad': [[250, 160], [290, 160], [290, 240], [250, 240]]}],
        'discard': {'id': 'discard-a', 'quad': [[360, 140], [400, 140], [400, 220], [360, 220]]},
    }


def descriptor(path: str, data: bytes) -> dict:
    return {'path': path, 'bytes': len(data), 'sha256': hashlib.sha256(data).hexdigest()}


def safe_area_members() -> dict[str, bytes]:
    """Return independent synthetic members relative to the fixed Nextgen prefix."""
    members, roster, cards_images, mobile_images = {}, [], [], []
    for index, (path, size) in enumerate(SAFE_AREA_PNGS.items()):
        data = two_color_png(*size, 240 + index)
        members[path] = data
        item = {**descriptor(path, data), 'width': size[0], 'height': size[1]}
        if '/cards_safe_area_regression/' in path:
            profile = Path(path).name.rsplit('-', 1)[0]
            layout_path = str(Path(path).with_suffix('.layout.json'))
            layout_data = json.dumps(synthetic_layout(profile, paused=path.endswith('-paused.png'))).encode()
            members[layout_path] = layout_data
            item['native_layout'] = descriptor(layout_path, layout_data)
            cards_images.append({'path': '/synthetic-unittest/' + path, 'profile': profile,
                                 'size': list(size), 'safe_rect_px': list(PROFILES[profile][2])})
        else:
            mobile_images.append({'module': Path(path).name.split('-')[0], 'path': Path(path).name,
                                  'width': size[0], 'height': size[1], 'sha256': item['sha256']})
        roster.append(item)
    cards_targets, projections = [], []
    for profile, (size, density, bounds) in PROFILES.items():
        cards_targets.append({'profile': profile, 'label': 'Synthetic parser target',
                              'rect_px': [bounds[0] + 10, bounds[1] + 10, 48 * density, 48 * density],
                              'dp': [48, 48], 'safe_rect_px': list(bounds)})
        layout = synthetic_layout(profile)
        # Actual Godot JSON.parse_string + JSON.stringify in projected_views
        # preserves integral values but writes them as floats in this report.
        for key in ('schema', 'layout_sequence', 'pending'):
            layout[key] = float(layout[key])
        projections.append({'profile': profile, 'hand': copy.deepcopy(layout['hand']),
                            'ui_rect': list(bounds), 'native_layout': layout})
    cards = {'checks': 1, 'failures': [], 'renderer': 'synthetic-parser-fixture',
             'android_device_measurement': False, 'fixture_scope': 'Synthetic parser input, never a renderer run',
             'images': cards_images, 'targets': cards_targets, 'projected_views': projections,
             'input_events': []}
    mobile = {'checks': 1, 'failures': [],
              'scope': 'production cache and scenes with asynchronous Android boundary fixture; not device execution',
              'surface': [2400, 1080], 'density': 2.625, 'observed_system_inset_fixture': [136, 63, 0, 63],
              'images': mobile_images, 'events': [],
              'targets': [{'module': module, 'caption': caption, 'rect_px': [200, 100, 126, 126],
                           'target_dp': [48, 48], 'exposed_dp': [48, 48], 'fully_inside_true_safe_area': True}
                          for module, caption in MOBILE_TARGETS]}
    reports = []
    for path, report in ((CARDS_REPORT, cards), (MOBILE_REPORT, mobile)):
        data = json.dumps(report).encode()
        members[path] = data
        reports.append(descriptor(path, data))
    members['safe-area-images.json'] = json.dumps({'schema': 1, 'images': roster, 'reports': reports}).encode()
    return members


class StudioSafeAreaReviewTests(unittest.TestCase):
    def verify(self, members: dict[str, bytes]) -> dict:
        output = BytesIO()
        with zipfile.ZipFile(output, 'w') as zipped:
            for path, data in members.items():
                zipped.writestr(delivery.NEXTGEN_PREFIX + '/' + path, data)
        with zipfile.ZipFile(BytesIO(output.getvalue())) as zipped:
            return delivery.verify_nextgen_safe_area_archive(zipped)

    @staticmethod
    def replace_bound_json(members: dict, path: str, value: dict) -> None:
        data = json.dumps(value).encode()
        members[path] = data
        roster = json.loads(members['safe-area-images.json'])
        if path.endswith('.layout.json'):
            for image in roster['images']:
                if image.get('native_layout', {}).get('path') == path:
                    image['native_layout'] = descriptor(path, data)
        else:
            for report in roster['reports']:
                if report['path'] == path:
                    report.update(descriptor(path, data))
        members['safe-area-images.json'] = json.dumps(roster).encode()

    def test_all_seven_originals_three_layouts_and_two_reports_keep_fixture_scope(self):
        members = safe_area_members()
        before = dict(members)
        facts = self.verify(members)
        self.assertEqual(dict(delivery.NEXTGEN_SAFE_AREA_PNGS), SAFE_AREA_PNGS)
        self.assertEqual(facts['native_safe_area_raster_count'], 7)
        self.assertEqual(facts['native_cards_layout_count'], 3)
        self.assertEqual(facts['native_safe_area_report_count'], 2)
        self.assertIn('not Android device execution', facts['native_safe_area_scope'])
        self.assertEqual(members, before)

    def test_mobile_scene_identity_is_fixed_per_original_filename(self):
        for module in ('jump', 'build', 'puzzle', 'treasure'):
            entry = delivery.NEXTGEN_MOBILE_SAFE_AREA_CAPTURE + '/' + module + '-landscape-cutout.png'
            self.assertEqual(delivery.capture_module(entry, native_profile='nextgen-2019'), module)
            for alternative in ('puzzle', 'treasure', 'cards'):
                if alternative == module:
                    continue
                with self.subTest(module=module, alternative=alternative), self.assertRaises(ValueError):
                    delivery.reviewed_relative_path('a' * 64, alternative, entry, native_profile='nextgen-2019')
            with self.assertRaises(ValueError):
                delivery.capture_module(entry)
        with self.assertRaises(ValueError):
            delivery.capture_module(delivery.NEXTGEN_MOBILE_SAFE_AREA_CAPTURE + '/invented.png',
                                    native_profile='nextgen-2019')

    def test_missing_original_members_never_pass_even_with_a_valid_roster(self):
        expected = safe_area_members()
        for path in expected:
            members = dict(expected)
            del members[path]
            with self.subTest(path=path), self.assertRaises(ValueError):
                self.verify(members)

    def test_roster_digest_bytes_duplicates_and_capture_directory_are_binding(self):
        for mutation in ('digest', 'bytes', 'duplicate', 'dimensions', 'wrong-sidecar',
                         'report-digest', 'report-duplicate', 'extra-png', 'mobile-layout'):
            members = safe_area_members()
            roster = json.loads(members['safe-area-images.json'])
            image = roster['images'][0]
            if mutation == 'digest': image['sha256'] = '0' * 64
            if mutation == 'bytes': image['bytes'] += 1
            if mutation == 'duplicate': roster['images'][-1] = copy.deepcopy(image)
            if mutation == 'dimensions': image['height'] += 1
            if mutation == 'wrong-sidecar': image['native_layout'] = roster['images'][1]['native_layout']
            if mutation == 'report-digest': roster['reports'][0]['sha256'] = '0' * 64
            if mutation == 'report-duplicate': roster['reports'][1] = copy.deepcopy(roster['reports'][0])
            if mutation == 'extra-png':
                members['captures/cards_safe_area_regression/unrequested.png'] = members[image['path']]
            if mutation == 'mobile-layout': roster['images'][-1]['native_layout'] = image['native_layout']
            members['safe-area-images.json'] = json.dumps(roster).encode()
            with self.subTest(mutation=mutation), self.assertRaises(ValueError):
                self.verify(members)

    def test_rehashed_unsettled_foreign_or_invisible_layout_cannot_pass(self):
        path = 'captures/cards_safe_area_regression/android35_portrait-playing.layout.json'
        for field, value in (('settled', False), ('pending', 1), ('ui_visible', False),
                             ('observation_source', 'android'), ('window_px', [2400, 1080]),
                             ('paused', True), ('layout_sequence', 0), ('hand', []), ('discard', {})):
            members = safe_area_members()
            layout = json.loads(members[path])
            layout[field] = value
            self.replace_bound_json(members, path, layout)
            with self.subTest(field=field), self.assertRaises(ValueError):
                self.verify(members)

    def test_rehashed_layout_requires_finite_visible_original_face_geometry(self):
        path = 'captures/cards_safe_area_regression/android35_portrait-playing.layout.json'
        for mutation in ('nan', 'outside', 'degenerate', 'duplicate-face'):
            members = safe_area_members()
            layout = json.loads(members[path])
            if mutation == 'nan': layout['hand'][0]['quad'][0][0] = float('nan')
            if mutation == 'outside': layout['hand'][0]['quad'][0][0] = -100
            if mutation == 'degenerate': layout['hand'][0]['quad'] = [[200, 200]] * 4
            if mutation == 'duplicate-face': layout['discard']['id'] = layout['hand'][0]['id']
            self.replace_bound_json(members, path, layout)
            with self.subTest(mutation=mutation), self.assertRaises(ValueError):
                self.verify(members)

    def test_original_reports_cannot_hide_failures_change_scope_or_lie_about_geometry(self):
        for mutation in ('cards-failure', 'device-claim', 'headless', 'wrong-card-profile',
                         'projection-drift', 'fractional-report-schema', 'boolean-report-pending',
                         'missing-profile', 'mobile-failure', 'mobile-scope',
                         'mobile-hash', 'mobile-module', 'duplicate-target', 'unsafe-target',
                         'clipped-target', 'small-target', 'lying-dp'):
            members = safe_area_members()
            cards = json.loads(members[CARDS_REPORT])
            mobile = json.loads(members[MOBILE_REPORT])
            if mutation == 'cards-failure': cards['failures'].append('real observed failure')
            if mutation == 'device-claim': cards['android_device_measurement'] = True
            if mutation == 'headless': cards['renderer'] = 'headless'
            if mutation == 'wrong-card-profile': cards['images'][0]['profile'] = 'desktop_without_insets'
            if mutation == 'projection-drift': cards['projected_views'][0]['hand'][0]['quad'][0][0] += 5
            if mutation == 'fractional-report-schema': cards['projected_views'][0]['native_layout']['schema'] = 1.5
            if mutation == 'boolean-report-pending': cards['projected_views'][0]['native_layout']['pending'] = False
            if mutation == 'missing-profile': cards['projected_views'].pop()
            if mutation == 'mobile-failure': mobile['failures'].append('real observed failure')
            if mutation == 'mobile-scope': mobile['scope'] = 'Android device acceptance'
            if mutation == 'mobile-hash': mobile['images'][0]['sha256'] = '0' * 64
            if mutation == 'mobile-module': mobile['images'][0]['module'] = 'puzzle'
            if mutation == 'duplicate-target': mobile['targets'][-1] = copy.deepcopy(mobile['targets'][0])
            if mutation == 'unsafe-target': mobile['targets'][0]['fully_inside_true_safe_area'] = False
            if mutation == 'clipped-target': mobile['targets'][0]['rect_px'][0] = 0
            if mutation == 'small-target':
                mobile['targets'][0].update(rect_px=[200, 100, 100, 100], target_dp=[100 / 2.625] * 2,
                                            exposed_dp=[100 / 2.625] * 2)
            if mutation == 'lying-dp': mobile['targets'][0]['rect_px'][2] = 200
            self.replace_bound_json(members, CARDS_REPORT, cards)
            self.replace_bound_json(members, MOBILE_REPORT, mobile)
            with self.subTest(mutation=mutation), self.assertRaises(ValueError):
                self.verify(members)

    def test_report_originals_require_regular_unique_zip_members(self):
        members = safe_area_members()
        for mutation in ('duplicate', 'symlink'):
            output = BytesIO()
            with zipfile.ZipFile(output, 'w') as zipped:
                for path, data in members.items():
                    name = delivery.NEXTGEN_PREFIX + '/' + path
                    if path == MOBILE_REPORT and mutation == 'symlink':
                        item = zipfile.ZipInfo(name)
                        item.create_system = 3
                        item.external_attr = 0o120777 << 16
                        zipped.writestr(item, data)
                    else:
                        zipped.writestr(name, data)
                if mutation == 'duplicate':
                    import warnings
                    with warnings.catch_warnings():
                        warnings.simplefilter('ignore', UserWarning)
                        zipped.writestr(delivery.NEXTGEN_PREFIX + '/' + MOBILE_REPORT, members[MOBILE_REPORT])
            with zipfile.ZipFile(BytesIO(output.getvalue())) as zipped:
                with self.subTest(mutation=mutation), self.assertRaises(ValueError):
                    delivery.verify_nextgen_safe_area_archive(zipped)


if __name__ == '__main__':
    unittest.main()
