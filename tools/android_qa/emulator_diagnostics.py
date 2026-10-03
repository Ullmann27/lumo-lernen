"""Read-only host/guest evidence; diagnostic failure never turns a test green."""
from __future__ import annotations
import argparse
import json
from pathlib import Path
import shutil
import subprocess
import threading
import time

FATAL = r'FATAL EXCEPTION|Fatal signal|SCRIPT ERROR|Parse Error| E godot.*ERROR:|LUMO_ASSET_ERROR(?:\s|$)'


def host_sample():
    memory = {}
    for line in Path('/proc/meminfo').read_text().splitlines():
        key, value = line.split(':', 1)
        if key in {'MemAvailable', 'MemFree', 'SwapFree', 'SwapTotal'}:
            memory[key] = value.strip()
    processes = []
    for directory in Path('/proc').glob('[0-9]*'):
        try:
            name = (directory/'comm').read_text().strip()
            if any(part in name.lower() for part in ('qemu', 'emulator', 'xvfb', 'adb')):
                status = (directory/'status').read_text().splitlines()
                processes.append({'pid': int(directory.name), 'name': name,
                                  'status': [line for line in status if line.startswith(('State:', 'VmRSS:', 'Threads:'))]})
        except (FileNotFoundError, PermissionError, ProcessLookupError):
            continue
    return {'time_utc': time.strftime('%Y-%m-%dT%H:%M:%SZ', time.gmtime()),
            'memory': memory, 'free_disk_bytes': shutil.disk_usage('.').free,
            'processes': processes}


class ContinuousDiagnostics:
    def __init__(self, adb, serial, out):
        self.adb, self.serial, self.out = adb, serial, out
        self.stop = threading.Event()

    def __enter__(self):
        self.out.mkdir(parents=True, exist_ok=True)
        self.log = (self.out/'android-logcat-continuous.txt').open('wb')
        self.process = subprocess.Popen([self.adb, '-s', self.serial, 'logcat', '-T', '1', '-v', 'threadtime'],
                                        stdout=self.log, stderr=subprocess.STDOUT)
        self.thread = threading.Thread(target=self.monitor, daemon=True)
        self.thread.start()
        return self

    def monitor(self):
        try:
            with (self.out/'host-monitor.jsonl').open('a') as stream:
                while not self.stop.is_set():
                    stream.write(json.dumps(host_sample())+'\n')
                    stream.flush()
                    if self.stop.wait(5):
                        break
        except Exception as error:
            (self.out/'host-monitor-error.txt').write_text(str(error)+'\n')

    def __exit__(self, *exc):
        self.stop.set()
        self.thread.join(timeout=6)
        ended = self.process.poll()
        if ended is None:
            self.process.terminate()
            try:
                self.process.wait(timeout=5)
            except subprocess.TimeoutExpired:
                self.process.kill()
                self.process.wait(timeout=5)
        self.log.close()
        if ended is not None:
            (self.out/'continuous-logcat-error.txt').write_text(
                f'Continuous adb logcat ended before usage checks, exit code {ended}.\n')
            if exc[0] is None:
                raise RuntimeError('Continuous Android logcat ended before usage checks completed')


def save_final_logs(device, out, preserve_error=False):
    import re
    continuous = out/'android-logcat-continuous.txt'
    logs = continuous.read_text(errors='replace') if continuous.exists() else ''
    try:
        final = device.adb('logcat', '-d', '-v', 'threadtime', timeout=10)
        (out/'android-logcat.txt').write_text(final)
        logs += '\n'+final
    except Exception as error:
        (out/'final-logcat-error.txt').write_text(str(error)+'\n')
        if not preserve_error:
            raise
    fatal = [line for line in logs.splitlines() if re.search(FATAL, line)]
    if fatal:
        (out/'fatal-errors.txt').write_text('\n'.join(fatal)+'\n')
        if not preserve_error:
            raise RuntimeError('Android, engine or bundled-asset errors appeared during the real usage checks; logs retained')


def collect_host(out):
    out.mkdir(parents=True, exist_ok=True)
    for name, command in [('host-memory.txt', ['free', '-m']),
                          ('host-disk.txt', ['df', '-h']),
                          ('host-processes.txt', ['ps', '-eo', 'pid,ppid,stat,rss,comm']),
                          ('host-kernel.txt', ['sudo', '-n', 'dmesg', '-T'])]:
        try:
            result = subprocess.run(command, capture_output=True, text=True, timeout=15)
            (out/name).write_text(f'exit_code={result.returncode}\n'+result.stdout+result.stderr)
        except Exception as error:
            (out/name).write_text(str(error)+'\n')
    for source in Path('/tmp/android-runner').glob('emu-crash-*'):
        destination = out/'emulator-crash'/source.name
        destination.parent.mkdir(parents=True, exist_ok=True)
        try:
            if source.is_dir():
                shutil.copytree(source, destination, dirs_exist_ok=True)
            else:
                shutil.copy2(source, destination)
        except Exception as error:
            (out/'host-crash-copy-error.txt').write_text(str(error)+'\n')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--out', type=Path, required=True)
    collect_host(parser.parse_args().out)
