"""Replay exact Treasure output; all other module files are synthetic fixtures."""
from pathlib import Path
import argparse
import hashlib
import importlib.util
import json
import os
import struct
import time


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--captures', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    captures = args.captures.resolve()
    output = args.output.resolve()
    output.mkdir(parents=True, exist_ok=False)
    package = Path(__file__).resolve().parent
    names = {
        'landscape': (1920, 1080), 'compact': (640, 320),
        'portrait': (1080, 2400), 'fold': (2176, 1812),
        'landscape-cutout': (2400, 1080),
    }
    report = captures / 'treasure-title-report.json'
    state = json.loads(report.read_bytes())
    assert state['checks'] == 3351 and state['failures'] == []
    assert len(state['observations']) == 10
    assert {p.name for p in captures.glob('*.png')} == {
        f'treasure-title-{name}.png' for name in names}
    files = []
    for path in [report] + sorted(captures.glob('*.png')):
        data = path.read_bytes()
        item = {'path': str(path), 'bytes': len(data),
                'sha256': hashlib.sha256(data).hexdigest()}
        if path.suffix == '.png':
            assert data[:8] == b'\x89PNG\r\n\x1a\n'
            size = struct.unpack('>II', data[16:24])
            assert size == names[path.stem.removeprefix('treasure-title-')]
            item['size_px'] = list(size)
        files.append(item)
    spec = importlib.util.spec_from_file_location(
        'treasure_contract', package / 'native/tools/tests/test_nextgen_runner.py')
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)

    class Replay(module.StudioPuzzleMenuContractTests):
        def treasure_title_fixture(self, root, mutation):
            os.symlink(captures, root / 'captures/treasure_title_contrast_regression',
                       target_is_directory=True)

    case = Replay()
    case.setUp()
    extended = case.roster
    original = (package / 'baseline/native/tools/validate_studio.sh').read_text()
    original = original.split("<<'PY'\n", 1)[1].split('\nPY\n', 1)[0]
    results = []
    for name, code in [('original-acf51', original), ('extended', extended)]:
        case.roster = code
        start = time.monotonic()
        process, roster = case.roster_fixture()
        elapsed = time.monotonic() - start
        (output / f'{name}.log').write_text(process.stdout + process.stderr)
        item = {'runner': name, 'exit_code': process.returncode,
                'elapsed_seconds': elapsed, 'renderer_roster_emitted': roster is not None,
                'stdout': process.stdout, 'stderr': process.stderr}
        if name == 'original-acf51':
            assert process.returncode != 0 and roster is None
        else:
            assert process.returncode == 0, process.stderr
            assert len(roster['images']) == 54
            selected = [row for row in roster['images']
                        if '/treasure_title_contrast_regression/' in row['path']]
            assert len(selected) == 5
            item['actual_treasure_image_entries'] = selected
            (output / 'mixed-fixture-roster.json').write_text(
                json.dumps(roster, indent=2) + '\n')
        results.append(item)
    sources = []
    for relative in ('tools/validate_studio.sh', 'tools/tests/test_nextgen_runner.py'):
        raw = (package / 'native' / relative).read_bytes()
        sources.append({'path': relative, 'sha256': hashlib.sha256(raw).hexdigest()})
    result = {
        'scope': 'Exact final Treasure renderer JSON and five PNGs replayed through original '
                 'and extended roster. Other 49 rasters and their sidecars are synthetic '
                 'contract fixtures. No new Engine/CI/Android execution or visual review.',
        'native_baseline': 'acf51d3bd2997c4b731e9a48e1791e05e756a132',
        'actual_report_checks': state['checks'], 'actual_observation_count': 10,
        'sources': sources, 'files': files, 'results': results,
    }
    (output / 'result.json').write_text(json.dumps(result, indent=2) + '\n')
    print(json.dumps({'original_exit': results[0]['exit_code'],
                      'extended_exit': results[1]['exit_code'],
                      'actual_treasure_images': 5, 'synthetic_other_images': 49,
                      'output': str(output)}, indent=2))


if __name__ == '__main__':
    main()
