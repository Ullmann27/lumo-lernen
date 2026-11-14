#!/usr/bin/env python3
"""Publish one new, completely accepted C4 2020 test bundle, never resume it.

The candidate checkout and its read-only verifier remain unchanged. All remote
mutations are explicit, once-only calls made after that verifier accepts fresh
original metadata. A failure can leave a new tag/draft or a published release;
this program never repairs, deletes, retries or resumes such an outcome.
"""
from __future__ import annotations

import argparse
from dataclasses import dataclass
import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import re
import socket
import stat
import subprocess
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
import zipfile


REPOSITORY = 'Ullmann27/lumo-lernen'
API = 'https://api.github.com/repos/' + REPOSITORY
UPLOAD = 'https://uploads.github.com/repos/' + REPOSITORY
API_VERSION = '2026-03-10'
WORKFLOW = '.github/workflows/lumo-connect-four-2020.yml'
BRANCH = 'integration/lumo-c4-connections-20261114'
BUNDLE = 'lumo-connect-four-2020-delivery-bundle'
TAG = 'coachpreview-build-2020'
ASSETS = frozenset((
    'Lumo-Lernen-Neu.apk', 'Lumo-Lernen-Neu.apk.sha256',
    'BUILD-PROVENANCE.json', 'GODOT-SOURCE.json', 'C4-CANDIDATE-FACTS.json',
    'C4-ANDROID-RESULT.json', 'C4-DESKTOP-RUNTIME.json', 'UPDATE-2020-RESULT.json',
    'C4-DELIVERY-FACTS.json', 'PUBLISH-VERIFICATION.json', 'VILLAGE-ANDROID-RESULT.json',
))
JOBS = frozenset((
    'connect-four-runtime', 'android-host-compile', 'verify-and-build',
    'android-c4', 'update-2020-from-2017', 'verify-c4-candidate', 'prepare-c4-delivery',
))
VERIFIER_SOURCES = {
    'scripts/verify_connect_four_delivery.py':
        '229b33a0f1b7de1c09cbfff871edaec5470e783df9068629a2337d3de4ccaa18',
    'scripts/release_pipeline_gates.py':
        '400e54f2952f0d8aae07fc964e4688c48f16c9213ea022fa8754731004551946',
}
MAX_ARCHIVE = 2 * 1024**3
MAX_UNPACKED = 3 * 1024**3
MAX_MEMBERS = 512
MAX_JSON = 16 * 1024**2
MAX_PAGES = 100
MAX_REDIRECTS = 5
OPERATION_SECONDS = 600
SIGNED_QUERY = re.compile(
    rb'(?i)[?&](?:sig|signature|access_token|token|x-amz-signature|'
    rb'x-amz-security-token|x-goog-signature|awsaccesskeyid)='
)


class PublicationError(RuntimeError):
    """Only fixed diagnostic codes, never a URL or a credential."""


def require(condition, code: str) -> None:
    if not condition:
        raise PublicationError(code)


def strict_json(data: bytes):
    def pairs(items):
        result = {}
        for key, value in items:
            require(key not in result, 'DUPLICATE_JSON_KEY')
            result[key] = value
        return result
    try:
        return json.loads(data.decode('utf-8'), object_pairs_hook=pairs,
                          parse_constant=lambda _: (_ for _ in ()).throw(
                              PublicationError('NONFINITE_JSON')))
    except (UnicodeError, json.JSONDecodeError) as exc:
        raise PublicationError('INVALID_UTF8_JSON') from exc


def encoded(value) -> bytes:
    return (json.dumps(value, sort_keys=True, indent=2, ensure_ascii=False) + '\n').encode('utf-8')


def regular(path: Path) -> Path:
    require(path.is_file() and not path.is_symlink(), 'REGULAR_FILE_REQUIRED')
    for parent in path.absolute().parents:
        require(not parent.is_symlink(), 'SYMLINK_ANCESTOR')
    return path


def record(path: Path) -> dict:
    with regular(path).open('rb') as handle:
        before = os.fstat(handle.fileno())
        sha, count = hashlib.sha256(), 0
        for block in iter(lambda: handle.read(1024**2), b''):
            count += len(block)
            sha.update(block)
        after = os.fstat(handle.fileno())
    require((before.st_dev, before.st_ino, before.st_size, before.st_mtime_ns) ==
            (after.st_dev, after.st_ino, after.st_size, after.st_mtime_ns)
            and count == before.st_size, 'FILE_CHANGED_DURING_READ')
    return {'bytes': count, 'sha256': sha.hexdigest()}


def blob(data: bytes) -> str:
    return hashlib.sha1(b'blob ' + str(len(data)).encode() + b'\0' + data).hexdigest()


class Evidence:
    def __init__(self, root: Path, token: str = ''):
        self.root, self.token, self.counter = root, token.encode(), 0

    def write(self, path: Path, data: bytes) -> Path:
        require(path.resolve().is_relative_to(self.root.resolve()), 'EVIDENCE_OUTSIDE_OUTPUT')
        if (self.token and self.token in data) or SIGNED_QUERY.search(data):
            omitted = path.with_name(path.name + '.omitted.json')
            omitted.parent.mkdir(parents=True, exist_ok=True)
            with omitted.open('xb') as handle:
                handle.write(encoded({'status': 'SECRET_BEARING_RESPONSE_NOT_STORED',
                                      'bytes': len(data), 'sha256': hashlib.sha256(data).hexdigest()}))
            raise PublicationError('SECRET_BEARING_RESPONSE_NOT_STORED')
        path.parent.mkdir(parents=True, exist_ok=True)
        with path.open('xb') as handle:
            handle.write(data)
        return path

    def json(self, path: Path, value) -> Path:
        return self.write(path, encoded(value))

    def entry(self, label: str) -> Path:
        require(re.fullmatch('[a-z0-9-]+', label) is not None, 'INVALID_EVIDENCE_LABEL')
        self.counter += 1
        path = self.root/'operations'/f'{self.counter:04d}-{label}'
        path.mkdir(parents=True, exist_ok=False)
        return path


@dataclass(frozen=True)
class Reply:
    value: object
    raw: bytes
    original: Path


class NoRedirect(urllib.request.HTTPRedirectHandler):
    def redirect_request(self, req, fp, code, msg, headers, newurl):
        return None


class GitHub:
    """No retries, no cookie jar, and no automatic authenticated redirects."""
    def __init__(self, evidence: Evidence, token: str):
        require(bool(token) and '\n' not in token and '\r' not in token, 'MISSING_TOKEN')
        self.evidence, self.token = evidence, token
        self.opener = urllib.request.build_opener(NoRedirect())

    @staticmethod
    def address(url: str, *, download: bool = False) -> None:
        parsed = urllib.parse.urlsplit(url)
        require(parsed.scheme == 'https' and parsed.username is None and parsed.password is None
                and parsed.port in (None, 443) and not parsed.fragment, 'UNSAFE_HTTPS_ADDRESS')
        host = parsed.hostname or ''
        hosts = host in ('api.github.com', 'uploads.github.com')
        if download:
            hosts = hosts or host == 'github.com' or host.endswith('.githubusercontent.com') \
                or host.endswith('.blob.core.windows.net')
        require(hosts, 'UNEXPECTED_HTTPS_HOST')

    def _open(self, request, timeout):
        try:
            return self.opener.open(request, timeout=timeout)
        except urllib.error.HTTPError as response:
            return response

    def call(self, method: str, path: str, *, payload: Path | None = None,
             upload: Path | None = None, expected: int = 200) -> Reply:
        require(method in ('GET', 'POST', 'PATCH'), 'UNSUPPORTED_HTTP_METHOD')
        require(path.startswith('/') and not path.startswith('//'), 'INVALID_API_PATH')
        is_upload = upload is not None
        if method != 'GET':
            permitted = (method == 'POST' and path == '/git/refs') or \
                (method == 'POST' and path == '/releases') or \
                (method == 'PATCH' and re.fullmatch(r'/releases/[1-9][0-9]*', path)) or \
                (method == 'POST' and is_upload and
                 re.fullmatch(r'/releases/[1-9][0-9]*/assets\?name=[A-Za-z0-9.\-]+', path))
            require(bool(permitted), 'MUTATION_ENDPOINT_OUTSIDE_SCOPE')
        require(not (payload is not None and is_upload), 'AMBIGUOUS_REQUEST_BODY')
        require((method == 'GET') == (payload is None and upload is None), 'MISSING_REQUEST_BODY')
        url = (UPLOAD if is_upload else API) + path
        self.address(url)
        entry = self.evidence.entry('api-' + method.lower())
        original = record(upload or payload) if upload or payload else None
        self.evidence.json(entry/'request.json', {
            'method': method, 'endpoint': url, 'request_body': original,
            'mutation_attempted_once': method != 'GET', 'automatic_retry': False,
        })
        headers = {'Accept': 'application/vnd.github+json', 'User-Agent': 'lumo-c4-publisher',
                   'X-GitHub-Api-Version': API_VERSION, 'Authorization': 'Bearer ' + self.token}
        body, opened = None, None
        if upload is not None:
            opened = regular(upload).open('rb')
            body = opened
            headers.update({'Content-Type': 'application/octet-stream',
                            'Content-Length': str(original['bytes'])})
        elif payload is not None:
            body = regular(payload).read_bytes()
            require({'bytes': len(body), 'sha256': hashlib.sha256(body).hexdigest()} == original,
                    'REQUEST_BODY_CHANGED')
            headers.update({'Content-Type': 'application/json', 'Content-Length': str(len(body))})
        started = time.monotonic()
        try:
            request = urllib.request.Request(url, data=body, headers=headers, method=method)
            with self._open(request, timeout=60) as response:
                status = response.code
                self.evidence.json(entry/'response-status.json', {'status': status,
                    'date': response.headers.get('Date'), 'request_id': response.headers.get('X-GitHub-Request-Id')})
                raw = response.read(MAX_JSON + 1)
                require(len(raw) <= MAX_JSON, 'API_RESPONSE_TOO_LARGE')
                original_path = self.evidence.write(entry/'response.json', raw)
                require(time.monotonic() - started <= OPERATION_SECONDS, 'HTTP_RESPONSE_TOO_LATE')
                require(status == expected, 'UNEXPECTED_HTTP_STATUS_NO_RETRY')
            require(upload is None or record(upload) == original, 'UPLOAD_SOURCE_CHANGED')
            return Reply(strict_json(raw), raw, original_path)
        except (OSError, TimeoutError, urllib.error.URLError) as exc:
            self.evidence.json(entry/'transport-error.json', {
                'exception_class': type(exc).__name__, 'status': 'TRANSPORT_FAILED',
                'mutation_outcome_may_be_unknown': method != 'GET', 'retried': False,
            })
            raise PublicationError('HTTP_TRANSPORT_FAILED_NO_RETRY') from exc
        finally:
            if opened is not None:
                opened.close()

    def download(self, url: str, destination: Path, expected: dict, *, authenticated: bool) -> dict:
        require(type(expected.get('bytes')) is int and 0 < expected['bytes'] <= MAX_ARCHIVE
                and re.fullmatch('[a-f0-9]{64}', str(expected.get('sha256'))), 'INVALID_DOWNLOAD_IDENTITY')
        original_url, started = url, time.monotonic()
        entry = self.evidence.entry('artifact-download' if authenticated else 'public-download')
        self.evidence.json(entry/'request.json', {'canonical_url': original_url,
            'authentication_on_initial_api_request': authenticated, 'expected': expected,
            'signed_redirect_urls_retained': False, 'automatic_retry': False})
        for hop in range(MAX_REDIRECTS + 1):
            self.address(url, download=True)
            require(time.monotonic() - started < OPERATION_SECONDS, 'DOWNLOAD_DEADLINE')
            headers = {'User-Agent': 'lumo-c4-publisher'}
            if authenticated and hop == 0:
                require(url.startswith(API + '/actions/artifacts/'), 'INVALID_ARTIFACT_DOWNLOAD_ENDPOINT')
                headers.update({'Authorization': 'Bearer ' + self.token,
                                'Accept': 'application/vnd.github+json',
                                'X-GitHub-Api-Version': API_VERSION})
            try:
                with self._open(urllib.request.Request(url, headers=headers, method='GET'), 60) as response:
                    self.evidence.json(entry/f'hop-{hop}.json', {
                        'status': response.code, 'host': urllib.parse.urlsplit(url).hostname,
                        'authorization_sent': bool(authenticated and hop == 0),
                        'date': response.headers.get('Date'),
                        'location_retained': False,
                    })
                    if response.code in (301, 302, 303, 307, 308):
                        location = response.headers.get('Location')
                        require(bool(location) and hop < MAX_REDIRECTS, 'INVALID_DOWNLOAD_REDIRECT')
                        url = urllib.parse.urljoin(url, location)
                        self.address(url, download=True)
                        continue
                    require(response.code == 200, 'DOWNLOAD_HTTP_STATUS')
                    length = response.headers.get('Content-Length')
                    require(length is None or (length.isdigit() and int(length) == expected['bytes']),
                            'DOWNLOAD_CONTENT_LENGTH')
                    sha, count = hashlib.sha256(), 0
                    with destination.open('xb') as handle:
                        while True:
                            data = response.read(1024**2)
                            if not data:
                                break
                            count += len(data)
                            require(count <= expected['bytes'], 'DOWNLOAD_TOO_LARGE')
                            require(time.monotonic() - started < OPERATION_SECONDS, 'DOWNLOAD_DEADLINE')
                            sha.update(data)
                            handle.write(data)
                    actual = {'bytes': count, 'sha256': sha.hexdigest()}
                    self.evidence.json(entry/'download-result.json', {
                        'actual': actual, 'expected': expected, 'redirects': hop,
                        'status': 'BYTES_MATCH' if actual == expected else 'BYTES_DIFFER',
                        'unauthenticated_on_every_hop': not authenticated,
                    })
                    require(actual == expected and record(destination) == expected, 'DOWNLOAD_BYTES_DIFFER')
                    return actual
            except (OSError, TimeoutError, urllib.error.URLError) as exc:
                self.evidence.json(entry/'transport-error.json', {
                    'exception_class': type(exc).__name__, 'retried': False,
                    'partial_file': record(destination) if destination.is_file() else None})
                raise PublicationError('DOWNLOAD_TRANSPORT_FAILED_NO_RETRY') from exc
        raise PublicationError('DOWNLOAD_REDIRECT_LIMIT')


def child_environment() -> dict:
    # The unchanged read-only verifier does not need any publication credential.
    env = {key: os.environ[key] for key in
           ('PATH', 'HOME', 'LANG', 'LC_ALL', 'LC_CTYPE', 'TZ', 'TMPDIR', 'SYSTEMROOT')
           if key in os.environ}
    env.update({'GIT_OPTIONAL_LOCKS': '0', 'GIT_NO_LAZY_FETCH': '1',
                'GIT_TERMINAL_PROMPT': '0', 'PYTHONDONTWRITEBYTECODE': '1'})
    return env


class SourceGuard:
    def __init__(self, path: Path, sha: str, tree: str, *, candidate: bool,
                 evidence: Evidence | None = None):
        self.path, self.sha, self.tree = path.resolve(), sha, tree
        self.candidate, self.evidence = candidate, evidence
        self.before = self.snapshot()

    def git(self, *args) -> bytes:
        try:
            result = subprocess.run(['git', *args], cwd=self.path, env=child_environment(),
                                    stdin=subprocess.DEVNULL, stdout=subprocess.PIPE,
                                    stderr=subprocess.PIPE, timeout=60, check=False)
        except (OSError, subprocess.TimeoutExpired) as exc:
            if self.evidence is not None:
                entry = self.evidence.entry('source-git-failure')
                self.evidence.write(entry/'stdout.log', getattr(exc, 'stdout', None) or b'')
                self.evidence.write(entry/'stderr.log', getattr(exc, 'stderr', None) or b'')
                self.evidence.json(entry/'result.json', {'argv': ['git', *args], 'cwd': str(self.path),
                    'exit_code': None, 'exception_class': type(exc).__name__})
            raise PublicationError('SOURCE_GIT_READ_FAILED') from exc
        if result.returncode != 0 and self.evidence is not None:
            entry = self.evidence.entry('source-git-failure')
            self.evidence.write(entry/'stdout.log', result.stdout)
            self.evidence.write(entry/'stderr.log', result.stderr)
            self.evidence.json(entry/'result.json', {'argv': ['git', *args], 'cwd': str(self.path),
                'exit_code': result.returncode})
        require(result.returncode == 0, 'SOURCE_GIT_READ_FAILED')
        return result.stdout

    def snapshot(self) -> dict:
        require(self.git('rev-parse', '--show-toplevel').decode().strip() == str(self.path),
                'SOURCE_ROOT_DIFFERS')
        require(self.git('rev-parse', 'HEAD').decode().strip() == self.sha and
                self.git('rev-parse', 'HEAD^{tree}').decode().strip() == self.tree,
                'SOURCE_HEAD_OR_TREE_DIFFERS')
        require(self.git('status', '--porcelain=v1', '-z', '--untracked-files=all') == b'',
                'SOURCE_CHECKOUT_NOT_CLEAN')
        require(self.git('diff', '--exit-code', 'HEAD', '--') == b'', 'SOURCE_BYTES_CHANGED')
        index = Path(self.git('rev-parse', '--git-path', 'index').decode().strip())
        if not index.is_absolute():
            index = self.path/index
        names = [*VERIFIER_SOURCES, 'config/godot-source.json', 'pubspec.yaml', WORKFLOW] \
            if self.candidate else ['scripts/publish_connect_four_delivery.py']
        files = {}
        for name in names:
            data = regular(self.path/name).read_bytes()
            require(self.git('show', 'HEAD:' + name) == data, 'SOURCE_FILE_NOT_COMMITTED')
            identity = record(self.path/name)
            if name in VERIFIER_SOURCES:
                require(identity['sha256'] == VERIFIER_SOURCES[name], 'VERIFIER_CHANGED')
            files[name] = {**identity, 'git_blob': blob(data)}
        return {'head': self.sha, 'tree': self.tree, 'index': record(index),
                'stage_sha256': hashlib.sha256(self.git('ls-files', '--stage', '-z')).hexdigest(),
                'files': files, 'status': 'CLEAN'}

    def check(self):
        require(self.snapshot() == self.before, 'SOURCE_OR_INDEX_CHANGED')


class Verifier:
    def __init__(self, candidate: SourceGuard, publisher: SourceGuard, evidence: Evidence):
        self.candidate, self.publisher, self.evidence = candidate, publisher, evidence

    def call(self, command: str, **arguments):
        require(command in ('check-current', 'check-vacant', 'check-tag', 'check-release', 'verify-public'),
                'VERIFIER_COMMAND_OUTSIDE_SCOPE')
        self.candidate.check()
        self.publisher.check()
        entry = self.evidence.entry('verifier-' + command)
        argv = [sys.executable, '-B', str(self.candidate.path/'scripts/verify_connect_four_delivery.py'), command]
        for name, value in arguments.items():
            argv.extend(['--' + name.replace('_', '-'), str(value)])
        self.evidence.json(entry/'command.json', {'argv': argv, 'cwd': str(self.candidate.path)})
        env = child_environment()
        # Do not load an ignored, pre-existing bytecode file in the checkout.
        env['PYTHONPYCACHEPREFIX'] = str(entry/'unused-bytecode-cache')
        started = time.monotonic()
        try:
            result = subprocess.run(argv, cwd=self.candidate.path, env=env, stdin=subprocess.DEVNULL,
                                    stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=900, check=False)
            self.evidence.write(entry/'stdout.log', result.stdout)
            self.evidence.write(entry/'stderr.log', result.stderr)
            self.evidence.json(entry/'result.json', {'exit_code': result.returncode,
                'elapsed_seconds': time.monotonic() - started, 'timed_out': False})
            require(result.returncode == 0, 'UNCHANGED_VERIFIER_REJECTED')
        except subprocess.TimeoutExpired as exc:
            self.evidence.write(entry/'stdout.log', exc.stdout or b'')
            self.evidence.write(entry/'stderr.log', exc.stderr or b'')
            self.evidence.json(entry/'result.json', {'exit_code': None, 'timed_out': True})
            raise PublicationError('UNCHANGED_VERIFIER_TIMEOUT') from exc
        self.candidate.check()
        self.publisher.check()


def extract_bundle(archive: Path, destination: Path, expected: dict) -> dict:
    require(expected['bytes'] <= MAX_ARCHIVE and record(archive) == expected, 'BUNDLE_ARCHIVE_IDENTITY')
    require(not destination.exists(), 'BUNDLE_OUTPUT_ALREADY_EXISTS')
    seen, files, total = set(), [], 0
    try:
        with zipfile.ZipFile(archive) as zipped:
            items = zipped.infolist()
            require(0 < len(items) <= MAX_MEMBERS, 'BUNDLE_MEMBER_COUNT')
            for item in items:
                name, path = item.filename, PurePosixPath(item.filename)
                require(item.orig_filename == name and '\x00' not in name and '\\' not in name
                        and not item.flag_bits & 1 and not path.is_absolute()
                        and path.parts and '..' not in path.parts
                        and path.as_posix() == name.rstrip('/')
                        and all(ord(c) >= 32 and ord(c) != 127 for c in name)
                        and ':' not in name and path.as_posix() not in seen, 'UNSAFE_BUNDLE_PATH')
                seen.add(path.as_posix())
                kind = stat.S_IFMT(item.external_attr >> 16)
                if item.is_dir():
                    require(kind in (0, stat.S_IFDIR) and item.file_size == 0, 'INVALID_BUNDLE_DIRECTORY')
                else:
                    require(kind in (0, stat.S_IFREG), 'NONREGULAR_BUNDLE_MEMBER')
                    total += item.file_size
                    require(total <= MAX_UNPACKED, 'UNPACKED_BUNDLE_TOO_LARGE')
                    files.append((item, path))
            file_names = {path.as_posix() for _, path in files}
            require(all(not any(parent.as_posix() in file_names for parent in path.parents)
                        for _, path in files), 'BUNDLE_FILE_DIRECTORY_COLLISION')
            destination.mkdir()
            result = {}
            for item, relative in files:
                output = destination/relative
                output.parent.mkdir(parents=True, exist_ok=True)
                sha, count = hashlib.sha256(), 0
                with zipped.open(item) as source, output.open('xb') as target:
                    for data in iter(lambda: source.read(1024**2), b''):
                        count += len(data)
                        require(count <= item.file_size, 'BUNDLE_MEMBER_TOO_LARGE')
                        sha.update(data)
                        target.write(data)
                require(count == item.file_size, 'BUNDLE_MEMBER_TRUNCATED')
                result[relative.as_posix()] = {'bytes': count, 'sha256': sha.hexdigest()}
                require(record(output) == result[relative.as_posix()], 'BUNDLE_MEMBER_READBACK')
            require(record(archive) == expected, 'BUNDLE_ARCHIVE_CHANGED')
            return result
    except PublicationError:
        raise
    except (zipfile.BadZipFile, RuntimeError, NotImplementedError) as exc:
        raise PublicationError('BUNDLE_CRC_OR_FORMAT_FAILED') from exc


@dataclass(frozen=True)
class Inputs:
    candidate_source: Path
    publisher_source: Path
    host_sha: str
    host_tree: str
    publisher_sha: str
    publisher_tree: str
    build_run: int
    run_attempt: int
    bundle_artifact_id: int
    bundle_artifact_digest: str
    bundle_artifact_size: int
    pull_request: int
    output: Path
    bundle_archive: Path | None = None

    def validate(self):
        paths = [self.candidate_source, self.publisher_source, self.output]
        if self.bundle_archive is not None:
            paths.append(self.bundle_archive)
        require(all(path.is_absolute() for path in paths), 'ABSOLUTE_PATHS_REQUIRED')
        require(all(re.fullmatch('[a-f0-9]{40}', value) for value in
                    (self.host_sha, self.host_tree, self.publisher_sha, self.publisher_tree)),
                'INVALID_SOURCE_IDENTITY')
        require(all(type(value) is int and value > 0 for value in
                    (self.build_run, self.run_attempt, self.bundle_artifact_id)), 'INVALID_NUMERIC_IDENTITY')
        require(self.pull_request == 485 and type(self.pull_request) is int, 'WRONG_PULL_REQUEST')
        require(re.fullmatch('sha256:[a-f0-9]{64}', self.bundle_artifact_digest) is not None,
                'INVALID_BUNDLE_DIGEST')
        require(type(self.bundle_artifact_size) is int and
                0 < self.bundle_artifact_size <= MAX_ARCHIVE, 'INVALID_BUNDLE_SIZE')
        require(self.candidate_source.resolve() != self.publisher_source.resolve(),
                'SEPARATE_PUBLISHER_SOURCE_REQUIRED')
        for root in (self.candidate_source, self.publisher_source):
            require(not self.output.resolve().is_relative_to(root.resolve()), 'OUTPUT_INSIDE_CHECKOUT')
        require(not self.output.exists(), 'OUTPUT_ALREADY_EXISTS_NO_RESUME')

    @property
    def archive_identity(self):
        return {'bytes': self.bundle_artifact_size, 'sha256': self.bundle_artifact_digest[7:]}


class Publisher:
    def __init__(self, inputs: Inputs, api: GitHub, verifier: Verifier,
                 candidate: SourceGuard, publisher: SourceGuard, evidence: Evidence):
        self.inputs, self.api, self.verifier = inputs, api, verifier
        self.candidate, self.publisher, self.evidence = candidate, publisher, evidence
        self.delivery = inputs.output/'delivery'
        self.archive = inputs.bundle_archive or inputs.output/'original-delivery.zip'
        self.phase = 'INITIAL'
        self.started = time.monotonic()
        self.created = None
        self.uploads = {}

    def check_sources(self):
        require(time.monotonic() - self.started < 3600, 'PUBLICATION_DECISION_BUDGET')
        self.candidate.check()
        self.publisher.check()

    def pages(self, path: str, label: str, key: str | None = None) -> tuple[list, list]:
        pages, rows, originals, declared = [], [], [], None
        for page in range(1, MAX_PAGES + 1):
            reply = self.api.call('GET', path + f'?per_page=100&page={page}')
            value = reply.value
            if key is not None:
                require(type(value) is dict and type(value.get('total_count')) is int,
                        'INCOMPLETE_PAGED_OBJECT')
                if declared is None:
                    declared = value['total_count']
                require(value['total_count'] == declared, 'PAGINATION_CHANGED_DURING_READ')
                current = value.get(key)
            else:
                current = value
            require(type(current) is list and len(current) <= 100 and
                    all(type(row) is dict for row in current), 'INVALID_PAGE')
            pages.append(current)
            rows.extend(current)
            originals.append({'path': str(reply.original), **record(reply.original)})
            if not current:
                require(key is None or declared == len(rows), 'INCOMPLETE_TOTAL_COUNT')
                self.evidence.json(self.evidence.entry('collection-' + label)/'pages.json', {
                    'originals': originals, 'derived_row_count': len(rows), 'terminal_empty_page': page})
                return pages, rows
        raise PublicationError('PAGINATION_LIMIT')

    def fresh_head(self) -> tuple[Reply, Reply]:
        args = self.inputs
        run = self.api.call('GET', f'/actions/runs/{args.build_run}')
        pull = self.api.call('GET', f'/pulls/{args.pull_request}')
        self.check_run(run.value)
        p = pull.value
        require(type(p) is dict and p.get('number') == args.pull_request and p.get('state') == 'open'
                and p.get('head', {}).get('sha') == args.host_sha
                and p.get('head', {}).get('ref') == BRANCH
                and p.get('head', {}).get('repo', {}).get('full_name') == REPOSITORY
                and p.get('base', {}).get('repo', {}).get('full_name') == REPOSITORY,
                'PULL_HEAD_MOVED_OR_CLOSED')
        self.check_sources()
        return run, pull

    def check_run(self, run):
        args = self.inputs
        require(type(run) is dict and run.get('id') == args.build_run and
                run.get('run_attempt') == args.run_attempt and run.get('head_sha') == args.host_sha
                and run.get('head_branch') == BRANCH and run.get('path') == WORKFLOW
                and run.get('event') == 'pull_request' and run.get('status') == 'completed'
                and run.get('conclusion') == 'success'
                and run.get('repository', {}).get('full_name') == REPOSITORY,
                'CANDIDATE_RUN_NOT_EXACT_SUCCESS')

    def metadata(self) -> Path:
        args = self.inputs
        latest, pull = self.fresh_head()
        attempt = self.api.call('GET', f'/actions/runs/{args.build_run}/attempts/{args.run_attempt}')
        self.check_run(attempt.value)
        _, jobs = self.pages(f'/actions/runs/{args.build_run}/attempts/{args.run_attempt}/jobs', 'jobs', 'jobs')
        _, artifacts = self.pages(f'/actions/runs/{args.build_run}/artifacts', 'artifacts', 'artifacts')
        require(len(jobs) == 7 and {row.get('name') for row in jobs} == JOBS and
                all(row.get('run_id') == args.build_run and row.get('run_attempt') == args.run_attempt
                    and row.get('head_sha') == args.host_sha and row.get('status') == 'completed'
                    and row.get('conclusion') == 'success' for row in jobs), 'SEVEN_SUCCESSFUL_JOBS_REQUIRED')
        require(all(type(row.get('id')) is int and row['id'] > 0 for row in [*jobs, *artifacts])
                and len({row.get('id') for row in jobs}) == len(jobs) and
                len({row.get('id') for row in artifacts}) == len(artifacts), 'DUPLICATE_API_ID')
        bundle = [row for row in artifacts if row.get('name') == BUNDLE]
        require(len(bundle) == 1, 'MISSING_OR_DUPLICATE_BUNDLE')
        row = bundle[0]
        require(row.get('id') == args.bundle_artifact_id and row.get('expired') is False
                and row.get('size_in_bytes') == args.bundle_artifact_size
                and row.get('digest') == args.bundle_artifact_digest
                and row.get('workflow_run', {}).get('id') == args.build_run
                and row.get('workflow_run', {}).get('head_sha') == args.host_sha,
                'BUNDLE_API_IDENTITY_DIFFERS')
        metadata = self.evidence.entry('current-metadata')
        self.evidence.write(metadata/'latest-run.json', latest.raw)
        self.evidence.write(metadata/'run.json', attempt.raw)
        self.evidence.write(metadata/'pull.json', pull.raw)
        self.evidence.json(metadata/'jobs.json', {'total_count': len(jobs), 'jobs': jobs})
        self.evidence.json(metadata/'artifacts.json', {'total_count': len(artifacts), 'artifacts': artifacts})
        self.evidence.json(metadata/'provenance.json', {
            'run_and_pull': 'Byte-identical original response bodies',
            'jobs_and_artifacts': 'Lossless arrays aggregated from separately retained complete original pages'})
        return metadata

    def catalog(self) -> tuple[Path, dict]:
        pages, releases = self.pages('/releases', 'releases')
        _, tags = self.pages('/tags', 'tags')
        refs_reply = self.api.call('GET', '/git/matching-refs/tags/')
        refs = refs_reply.value
        require(type(refs) is list and all(type(row) is dict for row in refs), 'INVALID_TAG_REFS')
        names = [row.get('ref') for row in refs]
        require(all(isinstance(name, str) and name.startswith('refs/tags/') for name in names)
                and all(type(row.get('name')) is str and row['name'] for row in tags)
                and all(type(row.get('object')) is dict and row['object'].get('type') in ('commit', 'tag')
                        and re.fullmatch('[a-f0-9]{40}', str(row['object'].get('sha'))) for row in refs)
                and len(set(names)) == len(names)
                and len({row.get('name') for row in tags}) == len(tags)
                and {name[10:] for name in names} == {row.get('name') for row in tags},
                'TAG_CATALOG_INCOMPLETE_OR_DUPLICATED')
        require(all(type(row.get('id')) is int and row['id'] > 0 for row in releases)
                and len({row.get('id') for row in releases}) == len(releases), 'DUPLICATE_RELEASE_ID')
        directory = self.evidence.entry('complete-catalog')
        self.evidence.json(directory/'releases.json', pages)
        self.evidence.write(directory/'tags.json', refs_reply.raw)
        self.evidence.json(directory/'provenance.json', {
            'releases': 'Array of complete original page values; raw page responses retained separately',
            'tags': 'Original matching-refs response cross-checked against all paginated repository tags'})
        signatures = {'releases': {}, 'tags': {row['ref']: row.get('object') for row in refs}}
        for row in releases:
            signatures['releases'][str(row['id'])] = {key: row.get(key) for key in
                ('id', 'tag_name', 'target_commitish', 'draft', 'prerelease', 'published_at')}
        return directory, signatures

    def catalog_after_creation(self):
        _, current = self.catalog()
        expected = dict(self.baseline['tags'])
        own = current['tags'].pop('refs/tags/' + TAG, None)
        require(type(own) is dict and own.get('type') == 'commit'
                and own.get('sha') == self.inputs.host_sha and current['tags'] == expected,
                'TAG_CATALOG_CHANGED')
        if self.created is not None:
            own_release = current['releases'].pop(str(self.created.value['id']), None)
            require(own_release is not None and own_release['tag_name'] == TAG
                    and own_release['target_commitish'] == self.inputs.host_sha
                    and own_release['draft'] is True and own_release['prerelease'] is True,
                    'NEW_DRAFT_IDENTITY_CHANGED')
        require(current['releases'] == self.baseline['releases'], 'RELEASE_CATALOG_CHANGED')

    def verifier_call(self, command, **kwargs):
        self.verifier.call(command, delivery=self.delivery, **kwargs)

    def check_current(self):
        self.verifier_call('check-current', metadata=self.metadata(), pull_request=self.inputs.pull_request,
                           bundle_archive=self.archive, bundle_artifact_id=self.inputs.bundle_artifact_id)

    def prepared(self):
        plan = strict_json(regular(self.delivery/'publication-plan.json').read_bytes())
        facts = strict_json(regular(self.delivery/'assets/C4-DELIVERY-FACTS.json').read_bytes())
        args = self.inputs
        require(plan.get('host_source') == args.host_sha and plan.get('tag') == TAG
                and plan.get('versionCode') == 2020 and set(plan.get('assets', {})) == ASSETS,
                'PREPARED_PLAN_IDENTITY')
        require(facts.get('host_source') == args.host_sha and facts.get('host_tree') == args.host_tree
                and facts.get('binding', {}).get('host_source') == args.host_sha
                and facts.get('binding', {}).get('run_id') == args.build_run
                and facts.get('binding', {}).get('run_attempt') == args.run_attempt,
                'PREPARED_FACTS_IDENTITY')
        config = strict_json(regular(args.candidate_source/'config/godot-source.json').read_bytes())
        require(facts.get('native_source') == facts.get('binding', {}).get('native_source') == config.get('revision'),
                'PREPARED_NATIVE_PIN_DIFFERS')
        self.payloads = {}
        for name in ('create-tag', 'create-release', 'publish-release'):
            path = self.delivery/'audit'/(name + '.json')
            self.payloads[name] = (path, record(path))
        create_tag = strict_json(self.payloads['create-tag'][0].read_bytes())
        create_release = strict_json(self.payloads['create-release'][0].read_bytes())
        publish = strict_json(self.payloads['publish-release'][0].read_bytes())
        require(create_tag == {'ref': 'refs/tags/' + TAG, 'sha': args.host_sha}, 'PREPARED_TAG_PAYLOAD')
        require(set(create_release) == {'tag_name', 'target_commitish', 'name', 'body', 'draft',
                'prerelease', 'make_latest', 'generate_release_notes'}
                and create_release['tag_name'] == TAG and create_release['target_commitish'] == args.host_sha
                and create_release['draft'] is True and create_release['prerelease'] is True
                and create_release['make_latest'] == 'false' and create_release['generate_release_notes'] is False
                and create_release['name'] == 'Lumo 2020 ARM64 Test-APK'
                and type(create_release['body']) is str and bool(create_release['body']),
                'PREPARED_RELEASE_PAYLOAD')
        require(publish == {'draft': False, 'make_latest': 'false'}, 'PREPARED_PUBLISH_PAYLOAD')
        require(regular(self.delivery/'audit/asset-names.txt').read_bytes() ==
                ''.join(name + '\n' for name in sorted(ASSETS)).encode(), 'PREPARED_ASSET_ORDER')
        require(plan.get('download_url') ==
                f'https://github.com/{REPOSITORY}/releases/download/{TAG}/Lumo-Lernen-Neu.apk',
                'PREPARED_PUBLIC_URL')
        self.plan = plan

    def mutate(self, method, path, *, payload_name=None, upload=None):
        self.fresh_head()
        payload = None
        if payload_name is not None:
            payload, identity = self.payloads[payload_name]
            require(record(payload) == identity, 'PREPARED_PAYLOAD_CHANGED')
        if upload is not None:
            require(record(upload) == self.plan['assets'][upload.name], 'UPLOAD_BYTES_CHANGED')
        return self.api.call(method, path, payload=payload, upload=upload,
                             expected=200 if method == 'PATCH' else 201)

    def current_tag(self):
        tag = self.api.call('GET', '/git/ref/tags/' + TAG)
        self.verifier_call('check-tag', tag=tag.original)
        return tag

    def current_release(self, stage):
        tag = self.current_tag()
        release_id = self.created.value['id']
        release = self.api.call('GET', f'/releases/{release_id}')
        self.verifier_call('check-release', tag=tag.original, created=self.created.original,
                           release=release.original, stage=stage)
        _, assets = self.pages(f'/releases/{release_id}/assets', 'release-assets')
        fields = ('id', 'name', 'state', 'size', 'digest', 'browser_download_url')
        def identities(rows):
            require(type(rows) is list and all(type(row) is dict for row in rows), 'INVALID_RELEASE_ASSETS')
            result = {row.get('name'): {field: row.get(field) for field in fields} for row in rows}
            require(len(result) == len(rows), 'DUPLICATE_RELEASE_ASSET_NAME')
            return result
        require(identities(assets) == identities(release.value.get('assets')), 'RELEASE_ASSET_PAGES_DIFFER')
        if stage != 'empty-draft':
            require(identities(assets) == self.uploads, 'RELEASE_ASSET_IDS_OR_BYTES_CHANGED')
        return tag, release

    def run(self):
        self.phase = 'INITIAL_CURRENT_METADATA'
        metadata = self.metadata()
        if self.inputs.bundle_archive is None:
            self.api.download(API + f'/actions/artifacts/{self.inputs.bundle_artifact_id}/zip',
                              self.archive, self.inputs.archive_identity, authenticated=True)
        self.phase = 'COMPLETE_ORIGINAL_BUNDLE'
        members = extract_bundle(self.archive, self.delivery, self.inputs.archive_identity)
        self.evidence.json(self.inputs.output/'original-bundle-inventory.json', {
            'archive': self.inputs.archive_identity, 'artifact_id': self.inputs.bundle_artifact_id,
            'original_archive_path': str(self.archive), 'members': members,
            'all_members_crc_and_sha256_checked': True})
        self.prepared()
        self.verifier_call('check-current', metadata=metadata, pull_request=self.inputs.pull_request,
                           bundle_archive=self.archive, bundle_artifact_id=self.inputs.bundle_artifact_id)
        self.phase = 'VACANCY'
        catalog, self.baseline = self.catalog()
        self.verifier_call('check-vacant', metadata=catalog)
        self.phase = 'CREATE_NEW_TAG'
        self.mutate('POST', '/git/refs', payload_name='create-tag')
        self.current_tag()
        self.catalog_after_creation()
        self.phase = 'CREATE_NEW_EMPTY_DRAFT'
        self.created = self.mutate('POST', '/releases', payload_name='create-release')
        require(type(self.created.value.get('id')) is int and self.created.value['id'] > 0,
                'INVALID_CREATED_RELEASE_ID')
        self.current_release('empty-draft')
        release_id = self.created.value['id']
        self.phase = 'UPLOAD_EXACTLY_ELEVEN_ASSETS'
        for name in sorted(ASSETS):
            reply = self.mutate('POST', f'/releases/{release_id}/assets?name={name}',
                                upload=self.delivery/'assets'/name)
            row = reply.value
            wanted = self.plan['assets'][name]
            require(type(row) is dict and type(row.get('id')) is int and row['id'] > 0
                    and row.get('name') == name and row.get('state') == 'uploaded'
                    and row.get('size') == wanted['bytes'] and row.get('digest') == 'sha256:' + wanted['sha256']
                    and row.get('browser_download_url') ==
                    f'https://github.com/{REPOSITORY}/releases/download/{TAG}/{name}'
                    and row['id'] not in {asset['id'] for asset in self.uploads.values()},
                    'UPLOADED_ASSET_IDENTITY')
            self.uploads[name] = {key: row[key] for key in
                ('id', 'name', 'state', 'size', 'digest', 'browser_download_url')}
        self.phase = 'FRESH_COMPLETE_PREPUBLICATION_RECHECK'
        self.check_current()
        self.catalog_after_creation()
        self.current_release('uploaded-draft')
        self.phase = 'PUBLISH_NEW_PRERELEASE'
        self.mutate('PATCH', f'/releases/{release_id}', payload_name='publish-release')
        self.phase = 'PUBLISHED_METADATA_AND_UNAUTHENTICATED_BYTES'
        tag, release = self.current_release('published')
        public_apk = self.inputs.output/'public-Lumo-Lernen-Neu.apk'
        self.api.download(self.plan['download_url'], public_apk,
                          self.plan['assets']['Lumo-Lernen-Neu.apk'], authenticated=False)
        self.check_current()
        # Re-read after the full public download; no old draft response is reused.
        tag, release = self.current_release('published')
        receipt = self.inputs.output/'public-verification.json'
        self.verifier_call('verify-public', tag=tag.original, created=self.created.original,
                           release=release.original, apk=public_apk, receipt=receipt)
        result = strict_json(regular(receipt).read_bytes())
        require(result.get('status') == 'PUBLIC_TEST_APK_BYTES_VERIFIED'
                and result.get('host_source') == self.inputs.host_sha
                and result.get('public_apk') == self.plan['assets']['Lumo-Lernen-Neu.apk'],
                'PUBLIC_RECEIPT_DIFFERS')
        self.check_sources()
        require(record(self.archive) == self.inputs.archive_identity
                and {path.relative_to(self.delivery).as_posix(): record(path)
                     for path in self.delivery.rglob('*') if path.is_file()} == members,
                'ORIGINAL_BUNDLE_CHANGED_AFTER_PUBLICATION')
        self.phase = 'PUBLIC_BYTES_VERIFIED'
        self.evidence.json(self.inputs.output/'completed.json', {
            'status': self.phase, 'host_source': self.inputs.host_sha, 'host_tree': self.inputs.host_tree,
            'build_run': self.inputs.build_run, 'run_attempt': self.inputs.run_attempt,
            'publisher_source': self.inputs.publisher_sha, 'publisher_tree': self.inputs.publisher_tree,
            'bundle_artifact_id': self.inputs.bundle_artifact_id, 'release_id': release_id,
            'download_url': self.plan['download_url'], 'receipt': record(receipt),
            'source_after': {'candidate': self.candidate.snapshot(), 'publisher': self.publisher.snapshot()},
            'scope': 'Publication of the original accepted signed ARM64 TEST APK; no additional runtime claims'})
        return self.plan['download_url']


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    for name in ('candidate-source', 'publisher-source', 'output'):
        parser.add_argument('--' + name, required=True, type=Path)
    for name in ('host-sha', 'host-tree', 'publisher-sha', 'publisher-tree', 'bundle-artifact-digest'):
        parser.add_argument('--' + name, required=True)
    for name in ('build-run', 'run-attempt', 'bundle-artifact-id', 'bundle-artifact-size', 'pull-request'):
        parser.add_argument('--' + name, type=int, required=True)
    parser.add_argument('--bundle-archive', type=Path)
    inputs = Inputs(**vars(parser.parse_args()))
    evidence, publisher = None, None
    try:
        inputs.validate()
        require(Path(__file__).resolve() ==
                (inputs.publisher_source/'scripts/publish_connect_four_delivery.py').resolve(),
                'INVOKED_PUBLISHER_SOURCE_DIFFERS')
        inputs.output.mkdir(parents=True, exist_ok=False)
        token = os.environ.get('GITHUB_TOKEN', '')
        evidence = Evidence(inputs.output, token)
        evidence.json(inputs.output/'explicit-inputs.json', {
            key: str(value) if isinstance(value, Path) else value
            for key, value in vars(inputs).items()})
        evidence.json(inputs.output/'runtime.json', {'python': sys.version, 'executable': sys.executable,
            'started_utc': time.strftime('%Y-%m-%dT%H:%M:%SZ', time.gmtime()),
            'rest_api_version': API_VERSION, 'credential_persisted': False})
        candidate_guard = SourceGuard(inputs.candidate_source, inputs.host_sha, inputs.host_tree,
                                      candidate=True, evidence=evidence)
        publisher_guard = SourceGuard(inputs.publisher_source, inputs.publisher_sha, inputs.publisher_tree,
                                      candidate=False, evidence=evidence)
        evidence.json(inputs.output/'source-before.json', {
            'candidate': candidate_guard.before, 'publisher': publisher_guard.before})
        api = GitHub(evidence, token)
        verifier = Verifier(candidate_guard, publisher_guard, evidence)
        publisher = Publisher(inputs, api, verifier, candidate_guard, publisher_guard, evidence)
        url = publisher.run()
        print('[C4Publication] verified new test APK:', url)
        return 0
    except Exception as exc:
        # The underlying HTTP exception can contain a signed URL. Do not print it.
        code = str(exc) if isinstance(exc, PublicationError) else 'UNEXPECTED_LOCAL_ERROR'
        if evidence is not None:
            failure = {'status': 'FAILED_NO_RESUME', 'phase': publisher.phase if publisher else 'PREFLIGHT',
                       'code': code, 'exception_class': type(exc).__name__,
                       'automatic_retry': False, 'automatic_cleanup': False,
                       'remote_outcome_requires_review': publisher is not None and
                           publisher.phase not in ('INITIAL', 'INITIAL_CURRENT_METADATA',
                                                   'COMPLETE_ORIGINAL_BUNDLE', 'VACANCY')}
            try:
                evidence.json(inputs.output/'failure.json', failure)
            except Exception:
                pass
        print('[C4Publication] failed:', code, file=sys.stderr)
        return 1


if __name__ == '__main__':
    raise SystemExit(main())
