#!/usr/bin/env python3
"""Bind repaired QA to the unchanged, already built 1e22 build-2020 APK.

This is a local preflight, not an APK build, Android result or release approval.
The original run may have failed its Android jobs: its exact successful build
and candidate artifact are the input. GitHub metadata must be downloaded by the
calling workflow without modification. No network, SDK or device is used here.
"""
from __future__ import annotations

import argparse
import hashlib
import importlib.util
import json
import os
from pathlib import Path
import re
import stat
import subprocess
import sys
import tempfile
import zipfile


ROOT = Path(__file__).resolve().parents[1]
REPOSITORY = 'Ullmann27/lumo-lernen'
REPOSITORY_ID = 1222433959
HOST = '1e22d2455937e2640d1e44e153d290746f3afe49'
HOST_TREE = '7fcc3748f8178bff91176ff27f11f7e86ca165ca'
NATIVE = 'e9a9f60f20403ffa6b2b26d1437f958b2704d2aa'
BUILD_RUN = 43596913210
BUILD_JOB = 132454178537
BUILD_ATTEMPT = 1
CANDIDATE_WORKFLOW = '.github/workflows/lumo-connect-four-2020.yml'
ARTIFACT_ID = 14119280540
ARTIFACT_BYTES = 665888449
ARTIFACT_DIGEST = 'sha256:3303cf5c34b96b9eefd08e3a64e5fcb4d6698ede4683810e9a2bb95311bc3210'
APK_BYTES = 334507298
APK_SHA256 = 'e65662ccc91366177a80bf6c6d43d364d9908836eb50bbe43625725d6010ab4b'
PCK_BYTES = 75403096
PCK_SHA256 = 'c4c6fb10d6a9492c7c34bcf330ff0dad18601cbcccaedcfe7468053c7328c6dc'
PCK_MEMBER = 'assets/lumo_game.pck'
SUM_MEMBER = 'dist/x86_64/Lumo-Lernen-Neu.apk'
PACKAGE = 'dev.ullmann.lumo.lumo_lernen.coachpreview'
CERTIFICATE = 'a6b1ef61bf59db4e0794c742aeb3b5506d130f4d21175c9975140e6acdb80702'
QA_WORKFLOW = '.github/workflows/lumo-unchanged-2020-apk-diagnostic.yml'
QA_BRANCH = 'qa/lumo-android-runtime-1e22-20261114'
QA_JOBS = ('unchanged-2020-main-api35', 'unchanged-2020-update2017-api35')
QA_ROUTES = {name: (QA_WORKFLOW, QA_BRANCH) for name in QA_JOBS}
BASELINE = {
    'host': '47889f74a651b073965def70743417cf320b1eb9',
    'tree': '5fad519864decd4700803b747cdff60ba7f3e02c',
    'native': '1d5c5cb45a323228f627ec529e6ff1ddd86f1c57',
    'run': 43220602252, 'job': 131192088702, 'attempt': 1,
    'workflow': '.github/workflows/lumo-unified-integration-2026.yml',
    'artifact': 13948686178, 'artifact_name': 'lumo-lernen-kart-unified-2026-candidate',
    'artifact_bytes': 640684233,
    'artifact_digest': 'sha256:4b4fa4e7de52d75f385fc4d7e398f571d86363ad17cc22ac41ef95aab61d08ff',
    'apk_bytes': 321904250,
    'apk_sha256': '03063cdc0956b3c1df00f604de504841e1a5fed4cabf31c9418a9167a11140e8',
    'pck_bytes': 62921032,
    'pck_sha256': '30b11b2f691294672038eafd53ddfc1c861db26def632fdb670893d5b508d65a',
}
QA_FILES = (
    'scripts/verify_unchanged_2020_apk_diagnostic.py',
    'scripts/run_unchanged_2020_apk_diagnostic.sh',
    QA_WORKFLOW,
    'scripts/verify_legacy_release_pin.py',
)
BUILD_STEPS = (
    'Build unified real Android APK',
    'Verify APK archive and collect reproducible source hashes',
    'Upload exact candidate (no release or synthetic screenshots)',
)


def require(condition: bool, message: str) -> None:
    if not condition:
        raise RuntimeError(message)


def regular(path: Path) -> Path:
    require(not path.is_symlink() and path.is_file(), 'Expected a regular, non-symlink input: ' + str(path))
    return path.resolve()


def file_digest(path: Path) -> str:
    with path.open('rb') as stream:
        return hashlib.file_digest(stream, 'sha256').hexdigest()


def unique_object(pairs):
    value = {}
    for key, item in pairs:
        require(key not in value, 'Duplicate JSON key')
        value[key] = item
    return value


def reject_constant(value):
    raise ValueError('Non-finite JSON value: ' + value)


def read_json(path: Path) -> dict:
    value = json.loads(regular(path).read_bytes(), object_pairs_hook=unique_object,
                       parse_constant=reject_constant)
    require(isinstance(value, dict), 'Expected a JSON object: ' + str(path))
    return value


def complete_rows(data: dict, key: str) -> list[dict]:
    rows = data.get(key)
    require(isinstance(rows, list) and all(isinstance(row, dict) for row in rows)
            and type(data.get('total_count')) is int and data['total_count'] == len(rows),
            'Incomplete original metadata collection: ' + key)
    ids = [row.get('id') for row in rows]
    require(all(type(value) is int and value > 0 for value in ids)
            and len(set(ids)) == len(ids), 'Duplicate or invalid metadata IDs: ' + key)
    return rows


def load_module(name: str, path: Path):
    spec = importlib.util.spec_from_file_location(name, regular(path))
    require(spec is not None and spec.loader is not None, 'Cannot load committed QA helper')
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def verify_candidate(run: dict, jobs: dict, artifacts: dict, c4) -> dict:
    rows = complete_rows(jobs, 'jobs')
    artifact_rows = complete_rows(artifacts, 'artifacts')
    binding = c4.artifact_binding(
        run, artifacts, jobs, source=HOST, native=NATIVE, run_id=BUILD_RUN,
        attempt=BUILD_ATTEMPT, artifact_id=ARTIFACT_ID, digest=ARTIFACT_DIGEST,
        version_name='0.13.8')
    require(type(run.get('run_attempt')) is int and run['run_attempt'] == BUILD_ATTEMPT,
            'Original build run attempt differs')
    require(run.get('repository', {}).get('id') == REPOSITORY_ID
            and run.get('head_commit', {}).get('id') == HOST
            and run.get('head_commit', {}).get('tree_id') == HOST_TREE,
            'Original build source tree or repository differs')
    artifact = next(row for row in artifact_rows if row['id'] == ARTIFACT_ID)
    require(type(artifact.get('size_in_bytes')) is int
            and artifact['size_in_bytes'] == ARTIFACT_BYTES
            and artifact['workflow_run'].get('repository_id') == REPOSITORY_ID
            and artifact['workflow_run'].get('head_repository_id') == REPOSITORY_ID,
            'Original artifact size or source repository differs')
    builders = [row for row in rows if row.get('name') == 'verify-and-build']
    require(len(builders) == 1, 'Exactly one original successful build is required')
    build = builders[0]
    require(build['id'] == BUILD_JOB and type(build.get('run_attempt')) is int
            and build['run_attempt'] == BUILD_ATTEMPT
            and build.get('status') == 'completed', 'Original successful build job differs')
    for name in BUILD_STEPS:
        steps = [step for step in build.get('steps', []) if step.get('name') == name]
        require(len(steps) == 1 and steps[0].get('status') == 'completed'
                and steps[0].get('conclusion') == 'success', 'Build evidence step did not succeed: ' + name)
    return {'host_source': HOST, 'tree': HOST_TREE, 'native_source': NATIVE,
            'run_id': BUILD_RUN, 'run_attempt': BUILD_ATTEMPT, 'build_job_id': BUILD_JOB,
            'workflow_path': CANDIDATE_WORKFLOW, 'run_status': run.get('status'),
            'run_conclusion': run.get('conclusion'), 'build_conclusion': build['conclusion'],
            'artifact_id': artifact['id'], 'artifact_name': artifact['name'],
            'artifact_bytes': artifact['size_in_bytes'], 'artifact_digest': artifact['digest'],
            'existing_c4_binding': binding,
            'archive_validation': 'Original API digest/size bound; complete artifact ZIP is not read by this preflight'}

def verify_qa(run: dict, jobs: dict, *, source: str, run_id: int, attempt: int, job_name: str) -> dict:
    require(isinstance(source, str) and re.fullmatch(r'[a-f0-9]{40}', source)
            and source != HOST, 'An explicit, distinct QA head SHA is required')
    require(type(run_id) is int and run_id > 0 and run_id != BUILD_RUN
            and type(attempt) is int and attempt > 0, 'Distinct QA run and attempt are required')
    require(job_name in QA_ROUTES, 'Unsupported diagnostic job name')
    workflow, branch = QA_ROUTES[job_name]
    require(run.get('id') == run_id and run.get('head_sha') == source
            and run.get('head_commit', {}).get('id') == source
            and type(run.get('run_attempt')) is int and run['run_attempt'] == attempt,
            'QA run source or attempt differs; use the PR head, not its merge SHA')
    require(run.get('repository', {}).get('full_name') == REPOSITORY
            and run.get('repository', {}).get('id') == REPOSITORY_ID
            and run.get('path') == workflow and run.get('head_branch') == branch
            and run.get('event') in ('push', 'workflow_dispatch'),
            'QA repository, workflow or branch differs')
    tree = run.get('head_commit', {}).get('tree_id')
    require(isinstance(tree, str) and re.fullmatch(r'[a-f0-9]{40}', tree), 'QA source tree is missing')
    rows = [row for row in complete_rows(jobs, 'jobs') if row.get('name') == job_name]
    require(len(rows) == 1, 'Exactly one original diagnostic job is required')
    job = rows[0]
    require(job.get('run_id') == run_id and job.get('head_sha') == source
            and type(job.get('run_attempt')) is int and job['run_attempt'] == attempt,
            'QA job source, run or attempt differs')
    return {'source': source, 'tree': tree, 'run_id': run_id, 'run_attempt': attempt,
            'workflow_path': workflow, 'branch': branch, 'job_id': job['id'],
            'job_name': job_name, 'run_status': run.get('status'),
            'run_conclusion': run.get('conclusion'), 'job_status': job.get('status'),
            'job_conclusion': job.get('conclusion')}


def git(source: Path, *arguments: str) -> bytes:
    result = subprocess.run(['git', '-C', str(source), *arguments], capture_output=True,
                            timeout=30, env={**os.environ, 'GIT_OPTIONAL_LOCKS': '0'})
    require(result.returncode == 0, 'Read-only Git source inspection failed')
    return result.stdout


def source_identity(source: Path, expected: str, tree: str) -> dict:
    require(source.is_dir() and not source.is_symlink(), 'Expected a real source checkout')
    source = source.resolve()
    require(Path(git(source, 'rev-parse', '--show-toplevel').decode().strip()).resolve() == source,
            'Source path is not its own Git checkout root')
    require(git(source, 'rev-parse', 'HEAD').decode().strip() == expected
            and git(source, 'rev-parse', 'HEAD^{tree}').decode().strip() == tree,
            'Actual Git source SHA or tree differs')
    require(not git(source, 'status', '--porcelain', '--untracked-files=no').strip(),
            'Tracked source checkout is dirty')
    return {'path': str(source), 'commit': expected, 'tree': tree, 'tracked_source_clean': True}


def committed_file(source: Path, relative: str) -> dict:
    path = regular(source / relative)
    require(path.is_relative_to(source.resolve()), 'Source file escapes its checkout')
    data = path.read_bytes()
    require(data == git(source, 'show', 'HEAD:' + relative), 'Source file differs from committed bytes: ' + relative)
    return {'path': relative, 'bytes': len(data), 'sha256': hashlib.sha256(data).hexdigest(),
            'git_blob': git(source, 'rev-parse', 'HEAD:' + relative).decode().strip()}


def verify_apk(apk: Path, provenance_path: Path, sums_path: Path, candidate_source: Path, tour) -> dict:
    apk, provenance_path, sums_path = map(regular, (apk, provenance_path, sums_path))
    before = apk.stat()
    require(before.st_size == APK_BYTES, 'Actual APK size differs from the original build')
    provenance = read_json(provenance_path)
    require(provenance.get('package') == PACKAGE and provenance.get('abis') == ['x86_64']
            and provenance.get('bytes') == APK_BYTES and provenance.get('sha256') == APK_SHA256
            and provenance.get('signingCertificateSha256') == CERTIFICATE
            and provenance.get('versionName') == '0.13.8' and provenance.get('versionCode') == 2020
            and provenance.get('flutter_source_commit') == HOST
            and provenance.get('tracked_source_clean') is True
            and provenance.get('elf16KiBAligned') is True and provenance.get('resourcesArscAligned') is True,
            'Original x86 APK build provenance differs')
    native = provenance.get('godot', {})
    require(native.get('revision') == NATIVE and native.get('pck_sha256') == PCK_SHA256
            and native.get('bytes') == PCK_BYTES and native.get('engine') == '4.6.3'
            and native.get('repository') == 'https://github.com/Ullmann27/lumo-godot.git',
            'Original embedded native identity differs')
    sums = [line.split(maxsplit=1) for line in sums_path.read_text().splitlines() if line.strip()]
    matches = [parts[0] for parts in sums if len(parts) == 2 and parts[1].strip().lstrip('*') == SUM_MEMBER]
    require(matches == [APK_SHA256], 'Build sums require exactly one unchanged x86 APK entry')
    previous = Path.cwd()
    try:
        os.chdir(candidate_source)
        identity = tour.verify_apk_identity(apk, provenance_path, sums_path)
    finally:
        os.chdir(previous)
    require(identity.get('apk_sha256') == APK_SHA256
            and identity.get('flutter_source_commit') == HOST
            and identity.get('godot_revision') == NATIVE,
            'Existing APK verifier did not bind the actual candidate checkout')
    with zipfile.ZipFile(apk) as archive:
        members = [info for info in archive.infolist() if info.filename == PCK_MEMBER]
        require(len(members) == 1, 'APK must contain one unambiguous embedded PCK')
        member = members[0]
        require(not member.is_dir() and not member.flag_bits & 1
                and stat.S_IFMT(member.external_attr >> 16) in (0, stat.S_IFREG)
                and member.file_size == PCK_BYTES, 'Embedded PCK entry is not the original regular file')
        with archive.open(member) as stream:
            digest = hashlib.file_digest(stream, 'sha256').hexdigest()
    require(digest == PCK_SHA256, 'Actual embedded PCK bytes differ')
    after = apk.stat()
    require((before.st_dev, before.st_ino, before.st_size, before.st_mtime_ns, before.st_ctime_ns)
            == (after.st_dev, after.st_ino, after.st_size, after.st_mtime_ns, after.st_ctime_ns),
            'APK changed during verification')
    return {'apk_sha256': APK_SHA256, 'apk_bytes': APK_BYTES,
            'pck_member': PCK_MEMBER, 'pck_sha256': digest, 'pck_bytes': member.file_size,
            'existing_apk_identity': identity,
            'certificate_scope': 'Original signer provenance bound by unchanged APK SHA; no new apksigner invocation'}


def verify_baseline(apk: Path, metadata_dir: Path) -> dict:
    apk = regular(apk)
    run, jobs, artifacts = [read_json(metadata_dir / name)
                            for name in ('run.json', 'jobs.json', 'artifacts.json')]
    require(run.get('id') == BASELINE['run'] and run.get('head_sha') == BASELINE['host']
            and type(run.get('run_attempt')) is int and run['run_attempt'] == BASELINE['attempt']
            and run.get('path') == BASELINE['workflow']
            and run.get('repository', {}).get('id') == REPOSITORY_ID
            and run.get('repository', {}).get('full_name') == REPOSITORY
            and run.get('head_commit', {}).get('id') == BASELINE['host']
            and run.get('head_commit', {}).get('tree_id') == BASELINE['tree'],
            'Original 2017 baseline run/source differs')
    builders = [row for row in complete_rows(jobs, 'jobs') if row.get('name') == 'verify-and-build']
    require(len(builders) == 1, 'Exactly one original baseline build is required')
    build = builders[0]
    require(build.get('id') == BASELINE['job'] and build.get('run_id') == BASELINE['run']
            and build.get('head_sha') == BASELINE['host']
            and type(build.get('run_attempt')) is int and build['run_attempt'] == BASELINE['attempt']
            and build.get('status') == 'completed' and build.get('conclusion') == 'success',
            'Original 2017 baseline build did not succeed')
    for name in BUILD_STEPS:
        steps = [row for row in build.get('steps', []) if row.get('name') == name]
        require(len(steps) == 1 and steps[0].get('status') == 'completed'
                and steps[0].get('conclusion') == 'success', 'Baseline evidence step failed: ' + name)
    found = [row for row in complete_rows(artifacts, 'artifacts')
             if row.get('name') == BASELINE['artifact_name']]
    require(len(found) == 1, 'Exactly one original 2017 baseline artifact is required')
    artifact = found[0]
    require(artifact.get('id') == BASELINE['artifact']
            and artifact.get('digest') == BASELINE['artifact_digest']
            and type(artifact.get('size_in_bytes')) is int
            and artifact['size_in_bytes'] == BASELINE['artifact_bytes']
            and artifact.get('expired') is False
            and artifact.get('workflow_run', {}).get('id') == BASELINE['run']
            and artifact['workflow_run'].get('head_sha') == BASELINE['host']
            and artifact['workflow_run'].get('repository_id') == REPOSITORY_ID
            and artifact['workflow_run'].get('head_repository_id') == REPOSITORY_ID,
            'Original 2017 baseline artifact differs')
    provenance = read_json(apk.parent / 'BUILD-PROVENANCE.json')
    require(apk.stat().st_size == BASELINE['apk_bytes']
            and file_digest(apk) == BASELINE['apk_sha256'],
            'Actual unchanged 2017 APK bytes differ')
    expected = {
        'package': PACKAGE, 'versionName': '0.13.5', 'versionCode': 2017,
        'abis': ['x86_64'], 'bytes': BASELINE['apk_bytes'], 'sha256': BASELINE['apk_sha256'],
        'signingCertificateSha256': CERTIFICATE, 'flutter_source_commit': BASELINE['host'],
        'tracked_source_clean': True, 'elf16KiBAligned': True, 'resourcesArscAligned': True,
    }
    require(all(provenance.get(key) == value and type(provenance.get(key)) is type(value)
                for key, value in expected.items()), 'Original 2017 APK provenance differs')
    native = provenance.get('godot', {})
    require(native == {'repository': 'https://github.com/Ullmann27/lumo-godot.git',
                       'revision': BASELINE['native'], 'engine': '4.6.3',
                       'pck_sha256': BASELINE['pck_sha256'], 'bytes': BASELINE['pck_bytes']},
            'Original 2017 embedded native provenance differs')
    with zipfile.ZipFile(apk) as archive:
        members = [entry for entry in archive.infolist() if entry.filename == PCK_MEMBER]
        require(len(members) == 1 and not members[0].is_dir() and not members[0].flag_bits & 1
                and stat.S_IFMT(members[0].external_attr >> 16) in (0, stat.S_IFREG)
                and members[0].file_size == BASELINE['pck_bytes'], 'Original 2017 PCK member differs')
        with archive.open(members[0]) as stream:
            require(hashlib.file_digest(stream, 'sha256').hexdigest() == BASELINE['pck_sha256'],
                    'Actual unchanged 2017 PCK bytes differ')
    return {**BASELINE, 'run_conclusion': run.get('conclusion'),
            'build_conclusion': build['conclusion'], 'apk_and_pck_bytes_verified': True}


def qa_inventory(qa: Path) -> list[dict]:
    paths = set(QA_FILES)
    tracked = git(qa, 'ls-files', '-z', '--', '.github/probes', 'scripts/probes', 'tools/android_qa')
    paths.update(name for name in tracked.decode().split(chr(0))
                 if name.endswith('.py') and '/tests/' not in name)
    require(all(name in paths for name in (
        '.github/probes/modernization_android_tour.py',
        '.github/probes/creative_android_probe.py',
        '.github/probes/lumo_2020_update_android_probe.py',
        '.github/probes/lumo_2003_update_android_probe.py',
        '.github/probes/lumo_learning_journey_probe.py',
        'tools/android_qa/kart_garage_evidence.py',
        'tools/android_qa/connect_four_android_evidence.py',
        'tools/android_qa/update_preservation.py',
        'tools/android_qa/update_artifact_identity.py',
    )), 'A required committed diagnostic observer is missing')
    return [committed_file(qa, relative) for relative in sorted(paths)]


def bind(args) -> dict:
    require(not args.qa_source.is_symlink() and not args.candidate_source.is_symlink(),
            'Source checkout paths must not be symlinks')
    qa, candidate = args.qa_source.resolve(), args.candidate_source.resolve()
    require(qa == ROOT and candidate != qa, 'Use this QA checkout and a distinct candidate checkout')
    update = args.qa_job_name == QA_JOBS[1]
    require((args.baseline is not None) == update
            and (args.baseline_metadata_dir is not None) == update,
            'Only the complete update case requires the original 2017 baseline')
    inputs = {f'candidate/{name}': args.candidate_metadata_dir / name
              for name in ('run.json', 'jobs.json', 'artifacts.json')}
    inputs.update({f'qa/{name}': args.qa_metadata_dir / name for name in ('run.json', 'jobs.json')})
    inputs.update(provenance=args.provenance, sums=args.sums)
    if update:
        inputs.update({f'baseline/{name}': args.baseline_metadata_dir / name
                       for name in ('run.json', 'jobs.json', 'artifacts.json')})
        inputs['baseline/provenance'] = args.baseline.parent / 'BUILD-PROVENANCE.json'
    input_hashes = {name: {'path': str(regular(path)), 'bytes': path.stat().st_size, 'sha256': file_digest(path)}
                    for name, path in inputs.items()}
    data = {name: read_json(path) for name, path in inputs.items() if name.endswith('.json')}
    qa_binding = verify_qa(data['qa/run.json'], data['qa/jobs.json'], source=args.expected_qa_source,
                           run_id=args.expected_qa_run, attempt=args.expected_qa_attempt, job_name=args.qa_job_name)
    sources = {'qa': source_identity(qa, qa_binding['source'], qa_binding['tree']),
               'candidate': source_identity(candidate, HOST, HOST_TREE)}
    source_files = {'qa': qa_inventory(qa), 'candidate': []}
    for name, source in (('qa', qa), ('candidate', candidate)):
        for relative in ('config/godot-source.json', 'pubspec.yaml'):
            source_files[name].append(committed_file(source, relative))
        pin = read_json(source / 'config/godot-source.json')
        require(pin.get('revision') == NATIVE
                and pin.get('repository') == 'https://github.com/Ullmann27/lumo-godot.git',
                'Source checkout native pin differs')
    sys.path.insert(0, str(qa / 'tools/android_qa'))
    c4 = load_module('unchanged_2020_c4_evidence', qa / 'tools/android_qa/connect_four_android_evidence.py')
    candidate_binding = verify_candidate(data['candidate/run.json'], data['candidate/jobs.json'],
                                         data['candidate/artifacts.json'], c4)
    tour = load_module('unchanged_2020_diagnostic_tour', qa / '.github/probes/modernization_android_tour.py')
    for module, relative in (
        (c4, 'tools/android_qa/connect_four_android_evidence.py'),
        (tour, '.github/probes/modernization_android_tour.py'),
        (tour.probe, '.github/probes/creative_android_probe.py'),
        (tour.base, 'scripts/probes/pr207_android_smoke.py'),
        (tour.live, 'scripts/probes/pr207_android_ui_probe.py'),
        (tour.garage_evidence, 'tools/android_qa/kart_garage_evidence.py'),
    ):
        require(Path(module.__file__).resolve() == (qa / relative).resolve(),
                'Imported observer is outside its bound QA checkout: ' + relative)
        committed_file(qa, relative)
    apk = verify_apk(args.apk, args.provenance, args.sums, candidate, tour)
    baseline = verify_baseline(args.baseline, args.baseline_metadata_dir) if update else None
    for name, path in inputs.items():
        require(path.stat().st_size == input_hashes[name]['bytes']
                and file_digest(path) == input_hashes[name]['sha256'], 'Diagnostic input changed: ' + name)
    for name, source in (('qa', qa), ('candidate', candidate)):
        source_identity(source, sources[name]['commit'], sources[name]['tree'])
        for entry in source_files[name]:
            require(committed_file(source, entry['path']) == entry, 'QA/source helper changed during verification')
    return {'schema': 1, 'status': 'BOUND',
            'scope': 'Source/metadata/APK/PCK preflight only; no Android or seven-job release acceptance',
            'candidate_build': candidate_binding, 'diagnostic_qa': qa_binding, 'git_sources': sources,
            'source_files': source_files, 'input_hashes': input_hashes, 'apk': apk, 'baseline': baseline,
            'required_probe_cwd': str(candidate), 'required_update_source_env': HOST,
            'not_tested': ['Android installation or input', 'completed 2017-to-2020 preservation',
                           'current device or emulator readiness', 'seven-job acceptance', 'release publication']}

def write_report(path: Path, report: dict) -> None:
    require(not path.exists() and not path.is_symlink(), 'Refusing to overwrite a diagnostic report')
    path.parent.mkdir(parents=True, exist_ok=True)
    encoded = (json.dumps(report, indent=2, sort_keys=True) + '\n').encode()
    temporary = None
    try:
        with tempfile.NamedTemporaryFile(dir=path.parent, prefix='.diagnostic-', delete=False) as stream:
            temporary = Path(stream.name)
            stream.write(encoded)
            stream.flush()
            os.fsync(stream.fileno())
        os.link(temporary, path)
    finally:
        if temporary is not None:
            temporary.unlink(missing_ok=True)


def main(argv=None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    for name in ('qa-source', 'candidate-source', 'candidate-metadata-dir', 'qa-metadata-dir',
                 'apk', 'provenance', 'sums', 'out'):
        parser.add_argument('--' + name, type=Path, required=True)
    parser.add_argument('--baseline', type=Path)
    parser.add_argument('--baseline-metadata-dir', type=Path)
    parser.add_argument('--expected-qa-source', required=True)
    parser.add_argument('--expected-qa-run', type=int, required=True)
    parser.add_argument('--expected-qa-attempt', type=int, required=True)
    parser.add_argument('--qa-job-name', choices=tuple(QA_ROUTES), required=True)
    args = parser.parse_args(argv)
    try:
        require(not args.out.exists() and not args.out.is_symlink(), 'Refusing to overwrite a diagnostic report')
        report = bind(args)
        write_report(args.out, report)
    except (OSError, ValueError, RuntimeError, zipfile.BadZipFile, subprocess.SubprocessError) as error:
        print('UNCHANGED_2020_APK_DIAGNOSTIC FAIL: ' + str(error), file=sys.stderr)
        return 1
    print('UNCHANGED_2020_APK_DIAGNOSTIC BOUND: APK source ' + HOST + '; QA source ' + args.expected_qa_source)
    return 0


if __name__ == '__main__':
    sys.dont_write_bytecode = True
    raise SystemExit(main())

