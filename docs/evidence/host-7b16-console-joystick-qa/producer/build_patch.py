#!/usr/bin/env python3
"""Prepare only a reviewable scratch overlay from the fixed published source."""
from pathlib import Path
import hashlib
import json
import subprocess

PACK = Path(__file__).resolve().parent
REPO = PACK.parent / 'lumo-host-jump-joystick-repair-7b16'
SOURCE = '21f7fbe6d378003d46b6d266eff9fdb91bc398b9'
TREE = '5a938c9bb82e3f966babd86adb26aceb0ae5f759'
WORKFLOW = '.github/workflows/lumo-console-joystick-7b16.yml'
BRANCH = 'qa/lumo-console-joystick-7b16-20261114'
FINAL = PACK / 'final-source'
INPUTS = PACK / 'inputs'
INPUTS.mkdir(exist_ok=True)
FINAL.mkdir(exist_ok=True)
records = {}


def git(*args):
    return subprocess.check_output(['git', '-C', str(REPO), *args])


assert git('rev-parse', 'HEAD').decode().strip() == SOURCE
assert git('rev-parse', 'HEAD^{tree}').decode().strip() == TREE
assert not git('status', '--porcelain', '--untracked-files=no').strip()


def original(path):
    data = git('show', SOURCE + ':' + path)
    target = INPUTS / path
    target.parent.mkdir(parents=True, exist_ok=True)
    if target.exists():
        assert target.read_bytes() == data
    else:
        target.write_bytes(data)
    records[path] = {'bytes': len(data), 'sha256': hashlib.sha256(data).hexdigest(),
                     'git_blob': git('rev-parse', SOURCE + ':' + path).decode().strip()}
    return data.decode()


def save(path, text):
    target = FINAL / path
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(text)


def once(text, old, new):
    assert text.count(old) == 1, (old, text.count(old))
    return text.replace(old, new, 1)


# Preserve every historical route and require four distinct new job names.
path = 'scripts/verify_unchanged_apk_diagnostic.py'
value = original(path)
anchor = 'QA_ROUTES = {name: (QA_WORKFLOW, QA_BRANCH) for name in QA_JOBS}'
added = """CONSOLE_JOYSTICK_QA_WORKFLOW = '.github/workflows/lumo-console-joystick-7b16.yml'
CONSOLE_JOYSTICK_QA_BRANCH = 'qa/lumo-console-joystick-7b16-20261114'
CONSOLE_JOYSTICK_CREATIVE_JOB = 'unchanged-apk-console-joystick-creative-api35'
CONSOLE_JOYSTICK_QA_JOBS = (
    'unchanged-apk-console-joystick-api37-host',
    'unchanged-apk-console-joystick-api37-swiftshader',
    'unchanged-apk-console-joystick-api37-swangle',
    CONSOLE_JOYSTICK_CREATIVE_JOB,
)
CREATIVE_QA_JOBS = (CREATIVE_QA_JOB, CONSOLE_JOYSTICK_CREATIVE_JOB)
"""
value = once(value, anchor, added + anchor)
anchor = '                  for name in FOLLOWUP_QA_JOBS})\n'
value = once(value, anchor, anchor + 'QA_ROUTES.update({name: (CONSOLE_JOYSTICK_QA_WORKFLOW, CONSOLE_JOYSTICK_QA_BRANCH)\n'
             '                  for name in CONSOLE_JOYSTICK_QA_JOBS})\n')
save(path, value)

# Only choose an explicitly bound Creative route. All three source checks,
# immutable APK/PCK checks and the before-input context recheck stay intact.
path = 'scripts/run_unchanged_creative_diagnostic.py'
value = original(path)
value = once(value, 'args.qa_job_name == common.CREATIVE_QA_JOB',
             'args.qa_job_name in common.CREATIVE_QA_JOBS')
value = once(value, 'job_name=common.CREATIVE_QA_JOB)', 'job_name=args.qa_job_name)')
value = once(value, '    args.qa_job_name = common.CREATIVE_QA_JOB\n',
             '    args.qa_job_name = getattr(args, \'qa_job_name\', common.CREATIVE_QA_JOB)\n'
             '    common.require(args.qa_job_name in common.CREATIVE_QA_JOBS,\n'
             '                   \'Unsupported Creative diagnostic job name\')\n')
value = once(value, "    parser.add_argument('--expected-qa-attempt', type=int, required=True)\n",
             "    parser.add_argument('--expected-qa-attempt', type=int, required=True)\n"
             "    parser.add_argument('--qa-job-name', choices=common.CREATIVE_QA_JOBS,\n"
             "                        default=common.CREATIVE_QA_JOB)\n")
save(path, value)

# A second diagnostic workflow retains the same bounded, lossless exporter.
path = 'scripts/export_creative_evidence_parts.py'
value = original(path)
anchor = 'DIAGNOSTIC_WORKFLOW = ".github/workflows/lumo-creative-7b16-diagnostic.yml"\n'
value = once(value, anchor, anchor + 'CONSOLE_JOYSTICK_WORKFLOW = ".github/workflows/lumo-console-joystick-7b16.yml"\n')
value = once(value, '    DIAGNOSTIC_WORKFLOW,\n)',
             '    DIAGNOSTIC_WORKFLOW,\n    CONSOLE_JOYSTICK_WORKFLOW,\n)')
value = once(value, '    diagnostic = workflow_path == DIAGNOSTIC_WORKFLOW\n',
             '    diagnostic = workflow_path in (DIAGNOSTIC_WORKFLOW, CONSOLE_JOYSTICK_WORKFLOW)\n')
save(path, value)

old_runtime_path = '.github/workflows/lumo-android-runtime-7b16-followup.yml'
runtime = original(old_runtime_path)
creative = original('.github/workflows/lumo-creative-7b16-diagnostic.yml')
original('.github/workflows/lumo-unchanged-apk-diagnostic.yml')

runtime = once(runtime, 'name: LUMO unchanged 7b16 APK Android runtime follow-up',
               'name: LUMO unchanged 7b16 Console and Joystick diagnostic')
runtime = once(runtime, 'lumo-unchanged-7b16-followup-${{', 'lumo-console-joystick-7b16-${{')
runtime = runtime.replace('qa/lumo-android-runtime-7b16-followup-20261114', BRANCH)
runtime = once(runtime, "      github.event.pull_request.head.repo.full_name == github.repository &&\n",
               "      github.event.pull_request.head.repo.full_name == github.repository &&\n"
               "      github.event.pull_request.base.ref == 'integration/lumo-connections-20261113' &&\n")
runtime = once(runtime, '    name: followup-diagnostic-probe-contracts',
               '    name: console-joystick-probe-contracts')
runtime = runtime.replace('lumo-7b16-followup-diagnostic-', 'lumo-console-joystick-7b16-')
runtime = runtime.replace('unchanged-apk-followup-${{ matrix.case }}',
                          'unchanged-apk-console-joystick-${{ matrix.case }}')
runtime = once(runtime, '  QA_SOURCE: ${{ github.event.pull_request.head.sha || github.sha }}\n',
               '  QA_SOURCE: ${{ github.event.pull_request.head.sha || github.sha }}\n'
               '  SOURCE_SHA: ${{ github.event.pull_request.head.sha || github.sha }}\n')
runtime = once(runtime, '--workflow ' + old_runtime_path, '--workflow ' + WORKFLOW)
for block in (
    '          - case: api35\n            api: 35\n            renderer: host\n            minutes: 65\n',
    '          - case: update2017\n            api: 35\n            renderer: host\n            minutes: 55\n',
):
    runtime = once(runtime, block, '')


def remove_step(text, title):
    start = text.index('      - name: ' + title + '\n')
    end = text.find('\n      - ', start + 1)
    assert end != -1
    return text[:start] + text[end + 1:]


runtime = remove_step(runtime, 'Download the original 2017 baseline only for the update')
runtime = remove_step(runtime, 'Run the actual API35 tour or complete update with the repaired driver observation')

# Three new modules plus the existing five-module Console discovery are all
# mandatory. The count check cannot turn a failed/skipped Unix test green.
runtime = once(runtime, '          bash -n scripts/run_unchanged_apk_diagnostic.sh\n',
               '          bash -n scripts/run_unchanged_apk_diagnostic.sh\n'
               '          .probe-venv/bin/python -B -m unittest -v \\\n'
               '            scripts.tests.test_android_console_transport \\\n'
               '            scripts.tests.test_android_runtime_device_logger \\\n'
               '            scripts.tests.test_runtime_logcat_sections \\\n'
               '            scripts.tests.test_android_framework_ready \\\n'
               '            scripts.tests.test_verify_android_runtime_anr \\\n'
               '            2>&1 | tee console-contracts.log\n'
               "          grep -Eq '^Ran 86 tests in ' console-contracts.log\n"
               "          grep -Fx 'OK' console-contracts.log\n"
               '          .probe-venv/bin/python -B -m unittest -v scripts.tests.test_studio_joystick_portrait \\\n'
               '            2>&1 | tee joystick-contracts.log\n'
               "          grep -Eq '^Ran 7 tests in ' joystick-contracts.log\n"
               "          grep -Fx 'OK' joystick-contracts.log\n")
# The five-module Console group above executes these old entries exactly once.
for name in ('test_android_framework_ready', 'test_verify_android_runtime_anr',
             'test_android_runtime_device_logger', 'test_runtime_logcat_sections'):
    line = '            scripts.tests.' + name + ' \\\n'
    first = runtime.index(line)
    second = runtime.index(line, first + len(line))
    runtime = runtime[:second] + runtime[second + len(line):]
runtime = once(runtime, '            scripts.tests.test_unchanged_apk_followup \\\n',
               '            scripts.tests.test_unchanged_apk_followup \\\n'
               '            scripts.tests.test_console_joystick_workflow \\\n')
runtime = once(runtime, '          path: diagnostic-contracts.log\n',
               '          path: |\n            diagnostic-contracts.log\n'
               '            console-contracts.log\n            joystick-contracts.log\n')


def prepare_step(directory):
    return f'''      - name: Prepare the private init-console channel before emulator launch
        env:
          LUMO_ANDROID_CONSOLE_SOCKET: ${{{{ runner.temp }}}}/lumo-serial-${{{{ github.run_id }}}}-${{{{ github.run_attempt }}}}/console.sock
        run: |
          set -euo pipefail
          mkdir -p {directory}
          python3 -B scripts/android_console_transport.py prepare --socket "$LUMO_ANDROID_CONSOLE_SOCKET" > {directory}/console-prepare-command.json
          cp -- "$(dirname -- "$LUMO_ANDROID_CONSOLE_SOCKET")/prepare.json" {directory}/console-prepare.json
          printf 'LUMO_ANDROID_CONSOLE_SOCKET=%s\\n' "$LUMO_ANDROID_CONSOLE_SOCKET" >> "$GITHUB_ENV"
'''


anchor = '      - name: Run the Android17 renderer comparison with continuous ANR observation\n'
assert anchor in runtime
runtime = once(runtime, anchor, prepare_step('tour/framework-start') + anchor)
runtime = once(runtime,
    '          emulator-options: -no-window -accel on -gpu ${{ matrix.renderer }} -no-snapshot -noaudio -no-boot-anim -camera-back none -camera-front none\n',
    '          emulator-options: -no-window -accel on -gpu ${{ matrix.renderer }} -no-snapshot -noaudio -no-boot-anim -camera-back none -camera-front none -shell-serial unix:${{ env.LUMO_ANDROID_CONSOLE_SOCKET }},server,nowait\n')

# Keep the original Creative job and its complete upload plus eight part slots.
creative = creative[creative.index('  creative-android:\n'):]
start = creative.index('    if: >-\n')
end = creative.index('    name:', start)
creative = creative[:start] + '    needs: [probe-contracts]\n' + creative[end:]
creative = once(creative, '    name: unchanged-apk-creative-api35',
                '    name: unchanged-apk-console-joystick-creative-api35')
creative = creative.replace('lumo-creative-7b16-diagnostic', 'lumo-console-joystick-7b16')
creative = once(creative,
    '      - name: Observe actual Jump Build Puzzle Treasure inputs on the unchanged APK\n',
    prepare_step('creative/console-preparation') +
    '      - name: Observe actual Jump Build Puzzle Treasure inputs on the unchanged APK\n')
creative = once(creative,
    '          emulator-options: -no-window -accel on -gpu host -no-snapshot -noaudio -no-boot-anim -camera-back none -camera-front none\n',
    '          emulator-options: -no-window -accel on -gpu host -no-snapshot -noaudio -no-boot-anim -camera-back none -camera-front none -shell-serial unix:${{ env.LUMO_ANDROID_CONSOLE_SOCKET }},server,nowait\n')
creative = once(creative, '--expected-qa-attempt "$GITHUB_RUN_ATTEMPT" --apk ',
                '--expected-qa-attempt "$GITHUB_RUN_ATTEMPT" --qa-job-name unchanged-apk-console-joystick-creative-api35 --apk ')
save(WORKFLOW, runtime.rstrip() + '\n' + creative)

# Separate, exact-branch-only exclusions from older broad build/QA entrypoints.
for path, job in (
    ('.github/workflows/lumo-unified-integration-2026.yml', 'verify-and-build'),
    ('.github/workflows/lumo-astra-script-recovery.yml', 'full-app-script-regression'),
    ('.github/workflows/lumo-1966-cards-route-kart-qa.yml', 'cards-route-and-probe'),
):
    value = original(path)
    condition = f"      github.head_ref != '{BRANCH}' && github.ref_name != '{BRANCH}'"
    if job == 'verify-and-build':
        previous = "      github.head_ref != 'qa/lumo-android-runtime-7b16-followup-20261114' && github.ref_name != 'qa/lumo-android-runtime-7b16-followup-20261114'"
        value = once(value, previous, previous + ' &&\n' + condition)
    else:
        value = once(value, '  ' + job + ':\n', '  ' + job + ':\n    if: >-\n' + condition + '\n')
    save(path, value)

(PACK / 'input-sources.json').write_text(json.dumps({
    'schema': 1, 'published_source': SOURCE, 'published_tree': TREE,
    'read_only_source_worktree': str(REPO), 'files': records,
}, indent=2, sort_keys=True) + '\n')
print(json.dumps({'source': SOURCE, 'tree': TREE, 'input_files': len(records),
                  'final_files': len([p for p in FINAL.rglob('*') if p.is_file()])}))
