"""Generate native launcher resources from the existing approved Lumo avatar.

Build-only dependency: scripts/requirements-icons.txt. No AI recolouring,
background removal, production keys, source assets or app rules are changed.
Android layer contract: 108dp canvas, centered 60dp artwork (<66dp safe zone).
https://developer.android.com/develop/ui/compose/system/icon_design_adaptive
"""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
import xml.etree.ElementTree as ET

ANDROID = 'http://schemas.android.com/apk/res/android'
SOURCE = 'assets/lumo_design/fox/fox_avatar.png'
SOURCE_SHA256 = '8211f7347e8be4dc6f37acd3490bb6bc0976285cfef195a430b7480c6e53b53f'
DENSITIES = {'mdpi': 1.0, 'hdpi': 1.5, 'xhdpi': 2.0, 'xxhdpi': 3.0, 'xxxhdpi': 4.0}
BACKGROUND = (8, 27, 67, 255)


def prepare(root: Path) -> dict:
    # Lazy import lets existing Android preparation tests remain SDK-independent.
    from PIL import Image, ImageDraw, __version__

    root = root.resolve()
    source = root / SOURCE
    digest = hashlib.sha256(source.read_bytes()).hexdigest()
    if digest != SOURCE_SHA256:
        raise ValueError('Avatar changed: review the image before changing its pinned digest')
    image = Image.open(source)
    image.load()
    if image.mode != 'RGBA' or image.size != (512, 512):
        raise ValueError('Expected the reviewed transparent 512x512 RGBA avatar')
    if image.getchannel('A').getextrema() != (0, 255):
        raise ValueError('Avatar alpha contract changed; do not manufacture transparency')
    main = root / 'android/app/src/main'
    manifest = main / 'AndroidManifest.xml'
    tree = ET.parse(manifest)
    app = tree.getroot().find('application')
    if app is None:
        raise ValueError('Missing generated Android application')
    res = main / 'res'
    generated = []

    def write(relative: str, data: bytes, size: tuple | None = None) -> None:
        path = res / relative
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(data)
        entry = {'path': relative, 'bytes': len(data), 'sha256': hashlib.sha256(data).hexdigest()}
        if size:
            entry.update(width=size[0], height=size[1])
        generated.append(entry)

    def save_png(relative: str, value) -> None:
        import io
        buf = io.BytesIO()
        value.save(buf, format='PNG', optimize=False, compress_level=9)
        write(relative, buf.getvalue(), value.size)

    def foreground(canvas: int, artwork: int):
        layer = Image.new('RGBA', (canvas, canvas), (0, 0, 0, 0))
        scaled = image.resize((artwork, artwork), Image.Resampling.LANCZOS)
        layer.alpha_composite(scaled, ((canvas-artwork)//2, (canvas-artwork)//2))
        return layer

    for density, scale in DENSITIES.items():
        folder = 'mipmap-' + density
        size = round(48 * scale)
        legacy = Image.new('RGBA', (size, size), BACKGROUND)
        legacy.alpha_composite(foreground(size, round(size * .80)))
        save_png(folder + '/ic_lumo.png', legacy)
        round_icon = Image.new('RGBA', (size, size), BACKGROUND)
        round_icon.alpha_composite(foreground(size, round(size * .72)))
        mask = Image.new('L', (size*4, size*4), 0)
        ImageDraw.Draw(mask).ellipse((0, 0, size*4-1, size*4-1), fill=255)
        round_icon.putalpha(mask.resize((size, size), Image.Resampling.LANCZOS))
        save_png(folder + '/ic_lumo_round.png', round_icon)
        layer = foreground(round(108*scale), round(60*scale))
        save_png(folder + '/lumo_foreground.png', layer)
        monochrome = Image.new('RGBA', layer.size, (255, 255, 255, 0))
        monochrome.putalpha(layer.getchannel('A'))
        save_png(folder + '/lumo_monochrome.png', monochrome)

    write('values/lumo_launcher_colors.xml', b'<resources>\n'
          b'    <color name="lumo_launcher_background">#081B43</color>\n</resources>\n')
    for api in (26, 33):
        mono = '\n    <monochrome android:drawable="@mipmap/lumo_monochrome" />' if api == 33 else ''
        xml = ('<?xml version="1.0" encoding="utf-8"?>\n'
               f'<adaptive-icon xmlns:android="{ANDROID}">\n'
               '    <background android:drawable="@color/lumo_launcher_background" />\n'
               '    <foreground android:drawable="@mipmap/lumo_foreground" />'
               f'{mono}\n</adaptive-icon>\n').encode()
        for name in ('ic_lumo', 'ic_lumo_round'):
            write(f'mipmap-anydpi-v{api}/{name}.xml', xml)

    ET.register_namespace('android', ANDROID)
    ET.register_namespace('tools', 'http://schemas.android.com/tools')
    app.set(f'{{{ANDROID}}}icon', '@mipmap/ic_lumo')
    app.set(f'{{{ANDROID}}}roundIcon', '@mipmap/ic_lumo_round')
    ET.indent(tree)
    tree.write(manifest, encoding='utf-8', xml_declaration=True)
    report = {'source': SOURCE, 'source_sha256': digest, 'source_size': [512, 512],
              'pillow_version': __version__, 'canvas_dp': 108, 'artwork_dp': 60,
              'background': '#081B43', 'files': generated,
              'scope': 'Generated resources only; APK and installed launcher must be checked separately'}
    dist = root / 'dist'
    dist.mkdir(exist_ok=True)
    (dist / 'LAUNCHER-RESOURCES.json').write_text(json.dumps(report, indent=2) + '\n')
    print('[LumoLauncher] prepared 5 densities, legacy/round/adaptive/monochrome; source=' + digest)
    return report


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--root', type=Path, default=Path(__file__).resolve().parents[1])
    prepare(parser.parse_args().root)
