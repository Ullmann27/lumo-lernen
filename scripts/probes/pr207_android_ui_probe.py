#!/usr/bin/env python3
"""Run the existing APK smoke with a non-idle-blocking accessibility reader.

Test-only adapter for a disposable emulator. The original Android CLI dumper
waited for UI idle and produced no XML on the animated Flutter onboarding.
No product change, fabricated XML, hardcoded control locations or gate bypass.
Dependency installed only in the workflow's isolated venv: uiautomator2==3.7.0.
See https://github.com/openatx/uiautomator2 (Configurator/dump_hierarchy).
"""
from __future__ import annotations

import json
from pathlib import Path
import xml.etree.ElementTree as ET

import uiautomator2 as u2
import pr207_android_smoke as probe

_device = None


def live_nodes(out: Path, name: str) -> list:
    global _device
    if _device is None:
        _device = u2.connect()
        _device.jsonrpc.setConfigurator({
            'waitForIdleTimeout': 0,
            'waitForSelectorTimeout': 0,
        })
        config = _device.jsonrpc.getConfigurator()
        (out / 'uiautomator-config.json').write_text(json.dumps(config, indent=2) + '\n')
    xml = _device.dump_hierarchy(compressed=False, pretty=False)
    (out / (name + '.xml')).write_text(xml)
    hierarchy = ET.fromstring(xml)
    if hierarchy.tag != 'hierarchy':
        raise RuntimeError('Unexpected live accessibility hierarchy root')
    return list(hierarchy.iter('node'))


if __name__ == '__main__':
    # Replace the harness adapter, not any application behaviour or test gate.
    probe.ui_nodes = live_nodes
    raise SystemExit(probe.main())
