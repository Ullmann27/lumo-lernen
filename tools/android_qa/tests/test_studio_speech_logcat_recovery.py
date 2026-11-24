"""Run the established transport/voice/movement cases on the actual 2019 probe.

Only the probe path used by the unit-test harness changes. Synthetic log strings
remain parser fixtures and cannot satisfy a real Android acceptance receipt.
"""
from unittest.mock import patch

import test_nextgen_speech_logcat_recovery as established


class StudioSpeechLogcatRecoveryTests(established.SpeechLogcatRecoveryTests):
    def setUp(self):
        super().setUp()
        replacement = patch.object(
            established, 'PROBE',
            established.ROOT / '.github/probes/lumo_studio_surfaces_android_probe.py')
        replacement.start()
        self.addCleanup(replacement.stop)
