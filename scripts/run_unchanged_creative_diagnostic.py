#!/usr/bin/env python3
"""Run repaired Creative observations against the exact original 7b16 APK.

The candidate and native code are immutable inputs. Only the separately bound
QA checkout supplies observation helpers. This runner never builds or publishes
an APK and cannot turn a recorded Jump movie into a visual or FPS approval.
"""
from __future__ import annotations

import argparse
import importlib.util
from pathlib import Path
import subprocess
import sys
import zipfile


ROOT = Path(__file__).resolve().parents[1]
COMMON_PATH = ROOT / 'scripts/verify_unchanged_apk_diagnostic.py'
SPEC = importlib.util.spec_from_file_location('creative_diagnostic_common', COMMON_PATH)
common = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(common)

NATIVE_TREE = 'b8ea9b1777e8d0b6302156330d4d1b298a316aea'
RUNNER = 'scripts/run_unchanged_creative_diagnostic.py'
QA_FILES = (
    'scripts/verify_unchanged_apk_diagnostic.py', RUNNER,
    'config/godot-source.json', 'pubspec.yaml',
    '.github/probes/studio_creative_android_probe.py',
    '.github/probes/modernization_android_tour.py',
    '.github/probes/creative_android_probe.py',
    'scripts/probes/pr207_android_smoke.py',
)
NATIVE_FILES = (
    'scripts/games/jump_islands.gd', 'scripts/games/jump_touch_button.gd',
    'scripts/games/kart_joystick.gd', 'scripts/creative/build_world.gd',
    'scripts/creative/build_state.gd', 'scripts/creative/puzzle_world.gd',
    'scripts/creative/puzzle_state.gd', 'scripts/creative/treasure_world.gd',
    'scripts/creative/treasure_state.gd',
)


def expected_candidate() -> dict:
    return {
        'host_source': common.HOST, 'native_source': common.NATIVE,
        'build_run': common.BUILD_RUN, 'artifact_id': common.ARTIFACT_ID,
        'artifact_digest': common.ARTIFACT_DIGEST,
        'workflow_path': common.CANDIDATE_WORKFLOW,
    }


def input_files(args) -> dict[str, Path]:
    inputs = {f'candidate/{name}': args.candidate_metadata_dir / name
              for name in ('run.json', 'jobs.json', 'artifacts.json')}
    inputs.update({f'qa/{name}': args.qa_metadata_dir / name
                   for name in ('run.json', 'jobs.json')})
    inputs.update(provenance=args.provenance, sums=args.sums)
    return inputs


def validate_tour_context(args, context: dict) -> str:
    """Recheck original metadata and committed helpers before any tour inputs."""
    common.require(isinstance(context, dict) and context.get('schema') == 1
                   and context.get('status') == 'BOUND',
                   'A completed, separately bound Creative preflight is required')
    common.require(args.qa_job_name in common.CREATIVE_QA_JOBS
                   and args.qa_source == args.probe_source == ROOT
                   and args.candidate_source != ROOT
                   and args.native_source not in (ROOT, args.candidate_source),
                   'Creative QA, candidate and native checkouts must remain distinct')
    common.require(common.read_json(args.diagnostic_report) == context,
                   'Creative preflight file and in-memory context differ')
    inputs = input_files(args)
    common.require(set(context.get('input_hashes', {})) == set(inputs),
                   'Creative preflight input collection differs')
    for name, path in inputs.items():
        actual = {'path': str(common.regular(path)), 'bytes': path.stat().st_size,
                  'sha256': common.file_digest(path)}
        common.require(context['input_hashes'][name] == actual,
                       'Creative original metadata/provenance changed: ' + name)
    data = {name: common.read_json(path) for name, path in inputs.items()
            if name.endswith('.json')}
    qa = common.verify_qa(
        data['qa/run.json'], data['qa/jobs.json'], source=args.expected_qa_source,
        run_id=args.expected_qa_run, attempt=args.expected_qa_attempt,
        job_name=args.qa_job_name)
    common.require(context.get('diagnostic_qa') == qa,
                   'Creative QA report belongs to another job, attempt or source')
    creative = common.load_module(
        'creative_diagnostic_context_probe',
        ROOT / '.github/probes/studio_creative_android_probe.py')
    candidate = common.verify_candidate(
        data['candidate/run.json'], data['candidate/jobs.json'],
        data['candidate/artifacts.json'], creative)
    common.require(context.get('candidate_build') == candidate,
                   'Creative preflight candidate build differs')
    binding = creative.verify_candidate_metadata(
        data['candidate/run.json'], data['candidate/artifacts.json'],
        data['candidate/jobs.json'], expected_candidate())
    common.require(context.get('candidate_binding') == args.binding == binding,
                   'Creative tour candidate binding differs from original metadata')
    roots = {
        'qa': (ROOT, qa['source'], qa['tree'], QA_FILES),
        'candidate': (args.candidate_source, common.HOST, common.HOST_TREE,
                      ('config/godot-source.json', 'pubspec.yaml')),
        'native': (args.native_source, common.NATIVE, NATIVE_TREE, NATIVE_FILES),
    }
    common.require(set(context.get('git_sources', {})) == set(roots)
                   and set(context.get('source_files', {})) == set(roots),
                   'Creative source collection is incomplete')
    for name, (source, commit, tree, required_files) in roots.items():
        common.require(context['git_sources'][name]
                       == common.source_identity(source, commit, tree),
                       'Creative source identity changed: ' + name)
        entries = context['source_files'][name]
        common.require(isinstance(entries, list)
                       and len(entries) == len(required_files)
                       and all(isinstance(row, dict) for row in entries)
                       and {row.get('path') for row in entries} == set(required_files),
                       'Creative committed helper collection differs: ' + name)
        for entry in entries:
            common.require(common.committed_file(source, entry['path']) == entry,
                           'Creative committed helper changed: ' + entry['path'])
    apk = context.get('apk', {})
    common.require(apk.get('apk_sha256') == common.APK_SHA256
                   and apk.get('apk_bytes') == common.APK_BYTES
                   and apk.get('pck_sha256') == common.PCK_SHA256
                   and apk.get('pck_bytes') == common.PCK_BYTES
                   and common.regular(args.apk).stat().st_size == common.APK_BYTES,
                   'Creative diagnostic does not name the unchanged APK/PCK')
    # Tour.run independently reads the full APK/PCK again in candidate cwd.
    return qa['source']


def prepare(args):
    for key in ('qa_source', 'candidate_source', 'native_source'):
        source = getattr(args, key)
        common.require(not source.is_symlink(), 'Source checkouts must not be symlinks')
        setattr(args, key, source.resolve())
    for key in ('candidate_metadata_dir', 'qa_metadata_dir', 'apk',
                'provenance', 'sums', 'out'):
        value = getattr(args, key)
        common.require(not value.is_symlink(), 'Diagnostic inputs must not be symlinks')
        setattr(args, key, value.resolve())
    common.require(not args.out.exists(), 'Refusing to reuse a Creative tour directory')
    args.qa_job_name = getattr(args, 'qa_job_name', common.CREATIVE_QA_JOB)
    common.require(args.qa_job_name in common.CREATIVE_QA_JOBS,
                   'Unsupported Creative diagnostic job name')
    args.probe_source = args.qa_source
    args.metadata_dir = args.candidate_metadata_dir
    args.expected_source = common.HOST
    args.build_run = common.BUILD_RUN
    args.artifact_id = common.ARTIFACT_ID
    args.artifact_digest = common.ARTIFACT_DIGEST
    args.workflow_path = common.CANDIDATE_WORKFLOW
    context = common.bind(args)
    context['git_sources']['native'] = common.source_identity(
        args.native_source, common.NATIVE, NATIVE_TREE)
    context['source_files']['native'] = [
        common.committed_file(args.native_source, relative)
        for relative in NATIVE_FILES]
    context['source_files']['qa'].append(common.committed_file(ROOT, RUNNER))
    creative = common.load_module(
        'unchanged_creative_diagnostic_probe',
        ROOT / '.github/probes/studio_creative_android_probe.py')
    args.binding = creative.candidate_binding(args)
    context['candidate_binding'] = args.binding
    context['scope'] = (
        'Original 7b16 APK/PCK and native source with separately committed Creative '
        'observation helpers. Preflight only; no Android, release or visual approval.')
    args.diagnostic_report = args.out.parent / 'creative-diagnostic-binding.json'
    common.write_report(args.diagnostic_report, context)
    args.diagnostic_context = context
    validate_tour_context(args, context)
    common.write_report(args.out.parent / 'candidate-artifact-binding.json', args.binding)
    common.write_report(args.out / 'candidate-artifact-binding.json', args.binding)
    return creative


def main(argv=None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    for name in ('qa-source', 'candidate-source', 'native-source',
                 'candidate-metadata-dir', 'qa-metadata-dir',
                 'apk', 'provenance', 'sums', 'out'):
        parser.add_argument('--' + name, type=Path, required=True)
    parser.add_argument('--expected-qa-source', required=True)
    parser.add_argument('--expected-qa-run', type=int, required=True)
    parser.add_argument('--expected-qa-attempt', type=int, required=True)
    parser.add_argument('--qa-job-name', choices=common.CREATIVE_QA_JOBS,
                        default=common.CREATIVE_QA_JOB)
    args = parser.parse_args(argv)
    try:
        creative = prepare(args)
        return creative.Tour(args).run()
    except (OSError, ValueError, RuntimeError, zipfile.BadZipFile,
            subprocess.SubprocessError) as error:
        print('UNCHANGED_CREATIVE_DIAGNOSTIC FAIL: ' + str(error), file=sys.stderr)
        return 1


if __name__ == '__main__':
    sys.dont_write_bytecode = True
    raise SystemExit(main())
