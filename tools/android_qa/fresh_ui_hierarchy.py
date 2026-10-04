"""Fresh read-only Android UI observations; never reuse a failed dump's XML.

AOSP DumpCommand returns without writing on null roots / idle timeouts, but
its Java launcher can still exit successfully. Every attempt therefore gets
an exclusive remote filename and requires both its completion marker and a
well-formed nonempty hierarchy. A retry sends no tap, swipe or app command.
"""
from __future__ import annotations

import hashlib
import json
from pathlib import Path
import re
import subprocess
import time
from typing import Callable
import uuid
import xml.etree.ElementTree as ET


def read_fresh_hierarchy(adb: Callable, out: Path, *, attempts: int = 3) -> ET.Element:
    if not 1 <= attempts <= 5:
        raise ValueError('UI observation attempts must be between one and five')
    out.mkdir(parents=True, exist_ok=True)
    last_error: Exception | None = None
    for attempt in range(1, attempts + 1):
        remote = f'/sdcard/lumo-ui-{uuid.uuid4().hex}.xml'
        record = {'attempt': attempt, 'remote': remote,
                  'time_utc': time.strftime('%Y-%m-%dT%H:%M:%SZ', time.gmtime()),
                  'fresh': False, 'compressed': True}
        root = None
        try:
            # Removing before creation additionally fails closed if a caller
            # supplies a deterministic UUID source for a regression replay.
            adb('shell', 'rm', '-f', remote, timeout=10)
            output = adb('shell', 'uiautomator', 'dump', '--compressed', remote,
                         timeout=20)
            record['command_stdout'] = output
            marker = re.compile(r'UI (?:hierchary|hierarchy) dumped to:\s*'
                                + re.escape(remote))
            if not any(marker.fullmatch(line.strip()) for line in output.splitlines()):
                raise RuntimeError('UIAutomator did not confirm a fresh dump for this request')
            data = adb('shell', 'cat', remote, timeout=10)
            start = data.find('<?xml')
            if start < 0:
                start = data.find('<hierarchy')
            if start < 0:
                raise RuntimeError('Fresh dump did not contain a UI hierarchy')
            root = ET.fromstring(data[start:])
            if root.tag != 'hierarchy' or root.find('node') is None:
                raise RuntimeError('Fresh dump did not contain an Android root node')
            record['xml_sha256'] = hashlib.sha256(data[start:].encode('utf-8')).hexdigest()
            record['fresh'] = True
        except (RuntimeError, subprocess.TimeoutExpired, ET.ParseError) as error:
            last_error = error
            record['error'] = str(error)
            root = None
        finally:
            try:
                adb('shell', 'rm', '-f', remote, timeout=10)
            except (RuntimeError, subprocess.TimeoutExpired) as error:
                record['cleanup_error'] = str(error)
                # Device loss during cleanup must not turn into a success.
                if root is not None:
                    last_error = error
                    record['fresh'] = False
                    root = None
            with (out/'ui-dump-observations.jsonl').open('a', encoding='utf-8') as log:
                log.write(json.dumps(record, ensure_ascii=False)+'\n')
        if root is not None:
            return root
        if attempt < attempts:
            time.sleep(.5)
    raise RuntimeError(f'No fresh Android UI hierarchy after {attempts} attempts: '
                       f'{last_error}') from last_error
