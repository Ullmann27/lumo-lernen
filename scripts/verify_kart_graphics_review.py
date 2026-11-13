#!/usr/bin/env python3
"""Verify a human-reviewed 2019 receipt against transferred original CI evidence.

This code never grants visual approval. It checks an explicit committed review
against the actual workflow, public archive digests, source identity and PNGs.
The authorized reviewer downloads and verifies original archives before copying
these files into the host commit. Publication rehashes those preserved files;
it neither downloads private archives nor claims to independently extract them.
"""
from __future__ import annotations

from datetime import datetime
import hashlib
import io
import json
from pathlib import Path, PurePosixPath
import re

from verify_nextgen_delivery import read_json, require


WORKFLOW_PATH = '.github/workflows/lumo-kart-experience.yml'
WORKFLOW_NAME = 'LUMO Kart world, home and driving graphics'
NATIVE_REPOSITORY = 'Ullmann27/lumo-godot'
PROOF_DIRECTORY = ('docs', 'evidence', 'kart-graphics-2019-reviewed')
ARTIFACT_NAMES = {
    key: 'lumo-kart-experience-' + key for key in ('home', 'worlds', 'feedback')
}
REVIEW_AREAS = {'home', 'winter_sprint', 'crystal_canyon', 'feedback'}
AREA_ARTIFACT = {'home': 'home', 'winter_sprint': 'worlds',
                 'crystal_canyon': 'worlds', 'feedback': 'feedback'}
REQUIRED_LOGS = {
    'home': {
        'regression.log': '[KartHomeExperience] PASS',
        'home-promenade.log': '[KartHomePromenade] PASS',
        'preserved-spatial-menu.log': '[SpatialMenu] PASS',
        'preserved-garage.log': '[NextGenGarage] PASS',
        'render.log': '[KartHomeExperienceCapture] PASS',
    },
    'worlds': {
        'regression.log': '[KartWorldExpansion] PASS',
        'render-winter_sprint.log': '[KartWorldExpansionCapture] PASS',
        'render-crystal_canyon.log': '[KartWorldExpansionCapture] PASS',
    },
    'feedback': {
        'regression.log': '[KartDriveFeedback] PASS',
        'render.log': '[KartDriveFeedbackCapture] PASS',
    },
}
SOURCE_FILES = ('source-sha.txt', 'source-tree.txt', 'source-dirty.txt',
                'engine.txt', 'image-manifest.json', 'artifact.json')
WORKFLOW_FILES = ('run.json', 'jobs.json')


def review_identity(receipt: dict, native: str) -> tuple[int, dict]:
    require(receipt.get('schema') == 1 and receipt.get('status') == 'approved',
            'The final 2019 graphics review is not approved')
    require(type(receipt.get('versionCode')) is int and receipt['versionCode'] == 2019 and
            receipt.get('native_revision') == native and
            bool(re.fullmatch(r'[a-f0-9]{40}', native)),
            'Graphics review belongs to another native source or version')
    require(all(isinstance(receipt.get(key), str) and receipt[key].strip()
                for key in ('reviewed_by', 'notes')), 'Missing actual reviewer or findings')
    try:
        reviewed_at = datetime.fromisoformat(receipt.get('reviewed_at', '').replace('Z', '+00:00'))
    except (TypeError, ValueError, AttributeError) as error:
        raise ValueError('Missing dated graphics review') from error
    require(reviewed_at.tzinfo is not None, 'Graphics review date must include its time zone')
    run_id = receipt.get('native_workflow_run_id')
    require(type(run_id) is int and run_id > 0, 'Missing exact native graphics run')
    workflow_hashes = receipt.get('workflow_metadata_sha256')
    require(isinstance(workflow_hashes, dict) and set(workflow_hashes) == set(WORKFLOW_FILES) and
            all(re.fullmatch(r'[a-f0-9]{64}', str(value)) for value in workflow_hashes.values()),
            'Missing original run/job metadata hashes')
    entries = receipt.get('artifacts')
    require(isinstance(entries, list) and len(entries) == 3, 'All three reviewed artifacts are required')
    artifacts, ids = {}, set()
    for entry in entries:
        require(isinstance(entry, dict), 'Invalid reviewed artifact')
        area = entry.get('area')
        require(area in ARTIFACT_NAMES and area not in artifacts and
                entry.get('name') == ARTIFACT_NAMES[area], 'Wrong or repeated graphics artifact')
        identity = entry.get('id')
        require(type(identity) is int and identity > 0 and identity not in ids,
                'Missing or repeated artifact identity')
        require(bool(re.fullmatch(r'[a-f0-9]{64}', str(entry.get('sha256', '')))),
                'Missing original archive SHA-256')
        hashes = entry.get('metadata_sha256')
        require(isinstance(hashes, dict) and set(hashes) == set(SOURCE_FILES) | set(REQUIRED_LOGS[area]) and
                all(re.fullmatch(r'[a-f0-9]{64}', str(value)) for value in hashes.values()),
                'Missing original source, manifest, artifact or gate-log hashes')
        artifacts[area] = entry
        ids.add(identity)
    require(set(artifacts) == set(ARTIFACT_NAMES), 'Missing reviewed graphics artifact area')
    return run_id, artifacts


def _relative(name: str) -> PurePosixPath:
    require(isinstance(name, str) and '\\' not in name, 'Invalid original archive path')
    path = PurePosixPath(name)
    require(name == str(path) and not path.is_absolute() and '..' not in path.parts and
            bool(path.parts), 'Original artifact path must stay inside its archive')
    return path


def _original(root: Path, relative: PurePosixPath, digest: str,
              limit: int = 64 * 1024 * 1024) -> bytes:
    path = root.joinpath(*relative.parts)
    require(path.is_file() and not path.is_symlink() and path.resolve().is_relative_to(root.resolve()) and
            path.stat().st_size <= limit, 'Missing or invalid preserved original: ' + str(relative))
    data = path.read_bytes()
    require(hashlib.sha256(data).hexdigest() == digest,
            'Preserved original bytes differ from the reviewed transfer: ' + str(relative))
    return data


def _png_dimensions(data: bytes) -> list[int]:
    from PIL import Image

    require(data[:8] == b'\x89PNG\r\n\x1a\n', 'Reviewed original is not a PNG')
    try:
        with Image.open(io.BytesIO(data)) as picture:
            require(picture.format == 'PNG' and not getattr(picture, 'is_animated', False),
                    'Review requires a real still PNG')
            width, height = picture.size
            require(320 <= width <= 8192 and 320 <= height <= 8192,
                    'Reviewed PNG dimensions are unsupported')
            picture.verify()
        with Image.open(io.BytesIO(data)) as picture:
            picture.load()
    except (OSError, SyntaxError, Image.DecompressionBombError) as error:
        raise ValueError('The original PNG cannot be decoded') from error
    return [width, height]


def verify_visual_review(root: Path, receipt: dict, native: str, proofs: Path) -> dict:
    run_id, requested = review_identity(receipt, native)
    evidence = PurePosixPath(*PROOF_DIRECTORY, 'metadata')
    saved_workflow = {}
    for name in WORKFLOW_FILES:
        saved_workflow[name] = json.loads(_original(
            root, evidence / name, receipt['workflow_metadata_sha256'][name], 8 * 1024 * 1024))
    workflow, jobs = read_json(proofs / 'run.json'), read_json(proofs / 'jobs.json')
    for run in (workflow, saved_workflow['run.json']):
        require(isinstance(run, dict) and run.get('id') == run_id and run.get('head_sha') == native and
                run.get('path') == WORKFLOW_PATH and run.get('name') == WORKFLOW_NAME and
                run.get('repository', {}).get('full_name') == NATIVE_REPOSITORY and
                run.get('status') == 'completed' and run.get('conclusion') == 'success',
                'Exact graphics workflow did not finish successfully on the reviewed source')
    expected_jobs = {'Actual ' + key + ' scene and interaction' for key in ARTIFACT_NAMES}
    recorded_jobs = None
    for record in (jobs, saved_workflow['jobs.json']):
        require(isinstance(record, dict), 'Missing original or live graphics job metadata')
        job_rows = record.get('jobs')
        require(isinstance(job_rows, list) and record.get('total_count') == len(job_rows) == 3,
                'All three actual graphics jobs are required')
        require(all(isinstance(job, dict) for job in job_rows) and
                {job.get('name') for job in job_rows} == expected_jobs and
                all(type(job.get('id')) is int and job['id'] > 0 and job.get('run_id') == run_id and
                    job.get('status') == 'completed' and job.get('conclusion') == 'success'
                    for job in job_rows), 'Missing or failed home, worlds or feedback acceptance job')
        identities = {job['name']: job['id'] for job in job_rows}
        require(recorded_jobs is None or recorded_jobs == identities,
                'Original graphics job identities differ from the actual completed jobs')
        recorded_jobs = identities
    images = receipt.get('images')
    require(isinstance(images, list) and bool(images), 'Missing reviewed original graphics PNGs')
    manifests, artifact_summaries = {}, []
    tree = None
    for key, specification in requested.items():
        originals = {
            name: _original(root, evidence / key / name, digest, 16 * 1024 * 1024)
            for name, digest in specification['metadata_sha256'].items()
        }
        for artifact in (read_json(proofs / (key + '-artifact.json')),
                         json.loads(originals['artifact.json'])):
            require(isinstance(artifact, dict) and artifact.get('id') == specification['id'] and
                    artifact.get('name') == ARTIFACT_NAMES[key] and artifact.get('expired') is False,
                    'Graphics artifact identity differs or has expired: ' + key)
            require(artifact.get('digest') == 'sha256:' + specification['sha256'] and
                    artifact.get('workflow_run', {}).get('id') == run_id and
                    artifact['workflow_run'].get('head_sha') == native,
                    'Graphics archive belongs to different bytes or source: ' + key)
        require(originals['source-sha.txt'].decode().strip() == native,
                'Archived graphics were rendered from another native source: ' + key)
        require(not originals['source-dirty.txt'].strip(),
                'Graphics source was modified while capturing: ' + key)
        actual_tree = originals['source-tree.txt'].decode().strip()
        require(bool(re.fullmatch(r'[a-f0-9]{40}', actual_tree)) and
                (tree is None or tree == actual_tree), 'Graphics artifact source trees differ')
        tree = actual_tree
        require(originals['engine.txt'].decode().strip().startswith('4.6.3.'),
                'Graphics artifact used another Godot engine')
        for filename, marker in REQUIRED_LOGS[key].items():
            log = originals[filename].decode()
            require(marker in log and not re.search(
                r'SCRIPT ERROR|Parse Error|ERROR:|\bFAIL(?:ED)?\b|ObjectDB instances leaked|'
                r'still in use at exit|Unreferenced static string', log),
                'Missing or failed original graphics gate: ' + key + '/' + filename)
            if filename.startswith('render') or (filename == 'regression.log' and key != 'home'):
                require('OpenGL API' in log, 'A headless result cannot approve rendered graphics')
        manifest = json.loads(originals['image-manifest.json'])
        require(isinstance(manifest, list) and bool(manifest), 'Missing original PNG hash manifest')
        indexed = {}
        for entry in manifest:
            require(isinstance(entry, dict), 'Invalid original PNG hash entry')
            name = str(_relative(entry.get('file')))
            require(name not in indexed and type(entry.get('bytes')) is int and entry['bytes'] > 0 and
                    bool(re.fullmatch(r'[a-f0-9]{64}', str(entry.get('sha256', '')))),
                    'Invalid or repeated original PNG hash entry')
            indexed[name] = entry
        manifests[key] = indexed
        artifact_summaries.append(dict(specification))
    paths, digests, areas, home_orientations, reviewed = set(), set(), set(), set(), []
    for entry in images:
        require(isinstance(entry, dict), 'Invalid graphics review image')
        area = entry.get('area')
        require(area in REVIEW_AREAS, 'Unknown graphics review area')
        key = AREA_ARTIFACT[area]
        require(entry.get('artifact_id') == requested[key]['id'] and entry.get('native_revision') == native,
                'Image names the wrong original artifact or native source')
        relative = _relative(entry.get('path'))
        require(relative.parts[:3] == PROOF_DIRECTORY and relative.suffix == '.png' and
                str(relative) not in paths, 'Reviewed PNG must be a unique committed 2019 original')
        original = _relative(entry.get('artifact_entry'))
        prefix = ('images', area) if key == 'worlds' else ('images',)
        require(original.parts[:len(prefix)] == prefix and original.suffix == '.png',
                'Baseline or unrelated image cannot approve current graphics')
        require(isinstance(entry.get('findings'), str) and entry['findings'].strip(),
                'Missing actual image review findings')
        original_bytes = _original(root, relative, entry.get('sha256'))
        digest = hashlib.sha256(original_bytes).hexdigest()
        manifest_entry = manifests[key].get(str(original), {})
        require(manifest_entry.get('sha256') == digest and manifest_entry.get('bytes') == len(original_bytes) and
                digest not in digests, 'Reviewed PNG differs from the original artifact manifest or is reused')
        dimensions = _png_dimensions(original_bytes)
        require(dimensions == entry.get('dimensions'), 'Reviewed original PNG dimensions differ')
        if area == 'home':
            home_orientations.add('portrait' if dimensions[1] > dimensions[0] else 'landscape')
        paths.add(str(relative))
        digests.add(digest)
        areas.add(area)
        reviewed.append(dict(entry))
    require(areas == REVIEW_AREAS, 'Review must cover home, winter_sprint, crystal_canyon and feedback')
    require(home_orientations == {'portrait', 'landscape'},
            'Home review must include actual portrait and landscape originals')
    return {'native_revision': native, 'native_source_tree': tree,
            'native_workflow_run_id': run_id, 'workflow_path': WORKFLOW_PATH,
            'artifacts': artifact_summaries, 'reviewed_by': receipt['reviewed_by'],
            'reviewed_at': receipt['reviewed_at'], 'notes': receipt['notes'],
            'workflow_metadata_sha256': receipt['workflow_metadata_sha256'],
            'evidenceScope': 'Authorized reviewer verified original archive downloads; publisher rehashed committed originals and compared public artifact/run/job identities',
            'areas': sorted(areas), 'images': reviewed}
