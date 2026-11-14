#!/usr/bin/env python3
"""Run a real engine probe and stop promptly on a GDScript/engine error."""
import argparse
import os
from pathlib import Path
import re
import signal
import subprocess
import sys
import threading


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--log', required=True)
    parser.add_argument('--timeout', type=float, default=240)
    parser.add_argument('--required', default='PASS')
    parser.add_argument('command', nargs=argparse.REMAINDER)
    args = parser.parse_args()
    command = args.command[1:] if args.command[:1] == ['--'] else args.command
    if not command:
        parser.error('An engine command is required after --')
    path = Path(args.log)
    path.parent.mkdir(parents=True, exist_ok=True)
    failed = False
    timed_out = threading.Event()
    passed = False
    kill_timer = None
    process = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                               text=True, bufsize=1, start_new_session=True)

    def stop():
        nonlocal kill_timer
        if process.poll() is None:
            try:
                os.killpg(process.pid, signal.SIGTERM)
            except ProcessLookupError:
                pass
            if kill_timer is None:
                # An engine/render-driver hang must not keep the CI gate alive
                # after its deadline or after a failing GDScript assertion.
                def force_stop():
                    if process.poll() is None:
                        try:
                            os.killpg(process.pid, signal.SIGKILL)
                        except ProcessLookupError:
                            pass
                kill_timer = threading.Timer(5.0, force_stop)
                kill_timer.daemon = True
                kill_timer.start()

    def deadline():
        timed_out.set()
        stop()

    timer = threading.Timer(args.timeout, deadline)
    timer.daemon = True
    timer.start()
    try:
        with path.open('w') as log:
            for line in process.stdout:
                log.write(line)
                log.flush()
                print(line, end='', flush=True)
                passed = passed or args.required in line
                if re.search(r'SCRIPT ERROR|Parse Error|ERROR:|Assertion failed', line):
                    failed = True
                    stop()
            result = process.wait()
    finally:
        timer.cancel()
        if kill_timer is not None:
            kill_timer.cancel()
    if timed_out.is_set():
        print(f'[ProbeRunner] timeout after {args.timeout:g}s', file=sys.stderr)
    if failed or timed_out.is_set() or result != 0 or not passed:
        print('[ProbeRunner] FAIL: clean exit and required success marker were not both present',
              file=sys.stderr)
        return 1
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
