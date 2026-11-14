#!/usr/bin/env python3
"""Prepare a private, source-bound partial runtime; never import the shared base."""
from pathlib import Path
import hashlib,json,re,shutil
BASE=Path('/workspace/scratch/5987865ae883/qa/restored-native344')
QA=Path('/workspace/scratch/5987865ae883/qa/studio-english-next-20261114/rebuild-344-1a903')
RUNTIME=Path('/tmp/lumo-english-rebuild-344-1a903')
def identity(p):
    b=p.read_bytes()
    return {'bytes':len(b),'sha256':hashlib.sha256(b).hexdigest(),
            'git_blob':hashlib.sha1(b'blob '+str(len(b)).encode()+b'\0'+b).hexdigest()}
if not (BASE/'project.godot').is_file(): raise SystemExit('Missing verified Native344 base')
seeds=['project.godot','icon.svg','scenes/default_env.tres','scenes/learning/learning_world.tscn',
       'scripts/learning/learning_world.gd','scripts/learning/learning_activity.gd',
       'scripts/tests/learning_world_regression.gd','scripts/tests/learning_studio_regression.gd',
       'scripts/tests/learning_sharing_regression.gd','tools/run_local_renderer.py']
project=(BASE/'project.godot').read_text()
seeds += re.findall(r'="\*(res://[^"]+)"',project)
todo=[s.removeprefix('res://') for s in seeds]
included=set(); omitted=[]
while todo:
    name=todo.pop()
    if name in included: continue
    path=BASE/name
    if not path.is_file(): raise SystemExit('Missing required baseline file '+name)
    included.add(name)
    if path.suffix in ('.gd','.tscn','.tres','.gdshader'):
        text=path.read_text()
        for ref in re.findall(r'res://[A-Za-z0-9_./ -]+\.[A-Za-z0-9_]+',text):
            rel=ref.removeprefix('res://')
            if name=='scripts/app/scene_router.gd' and rel!='scenes/learning/learning_world.tscn':
                omitted.append({'from':name,'reference':rel,'reason':'unused dynamic scene route; embedded-return boundary is explicit in the test'})
                continue
            if (BASE/rel).is_file(): todo.append(rel)
    if path.suffix in ('.glb','.gltf','.png','.svg','.wav','.ogg') and (BASE/(name+'.import')).is_file():
        todo.append(name+'.import')
RUNTIME.mkdir(parents=True,exist_ok=True)
rows=[]
for name in sorted(included):
    source=BASE/name; dest=RUNTIME/name
    dest.parent.mkdir(parents=True,exist_ok=True)
    shutil.copy2(source,dest)
    before=identity(source); after=identity(dest)
    if before!=after: raise SystemExit('Copy identity mismatch '+name)
    rows.append({'path':name,**before})
changed=[]
for source in sorted((QA/'prepared/native').rglob('*')):
    if not source.is_file(): continue
    rel=source.relative_to(QA/'prepared/native'); dest=RUNTIME/rel
    dest.parent.mkdir(parents=True,exist_ok=True)
    shutil.copy2(source,dest)
    changed.append({'path':str(rel),**identity(source)})
# Runtime-only application entry; all existing autoloads and renderer settings remain.
p=RUNTIME/'project.godot'
s=p.read_text(); old='run/main_scene="res://scenes/app/boot.tscn"'
if s.count(old)!=1: raise SystemExit('Unexpected private main-scene anchor')
p.write_text(s.replace(old,'run/main_scene="res://scenes/learning/learning_world.tscn"'))
report={'schema':1,'base_native':'34421df83566dd4773420cc2a225887956459435',
 'host_contract':'1a903aefc751f80537c7dd4c96ae8c99915962f5',
 'scope':'partial runtime dependency graph; no full-checkout claim; original project only has private main-scene override',
 'base_root':str(BASE),'runtime':str(RUNTIME),'baseline_files':rows,
 'prepared_files':changed,'omitted_unused_dynamic_routes':omitted,
 'runtime_project':identity(p),'baseline_project':identity(BASE/'project.godot')}
(QA/'evidence').mkdir(exist_ok=True)
(QA/'evidence/runtime-source-binding.json').write_text(json.dumps(report,indent=2)+'\n')
print(json.dumps({'runtime':str(RUNTIME),'baseline_files':len(rows),'prepared_files':len(changed),'baseline_bytes':sum(r['bytes'] for r in rows)}))
