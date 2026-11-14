from pathlib import Path
import ast, difflib, hashlib, json
ROOT=Path('/tmp/root-c4-return-deadline-integration-20261114')
def ident(data):
    return {'bytes':len(data),'sha256':hashlib.sha256(data).hexdigest(),'git_blob':hashlib.sha1(b'blob '+str(len(data)).encode()+b'\0'+data).hexdigest()}
def read(rel): return (ROOT/rel).read_bytes()
freeze_raw=read('source-freeze.json')
assert ident(freeze_raw)['sha256']=='852d92fe7d3edefe6bb689be9909b6e51047f581641e2cb1d1a4d28f0bc88e54'
freeze=json.loads(freeze_raw)
binding=json.loads(read('baseline-binding.json'))
assert freeze['baseline_host']==binding['host_sha']=='0cda410b9e5dceba3ffaf04f9c0fc45880dac6a9'
assert freeze['baseline_tree']==binding['host_tree']=='a97942c991cbb38d22c8b97f06a3e5bb162ab942'
records=[]
basepaths=[]
for entry in binding['records']:
    p=entry['path']; basepaths.append(p)
    before=ident(read('baseline/'+p)); after=ident(read('source/'+p))
    for key in ('bytes','sha256','git_blob'): assert before[key]==entry[key],(p,key)
    records.append({'path':p,'before':before,'after':after,'byte_identical':read('baseline/'+p)==read('source/'+p)})
actualbefore=sorted(str(p.relative_to(ROOT/'baseline')) for p in (ROOT/'baseline').rglob('*') if p.is_file())
actualafter=sorted(str(p.relative_to(ROOT/'source')) for p in (ROOT/'source').rglob('*') if p.is_file())
assert actualbefore==actualafter==sorted(basepaths)
changed=[r['path'] for r in records if not r['byte_identical']]
assert set(changed)=={x['target'] for x in freeze['files']}
for entry in freeze['files']:
    before=ident(read('baseline/'+entry['target'])); after=ident(read('source/'+entry['target']))
    assert before['git_blob']==entry['old_blob']
    assert after['git_blob']==entry['new_blob']
    assert after['bytes']==entry['bytes'] and after['sha256']==entry['sha256']
patch=''.join(''.join(difflib.unified_diff(read('baseline/'+x['target']).decode().splitlines(True),read('source/'+x['target']).decode().splitlines(True),fromfile='a/'+x['target'],tofile='b/'+x['target'])) for x in freeze['files'])
assert patch.encode()==read('implementation.patch')
def definitions(raw):
    text=raw.decode(); lines=text.splitlines(keepends=True); tree=ast.parse(text); found={}
    def scan(body,prefix=''):
        for n in body:
            if isinstance(n,ast.ClassDef): scan(n.body,prefix+n.name+'.')
            elif isinstance(n,(ast.FunctionDef,ast.AsyncFunctionDef)):
                first=min([n.lineno]+[d.lineno for d in n.decorator_list])
                found[prefix+n.name]={'ast':ast.dump(n,include_attributes=False),'text':''.join(lines[first-1:n.end_lineno])}
    scan(tree.body)
    return found
comparisons=[]
for p in changed:
    before=definitions(read('baseline/'+p)); after=definitions(read('source/'+p))
    common=set(before)&set(after)
    altered=sorted(n for n in common if before[n]['ast']!=after[n]['ast'] or before[n]['text']!=after[n]['text'])
    added=sorted(set(after)-set(before)); removed=sorted(set(before)-set(after))
    comparisons.append({'path':p,'before_definitions':len(before),'after_definitions':len(after),'changed_definitions':altered,'added_definitions':added,'removed_definitions':removed,'unchanged_definitions':sorted(common-set(altered))})
assert comparisons[0]['changed_definitions']==['Probe.original','Probe.return_to_flutter']
assert comparisons[0]['added_definitions']==comparisons[0]['removed_definitions']==[]
assert comparisons[1]['changed_definitions']==comparisons[1]['removed_definitions']==[]
assert comparisons[1]['added_definitions']==['ReturnObservationTests.test_each_read_receives_only_the_remaining_local_budget_across_retries']
before_tests=[n for n in comparisons[1]['unchanged_definitions'] if n.startswith('ReturnObservationTests.test_')]
assert len(before_tests)==9
deadline_definitions=definitions(read('source/tools/android_qa/tests/test_connect_four_probe_deadlines.py'))
deadline_tests=sorted(n for n in deadline_definitions if n.startswith('DeadlineTests.test_'))
assert len(deadline_tests)==11
probe_before=read('baseline/.github/probes/lumo_connect_four_android_probe.py')
probe_after=read('source/.github/probes/lumo_connect_four_android_probe.py')
suffix=b'        prefs, prefs_file = self.read_preferences(tag + \'-after-return\')'
assert probe_before.split(suffix,1)[1]==probe_after.split(suffix,1)[1]
fixture=ROOT/'baseline/tools/android_qa/tests/fixtures/c4-final-return-7c5'
source_manifest=json.loads((fixture/'source.json').read_text())
fixture_records=[]
for item in source_manifest['files']:
    data=(fixture/item['path']).read_bytes()
    assert len(data)==item['bytes'] and hashlib.sha256(data).hexdigest()==item['sha256'],item['path']
    fixture_records.append({'path':item['path'],**ident(data)})
metadata_count=0
for p in sorted(fixture.glob('*.json')):
    if p.name=='source.json':continue
    meta=json.loads(p.read_text())
    for suffix in ('stdout','stderr'):
        data=p.with_suffix('.'+suffix).read_bytes()
        assert len(data)==meta[suffix+'_bytes'] and hashlib.sha256(data).hexdigest()==meta[suffix+'_sha256']
    metadata_count+=1
result={'kind':'read_only_source_binding_no_tests','source_freeze':ident(freeze_raw),'baseline_binding':ident(read('baseline-binding.json')),'patch':ident(read('implementation.patch')),'baseline_host':freeze['baseline_host'],'baseline_tree':freeze['baseline_tree'],'records':records,'changed_paths':changed,'definition_comparisons':comparisons,'old_return_tests_byte_and_ast_identical':before_tests,'deadline_tests_byte_identical':deadline_tests,'entire_post_mailbox_persistence_ui_navigation_suffix_byte_identical':True,'fixtures':fixture_records,'fixture_command_metadata_count':metadata_count,'test_execution':False,'imports_of_product_or_test_modules':False}
print(json.dumps(result,ensure_ascii=False,indent=2))
