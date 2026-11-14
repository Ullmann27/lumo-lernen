#!/usr/bin/env python3
"""Bounded local two-process capture. Test preferences, not Android persistence."""
import argparse, hashlib, json, os, subprocess, time
from pathlib import Path
p=argparse.ArgumentParser(); p.add_argument('name'); args=p.parse_args()
base=Path(__file__).resolve().parent; root=base.parents[1]
out=base/('runtime-'+args.name); out.mkdir(exist_ok=False)
renderer=base/('xorg-'+args.name)
paths=[x['path'] for x in json.loads((base/'runtime-render-v4/source-before.json').read_text())['files']]
def source():
 return [dict(path=n,bytes=(base/n).stat().st_size,sha256=hashlib.sha256((base/n).read_bytes()).hexdigest()) for n in paths]
before=source(); (out/'source-before.json').write_text(json.dumps({'files':before,'native_original_lumo':'803e7a626ea6ef0aeeda9c37010e844033d3a8e3'},indent=2)+'\n')
env=os.environ.copy(); env['LUMO_C4_RUNTIME_DIR']=str(out)
flutter='/workspace/scratch/e0abce7d2838/toolchain/flutter/bin/flutter'
dcmd=[flutter,'test','--no-pub','test/games/connect_four_runtime_bridge.dart']
gcmd=['python',str(root/'lumo-godot/tools/run_local_renderer.py'),'--display','95','--output',str(renderer),'--project',str(base/'runtime'),'--timeout','1200','--','--fixed-fps','24','--resolution','960x540','--script','res://scripts/tests/connect_four_runtime_regression.gd','--','--capture']
started=time.monotonic(); report={'scope':'Local software renderer + production Dart controller; file IPC and test preferences; not Android','dart_command':dcmd,'renderer_command':gcmd,'environment':{'LUMO_C4_RUNTIME_DIR':str(out)},'dart_cwd':str(base/'host')}
with (base/'logs'/('runtime-dart-'+args.name+'.log')).open('w') as log:
 dart=subprocess.Popen(dcmd,cwd=base/'host',env=env,stdout=log,stderr=subprocess.STDOUT)
 try:
  until=time.monotonic()+90
  while not (out/'session.json').exists() and dart.poll() is None and time.monotonic()<until:
   time.sleep(.1)
  if not (out/'session.json').exists(): raise RuntimeError('Dart session did not become ready')
  game=subprocess.run(gcmd,cwd=root,env=env,timeout=1250,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True)
  (out/'renderer-launcher.log').write_text(game.stdout)
  report['renderer_exit']=game.returncode
  try: report['dart_exit']=dart.wait(timeout=20)
  except subprocess.TimeoutExpired:
   dart.terminate(); report['dart_exit']=dart.wait(timeout=10); report['dart_terminated_after_renderer']=True
 finally:
  if dart.poll() is None: dart.terminate(); dart.wait(timeout=10)
  after=source(); (out/'source-after.json').write_text(json.dumps({'files':after,'all_unchanged':after==before},indent=2)+'\n')
  report.update(elapsed_seconds=time.monotonic()-started,all_source_unchanged=before==after)
  (out/'two-process-run.json').write_text(json.dumps(report,indent=2)+'\n')
print(json.dumps(report))
raise SystemExit(0 if report.get('renderer_exit')==0 and report.get('dart_exit')==0 and report['all_source_unchanged'] else 1)
