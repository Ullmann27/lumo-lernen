from pathlib import Path
import datetime, hashlib, importlib.metadata, json, os, platform, re, subprocess, sys, time
ROOT=Path('/tmp/host-pr493-mailbox-close-observation-repair-20261114')
VIEW=ROOT/'test-view'
CHECKOUT=Path('/workspace/scratch/b3485b7bb989/host-36274db-c4-preferences-checkout-20261114')
OUT=ROOT/'validation'
OUT.mkdir(exist_ok=False)
def ident(b):
 return {'bytes':len(b),'sha256':hashlib.sha256(b).hexdigest(),'git_blob':hashlib.sha1(b'blob '+str(len(b)).encode()+b'\0'+b).hexdigest()}
def write(name,value):
 p=OUT/name
 with p.open('xb') as f:f.write((json.dumps(value,ensure_ascii=False,indent=2)+'\n').encode())
def now():return datetime.datetime.now(datetime.timezone.utc).isoformat()
env=dict(os.environ,PYTHONDONTWRITEBYTECODE='1',GIT_OPTIONAL_LOCKS='0')
env.pop('LUMO_C4_PROBE_SOURCE',None)
env.pop('PYTHONPATH',None)
def git(*args):
 p=subprocess.run(['git','-C',str(CHECKOUT),*args],env=env,capture_output=True)
 if p.returncode!=0:raise RuntimeError(str(args)+': '+p.stderr.decode())
 return p.stdout
def directory(root):
 return [{'path':p.relative_to(root).as_posix(),'mode':oct(p.stat().st_mode & 0o777),**ident(p.read_bytes())} for p in sorted(root.rglob('*')) if p.is_file()]
def snapshot():
 stage=git('ls-files','--stage','-z')
 flags=git('ls-files','-v','-z')
 index=Path(git('rev-parse','--path-format=absolute','--git-path','index').decode().strip())
 materialized=[]
 for raw in stage.split(b'\0'):
  if not raw:continue
  meta,path=raw.split(b'\t',1); mode,oid,level=meta.decode().split()
  rel=path.decode(); p=CHECKOUT/rel
  if not p.is_file():continue
  content=p.read_bytes()
  item={'path':rel,'index_mode':mode,'index_blob':oid,'worktree_mode':oct(p.stat().st_mode & 0o777),**ident(content)}
  if item['git_blob']!=oid:raise RuntimeError('Reference checkout source differs: '+rel)
  materialized.append(item)
 result={'reference_head':git('rev-parse','HEAD').decode().strip(),'reference_tree':git('rev-parse','HEAD^{tree}').decode().strip(),
 'reference_status':git('status','--porcelain=v1','--untracked-files=all').decode(),
 'reference_index_path':str(index),'reference_index':ident(index.read_bytes()),
 'reference_index_stage':ident(stage),'reference_index_flags':ident(flags),
 'reference_materialized_sources':materialized,
 'frozen_source':directory(ROOT/'final-source'),'before_source':directory(ROOT/'before-source'),
 'reference_source':directory(ROOT/'reference-source'),'test_view':directory(VIEW),
 'source_freeze':ident((ROOT/'source-freeze.json').read_bytes()),
 'recorder':ident((ROOT/'validation-recorder.py').read_bytes())}
 if result['reference_head']!='36274db2941963c59b1f819ad7bc2358470d3a76' or result['reference_status']:
  raise RuntimeError('Reference checkout identity/status mismatch')
 return result
before=snapshot();write('sources-before.json',before)
freeze=json.loads((ROOT/'source-freeze.json').read_text())
for item in freeze['files']:
 raw=(ROOT/'final-source'/item['path']).read_bytes()
 if any(ident(raw)[k]!=item[k] for k in ['bytes','sha256','git_blob']):
  raise RuntimeError('Frozen source mismatch: '+item['path'])
 if (VIEW/item['path']).read_bytes()!=raw:raise RuntimeError('Execution source mismatch: '+item['path'])
roster=json.loads((ROOT/'test-roster.json').read_text())
argv=[sys.executable,'-B','-m','unittest',*[x['module'] for x in roster['modules']],'-v']
write('environment.json',{'python':sys.version,'executable':sys.executable,'platform':platform.platform(),'pillow':importlib.metadata.version('Pillow'),'cwd':str(VIEW),'environment_overrides':{'PYTHONDONTWRITEBYTECODE':'1','GIT_OPTIONAL_LOCKS':'0','LUMO_C4_PROBE_SOURCE':'removed','PYTHONPATH':'removed'}})
write('invocation.json',{'argv':argv,'cwd':str(VIEW),'count':1,'expected_tests':54,'scope':'Explicit controlled observer contracts only; no device/engine/CI calls. Exact published producer sources on verified unchanged reference dependencies.','started_at':now()})
started=now();clock=time.monotonic()
with (OUT/'stdout.original.log').open('xb') as stdout,(OUT/'stderr.original.log').open('xb') as stderr:
 try:
  p=subprocess.run(argv,cwd=VIEW,env=env,stdout=stdout,stderr=stderr,timeout=300,check=False)
  rc=p.returncode; timed_out=False
 except subprocess.TimeoutExpired:
  rc=None; timed_out=True
elapsed=time.monotonic()-clock;ended=now()
write('process.json',{'argv':argv,'cwd':str(VIEW),'started_at':started,'ended_at':ended,'elapsed_seconds':elapsed,'returncode':rc,'timed_out':timed_out})
after=snapshot();write('sources-after.json',after)
stderr=(OUT/'stderr.original.log').read_text()
stdout=(OUT/'stdout.original.log').read_bytes()
summary=re.findall(r'(?m)^Ran (\d+) tests? in ([0-9.]+)s\s*$',stderr)
ok=bool(re.search(r'(?m)^OK\s*$',stderr))
observed_count=int(summary[-1][0]) if summary else None
status='PASS' if rc==0 and not timed_out and observed_count==54 and ok and before==after else 'FAIL'
result={'schema':1,'status':status,'actual_invocations':1,'returncode':rc,'timed_out':timed_out,
 'observed_test_count':observed_count,'unittest_seconds':float(summary[-1][1]) if summary else None,
 'wall_seconds':elapsed,'exact_OK_summary':ok,'source_snapshot_unchanged':before==after,
 'stdout':ident(stdout),'stderr':ident((OUT/'stderr.original.log').read_bytes()),
 'count_scope':{'new_return':9,'unchanged_preferences':9,'unchanged_evidence':17,'unchanged_deadlines':11,'unchanged_navigation':8},
 'historical_android_result':'FAIL remains unchanged; later successful cleanup answers in controlled tests are synthetic.'}
write('result.json',result)
write('source-comparison.json',{'equal':before==after,'reference_materialized_count':len(before['reference_materialized_sources']),'frozen_source_count':len(before['frozen_source']),'test_view_count':len(before['test_view']),'reference_index_unchanged':before['reference_index']==after['reference_index'],'reference_stage_flags_unchanged':before['reference_index_stage']==after['reference_index_stage'] and before['reference_index_flags']==after['reference_index_flags']})
print(json.dumps(result,indent=2),flush=True)
sys.exit(0 if status=='PASS' else 1)
