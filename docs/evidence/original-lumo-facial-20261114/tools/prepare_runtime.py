from pathlib import Path
import re,json,hashlib
BASE=Path(__file__).resolve().parents[1];ROOT=BASE.parents[1];SOURCE=ROOT/'lumo-godot';RUNTIME=BASE/'runtime';RUNTIME.mkdir(exist_ok=True)
published={x['path']:x for x in json.loads((ROOT/'qa/kart-theme-source-803e-20261114/published-runtime-blobs.json').read_text())['files']}
autoloads={'EventBus':'scripts/systems/event_bus.gd','SettingsStore':'scripts/systems/settings_store.gd','PerformanceManager':'scripts/systems/performance_manager.gd','MobileRuntime':'scripts/app/mobile_runtime.gd','HostBridge':'scripts/systems/host_bridge.gd','SceneRouter':'scripts/app/scene_router.gd','AssetLoader':'scripts/systems/asset_loader.gd','AudioManager':'scripts/systems/audio_manager.gd','ProgressStore':'scripts/systems/progress_store.gd'}
queue=list(autoloads.values())+['scripts/learning/learning_world.gd','scripts/learning/learning_atelier.gd','assets/characters/lumo_animated/Lumo-Animated-Mobile.glb','assets/characters/lumo_animated/Lumo-Animated-Mobile.glb.import','assets/characters/lumo_animated/lumo_studio_clips.gd','assets/learning/studio/learning_studio.glb','assets/learning/studio/studio_leaf_motion.gdshader','assets/creative/models/lumo_lantern.glb','assets/audio/voice/words/apfel.wav','assets/manifests/assets.json','scripts/tests/lumo_teacher_pose_regression.gd','scripts/tests/lumo_studio_motion_regression.gd','scripts/tests/lumo_rigged_animation_capture.gd']
queue += [str(p.relative_to(BASE/'native')) for p in (BASE/'native').rglob('*') if p.is_file()]
queue += ['scenes/learning/learning_world.tscn']
seen=set();records=[]
while queue:
 rel=queue.pop(0)
 if rel in seen:continue
 seen.add(rel);staged=BASE/'native'/rel;original=SOURCE/rel
 if staged.is_file():p=staged;kind='staged_delta'
 else:p=original;kind='exact_803e'
 data=p.read_bytes();blob=hashlib.sha1(b'blob '+str(len(data)).encode()+b'\0'+data).hexdigest()
 if kind=='exact_803e':assert rel in published and published[rel]['sha']==blob,(rel,blob,published.get(rel))
 out=RUNTIME/rel;out.parent.mkdir(parents=True,exist_ok=True);out.write_bytes(data)
 records.append({'path':rel,'kind':kind,'sha256':hashlib.sha256(data).hexdigest(),'git_blob':blob})
 if p.suffix in ['.gd','.tscn','.tres']:
  text=data.decode();queue += re.findall(r'(?:preload|load)\("res://([^"%]+)"\)',text)
project='config_version=5\n[application]\nconfig/name="Lumo Facial QA Staging"\n[autoload]\n'+''.join(f'{name}="*res://{path}"\n' for name,path in autoloads.items())+'\n[display]\nwindow/size/viewport_width=640\nwindow/size/viewport_height=640\n[rendering]\nrenderer/rendering_method="gl_compatibility"\nrenderer/rendering_method.mobile="gl_compatibility"\ntextures/default_filters/use_nearest_mipmap_filter=false\n'
(RUNTIME/'project.godot').write_text(project)
(BASE/'evidence/runtime-source-binding.json').write_text(json.dumps({'native_base':'803e7a626ea6ef0aeeda9c37010e844033d3a8e3','runtime_project':'explicit isolated QA configuration; no claim that local worktree is clean803e','files':records},indent=2)+'\n')
print(json.dumps({'runtime':str(RUNTIME),'files':len(records),'bytes':sum((RUNTIME/x['path']).stat().st_size for x in records)}))
