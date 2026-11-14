#!/usr/bin/env python3
"""Read actual old/new frames with the unchanged 86445 screenshot reader."""
import hashlib
import importlib.util
import json
from pathlib import Path
import subprocess
import sys
import time
import types

ROOT = Path(__file__).resolve().parent
HOST = ROOT.parents[1] / 'lumo-studio-final-e3d'
sys.path.insert(0, str(HOST / '.github/probes'))
# Import-only Android transport dependency; this replay never calls a device.
sys.modules.setdefault('uiautomator2', types.ModuleType('uiautomator2'))
spec = importlib.util.spec_from_file_location('original_creative', HOST / '.github/probes/creative_android_probe.py')
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
OUT = ROOT / 'evidence/title-ocr'
OUT.mkdir(parents=True, exist_ok=True)

def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

sources = {
    'original-android': ROOT.parents[0] / 'studio-final-86445f53/creative/streamed-original/selected-originals/tour/0199-native-lumossternenschatz-9.png',
    'new-landscape': ROOT / 'treasure-green-render-captures/treasure-title-landscape.png',
    'new-compact': ROOT / 'treasure-green-render-captures/treasure-title-compact.png',
    'new-fold': ROOT / 'treasure-green-render-captures/treasure-title-fold.png',
}
result = {
    'scope': 'Local unchanged reader on original pixels; not a new Android tour. Local German OCR model absent.',
    'unused_android_transport_import': 'uiautomator2 import stub; no ADB or UI transport invoked',
    'reader_sha256': digest(Path(module.__file__)),
    'tesseract_version': subprocess.check_output(['tesseract', '--version'], text=True),
    'languages': subprocess.check_output(['tesseract', '--list-langs'], text=True),
    'models': {p.name: digest(p) for p in Path('/usr/share/tesseract-ocr/5/tessdata').glob('*.traineddata')},
    'observations': [],
}
for name, source in sources.items():
    entry = {'name': name, 'source': str(source), 'source_sha256': digest(source)}
    started = time.monotonic()
    try:
        lines = module.image_lines(OUT, name, module.normalized('LUMOS STERNENSCHATZ'),
                                   source_path=source, timeout=60)
        entry['lines'] = lines
        entry['exact_title_observed'] = any(module.normalized(line['text']) == module.normalized('LUMOS STERNENSCHATZ') for line in lines)
        entry['actual_requested_phrase_observed'] = any(module.normalized('LUMOS STERNENSCHATZ') in module.normalized(line['text']) for line in lines)
    except Exception as error:
        entry['error'] = f'{type(error).__name__}: {error}'
    entry['elapsed_seconds'] = time.monotonic() - started
    entry['source_unchanged'] = digest(source) == entry['source_sha256']
    result['observations'].append(entry)
    (OUT / 'result.json').write_text(json.dumps(result, indent=2, ensure_ascii=False) + '\n')
    print(json.dumps({k: v for k, v in entry.items() if k != 'lines'}, ensure_ascii=False), flush=True)
