"""Tiny synthetic ZIP contracts; downloads are always mocked, never real."""
from __future__ import annotations

import copy
import hashlib
import importlib.util
import io
import json
from pathlib import Path
import stat
import struct
import subprocess
import tempfile
import unittest
from unittest.mock import patch
import warnings
import zipfile

ROOT = Path(__file__).resolve().parents[2]
SPEC = importlib.util.spec_from_file_location('artifact_originals_contract', ROOT/'scripts/verify_studio_artifact_originals.py')
gate = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(gate)
SOURCE = 'a'*40
RUN = 123


def dump(path, value):
    path.write_text(json.dumps(value)+'\n')


def zip_bytes(entries):
    output = io.BytesIO()
    with warnings.catch_warnings():
        warnings.simplefilter('ignore', UserWarning)  # Deliberate duplicate ZIP test.
        with zipfile.ZipFile(output, 'w', compression=zipfile.ZIP_STORED) as archive:
            for name, data in entries:
                archive.writestr(name, data)
    return output.getvalue()


class ArtifactOriginalContracts(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.base = Path(self.temporary.name)
        self.metadata = self.base/'metadata'; self.metadata.mkdir()
        self.roots = {}
        self.archives = {}
        self.run = {'id': RUN, 'head_sha': SOURCE, 'run_attempt': 1,
                    'path': gate.WORKFLOW, 'status': 'in_progress',
                    'repository': {'full_name': gate.REPOSITORY}}
        self.artifacts = []
        for index, (role, name) in enumerate(gate.NAMES.items(), 1):
            root = self.base/role; root.mkdir(); (root/'nested').mkdir()
            entries = [('result.json', b'{"fixture":true}\n'), ('nested/raw.bin', b'original-'+bytes([index])*37)]
            for relative, data in entries:
                (root/relative).write_bytes(data)
            raw = zip_bytes(entries)
            self.archives[index] = raw; self.roots[role] = root
            self.artifacts.append({'id': index, 'name': name, 'size_in_bytes': len(raw),
                                   'digest': 'sha256:'+hashlib.sha256(raw).hexdigest(), 'expired': False,
                                   'workflow_run': {'id': RUN, 'head_sha': SOURCE}})
        self.collection = {'total_count': len(self.artifacts), 'artifacts': self.artifacts}
        self.save_metadata()
        self.destinations = []

    def save_metadata(self):
        dump(self.metadata/'run.json', self.run)
        dump(self.metadata/'artifacts.json', self.collection)

    def download(self, artifact_id, destination):
        self.destinations.append(destination)
        destination.write_bytes(self.archives[artifact_id])

    def verify(self):
        self.save_metadata()
        with patch.object(gate, 'download_archive', side_effect=self.download):
            return gate.verify(SOURCE, RUN, self.metadata, self.roots)

    def compare(self, raw=None):
        raw = self.archives[1] if raw is None else raw
        path = self.base/'small-original.zip'; path.write_bytes(raw)
        metadata = copy.deepcopy(self.artifacts[0])
        metadata.update(size_in_bytes=len(raw), digest='sha256:'+hashlib.sha256(raw).hexdigest())
        return gate.compare_archive(path, self.roots['api35'], metadata)

    def original_hashes(self):
        return {str(path): gate.sha256(path) for root in self.roots.values()
                for path in root.rglob('*') if path.is_file() and not path.is_symlink()}

    def test_all_three_original_archives_are_stream_compared_without_mutating_or_extracting(self):
        before = self.original_hashes()
        with patch.object(gate, 'CHUNK_BYTES', 3):
            result = self.verify()
        self.assertEqual(result['status'], 'PASS')
        self.assertEqual(set(result['artifacts']), {'api35','api37','runtime'})
        self.assertFalse(result['archive_extraction_performed'])
        self.assertEqual(self.original_hashes(), before)
        self.assertEqual(len({path.parent for path in self.destinations}), 3)
        self.assertTrue(all(not path.parent.exists() for path in self.destinations))
        for role, facts in result['artifacts'].items():
            self.assertEqual(facts['name'], gate.NAMES[role])
            self.assertEqual(facts['file_count'], 2)
            self.assertEqual(facts['zip_crc'], 'PASS')
            self.assertTrue(facts['every_file_stream_compared'])
            self.assertTrue(facts['temporary_archive_removed'])
            self.assertRegex(facts['member_manifest_sha256'], '^[a-f0-9]{64}$')

    def test_wrong_run_source_repository_workflow_and_nonpositive_ids_are_rejected_before_download(self):
        original = copy.deepcopy(self.run)
        variants = [('id', 999), ('id', True), ('head_sha', 'b'*40),
                    ('path', '.github/workflows/other.yml'),
                    ('repository', {'full_name':'another/repository'}), ('run_attempt', 0)]
        for field, value in variants:
            with self.subTest(field=field, value=value):
                self.run = dict(original, **{field:value})
                with self.assertRaises(gate.VerificationError): self.verify()
        self.assertEqual(self.destinations, [])

    def test_incomplete_missing_duplicate_names_or_reused_ids_are_rejected(self):
        original = copy.deepcopy(self.collection)
        for variant in ('count','missing','duplicate_name','duplicate_id'):
            self.collection = copy.deepcopy(original)
            if variant == 'count': self.collection['total_count'] += 1
            if variant == 'missing':
                self.collection['artifacts'].pop(); self.collection['total_count'] -= 1
            if variant == 'duplicate_name':
                self.collection['artifacts'].append(copy.deepcopy(self.collection['artifacts'][0]))
                self.collection['total_count'] += 1
            if variant == 'duplicate_id': self.collection['artifacts'][1]['id'] = 1
            with self.subTest(variant=variant), self.assertRaises(gate.VerificationError): self.verify()
        self.assertEqual(self.destinations, [])

    def test_unrelated_artifacts_in_complete_original_list_do_not_replace_required_three(self):
        self.collection['artifacts'].append({'id': 88, 'name': 'unrelated-log'})
        self.collection['total_count'] += 1
        self.assertEqual(len(self.verify()['artifacts']), 3)

    def test_foreign_artifact_source_run_expiry_digest_and_size_fail_before_download(self):
        original = copy.deepcopy(self.artifacts[0])
        variants = [('id', False), ('size_in_bytes', 0), ('size_in_bytes', True),
                    ('digest', 'sha256:short'), ('digest', None), ('expired', True),
                    ('workflow_run', {'id':999,'head_sha':SOURCE}),
                    ('workflow_run', {'id':RUN,'head_sha':'b'*40})]
        for field, value in variants:
            self.collection['artifacts'][0] = dict(original, **{field:value})
            with self.subTest(field=field,value=value), self.assertRaises(gate.VerificationError): self.verify()
        self.assertEqual(self.destinations, [])

    def test_duplicate_keys_nonfinite_and_symlinked_metadata_are_rejected(self):
        path = self.metadata/'bad.json'
        for raw in ('{"id":1,"id":2}', '{"n":NaN}', '[]'):
            path.write_text(raw)
            with self.subTest(raw=raw), self.assertRaises(gate.VerificationError): gate.load_metadata(path)
        path.unlink(); path.symlink_to(self.metadata/'run.json')
        with self.assertRaises(gate.VerificationError): gate.load_metadata(path)

    def test_original_archive_size_and_digest_are_both_mandatory(self):
        path = self.base/'original.zip'; path.write_bytes(self.archives[1])
        for change in ({'size_in_bytes':len(self.archives[1])+1}, {'digest':'sha256:'+'0'*64}):
            metadata = dict(self.artifacts[0], **change)
            with self.subTest(change=change), self.assertRaises(gate.VerificationError):
                gate.compare_archive(path,self.roots['api35'],metadata)

    def test_missing_and_additional_downloaded_files_are_rejected(self):
        path = self.roots['api35']/'result.json'; raw = path.read_bytes(); path.unlink()
        with self.assertRaisesRegex(gate.VerificationError, 'Missing or additional'): self.compare()
        path.write_bytes(raw); (self.roots['api35']/'unbound.txt').write_text('extra')
        with self.assertRaisesRegex(gate.VerificationError, 'Missing or additional'): self.compare()

    def test_equal_length_changed_file_and_changed_size_are_rejected(self):
        path = self.roots['api35']/'nested/raw.bin'; original = path.read_bytes()
        path.write_bytes(b'X'+original[1:])
        with self.assertRaisesRegex(gate.VerificationError, 'file bytes differ'): self.compare()
        path.write_bytes(original+b'X')
        with self.assertRaisesRegex(gate.VerificationError, 'file size differs'): self.compare()

    def test_duplicate_zip_member_and_file_directory_prefix_are_rejected(self):
        for entries in ([('same',b'a'),('same',b'b')], [('same',b'a'),('same/child',b'b')],
                        [('same/',b''),('same',b'b')]):
            with self.subTest(entries=entries), self.assertRaisesRegex(gate.VerificationError,'Duplicate|prefix'):
                self.compare(zip_bytes(entries))

    def test_traversal_absolute_backslash_drive_and_ambiguous_names_are_rejected(self):
        for name in ('../escape','/absolute','a/../escape','a//b','./a','a\\b','C:/x','a\nname'):
            with self.subTest(name=name), self.assertRaises(gate.VerificationError):
                self.compare(zip_bytes([(name,b'bad')]))
        self.assertFalse((self.base/'escape').exists())
        info = zipfile.ZipInfo('a\0ignored')
        with self.assertRaises(gate.VerificationError): gate.member_name(info)

    def test_zip_symlink_fifo_and_directory_type_mismatch_are_rejected(self):
        for mode in (stat.S_IFLNK|0o777,stat.S_IFIFO|0o600,stat.S_IFDIR|0o755):
            info = zipfile.ZipInfo('item'); info.create_system=3; info.external_attr=mode<<16
            with self.subTest(mode=mode), self.assertRaisesRegex(gate.VerificationError,'symlink/special'):
                self.compare(zip_bytes([(info,b'target')]))

    def test_original_directory_file_directory_and_root_symlinks_are_rejected(self):
        root = self.roots['api35']; path=root/'result.json'; data=path.read_bytes()
        path.unlink(); path.symlink_to(self.roots['api37']/'result.json')
        with self.assertRaisesRegex(gate.VerificationError,'Symlink'): self.compare()
        path.unlink(); path.write_bytes(data)
        (root/'linkdir').symlink_to(self.roots['api37'], target_is_directory=True)
        with self.assertRaisesRegex(gate.VerificationError,'Symlink'): self.compare()
        (root/'linkdir').unlink()
        alias=self.base/'alias'; alias.symlink_to(root,target_is_directory=True)
        self.roots['api35']=alias
        with self.assertRaisesRegex(gate.VerificationError,'symlink'): self.verify()

    def test_crc_corruption_fails_even_when_new_archive_digest_matches_metadata(self):
        raw=bytearray(self.archives[1]); marker=b'{"fixture":true}\n'; offset=raw.index(marker)
        raw[offset] ^= 1
        with self.assertRaisesRegex(gate.VerificationError,'CRC'): self.compare(bytes(raw))

    def test_encrypted_entry_empty_archive_and_data_bearing_directory_are_rejected(self):
        raw=bytearray(self.archives[1]); local=raw.index(b'PK\x03\x04'); central=raw.index(b'PK\x01\x02')
        struct.pack_into('<H',raw,local+6,struct.unpack_from('<H',raw,local+6)[0]|1)
        struct.pack_into('<H',raw,central+8,struct.unpack_from('<H',raw,central+8)[0]|1)
        with self.assertRaisesRegex(gate.VerificationError,'Encrypted'): self.compare(bytes(raw))
        with self.assertRaisesRegex(gate.VerificationError,'no files'): self.compare(zip_bytes([('empty/',b'')]))
        with self.assertRaisesRegex(gate.VerificationError,'directory carries'): self.compare(zip_bytes([('dir/',b'x')]))

    def test_download_failure_timeout_and_unavailable_cli_never_disclose_stderr_or_tokens(self):
        secret='SECRET_TOKEN https://redirect.invalid/signed?secret=value'
        variants=[subprocess.CompletedProcess(['gh'],22,stderr=secret.encode()),
                  subprocess.TimeoutExpired(['gh'],900,stderr=secret.encode()),FileNotFoundError(secret)]
        for index,value in enumerate(variants):
            with self.subTest(index=index):
                kwargs={'side_effect':value} if isinstance(value,Exception) else {'return_value':value}
                with patch.object(gate.subprocess,'run',**kwargs):
                    with self.assertRaises(gate.VerificationError) as caught:
                        gate.download_archive(99,self.base/f'failure-{index}.zip')
                self.assertNotIn('SECRET_TOKEN',str(caught.exception))
                self.assertNotIn('https://',str(caught.exception))

    def test_download_command_uses_exact_repository_id_and_redirect_safe_stderr_capture(self):
        destination=self.base/'download.zip'
        def run(command,**options):
            self.assertEqual(command,['gh','api','repos/Ullmann27/lumo-lernen/actions/artifacts/73/zip'])
            self.assertIs(options['stderr'],subprocess.PIPE)
            self.assertEqual(options['timeout'],900)
            self.assertFalse(options['check'])
            options['stdout'].write(self.archives[1])
            return subprocess.CompletedProcess(command,0,stderr=b'not logged')
        with patch.object(gate.subprocess,'run',side_effect=run): gate.download_archive(73,destination)
        self.assertEqual(destination.read_bytes(),self.archives[1])

    def test_failed_comparison_removes_owned_temporary_archive_and_preserves_originals(self):
        before=self.original_hashes();self.artifacts[0]['digest']='sha256:'+'0'*64
        with self.assertRaises(gate.VerificationError):self.verify()
        self.assertEqual(len(self.destinations),1)
        self.assertFalse(self.destinations[0].parent.exists())
        self.assertEqual(before,self.original_hashes())

    def test_overlapping_roots_and_output_inside_originals_or_existing_output_fail(self):
        old=self.roots['api37'];self.roots['api37']=self.roots['api35']
        with self.assertRaisesRegex(gate.VerificationError,'nonoverlapping'):self.verify()
        self.roots['api37']=old
        arguments=['--source-sha',SOURCE,'--build-run',str(RUN),'--metadata-dir',str(self.metadata)]
        for role,root in self.roots.items():arguments += ['--'+role,str(root)]
        existing=self.base/'existing.json';existing.write_text('keep')
        for output in (self.roots['api35']/'new.json',existing):
            with self.subTest(output=str(output)),patch.object(gate,'download_archive') as download:
                with self.assertRaises(gate.VerificationError):gate.main(arguments+['--out',str(output)])
                download.assert_not_called()
        self.assertEqual(existing.read_text(),'keep')

    def test_cli_writes_only_new_bound_report_after_three_successful_originals(self):
        output=self.base/'dist/C4-ARTIFACT-ORIGINALS.json'
        arguments=['--source-sha',SOURCE,'--build-run',str(RUN),'--metadata-dir',str(self.metadata),'--out',str(output)]
        for role,root in self.roots.items():arguments += ['--'+role,str(root)]
        before=self.original_hashes()
        with patch.object(gate,'download_archive',side_effect=self.download),patch('sys.stdout',new_callable=io.StringIO):
            self.assertEqual(gate.main(arguments),0)
        report=json.loads(output.read_text())
        self.assertEqual(report['source_sha'],SOURCE);self.assertEqual(report['build_run'],RUN)
        self.assertEqual(report['metadata_sha256']['artifacts.json'],gate.sha256(self.metadata/'artifacts.json'))
        self.assertEqual(before,self.original_hashes())
        self.assertEqual(len(report['artifacts']),3)


if __name__=='__main__':unittest.main()
