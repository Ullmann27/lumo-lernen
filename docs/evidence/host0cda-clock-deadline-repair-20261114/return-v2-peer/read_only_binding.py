from pathlib import Path
import ast,difflib,hashlib,json
P=Path('/tmp/root-c4-return-deadline-integration-v2-20261114')
V1=Path('/tmp/root-c4-return-deadline-integration-20261114')
def ident(b):return {'bytes':len(b),'sha256':hashlib.sha256(b).hexdigest(),'git_blob':hashlib.sha1(b'blob '+str(len(b)).encode()+b'\0'+b).hexdigest()}
fraw=(P/'source-freeze.json').read_bytes();assert ident(fraw)['sha256']=='91566ea8ef448a877be89d478845e97d2298653e297e714a06212f320b9d892c'
f=json.loads(fraw); p=f['changes']['target']
before=(P/'baseline'/p).read_bytes();after=(P/'source'/p).read_bytes()
assert before==(V1/'source'/p).read_bytes()
assert ident(before)['git_blob']==f['changes']['old_blob']
assert ident(after)['git_blob']==f['changes']['new_blob']
assert ident(after)['bytes']==f['changes']['bytes'] and ident(after)['sha256']==f['changes']['sha256']
assert after.count(b'with self.assertRaises((RuntimeError, TimeoutError)):')-before.count(b'with self.assertRaises((RuntimeError, TimeoutError)):')==2
assert ''.join(difflib.unified_diff(before.decode().splitlines(True),after.decode().splitlines(True),fromfile='a/'+p,tofile='b/'+p)).encode()==(P/'implementation.patch').read_bytes()
def definitions(raw):
 text=raw.decode();lines=text.splitlines(keepends=True);out={}
 for c in ast.parse(text).body:
  nodes=c.body if isinstance(c,ast.ClassDef) else [c]
  for n in nodes:
   if isinstance(n,(ast.FunctionDef,ast.AsyncFunctionDef)):
    first=min([n.lineno]+[d.lineno for d in n.decorator_list])
    out[(c.name+'.' if isinstance(c,ast.ClassDef) else '')+n.name]=''.join(lines[first-1:n.end_lineno])
 return out
old=definitions(before);new=definitions(after)
assert old.keys()==new.keys()
changed=sorted(n for n in old if old[n]!=new[n])
assert changed==sorted('ReturnObservationTests.'+n for n in f['two_changed_assertions'])
inverse=after.decode()
for n in changed:
 assert new[n].replace('with self.assertRaises((RuntimeError, TimeoutError)):','with self.assertRaises(RuntimeError):')==old[n]
 inverse=inverse.replace(new[n],old[n],1)
assert inverse.encode()==before
records=[]; paths=sorted(str(q.relative_to(P/'source')) for q in (P/'source').rglob('*') if q.is_file())
assert paths==sorted(str(q.relative_to(P/'baseline')) for q in (P/'baseline').rglob('*') if q.is_file())
for path in paths:
 b=(P/'baseline'/path).read_bytes();a=(P/'source'/path).read_bytes()
 assert b==(V1/'source'/path).read_bytes()
 if path!=p:assert a==b
 records.append({'path':path,'before':ident(b),'after':ident(a),'identical':b==a})
red=(V1/'actual-validation/stderr.original').read_bytes()
assert ident(red)['sha256']=='8c76a4a6548b6d90dd906078dc6decc38df04ea4230f4f8069026f5e50834d66'
assert red.count(b"TimeoutError: The actual native C4 return exceeded its 45-second observation deadline")==5
assert b'Ran 21 tests in 0.399s' in red and b'FAILED (errors=5)' in red
result={'kind':'static_v2_source_binding_no_tests','freeze':ident(fraw),'baseline_host':f['base_host'],'baseline_tree':f['base_tree'],'source_records':records,'changed_path':p,'changed_methods':changed,'other_method_count':len(old)-len(changed),'old_new_method_count':[len(old),len(new)],'inverse_two_literal_replacements_recovers_complete_before_bytes':True,'all_no_acceptance_no_find_one_back_checks_exactly_preserved':True,'production_blob':next(x['after'] for x in records if x['path']=='.github/probes/lumo_connect_four_android_probe.py'),'original_red_log':{'path':str(V1/'actual-validation/stderr.original'),**ident(red)},'tests_run_by_reviewer':False}
print(json.dumps(result,ensure_ascii=False,indent=2))
