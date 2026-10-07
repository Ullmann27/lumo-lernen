from pathlib import Path
import unittest


ROOT = Path(__file__).resolve().parents[3]
PREPARE = ROOT / "scripts" / "prepare_embedded_games.py"


class EmbeddedKartOrientationTest(unittest.TestCase):
    def setUp(self):
        self.source = PREPARE.read_text(encoding="utf-8")

    def test_kart_activity_uses_sensor_landscape_not_portrait(self):
        self.assertIn("'screenOrientation': 'sensorLandscape'", self.source)
        self.assertNotIn("'screenOrientation': 'portrait'", self.source)

    def test_kart_activity_remains_resizable_for_foldables(self):
        self.assertIn("'resizeableActivity': 'true'", self.source)

    def test_resize_config_changes_cover_fold_window_changes(self):
        for token in (
            "orientation",
            "screenSize",
            "smallestScreenSize",
            "screenLayout",
            "density",
        ):
            self.assertIn(token, self.source)


if __name__ == "__main__":
    unittest.main()
