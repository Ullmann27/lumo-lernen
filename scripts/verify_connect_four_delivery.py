#!/usr/bin/env python3
"""Prepare a verified C4 bundle and separately verify a future new 2020 release.

This program performs no GitHub writes. The ordinary CI job only prepares a
bundle. A separate, explicitly credentialed publication procedure may use the
checked inputs after that entire workflow succeeds. Historical 2019 receipts
never authorize this path, and bundle preparation never means publication.
"""
from __future__ import annotations

import argparse
import hashlib
import importlib.util
import json
import os
from pathlib import Path, PurePosixPath
import re
import shlex
import shutil
import stat
import subprocess
import sys
import tempfile
import zipfile

ROOT = Path(__file__).resolve().parents[1]
REPOSITORY = 'Ullmann27/lumo-lernen'
WORKFLOW = '.github/workflows/lumo-connect-four-2020.yml'
BRANCH = 'integration/lumo-c4-connections-20261114'
QUALITY_BRANCH = 'work/lumo-play-quality-20261114'
ACCEPTED_BRANCHES = frozenset((BRANCH, QUALITY_BRANCH))
DELIVERY_JOB = 'prepare-c4-delivery'
BUNDLE_ARTIFACT = 'lumo-connect-four-2020-delivery-bundle'
LEARNING_AUDIT_ARTIFACT = 'lumo-connect-four-2020-learning-curriculum-audit'
LEARNING_AUDIT_STEP = 'Audit every exact current-grade learning family on this candidate'
LEARNING_AUDIT_FILES = (
    'summary.json', 'task-families.json', 'task-samples.jsonl', 'issues.json',
    'audit.stdout.log', 'audit.stderr.log',
)
LEARNING_AUDIT_SOURCES = (
    'lib/core/school_exercise_generator.dart',
    'tools/audit_learning_tasks_all_grades.dart',
    'test/learning/learning_exact_selection_test.dart',
    'pubspec.yaml', 'pubspec.lock', '.github/workflows/lumo-connect-four-2020.yml',
)
DELIVERY_ASSETS = {
    'Lumo-Lernen-Neu.apk', 'Lumo-Lernen-Neu.apk.sha256',
    'BUILD-PROVENANCE.json', 'GODOT-SOURCE.json', 'C4-CANDIDATE-FACTS.json',
    'C4-ANDROID-RESULT.json', 'C4-DESKTOP-RUNTIME.json', 'UPDATE-2020-RESULT.json',
    'C4-DELIVERY-FACTS.json', 'PUBLISH-VERIFICATION.json',
}
REQUIRED_STEPS = {
    'connect-four-runtime': (
        'Import the exact configured native source in its own directory',
        'Require the actual production Dart and rendered Godot two-process gate',
    ),
    'android-host-compile': (
        'Compile actual current Android host before native release pin approval',
        'Bind actual compiled C4 Activity bridge and Binder bytecode',
    ),
    'verify-and-build': (
        LEARNING_AUDIT_STEP,
        'Full Flutter regression suite including every capture',
        'Verify all build and preservation contracts',
        'Code-level Android probe regression with verified image dependencies',
        'Require actual gameplay gates on the exact pinned native source',
        'Require acknowledged Connect Four return retry',
        'Build unified real Android APK',
        'Verify APK archive and collect reproducible source hashes',
        'Upload exact candidate (no release or synthetic screenshots)',
    ),
    'android-c4': ('Install and tour the exact APK',),
    'update-2020-from-2017': (
        'Preserve actual 2017 learning through an in-place 2020 upgrade',
    ),
    'verify-c4-candidate': (
        'Reverify both signed APKs and every mandatory current C4 and update proof',
    ),
}
ARTIFACT_NAMES = (
    'lumo-connect-four-2020-candidate',
    'lumo-connect-four-2020-desktop-runtime',
    'lumo-connect-four-2020-android-host-compile',
    'lumo-connect-four-2020-android-c4',
    'lumo-connect-four-2020-in-place-update-proof',
    'lumo-connect-four-2020-candidate-verification',
    'lumo-connect-four-2020-build-contracts',
    'lumo-candidate-pinned-native-gameplay',
    LEARNING_AUDIT_ARTIFACT,
)
PCM_CONTRACTS = {
    'test_original_pcm_envelope_contract':
        'LUMO_SPEECH_ENVELOPE_PASS checks=23 original_apfel_duration_ms=929 bins=47',
    'test_original_learning_lifecycle_contract':
        'LUMO_SPEECH_LIFECYCLE_PASS checks=17 platform=synthetic_JVM_boundary no_Android_playback_claim=true',
    'test_build_consent_rate_and_activity_contract':
        'LUMO_BUILD_SPEECH_PASS checks=30 platform=synthetic_JVM_boundary no_Android_playback_claim=true',
}
NEW_NATIVE = {
    ('lumo_facial_regression', 'headless'),
    ('lumo_facial_capture', 'rendered'),
    ('connect_four_visual_capture', 'rendered'),
    ('treasure_title_contrast_regression', 'rendered'),
}
ERROR_LINE = re.compile(r'SCRIPT ERROR|Parse Error|ERROR:|Assertion failed|'
                        r'ObjectDB instances leaked|resources still in use at exit')


def require(condition: bool, message: str) -> None:
    if not condition:
        raise ValueError(message)


def regular(path: Path) -> Path:
    require(path.is_file() and not path.is_symlink(), 'Original regular file required: ' + str(path))
    return path


def digest(path: Path) -> str:
    with regular(path).open('rb') as handle:
        return hashlib.file_digest(handle, 'sha256').hexdigest()


def record(path: Path) -> dict:
    return {'bytes': regular(path).stat().st_size, 'sha256': digest(path)}


def read(path: Path):
    def unique(pairs):
        result = {}
        for key, value in pairs:
            require(key not in result, 'Duplicate original JSON key: ' + key)
            result[key] = value
        return result
    return json.loads(regular(path).read_bytes(), object_pairs_hook=unique,
                      parse_constant=lambda value: (_ for _ in ()).throw(ValueError(value)))


def write_new(path: Path, value) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open('x', encoding='utf-8') as handle:
        handle.write(json.dumps(value, indent=2, sort_keys=True) + '\n')


def checked_jobs(run: dict, jobs: dict, pull: dict, binding: dict, pr_number: int,
                 *, publication: bool = False) -> dict:
    source, run_id, attempt = (binding['host_source'], binding['run_id'], binding['run_attempt'])
    branch = run.get('head_branch')
    require(run.get('id') == run_id and run.get('run_attempt') == attempt
            and run.get('head_sha') == source and branch in ACCEPTED_BRANCHES
            and run.get('path') == WORKFLOW and run.get('event') == 'pull_request'
            and run.get('repository', {}).get('full_name') == REPOSITORY
            and run.get('status') == ('completed' if publication else 'in_progress')
            and run.get('conclusion') == ('success' if publication else None),
            'Delivery requires the corresponding exact C4 workflow phase/attempt')
    require(pull.get('number') == pr_number and pull.get('state') == 'open'
            and pull.get('head', {}).get('sha') == source
            and pull.get('head', {}).get('ref') == branch
            and pull.get('head', {}).get('repo', {}).get('full_name') == REPOSITORY
            and pull.get('base', {}).get('repo', {}).get('full_name') == REPOSITORY,
            'The current same-repository C4 pull request moved or closed')
    rows = jobs.get('jobs', [])
    require(isinstance(rows, list) and jobs.get('total_count') == len(rows),
            'Incomplete original workflow job list')
    result = {}
    for name, required_steps in REQUIRED_STEPS.items():
        found = [row for row in rows if row.get('name') == name]
        require(len(found) == 1, 'Missing or duplicate mandatory job: ' + name)
        job = found[0]
        require(job.get('run_id') == run_id and job.get('head_sha') == source
                and job.get('run_attempt') == attempt and job.get('status') == 'completed'
                and job.get('conclusion') == 'success', 'Mandatory current job failed: ' + name)
        steps = job.get('steps', [])
        require(isinstance(steps, list) and steps
                and all(step.get('conclusion') in ('success', 'skipped') for step in steps),
                'A mandatory job contains an unsuccessful original step: ' + name)
        for label in required_steps:
            selected = [step for step in steps if step.get('name') == label]
            require(len(selected) == 1 and selected[0].get('status') == 'completed'
                    and selected[0].get('conclusion') == 'success',
                    'Actual required step missing or skipped: ' + label)
        result[name] = {'id': job['id'], 'completed_at': job.get('completed_at'),
                        'required_steps': list(required_steps)}
    delivery = [row for row in rows if row.get('name') == DELIVERY_JOB]
    require(len(delivery) == 1 and delivery[0].get('run_id') == run_id
            and delivery[0].get('head_sha') == source
            and delivery[0].get('run_attempt') == attempt
            and delivery[0].get('status') == ('completed' if publication else 'in_progress')
            and delivery[0].get('conclusion') == ('success' if publication else None),
            'The exact read-only delivery preparation has not reached its required phase')
    require(len(rows) == len(REQUIRED_STEPS) + 1
            and {row.get('name') for row in rows} == {*REQUIRED_STEPS, DELIVERY_JOB},
            'Unexpected C4 job set requires an explicit delivery-contract update')
    if publication:
        for label in (
            'Reverify actual current APKs C4 update PCM and complete native originals',
            'Preserve the complete verified 2020 ARM64 delivery bundle without publication',
        ):
            matches = [step for step in delivery[0].get('steps', []) if step.get('name') == label]
            require(len(matches) == 1 and matches[0].get('status') == 'completed'
                    and matches[0].get('conclusion') == 'success',
                    'The actual delivery replay/upload was not successful: '+label)
    return result


def checked_artifacts(metadata: dict, binding: dict) -> dict:
    rows = metadata.get('artifacts', [])
    require(isinstance(rows, list) and metadata.get('total_count') == len(rows),
            'Incomplete original artifact list')
    result = {}
    for name in ARTIFACT_NAMES:
        matches = [row for row in rows if row.get('name') == name]
        require(len(matches) == 1, 'Missing or duplicate required original artifact: ' + name)
        row = matches[0]
        require(type(row.get('id')) is int and row['id'] > 0
                and type(row.get('size_in_bytes')) is int and row['size_in_bytes'] > 0
                and row.get('expired') is False
                and re.fullmatch(r'sha256:[a-f0-9]{64}', str(row.get('digest')))
                and row.get('workflow_run', {}).get('id') == binding['run_id']
                and row.get('workflow_run', {}).get('head_sha') == binding['host_source'],
                'Required original artifact has wrong source/run/digest: ' + name)
        result[name] = {key: row[key] for key in ('id', 'name', 'size_in_bytes', 'digest')}
    candidate = result[ARTIFACT_NAMES[0]]
    require(candidate['id'] == binding['candidate_artifact_id']
            and candidate['digest'] == binding['candidate_artifact_digest'],
            'Delivery candidate differs from tested upload')
    return result


def checked_pcm_log(path: Path) -> dict:
    text = regular(path).read_text(encoding='utf-8')
    totals = re.findall(r'^Ran (\d+) tests? in [0-9.]+s$', text, re.M)
    require(len(totals) == 1 and int(totals[0]) > 0
            and len(re.findall(r'^OK$', text, re.M)) == 1
            and not re.search(r'^(?:FAILED|ERROR: |FAIL: |OK \(skipped=)', text, re.M)
            and not re.search(r'\.\.\. skipped\b', text),
            'The original full scripts contract suite is incomplete, failed or skipped')
    for method, marker in PCM_CONTRACTS.items():
        line = method + ' (test_speech_envelope_contract.SpeechEnvelopeContractTest.' + method + ') ... ok'
        require(text.splitlines().count(line) == 1 and text.splitlines().count(marker) == 1,
                'The exact actual current PCM/JVM contract is missing: ' + method)
    return {'tests': int(totals[0]), 'skips': 0, 'pcm_assertions': 70,
            'scope': 'Synthetic JVM boundary compiled from current production Kotlin; no Android audio claim',
            'original_log': record(path), 'required_markers': list(PCM_CONTRACTS.values())}


def learning_source_identity(source: str) -> dict:
    require(re.fullmatch(r'[a-f0-9]{40}', source), 'Invalid learning audit source')
    head = subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT, text=True).strip()
    tree = subprocess.check_output(['git', 'rev-parse', 'HEAD^{tree}'], cwd=ROOT, text=True).strip()
    require(head == source, 'Learning audit checkout differs from the current candidate')
    # All tracked imports/data banks must stay at the same committed source.
    # Untracked audit output is expected and is not an alternative source tree.
    subprocess.run(['git', 'diff', '--exit-code', 'HEAD', '--'], cwd=ROOT, check=True)
    sources = {}
    for relative in LEARNING_AUDIT_SOURCES:
        path = regular(ROOT/relative)
        require(path.read_bytes() == subprocess.check_output(['git', 'show', source+':'+relative], cwd=ROOT),
                'Learning audit executable source changed: '+relative)
        sources[relative] = record(path)
    return {'commit': head, 'tree': tree, 'files': sources}


def checked_learning_outputs(root: Path) -> dict:
    summary, families, issues = (read(root/name) for name in
                                  ('summary.json', 'task-families.json', 'issues.json'))
    require(isinstance(summary, dict) and summary.get('status') == 'SAMPLED_CONTRACT_PASS'
            and summary.get('grades') == [1, 2, 3, 4]
            and all(type(grade) is int for grade in summary['grades'])
            and type(summary.get('familyCount')) is int and summary['familyCount'] == 236
            and type(summary.get('generatedSamples')) is int and summary['generatedSamples'] == 7552
            and type(summary.get('issues')) is int and summary['issues'] == 0 and issues == []
            and all(summary.get(flag) is False for flag in
                    ('allExistingTasksReviewed', 'officialCurriculumApproval', 'allVariantsEnumerated')),
            'Current learning audit requires all 236 families/7552 structural samples without curriculum approval')
    require(read(root/'audit.stdout.log') == summary,
            'Original Dart audit stdout differs from its original summary')
    require(isinstance(families, list) and len(families) == 236,
            'Current learning family roster is incomplete')
    roster = set()
    for row in families:
        require(isinstance(row, dict) and type(row.get('grade')) is int and row['grade'] in (1, 2, 3, 4)
                and all(isinstance(row.get(key), str) and row[key].strip() for key in ('subject', 'unit'))
                and type(row.get('generatedSamples')) is int and row['generatedSamples'] == 32
                and row.get('allVariantsEnumerated') is False, 'Invalid original learning family')
        key = (row['grade'], row['subject'], row['unit'])
        require(key not in roster, 'Duplicate original learning family')
        roster.add(key)
    require({key[0] for key in roster} == {1, 2, 3, 4}, 'Learning audit omits a school grade')
    expected = {(*key, seed, attempt) for key in roster for seed in (0, 1, 17, 1937) for attempt in range(8)}
    seen = set()
    def unique(pairs):
        result = {}
        for key, value in pairs:
            require(key not in result, 'Duplicate original learning sample JSON key')
            result[key] = value
        return result
    with regular(root/'task-samples.jsonl').open(encoding='utf-8') as handle:
        for line in handle:
            require(line.strip(), 'Blank line cannot substitute an original learning sample')
            row = json.loads(line, object_pairs_hook=unique,
                             parse_constant=lambda value: (_ for _ in ()).throw(ValueError(value)))
            require(isinstance(row, dict)
                    and all(type(row.get(key)) is int for key in ('grade', 'seed', 'attempt'))
                    and all(isinstance(row.get(key), str) and row[key].strip()
                            for key in ('subject', 'unit', 'prompt', 'answer', 'explanation'))
                    and isinstance(row.get('choices'), list)
                    and all(isinstance(choice, str) for choice in row['choices'])
                    and len(set(row['choices'])) == len(row['choices'])
                    and (not row['choices'] or row['answer'] in row['choices'])
                    and row.get('issues') == [] and row.get('semanticCurriculumReview') == 'pending'
                    and row.get('threeDSceneApproval') is False,
                    'Original learning sample has a structural defect or overstates review')
            key = tuple(row[name] for name in ('grade', 'subject', 'unit', 'seed', 'attempt'))
            require(key in expected and key not in seen, 'Missing-family or duplicate original learning sample')
            seen.add(key)
    require(seen == expected, 'Original learning samples omit a required family/seed/attempt')
    return {'family_count': len(roster), 'generated_samples': len(seen), 'structural_issues': 0,
            'official_curriculum_approval': False, 'all_variants_enumerated': False,
            'scope': 'Current core ExerciseFactory samples only; no semantic, Android or 3D approval',
            'originals': {name: record(root/name) for name in LEARNING_AUDIT_FILES}}


def bind_learning_audit(root: Path, source: str, run_id: int, attempt: int) -> dict:
    require(type(run_id) is int and run_id > 0 and type(attempt) is int and attempt > 0,
            'Learning audit requires the actual positive run and attempt')
    require(not (root/'source-binding.json').exists(), 'Refusing to overwrite an existing learning audit binding')
    source_identity = learning_source_identity(source)
    checked = checked_learning_outputs(root)
    binding = {'schema': 1, 'kind': 'c4_current_learning_audit', 'repository': REPOSITORY,
               'workflow': WORKFLOW, 'job': 'verify-and-build', 'run_id': run_id, 'run_attempt': attempt,
               'host_source': source, 'source': source_identity, 'originals': checked['originals']}
    write_new(root/'source-binding.json', binding)
    return checked


def checked_learning_audit(root: Path, binding: dict) -> dict:
    original = read(root/'source-binding.json')
    require(isinstance(original, dict) and original.get('schema') == 1
            and original.get('kind') == 'c4_current_learning_audit'
            and original.get('repository') == REPOSITORY and original.get('workflow') == WORKFLOW
            and original.get('job') == 'verify-and-build'
            and original.get('host_source') == binding['host_source']
            and type(original.get('run_id')) is int and original['run_id'] == binding['run_id']
            and type(original.get('run_attempt')) is int and original['run_attempt'] == binding['run_attempt']
            and original.get('source') == learning_source_identity(binding['host_source']),
            'Learning audit source/tree/run/attempt differs from the current C4 candidate')
    checked = checked_learning_outputs(root)
    require(original.get('originals') == checked['originals'], 'Original learning audit output bytes changed')
    return {**checked, 'source': original['source'], 'binding': record(root/'source-binding.json')}


def checked_release_catalog(pages, refs, facts: dict) -> dict:
    from release_pipeline_gates import (evaluate_source, newest_published_family_build)
    require(isinstance(pages, list) and pages and all(isinstance(page, list) for page in pages),
            'The complete paginated original release catalog is required')
    require(isinstance(refs, list), 'Original matching tag refs must be an array')
    releases = [item for page in pages for item in page]
    require(all(isinstance(item, dict) for item in releases), 'Invalid original release object')
    tag = 'coachpreview-build-' + str(facts['versionCode'])
    require(not any(item.get('tag_name') == tag for item in releases),
            'Version release already exists; never reuse, overwrite or repair it in place')
    require(not any(item.get('ref') == 'refs/tags/' + tag for item in refs),
            'Version tag already exists; no replacement or verify-existing publication')
    result = evaluate_source(pubspec_text='version: '+facts['versionName']+'+'+str(facts['versionCode'])+'\n',
                             last_published=newest_published_family_build(releases))
    require(result['versionCode'] == 2020, 'This separate delivery accepts only the actual 2020 version')
    return result


def checked_tag(tag: dict, plan: dict) -> None:
    require(tag.get('ref') == 'refs/tags/' + plan['tag']
            and tag.get('object', {}).get('type') == 'commit'
            and tag.get('object', {}).get('sha') == plan['host_source'],
            'New version tag does not identify the exact verified Host commit')


def checked_release(release: dict, tag: dict, created: dict, plan: dict, stage: str) -> dict:
    require(stage in ('empty-draft', 'uploaded-draft', 'published'), 'Unknown publication stage')
    checked_tag(tag, plan)
    expected_id = created.get('id')
    require(type(expected_id) is int and expected_id > 0 and release.get('id') == expected_id
            and created.get('tag_name') == release.get('tag_name') == plan['tag']
            and created.get('target_commitish') == release.get('target_commitish') == plan['host_source']
            and created.get('draft') is True and created.get('prerelease') is True
            and release.get('prerelease') is True
            and release.get('draft') is (stage != 'published'),
            'The newly created release identity/state/source differs')
    upload_url = 'https://uploads.github.com/repos/'+REPOSITORY+'/releases/'+str(expected_id)+'/assets{?name,label}'
    require(created.get('upload_url') == release.get('upload_url') == upload_url,
            'Original release upload relation differs from the exact new repository/release')
    require(created.get('assets') == [], 'The creation response was not a fresh empty draft')
    rows = release.get('assets')
    require(isinstance(rows, list), 'Original uploaded asset objects are missing')
    expected = {} if stage == 'empty-draft' else plan['assets']
    require(len(rows) == len(expected)
            and {row.get('name') for row in rows} == set(expected)
            and len({row.get('id') for row in rows}) == len(rows),
            'New release asset set differs from the exact verified input set')
    for asset in rows:
        name = asset['name']
        require(asset.get('state') == 'uploaded' and type(asset.get('id')) is int
                and asset['id'] > 0 and asset.get('size') == expected[name]['bytes']
                and asset.get('digest') == 'sha256:' + expected[name]['sha256']
                and asset.get('browser_download_url') ==
                'https://github.com/'+REPOSITORY+'/releases/download/'+plan['tag']+'/'+name,
                'Actual uploaded asset digest/size/direct URL differs: ' + name)
    if stage == 'published':
        require(isinstance(release.get('published_at'), str) and release['published_at'],
                'Published release timestamp is missing')
    immutable = release.get('immutable')
    require(immutable is None or type(immutable) is bool, 'Malformed GitHub immutable flag')
    return {'release_id': expected_id, 'tag': plan['tag'], 'stage': stage,
            'github_immutable': immutable,
            'no_replacement_policy': True,
            'direct_apk_url': plan['download_url']}


def native_module(root: Path, name: str):
    sys.path.insert(0, str(root/'tools'))
    path = regular(root/'tools'/name)
    spec = importlib.util.spec_from_file_location('_c4_delivery_'+path.stem, path)
    loaded = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = loaded
    spec.loader.exec_module(loaded)
    return loaded


def checked_native_results(root: Path, runner: str) -> list[dict]:
    # The actual facial command spans three physical shell lines. A shell
    # backslash/newline is one logical command, never a second probe.
    logical = runner.replace(chr(92) + chr(10), ' ')
    roster = [shlex.split(line)[1:4] for line in logical.splitlines() if line.startswith('check_probe ')]
    require(len(roster) == 52 and all(len(row) == 3 for row in roster)
            and len({(row[0], row[2]) for row in roster}) == 52
            and NEW_NATIVE <= {(row[0], row[2]) for row in roster},
            'Approved source must contain all 52 current native modes, including the four new modes')
    results = regular(root/'results.tsv').read_text().splitlines()
    expected = ['probe\tmode\tresult', *[name+'\t'+mode+'\tPASS' for name, marker, mode in roster]]
    require(results == expected, 'The exact original 52-mode result order is incomplete or failed')
    proofs = []
    for name, marker, mode in roster:
        path = root/(name+'-'+mode+'.log')
        text = regular(path).read_text()
        require(marker in text and not ERROR_LINE.search(text),
                'Original native log is missing PASS or contains a real engine error: '+path.name)
        proofs.append({'path': path.name, 'marker': marker, **record(path)})
    return proofs


def checked_native_runner_log(path: Path) -> dict:
    runner_log = regular(path).read_text()
    for marker in (
        '[Studio2020RasterRoster] PASS 17 actual PNG files, 3 original sidecars and 1 verified facial movie',
        '[LumoNextgen52] PASS: all 48 previous modes plus four Studio2020 modes and 17 bound rasters/movie/sidecars',
        '[LumoNextgen] PASS',
    ):
        require(marker in runner_log, 'Original complete 52-mode runner lacks its required ending: '+marker)
    require(not ERROR_LINE.search(runner_log), 'Original complete native runner contains a real failure')
    return record(path)


def checked_native(logs: Path, source: Path, revision: str) -> dict:
    head = subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=source, text=True).strip()
    tree = subprocess.check_output(['git', 'rev-parse', 'HEAD^{tree}'], cwd=source, text=True).strip()
    require(head == revision, 'Native verifier checkout differs from approved candidate pin')
    subprocess.run(['git', 'diff', '--exit-code', 'HEAD', '--'], cwd=source, check=True)
    root = logs/'nextgen'
    require(regular(logs/'source-sha.txt').read_text().strip() == revision
            and regular(root/'source-sha.txt').read_text().strip() == revision
            and regular(root/'source-tree.txt').read_text().strip() == tree
            and not regular(root/'source-dirty.txt').read_text().strip()
            and regular(root/'engine.txt').read_text().strip().startswith('4.6.3.stable.'),
            'Original native source/tree/clean/engine stamps differ')
    runner = regular(source/'tools/validate_nextgen.sh').read_text()
    proofs = checked_native_results(root, runner)
    runner_record = checked_native_runner_log(logs/'nextgen-runner.log')
    # Existing roster helpers write their indices. Replay in a disposable mirror:
    # only immutable PNG/movie payloads are hardlinked; JSON originals are copied.
    # The downloaded original metadata remains untouched.
    def payload_copy(src, dest):
        path = regular(Path(src))
        if path.suffix in ('.png', '.avi', '.mp4'):
            try:
                os.link(src, dest)
            except OSError:
                shutil.copyfile(src, dest)
        else:
            shutil.copyfile(src, dest)
        return dest
    rosters = {}
    with tempfile.TemporaryDirectory(prefix='c4-native-replay-') as temporary:
        replay = Path(temporary)
        for path in (root/'captures').rglob('*'):
            require(not path.is_symlink(), 'Native capture symlink is not accepted')
        shutil.copytree(root/'captures', replay/'captures', copy_function=payload_copy)
        helpers = (
            ('verify_studio_rasters.py', 'renderer-images.json', 24),
            ('verify_village_rasters.py', 'village-images.json', 4),
            ('verify_puzzle_menu_rasters.py', 'puzzle-menu-images.json', 6),
            ('verify_safe_area_rasters.py', 'safe-area-images.json', 7),
        )
        for helper, manifest, count in helpers:
            original = read(root/manifest)
            native_module(source, helper).verify(replay)
            checked = read(replay/manifest)
            require(checked == original and len(checked.get('images', [])) == count,
                    'Current native original roster replay differs: '+manifest)
            from PIL import Image
            for row in checked['images']:
                path = regular(root/row['path'])
                require(path.resolve().is_relative_to(root.resolve()), 'Native raster escapes original evidence')
                with Image.open(path) as image:
                    image.verify()
                with Image.open(path) as image:
                    image.load()
                    require(image.format == 'PNG' and image.size == (row['width'], row['height']),
                            'Original raster did not decode to its reported physical dimensions')
            rosters[manifest] = record(root/manifest)
    before = checked_native_extension(root, source, revision, tree)
    rosters['studio-2020-images.json'] = before
    return {'source': revision, 'tree': tree, 'core_modes': 52, 'mode_logs': proofs,
            'complete_runner_log': runner_record,
            'original_rosters': rosters,
            'scope': 'Actual pinned-source desktop engine and raster/movie proofs; no device FPS/audio claim'}


def checked_native_extension(root: Path, source: Path, revision: str, tree: str) -> dict:
    # This is the actual additive helper from the configured Native commit.
    # Its write=False contract rechecks all 17 new PNGs, original sidecars,
    # movie hashes and bound original decoding proofs without rewriting them.
    original = read(root/'studio-2020-images.json')
    before = record(root/'studio-2020-images.json')
    fresh = native_module(source, 'verify_studio_2020_rasters.py').verify(root, write=False)
    require(fresh == original and record(root/'studio-2020-images.json') == before
            and fresh.get('schema') == 1 and fresh.get('kind') == 'studio_2020_extension'
            and fresh.get('source', {}).get('commit') == revision
            and fresh.get('source', {}).get('tree') == tree
            and len(fresh.get('images', [])) == 17 and len(fresh.get('reports', [])) == 3
            and len(fresh.get('movies', [])) == 1,
            'The original new 2020 face/C4/treasure raster/movie evidence differs')
    return before


def committed_pcm_sources() -> dict:
    paths = [ROOT/'tools/auto_install/LumoLearningSpeech.kt',
             ROOT/'tools/auto_install/LumoSpeechEnvelope.kt', ROOT/'scripts/prepare_android.py',
             ROOT/'scripts/tests/test_speech_envelope_contract.py', ROOT/'scripts/tests/test_prepare_android.py',
             *sorted((ROOT/'scripts/tests/fixtures/speech_envelope_contract').rglob('*'))]
    result = {}
    for path in paths:
        if path.is_dir():
            continue
        relative = path.relative_to(ROOT).as_posix()
        data = regular(path).read_bytes()
        committed = subprocess.check_output(['git', 'show', 'HEAD:'+relative], cwd=ROOT)
        require(data == committed, 'PCM evidence source is not the committed candidate: '+relative)
        result[relative] = record(path)
    require(len(result) >= 17, 'Complete actual PCM fixtures and installer sources are required')
    return result


def prepare(args) -> dict:
    from verify_connect_four_candidate import verify as verify_candidate
    from release_pipeline_gates import evaluate_verification
    require(not args.out.exists(), 'Refusing to overwrite a delivery snapshot')
    original_facts = read(args.facts)
    # Re-execute the existing verifier against actual APKs and original C4,
    # runtime, compile and update evidence; no reported PASS substitutes for it.
    fresh = verify_candidate(args)
    require(fresh == original_facts, 'Fresh complete candidate replay differs from original final facts')
    binding = fresh['binding']
    jobs = checked_jobs(read(args.metadata/'run.json'), read(args.metadata/'jobs.json'),
                        read(args.metadata/'pull.json'), binding, args.pull_request)
    artifacts = checked_artifacts(read(args.metadata/'artifacts.json'), binding)
    pcm = checked_pcm_log(args.build_contracts/'build-contracts.log')
    pcm['sources'] = committed_pcm_sources()
    native = checked_native(args.native_evidence, args.native_source, binding['native_source'])
    learning = checked_learning_audit(args.learning_audit, binding)
    selected = checked_release_catalog(read(args.metadata/'releases.json'),
                                       read(args.metadata/'tags.json'), fresh)
    arm64 = fresh['apks']['arm64-v8a']
    evaluate_verification(arm64, version_name=fresh['versionName'], version_code=fresh['versionCode'])
    require(read(args.candidate/'GODOT-SOURCE.json') == read(ROOT/'config/godot-source.json'),
            'Original candidate native config differs from current approved source')
    host_tree = subprocess.check_output(['git', 'rev-parse', 'HEAD^{tree}'], cwd=ROOT, text=True).strip()
    facts = {
        'schema': 1, 'status': 'VERIFIED_TEST_BUNDLE_NOT_PUBLISHED',
        'host_source': binding['host_source'], 'host_tree': host_tree,
        'native_source': binding['native_source'], 'versionName': fresh['versionName'],
        'versionCode': fresh['versionCode'], 'binding': binding, 'jobs': jobs,
        'original_artifacts': artifacts, 'pcm': pcm, 'native': native, 'learning_audit': learning,
        'original_candidate_facts': record(args.facts), 'apks': fresh['apks'],
        'api37_approved': False, 'physical_arm64_tested': False,
        'published': False, 'release_approved': False,
        'measured_device_fps': None, 'audible_android_pcm_approved': False,
        'separate_human_visual_receipt': False,
        'scope': 'Signed ARM64 test delivery; real API35 C4/update and desktop gates only',
        'publication_policy': 'Only a newly created version tag and release; never replace or resume existing assets',
    }
    assets, audit = args.out/'assets', args.out/'audit'
    assets.mkdir(parents=True); audit.mkdir()
    originals = {
        'Lumo-Lernen-Neu.apk': args.candidate/'Lumo-Lernen-Neu.apk',
        'BUILD-PROVENANCE.json': args.candidate/'BUILD-PROVENANCE.json',
        'GODOT-SOURCE.json': args.candidate/'GODOT-SOURCE.json',
        'C4-CANDIDATE-FACTS.json': args.facts,
        'C4-ANDROID-RESULT.json': args.android/'c4/c4-result.json',
        'C4-DESKTOP-RUNTIME.json': args.runtime/'runtime-gate.json',
        'UPDATE-2020-RESULT.json': args.update/'update-result.json',
    }
    for name, source in originals.items():
        regular(source)
        if name.endswith('.apk'):
            os.link(source, assets/name)
        else:
            shutil.copyfile(source, assets/name)
        require(record(assets/name) == record(source), 'Release staging changed original bytes: '+name)
    with (assets/'Lumo-Lernen-Neu.apk.sha256').open('x') as handle:
        handle.write(arm64['sha256']+'  Lumo-Lernen-Neu.apk\n')
    write_new(assets/'C4-DELIVERY-FACTS.json', facts)
    write_new(assets/'PUBLISH-VERIFICATION.json', arm64)
    asset_index = {path.name: record(path) for path in sorted(assets.iterdir())}
    require(set(asset_index) == DELIVERY_ASSETS, 'Incomplete actual delivery asset set')
    plan = {'schema': 1, 'host_source': binding['host_source'], 'tag': selected['tag'],
            'versionName': fresh['versionName'], 'versionCode': fresh['versionCode'],
            'download_url': selected['downloadUrl'], 'assets': asset_index}
    write_new(args.out/'publication-plan.json', plan)
    for name in ('run', 'jobs', 'artifacts', 'pull', 'releases', 'tags'):
        shutil.copyfile(args.metadata/(name+'.json'), audit/('original-'+name+'.json'))
    learning_originals = audit/'learning-curriculum'
    learning_originals.mkdir()
    for name in (*LEARNING_AUDIT_FILES, 'source-binding.json'):
        shutil.copyfile(regular(args.learning_audit/name), learning_originals/name)
        require(record(learning_originals/name) == record(args.learning_audit/name),
                'Learning audit staging changed original bytes: '+name)
    write_new(audit/'create-tag.json', {'ref': 'refs/tags/'+plan['tag'], 'sha': args.source})
    body = (
        'Lumo Lernen C4 '+fresh['versionName']+'+'+str(fresh['versionCode'])+' — signed ARM64 TEST APK.\n\n'
        'Exact Host: '+args.source+'\nExact Godot: '+binding['native_source']+'\n'
        'APK SHA-256: '+arm64['sha256']+'\nPCK SHA-256: '+arm64['godot']['pck_sha256']+'\n'
        'Signing certificate SHA-256: '+arm64['signingCertificateSha256']+'\n'
        'Original acceptance run: https://github.com/'+REPOSITORY+'/actions/runs/'+str(args.build_run)+'\n\n'
        'All current Flutter/build contracts, the current 236-family/7552-sample structural learning audit, '
        '52 native modes with 17 additional face/C4/treasure rasters and movie, '
        'the real Dart/Godot C4 pair, actual API35 C4 touches/IPC/return and 2017→2020 preservation '
        'passed and their originals were rechecked before this new version was published.\n'
        'The learning audit is not semantic or official curriculum approval. '
        'PCM contracts use a synthetic JVM boundary. No API37, physical ARM64, audible device PCM, '
        'human visual receipt or device FPS claim is made.\n'
        'Update the existing family app without uninstalling. This uses the unchanged Lumo TEST '
        'certificate, not Google Play production signing. Previous tags/releases/assets are never replaced.\n'
    )
    write_new(audit/'create-release.json', {'tag_name': plan['tag'], 'target_commitish': args.source,
              'name': 'Lumo '+str(fresh['versionCode'])+' ARM64 Test-APK', 'body': body,
              'draft': True, 'prerelease': True, 'make_latest': 'false', 'generate_release_notes': False})
    write_new(audit/'publish-release.json', {'draft': False, 'make_latest': 'false'})
    with (audit/'asset-names.txt').open('x') as handle:
        handle.write(''.join(name+'\n' for name in asset_index))
    print('[C4Delivery] PREPARED: current test bundle verified, not published')
    return plan


def checked_plan(root: Path) -> dict:
    plan = read(root/'publication-plan.json')
    require(plan.get('schema') == 1 and plan.get('versionCode') == 2020
            and plan.get('tag') == 'coachpreview-build-2020'
            and re.fullmatch('[a-f0-9]{40}', str(plan.get('host_source'))), 'Invalid current delivery plan')
    require(isinstance(plan.get('assets'), dict) and set(plan['assets']) == DELIVERY_ASSETS,
            'Complete APK/proof/checksum release input set missing')
    require(all(re.fullmatch(r'[A-Za-z0-9][A-Za-z0-9.\-]+', name) for name in plan['assets']),
            'Release asset names must be the original plain filenames')
    actual = {p.name: record(p) for p in (root/'assets').iterdir()}
    require(actual == plan['assets'], 'Staged release files changed after acceptance')
    from release_pipeline_gates import family_apk_download_url
    require(plan.get('download_url') == family_apk_download_url(plan['tag']), 'Direct APK URL differs')
    return plan


def checked_bundle(archive: Path, root: Path, artifacts: dict, binding: dict, artifact_id: int) -> dict:
    """Bind every local bundle byte to its complete authenticated Actions ZIP.

    This only reads. The caller supplies the original API object and archive;
    neither a selected subset nor a rebuilt ZIP can satisfy the digest check.
    """
    rows = artifacts.get('artifacts')
    require(isinstance(rows, list) and artifacts.get('total_count') == len(rows),
            'Complete current original artifact metadata is required')
    matches = [row for row in rows if row.get('name') == BUNDLE_ARTIFACT]
    require(len(matches) == 1, 'Missing or duplicate completed delivery bundle artifact')
    artifact = matches[0]
    original_archive = record(archive)
    require(type(artifact_id) is int and artifact_id > 0 and artifact.get('id') == artifact_id
            and artifact.get('expired') is False
            and artifact.get('workflow_run', {}).get('id') == binding['run_id']
            and artifact.get('workflow_run', {}).get('head_sha') == binding['host_source']
            and type(artifact.get('size_in_bytes')) is int
            and artifact['size_in_bytes'] == original_archive['bytes']
            and artifact.get('digest') == 'sha256:' + original_archive['sha256'],
            'Original complete delivery archive differs from current API identity')
    require(root.is_dir() and not root.is_symlink(), 'Original unpacked delivery directory required')
    local = {}
    for path in sorted(root.rglob('*')):
        require(not path.is_symlink(), 'Unpacked delivery contains a symlink')
        if path.is_dir():
            continue
        local[path.relative_to(root).as_posix()] = record(path)
    seen, members = set(), {}
    with zipfile.ZipFile(archive) as zipped:
        for item in zipped.infolist():
            path = PurePosixPath(item.filename)
            name = path.as_posix()
            require(not item.flag_bits & 1 and not path.is_absolute() and path.parts
                    and '..' not in path.parts and '\\' not in item.filename
                    and name == item.filename.rstrip('/') and name not in seen,
                    'Unsafe, encrypted or duplicate original bundle member')
            seen.add(name)
            kind = stat.S_IFMT(item.external_attr >> 16)
            if item.is_dir():
                require(kind in (0, stat.S_IFDIR) and item.file_size == 0,
                        'Invalid original bundle directory')
                continue
            require(kind in (0, stat.S_IFREG), 'Original bundle member is not a regular file')
            total, sha = 0, hashlib.sha256()
            with zipped.open(item) as handle:
                for chunk in iter(lambda: handle.read(1024 * 1024), b''):
                    total += len(chunk); sha.update(chunk)
            require(total == item.file_size, 'Truncated original bundle member')
            members[name] = {'bytes': total, 'sha256': sha.hexdigest()}
    require(members == local and members, 'Unpacked bundle is missing, changed or contains extra bytes')
    require(record(archive) == original_archive
            and all(record(root/name) == identity for name, identity in local.items()),
            'Original bundle changed during archive verification')
    return {'artifact_id': artifact_id, 'artifact_name': BUNDLE_ARTIFACT,
            'archive': original_archive, 'members': members}


def checked_current(delivery: Path, metadata: Path, archive: Path,
                    artifact_id: int, pull_request: int) -> dict:
    plan = checked_plan(delivery)
    facts = read(delivery/'assets/C4-DELIVERY-FACTS.json')
    require(facts.get('schema') == 1 and facts.get('status') == 'VERIFIED_TEST_BUNDLE_NOT_PUBLISHED'
            and facts.get('published') is False and facts.get('release_approved') is False
            and facts.get('host_source') == facts.get('binding', {}).get('host_source') == plan['host_source']
            and facts.get('versionCode') == plan['versionCode'] == 2020
            and facts.get('versionName') == plan['versionName'],
            'Only the exact unmodified prepared 2020 test bundle can be considered for publication')
    head = subprocess.check_output(['git', 'rev-parse', 'HEAD'], cwd=ROOT, text=True).strip()
    tree = subprocess.check_output(['git', 'rev-parse', 'HEAD^{tree}'], cwd=ROOT, text=True).strip()
    require(head == plan['host_source'] and tree == facts['host_tree'],
            'Publication verifier checkout differs from the exact accepted source/tree')
    subprocess.run(['git', 'diff', '--exit-code', 'HEAD', '--'], cwd=ROOT, check=True)
    binding = facts['binding']
    jobs = checked_jobs(read(metadata/'run.json'), read(metadata/'jobs.json'),
                        read(metadata/'pull.json'), binding, pull_request, publication=True)
    originals = read(metadata/'artifacts.json')
    require(checked_artifacts(originals, binding) == facts['original_artifacts'],
            'A required original upload identity changed after delivery preparation')
    bundle = checked_bundle(archive, delivery, originals, binding, artifact_id)
    return {'status': 'COMPLETE_CURRENT_ACCEPTANCE_VERIFIED_NOT_PUBLISHED',
            'host_source': head, 'host_tree': tree, 'jobs': jobs, 'bundle': bundle}


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest='command', required=True)
    prepare_parser = commands.add_parser('prepare')
    for name in ('candidate', 'runtime', 'host-compile', 'android', 'update', 'metadata', 'out',
                 'facts', 'build-contracts', 'native-evidence', 'native-source', 'learning-audit'):
        prepare_parser.add_argument('--'+name, type=Path, required=True)
    for name in ('source', 'artifact-digest'):
        prepare_parser.add_argument('--'+name, required=True)
    for name in ('build-run', 'run-attempt', 'artifact-id', 'pull-request'):
        prepare_parser.add_argument('--'+name, type=int, required=True)
    audit_parser = commands.add_parser('bind-learning-audit')
    audit_parser.add_argument('--directory', type=Path, required=True)
    audit_parser.add_argument('--source', required=True)
    audit_parser.add_argument('--build-run', type=int, required=True)
    audit_parser.add_argument('--run-attempt', type=int, required=True)
    current = commands.add_parser('check-current')
    current.add_argument('--delivery', type=Path, required=True)
    current.add_argument('--metadata', type=Path, required=True)
    current.add_argument('--pull-request', type=int, required=True)
    current.add_argument('--bundle-archive', type=Path, required=True)
    current.add_argument('--bundle-artifact-id', type=int, required=True)
    vacant = commands.add_parser('check-vacant')
    vacant.add_argument('--delivery', type=Path, required=True)
    vacant.add_argument('--metadata', type=Path, required=True)
    for name in ('check-tag', 'check-release', 'verify-public'):
        command = commands.add_parser(name)
        command.add_argument('--delivery', type=Path, required=True)
        command.add_argument('--tag', type=Path, required=True)
        if name != 'check-tag':
            command.add_argument('--created', type=Path, required=True)
            command.add_argument('--release', type=Path, required=True)
        if name == 'check-release':
            command.add_argument('--stage', choices=('empty-draft', 'uploaded-draft', 'published'), required=True)
        if name == 'verify-public':
            command.add_argument('--apk', type=Path, required=True)
            command.add_argument('--receipt', type=Path, required=True)
    args = parser.parse_args()
    if args.command == 'bind-learning-audit':
        checked = bind_learning_audit(args.directory, args.source, args.build_run, args.run_attempt)
        print(json.dumps(checked, sort_keys=True))
        return 0
    if args.command == 'prepare':
        prepare(args)
        return 0
    plan = checked_plan(args.delivery)
    if args.command == 'check-current':
        checked_current(args.delivery, args.metadata, args.bundle_archive,
                        args.bundle_artifact_id, args.pull_request)
        return 0
    if args.command == 'check-vacant':
        facts = read(args.delivery/'assets/C4-DELIVERY-FACTS.json')
        checked_release_catalog(read(args.metadata/'releases.json'), read(args.metadata/'tags.json'), facts)
        return 0
    if args.command == 'check-tag':
        checked_tag(read(args.tag), plan)
    else:
        stage = args.stage if args.command == 'check-release' else 'published'
        receipt = checked_release(read(args.release), read(args.tag), read(args.created), plan, stage)
        if args.command == 'verify-public':
            require(record(args.apk) == plan['assets']['Lumo-Lernen-Neu.apk'],
                    'Unauthenticated direct Chrome download bytes differ from the actual signed APK')
            receipt.update({'status': 'PUBLIC_TEST_APK_BYTES_VERIFIED', 'host_source': plan['host_source'],
                            'versionName': plan['versionName'], 'versionCode': plan['versionCode'],
                            'public_apk': record(args.apk), 'plan_sha256': digest(args.delivery/'publication-plan.json')})
            require(not args.receipt.resolve().is_relative_to(args.delivery.resolve()),
                    'Public receipt must not mutate the original delivery bundle')
            write_new(args.receipt, receipt)
            print('[C4Delivery] verified direct Chrome APK:', plan['download_url'])
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
