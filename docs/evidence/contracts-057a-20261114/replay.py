#!/usr/bin/env python3
"""Read the original current build-contract log through the exact delivery reader."""
from pathlib import Path
import datetime,hashlib,importlib.util,json,re,subprocess,sys,time
sys.dont_write_bytecode=True
BASE=Path('/workspace/scratch/2708c7907f28/contracts-057a-originals-14119418657')
REPO=Path('/workspace/scratch/2708c7907f28/lumo-host-current')
HELPER=REPO/'scripts/verify_connect_four_delivery.py'
LOG=BASE/'original/build-contracts.log'
def record(path):
 b=path.read_bytes();return {'bytes':len(b),'sha256':hashlib.sha256(b).hexdigest(),'git_blob':hashlib.sha1(b'blob '+str(len(b)).encode()+b'\0'+b).hexdigest()}
def git(*args):return subprocess.check_output(['git',*args],cwd=REPO,text=True).strip()
assert git('rev-parse','HEAD')=='057a4e8d067872c4f3514b126aa04c3706d2e5b5'
assert git('rev-parse','HEAD^{tree}')=='a2ae17af283a76fb3b99f1a0899a0898e7157230'
subprocess.run(['git','diff','--exit-code','HEAD','--'],cwd=REPO,check=True)
index=json.loads((BASE/'archive-index.json').read_text())
assert index['file_count']==1
original=record(LOG);before=record(HELPER)
assert original=={k:index['members'][0][k] for k in ('bytes','sha256','git_blob')}
assert before['git_blob']==git('rev-parse','HEAD:scripts/verify_connect_four_delivery.py')=='214e21a6300b361985615c0a90b79d48a43ca2fd'
spec=importlib.util.spec_from_file_location('original_current_contract_reader',HELPER)
reader=importlib.util.module_from_spec(spec);spec.loader.exec_module(reader)
start=time.monotonic();result=reader.checked_pcm_log(LOG);sources=reader.committed_pcm_sources();elapsed=time.monotonic()-start
text=LOG.read_text();total=re.findall(r'^Ran (\d+) tests? in ([0-9.]+)s$',text,re.M)
assert len(total)==1 and int(total[0][0])==result['tests']
assert record(LOG)==original and record(HELPER)==before
subprocess.run(['git','diff','--exit-code','HEAD','--'],cwd=REPO,check=True)
report={'schema':1,'kind':'actual_original_build_contract_readonly_replay','recorded_at_utc':datetime.datetime.now(datetime.timezone.utc).isoformat(),'performed':True,'passed':True,'host':git('rev-parse','HEAD'),'host_tree':git('rev-parse','HEAD^{tree}'),'run_id':43607156921,'run_attempt':1,'artifact_id':14119418657,'archive':index['archive'],'reader':{'path':'scripts/verify_connect_four_delivery.py',**before},'actual_reader_calls':['checked_pcm_log(original/build-contracts.log)','committed_pcm_sources()'],'result':result,'original_unittest_seconds':float(total[0][1]),'committed_pcm_source_bindings':sources,'original_log_unchanged':True,'reader_and_source_unchanged':True,'reader_elapsed_seconds':elapsed,'limitations':['The original current CI test log was parsed; no new contract tests or JVM compilation were executed in this replay.','The 70 assertions are a synthetic PCM/JVM boundary, not audible Android device acceptance.']}
(BASE/'ROOT_READONLY_REPLAY.json').write_text(json.dumps(report,indent=2)+'\n')
print(json.dumps({'passed':True,'tests':result['tests'],'skips':result['skips'],'pcm_assertions':result['pcm_assertions'],'original_unittest_seconds':report['original_unittest_seconds'],'bound_source_files':len(sources),'reader_elapsed_seconds':elapsed,'original_log_unchanged':True},indent=2))
