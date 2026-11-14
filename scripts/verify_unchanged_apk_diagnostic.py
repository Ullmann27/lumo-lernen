#!/usr/bin/env python3
"""Bind repaired QA to the unchanged, already built 7b16 APK.

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
HOST = '7b16f2f5ab16f3d913ee170aefd9807c87216260'
HOST_TREE = 'fe430b86449e4f4e221cadfc802f42db639f3133'
NATIVE = '17f5b9d4a14c70050d4a125a8bd6bd8c68ee7845'
BUILD_RUN = 43540111465
BUILD_JOB = 132278438809
BUILD_ATTEMPT = 1
CANDIDATE_WORKFLOW = '.github/workflows/lumo-kart-graphics-2019.yml'
ARTIFACT_ID = 14093773196
ARTIFACT_BYTES = 648186489
ARTIFACT_DIGEST = 'sha256:3f613c64c78c2b20dd0a91741627ab93a418a66bfc6df6292b041f06c36c2e30'
APK_BYTES = 325657350
APK_SHA256 = 'cf60f0cc3fac67408b84b75722c3a656a6bb0e09d2299894227ae5ba969efe20'
PCK_BYTES = 66595192
PCK_SHA256 = '04acb69c117bc245186a65cb35d8b392d3846df7222bf6de610f8abce7da368d'
PCK_MEMBER = 'assets/lumo_game.pck'
SUM_MEMBER = 'dist/x86_64/Lumo-Lernen-Neu.apk'
PACKAGE = 'dev.ullmann.lumo.lumo_lernen.coachpreview'
CERTIFICATE = 'a6b1ef61bf59db4e0794c742aeb3b5506d130f4d21175c9975140e6acdb80702'
QA_WORKFLOW = '.github/workflows/lumo-unchanged-apk-diagnostic.yml'
QA_BRANCH = 'qa/lumo-android-runtime-7b16-20261114'
QA_JOBS = (
    'unchanged-apk-api35', 'unchanged-apk-api37-host',
    'unchanged-apk-api37-swiftshader', 'unchanged-apk-update2017',
)
CREATIVE_QA_WORKFLOW = '.github/workflows/lumo-creative-7b16-diagnostic.yml'
CREATIVE_QA_BRANCH = 'qa/lumo-creative-7b16-20261114'
CREATIVE_QA_JOB = 'unchanged-apk-creative-api35'
FOLLOWUP_QA_WORKFLOW = '.github/workflows/lumo-android-runtime-7b16-followup.yml'
FOLLOWUP_QA_BRANCH = 'qa/lumo-android-runtime-7b16-followup-20261114'
FOLLOWUP_QA_JOBS = (
    'unchanged-apk-followup-api35', 'unchanged-apk-followup-api37-host',
    'unchanged-apk-followup-api37-swiftshader', 'unchanged-apk-followup-api37-swangle',
    'unchanged-apk-followup-update2017',
)
CONSOLE_JOYSTICK_QA_WORKFLOW = '.github/workflows/lumo-console-joystick-7b16.yml'
CONSOLE_JOYSTICK_QA_BRANCH = 'qa/lumo-console-joystick-7b16-20261114'
CONSOLE_JOYSTICK_CREATIVE_JOB = 'unchanged-apk-console-joystick-creative-api35'
CONSOLE_JOYSTICK_QA_JOBS = (
    'unchanged-apk-console-joystick-api37-host',
    'unchanged-apk-console-joystick-api37-swiftshader',
    'unchanged-apk-console-joystick-api37-swangle',
    CONSOLE_JOYSTICK_CREATIVE_JOB,
)
CONSOLE_START_QA_WORKFLOW = '.github/workflows/lumo-console-start-7b16.yml'
CONSOLE_START_QA_BRANCH = 'qa/lumo-console-start-7b16-20261114'
CONSOLE_START_QA_JOBS = (
    'unchanged-apk-console-start-api37-host',
    'unchanged-apk-console-start-api37-swiftshader',
    'unchanged-apk-console-start-api37-swangle',
)
CREATIVE_QA_JOBS = (CREATIVE_QA_JOB, CONSOLE_JOYSTICK_CREATIVE_JOB)
QA_ROUTES = {name: (QA_WORKFLOW, QA_BRANCH) for name in QA_JOBS}
QA_ROUTES[CREATIVE_QA_JOB] = (CREATIVE_QA_WORKFLOW, CREATIVE_QA_BRANCH)
QA_ROUTES.update({name: (FOLLOWUP_QA_WORKFLOW, FOLLOWUP_QA_BRANCH)
                  for name in FOLLOWUP_QA_JOBS})
QA_ROUTES.update({name: (CONSOLE_JOYSTICK_QA_WORKFLOW, CONSOLE_JOYSTICK_QA_BRANCH)
                  for name in CONSOLE_JOYSTICK_QA_JOBS})
QA_ROUTES.update({name: (CONSOLE_START_QA_WORKFLOW, CONSOLE_START_QA_BRANCH)
                  for name in CONSOLE_START_QA_JOBS})
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


def read_json(path: Path) -> dict:
    value = json.loads(regular(path).read_bytes(), object_pairs_hook=unique_object)
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


def verify_candidate(run: dict, jobs: dict, artifacts: dict, creative) -> dict:
    rows = complete_rows(jobs, 'jobs')
    complete_rows(artifacts, 'artifacts')
    binding = creative.verify_candidate_metadata(run, artifacts, jobs, {
        'host_source': HOST, 'native_source': NATIVE, 'build_run': BUILD_RUN,
        'artifact_id': ARTIFACT_ID, 'artifact_digest': ARTIFACT_DIGEST,
        'workflow_path': CANDIDATE_WORKFLOW,
    })
    require(type(run.get('run_attempt')) is int and run['run_attempt'] == BUILD_ATTEMPT,
            'Original build run attempt differs')
    require(run.get('repository', {}).get('id') == REPOSITORY_ID
            and run.get('head_commit', {}).get('id') == HOST
            and run.get('head_commit', {}).get('tree_id') == HOST_TREE,
            'Original build source tree or repository differs')
    artifact = binding['artifact']
    require(artifact['size_in_bytes'] == ARTIFACT_BYTES
            and artifact['workflow_run'].get('repository_id') == REPOSITORY_ID
            and artifact['workflow_run'].get('head_repository_id') == REPOSITORY_ID,
            'Original artifact size or source repository differs')
    build = next(row for row in rows if row['id'] == binding['build_job_id'])
    require(build['id'] == BUILD_JOB and type(build.get('run_attempt')) is int
            and build['run_attempt'] == BUILD_ATTEMPT, 'Original successful build job differs')
    for name in BUILD_STEPS:
        steps = [step for step in build.get('steps', []) if step.get('name') == name]
        require(len(steps) == 1 and steps[0].get('status') == 'completed'
                and steps[0].get('conclusion') == 'success', 'Build evidence step did not succeed: ' + name)
    # Overall Android failures are neither discarded nor turned into build failures.
    return {'host_source': HOST, 'tree': HOST_TREE, 'native_source': NATIVE,
            'run_id': BUILD_RUN, 'run_attempt': BUILD_ATTEMPT, 'build_job_id': BUILD_JOB,
            'workflow_path': CANDIDATE_WORKFLOW, 'run_status': run.get('status'),
            'run_conclusion': run.get('conclusion'), 'build_conclusion': build['conclusion'],
            'artifact_id': artifact['id'], 'artifact_name': artifact['name'],
            'artifact_bytes': artifact['size_in_bytes'], 'artifact_digest': artifact['digest'],
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
            and run.get('path') == workflow and run.get('head_branch') == branch,
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
            and provenance.get('versionName') == '0.13.7' and provenance.get('versionCode') == 2019
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


def bind(args) -> dict:
    require(not args.qa_source.is_symlink() and not args.candidate_source.is_symlink(),
            'Source checkout paths must not be symlinks')
    qa, candidate = args.qa_source.resolve(), args.candidate_source.resolve()
    require(qa == ROOT and candidate != qa, 'Use this QA checkout and a distinct candidate checkout')
    inputs = {f'candidate/{name}': args.candidate_metadata_dir / name
              for name in ('run.json', 'jobs.json', 'artifacts.json')}
    inputs.update({f'qa/{name}': args.qa_metadata_dir / name for name in ('run.json', 'jobs.json')})
    inputs.update(provenance=args.provenance, sums=args.sums)
    input_hashes = {name: {'path': str(regular(path)), 'bytes': path.stat().st_size, 'sha256': file_digest(path)}
                    for name, path in inputs.items()}
    data = {name: read_json(path) for name, path in inputs.items() if name.endswith('.json')}
    qa_binding = verify_qa(data['qa/run.json'], data['qa/jobs.json'], source=args.expected_qa_source,
                           run_id=args.expected_qa_run, attempt=args.expected_qa_attempt, job_name=args.qa_job_name)
    sources = {'qa': source_identity(qa, qa_binding['source'], qa_binding['tree']),
               'candidate': source_identity(candidate, HOST, HOST_TREE)}
    own = committed_file(qa, 'scripts/verify_unchanged_apk_diagnostic.py')
    creative = load_module('unchanged_diagnostic_creative', qa / '.github/probes/studio_creative_android_probe.py')
    creative.committed_helper(qa, creative, '.github/probes/studio_creative_android_probe.py')
    candidate_binding = verify_candidate(data['candidate/run.json'], data['candidate/jobs.json'],
                                         data['candidate/artifacts.json'], creative)
    source_files = {'qa': [own], 'candidate': []}
    for name, source in (('qa', qa), ('candidate', candidate)):
        for relative in ('config/godot-source.json', 'pubspec.yaml'):
            source_files[name].append(committed_file(source, relative))
        pin = read_json(source / 'config/godot-source.json')
        require(pin.get('revision') == NATIVE
                and pin.get('repository') == 'https://github.com/Ullmann27/lumo-godot.git',
                'Source checkout native pin differs')
    tour = load_module('unchanged_diagnostic_tour', qa / '.github/probes/modernization_android_tour.py')
    for module, relative in (
        (creative, '.github/probes/studio_creative_android_probe.py'),
        (tour, '.github/probes/modernization_android_tour.py'),
        (tour.probe, '.github/probes/creative_android_probe.py'),
        (tour.base, 'scripts/probes/pr207_android_smoke.py'),
    ):
        creative.committed_helper(qa, module, relative)
        source_files['qa'].append(committed_file(qa, relative))
    apk = verify_apk(args.apk, args.provenance, args.sums, candidate, tour)
    for name, path in inputs.items():
        require(path.stat().st_size == input_hashes[name]['bytes']
                and file_digest(path) == input_hashes[name]['sha256'], 'Diagnostic input changed: ' + name)
    for name, source in (('qa', qa), ('candidate', candidate)):
        source_identity(source, sources[name]['commit'], sources[name]['tree'])
        for entry in source_files[name]:
            require(committed_file(source, entry['path']) == entry, 'QA/source helper changed during verification')
    return {'schema': 1, 'status': 'BOUND', 'scope': 'Source/metadata/APK/PCK preflight only; no Android or release acceptance',
            'candidate_build': candidate_binding, 'diagnostic_qa': qa_binding, 'git_sources': sources,
            'source_files': source_files, 'input_hashes': input_hashes, 'apk': apk,
            'required_probe_cwd': str(candidate), 'required_update_source_env': HOST,
            'not_tested': ['Android installation or input', '2017-to-2019 preservation',
                           'current device or emulator readiness', 'release publication']}


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
        print('UNCHANGED_APK_DIAGNOSTIC FAIL: ' + str(error), file=sys.stderr)
        return 1
    print('UNCHANGED_APK_DIAGNOSTIC BOUND: APK source ' + HOST + '; QA source ' + args.expected_qa_source)
    return 0


if __name__ == '__main__':
    sys.dont_write_bytecode = True
    raise SystemExit(main())
