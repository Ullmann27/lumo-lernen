"""Read-only call timing; records overlap rather than attributing time to the app."""
from __future__ import annotations

import json
from pathlib import Path
import threading
import time


class TimingJournal:
    def __init__(self, path: Path, *, clock=time.monotonic):
        self.path = Path(path)
        self.clock = clock
        self.lock = threading.Lock()
        self.local = threading.local()
        self.sequence = 0
        self.write_error_count = 0
        self.write_errors = []
        self.origin = clock()

    def _identity(self):
        with self.lock:
            self.sequence += 1
            return self.sequence

    def _write(self, event):
        # Close flushes each complete line, including when the existing alarm
        # unwinds a screenshot/OCR/readiness call. No additional device reads.
        try:
            with self.lock, self.path.open('a') as stream:
                stream.write(json.dumps(event, separators=(',', ':')) + '\n')
        except TimeoutError as error:
            # The existing one-shot hard alarm must still abort the probe,
            # including when it interrupts this optional journal write.
            with self.lock:
                self.write_error_count += 1
                if len(self.write_errors) < 8:
                    self.write_errors.append(type(error).__name__ + ': ' + str(error))
            raise
        except OSError as error:
            # Optional observation must not replace the callback's return or
            # original timeout/exception. Its separate result marks the gap.
            with self.lock:
                self.write_error_count += 1
                if len(self.write_errors) < 8:
                    self.write_errors.append(type(error).__name__ + ': ' + str(error))

    def summary(self):
        return {'status': 'PASS' if self.write_error_count == 0 else 'NOT_MEASURED',
                'path': self.path.name, 'write_error_count': self.write_error_count,
                'write_errors': list(self.write_errors),
                'scope': 'Optional host call timings; nested intervals overlap; no CPU/GPU attribution'}

    def call(self, category, tag, callback, *args, **kwargs):
        identity = self._identity()
        parent = getattr(self.local, 'parent', None)
        self.local.parent = identity
        started = self.clock()
        status = 'PASS'
        error_type = None
        try:
            return callback(*args, **kwargs)
        except BaseException as error:
            status = 'FAIL'
            error_type = type(error).__name__
            raise
        finally:
            finished = self.clock()
            self.local.parent = parent
            self._write({
                'event': identity, 'parent': parent, 'thread': threading.get_ident(),
                'category': category, 'tag': str(tag), 'status': status,
                'started_since_origin_seconds': started - self.origin,
                'finished_since_origin_seconds': finished - self.origin,
                'wall_seconds': finished - started, 'error_type': error_type,
                'scope': 'Observed call wall time; nested intervals overlap; no CPU/GPU attribution',
            })

    def wrap(self, category, callback, *, tag_index=1):
        def measured(*args, **kwargs):
            # Existing UI helpers use (out, label/name/tag, ...). Record only a
            # label/file tag, never profile, wallet or environment contents.
            tag = args[tag_index] if len(args) > tag_index else getattr(callback, '__name__', category)
            return self.call(category, tag, callback, *args, **kwargs)
        return measured

    def phase(self, tag):
        now = self.clock()
        self._write({'event': self._identity(), 'parent': None,
                     'thread': threading.get_ident(), 'category': 'phase',
                     'tag': str(tag), 'status': 'OBSERVED',
                     'since_origin_seconds': now - self.origin})
