"""Read SDK catalogs without installing platforms, system images or an APK."""
import argparse
from datetime import datetime, timezone
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import signal
import subprocess
import sys
import time
import zipfile


BASE_HOST_COMMIT = 'e3d161cb2f79b732ac2dbafc2764b151247f018b'
TOOLS_URL = 'https://dl.google.com/android/repository/commandlinetools-linux-15859902_latest.zip'
TOOLS_SHA256 = '4e4c464f145a7512b57d088ac6c278c03c9eea610886b35a5e0804e74eedf583'
REPOSITORY = Path(__file__).resolve().parents[1]


def utc_now():
    return datetime.now(timezone.utc).isoformat()


def digest(path):
    with path.open('rb') as stream:
        return hashlib.file_digest(stream, 'sha256').hexdigest()


def write_json(path, value):
    path.write_text(json.dumps(value, indent=2, ensure_ascii=False) + '\n')


class Inventory:
    def __init__(self, out):
        self.out = out
        self.commands = []

    def run(self, name, argv, *, environment=None, timeout=180):
        folder = self.out / name
        folder.mkdir()
        command = [str(value) for value in argv]
        overrides = {key: str(value) for key, value in (environment or {}).items()}
        record = {'name': name, 'argv': command, 'environment_overrides': overrides,
                  'started_utc': utc_now(), 'timeout_seconds': timeout,
                  'exit_code': None, 'timed_out': False, 'start_error': None}
        started = time.monotonic()
        with (folder / 'stdout.txt').open('wb') as stdout, (folder / 'stderr.txt').open('wb') as stderr:
            try:
                process = subprocess.Popen(command, stdout=stdout, stderr=stderr,
                                           env={**os.environ, **overrides},
                                           start_new_session=True)
                try:
                    process.wait(timeout=timeout)
                except subprocess.TimeoutExpired:
                    record['timed_out'] = True
                    try:
                        os.killpg(process.pid, signal.SIGTERM)
                    except ProcessLookupError:
                        pass
                    try:
                        process.wait(timeout=10)
                    except subprocess.TimeoutExpired:
                        try:
                            os.killpg(process.pid, signal.SIGKILL)
                        except ProcessLookupError:
                            pass
                        process.wait()
                record['exit_code'] = process.returncode
            except OSError as error:
                record['start_error'] = f'{type(error).__name__}: {error}'
        record.update(finished_utc=utc_now(), elapsed_seconds=time.monotonic() - started)
        record['success'] = (record['exit_code'] == 0 and not record['timed_out']
                             and record['start_error'] is None)
        for stream in ('stdout', 'stderr'):
            path = folder / (stream + '.txt')
            record[stream] = {'path': str(path.relative_to(self.out)),
                              'bytes': path.stat().st_size, 'sha256': digest(path)}
        write_json(folder / 'command.json', record)
        self.commands.append(record)
        print(json.dumps({'command': name, 'exit_code': record['exit_code'],
                          'timed_out': record['timed_out'], 'success': record['success']}), flush=True)
        return record

    def properties(self, name, sdk_root, manager):
        paths = {manager.parent.parent / 'source.properties'}
        for pattern in ('cmdline-tools/*/source.properties', 'platform-tools/source.properties',
                        'emulator/source.properties', 'platforms/*/source.properties'):
            paths.update(sdk_root.glob(pattern))
        folder = self.out / (name + '-source-properties')
        folder.mkdir()
        records = []
        for index, path in enumerate(sorted(paths)):
            if not path.is_file():
                continue
            destination = folder / f'{index:03d}-source.properties'
            shutil.copyfile(path, destination)
            records.append({'original_path': str(path), 'resolved_path': str(path.resolve()),
                            'artifact_path': str(destination.relative_to(self.out)),
                            'sha256': digest(destination), 'bytes': destination.stat().st_size})
        write_json(folder / 'index.json', records)

    def catalogs(self, name, manager, sdk_root, user_root):
        user_root.mkdir(parents=True)
        environment = {'ANDROID_HOME': sdk_root, 'ANDROID_SDK_ROOT': sdk_root,
                       'ANDROID_USER_HOME': user_root}
        self.properties(name, sdk_root, manager)
        self.run(name + '-version', [manager, '--version'], environment=environment, timeout=60)
        for channel in (0, 3):
            self.run(f'{name}-channel-{channel}',
                     [manager, f'--sdk_root={sdk_root}', '--list', '--verbose', f'--channel={channel}'],
                     environment=environment)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--out', type=Path, required=True)
    parser.add_argument('--work', type=Path, required=True)
    args = parser.parse_args()
    out, work = args.out.resolve(), args.work.resolve()
    if out == work or out in work.parents or work in out.parents:
        parser.error('Evidence and downloaded tool directories must be separate siblings.')
    out.mkdir(parents=True, exist_ok=False)
    work.mkdir(parents=True, exist_ok=False)
    inventory = Inventory(out)
    errors = []
    write_json(out / 'environment.json', {
        'recorded_utc': utc_now(), 'base_host_commit': BASE_HOST_COMMIT,
        'python': sys.version, 'environment': {key: os.environ.get(key) for key in (
            'ImageOS', 'ImageVersion', 'RUNNER_OS', 'RUNNER_ARCH', 'GITHUB_SHA',
            'GITHUB_REF', 'GITHUB_RUN_ID', 'GITHUB_RUN_ATTEMPT', 'JAVA_HOME',
            'ANDROID_HOME', 'ANDROID_SDK_ROOT')},
        'on_path_sdkmanager': shutil.which('sdkmanager'),
        'scope': 'Package inventory only. No Android runtime, APK, privacy or performance acceptance.',
    })
    try:
        inventory.run('source-commit-tree-parents', ['git', '-C', REPOSITORY, 'show', '--no-patch',
                                                  '--format=%H%n%T%n%P', 'HEAD'], timeout=30)
        inventory.run('source-status', ['git', '-C', REPOSITORY, 'status', '--porcelain=v1'], timeout=30)
        inventory.run('java-version', ['java', '-version'], timeout=30)
        root_value = os.environ.get('ANDROID_HOME') or os.environ.get('ANDROID_SDK_ROOT')
        on_path = shutil.which('sdkmanager')
        if not root_value:
            errors.append('Runner does not expose ANDROID_HOME or ANDROID_SDK_ROOT.')
        else:
            sdk_root = Path(root_value).resolve()
            preferred = sdk_root / 'cmdline-tools/latest/bin/sdkmanager'
            manager = preferred if preferred.is_file() else (Path(on_path) if on_path else preferred)
            write_json(out / 'existing-manager.json', {
                'sdk_root': str(sdk_root), 'action_preferred_path': str(preferred),
                'on_path': on_path, 'selected': str(manager), 'resolved': str(manager.resolve()),
                'exists': manager.is_file(),
                'selection': 'Use the same latest/bin precedence as the observed emulator action.',
            })
            inventory.catalogs('existing', manager, sdk_root, work / 'existing-user')
        archive = work / 'commandlinetools-linux-15859902_latest.zip'
        download = inventory.run('fresh-download', [
            'curl', '--fail', '--location', '--proto', '=https', '--tlsv1.2',
            '--connect-timeout', '30', '--max-time', '240', '--retry', '1',
            '--output', archive, TOOLS_URL], timeout=300)
        download_identity = {'url': TOOLS_URL, 'expected_sha256': TOOLS_SHA256,
                             'actual_sha256': digest(archive) if archive.is_file() else None,
                             'bytes': archive.stat().st_size if archive.is_file() else None}
        download_identity['verified'] = download['success'] and download_identity['actual_sha256'] == TOOLS_SHA256
        write_json(out / 'fresh-download-identity.json', download_identity)
        if not download_identity['verified']:
            errors.append('Fresh official tool download failed or does not match its pinned SHA256; not executed.')
        else:
            extraction = work / 'verified-archive'
            with zipfile.ZipFile(archive) as source:
                if source.testzip() is not None:
                    raise RuntimeError('Verified command-line-tools ZIP failed CRC validation.')
                members = source.namelist()
                if any(Path(name).is_absolute() or '..' in Path(name).parts for name in members):
                    raise RuntimeError('Command-line-tools archive contains an unsafe member path.')
                (out / 'fresh-archive-members.txt').write_text('\n'.join(members) + '\n')
                source.extractall(extraction)
            fresh_root = work / 'fresh-sdk'
            (fresh_root / 'cmdline-tools').mkdir(parents=True)
            shutil.move(extraction / 'cmdline-tools', fresh_root / 'cmdline-tools/latest')
            manager = fresh_root / 'cmdline-tools/latest/bin/sdkmanager'
            # ZipFile extraction does not restore executable permission bits.
            manager.chmod(manager.stat().st_mode | 0o100)
            inventory.catalogs('fresh', manager, fresh_root, work / 'fresh-user')
    except Exception as error:
        errors.append(f'{type(error).__name__}: {error}')
    finally:
        required = {'source-commit-tree-parents', 'source-status', 'java-version',
                    'existing-version', 'existing-channel-0', 'existing-channel-3',
                    'fresh-download', 'fresh-version', 'fresh-channel-0', 'fresh-channel-3'}
        completed = {record['name'] for record in inventory.commands if record['success']}
        observed = {}
        for name in ('existing-channel-0', 'existing-channel-3', 'fresh-channel-0', 'fresh-channel-3'):
            path = out / name / 'stdout.txt'
            lines = path.read_text(errors='replace').splitlines() if path.is_file() else []
            observed[name] = [line for line in lines if re.search(r'android-37|cinnamon|bun', line, re.I)]
        summary = {
            'status': 'INVENTORY_COMPLETE' if not errors and required <= completed else 'INVENTORY_INCOMPLETE',
            'errors': errors, 'missing_or_unsuccessful_commands': sorted(required - completed),
            'commands': inventory.commands, 'matching_catalog_lines_only': observed,
            'interpretation': 'Matches are a navigation aid. Read complete raw catalogs and their installed/available headings before choosing a package.',
            'no_sdkmanager_install_invoked': True, 'no_emulator_boot_attempted': True,
            'no_apk_installed_or_published': True, 'android17_runtime_verified': False,
            'previous_api37_failure_resolved': False,
        }
        write_json(out / 'summary.json', summary)
        files = [{'path': str(path.relative_to(out)), 'bytes': path.stat().st_size, 'sha256': digest(path)}
                 for path in sorted(out.rglob('*')) if path.is_file()]
        write_json(out / 'evidence-files.json', files)
        print(json.dumps({'status': summary['status'], 'errors': errors,
                          'missing_or_unsuccessful_commands': summary['missing_or_unsuccessful_commands']}), flush=True)
    return 0 if summary['status'] == 'INVENTORY_COMPLETE' else 1


if __name__ == '__main__':
    sys.exit(main())
