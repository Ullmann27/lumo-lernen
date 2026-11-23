"""Resolve the digest-pinned org.json fixture shared by JVM contract suites.

Explicit LUMO_TEST_JSON_JAR and LUMO_JSON_JAR must be valid when set.
Otherwise reuse Gradle's artifact or a content-addressed cache, downloading at
most twice per configured Maven Central endpoint. No test is skipped.
"""
from contextlib import contextmanager
from datetime import datetime, timezone
from email.utils import parsedate_to_datetime
import hashlib
import io
import os
from pathlib import Path
import tempfile
import threading
import time
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen
import zipfile

try:
    import fcntl
except ImportError:  # Atomic publication still protects non-POSIX hosts.
    fcntl = None


JSON_URL = 'https://repo.maven.apache.org/maven2/org/json/json/20240303/json-20240303.jar'
JSON_SHA256 = '3cf6cd6892e32e2b4c1c39e0f52f5248a2f5b37646fdfbb79a66b46b618414ed'
_JSON_URLS = (
    JSON_URL,
    'https://maven-central.storage-download.googleapis.com/maven2/org/json/json/20240303/json-20240303.jar',
)
_MAX_JAR_BYTES = 2 * 1024 * 1024
_ATTEMPTS_PER_URL = 2
_MAX_RETRY_DELAY = 30
_RETRYABLE_HTTP = {408, 429, 500, 502, 503, 504}
_CACHE_MUTEX = threading.Lock()


def _verified(data, origin):
    if len(data) > _MAX_JAR_BYTES or hashlib.sha256(data).hexdigest() != JSON_SHA256:
        raise RuntimeError(f'The pinned org.json dependency digest changed: {origin}')
    try:
        with zipfile.ZipFile(io.BytesIO(data)) as archive:
            required = {'org/json/JSONObject.class', 'org/json/JSONArray.class'}
            if not required.issubset(archive.namelist()) or archive.testzip() is not None:
                raise RuntimeError(f'The pinned org.json dependency is not a complete JAR: {origin}')
    except zipfile.BadZipFile as error:
        raise RuntimeError(f'The pinned org.json dependency is not a valid ZIP: {origin}') from error
    return data


def _read_verified(path):
    with path.open('rb') as stream:
        return _verified(stream.read(_MAX_JAR_BYTES + 1), path)


def _retry_delay(header, attempt):
    fallback = float(2 ** (attempt + 1))
    if header is None:
        return fallback
    try:
        seconds = int(header)
        return float(seconds) if seconds >= 0 else fallback
    except (ValueError, TypeError, OverflowError):
        try:
            when = parsedate_to_datetime(header)
            if when.tzinfo is None:
                when = when.replace(tzinfo=timezone.utc)
            return max(0.0, (when - datetime.now(timezone.utc)).total_seconds())
        except (ValueError, TypeError, OverflowError):
            return fallback


def _download():
    last_error = None
    for url in _JSON_URLS:
        for attempt in range(_ATTEMPTS_PER_URL):
            try:
                request = Request(url, headers={'User-Agent': 'Lumo-JVM-Contract-Tests/1'})
                with urlopen(request, timeout=30) as response:
                    data = response.read(_MAX_JAR_BYTES + 1)
            except HTTPError as error:
                last_error = error
                delay = _retry_delay((error.headers or {}).get('Retry-After'), attempt)
                error.close()
                if error.code not in _RETRYABLE_HTTP:
                    raise RuntimeError(f'Cannot download pinned org.json: HTTP {error.code} from {url}') from error
            except (URLError, TimeoutError, ConnectionError) as error:
                last_error = error
                delay = _retry_delay(None, attempt)
            else:
                # Integrity errors are never retried or hidden by a mirror.
                return _verified(data, url)
            if attempt + 1 == _ATTEMPTS_PER_URL or delay > _MAX_RETRY_DELAY:
                # Do not retry this endpoint earlier than its Retry-After.
                break
            time.sleep(delay)
    raise RuntimeError(
        'Cannot obtain pinned org.json after bounded retries; supply a verified '
        'LUMO_TEST_JSON_JAR or populate LUMO_TEST_DEPS_CACHE'
    ) from last_error


@contextmanager
def _cache_lock(path):
    with _CACHE_MUTEX, path.open('a+b') as lock:
        if fcntl is not None:
            fcntl.flock(lock.fileno(), fcntl.LOCK_EX)
        try:
            yield
        finally:
            if fcntl is not None:
                fcntl.flock(lock.fileno(), fcntl.LOCK_UN)


def _publish(path, data):
    temporary = None
    try:
        with tempfile.NamedTemporaryFile(dir=path.parent, prefix=path.name + '.', suffix='.tmp', delete=False) as stream:
            temporary = Path(stream.name)
            stream.write(data)
            stream.flush()
            os.fsync(stream.fileno())
        os.replace(temporary, path)
    finally:
        if temporary is not None:
            temporary.unlink(missing_ok=True)


def _resolve():
    explicit = None
    for variable in ('LUMO_TEST_JSON_JAR', 'LUMO_JSON_JAR'):
        supplied = os.environ.get(variable)
        if supplied is not None:
            # A broken explicit override must fail, even if another source works.
            data = _read_verified(Path(supplied).expanduser())
            if explicit is None:
                explicit = data
    if explicit is not None:
        return explicit

    configured = os.environ.get('LUMO_TEST_DEPS_CACHE')
    cache_root = (Path(configured).expanduser() if configured else
                  Path(os.environ.get('XDG_CACHE_HOME', Path.home() / '.cache')) / 'lumo/jvm-tests')
    cache_root.mkdir(parents=True, exist_ok=True)
    cached = cache_root / f'json-20240303-{JSON_SHA256}.jar'
    with _cache_lock(cached.with_suffix('.lock')):
        if cached.is_file():
            try:
                return _read_verified(cached)
            except RuntimeError:
                # Repair only this helper's cache, never explicit/Gradle files.
                pass
        gradle = Path(os.environ.get('GRADLE_USER_HOME', Path.home() / '.gradle'))
        data = None
        for candidate in sorted(gradle.glob(
                'caches/modules-2/files-2.1/org.json/json/20240303/*/json-20240303.jar')):
            try:
                data = _read_verified(candidate)
                break
            except (OSError, RuntimeError):
                continue
        if data is None:
            data = _download()
        _publish(cached, data)
        return data


def prepare_json_jar(destination):
    """Copy verified bytes into the suite's private temporary work directory."""
    data = _resolve()
    destination = Path(destination)
    destination.write_bytes(data)
    return destination
