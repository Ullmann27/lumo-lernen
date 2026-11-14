"""Replay actual preserved local sidecars through the new pure roster readers.
No new scene is rendered and no Android/CI PASS is inferred.
"""
from pathlib import Path
import argparse,hashlib,json,sys,traceback
p=argparse.ArgumentParser();p.add_argument('--harness',type=Path,required=True);p.add_argument('--face',type=Path,required=True);p.add_argument('--c4',type=Path,required=True);p.add_argument('--root',type=Path,required=True);p.add_argument('--out',type=Path,required=True);a=p.parse_args()
s=a.harness.read_text();roster=s.split("<<'PY'\n",1)[1].split('\nPY\n',1)[0]
report={'scope':__doc__,'harness_sha256':hashlib.sha256(a.harness.read_bytes()).hexdigest(),'errors':[]}
ns={};sys.argv=['roster',str(a.root.resolve())]
try:
 exec(compile(roster.split('images = []\n',1)[0],str(a.harness)+':roster','exec'),ns)
 report['face']=ns['face_report'](a.face.resolve())
 report['face_original_sidecar_sha256']=hashlib.sha256((a.face/'runtime-frames.json').read_bytes()).hexdigest()
 result=ns['c4_report'](a.c4.resolve());report['c4_sidecar']=result[0];report['c4_capture_names']=sorted(result[1])
 report['c4_original_sidecar_sha256']=hashlib.sha256((a.c4/'visual-state.json').read_bytes()).hexdigest()
except Exception as error:
 traceback.print_exc();report['errors'].append({'type':type(error).__name__,'message':str(error)})
report['passed']=not report['errors'];a.out.write_text(json.dumps(report,indent=2)+'\n')
print(json.dumps(report,indent=2));raise SystemExit(0 if report['passed'] else 1)
