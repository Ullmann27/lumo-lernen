from pathlib import Path
import datetime, hashlib, json, os, re, subprocess, sys, time
root=Path('/tmp/lumo-root-recovery-1242/host')
out=Path(__file__).resolve().parent
expected_sha='9f2f3690caacadbe7ced363f0e810f0cc0b5eb9b';expected_tree='4159e7ab2212aca6e3347aa5f08544bdfdb30c26'
def run_git(*args):
 return subprocess.check_output(['git',*args],cwd=root)
def h(b):return hashlib.sha256(b).hexdigest()
def blob(b):return hashlib.sha1(b'blob '+str(len(b)).encode()+bytes([0])+b).hexdigest()
def snapshot(label):
 status=run_git('status','--porcelain=v1','--untracked-files=all')
 assert not status,status.decode()
 sha=run_git('rev-parse','HEAD').decode().strip();tree=run_git('rev-parse','HEAD^{tree}').decode().strip()
 assert (sha,tree)==(expected_sha,expected_tree),(sha,tree)
 staged=run_git('ls-files','--stage','-z');flags=run_git('ls-files','-v','-z')
 (out/(label+'-index-stage.z')).write_bytes(staged);(out/(label+'-index-flags.z')).write_bytes(flags)
 skip={x[2:].decode() for x in flags.split(bytes([0])) if x and x[:1]==b'S'}
 entries=[]
 for row in staged.split(bytes([0])):
  if not row:continue
  fields,name=row.split(b'\t',1);mode,oid,stage=fields.decode().split();path=name.decode();assert stage=='0'
  f=root/path;e={'path':path,'mode':mode,'git_blob':oid,'skip_worktree':path in skip}
  if f.is_symlink():data=os.readlink(f).encode();e['materialized']=True
  elif f.is_file():data=f.read_bytes();e['materialized']=True
  else:
   assert path in skip,('unexpected missing',path);e['materialized']=False;entries.append(e);continue
  assert blob(data)==oid,('modified',path)
  e.update(bytes=len(data),sha256=h(data));entries.append(e)
 index_path=Path(run_git('rev-parse','--git-path','index').decode().strip())
 if not index_path.is_absolute():index_path=root/index_path
 state={'head':sha,'tree':tree,'index_stage_sha256':h(staged),'index_flags_sha256':h(flags),'raw_index_sha256':h(index_path.read_bytes()),'status':status.decode(),'entries':entries}
 (out/(label+'-source.json')).write_text(json.dumps(state,indent=2)+'\n')
 return state
before=snapshot('before')
cmd=[sys.executable,'-B','-m','unittest','-v','test_kart_garage_evidence','test_kart_garage_scroll_recovery','test_kart_scroll_word_evidence','test_kart_driver_word_evidence','test_kart_continue_caption','test_native_surface_readiness']
inv={'command':cmd,'cwd':str(root),'python':sys.version,'host_sha':expected_sha,'host_tree':expected_tree,'native_sha':json.loads((root/'config/godot-source.json').read_text())['revision'],'additional_environment':{'PYTHONPATH':'tools/android_qa/tests','PYTHONDONTWRITEBYTECODE':'1'},'started_at':datetime.datetime.now(datetime.timezone.utc).isoformat()}
(out/'invocation.json').write_text(json.dumps(inv,indent=2)+'\n')
started=time.monotonic()
with (out/'stdout.original.log').open('wb') as stdout,(out/'stderr.original.log').open('wb') as stderr:
 proc=subprocess.run(cmd,cwd=root,env={**os.environ,'PYTHONDONTWRITEBYTECODE':'1','PYTHONPATH':'tools/android_qa/tests'},stdout=stdout,stderr=stderr)
elapsed=time.monotonic()-started
(out/'exit-code.txt').write_text(str(proc.returncode)+'\n')
after=snapshot('after');assert before==after,'Source inventory changed'
text=(out/'stdout.original.log').read_text()+(out/'stderr.original.log').read_text()
match=re.search(r'^Ran (\d+) tests in ([\d.]+)s$',text,re.M)
result={'host_sha':expected_sha,'host_tree':expected_tree,'native_sha':inv['native_sha'],'started_at':inv['started_at'],'finished_at':datetime.datetime.now(datetime.timezone.utc).isoformat(),'exit_code':proc.returncode,'wall_seconds':elapsed,'unittest_count':int(match.group(1)) if match else None,'unittest_seconds':float(match.group(2)) if match else None,'terminal_ok':text.rstrip().endswith('OK'),'case_pass_count':len(re.findall(r'^test_.* \.\.\. ok$',text,re.M)),'failure_lines':[x for x in text.splitlines() if x.startswith(('FAIL:','ERROR:'))],'skip_lines':[x for x in text.splitlines() if '... skipped ' in x],'sources_unchanged':True,'tracked_files':len(before['entries']),'materialized_files':sum(e['materialized'] for e in before['entries']),'sparse_absent_files':sum(not e['materialized'] for e in before['entries'])}
(out/'result.json').write_text(json.dumps(result,indent=2)+'\n')
print(json.dumps(result))
sys.exit(proc.returncode)
