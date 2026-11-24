"""Bounded visual readiness for genuine Flutter Android screenshots.

Accessibility readiness and rendered pixels are independent evidence. Some
software-rendered emulator frames expose correct labels while the image is
still an unpainted navy loading surface. Never publish such frames as proof.
"""
from __future__ import annotations

import json
import math
from pathlib import Path
import time

from PIL import Image

MIN_FLUTTER_ENTROPY = 3.0


def inspect_flutter_frame(file: Path) -> dict:
    """Inspect only the central Flutter content, excluding Android system bars."""
    with Image.open(file) as source:
        source.load()
        width, height = source.size
        if source.format != 'PNG' or min(width, height) < 240:
            raise ValueError('Expected a complete Android screenshot PNG')
        content = source.convert('L').crop((
            int(width * .05), int(height * .10),
            int(width * .95), int(height * .83),
        )).resize((96, 96), Image.Resampling.BILINEAR)
        entropy = content.entropy()
        if not math.isfinite(entropy):
            raise ValueError('Non-finite Flutter screenshot entropy')
        return {
            'width': width, 'height': height,
            'content_entropy_bits': round(entropy, 3),
            'threshold_bits': MIN_FLUTTER_ENTROPY,
            'visually_ready': entropy >= MIN_FLUTTER_ENTROPY,
            'scope': 'Rendered content readiness, not an accessibility or gameplay check',
        }


def capture_when_ready(out: Path, name: str, capture,
                       *, timeout: float = 30, max_attempts: int = 12,
                       wait=time.sleep, clock=time.monotonic) -> dict:
    """Wait for a real rendered frame or fail closed with evidence.

    The caller must independently verify that expected accessibility controls
    belong to this page. Never tap, dismiss dialogs, or manipulate app data.
    """
    if Path(name).name != name or not name or '/' in name or '\\' in name:
        raise ValueError('Unsafe screenshot name')
    if not callable(capture) or not 0 < timeout <= 120 or not 1 <= max_attempts <= 30:
        raise ValueError('Invalid bounded screenshot readiness options')
    out = Path(out)
    out.mkdir(parents=True, exist_ok=True)
    started = clock()
    journal = out / (name + '-render-readiness.json')
    attempts = []
    status = 'FAIL'
    try:
        for index in range(max_attempts):
            if clock() - started >= timeout:
                break
            tag = f'{name}-render-candidate-{index + 1}'
            result = capture(out, tag)
            candidate = result.get('file')
            if not isinstance(candidate, str) or Path(candidate).name != candidate:
                raise ValueError('Screenshot capture returned unsafe file name')
            source = out / candidate
            observation = inspect_flutter_frame(source)
            attempts.append({'capture': candidate, 'sha256': result.get('sha256'),
                             **observation})
            if observation['visually_ready']:
                target = out / (name + '.png')
                if target.exists():
                    raise FileExistsError('Refusing to overwrite existing accepted evidence')
                source.rename(target)
                status = 'PASS'
                return {**result, 'file': target.name,
                        'render_readiness': observation}
            remaining = timeout - (clock() - started)
            if remaining <= 0:
                break
            wait(min(1.5, remaining))
        raise RuntimeError(
            f'Flutter {name} stayed visually unrendered after {len(attempts)} '
            f'frames; last entropy={attempts[-1]["content_entropy_bits"] if attempts else "none"}')
    finally:
        journal.write_text(json.dumps({
            'schema': 'lumo-flutter-render-readiness', 'version': 1,
            'name': name, 'status': status,
            'attempts': attempts, 'elapsed_seconds': round(clock() - started, 3)
        }, ensure_ascii=False, indent=2) + '\n')
