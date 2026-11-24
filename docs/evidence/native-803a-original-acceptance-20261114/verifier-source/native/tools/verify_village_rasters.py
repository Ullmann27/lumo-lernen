#!/usr/bin/env python3
"""Decode the four actual Village captures and bind their original PNG bytes."""
import argparse
import hashlib
from io import BytesIO
import json
from pathlib import Path
import sys

from PIL import Image


CAPTURE_DIRECTORY = 'captures/build_village_scene_regression'
EXPECTED_PNGS = {
    CAPTURE_DIRECTORY + '/village-overview-1280x720.png': (1280, 720),
    CAPTURE_DIRECTORY + '/village-chapters-412x915.png': (412, 915),
    CAPTURE_DIRECTORY + '/village-trader-2176x1812.png': (2176, 1812),
    CAPTURE_DIRECTORY + '/village-treasury-640x360.png': (640, 360),
}


def verify_fixed_rasters(root: Path, *, directory: str, expected: dict[str, tuple[int, int]],
                         label: str, manifest: str, write: bool = True) -> list[dict]:
    """Validate an internally fixed set of decoded, visible production frames."""
    capture = root / directory
    if not capture.is_dir() or capture.is_symlink():
        raise ValueError(f'Missing original {label} capture directory')
    found = {path.relative_to(root).as_posix() for path in capture.rglob('*')
             if path.suffix.lower() == '.png'}
    if found != set(expected):
        raise ValueError(f'The complete original {len(expected)}-PNG {label} directory is required')
    images = []
    for relative, dimensions in sorted(expected.items()):
        path = root / relative
        if not path.is_file() or path.is_symlink():
            raise ValueError(f'{label} capture must be an original regular PNG file: ' + relative)
        data = path.read_bytes()
        if len(data) <= 32 or data[:8] != b'\x89PNG\r\n\x1a\n' or data[12:16] != b'IHDR':
            raise ValueError(f'Invalid {label} PNG: ' + relative)
        try:
            with Image.open(BytesIO(data)) as image:
                if image.format != 'PNG' or image.size != dimensions:
                    raise ValueError(f'{label} PNG has different physical dimensions: ' + relative)
                image.verify()
            with Image.open(BytesIO(data)) as image:
                image.load()
                # Invisible RGB noise must not turn an empty transparent image
                # into apparent scene evidence. Inspect the visible pixels.
                visible = Image.alpha_composite(
                    Image.new('RGBA', image.size, (0, 0, 0, 255)),
                    image.convert('RGBA')).convert('RGB')
                if not any(low != high for low, high in visible.getextrema()):
                    raise ValueError(f'{label} PNG is empty or a uniform color: ' + relative)
        except (OSError, SyntaxError, ValueError, Image.DecompressionBombError) as error:
            raise ValueError(f'Invalid or incomplete original {label} raster: ' + relative) from error
        images.append({'path': relative, 'width': dimensions[0], 'height': dimensions[1],
                       'bytes': len(data), 'sha256': hashlib.sha256(data).hexdigest()})
    # Publish metadata only after the entire original image set passed.
    if write:
        temporary = root / ('.' + manifest + '.tmp')
        temporary.write_text(json.dumps({'images': images}, indent=2) + '\n')
        temporary.replace(root / manifest)
    return images


def verify(root: Path) -> list[dict]:
    return verify_fixed_rasters(root, directory=CAPTURE_DIRECTORY, expected=EXPECTED_PNGS,
                                label='Village', manifest='village-images.json')


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('log_dir', type=Path)
    args = parser.parse_args()
    try:
        images = verify(args.log_dir)
    except (OSError, ValueError) as error:
        print(f'[VillageRasterRoster] FAIL: {error}', file=sys.stderr)
        return 1
    print(f'[VillageRasterRoster] PASS {len(images)} actual PNG files')
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
