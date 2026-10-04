"""Synthetic system-dialog guards; these are not Android usage evidence.

Only the three captions were observed in CI runs 37117513430/37117848830.
The prior failure path saved no actual dialog XML or screenshot, so layout and
resource nodes below model normal Android dialogs rather than a device dump.
"""
from pathlib import Path
import sys
import unittest
import xml.etree.ElementTree as ET

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from system_ui import PIXEL_LAUNCHER_ANR_TITLE, pixel_launcher_anr_close_bounds


def dialog():
    return ET.fromstring('''<hierarchy rotation="0">
      <node package="android" enabled="true" bounds="[0,0][480,800]">
        <node package="android" enabled="true" bounds="[24,260][456,540]">
          <node text="Pixel Launcher isn't responding" resource-id="android:id/alertTitle"
            class="android.widget.TextView" package="android" enabled="true"
            clickable="false" bounds="[48,280][432,330]"/>
          <node text="Close app" resource-id="android:id/aerr_close"
            class="android.widget.TextView" package="android" enabled="true"
            clickable="true" bounds="[48,360][432,420]"/>
          <node text="Wait" resource-id="android:id/aerr_wait"
            class="android.widget.TextView" package="android" enabled="true"
            clickable="true" bounds="[48,440][432,500]"/>
        </node>
      </node>
    </hierarchy>''')


class PixelLauncherAnrTests(unittest.TestCase):
    def test_exact_observed_captions_return_current_clickable_bounds_without_mutation(self):
        root = dialog()
        before = ET.tostring(root)
        self.assertEqual(pixel_launcher_anr_close_bounds(root), (48, 360, 432, 420))
        self.assertEqual(ET.tostring(root), before)
        close = root.find(".//node[@text='Close app']")
        close.set('bounds', '[60,365][420,415]')
        self.assertEqual(pixel_launcher_anr_close_bounds(root), (60, 365, 420, 415))

    def test_every_other_app_failure_or_near_title_remains_unrecovered(self):
        for title in ("Lumo Lernen isn't responding", "System UI isn't responding",
                      'Pixel Launcher keeps stopping', 'Pixel Launcher isn’t responding',
                      PIXEL_LAUNCHER_ANR_TITLE + ' again', ''):
            with self.subTest(title=title):
                root = dialog()
                root.find(".//node[@resource-id='android:id/alertTitle']").set('text', title)
                self.assertIsNone(pixel_launcher_anr_close_bounds(root))

    def test_missing_wait_or_ambiguous_close_app_fails_closed(self):
        root = dialog()
        wait = root.find(".//node[@text='Wait']")
        root.find('.//node/node').remove(wait)
        self.assertIsNone(pixel_launcher_anr_close_bounds(root))
        root = dialog()
        root.find('.//node/node').append(ET.fromstring('''<node text="Close app"
            package="android" enabled="true" clickable="true"
            bounds="[48,510][432,530]"/>'''))
        self.assertIsNone(pixel_launcher_anr_close_bounds(root))

    def test_foreign_packages_ids_disabled_hidden_or_unclickable_actions_are_rejected(self):
        for caption, attribute, value in (
            (PIXEL_LAUNCHER_ANR_TITLE, 'package', 'dev.ullmann.lumo.lumo_lernen'),
            ('Close app', 'package', 'dev.ullmann.lumo.lumo_lernen'),
            ('Close app', 'resource-id', 'android:id/button1'),
            ('Close app', 'enabled', 'false'), ('Close app', 'clickable', 'false'),
            ('Close app', 'visible-to-user', 'false'), ('Wait', 'displayed', 'false'),
            ('Wait', 'clickable', 'false'),
        ):
            with self.subTest(caption=caption, attribute=attribute):
                root = dialog()
                next(n for n in root.iter('node') if n.get('text') == caption).set(attribute, value)
                self.assertIsNone(pixel_launcher_anr_close_bounds(root))

    def test_empty_malformed_clipped_or_overlapping_action_bounds_are_rejected(self):
        for bounds in ('', '[48,360][48,420]', '[-1,360][432,420]',
                       '[48,360][490,420]', '[48,460][432,500]', '[48,360][432,900]'):
            with self.subTest(bounds=bounds):
                root = dialog()
                root.find(".//node[@text='Close app']").set('bounds', bounds)
                self.assertIsNone(pixel_launcher_anr_close_bounds(root))

    def test_actions_must_share_one_visible_system_dialog(self):
        root = dialog()
        root.find('.//node/node').set('package', 'other.app')
        self.assertIsNone(pixel_launcher_anr_close_bounds(root))
        root = dialog()
        root.find('.//node').set('visible-to-user', 'false')
        self.assertIsNone(pixel_launcher_anr_close_bounds(root))
        root = dialog()
        root.find('.//node/node').append(ET.fromstring('''<node text="Other app isn't responding"
            resource-id="android:id/alertTitle" package="android" enabled="true"
            bounds="[48,510][432,530]"/>'''))
        self.assertIsNone(pixel_launcher_anr_close_bounds(root))


if __name__ == '__main__':
    unittest.main()
