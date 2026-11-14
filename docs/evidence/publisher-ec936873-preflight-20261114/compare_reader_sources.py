#!/usr/bin/env python3
"""Independent immutable-source parity check; no reader or publisher is run."""
import difflib
import hashlib
import json
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parent


def blob(data):
    return hashlib.sha1(b'blob '+str(len(data)).encode()+b'\0'+data).hexdigest()


def main():
    inputs = ROOT/'review-inputs'
    publisher_bytes = (ROOT/'lumo-live-2020-publish.yml').read_bytes()
    reader_bytes = (inputs/'reader-workflow-ec.yml').read_bytes()
    assert blob(publisher_bytes) == 'ecbf779ab2e5ce2776fce6418e9419ce013f9b82'
    assert blob(reader_bytes) == 'ed72f394fb7674a3e7ac960235c22cee82450477'
    publisher = yaml.load(publisher_bytes, Loader=yaml.BaseLoader)['jobs']['publish-verified-test-apk']
    reader = yaml.load(reader_bytes, Loader=yaml.BaseLoader)['jobs']['read-current-originals']
    positions = [1, 5, 6, 7, 8, 9, 10]
    paired = [reader['steps'][index-1] for index in positions]
    assert publisher['steps'][:7] == paired
    for key in ('SOURCE_SHA', 'ACCEPTANCE_RUN'):
        assert publisher['env'][key] == reader['env'][key]
    old = (inputs/'reader-driver-04.py').read_text()
    new = (inputs/'reader-driver-ec.py').read_text()
    assert blob(old.encode()) == '0028aac49374245c85da27a69d1ae4113e87c1a9'
    assert blob(new.encode()) == '72406f6f995b0c85414c8c8560ca563273071921'
    substitutions = [
        ('04a8e850d4c198e16ff758df614ce6e53eab4524', 'ec936873a45ffeb9ab347cc6bdb10951e38fac5e'),
        ('80a797c2b547ed72fc496600f7959f6ac4f5f9e6', 'c7d6541e474f8d8ba64b204beb6466c811fb246b'),
        ('43628840534', '43633922088'),
        ('exact accepted 04 original archives', 'exact accepted ec original archives'),
    ]
    expected = old
    for before, after in substitutions:
        assert expected.count(before) == 1
        expected = expected.replace(before, after)
    assert expected == new
    comparison = json.loads((inputs/'reader-compare-summary.json').read_text())
    assert comparison['base_commit'] == 'ec936873a45ffeb9ab347cc6bdb10951e38fac5e'
    assert len(comparison['files']) == 8 and all(row['status'] == 'added' for row in comparison['files'])
    unchanged = {
        'test_original_replay.py': '11c5ad2de2ce556a66273c776da2947ad23de8cd',
        'original_png_transport.py': '88388945e5e31eaefb2dad69f400b93f65a6b94a',
        'test_original_png_transport.py': '313fdb2c57f018cf251be00b6171fccb3c2bfa67',
    }
    for name, sha in unchanged.items():
        rows = [row for row in comparison['files'] if Path(row['path']).name == name]
        assert len(rows) == 1 and rows[0]['sha'] == sha
    report = {
        'schema': 1, 'scope': 'Independent source comparison; no tests, archives, reader or publisher execution.',
        'reader_checkpoint': '99faf8deee4b43594965ed7b9e172919fe6ef6aa',
        'reader_tree': '660864f7b96bf2e19de8d6c1d5becd3fd3138749',
        'reader_workflow_blob': blob(reader_bytes), 'publisher_workflow_blob': blob(publisher_bytes),
        'seven_publisher_read_steps_structurally_identical_in_reader': True,
        'reader_step_positions': positions, 'literal_first_seven_reader_steps_equal': False,
        'reader_extra_setup_steps': [row['name'] for row in reader['steps'][1:4]],
        'first_seven_step_names': [row['name'] for row in paired],
        'source_and_main_run_env_identical': True,
        'embedded_additional_verifier_and_bindings_identical': True,
        'old_reader_driver_blob': blob(old.encode()), 'new_reader_driver_blob': blob(new.encode()),
        'driver_only_four_exact_substitutions': [{'old': a, 'new': b, 'occurrences': 1} for a, b in substitutions],
        'all_other_driver_bytes_unchanged': True,
        'unchanged_24_plus_3_tests_and_png_exporter': unchanged,
        'reader_compare_only_eight_added_files': True,
        'reader_or_publisher_activated': False,
        'conclusion': 'No source rebind or read-step parity blocker. Full seven-job acceptance and original replay remain mandatory.'}
    with (ROOT/'reader-source-comparison.json').open('x') as output:
        output.write(json.dumps(report, indent=2)+'\n')
    with (ROOT/'reader-driver-binding.diff').open('x') as output:
        output.write(''.join(difflib.unified_diff(old.splitlines(True), new.splitlines(True),
                                               fromfile='reader04.py', tofile='readerec.py')))
    print(json.dumps({'status': 'PASS_SOURCE_COMPARISON_ONLY', 'read_steps': len(positions),
                      'driver_binding_changes': len(substitutions)}))


if __name__ == '__main__':
    main()
