#!/usr/bin/env python3
"""Encode actual consecutive Godot frames without interpolation and fully decode."""
import argparse, hashlib, json, subprocess
from pathlib import Path
from PIL import Image
p=argparse.ArgumentParser(); p.add_argument('directory',type=Path); args=p.parse_args()
out=args.directory.resolve(); frames=sorted((out/'frames').glob('*.png'))
native=json.loads((out/'native-result.json').read_text())
assert len(frames)==native['frames'] and len(frames)>0
assert [f.name for f in frames]==[f'{i:05}.png' for i in range(len(frames))]
manifest=[]
for i,f in enumerate(frames):
 with Image.open(f) as im:
  assert im.size==(960,540)
  pixels=im.convert('RGB').tobytes()
 manifest.append({'index':i,'path':str(f.relative_to(out)),'bytes':f.stat().st_size,'sha256':hashlib.sha256(f.read_bytes()).hexdigest(),'rgb_sha256':hashlib.sha256(pixels).hexdigest()})
(out/'frame-manifest.json').write_text(json.dumps({'origin':'consecutive actual Godot viewport frames','interpolated_frames':0,'size':[960,540],'media_fps':24,'device_fps_not_measured':True,'frames':manifest},indent=2)+'\n')
files=[]; commands=[]
for name,options in [('runtime-lossless.mkv',['-c:v','ffv1','-level','3','-coder','1','-context','1','-pix_fmt','bgr0']),('connect-four-runtime.mp4',['-c:v','libx264','-crf','18','-preset','veryfast','-pix_fmt','yuv420p','-movflags','+faststart'])]:
 target=out/name
 cmd=['ffmpeg','-hide_banner','-loglevel','warning','-y','-framerate','24','-i',str(out/'frames/%05d.png'),'-fps_mode','passthrough','-threads','2',*options,str(target)]
 run=subprocess.run(cmd,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True)
 (out/(name+'.encode.log')).write_text(run.stdout); assert run.returncode==0,run.stdout
 commands.append({'command':cmd,'exit_code':run.returncode})
positions=native['positions']; chosen=sorted(set([0,next(i for i,x in enumerate(positions) if x['dropping']),len(frames)//2,next(i for i,x in enumerate(positions) if x['win_rings']==4),len(frames)-1]))
(out/'decoded').mkdir(exist_ok=True)
for name in ['runtime-lossless.mkv','connect-four-runtime.mp4']:
 target=out/name
 cmd=['ffmpeg','-hide_banner','-loglevel','error','-i',str(target),'-f','rawvideo','-pix_fmt','rgb24','-']
 process=subprocess.Popen(cmd,stdout=subprocess.PIPE,stderr=subprocess.PIPE)
 count=0; mismatches=[]; nbytes=960*540*3
 while True:
  pixel=process.stdout.read(nbytes)
  if not pixel: break
  assert len(pixel)==nbytes, 'truncated decoded frame'
  assert count<len(manifest),'unexpected interpolated frame'
  if name.endswith('.mkv') and hashlib.sha256(pixel).hexdigest()!=manifest[count]['rgb_sha256']: mismatches.append(count)
  if name.endswith('.mp4') and count in chosen:
   Image.frombytes('RGB',(960,540),pixel).save(out/'decoded'/f'frame-{count:05d}.png')
  count+=1
 err=process.stderr.read().decode(); code=process.wait(); assert code==0 and count==len(frames) and not mismatches,(code,count,mismatches,err)
 files.append({'file':name,'sha256':hashlib.sha256(target.read_bytes()).hexdigest(),'bytes':target.stat().st_size,'decoded_frames':count,'decode_exit':code,'stderr':err,'lossless_exact_rgb':name.endswith('.mkv'),'mismatches':mismatches,'decode_command':cmd})
report={'origin':'actual successive viewport frames','media_fps':24,'duration_seconds':len(frames)/24,'device_fps_not_measured':True,'commands':commands,'files':files,'representative_decoded_frames':chosen}
(out/'decode-verification.json').write_text(json.dumps(report,indent=2)+'\n')
print(json.dumps({'frames':len(frames),'seconds':len(frames)/24,'files':[{k:v for k,v in x.items() if k not in ['decode_command']} for x in files],'representative_frames':chosen}))
