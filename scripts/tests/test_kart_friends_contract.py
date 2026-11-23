"""Geister-Duell (Lumo Kart): Host-Regeln kompilieren und gegen einen echten Godot-Geist prüfen.

Prüft nur die Android-freien Regeln (Größe, Kennung, Textform, Namen, Dateiname) und den
Quelltext-Vertrag. Teilen-Menü, „Öffnen mit“ und Dateiauswahl brauchen ein echtes Gerät.
"""
from pathlib import Path
import os
import re
import shutil
import subprocess
import tempfile
import unittest
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[2]
FIXTURE = ROOT / 'test/fixtures/kart_friend_ghost_lena.lumogeist'


class KartFriendsContractTest(unittest.TestCase):
    def test_rules_compile_and_accept_only_small_ghost_files(self):
        java = shutil.which('java')
        libraries = Path(os.environ.get('LUMO_KOTLIN_LIB_DIR', '/nonexistent'))
        if not java or not list(libraries.glob('kotlin-compiler-embeddable-*.jar')):
            self.skipTest('Kotlin-Bibliotheken fehlen (LUMO_KOTLIN_LIB_DIR)')
        with tempfile.TemporaryDirectory(prefix='lumo-kart-friends-') as temp:
            classes = Path(temp) / 'classes'
            classes.mkdir()
            stdlib = next(libraries.glob('kotlin-stdlib-*.jar'))
            classpath = os.pathsep.join(map(str, (classes, stdlib)))
            compile_result = subprocess.run([
                java, '-cp', os.pathsep.join(map(str, sorted(libraries.glob('*.jar')))),
                'org.jetbrains.kotlin.cli.jvm.K2JVMCompiler', '-no-stdlib', '-no-reflect',
                '-classpath', classpath, '-jvm-target', '1.8', '-d', str(classes),
                str(ROOT / 'tools/auto_install/KartGhostRules.kt'),
                str(ROOT / 'scripts/tests/fixtures/kart_ghost_rules/KartGhostRulesContract.kt'),
            ], capture_output=True, text=True, timeout=180)
            self.assertEqual(compile_result.returncode, 0, compile_result.stdout + compile_result.stderr)
            run = subprocess.run([java, '-cp', classpath, 'dev.ullmann.lumo.KartGhostRulesContractKt', str(FIXTURE)],
                                 capture_output=True, text=True, timeout=60)
            self.assertEqual(run.returncode, 0, run.stdout + run.stderr)
            self.assertIn('LUMO_KART_GHOST_RULES_PASS checks=20', run.stdout)

    def test_host_wiring(self):
        main = (ROOT / 'tools/auto_install/MainActivity.kt').read_text()
        game = (ROOT / 'tools/auto_install/LumoGameActivity.kt').read_text()
        bridge = (ROOT / 'tools/auto_install/KartFriendsBridge.kt').read_text()
        self.assertIn('kartFriends?.handleIntent(intent)', main)
        self.assertIn('kartFriends?.onActivityResult(requestCode, resultCode, data) == true', main)
        # Startoption nur für das Kart und nur in geprüfter Form. Der Block
        # enthält inzwischen sichere runCatching/Lambda-Blöcke mit eigenen
        # Klammern; deshalb die echte Kart-Scope-Grenze statt eines [^}]-Regex.
        kart_start = main.index('if (game == "kart") {')
        kart_end = main.index('options.put("reduceAnimations"', kart_start)
        kart_block = main[kart_start:kart_end]
        self.assertIn('if (ghostDuel && KartGhostRules.isLaunchText(ghost))', kart_block)
        self.assertIn('fun shareKartGhost(base64: String, fileName: String, title: String): Boolean', game)
        # Zweite Elternfreigabe „Geister-Duell“: ohne sie startet kein Geist und teilt der Host nichts.
        self.assertIn('if (ghostDuel && KartGhostRules.isLaunchText(ghost))', main)
        self.assertIn('options.put("friendsGhostShare", ghostDuel)', main)
        self.assertRegex(game, r'optBoolean\("friendsGhostShare", false\)[\s\S]{0,160}allowed && KartFriendsBridge\.share')
        # Lesen nie auf dem Hauptthread, Größe begrenzt, keine neue Berechtigung.
        self.assertIn('Thread({', bridge)
        self.assertIn('KartGhostRules.readLimited(it)', bridge)
        self.assertNotIn('requestPermissions', bridge)
        self.assertNotIn('checkSelfPermission', bridge)
        self.assertIn('ACTION_OPEN_DOCUMENT', bridge)
        # Deep-Links (lumolernen:) dürfen nie als Geist-Datei gelesen werden.
        self.assertIn('if (uri.scheme != "content") return false', bridge)
        prepare = (ROOT / 'scripts/prepare_android.py').read_text()
        for name in ('KartGhostRules.kt', 'KartFriendsBridge.kt'):
            self.assertIn(f"('{name}', 'kotlin')", prepare)

    def test_parent_approvals_default_off_and_gate_name_and_ghost(self):
        settings = (ROOT / 'lib/core/app_settings.dart').read_text()
        launcher = (ROOT / 'lib/features/lumo3d/lumo3d_launcher.dart').read_text()
        inbox = (ROOT / 'lib/features/kart_friends/kart_friends_inbox.dart').read_text()
        for field in ('lanPlayEnabled', 'ghostDuelEnabled'):
            self.assertIn(f'this.{field} = false', settings)
            self.assertIn(f"{field}: _bool(json['{field}'], fallback: false)", settings)
        self.assertIn("appState?.state.settings.ghostDuelEnabled != true", launcher)
        self.assertIn("'friendsGhostShare': appState?.state.settings.ghostDuelEnabled == true", launcher)
        self.assertIn('!appState.state.settings.ghostDuelEnabled', inbox)

    def test_dart_and_kotlin_share_the_launch_text_limit(self):
        dart = (ROOT / 'lib/features/kart_friends/kart_friend_ghost.dart').read_text()
        kotlin = (ROOT / 'tools/auto_install/KartGhostRules.kt').read_text()
        self.assertIn('textPrefix.length + 87382', dart)
        self.assertIn('{40,87382}', kotlin)
        self.assertIn('maxFileBytes = 65536', dart)
        self.assertIn('MAX_BYTES = 65536', kotlin)


if __name__ == '__main__':
    unittest.main()
