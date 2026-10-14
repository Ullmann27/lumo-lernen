"""Synthetic motion replay anchored to the real 1939 moving-sheet coordinates."""
import ast
import json
from pathlib import Path
import tempfile
from types import SimpleNamespace
import unittest

ROOT = Path(__file__).resolve().parents[3]


class StableFlutterControlTest(unittest.TestCase):
    def test_never_tap_the_parent_row_while_it_is_bouncing(self):
        node = next(n for n in ast.walk(ast.parse((ROOT/'.github/probes/lumo_1939_flutter_navigation.py').read_text())) if isinstance(n, ast.FunctionDef) and n.name == 'tap_stable_control')
        # First two positions are from real captures in failed/passed 1939 runs.
        # Remaining positions model a bouncing sheet; this is an offline unit test.
        motion = iter([[36,1785,1044,1977], [36,1729,1044,1921],
                       [36,1810,1044,2002], [36,1810,1044,2002],
                       [36,1810,1044,2002], [36,1810,1044,2002]])
        now, touches, observations = [0.0], [], []
        def nodes(*_):
            b=next(motion);observations.append(b);return b
        def sleep(s): now[0] += s
        existing=SimpleNamespace(live=SimpleNamespace(live_nodes=nodes),
            recover_launcher_dialog=lambda *_:False,
            base=SimpleNamespace(adb=lambda *args: touches.append(args)))
        scope=dict(Path=Path,json=json,existing=existing,
                   time=SimpleNamespace(monotonic=lambda:now[0],sleep=sleep),
                   _enabled_control_bounds=lambda nodes,caption:nodes)
        exec(compile(ast.Module(body=[node],type_ignores=[]),'actual_flutter_tap','exec'),scope)
        with tempfile.TemporaryDirectory() as tmp:
            scope['tap_stable_control'](Path(tmp),'Elternbereich','parents')
            self.assertGreaterEqual(len(observations),5)
            self.assertEqual(touches,[('shell','input','swipe','540','1906','540','1906','120')])
            proof=json.loads((Path(tmp)/'parents-stable-touch.json').read_text())
            self.assertGreaterEqual(proof['stable_seconds'],.8)

if __name__ == '__main__': unittest.main()
