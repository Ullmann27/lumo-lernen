from pathlib import Path
import ast
import hashlib
import json
import subprocess

REPO=Path('/tmp/lumo-root-recovery-0900/host-c4')
OUT=Path('/tmp/lumo-root-recovery-0900/host-final-gates')
OLD='0e26153f0e58cc05739e72923b4c563a4cf380b8'
NEW='f052c2795b765265dbb6f5c27b9e92b557d39a39'
RETURN_STEP='Retry the acknowledged native exit after a transient Android refusal'
WISP_STEP='Require the additional pinned native Treasure wisp regression'
assert subprocess.check_output(['git','rev-parse','HEAD'],cwd=REPO,text=True).strip()=='2b586530db4f2cb20c28f426e2549342316151bf'
assert subprocess.check_output(['git','status','--porcelain=v1','--untracked-files=all'],cwd=REPO)==b''
sources={}

def replace(text,before,after):
    assert text.count(before)==1,(before[:80],text.count(before))
    return text.replace(before,after,1)

for path in ('config/godot-source.json','scripts/verify_legacy_release_pin.py','scripts/tests/test_candidate_2011_pin.py'):
    sources[path]=replace((REPO/path).read_text(),OLD,NEW)

workflow_path='.github/workflows/lumo-connect-four-2020.yml'
workflow=(REPO/workflow_path).read_text()
anchor='      - name: Require the actual production Dart and rendered Godot two-process gate\n'
steps='''      - name: Retry the acknowledged native exit after a transient Android refusal
        run: |
          set -euo pipefail
          export XDG_DATA_HOME="$RUNNER_TEMP/c4-return/data"
          export XDG_CONFIG_HOME="$RUNNER_TEMP/c4-return/config"
          export XDG_CACHE_HOME="$RUNNER_TEMP/c4-return/cache"
          mkdir -p "$XDG_DATA_HOME" "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME"
          timeout 60s godot --headless --audio-driver Dummy --path native-source --script res://scripts/tests/connect_four_return_regression.gd 2>&1 | tee c4-runtime/return-recovery.log
          if grep -En 'ERROR:|SCRIPT ERROR:|Parse Error:|Assertion failed' c4-runtime/return-recovery.log; then
            echo 'The actual native return regression reported an engine or script failure' >&2
            exit 1
          fi
          test "$(grep -Fxc 'CONNECT_FOUR_RETURN_PASS checks=21' c4-runtime/return-recovery.log)" = 1
      - name: Require the additional pinned native Treasure wisp regression
        run: |
          set -euo pipefail
          export XDG_DATA_HOME="$RUNNER_TEMP/c4-wisps/data"
          export XDG_CONFIG_HOME="$RUNNER_TEMP/c4-wisps/config"
          export XDG_CACHE_HOME="$RUNNER_TEMP/c4-wisps/cache"
          mkdir -p "$XDG_DATA_HOME" "$XDG_CONFIG_HOME" "$XDG_CACHE_HOME"
          (cd native-source && python3 tools/run_godot_probe.py --log "$GITHUB_WORKSPACE/c4-runtime/wisps.log" --timeout 180 --required '[TreasureWisp] PASS' -- godot --headless --path . --audio-driver Dummy --script scripts/tests/treasure_wisp_regression.gd)
          test "$(grep -Fxc '[TreasureWisp] PASS checks=14' c4-runtime/wisps.log)" = 1
'''
sources[workflow_path]=replace(workflow,anchor,steps+anchor)

path='scripts/verify_connect_four_delivery.py'
source=(REPO/path).read_text()
constant='''ADDITIONAL_NATIVE_LOGS = {
    'acknowledged_exit': ('return-recovery.log', 'CONNECT_FOUR_RETURN_PASS checks=21', 21),
    'treasure_wisps': ('wisps.log', '[TreasureWisp] PASS checks=14', 14),
}
ADDITIONAL_ENGINE_BANNER = 'Godot Engine v4.6.3.stable.official.7d41c59c4 - https://godotengine.org'
'''
source=replace(source,'REQUIRED_STEPS = {\n',constant+'REQUIRED_STEPS = {\n')
source=replace(source,"        'Import the exact configured native source in its own directory',\n",
               "        'Import the exact configured native source in its own directory',\n"
               f"        {RETURN_STEP!r},\n        {WISP_STEP!r},\n")
helper='''def checked_additional_native_logs(runtime: Path) -> dict:
    """Bind original logs from the two additionally required native CI steps."""
    result = {}
    for name, (filename, marker, checks) in ADDITIONAL_NATIVE_LOGS.items():
        path = regular(runtime.parent/filename)
        original = record(path)
        text = path.read_bytes().decode('utf-8')
        lines = text.splitlines()
        require(lines.count(ADDITIONAL_ENGINE_BANNER) == 1 and lines.count(marker) == 1,
                'Incomplete or duplicate additional native result: '+name)
        require(not re.search(r'SCRIPT ERROR|Parse Error|ERROR:|Assertion failed|\\[ProbeRunner\\] (?:FAIL|timeout)', text),
                'Original additional native regression failed: '+name)
        require(record(path) == original, 'Additional native log changed during verification: '+name)
        result[name] = {'filename': filename, 'checks': checks, 'marker': marker,
                        'original_log': original}
    return {'status': 'PASS', 'gates': result,
            'scope': 'Pinned-source desktop regressions; acknowledged exit uses an explicit Android host fixture. No real device or FPS claim.'}


'''
source=replace(source,'def committed_pcm_sources() -> dict:\n',helper+'def committed_pcm_sources() -> dict:\n')
source=replace(source,"    native = checked_native(args.native_evidence, args.native_source, binding['native_source'])\n",
               "    native = checked_native(args.native_evidence, args.native_source, binding['native_source'])\n"
               "    additional_native = checked_additional_native_logs(args.runtime)\n")
source=replace(source,"        'original_artifacts': artifacts, 'pcm': pcm, 'native': native, 'learning_audit': learning,\n",
               "        'original_artifacts': artifacts, 'pcm': pcm, 'native': native, 'learning_audit': learning,\n"
               "        'additional_native_regressions': additional_native,\n")
source=replace(source,"    learning_originals = audit/'learning-curriculum'\n",
               "    native_additional_originals = audit/'native-additional'\n"
               "    native_additional_originals.mkdir()\n"
               "    for gate in additional_native['gates'].values():\n"
               "        filename = gate['filename']\n"
               "        shutil.copyfile(regular(args.runtime.parent/filename), native_additional_originals/filename)\n"
               "        require(record(native_additional_originals/filename) == gate['original_log'],\n"
               "                'Additional native staging changed original bytes: '+filename)\n"
               "    learning_originals = audit/'learning-curriculum'\n")
sources[path]=source

path='scripts/tests/test_connect_four_delivery.py';source=(REPO/path).read_text()
test_class='''class AdditionalNativeLogTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(); self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.runtime = self.root/'runtime'; self.runtime.mkdir()
        self.originals = {}
        for name, (filename, marker, checks) in delivery.ADDITIONAL_NATIVE_LOGS.items():
            text = delivery.ADDITIONAL_ENGINE_BANNER+'\\n\\n'+marker+'\\n'
            self.originals[filename] = text.encode()
            (self.root/filename).write_bytes(text.encode())

    def test_both_original_logs_are_required_and_bound_without_mutation(self):
        result = delivery.checked_additional_native_logs(self.runtime)
        self.assertEqual({name: row['checks'] for name,row in result['gates'].items()},
                         {'acknowledged_exit': 21, 'treasure_wisps': 14})
        for row in result['gates'].values():
            raw = self.originals[row['filename']]
            self.assertEqual((self.root/row['filename']).read_bytes(), raw)
            self.assertEqual(row['original_log']['sha256'], hashlib.sha256(raw).hexdigest())

    def test_truncated_duplicate_failed_or_foreign_engine_results_are_rejected(self):
        for filename,marker,checks in delivery.ADDITIONAL_NATIVE_LOGS.values():
            original = self.originals[filename]
            variants = [b'', original.replace(marker.encode(), b''),
                        original+marker.encode()+b'\\n',
                        original.replace(b'v4.6.3.', b'v4.5.0.'),
                        original+b'SCRIPT ERROR: actual assertion failed\\n',
                        original+b'ERROR: renderer failed\\n',
                        original+b'[ProbeRunner] FAIL: unclean process exit\\n',
                        original+b'[ProbeRunner] timeout after 180s\\n',
                        original+b'\\xff']
            for data in variants:
                (self.root/filename).write_bytes(data)
                with self.subTest(filename=filename, data=data[-80:]), \\
                     self.assertRaises((ValueError, UnicodeDecodeError)):
                    delivery.checked_additional_native_logs(self.runtime)
            (self.root/filename).write_bytes(original)

    def test_missing_directory_or_symlink_cannot_replace_an_original_log(self):
        for filename in self.originals:
            path = self.root/filename; path.unlink()
            with self.assertRaises(ValueError): delivery.checked_additional_native_logs(self.runtime)
            path.mkdir()
            with self.assertRaises(ValueError): delivery.checked_additional_native_logs(self.runtime)
            path.rmdir()
            other = self.root/(filename+'.outside'); other.write_bytes(self.originals[filename])
            path.symlink_to(other)
            with self.assertRaises(ValueError): delivery.checked_additional_native_logs(self.runtime)
            path.unlink(); path.write_bytes(self.originals[filename])


'''
source=replace(source,'class CurrentLearningAuditTests(unittest.TestCase):\n',test_class+'class CurrentLearningAuditTests(unittest.TestCase):\n')
fixture_anchor="        learning_fixture(root/'learning_audit')\n"
source=replace(source,fixture_anchor,
               "        for filename, marker, _ in delivery.ADDITIONAL_NATIVE_LOGS.values():\n"
               "            (root/filename).write_text(delivery.ADDITIONAL_ENGINE_BANNER+'\\n\\n'+marker+'\\n')\n"+fixture_anchor)
source=replace(source,"            self.assertEqual(report['learning_audit']['generated_samples'], 7552)\n",
               "            self.assertEqual(report['learning_audit']['generated_samples'], 7552)\n"
               "            self.assertEqual(set(report['additional_native_regressions']['gates']),\n"
               "                             {'acknowledged_exit', 'treasure_wisps'})\n"
               "            for filename, _, _ in delivery.ADDITIONAL_NATIVE_LOGS.values():\n"
               "                self.assertEqual((args.out/'audit/native-additional'/filename).read_bytes(),\n"
               "                                 (args.runtime.parent/filename).read_bytes())\n")
missing_gate='''    def test_missing_or_duplicate_added_native_step_blocks_otherwise_successful_jobs(self):
        row = next(row for row in self.jobs['jobs'] if row['name'] == 'connect-four-runtime')
        original = copy.deepcopy(row['steps'])
        for label in ('''+repr(RETURN_STEP)+', '+repr(WISP_STEP)+'''):
            selected = next(step for step in original if step['name'] == label)
            for changed in ([step for step in original if step['name'] != label], original+[selected]):
                row['steps'] = changed
                with self.subTest(label=label, length=len(changed)), self.assertRaises(ValueError):
                    self.check()
            row['steps'] = copy.deepcopy(original)

'''
source=replace(source,'    def test_stale_or_foreign_branch_event_or_pull_request_is_rejected(self):\n',
               missing_gate+'    def test_stale_or_foreign_branch_event_or_pull_request_is_rejected(self):\n')
sources[path]=source

records=[]
for path,text in sources.items():
    if path.endswith('.py'):ast.parse(text,filename=path)
    before=(REPO/path).read_bytes();after=text.encode()
    target=OUT/'final-source'/path;target.parent.mkdir(parents=True,exist_ok=True);target.write_bytes(after)
    original=OUT/'before'/path;original.parent.mkdir(parents=True,exist_ok=True);original.write_bytes(before)
    def sha(data):return hashlib.sha1(b'blob '+str(len(data)).encode()+b'\0'+data).hexdigest()
    records.append({'path':path,'mode':'100644','before_blob':sha(before),'git_blob':sha(after),
                    'bytes':len(after),'sha256':hashlib.sha256(after).hexdigest()})
freeze={'schema':1,'status':'SOURCE_PREPARED_TESTS_NOT_RUN','base':'2b586530db4f2cb20c28f426e2549342316151bf',
        'native_pin':NEW,'files':records,'existing_native_contract':{'calls':52,'studio_images':17,'unchanged':True},
        'additional_gates':{'acknowledged_exit_checks':21,'treasure_wisp_checks':14},
        'changed_test_methods':4,'tests_executed':0}
(OUT/'source-freeze.json').write_text(json.dumps(freeze,indent=2)+'\n')
print(json.dumps(freeze))
