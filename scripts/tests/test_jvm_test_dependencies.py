"""Offline regressions for the shared, digest-pinned JVM test dependency."""
from concurrent.futures import ThreadPoolExecutor
from datetime import datetime, timedelta, timezone
from email.utils import format_datetime
import hashlib
import io
import os
from pathlib import Path
import tempfile
import unittest
from unittest import mock
from urllib.error import HTTPError, URLError
import zipfile

if __package__:
    from . import jvm_test_dependencies as dependency
else:
    import jvm_test_dependencies as dependency


def fixture_jar():
    output = io.BytesIO()
    with zipfile.ZipFile(output, 'w') as archive:
        for name in ('org/json/JSONObject.class', 'org/json/JSONArray.class'):
            archive.writestr(zipfile.ZipInfo(name), b'fixture class bytes')
    return output.getvalue()


class JvmTestDependenciesTest(unittest.TestCase):
    def setUp(self):
        temporary = tempfile.TemporaryDirectory(prefix='lumo-jvm-cache-test-')
        self.addCleanup(temporary.cleanup)
        self.work = Path(temporary.name)
        self.cache = self.work / 'cache'
        self.gradle = self.work / 'gradle'
        self.data = fixture_jar()
        self.digest = hashlib.sha256(self.data).hexdigest()
        environment = mock.patch.dict(os.environ, {
            'LUMO_TEST_DEPS_CACHE': str(self.cache),
            'GRADLE_USER_HOME': str(self.gradle),
        }, clear=True)
        environment.start()
        self.addCleanup(environment.stop)
        digest = mock.patch.object(dependency, 'JSON_SHA256', self.digest)
        digest.start()
        self.addCleanup(digest.stop)
        network = mock.patch.object(dependency, 'urlopen')
        self.urlopen = network.start()
        self.addCleanup(network.stop)
        self.urlopen.side_effect = lambda *args, **kwargs: io.BytesIO(self.data)

    @property
    def cached(self):
        return self.cache / f'json-20240303-{self.digest}.jar'

    def destination(self, name='suite.jar'):
        return self.work / name

    def test_four_suites_share_one_verified_download(self):
        for number in range(4):
            output = dependency.prepare_json_jar(self.destination(f'suite-{number}.jar'))
            self.assertEqual(output.read_bytes(), self.data)
        self.urlopen.assert_called_once()
        self.assertEqual(self.cached.read_bytes(), self.data)
        self.assertEqual(list(self.cache.glob('*.tmp')), [])

    def test_explicit_test_jar_precedes_other_sources(self):
        supplied = self.work / 'supplied.jar'
        supplied.write_bytes(self.data)
        os.environ['LUMO_TEST_JSON_JAR'] = str(supplied)
        os.environ['LUMO_JSON_JAR'] = str(supplied)
        dependency.prepare_json_jar(self.destination())
        self.urlopen.assert_not_called()
        self.assertFalse(self.cache.exists())

    def test_legacy_env_jar_is_reused_without_network(self):
        supplied = self.work / 'existing.jar'
        supplied.write_bytes(self.data)
        os.environ['LUMO_JSON_JAR'] = str(supplied)
        dependency.prepare_json_jar(self.destination())
        self.urlopen.assert_not_called()

    def test_invalid_explicit_jar_does_not_fall_back_to_a_valid_cache(self):
        self.cache.mkdir()
        self.cached.write_bytes(self.data)
        supplied = self.work / 'corrupt.jar'
        supplied.write_bytes(b'wrong dependency')
        os.environ['LUMO_TEST_JSON_JAR'] = str(supplied)
        with self.assertRaisesRegex(RuntimeError, 'digest changed'):
            dependency.prepare_json_jar(self.destination())
        self.urlopen.assert_not_called()
        self.assertFalse(self.destination().exists())
        self.assertEqual(self.cached.read_bytes(), self.data)

    def test_missing_explicit_jar_is_an_error(self):
        os.environ['LUMO_TEST_JSON_JAR'] = str(self.work / 'missing.jar')
        with self.assertRaises(FileNotFoundError):
            dependency.prepare_json_jar(self.destination())
        self.urlopen.assert_not_called()

    def test_invalid_secondary_env_jar_is_not_silently_ignored(self):
        supplied = self.work / 'valid.jar'
        supplied.write_bytes(self.data)
        corrupt = self.work / 'invalid-legacy.jar'
        corrupt.write_bytes(b'wrong dependency')
        os.environ['LUMO_TEST_JSON_JAR'] = str(supplied)
        os.environ['LUMO_JSON_JAR'] = str(corrupt)
        with self.assertRaisesRegex(RuntimeError, 'digest changed'):
            dependency.prepare_json_jar(self.destination())
        self.urlopen.assert_not_called()
        self.assertFalse(self.destination().exists())

    def test_existing_gradle_jar_populates_shared_cache_without_network(self):
        supplied = self.gradle / 'caches/modules-2/files-2.1/org.json/json/20240303/existing/json-20240303.jar'
        supplied.parent.mkdir(parents=True)
        supplied.write_bytes(self.data)
        dependency.prepare_json_jar(self.destination())
        self.urlopen.assert_not_called()
        self.assertEqual(self.cached.read_bytes(), self.data)

    def test_corrupt_gradle_candidate_is_not_used_or_modified(self):
        supplied = self.gradle / 'caches/modules-2/files-2.1/org.json/json/20240303/existing/json-20240303.jar'
        supplied.parent.mkdir(parents=True)
        supplied.write_bytes(b'corrupt cached dependency')
        dependency.prepare_json_jar(self.destination())
        self.urlopen.assert_called_once()
        self.assertEqual(supplied.read_bytes(), b'corrupt cached dependency')
        self.assertEqual(self.destination().read_bytes(), self.data)

    def test_corrupt_shared_cache_is_replaced_only_by_verified_bytes(self):
        self.cache.mkdir()
        self.cached.write_bytes(b'incomplete download')
        dependency.prepare_json_jar(self.destination())
        self.urlopen.assert_called_once()
        self.assertEqual(self.cached.read_bytes(), self.data)

    def test_http_429_honors_numeric_retry_after(self):
        self.urlopen.side_effect = [
            HTTPError(dependency.JSON_URL, 429, 'rate limited', {'Retry-After': '3'}, None),
            io.BytesIO(self.data),
        ]
        with mock.patch.object(dependency.time, 'sleep') as sleep:
            dependency.prepare_json_jar(self.destination())
        sleep.assert_called_once_with(3.0)
        self.assertEqual(self.urlopen.call_count, 2)

    def test_http_retry_after_date_is_honored(self):
        now = datetime(2026, 11, 23, 12, 0, tzinfo=timezone.utc)
        header = format_datetime(now + timedelta(seconds=4), usegmt=True)
        self.urlopen.side_effect = [
            HTTPError(dependency.JSON_URL, 503, 'busy', {'Retry-After': header}, None),
            io.BytesIO(self.data),
        ]
        with mock.patch.object(dependency, 'datetime') as clock, mock.patch.object(dependency.time, 'sleep') as sleep:
            clock.now.return_value = now
            dependency.prepare_json_jar(self.destination())
        sleep.assert_called_once_with(4.0)

    def test_missing_or_invalid_retry_after_uses_bounded_backoff(self):
        for headers in (None, {'Retry-After': 'invalid'}):
            with self.subTest(headers=headers):
                self.urlopen.side_effect = [
                    HTTPError(dependency.JSON_URL, 429, 'busy', headers, None),
                    io.BytesIO(self.data),
                ]
                with mock.patch.object(dependency.time, 'sleep') as sleep:
                    self.assertEqual(dependency._download(), self.data)
                sleep.assert_called_once_with(2.0)

    def test_long_retry_after_uses_mirror_without_retrying_early(self):
        self.urlopen.side_effect = [
            HTTPError(dependency.JSON_URL, 429, 'rate limited', {'Retry-After': '120'}, None),
            io.BytesIO(self.data),
        ]
        with mock.patch.object(dependency.time, 'sleep') as sleep:
            dependency.prepare_json_jar(self.destination())
        sleep.assert_not_called()
        urls = [call.args[0].full_url for call in self.urlopen.call_args_list]
        self.assertEqual(urls, list(dependency._JSON_URLS))

    def test_transient_network_failures_have_a_finite_budget(self):
        self.urlopen.side_effect = URLError('temporary network failure')
        with mock.patch.object(dependency.time, 'sleep') as sleep:
            with self.assertRaisesRegex(RuntimeError, 'bounded retries'):
                dependency.prepare_json_jar(self.destination())
        self.assertEqual(self.urlopen.call_count, 4)
        self.assertEqual(sleep.call_args_list, [mock.call(2.0), mock.call(2.0)])
        self.assertFalse(self.cached.exists())
        self.assertFalse(self.destination().exists())

    def test_non_retryable_http_error_fails_immediately(self):
        self.urlopen.side_effect = HTTPError(dependency.JSON_URL, 404, 'missing', {}, None)
        with mock.patch.object(dependency.time, 'sleep') as sleep:
            with self.assertRaisesRegex(RuntimeError, 'HTTP 404'):
                dependency.prepare_json_jar(self.destination())
        self.urlopen.assert_called_once()
        sleep.assert_not_called()
        self.assertFalse(self.cached.exists())

    def test_bad_digest_is_not_cached_retried_or_hidden_by_mirror(self):
        self.urlopen.side_effect = lambda *args, **kwargs: io.BytesIO(b'wrong bytes')
        with self.assertRaisesRegex(RuntimeError, 'digest changed'):
            dependency.prepare_json_jar(self.destination())
        self.urlopen.assert_called_once()
        self.assertFalse(self.cached.exists())
        self.assertFalse(self.destination().exists())

    def test_matching_digest_does_not_make_non_zip_bytes_a_jar(self):
        data = b'not a zip'
        self.urlopen.side_effect = lambda *args, **kwargs: io.BytesIO(data)
        with mock.patch.object(dependency, 'JSON_SHA256', hashlib.sha256(data).hexdigest()):
            with self.assertRaisesRegex(RuntimeError, 'not a valid ZIP'):
                dependency.prepare_json_jar(self.destination())
        self.assertEqual(list(self.cache.glob('*.jar')), [])

    def test_valid_zip_must_contain_the_json_classes(self):
        output = io.BytesIO()
        with zipfile.ZipFile(output, 'w') as archive:
            archive.writestr('unrelated.txt', 'not org.json')
        data = output.getvalue()
        self.urlopen.side_effect = lambda *args, **kwargs: io.BytesIO(data)
        with mock.patch.object(dependency, 'JSON_SHA256', hashlib.sha256(data).hexdigest()):
            with self.assertRaisesRegex(RuntimeError, 'not a complete JAR'):
                dependency.prepare_json_jar(self.destination())
        self.assertEqual(list(self.cache.glob('*.jar')), [])

    def test_parallel_suites_serialize_cache_population(self):
        with ThreadPoolExecutor(max_workers=4) as workers:
            outputs = list(workers.map(
                dependency.prepare_json_jar,
                [self.destination(f'parallel-{number}.jar') for number in range(4)]))
        self.urlopen.assert_called_once()
        self.assertTrue(all(path.read_bytes() == self.data for path in outputs))
        self.assertEqual(list(self.cache.glob('*.tmp')), [])

    def test_failed_atomic_publication_does_not_leave_partial_artifacts(self):
        with mock.patch.object(dependency.os, 'replace', side_effect=OSError('disk full')):
            with self.assertRaisesRegex(OSError, 'disk full'):
                dependency.prepare_json_jar(self.destination())
        self.assertFalse(self.cached.exists())
        self.assertFalse(self.destination().exists())
        self.assertEqual(list(self.cache.glob('*.tmp')), [])


if __name__ == '__main__':
    unittest.main()
