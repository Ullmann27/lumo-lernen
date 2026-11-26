#!/usr/bin/env python3
"""Require observed UI starts for the integrated games in this candidate tour.

The diagnostic collector remains independent and preserves every observation.
This release-workflow gate separately rejects missing, skipped or failed starts.
"""

import argparse
import json
from pathlib import Path
import re


REQUIRED = ('run', 'quiz', 'memory', 'chess', 'kart', 'cards', 'world', 'stars')
FATAL_ISSUES = ('script_error', 'fatal', 'android_runtime', 'fatal_signal',
                'boot_load_error', 'process_died')


def verify(report: dict) -> dict:
    if report.get('status') != 'DONE':
        raise ValueError('Native start diagnostics did not finish')
    package = report.get('package')
    if not isinstance(package, str) or not package:
        raise ValueError('Native start diagnostics contain no observed package')
    native_process_name = package + ':lumo_game'
    entries = report.get('scenes')
    if not isinstance(entries, list):
        raise ValueError('Native start diagnostics contain no scene observations')
    verified = {}
    for name in REQUIRED:
        matches = [entry for entry in entries
                   if isinstance(entry, dict) and entry.get('id') == name]
        if len(matches) != 1:
            raise ValueError(f'{name}: expected exactly one native start observation')
        entry = matches[0]
        if entry.get('scene') != name or entry.get('path') != 'ui':
            raise ValueError(f'{name}: native start did not follow the actual UI route')
        for key in ('skipped', 'error', 'tap_error'):
            if entry.get(key):
                raise ValueError(f'{name}: {key}: {entry[key]}')
        for key in ('tapped', 'router_loaded', 'game_process_alive_at_end', 'app_alive_at_end'):
            if entry.get(key) is not True:
                raise ValueError(f'{name}: missing positive observation for {key}')
        pid = entry.get('native_pid_at_end')
        snapshot = entry.get('process_snapshot_at_end')
        if (type(pid) is not int or pid <= 0 or not isinstance(snapshot, dict)
                or snapshot.get(native_process_name) != pid
                or entry.get('native_process_name') != native_process_name):
            raise ValueError(f'{name}: native process identity was not observed')
        if type(snapshot.get(package)) is not int or snapshot[package] <= 0:
            raise ValueError(f'{name}: Flutter host process identity was not observed')
        router_line = entry.get('router_loaded_line')
        marker = f'[Router] loaded:{name} '
        match = (re.match(r'^\S+\s+\S+\s+(\d+)\s+\d+\s+[VDIWEF]\s+', router_line)
                 if isinstance(router_line, str) else None)
        if (not match or int(match.group(1)) != pid or marker not in router_line
                or entry.get('router_loaded_pid') != pid):
            raise ValueError(f'{name}: router scene and live native PID do not match')
        issues = entry.get('issues')
        if not isinstance(issues, dict):
            raise ValueError(f'{name}: crash and script diagnostics are missing')
        for issue in FATAL_ISSUES:
            if type(issues.get(issue)) is not int or issues[issue] != 0:
                raise ValueError(f'{name}: {issue} was reported or not measured')
        verified[name] = {'router_loaded_after_s': entry.get('router_loaded_after_s'),
                          'ui_route': True, 'process_alive': True,
                          'native_process_name': native_process_name, 'native_pid': pid,
                          'router_loaded_line': router_line}
    return {'status': 'PASS', 'required_scenes': verified,
            'scope': 'Observed UI launch and process survival, not full gameplay or physical-device FPS.'}


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('report', type=Path)
    parser.add_argument('--out', type=Path)
    args = parser.parse_args()
    result = verify(json.loads(args.report.read_text()))
    encoded = json.dumps(result, indent=2) + '\n'
    if args.out:
        args.out.parent.mkdir(parents=True, exist_ok=True)
        args.out.write_text(encoded)
    print(encoded, end='')


if __name__ == '__main__':
    main()
