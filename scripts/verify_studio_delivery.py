#!/usr/bin/env python3
"""Bind Studio 2019 publication to its exact APK, Android and renderer evidence.

The historical 2018 verifier and receipts remain immutable. This verifier does
not approve images: it validates an explicitly recorded review against the
downloaded original artifact, including all independent capture source stamps.
"""
from __future__ import annotations

import argparse
from dataclasses import dataclass
from datetime import datetime
import hashlib
from io import BytesIO
import json
import math
from pathlib import Path, PurePosixPath
import re
import stat
import struct
from types import MappingProxyType
from typing import Mapping
import zipfile

from release_pipeline_gates import (EXPECTED_CERT_SHA256, PACKAGE_ID,
                                    parse_pubspec_version, sha256_file)
from verify_legacy_release_pin import verify as verify_pin
from verify_nextgen_delivery import (BASELINE_NATIVE, BASELINE_SOURCE,
                                    CARDS_FACE_STAGES, COMPILED_CLASSES,
                                    read_json, require, verify_cards_front_faces)


VERSION_CODE = 2019
VERSION_NAME = '0.13.7'
NATIVE_ARTIFACT = 'lumo-studio-2019-native-evidence'
NATIVE_WORKFLOW = '.github/workflows/lumo-studio-2019.yml'
NATIVE_JOBS = frozenset({'gameplay', 'new-worlds', 'studio', 'learning-preview',
                         'touch-workshop', 'touch-treasure', 'touch-build', 'bundle-evidence'})
REVIEW_MODULES = frozenset({'learning', 'jump', 'build', 'settlement', 'garage',
                            'cards', 'rhythm', 'puzzle', 'treasure'})
REVIEW_DIRECTORY = PurePosixPath('docs/evidence/studio-2019-reviewed')
REVIEW_RECEIPT = 'config/studio-2019-visual-review.json'
CAPTURE_SOURCES = ('nextgen-evidence/nextgen', 'studio-evidence',
                   'touch-evidence/workshop', 'touch-evidence/treasure', 'touch-evidence/build')
TOUCH_CAPTURE_PROBES = frozenset({
    'touch-evidence/workshop/captures/kart_workshop_density_regression',
    'touch-evidence/treasure/captures/treasure_density_regression',
    'touch-evidence/build/captures/build_dialog_density_regression',
})
PUZZLE_MENU_CAPTURE_PROBE = 'studio-evidence/captures/puzzle_menu_lifecycle_regression'
CARDS_SAFE_AREA_CAPTURE_PROBE = 'studio-evidence/captures/cards_safe_area_regression'
MOBILE_SAFE_AREA_CAPTURE_MODULES = MappingProxyType({
    f'studio-evidence/captures/mobile_safe_area_regression/{module}-landscape-cutout.png': module
    for module in ('jump', 'build', 'puzzle', 'treasure')
})
# Pose-studio images are useful technical evidence, but cannot stand in for an
# actual production scene. The probe directory fixes the image's module.
CAPTURE_MODULES = {
    'nextgen-evidence/nextgen/captures/learning_world_capture': 'learning',
    'studio-evidence/captures/learning_sharing_capture': 'learning',
    'nextgen-evidence/nextgen/captures/jump_nextgen_capture': 'jump',
    'nextgen-evidence/nextgen/captures/build_nextgen_play_regression': 'build',
    'nextgen-evidence/nextgen/captures/build_settlement_play_regression': 'settlement',
    'nextgen-evidence/nextgen/captures/kart_nextgen_garage_regression': 'garage',
    'nextgen-evidence/nextgen/captures/cards_table_capture': 'cards',
    CARDS_SAFE_AREA_CAPTURE_PROBE: 'cards',
    'nextgen-evidence/nextgen/captures/rhythm_tour_play_regression': 'rhythm',
    'studio-evidence/captures/puzzle_rotation_regression': 'puzzle',
    PUZZLE_MENU_CAPTURE_PROBE: 'puzzle',
    'studio-evidence/captures/treasure_exploration_regression': 'treasure',
    'touch-evidence/workshop/captures/kart_workshop_density_regression': 'garage',
    'touch-evidence/treasure/captures/treasure_density_regression': 'treasure',
    'touch-evidence/build/captures/build_dialog_density_regression': 'build',
}

# These are two concrete producer layouts, never caller-supplied acceptance
# rules. The Studio default follows the published producer contract.
NEXTGEN_PREFIX = 'nextgen-evidence/nextgen'
NEXTGEN_VILLAGE_CAPTURE = NEXTGEN_PREFIX + '/captures/build_village_scene_regression'
NEXTGEN_PUZZLE_MENU_CAPTURE = NEXTGEN_PREFIX + '/captures/puzzle_menu_lifecycle_regression'
NEXTGEN_CARDS_SAFE_AREA_CAPTURE = NEXTGEN_PREFIX + '/captures/cards_safe_area_regression'
NEXTGEN_MOBILE_SAFE_AREA_CAPTURE = NEXTGEN_PREFIX + '/captures/mobile_safe_area_regression'
NEXTGEN_SAFE_AREA_PNGS = MappingProxyType({
    'captures/cards_safe_area_regression/android35_portrait-playing.png': (1080, 2400),
    'captures/cards_safe_area_regression/android35_portrait-paused.png': (1080, 2400),
    'captures/cards_safe_area_regression/landscape_cutout_fixture-playing.png': (2400, 1080),
    **{f'captures/mobile_safe_area_regression/{module}-landscape-cutout.png': (2400, 1080)
       for module in ('jump', 'build', 'puzzle', 'treasure')},
})
NEXTGEN_SAFE_AREA_CAPTURE_IMAGES = MappingProxyType({
    NEXTGEN_PREFIX + '/' + path: (
        'cards' if '/cards_safe_area_regression/' in path else PurePosixPath(path).name.split('-')[0])
    for path in NEXTGEN_SAFE_AREA_PNGS
})
NEXTGEN_SAFE_AREA_PROBES = frozenset({
    ('cards_safe_area_android_contract', 'headless'),
    ('cards_safe_area_regression', 'headless'),
    ('mobile_safe_area_regression', 'headless'),
    ('cards_safe_area_regression', 'rendered'),
    ('mobile_safe_area_regression', 'rendered'),
})
NEXTGEN_CAPTURE_MODULES = MappingProxyType({
    **{NEXTGEN_PREFIX + '/captures/' + probe: module for probe, module in (
        ('learning_world_capture', 'learning'), ('learning_sharing_capture', 'learning'),
        ('jump_nextgen_capture', 'jump'), ('build_nextgen_play_regression', 'build'),
        ('build_settlement_play_regression', 'settlement'),
        ('build_village_scene_regression', 'settlement'),
        ('kart_nextgen_garage_regression', 'garage'), ('cards_table_capture', 'cards'),
        ('rhythm_tour_play_regression', 'rhythm'), ('puzzle_rotation_regression', 'puzzle'),
        ('puzzle_menu_lifecycle_regression', 'puzzle'),
        ('treasure_exploration_regression', 'treasure'),
    )},
    **{probe: CAPTURE_MODULES[probe] for probe in TOUCH_CAPTURE_PROBES},
})
NEXTGEN_REQUIRED_PROBES = NEXTGEN_SAFE_AREA_PROBES | frozenset(
    (probe, 'headless') for probe in (
        'learning_world_regression', 'learning_sharing_regression', 'learning_studio_regression',
        'learning_host_payload_regression', 'puzzle_rotation_regression',
        'puzzle_menu_lifecycle_regression',
        'treasure_exploration_regression', 'jump_nextgen_regression', 'jump_expeditions_regression',
        'lumo_teacher_pose_regression', 'lumo_studio_motion_regression', 'lumo_65bone_walk_gait_regression',
        'lumo_original_jump_visual_regression', 'bauwelt_identity_2013_regression',
        'build_frontier_regression', 'build_transform_regression', 'build_nextgen_play_regression',
        'build_settlement_regression', 'build_settlement_play_regression',
        'build_village_economy_regression', 'build_village_art_regression',
        'build_village_scene_regression',
        'creative_nextgen_environment_regression', 'kart_nextgen_garage_regression',
        'kart_track_pass_regression', 'cards_table_regression', 'rhythm_tour_regression',
        'rhythm_tour_play_regression',
    )
) | frozenset(
    (probe, 'rendered') for probe in (
        'learning_world_capture', 'learning_sharing_capture', 'lumo_studio_motion_capture',
        'puzzle_rotation_regression', 'treasure_exploration_regression', 'jump_nextgen_capture',
        'puzzle_menu_lifecycle_regression',
        'build_nextgen_play_regression', 'build_settlement_play_regression',
        'build_village_scene_regression',
        'creative_nextgen_environment_regression', 'kart_nextgen_garage_regression',
        'cards_table_capture', 'rhythm_tour_play_regression', 'kart_player_full_route_regression',
    )
)
# The eight pose-studio frames are required archive evidence, but are never
# allowed to substitute for a reviewed production scene in CAPTURE_MODULES.
NEXTGEN_STUDIO_PNGS = frozenset(
    f'captures/learning_sharing_capture/{state}-{size}.png'
    for state in ('sharing-start', 'sharing-first-round', 'sharing-complete')
    for size in ('1280x720', '412x915')
) | frozenset(
    f'captures/lumo_studio_motion_capture/{variant}_{sample}.png'
    for variant in ('before', 'after') for sample in ('walk', 'sprint', 'jump_rise', 'land')
) | frozenset(
    f'captures/puzzle_rotation_regression/puzzle_rotation_{view}.png'
    for view in ('table', 'hint', 'placed', '640x360', '412x915', '840x760', 'compact_menu')
) | frozenset(
    f'captures/treasure_exploration_regression/treasure_{view}.png'
    for view in ('choose_route', 'garden_first', 'route_complete')
)

# Village is a separately inspected production scene within the settlement
# module family. Its four original captures supplement the unchanged Studio set.
NEXTGEN_VILLAGE_PNGS = MappingProxyType({
    'captures/build_village_scene_regression/village-overview-1280x720.png': (1280, 720),
    'captures/build_village_scene_regression/village-chapters-412x915.png': (412, 915),
    'captures/build_village_scene_regression/village-trader-2176x1812.png': (2176, 1812),
    'captures/build_village_scene_regression/village-treasury-640x360.png': (640, 360),
})
NEXTGEN_PUZZLE_MENU_PNGS = MappingProxyType({
    f'captures/puzzle_menu_lifecycle_regression/{width}x{height}-{stage}.png': (width, height)
    for width, height in ((960, 540), (640, 360))
    for stage in ('rotation-menu', 'rotation-play', 'classic-play')
})

# The independent density captures were published in native 24fb8580. Their
# paths and physical dimensions come from the three production input probes;
# they supplement, and never replace, the fixed core and its 24 Studio rasters.
NEXTGEN_TOUCH_PROBES = MappingProxyType({
    'touch-evidence/workshop': 'kart_workshop_density_regression',
    'touch-evidence/treasure': 'treasure_density_regression',
    'touch-evidence/build': 'build_dialog_density_regression',
})
NEXTGEN_TOUCH_PNGS = MappingProxyType({
    'touch-evidence/workshop': MappingProxyType({
        f'captures/kart_workshop_density_regression/workshop-{width}x{height}-{view}.png': (width, height)
        for width, height in ((2400, 1080), (1080, 2400))
        for view in ('performance', 'paint-purchase', 'refund')
    }),
    'touch-evidence/treasure': MappingProxyType({
        **{f'captures/treasure_density_regression/treasure-{width}x{height}-{view}.png': (width, height)
           for width, height in ((2400, 1080), (1080, 2400), (640, 320))
           for view in ('play', 'question', 'complete', 'inventory')},
        **{f'captures/treasure_density_regression/treasure-2176x1812-{view}.png': (2176, 1812)
           for view in ('play', 'complete')},
    }),
    'touch-evidence/build': MappingProxyType({
        f'captures/build_dialog_density_regression/build-dialog-{width}x{height}-{view}.png': (width, height)
        for width, height in ((2400, 1080), (1080, 2400), (2176, 1812), (640, 360))
        for view in ('templates-top', 'templates-bottom', 'current-goal')
    }),
})


@dataclass(frozen=True)
class _NativeReviewProfile:
    artifact: str
    workflow: str
    jobs: frozenset[str]
    sources: tuple[str, ...]
    capture_modules: Mapping[str, str]
    directory: PurePosixPath
    receipt: str


NATIVE_PROFILES = MappingProxyType({
    'studio-2019': _NativeReviewProfile(NATIVE_ARTIFACT, NATIVE_WORKFLOW, NATIVE_JOBS,
        CAPTURE_SOURCES, MappingProxyType(CAPTURE_MODULES), REVIEW_DIRECTORY, REVIEW_RECEIPT),
    'nextgen-2019': _NativeReviewProfile('lumo-nextgen-2018-native-evidence',
        '.github/workflows/lumo-nextgen-2018.yml',
        frozenset({'gameplay', 'new-worlds', 'learning-preview', 'touch-workshop',
                   'touch-treasure', 'touch-build', 'bundle-evidence'}),
        (NEXTGEN_PREFIX, *NEXTGEN_TOUCH_PROBES),
        NEXTGEN_CAPTURE_MODULES, PurePosixPath('docs/evidence/nextgen-2019-reviewed'),
        'config/nextgen-2019-visual-review.json'),
})


def native_review_profile(name: str) -> _NativeReviewProfile:
    require(isinstance(name, str) and name in NATIVE_PROFILES, 'Unknown fixed native review profile')
    return NATIVE_PROFILES[name]


def verify_native_acceptance(native: str, artifact: dict, workflow: dict, jobs: dict,
                             *, native_profile: str = 'studio-2019') -> None:
    profile = native_review_profile(native_profile)
    require(bool(re.fullmatch(r'[a-f0-9]{40}', str(native))), 'Invalid reviewed native SHA')
    require(artifact.get('name') == profile.artifact and artifact.get('expired') is False,
            'Current Studio native visual evidence is missing or expired')
    require(type(artifact.get('id')) is int and artifact['id'] > 0, 'Invalid native artifact identity')
    run_id = workflow.get('id')
    require(type(run_id) is int and run_id > 0 and
            artifact.get('workflow_run', {}).get('id') == run_id and
            artifact['workflow_run'].get('head_sha') == native,
            'Native artifact was rendered from another source or workflow run')
    require(workflow.get('path') == profile.workflow and workflow.get('head_sha') == native and
            workflow.get('status') == 'completed' and workflow.get('conclusion') == 'success',
            'Current Studio native workflow did not succeed at the exact pin')
    actual_jobs = jobs.get('jobs')
    require(isinstance(actual_jobs, list) and all(isinstance(job, dict) for job in actual_jobs),
            'Missing native acceptance job metadata')
    for name in sorted(profile.jobs):
        matching = [job for job in actual_jobs if job.get('name') == name]
        require(len(matching) == 1, 'Missing or ambiguous full native acceptance job: ' + name)
        job = matching[0]
        require(job.get('run_id') == run_id and job.get('head_sha') == native and
                job.get('status') == 'completed' and job.get('conclusion') == 'success',
                'Native acceptance job did not succeed at the exact pin: ' + name)


def archive_member(zipped: zipfile.ZipFile, name: str) -> bytes:
    matching = [entry for entry in zipped.infolist() if entry.filename == name]
    require(len(matching) == 1, 'Missing or duplicate original native archive member: ' + name)
    entry = matching[0]
    require(not entry.is_dir() and not stat.S_ISLNK(entry.external_attr >> 16),
            'Native archive evidence must be an original regular file: ' + name)
    try:
        return zipped.read(entry)
    except (OSError, RuntimeError, zipfile.BadZipFile) as error:
        raise ValueError('Cannot read original native archive member: ' + name) from error


def verify_archive_sources(zipped: zipfile.ZipFile, native: str,
                           *, native_profile: str = 'studio-2019') -> dict:
    profile = native_review_profile(native_profile)
    sources = {}
    for prefix in profile.sources:
        try:
            source = archive_member(zipped, prefix + '/source-sha.txt').decode('utf-8').strip()
            dirty = archive_member(zipped, prefix + '/source-dirty.txt').decode('utf-8').strip()
        except UnicodeDecodeError as error:
            raise ValueError('Invalid native capture source metadata: ' + prefix) from error
        require(source == native, 'Archive capture source differs from the current native pin: ' + prefix)
        require(not dirty, 'Native screenshots were captured from modified tracked source: ' + prefix)
        sources[prefix] = source
    return sources


def capture_module(entry: str, *, native_profile: str = 'studio-2019') -> str:
    profile = native_review_profile(native_profile)
    require(isinstance(entry, str) and '\\' not in entry, 'Invalid original artifact image path')
    path = PurePosixPath(entry)
    require(not path.is_absolute() and '..' not in path.parts and str(path) == entry and
            bool(re.fullmatch(r'[A-Za-z0-9][A-Za-z0-9._-]*\.png', path.name)),
            'Only original current production-scene PNGs may be reviewed')
    image_modules = (NEXTGEN_SAFE_AREA_CAPTURE_IMAGES if native_profile == 'nextgen-2019'
                     else MOBILE_SAFE_AREA_CAPTURE_MODULES)
    module = image_modules.get(entry)
    if module is None:
        module = profile.capture_modules.get(str(path.parent))
    require(module in REVIEW_MODULES, 'Unknown production capture; a pose studio is not a product module')
    return module


def png_dimensions(data: bytes) -> list[int]:
    require(len(data) > 32 and data[:8] == b'\x89PNG\r\n\x1a\n' and data[12:16] == b'IHDR',
            'Selected image is not an original PNG')
    width, height = struct.unpack('>II', data[16:24])
    require(width >= 320 and height >= 320, 'Reviewed PNG is too small for production review')
    # Header-shaped or truncated files must not satisfy a screenshot gate. The
    # publisher already installs Pillow for the unchanged Android Cards check.
    from PIL import Image
    try:
        with Image.open(BytesIO(data)) as image:
            require(image.format == 'PNG' and image.size == (width, height), 'Invalid PNG dimensions')
            image.verify()
        with Image.open(BytesIO(data)) as image:
            image.load()
    except (OSError, SyntaxError, ValueError, Image.DecompressionBombError) as error:
        raise ValueError('Reviewed original PNG is corrupt or incomplete') from error
    return [width, height]


def reviewed_relative_path(digest: str, module: str, entry: str,
                           *, native_profile: str = 'studio-2019') -> str:
    profile = native_review_profile(native_profile)
    require(bool(re.fullmatch(r'[a-f0-9]{64}', str(digest))), 'Invalid reviewed image SHA-256')
    require(capture_module(entry, native_profile=native_profile) == module,
            'Reviewed module differs from its actual production capture')
    return str(profile.directory / f'{digest}-{module}-{PurePosixPath(entry).name}')


def reviewed_file(root: Path, relative: str, *, native_profile: str = 'studio-2019') -> Path:
    profile = native_review_profile(native_profile)
    parts = PurePosixPath(relative).parts
    require(parts[:3] == profile.directory.parts and len(parts) == 4 and '\\' not in relative,
            'Reviewed image must be a content-addressed committed Studio PNG')
    path = root
    for component in parts:
        path = path / component
        require(not path.is_symlink(), 'Reviewed PNG path must not contain symlinks')
    return path


def verify_nextgen_archive(zipped: zipfile.ZipFile, workflow: dict) -> dict:
    """Check the fixed combined runner's original results and complete raster roster."""
    try:
        tree = archive_member(zipped, NEXTGEN_PREFIX + '/source-tree.txt').decode('utf-8').strip()
        engine = archive_member(zipped, NEXTGEN_PREFIX + '/engine.txt').decode('utf-8').strip()
        rows = [line.split('\t') for line in archive_member(
            zipped, NEXTGEN_PREFIX + '/results.tsv').decode('utf-8').splitlines()]
        roster = json.loads(archive_member(zipped, NEXTGEN_PREFIX + '/renderer-images.json'))
    except (UnicodeDecodeError, json.JSONDecodeError) as error:
        raise ValueError('Invalid original Nextgen runner metadata') from error
    head_commit = workflow.get('head_commit')
    require(bool(re.fullmatch(r'[a-f0-9]{40}', tree)) and isinstance(head_commit, dict) and
            head_commit.get('tree_id') == tree, 'Native capture tree differs from its exact workflow source')
    require(engine.startswith('4.6.3.stable.'), 'Unexpected native capture engine')
    require(bool(rows) and rows[0] == ['probe', 'mode', 'result'] and
            all(len(row) == 3 and row[2] == 'PASS' for row in rows[1:]),
            'Every original Nextgen probe must report PASS')
    observed = [(row[0], row[1]) for row in rows[1:]]
    require(len(observed) == len(set(observed)) and set(observed) == NEXTGEN_REQUIRED_PROBES,
            'The complete original 48-probe Nextgen result is required')
    images = roster.get('images') if isinstance(roster, dict) else None
    require(isinstance(images, list) and len(images) == len(NEXTGEN_STUDIO_PNGS),
            'The complete original 24-PNG Studio roster is required')
    seen = set()
    for item in images:
        require(isinstance(item, dict), 'Invalid original Studio raster metadata')
        relative = item.get('path')
        require(isinstance(relative, str) and relative in NEXTGEN_STUDIO_PNGS and relative not in seen,
                'Missing, duplicate or unexpected original Studio raster path')
        seen.add(relative)
        data = archive_member(zipped, NEXTGEN_PREFIX + '/' + relative)
        require(type(item.get('bytes')) is int and len(data) == item['bytes'] and
                hashlib.sha256(data).hexdigest() == item.get('sha256'),
                'Original Studio raster digest or byte count differs')
        dimensions = png_dimensions(data)
        require(all(type(item.get(key)) is int for key in ('width', 'height')) and
                dimensions == [item['width'], item['height']] and min(dimensions) >= 360,
                'Original Studio raster dimensions differ')
    require(seen == NEXTGEN_STUDIO_PNGS, 'The complete original 24-PNG Studio roster is required')
    return {'native_capture_tree': tree, 'native_probe_count': len(observed),
            'native_studio_raster_count': len(seen), **verify_nextgen_village_archive(zipped),
            **verify_nextgen_puzzle_menu_archive(zipped),
            **verify_nextgen_safe_area_archive(zipped),
            **verify_nextgen_touch_archive(zipped, tree)}


def verify_fixed_scene_rasters(zipped: zipfile.ZipFile, *, capture: str, manifest: str,
                              expected: Mapping[str, tuple[int, int]], label: str) -> int:
    """Verify a fixed production capture set, including decoded visible pixels."""
    try:
        roster = json.loads(archive_member(zipped, NEXTGEN_PREFIX + '/' + manifest))
    except (UnicodeDecodeError, json.JSONDecodeError) as error:
        raise ValueError(f'Invalid original {label} raster metadata') from error
    images = roster.get('images') if isinstance(roster, dict) else None
    require(isinstance(images, list) and len(images) == len(expected),
            f'The complete original {len(expected)}-PNG {label} roster is required')
    originals = [item.filename for item in zipped.infolist()
                 if item.filename.startswith(capture + '/') and
                 PurePosixPath(item.filename).suffix.lower() == '.png']
    require(len(originals) == len(set(originals)) and
            set(originals) == {NEXTGEN_PREFIX + '/' + path for path in expected},
            f'The complete original {len(expected)}-PNG {label} capture directory is required')
    seen = set()
    from PIL import Image
    for item in images:
        require(isinstance(item, dict), f'Invalid original {label} raster entry')
        relative = item.get('path')
        require(isinstance(relative, str) and relative in expected and relative not in seen,
                f'Missing, duplicate or unexpected original {label} raster path')
        seen.add(relative)
        data = archive_member(zipped, NEXTGEN_PREFIX + '/' + relative)
        require(type(item.get('bytes')) is int and len(data) == item['bytes'] and
                hashlib.sha256(data).hexdigest() == item.get('sha256'),
                f'Original {label} raster digest or byte count differs')
        size = expected[relative]
        require(data[16:24] == struct.pack('>II', *size),
                f'Original {label} raster dimensions differ from the production probe')
        dimensions = png_dimensions(data)
        require(all(type(item.get(key)) is int for key in ('width', 'height')) and
                dimensions == [item['width'], item['height']] == list(size),
                f'Original {label} raster dimensions differ from the production probe')
        with Image.open(BytesIO(data)) as image:
            image.load()
            visible = Image.alpha_composite(
                Image.new('RGBA', image.size, (0, 0, 0, 255)),
                image.convert('RGBA')).convert('RGB')
            require(any(low != high for low, high in visible.getextrema()),
                    f'Original {label} PNG is empty or a uniform color')
    require(seen == set(expected),
            f'The complete original {len(expected)}-PNG {label} roster is required')
    return len(seen)


def verify_nextgen_village_archive(zipped: zipfile.ZipFile) -> dict:
    count = verify_fixed_scene_rasters(
        zipped, capture=NEXTGEN_VILLAGE_CAPTURE, manifest='village-images.json',
        expected=NEXTGEN_VILLAGE_PNGS, label='Village')
    return {'native_village_raster_count': count}


def verify_nextgen_puzzle_menu_archive(zipped: zipfile.ZipFile) -> dict:
    count = verify_fixed_scene_rasters(
        zipped, capture=NEXTGEN_PUZZLE_MENU_CAPTURE, manifest='puzzle-menu-images.json',
        expected=NEXTGEN_PUZZLE_MENU_PNGS, label='Puzzle menu')
    return {'native_puzzle_menu_raster_count': count}


def _safe_area_numbers(value: object, length: int, label: str) -> list:
    require(isinstance(value, list) and len(value) == length and
            all(type(number) in (int, float) and math.isfinite(number) for number in value),
            'Invalid safe-area geometry: ' + label)
    return value


def _safe_area_rect(value: object, bounds: list, label: str, tolerance: float = 0.51) -> list:
    rect = _safe_area_numbers(value, 4, label)
    x, y, width, height = rect
    sx, sy, sw, sh = bounds
    require(width > 0 and height > 0 and x >= sx - tolerance and y >= sy - tolerance and
            x + width <= sx + sw + tolerance and y + height <= sy + sh + tolerance,
            'Safe-area target leaves its actual fixture bounds: ' + label)
    return rect


def _safe_area_bound_json(zipped: zipfile.ZipFile, descriptor: object,
                         path: str, *, limit: int) -> dict:
    require(isinstance(descriptor, dict) and descriptor.get('path') == path,
            'Safe-area original metadata names another archive member')
    data = archive_member(zipped, NEXTGEN_PREFIX + '/' + path)
    require(0 < len(data) <= limit and type(descriptor.get('bytes')) is int and
            descriptor['bytes'] == len(data) and
            descriptor.get('sha256') == hashlib.sha256(data).hexdigest(),
            'Safe-area original JSON digest or byte count differs')
    try:
        result = json.loads(data)
    except (UnicodeDecodeError, json.JSONDecodeError) as error:
        raise ValueError('Invalid original safe-area JSON: ' + path) from error
    require(isinstance(result, dict), 'Safe-area original JSON must be an object')
    return result


def _safe_area_layout(layout: dict, size: tuple[int, int], *, paused: bool,
                      report_roundtrip: bool = False) -> None:
    # The primary sidecar preserves Godot's explicitly written integer fields.
    # The independent report parses that JSON in Godot and serializes it again,
    # which records those same integral values as floats. Limit that conversion
    # to this secondary report; fractions, booleans and nonfinite values fail.
    integer_types = (int, float) if report_roundtrip else (int,)

    def integer(value: object, minimum: int) -> bool:
        return (type(value) in integer_types and math.isfinite(value) and
                value >= minimum and int(value) == value)

    require(integer(layout.get('schema'), 1) and layout['schema'] == 1 and
            layout.get('settled') is True and layout.get('ui_visible') is True and
            integer(layout.get('pending'), 0) and layout['pending'] == 0 and
            layout.get('observation_source') == 'fixture' and layout.get('paused') is paused,
            'Cards renderer layout must be settled, visible and explicitly a fixture')
    require(_safe_area_numbers(layout.get('window_px'), 2, 'Cards window') == list(size) and
            integer(layout.get('layout_sequence'), 1) and
            all(isinstance(layout.get(key), str) and bool(layout[key]) for key in ('token', 'roundId')),
            'Cards renderer layout does not identify its actual window and settled state')
    _safe_area_rect(layout.get('ui_rect'), [0, 0, *size], 'Cards UI')
    hand, discard = layout.get('hand'), layout.get('discard')
    require(isinstance(hand, list) and bool(hand) and isinstance(discard, dict) and bool(discard),
            'Cards renderer layout must retain its hand and discard projections')
    seen = set()
    for card in [*hand, discard]:
        require(isinstance(card, dict) and isinstance(card.get('id'), str) and bool(card['id']),
                'Cards renderer layout has an invalid original face identity')
        require(card['id'] not in seen, 'Cards renderer layout repeats an original face identity')
        seen.add(card['id'])
        quad = card.get('quad')
        require(isinstance(quad, list) and len(quad) == 4, 'Cards renderer face projection is incomplete')
        for point in quad:
            x, y = _safe_area_numbers(point, 2, 'Cards face corner')
            require(-1 <= x <= size[0] + 1 and -1 <= y <= size[1] + 1,
                    'Cards renderer face projection leaves the captured window')
        area = abs(sum(quad[i][0] * quad[(i + 1) % 4][1] -
                       quad[(i + 1) % 4][0] * quad[i][1] for i in range(4))) / 2
        require(area > 1, 'Cards renderer face projection has no visible area')


def _verify_safe_area_reports(cards: dict, mobile: dict, images: dict[str, dict]) -> None:
    """Retain the producer's fixture scope and recompute its geometric claims."""
    for report in (cards, mobile):
        require(type(report.get('checks')) is int and report['checks'] > 0 and report.get('failures') == [],
                'The original safe-area renderer report contains failures or no checks')
    require(cards.get('android_device_measurement') is False and
            isinstance(cards.get('renderer'), str) and cards['renderer'] not in ('', 'headless') and
            isinstance(cards.get('fixture_scope'), str) and bool(cards['fixture_scope']),
            'Cards renderer fixtures must not be relabelled as Android device measurements')
    profiles = {
        'android35_portrait': ((1080, 2400), 2.625, [0, 136, 1080, 2201]),
        'android35_portrait_earlier_inset': ((1080, 2400), 2.625, [0, 145, 1080, 2192]),
        'landscape_cutout_fixture': ((2400, 1080), 2.625, [136, 63, 2264, 954]),
        'short_landscape_fixture': ((640, 360), 1.0, [0, 32, 640, 304]),
        'desktop_without_insets': ((1280, 720), 1.0, [0, 0, 1280, 720]),
    }
    observed = cards.get('images')
    require(isinstance(observed, list) and len(observed) == 3, 'All three original Cards captures are required')
    seen = set()
    for item in observed:
        require(isinstance(item, dict) and isinstance(item.get('path'), str), 'Invalid Cards capture report entry')
        relative = 'captures/cards_safe_area_regression/' + PurePosixPath(item['path']).name
        require(relative in NEXTGEN_SAFE_AREA_PNGS and relative not in seen and
                item.get('size') == list(NEXTGEN_SAFE_AREA_PNGS[relative]),
                'Original Cards report names missing, duplicate or differently sized captures')
        seen.add(relative)
        profile = PurePosixPath(relative).name.rsplit('-', 1)[0]
        require(item.get('profile') == profile and item.get('safe_rect_px') == profiles[profile][2],
                'Original Cards capture has another inset fixture')
    targets = cards.get('targets')
    require(isinstance(targets, list) and bool(targets), 'Missing original Cards safe-area targets')
    target_profiles = set()
    for item in targets:
        require(isinstance(item, dict) and item.get('profile') in profiles, 'Unknown Cards target fixture')
        profile = item['profile']
        target_profiles.add(profile)
        _, density, bounds = profiles[profile]
        require(item.get('safe_rect_px') == bounds, 'Cards target reports another safe rectangle')
        rect = _safe_area_rect(item.get('rect_px'), bounds, 'Cards target')
        dp = _safe_area_numbers(item.get('dp'), 2, 'Cards target dp')
        require(min(dp) >= 47.99 and all(abs(dp[i] - rect[i + 2] / density) < 0.001 for i in range(2)),
                'Cards target does not preserve the original 48-dp fixture geometry')
    require(target_profiles == set(profiles), 'All five original Cards inset profiles are required')
    projections = cards.get('projected_views')
    require(isinstance(projections, list) and len(projections) == len(profiles),
            'All five original Cards projection comparisons are required')
    seen = set()
    for item in projections:
        require(isinstance(item, dict) and isinstance(item.get('profile'), str) and
                item['profile'] in profiles and item['profile'] not in seen,
                'Missing, duplicate or unknown Cards projected view')
        seen.add(item['profile'])
        layout = item.get('native_layout')
        require(isinstance(layout, dict), 'Missing original Cards projected layout')
        _safe_area_layout(layout, profiles[item['profile']][0], paused=False, report_roundtrip=True)
        hand = item.get('hand')
        require(isinstance(hand, list) and len(hand) == len(layout['hand']),
                'Independent Cards projection does not retain the original hand')
        for actual, original in zip(hand, layout['hand']):
            require(isinstance(actual, dict) and actual.get('id') == original['id'] and
                    isinstance(actual.get('quad'), list) and len(actual['quad']) == 4,
                    'Independent Cards projection changes the public hand order')
            for actual_point, original_point in zip(actual['quad'], original['quad']):
                point = _safe_area_numbers(actual_point, 2, 'Independent Cards face corner')
                require(math.dist(point, original_point) < 0.1,
                        'Independent Cards projection differs from the native layout')
    require(mobile.get('scope') ==
            'production cache and scenes with asynchronous Android boundary fixture; not device execution' and
            mobile.get('surface') == [2400, 1080] and mobile.get('density') == 2.625 and
            mobile.get('observed_system_inset_fixture') == [136, 63, 0, 63],
            'Mobile renderer report must retain its exact asynchronous boundary fixture scope')
    captures = mobile.get('images')
    require(isinstance(captures, list) and len(captures) == 4, 'All four original mobile captures are required')
    seen = set()
    for item in captures:
        require(isinstance(item, dict) and isinstance(item.get('path'), str), 'Invalid original mobile capture')
        relative = 'captures/mobile_safe_area_regression/' + item['path']
        require(relative in NEXTGEN_SAFE_AREA_PNGS and relative not in seen,
                'Missing, duplicate or unexpected mobile capture')
        seen.add(relative)
        original = images[relative]
        require(item.get('module') == NEXTGEN_SAFE_AREA_CAPTURE_IMAGES[NEXTGEN_PREFIX + '/' + relative] and
                all(item.get(key) == original[key] for key in ('width', 'height', 'sha256')),
                'Original mobile report does not identify the captured scene and original pixels')
    expected_targets = {
        ('jump', '‹ Spiele'), ('jump', 'Pause'), ('jump', 'MovementStick'), ('jump', 'JumpAction'),
        ('build', '‹ Spiele'), ('build', 'Ⅱ'), ('build', 'Verschieben'),
        ('puzzle', '‹ Spiele'), ('puzzle', 'Ⅱ'),
        ('treasure', '‹ Spiele'), ('treasure', 'Rucksack'), ('treasure', 'Ⅱ'),
        ('treasure', 'Springen'), ('treasure', 'MovementStick'), ('treasure', 'ANSEHEN'),
    }
    targets = mobile.get('targets')
    require(isinstance(targets, list) and len(targets) == 15, 'All fifteen original mobile targets are required')
    seen = set()
    for item in targets:
        require(isinstance(item, dict) and isinstance(item.get('module'), str) and
                isinstance(item.get('caption'), str), 'Invalid original mobile target')
        key = item['module'], item['caption']
        require(key in expected_targets and key not in seen and item.get('fully_inside_true_safe_area') is True,
                'Mobile report omits, duplicates or exposes an unsafe original control')
        seen.add(key)
        rect = _safe_area_rect(item.get('rect_px'), [136, 63, 2264, 954], 'Mobile ' + '/'.join(key))
        dp = _safe_area_numbers(item.get('target_dp'), 2, 'Mobile target dp')
        exposed = _safe_area_numbers(item.get('exposed_dp'), 2, 'Mobile exposed dp')
        intersection = [max(0, min(rect[0] + rect[2], 2400) - max(rect[0], 136)),
                        max(0, min(rect[1] + rect[3], 1017) - max(rect[1], 63))]
        require(min(dp) >= 47.95 and all(abs(dp[i] - rect[i + 2] / 2.625) < 0.001 and
                abs(exposed[i] - intersection[i] / 2.625) < 0.001 for i in range(2)),
                'Mobile target geometry does not preserve the original 48-dp control')


def verify_nextgen_safe_area_archive(zipped: zipfile.ZipFile) -> dict:
    """Bind seven renderer originals, three native layouts and two original reports."""
    try:
        roster = json.loads(archive_member(zipped, NEXTGEN_PREFIX + '/safe-area-images.json'))
    except (UnicodeDecodeError, json.JSONDecodeError) as error:
        raise ValueError('Invalid original safe-area raster metadata') from error
    require(isinstance(roster, dict) and type(roster.get('schema')) is int and roster['schema'] == 1,
            'Unknown original safe-area raster schema')
    images = roster.get('images')
    require(isinstance(images, list) and len(images) == 7, 'All seven original safe-area rasters are required')
    prefixes = (NEXTGEN_CARDS_SAFE_AREA_CAPTURE + '/', NEXTGEN_MOBILE_SAFE_AREA_CAPTURE + '/')
    originals = [item.filename for item in zipped.infolist()
                 if item.filename.startswith(prefixes) and PurePosixPath(item.filename).suffix.lower() == '.png']
    require(len(originals) == len(set(originals)) and set(originals) == set(NEXTGEN_SAFE_AREA_CAPTURE_IMAGES),
            'The complete original seven-PNG safe-area capture directories are required')
    captured, layout_count = {}, 0
    from PIL import Image
    for item in images:
        require(isinstance(item, dict) and isinstance(item.get('path'), str), 'Invalid original safe-area raster')
        relative = item['path']
        require(relative in NEXTGEN_SAFE_AREA_PNGS and relative not in captured,
                'Missing, duplicate or unexpected original safe-area raster path')
        data = archive_member(zipped, NEXTGEN_PREFIX + '/' + relative)
        require(type(item.get('bytes')) is int and len(data) == item['bytes'] and
                item.get('sha256') == hashlib.sha256(data).hexdigest(),
                'Original safe-area raster digest or byte count differs')
        dimensions = png_dimensions(data)
        require(all(type(item.get(key)) is int for key in ('width', 'height')) and
                dimensions == [item['width'], item['height']] == list(NEXTGEN_SAFE_AREA_PNGS[relative]),
                'Original safe-area raster dimensions differ from the production probe')
        with Image.open(BytesIO(data)) as image:
            visible = Image.alpha_composite(Image.new('RGBA', image.size, (0, 0, 0, 255)),
                                            image.convert('RGBA')).convert('RGB')
            require(any(low != high for low, high in visible.getextrema()),
                    'Original safe-area PNG is empty or a uniform color')
        if relative.startswith('captures/cards_safe_area_regression/'):
            layout = _safe_area_bound_json(zipped, item.get('native_layout'),
                                          str(PurePosixPath(relative).with_suffix('.layout.json')), limit=131072)
            _safe_area_layout(layout, NEXTGEN_SAFE_AREA_PNGS[relative], paused=relative.endswith('-paused.png'))
            layout_count += 1
        else:
            require('native_layout' not in item, 'Mobile captures cannot borrow Cards layout observations')
        captured[relative] = item
    reports = roster.get('reports')
    expected_reports = {'captures/cards_safe_area_regression/cards-safe-area.json',
                        'captures/mobile_safe_area_regression/mobile-safe-area.json'}
    require(isinstance(reports, list) and len(reports) == 2, 'Both original safe-area reports are required')
    original_reports = {}
    for descriptor in reports:
        require(isinstance(descriptor, dict) and isinstance(descriptor.get('path'), str) and
                descriptor['path'] in expected_reports and descriptor['path'] not in original_reports,
                'Missing, duplicate or unexpected original safe-area report')
        path = descriptor['path']
        original_reports[path] = _safe_area_bound_json(zipped, descriptor, path, limit=1048576)
    _verify_safe_area_reports(original_reports['captures/cards_safe_area_regression/cards-safe-area.json'],
                              original_reports['captures/mobile_safe_area_regression/mobile-safe-area.json'], captured)
    return {'native_safe_area_raster_count': len(captured), 'native_cards_layout_count': layout_count,
            'native_safe_area_report_count': len(original_reports),
            'native_safe_area_scope': 'Source-bound renderer and platform-boundary fixtures; not Android device execution'}


def verify_nextgen_touch_archive(zipped: zipfile.ZipFile, tree: str) -> dict:
    """Require all three source-bound input runs and their 32 original PNGs."""
    trees, probe_count, raster_count = {}, 0, 0
    for prefix, probe in NEXTGEN_TOUCH_PROBES.items():
        try:
            captured_tree = archive_member(zipped, prefix + '/source-tree.txt').decode('utf-8').strip()
            dirty_after = archive_member(zipped, prefix + '/source-dirty-after.txt').decode('utf-8').strip()
            engine = archive_member(zipped, prefix + '/engine.txt').decode('utf-8').strip()
            rows = [line.split('\t') for line in archive_member(
                zipped, prefix + '/results.tsv').decode('utf-8').splitlines()]
            roster = json.loads(archive_member(zipped, prefix + '/renderer-images.json'))
        except (UnicodeDecodeError, json.JSONDecodeError) as error:
            raise ValueError('Invalid original touch runner metadata: ' + prefix) from error
        require(captured_tree == tree, 'Touch capture tree differs from its exact workflow source: ' + prefix)
        require(not dirty_after, 'Tracked touch source changed during capture: ' + prefix)
        require(engine.startswith('4.6.3.stable.'), 'Unexpected touch capture engine: ' + prefix)
        require(bool(rows) and rows[0] == ['probe', 'mode', 'result'] and
                all(len(row) == 3 and row[2] == 'PASS' for row in rows[1:]),
                'Every original touch probe must report PASS: ' + prefix)
        observed = [(row[0], row[1]) for row in rows[1:]]
        require(len(observed) == 2 and set(observed) == {(probe, 'headless'), (probe, 'rendered')},
                'Both independent original touch modes must pass exactly once: ' + prefix)
        expected = NEXTGEN_TOUCH_PNGS[prefix]
        images = roster.get('images') if isinstance(roster, dict) else None
        require(isinstance(images, list) and len(images) == len(expected),
                'The complete original touch raster roster is required: ' + prefix)
        seen = set()
        for item in images:
            require(isinstance(item, dict), 'Invalid original touch raster metadata: ' + prefix)
            relative = item.get('path')
            require(isinstance(relative, str) and relative in expected and relative not in seen,
                    'Missing, duplicate or unexpected original touch raster path: ' + prefix)
            seen.add(relative)
            data = archive_member(zipped, prefix + '/' + relative)
            require(type(item.get('bytes')) is int and len(data) == item['bytes'] and
                    hashlib.sha256(data).hexdigest() == item.get('sha256'),
                    'Original touch raster digest or byte count differs: ' + prefix)
            dimensions = png_dimensions(data)
            require(all(type(item.get(key)) is int for key in ('width', 'height')) and
                    dimensions == [item['width'], item['height']] == list(expected[relative]),
                    'Original touch raster dimensions differ from the production probe: ' + prefix)
        require(seen == set(expected), 'The complete original touch raster roster is required: ' + prefix)
        trees[prefix] = captured_tree
        probe_count += len(observed)
        raster_count += len(seen)
    return {'native_touch_capture_trees': trees, 'native_touch_probe_count': probe_count,
            'native_touch_raster_count': raster_count}


def verify_visual_review(root: Path, receipt: dict, native: str,
                         artifact: dict, workflow: dict, jobs: dict, archive: Path,
                         *, native_profile: str = 'studio-2019') -> dict:
    profile = native_review_profile(native_profile)
    require(receipt.get('schema') == 1 and receipt.get('status') == 'approved',
            'The final Studio visual review is not approved')
    require(receipt.get('versionCode') == VERSION_CODE and receipt.get('native_revision') == native,
            'Visual review belongs to another native source or version')
    require(bool(str(receipt.get('reviewed_by') or '').strip()) and
            bool(str(receipt.get('notes') or '').strip()), 'Missing actual reviewer/findings')
    try:
        reviewed_at = datetime.fromisoformat(receipt.get('reviewed_at', '').replace('Z', '+00:00'))
    except (TypeError, ValueError, AttributeError) as error:
        raise ValueError('Missing dated visual review') from error
    require(reviewed_at.tzinfo is not None, 'Visual review date must include its time zone')
    if native_profile == 'nextgen-2019':
        require(receipt.get('native_profile') == native_profile,
                'The combined Nextgen review must name its fixed native profile')
    verify_native_acceptance(native, artifact, workflow, jobs, native_profile=native_profile)
    require(artifact['id'] == receipt.get('native_artifact_id') and
            workflow['id'] == receipt.get('native_workflow_run_id'),
            'Visual artifact or workflow identity differs from the reviewed artifact')
    digest = receipt.get('native_artifact_sha256', '')
    require(bool(re.fullmatch(r'[a-f0-9]{64}', str(digest))) and
            artifact.get('digest') == 'sha256:' + digest, 'Reviewed artifact bytes differ')
    require(archive.is_file() and not archive.is_symlink() and sha256_file(archive) == digest,
            'Downloaded original native archive digest differs')
    images = receipt.get('images')
    require(isinstance(images, list) and bool(images), 'No reviewed original PNGs')
    modules, orientations, paths, hashes, entries = set(), set(), set(), set(), set()
    additional = {}
    capture_probes = set()
    with zipfile.ZipFile(archive) as zipped:
        sources = verify_archive_sources(zipped, native, native_profile=native_profile)
        if native_profile == 'nextgen-2019':
            additional = verify_nextgen_archive(zipped, workflow)
        for entry in images:
            require(isinstance(entry, dict), 'Invalid reviewed image entry')
            module, original = entry.get('module'), entry.get('artifact_entry')
            image_digest = entry.get('sha256')
            relative = reviewed_relative_path(image_digest, module, original, native_profile=native_profile)
            require(entry.get('path') == relative, 'Reviewed PNG filename must contain its full SHA-256 and module')
            require(relative not in paths and original not in entries, 'Duplicate reviewed image path or archive entry')
            paths.add(relative)
            entries.add(original)
            capture_probes.add(str(PurePosixPath(original).parent))
            path = reviewed_file(root, relative, native_profile=native_profile)
            require(path.is_file(), 'Reviewed PNG is not committed as a real file')
            data = path.read_bytes()
            require(hashlib.sha256(data).hexdigest() == image_digest and image_digest not in hashes,
                    'Reviewed image bytes changed or were reused across modules')
            require(data == archive_member(zipped, original), 'Reviewed PNG differs from the original current native artifact')
            dimensions = png_dimensions(data)
            require(dimensions == entry.get('dimensions'), 'Reviewed PNG dimensions differ')
            require(bool(str(entry.get('findings') or '').strip()), 'Missing actual visual findings')
            hashes.add(image_digest)
            modules.add(module)
            orientations.add('portrait' if dimensions[1] > dimensions[0] else 'landscape')
    require(modules == REVIEW_MODULES, 'Visual review must cover all nine changed production scenes')
    require(TOUCH_CAPTURE_PROBES.issubset(capture_probes),
            'Visual review must include the current workshop, treasure and build touch captures')
    if native_profile == 'nextgen-2019':
        require(NEXTGEN_VILLAGE_CAPTURE in capture_probes,
                'Visual review must include the current Village production capture')
        additional['reviewed_village_capture_probes'] = [NEXTGEN_VILLAGE_CAPTURE]
        require(NEXTGEN_PUZZLE_MENU_CAPTURE in capture_probes,
                'Visual review must include the current Puzzle menu lifecycle capture')
        additional['reviewed_puzzle_menu_capture_probes'] = [NEXTGEN_PUZZLE_MENU_CAPTURE]
        require(set(NEXTGEN_SAFE_AREA_CAPTURE_IMAGES).issubset(entries),
                'Visual review must include all seven current Cards and mobile safe-area originals')
        additional['reviewed_safe_area_entries'] = sorted(NEXTGEN_SAFE_AREA_CAPTURE_IMAGES)
        additional['reviewed_cards_safe_area_capture_probe'] = NEXTGEN_CARDS_SAFE_AREA_CAPTURE
    else:
        require(PUZZLE_MENU_CAPTURE_PROBE in capture_probes,
                'Visual review must include the current Puzzle menu lifecycle capture')
        require(CARDS_SAFE_AREA_CAPTURE_PROBE in capture_probes,
                'Visual review must include the current Cards safe-area capture')
        additional['reviewed_cards_safe_area_capture_probe'] = CARDS_SAFE_AREA_CAPTURE_PROBE
    require(orientations == {'portrait', 'landscape'}, 'Phone and landscape visual evidence are required')
    return {'native_revision': native, 'native_workflow_run_id': workflow['id'],
            'native_artifact_id': artifact['id'], 'native_artifact_sha256': digest,
            'native_capture_sources': sources, 'native_acceptance_jobs': sorted(profile.jobs),
            'reviewed_touch_capture_probes': sorted(TOUCH_CAPTURE_PROBES),
            'reviewed_by': receipt['reviewed_by'], 'reviewed_at': receipt['reviewed_at'],
            'images': len(images), 'modules': sorted(modules), **additional}


def verify_proofs(source: str, native: str, version_name: str, digest: str, size: int,
                  proof: dict, verification: dict, measured: dict, update: dict,
                  tour: dict, surfaces: dict, host: dict, surface_evidence: Path) -> dict:
    require(version_name == VERSION_NAME, 'This publisher only accepts Studio 0.13.7+2019')
    require(bool(re.fullmatch(r'[a-f0-9]{40}', source)), 'Missing immutable Flutter source')
    require(proof.get('flutter_source_commit') == source and proof.get('tracked_source_clean') is True,
            'APK provenance belongs to different or uncommitted Flutter source')
    for info in (proof, verification, measured):
        require(info.get('versionCode') == VERSION_CODE and info.get('versionName') == version_name,
                'Wrong Android delivery version')
        require(info.get('package') == PACKAGE_ID and
                info.get('signingCertificateSha256') == EXPECTED_CERT_SHA256,
                'Wrong installed-family package or test signing certificate')
        require(info.get('abis') == ['arm64-v8a'], 'Delivery must contain the actual ARM64 APK')
        require(info.get('sha256') == digest and info.get('bytes') == size,
                'Actual APK bytes differ from provenance or repeated verification')
        require(info.get('godot', {}).get('revision') == native, 'Wrong embedded native source')
    require(update.get('status') == 'PASS' and tour.get('status') == 'PASS' and
            surfaces.get('status') == 'PASS', 'Actual Android acceptance is incomplete')
    baseline = update.get('baseline', {})
    require(update.get('candidate_source') == source and baseline.get('versionCode') == 2017 and
            baseline.get('flutter_source_commit') == BASELINE_SOURCE and
            baseline.get('godot', {}).get('revision') == BASELINE_NATIVE,
            'In-place upgrade did not use the real 2017 baseline and this candidate')
    candidate = update.get('candidate', {})
    require(candidate.get('flutter_source_commit') == source and candidate.get('tracked_source_clean') is True and
            candidate.get('versionCode') == VERSION_CODE and candidate.get('versionName') == version_name and
            candidate.get('package') == PACKAGE_ID and
            candidate.get('signingCertificateSha256') == EXPECTED_CERT_SHA256 and
            candidate.get('abis') == ['x86_64'] and candidate.get('godot', {}).get('revision') == native,
            'Android update tested another candidate')
    identities = [step for step in tour.get('steps', []) if step.get('step') == 'apk-identity']
    require(len(identities) == 1 and identities[0].get('ok') is True, 'Missing actual tour APK identity')
    for identity in (identities[0], surfaces.get('apk_identity', {})):
        require(identity.get('flutter_source_commit') == source and identity.get('godot_revision') == native and
                identity.get('versionCode') == VERSION_CODE and identity.get('versionName') == version_name and
                identity.get('signingCertificateSha256') == EXPECTED_CERT_SHA256,
                'Android surface or tour tested another source/version/signature')
        require(identity.get('apk_sha256') == tour.get('apk_sha256') == candidate.get('sha256'),
                'Tour, new surfaces and update tested different APK bytes')
        require(proof.get('godot', {}).get('pck_sha256') == candidate.get('godot', {}).get('pck_sha256') ==
                identity.get('godot_pck_sha256') and
                bool(re.fullmatch(r'[a-f0-9]{64}', str(identity.get('godot_pck_sha256', '')))),
                'The native PCK differs between emulator evidence and ARM64 delivery')
    require(update.get('offline') is True and all(item.get('fatal_crashes') == 0
            for item in (update, tour, surfaces)), 'Offline upgrade or crash acceptance failed')
    launches = [step for step in tour.get('steps', []) if step.get('step') == 'start-kart-race']
    require(len(launches) == 1 and launches[0].get('ok') is True, 'Actual Kart launch not proven')
    navigation = launches[0].get('spatial_menu_navigation', {})
    require(navigation.get('status') == 'PASS' and navigation.get('selected_mode') == 'cup' and
            [section.get('section') for section in navigation.get('sections', [])] == ['garage', 'driver'],
            'Actual spatial garage/driver/cup navigation not proven')
    learning, cards = surfaces.get('learning', {}), surfaces.get('cards', {})
    require(learning.get('moves', {}).get('complete') is True and
            learning['moves'].get('moved_objects') == 5 and learning.get('same_lesson_after_return') is True and
            learning.get('illustration_did_not_award_mastery') is True,
            'Actual learning object movement and unchanged learning state not proven')
    permission = surfaces.get('local_voice_permission', {})
    require(surfaces.get('offline') is True and permission.get('local_model_assent') is True and
            permission.get('voice_enabled') is True and permission.get('auto_read') is True and
            permission.get('unrelated_permissions_unchanged') is True,
            'Actual offline speech permission route was not verified')
    speech = learning.get('speech', {})
    initial_voice, result_voice = speech.get('initial', {}), speech.get('result', {})
    for observed in (initial_voice, result_voice):
        ids = observed.get('completed_utterance_ids')
        require(observed.get('profile') == 'lumo-free-supertonic-de-v1' and
                observed.get('preset') == 'F2' and isinstance(ids, list) and bool(ids) and
                all(type(value) is int and value > 0 for value in ids) and
                type(observed.get('native_process_pid')) is int and observed['native_process_pid'] > 0 and
                observed.get('audible_quality_verified') is False and observed.get('lip_sync_verified') is False,
                'Actual original local playback start/completion was not verified')
    require(initial_voice['native_process_pid'] == result_voice['native_process_pid'] and
            max(initial_voice['completed_utterance_ids']) < min(result_voice['completed_utterance_ids']) and
            speech.get('native_process_gone_on_return') is True,
            'Speech belongs to another native lesson or its process remained alive')
    for key in ('pause_saved_state_unchanged', 'reopened_same_round', 'new_mailbox_token'):
        require(cards.get(key) is True, 'Cards lifecycle/persistence gate failed: ' + key)
    for key in ('draw', 'draw_after_visible_idle'):
        move = cards.get(key, {})
        require(move.get('cards_conserved') == 112 and move.get('child_cards_added', 0) > 0,
                'Missing actual Cards draw/persistence proof: ' + key)
    require(cards['draw'].get('owner') == cards['draw_after_visible_idle'].get('owner') and
            cards['draw'].get('round_id') == cards['draw_after_visible_idle'].get('round_id') and
            cards.get('visible_idle_seconds', 0) >= 35, 'Cards authority did not survive visible idle')
    bindings = cards.get('android_authority_binding', [])
    require(len(bindings) == 2 and bindings[0] == bindings[1] and bindings[0].get('bound') is True and
            bindings[0].get('main_process_pid') != bindings[0].get('native_process_pid'),
            'Missing actual Android binding between native activity and Dart authority')
    require(host.get('status') == 'PASS' and host.get('flutter_source_commit') == source and
            COMPILED_CLASSES <= set(host.get('classes', {})), 'Current Android host bytecode not verified')
    card_pixels = verify_cards_front_faces(cards, surface_evidence, require_layout=True)
    return {'package': PACKAGE_ID, 'versionName': version_name, 'versionCode': VERSION_CODE,
            'flutterSourceCommit': source, 'godotSourceCommit': native,
            'signingCertificateSha256': EXPECTED_CERT_SHA256, 'apkSha256': digest, 'apkBytes': size,
            'androidTourApkSha256': candidate['sha256'],
            'cardsFrontFacePixels': card_pixels,
            'signingScope': 'Public Lumo test key; not Google Play signing',
            'voiceScope': 'Actual local playback callbacks in a -noaudio emulator; audible quality and lip synchronization not verified',
            'deviceScope': 'x86_64 Android emulator acceptance; physical Fold7/Android17/FPS not measured'}


def verify_android_runtime(surfaces: dict, expected_api: int) -> dict:
    require(isinstance(surfaces, dict), 'Missing actual Android surface report')
    runtime = surfaces.get('android_runtime')
    require(isinstance(runtime, dict) and type(runtime.get('sdk')) is int and
            runtime['sdk'] == expected_api,
            f'Actual Android runtime must report API {expected_api}')
    for field in ('release', 'fingerprint', 'model'):
        require(isinstance(runtime.get(field), str) and bool(runtime[field].strip()),
                f'Missing actual Android API {expected_api} runtime {field}')
    if expected_api == 37:
        require(bool(re.fullmatch(r'17(?:\.[0-9]+)*', runtime['release'])),
                'API 37 acceptance requires actual Android release 17')
    return {field: runtime[field] for field in ('sdk', 'release', 'fingerprint', 'model')}


def verify_tour_android_runtime(tour: dict, runtime: dict) -> None:
    # The original tour writes the stripped getprop value as a JSON string.
    # Do not coerce other types or normalize evidence from a different device.
    require(isinstance(tour, dict) and isinstance(tour.get('android_sdk'), str) and
            tour['android_sdk'] == str(runtime['sdk']),
            f"Original Android tour must report API {runtime['sdk']} matching its surface runtime")


def verify_android_platforms(source: str, native: str, version_name: str, digest: str, size: int,
                             proof: dict, verification: dict, measured: dict, update: dict,
                             tour: dict, surfaces: dict, host: dict, surface_evidence: Path,
                             android17_root: Path) -> dict:
    """Require both original emulator datasets without altering any input proof.

    The same ARM64 delivery and exact x86_64 candidate/PCK must satisfy the full
    existing gates twice. The original 2017 update remains mandatory; an API 35
    tour or surface directory cannot substitute for the separate Android 17 run.
    """
    require(android17_root.is_dir() and not android17_root.is_symlink(),
            'Missing separate original Android 17 evidence directory')
    android17_evidence = android17_root / 'nextgen'
    require(android17_evidence.resolve() != surface_evidence.resolve(),
            'Android 17 evidence cannot reuse the API 35 surface directory')
    reports = []
    for relative in ('tour-result.json', 'nextgen/native-surfaces-result.json'):
        path = android17_root / relative
        require(path.is_file() and not path.is_symlink(),
                'Missing original Android 17 report: ' + relative)
        reports.append(read_json(path))
    android17_tour, android17_surfaces = reports
    runtime35 = verify_android_runtime(surfaces, 35)
    runtime37 = verify_android_runtime(android17_surfaces, 37)
    verify_tour_android_runtime(tour, runtime35)
    verify_tour_android_runtime(android17_tour, runtime37)
    facts = verify_proofs(source, native, version_name, digest, size, proof, verification, measured,
                          update, tour, surfaces, host, surface_evidence)
    android17 = verify_proofs(source, native, version_name, digest, size, proof, verification, measured,
                              update, android17_tour, android17_surfaces, host, android17_evidence)
    facts['androidEmulatorAcceptance'] = [
        {'status': 'PASS', 'android_runtime': runtime35,
         'androidTourApkSha256': facts['androidTourApkSha256'],
         'cardsFrontFacePixels': facts['cardsFrontFacePixels']},
        {'status': 'PASS', 'android_runtime': runtime37,
         'androidTourApkSha256': android17['androidTourApkSha256'],
         'cardsFrontFacePixels': android17['cardsFrontFacePixels']},
    ]
    facts['deviceScope'] = (
        'Android API 35 and API 37 (Android 17) x86_64 emulator acceptance; '
        'physical Samsung Galaxy Z Fold7 performance, FPS and temperature not measured'
    )
    return facts


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--source-sha', required=True)
    parser.add_argument('--root', type=Path, default=Path('.'))
    parser.add_argument('--dist', type=Path, default=Path('dist'))
    parser.add_argument('--proofs', type=Path, default=Path('proofs'))
    parser.add_argument('--native-archive', type=Path,
                        help='Original downloaded ZIP, default: <proofs>/native-evidence.zip')
    args = parser.parse_args()
    root, dist, proofs = args.root, args.dist, args.proofs
    pubspec = (root / 'pubspec.yaml').read_text()
    source_config = (root / 'config/godot-source.json').read_text()
    version_name, version_code = parse_pubspec_version(pubspec)
    build, native = verify_pin(pubspec, source_config)
    require(build == version_code == VERSION_CODE and version_name == VERSION_NAME,
            'This publisher only accepts reviewed Studio 0.13.7+2019')
    require((dist / 'APP-VERSION.txt').read_text().strip() == f'version: {VERSION_NAME}+{VERSION_CODE}',
            'Packaged application version differs from current source')
    require(read_json(dist / 'GODOT-SOURCE.json') == json.loads(source_config), 'Packaged source pin differs')
    apk = dist / 'Lumo-Lernen-Neu.apk'
    facts = verify_android_platforms(args.source_sha, native, version_name, sha256_file(apk), apk.stat().st_size,
                          read_json(dist / 'BUILD-PROVENANCE.json'), read_json(dist / 'APK-VERIFICATION.json'),
                          read_json(dist / 'PUBLISH-VERIFICATION.json'), read_json(proofs / 'update/update-result.json'),
                          read_json(proofs / 'tour/tour-result.json'),
                          read_json(proofs / 'tour/nextgen/native-surfaces-result.json'),
                          read_json(proofs / 'host/result.json'), proofs / 'tour/nextgen',
                          proofs / 'android17')
    facts['visualReview'] = verify_visual_review(root, read_json(root / REVIEW_RECEIPT), native,
                                               read_json(proofs / 'native-artifact.json'),
                                               read_json(proofs / 'native-run.json'),
                                               read_json(proofs / 'native-jobs.json'),
                                               args.native_archive or proofs / 'native-evidence.zip')
    (dist / 'RELEASE-FACTS.json').write_text(json.dumps(facts, indent=2) + '\n')
    (dist / 'Lumo-Lernen-Neu.apk.sha256').write_text(f"{facts['apkSha256']}  Lumo-Lernen-Neu.apk\n")
    print(json.dumps(facts, indent=2))
    return 0


if __name__ == '__main__':
    raise SystemExit(main())

