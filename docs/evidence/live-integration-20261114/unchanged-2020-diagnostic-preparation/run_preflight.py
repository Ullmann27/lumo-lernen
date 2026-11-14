from pathlib import Path
import ast,datetime,hashlib,json,os,subprocess,sys,yaml
root=Path('/workspace/scratch/909ddb52fe7b/unchanged-2020-diagnostic-preparation')
out=Path('/workspace/scratch/909ddb52fe7b/unchanged-2020-diagnostic-evidence')
workflow=root/'.github/workflows/lumo-unchanged-2020-apk-diagnostic.yml'
runner=root/'scripts/run_unchanged_2020_apk_diagnostic.sh'
before={str(p.relative_to(root)):hashlib.sha256(p.read_bytes()).hexdigest() for p in [workflow,runner,root/'scripts/verify_unchanged_2020_apk_diagnostic.py',root/'scripts/tests/test_verify_unchanged_2020_apk_diagnostic.py']}
started=datetime.datetime.now(datetime.timezone.utc).isoformat()
commands=[];syntax=[]
doc=yaml.safe_load(workflow.read_text())
for name,job in doc['jobs'].items():
 for index,step in enumerate(job.get('steps',[])):
  if 'run' not in step:continue
  script=out/f'{name}-step-{index+1}.bash'
  script.write_text(step['run'])
  run=subprocess.run(['bash','-n',str(script)],capture_output=True,text=True)
  syntax.append({'job':name,'step':index+1,'exit_code':run.returncode,'stderr':run.stderr,'sha256':hashlib.sha256(script.read_bytes()).hexdigest()})
  if run.returncode:raise SystemExit(run.stderr)
run=subprocess.run(['bash','-n',str(runner)],capture_output=True,text=True)
syntax.append({'runner':str(runner.relative_to(root)),'exit_code':run.returncode,'stderr':run.stderr})
if run.returncode:raise SystemExit(run.stderr)
for p in [root/'scripts/verify_unchanged_2020_apk_diagnostic.py',root/'scripts/tests/test_verify_unchanged_2020_apk_diagnostic.py']:ast.parse(p.read_text())
shell=runner.read_text();start=shell.index("<<'PY'\n")+len("<<'PY'\n");end=shell.index('\nPY\n',start)
ast.parse(shell[start:end]);syntax.append({'runner_embedded_python':'PASS'})
command=[sys.executable,'-B','-m','unittest','-v',
 'scripts.tests.test_verify_unchanged_2020_apk_diagnostic',
 'tools.android_qa.tests.test_kart_garage_evidence',
 'tools.android_qa.tests.test_kart_driver_word_evidence',
 'tools.android_qa.tests.test_update_2020_preservation']
env={**os.environ,'PYTHONPATH':str(root/'tools/android_qa/tests'),'PYTHONDONTWRITEBYTECODE':'1'}
with (out/'diagnostic-contracts-original.log').open('wb') as stream:
 completed=subprocess.run(command,cwd=root,env=env,stdout=stream,stderr=subprocess.STDOUT,timeout=180)
raw=(out/'diagnostic-contracts-original.log').read_bytes()
after={name:hashlib.sha256((root/name).read_bytes()).hexdigest() for name in before}
report={'started_at':started,'finished_at':datetime.datetime.now(datetime.timezone.utc).isoformat(),'command':command,
 'cwd':str(root),'exit_code':completed.returncode,'syntax':syntax,'source_before':before,'source_after':after,
 'source_unchanged':before==after,'log_bytes':len(raw),'log_sha256':hashlib.sha256(raw).hexdigest(),
 'actionlint':'NOT_RUN_NOT_INSTALLED','scope':'Offline verifier/source/observation contracts only; no APK rebuild, ADB, emulator, Android acceptance or publication.'}
(out/'preflight-result.json').write_text(json.dumps(report,indent=2)+'\n')
print(json.dumps(report))
print(raw.decode()[-6000:])
raise SystemExit(completed.returncode)

