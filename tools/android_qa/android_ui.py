#!/usr/bin/env python3
"""ADB UI helpers for documented Lumo emulator checks; no application source edits."""
from __future__ import annotations
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import time
import xml.etree.ElementTree as ET

ADB = os.environ.get('LUMO_ADB') or shutil.which('adb') or '/workspace/toolchain/android-sdk/platform-tools/adb'
QA_ROOT = Path(os.environ.get('LUMO_QA_DIR', 'android-qa-evidence'))
EVIDENCE = QA_ROOT / 'screens'
LOG = QA_ROOT / 'android-ui-actions.jsonl'
DISPLAY = QA_ROOT / 'emulator-display.json'

class Android:
    def __init__(self, serial='emulator-5554', fast_input=False):
        QA_ROOT.mkdir(parents=True, exist_ok=True)
        self.serial = serial
        self.fast_input = fast_input and serial.startswith('emulator-')

    def adb(self, *args, binary=False, timeout=90):
        started = time.time()
        result = subprocess.run([ADB, '-s', self.serial, *map(str, args)], capture_output=True,
                                text=not binary, timeout=timeout)
        record = {'time_utc': time.strftime('%Y-%m-%dT%H:%M:%SZ', time.gmtime(started)),
                  'serial': self.serial, 'arguments': list(map(str, args)),
                  'exit_code': result.returncode, 'seconds': round(time.time() - started, 2)}
        with LOG.open('a') as log:
            log.write(json.dumps(record) + '\n')
        if result.returncode:
            error = (result.stderr + result.stdout).decode(errors='replace') if binary else result.stderr + result.stdout
            raise RuntimeError(error.strip() or f'adb failed: {args!r}')
        return result.stdout

    def dump(self):
        # Flutter supplies Semantics nodes. Godot normally exposes only its native view.
        remote = f'/sdcard/lumo-qa-ui-{os.getpid()}.xml'
        for attempt in range(3):
            try:
                self.adb('shell', 'uiautomator', 'dump', remote)
                data = self.adb('shell', 'cat', remote)
                break
            except RuntimeError:
                if attempt == 2:
                    raise
                time.sleep(2)
        start = data.find('<?xml')
        if start < 0:
            start = data.find('<hierarchy')
        if start < 0:
            raise RuntimeError('No UI hierarchy returned')
        return ET.fromstring(data[start:])

    @staticmethod
    def bounds(node):
        values = list(map(int, re.findall(r'-?\d+', node.attrib.get('bounds', ''))))
        if len(values) != 4:
            raise RuntimeError(f'Invalid bounds: {node.attrib.get("bounds")}')
        left, top, right, bottom = values
        if right <= left or bottom <= top:
            raise RuntimeError('The element has empty bounds')
        return left, top, right, bottom

    def click(self, label, contains=False, index=None):
        root = self.dump()
        parents = {child: parent for parent in root.iter() for child in parent}
        def matches(node):
            values = [node.attrib.get('text', ''), node.attrib.get('content-desc', '')]
            return any(label.casefold() in value.casefold() if contains else label == value
                       for value in values if value)
        nodes = [n for n in root.iter('node') if matches(n) and n.attrib.get('enabled', 'true') == 'true']
        if not nodes:
            labels = [n.attrib.get('text') or n.attrib.get('content-desc') for n in root.iter('node')]
            raise RuntimeError(f'Label not found: {label!r}. Present: {[v for v in labels if v]}')
        if index is None and len(nodes) != 1:
            options = [{'text': n.attrib.get('text'), 'description': n.attrib.get('content-desc'),
                        'bounds': n.attrib.get('bounds')} for n in nodes]
            raise RuntimeError(f'Ambiguous label {label!r}; choose --index: {options}')
        selected = nodes[index if index is not None else 0]
        click_target = selected
        ancestor = selected
        while ancestor in parents:
            if ancestor.attrib.get('clickable') == 'true':
                click_target = ancestor
                break
            ancestor = parents[ancestor]
        l, t, r, b = self.bounds(click_target)
        self.tap((l + r) // 2, (t + b) // 2)
        return {'label': label, 'bounds': [l, t, r, b]}

    def physical_point(self, x, y):
        # event mouse uses physical display pixels. UI hierarchy uses logical override pixels.
        data = json.loads(DISPLAY.read_text()) if DISPLAY.exists() else {
            'physical': [720, 1280], 'logical': [720, 1280]}
        pw, ph = data['physical']; lw, lh = data['logical']
        return round(x * pw / lw), round(y * ph / lh)

    def tap(self, x, y, hold_ms=80):
        if not self.fast_input:
            if hold_ms > 100:
                return self.adb('shell', 'input', 'swipe', x, y, x, y, hold_ms)
            return self.adb('shell', 'input', 'tap', x, y)
        x, y = self.physical_point(x, y)
        self.adb('emu', 'event', 'mouse', x, y, 0, 1)
        try:
            time.sleep(hold_ms / 1000)
        finally:
            self.adb('emu', 'event', 'mouse', x, y, 0, 0)
        return {'physical_touch': [x, y], 'hold_ms': hold_ms}

    def key(self, android_code, linux_name):
        if not self.fast_input:
            return self.adb('shell', 'input', 'keyevent', android_code)
        return self.adb('emu', 'event', 'send', f'EV_KEY:{linux_name}:1', 'EV_SYN:0:0',
                        f'EV_KEY:{linux_name}:0', 'EV_SYN:0:0')

    def swipe(self, x1, y1, x2, y2, ms):
        if not self.fast_input:
            return self.adb('shell', 'input', 'swipe', x1, y1, x2, y2, ms)
        x1, y1 = self.physical_point(x1, y1); x2, y2 = self.physical_point(x2, y2)
        self.adb('emu', 'event', 'mouse', x1, y1, 0, 1)
        steps = max(2, min(40, ms // 30))
        try:
            for i in range(1, steps + 1):
                self.adb('emu', 'event', 'mouse', round(x1 + (x2-x1)*i/steps),
                         round(y1 + (y2-y1)*i/steps), 0, 1)
                time.sleep(ms / steps / 1000)
        finally:
            self.adb('emu', 'event', 'mouse', x2, y2, 0, 0)
        return {'physical_swipe': [x1, y1, x2, y2], 'ms': ms}

    def resize(self, size, density=None):
        result = self.adb('shell', 'wm', 'size', size)
        if density: result += self.adb('shell', 'wm', 'density', density)
        state = self.adb('shell', 'wm', 'size')
        pairs = re.findall(r'(Physical|Override) size: (\d+)x(\d+)', state)
        data = {kind.lower(): [int(w), int(h)] for kind, w, h in pairs}
        DISPLAY.write_text(json.dumps({'physical': data['physical'],
                                       'logical': data.get('override', data['physical'])}))
        return {'wm_output': result, 'display': json.loads(DISPLAY.read_text())}

    def capture(self, label):
        safe = re.sub(r'[^A-Za-z0-9_.-]+', '-', label)
        EVIDENCE.mkdir(exist_ok=True)
        files = {}
        # First await accessibility/idle, so app startup is not captured before first paint.
        try:
            root = self.dump()
            xml = EVIDENCE / f'{safe}.xml'
            ET.ElementTree(root).write(xml, encoding='utf-8', xml_declaration=True)
            files['hierarchy'] = str(xml)
        except Exception as error:
            files['hierarchy_error'] = str(error)
        png = EVIDENCE / f'{safe}.png'
        data = self.adb('exec-out', 'screencap', '-p', binary=True)
        if not data.startswith(b'\x89PNG\r\n\x1a\n'):
            raise RuntimeError('Invalid/empty screenshot returned; emulator may have disconnected')
        png.write_bytes(data)
        files['screenshot'] = str(png)
        activity = EVIDENCE / f'{safe}.activity.txt'
        activity.write_text(self.adb('shell', 'dumpsys', 'activity', 'activities'))
        files['activity'] = str(activity)
        return files

    def foreground(self, package):
        resolved = self.adb('shell', 'cmd', 'package', 'resolve-activity', '--brief',
                            '-a', 'android.intent.action.MAIN', '-c',
                            'android.intent.category.LAUNCHER', package)
        components = [line.strip() for line in resolved.splitlines() if '/' in line and ' ' not in line.strip()]
        if not components:
            raise RuntimeError(f'No launcher activity for {package}: {resolved}')
        return self.adb('shell', 'am', 'start', '-n', components[-1])

    def install(self, apk):
        path = Path(apk).resolve()
        checksum = hashlib.sha256(path.read_bytes()).hexdigest()
        # -r preserves app data. No downgrade or uninstall is attempted on signature mismatch.
        output = self.adb('install', '--no-incremental', '-r', str(path), timeout=600)
        return {'file': str(path), 'bytes': path.stat().st_size, 'sha256': checksum,
                'adb_install_output': output.strip()}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--serial', default='emulator-5554')
    parser.add_argument('--fast-input', action='store_true', help='Use emulator-console touches; faster under TCG')
    sub = parser.add_subparsers(dest='command', required=True)
    p = sub.add_parser('click'); p.add_argument('label'); p.add_argument('--contains', action='store_true'); p.add_argument('--index', type=int)
    p = sub.add_parser('capture'); p.add_argument('label')
    sub.add_parser('dump')
    sub.add_parser('back')
    sub.add_parser('background')
    p = sub.add_parser('foreground'); p.add_argument('package')
    p = sub.add_parser('tap'); p.add_argument('x', type=int); p.add_argument('y', type=int)
    p = sub.add_parser('hold'); p.add_argument('x', type=int); p.add_argument('y', type=int); p.add_argument('ms', type=int)
    p = sub.add_parser('swipe'); p.add_argument('x1', type=int); p.add_argument('y1', type=int); p.add_argument('x2', type=int); p.add_argument('y2', type=int); p.add_argument('ms', type=int, nargs='?', default=500)
    p = sub.add_parser('resize'); p.add_argument('size'); p.add_argument('density', nargs='?')
    p = sub.add_parser('install'); p.add_argument('apk')
    p = sub.add_parser('offline'); p.add_argument('mode', choices=['on', 'off'])
    p = sub.add_parser('stop'); p.add_argument('package')
    args = parser.parse_args()
    device = Android(args.serial, args.fast_input)
    if args.command == 'click': result = device.click(args.label, args.contains, args.index)
    elif args.command == 'capture': result = device.capture(args.label)
    elif args.command == 'dump':
        root = device.dump()
        result = [{key: n.attrib.get(key, '') for key in ['text', 'content-desc', 'resource-id', 'class', 'bounds', 'clickable', 'enabled']}
                  for n in root.iter('node') if n.attrib.get('text') or n.attrib.get('content-desc')]
    elif args.command == 'back': result = device.key('4', 'KEY_BACK')
    elif args.command == 'background': result = device.key('3', 'KEY_HOMEPAGE')
    elif args.command == 'foreground': result = device.foreground(args.package)
    elif args.command == 'tap': result = device.tap(args.x, args.y)
    elif args.command == 'hold': result = device.tap(args.x, args.y, args.ms)
    elif args.command == 'swipe': result = device.swipe(args.x1, args.y1, args.x2, args.y2, args.ms)
    elif args.command == 'resize':
        result = device.resize(args.size, args.density)
    elif args.command == 'install': result = device.install(args.apk)
    elif args.command == 'offline':
        value = 'disable' if args.mode == 'on' else 'enable'
        result = device.adb('shell', 'svc', 'wifi', value)
        result += device.adb('shell', 'svc', 'data', value)
    elif args.command == 'stop': result = device.adb('shell', 'am', 'force-stop', args.package)
    print(json.dumps(result, ensure_ascii=False, indent=2))

if __name__ == '__main__':
    try: main()
    except Exception as error:
        print(json.dumps({'error': str(error)}, ensure_ascii=False), file=sys.stderr)
        raise SystemExit(1)
