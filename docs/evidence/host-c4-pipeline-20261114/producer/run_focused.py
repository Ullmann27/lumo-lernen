#!/usr/bin/env python3
"""Run only the proposed C4 contracts; this is not a device or engine run."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import time

PACK = Path(__file__).resolve().parent
HOST = PACK.parent / 'lumo-host-connect-four-integration'
PROPOSED = PACK / 'proposed'
PYTHON = '/opt/codex/runtimes/codex-primary-runtime/dependencies/python/bin/python3'


def write(path, value):
    path.write_text(json.dumps(value, indent=2, sort_keys=True)+'\n')


def sources():
    paths = list(PROPOSED.rglob('*.py')) + list(PROPOSED.rglob('*.yml'))
    paths += [HOST/p for p in (
        'tools/android_qa/native_surface_readiness.py',
        'tools/android_qa/update_preservation.py',
        'scripts/verify_unified_apk.py','scripts/verify_legacy_release_pin.py',
        'scripts/release_pipeline_gates.py','scripts/run_connect_four_runtime.py',
        'config/godot-source.json','pubspec.yaml')]
    return {str(path):{'bytes':path.stat().st_size,'sha256':hashlib.sha256(path.read_bytes()).hexdigest()}
            for path in sorted(paths)}


def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('--name',required=True)
    parser.add_argument('--suite',choices=('android','pipeline','both'),default='both')
    parser.add_argument('--case',help='Optional exact unittest name filter for a concrete regression')
    args=parser.parse_args()
    out=PACK/'evidence'/args.name
    out.mkdir(parents=True,exist_ok=False)
    env=os.environ.copy()
    env['PYTHONDONTWRITEBYTECODE']='1'
    env['PYTHONPATH']=os.pathsep.join(str(p) for p in (
        PROPOSED/'tools/android_qa',HOST/'tools/android_qa',HOST/'scripts'))
    env['LUMO_C4_REFERENCE_HOST']=str(HOST)
    before=sources()
    write(out/'sources-before.json',before)
    head=subprocess.check_output(['git','rev-parse','HEAD'],cwd=HOST,text=True).strip()
    commands=[]
    if args.suite in ('android','both'):
        commands.append([PYTHON,'-m','unittest','discover','-s','tools/android_qa/tests',
                         '-p','test_connect_four_android_evidence.py','-v'])
    if args.suite in ('pipeline','both'):
        commands.append([PYTHON,'-m','unittest','discover','-s','scripts/tests',
                         '-p','test_connect_four_pipeline.py','-v'])
    records=[]
    for i,command in enumerate(commands,1):
        if args.case:
            command += ['-k',args.case]
        started=time.monotonic()
        result=subprocess.run(command,cwd=PROPOSED,env=env,stdout=subprocess.PIPE,
                              stderr=subprocess.STDOUT,timeout=240)
        log=out/f'suite-{i}.log';log.write_bytes(result.stdout)
        text=result.stdout.decode('utf-8')
        ran=re.findall(r'Ran (\d+) tests? in ',text)
        records.append({'command':command,'cwd':str(PROPOSED),'exit_code':result.returncode,
                        'duration_seconds':time.monotonic()-started,'tests':int(ran[-1]) if ran else None,
                        'skips':len(re.findall(r"\.\.\. skipped ",text)),
                        'log':log.name,'log_bytes':len(result.stdout),
                        'log_sha256':hashlib.sha256(result.stdout).hexdigest()})
        print(text,flush=True)
    after=sources();write(out/'sources-after.json',after)
    final_head=subprocess.check_output(['git','rev-parse','HEAD'],cwd=HOST,text=True).strip()
    value={'scope':'Local synthetic C4 evidence and workflow contracts only; no engine, APK or device',
           'host_head_before':head,'host_head_after':final_head,'source_scope_unchanged':before==after,
           'runtime':PYTHON,'environment':{k:env[k] for k in ('PYTHONDONTWRITEBYTECODE','PYTHONPATH','LUMO_C4_REFERENCE_HOST')},
           'runs':records,'passed':before==after and all(r['exit_code']==0 and r['tests'] and r['skips']==0 for r in records)}
    write(out/'result.json',value)
    return 0 if value['passed'] else 1


if __name__=='__main__':
    raise SystemExit(main())
