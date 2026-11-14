#!/usr/bin/env python3
"""Narrow synthetic observation regression; no Android/Flutter/renderer run."""
from pathlib import Path
import datetime, hashlib, json, os, subprocess, sys, time
root=Path(__file__).resolve().parents[1]
phase=sys.argv[1]
assert phase in ('red','green')
modules=(['tools.android_qa.tests.test_connect_four_probe_deadlines.DeadlineTests.test_return_waits_for_actual_private_cleanup_after_native_exit'] if phase=='red' else ['tools.android_qa.tests.test_connect_four_probe_deadlines','tools.android_qa.tests.test_connect_four_android_evidence'])
command=[sys.executable,'-m','unittest','-v',*modules]
paths=['.github/probes/lumo_connect_four_android_probe.py','tools/android_qa/tests/test_connect_four_probe_deadlines.py','tools/android_qa/tests/test_connect_four_android_evidence.py','tools/android_qa/connect_four_android_evidence.py','tools/android_qa/native_surface_readiness.py']
def identity():
 return [{'path':name,'bytes':len(data:=(root/name).read_bytes()),'sha256':hashlib.sha256(data).hexdigest(),'git_blob':hashlib.sha1(b'blob '+str(len(data)).encode()+b'\0'+data).hexdigest()} for name in paths]
start=datetime.datetime.now(datetime.timezone.utc).isoformat(); before=identity(); clock=time.monotonic()
env={**os.environ,'PYTHONDONTWRITEBYTECODE':'1','LUMO_C4_PROBE_SOURCE':str(root/paths[0])}
with (root/'evidence'/f'{phase}.original.log').open('xb') as log:
 result=subprocess.run(command,cwd=root,env=env,stdout=log,stderr=subprocess.STDOUT,check=False)
report={'phase':phase,'source_base':'04a8e850d4c198e16ff758df614ce6e53eab4524','started_at':start,'elapsed_seconds':time.monotonic()-clock,'command':command,'exit_code':result.returncode,'before':before,'after':identity(),'scope':'Synthetic boundary regression using actual Probe.original journals and unchanged offline verifier; no device, SDK, Flutter or renderer'}
assert report['before']==report['after']
(root/'evidence'/f'{phase}.execution.json').write_text(json.dumps(report,indent=2)+'\n')
print(json.dumps({'phase':phase,'exit_code':result.returncode,'elapsed_seconds':report['elapsed_seconds'],'original_log':str(root/'evidence'/f'{phase}.original.log')}))
sys.exit(result.returncode)
