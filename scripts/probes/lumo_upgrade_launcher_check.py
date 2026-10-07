#!/usr/bin/env python3
"""Run the unchanged update assertions with one UI-automation connection.

Run37577120818 already proved the downgrade rejection, update and profile
recovery, but a second Android CLI uiautomator process failed with exit137.
The actual launcher screenshot showed Lumo. This adapter reads live XML through
our existing uiautomator2 session; it does not bypass a failed application gate.
"""
from __future__ import annotations

from pathlib import Path
import time

import lumo_upgrade_install_check as upgrade
import pr207_android_smoke as base
import pr207_android_ui_probe as ui


def inspect_launcher(out: Path) -> dict:
    base.adb('shell', 'input', 'keyevent', 'KEYCODE_HOME')
    time.sleep(2)
    base.adb('shell', 'input', 'swipe', '540', '2150', '540', '350', '400')
    time.sleep(3)
    shot = base.capture(out, '00_installed_launcher')
    nodes = ui.live_nodes(out, 'installed-launcher-live')
    for node in nodes:
        label = ' '.join((node.get('text', ''), node.get('content-desc', '')))
        if 'Lumo Lernen Neu' in label:
            return {'capture': shot, 'icon_found': True, 'label': label.strip(),
                    'bounds': node.get('bounds'),
                    'reader': 'existing live uiautomator2 connection'}
    return {'capture': shot, 'icon_found': False,
            'reader': 'existing live uiautomator2 connection'}


if __name__ == '__main__':
    base.inspect_installed_icon = inspect_launcher
    raise SystemExit(upgrade.main())
