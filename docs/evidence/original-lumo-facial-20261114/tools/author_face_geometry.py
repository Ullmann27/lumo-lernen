"""Original Lumo: measured surface lids and restrained gaze/jaw morphs.

The original GLB binary payload, original vertices/UVs/skin and nine clips
are preserved. Additional skinned lid geometry follows the measured painted
eye contour; it is explicitly new authoring, not a pre-existing facial rig.
"""
import argparse, copy, hashlib, json, math, struct, sys
from pathlib import Path
import bpy
import numpy as np
from mathutils import Matrix, Vector
sys.path.insert(0, str(Path(__file__).resolve().parent))
from author_face_shapes import read_glb, accessor, render_setup, smooth

C=Matrix(((1,0,0),(0,0,-1),(0,1,0)))
BODY=('LookLeft','LookRight','LookUp','LookDown','JawArticulation')
LID_STAGES=('Quarter','Half','ThreeQuarter','Close')
LIDS=tuple('Blink'+eye+stage for eye in ('Left','Right') for stage in LID_STAGES)

def body_point(name,p):
 x,y,z=p;v=np.array(p,dtype=np.float64)
 for sign in (-1,1):
  dx,dy=(x-sign*.108)/.063,(y-1.352)/.062
  f=(1-smooth(.38,1.04,math.sqrt(dx*dx+dy*dy)))*smooth(.17,.22,z)*(1-smooth(.35,.39,z))
  if name in ('LookLeft','LookRight'):v[0]+=(-1 if name=='LookLeft' else 1)*.008*f
  if name in ('LookUp','LookDown'):v[1]+=(1 if name=='LookUp' else -1)*.006*f
 if name=='JawArticulation':
  lip=1.218+.42*min(abs(x),.14)
  f=(1-smooth(lip-.006,lip+.009,y))*smooth(1.105,1.15,y)*(1-smooth(.105,.18,abs(x)))*smooth(.20,.27,z)
  angle=.045;cy,cz=y-1.25,z-.195
  v[1]+=((1.25+cy*math.cos(angle)-cz*math.sin(angle))-y)*f
  v[2]+=((.195+cy*math.sin(angle)+cz*math.cos(angle))-z)*f
 return v

def normals(points,indices):
 out=np.zeros_like(points,dtype=np.float64)
 f=np.cross(points[indices[:,1]]-points[indices[:,0]],points[indices[:,2]]-points[indices[:,0]])
 for j in range(3):np.add.at(out,indices[:,j],f)
 size=np.linalg.norm(out,axis=1);out[size>1e-10]/=size[size>1e-10,None]
 out[size<=1e-10]=[0,0,1]
 return out.astype(np.float32)

class Writer:
 def __init__(self,doc,data):self.doc=doc;self.data=bytearray(data)
 def add(self,values,kind='VEC3',component=5126,target=34962):
  types={5126:'<f4',5123:'<u2',5125:'<u4'};a=np.array(values,dtype=types[component]);count=len(a)
  while len(self.data)%4:self.data.append(0)
  vi=len(self.doc['bufferViews']);view={'buffer':0,'byteOffset':len(self.data),'byteLength':a.nbytes}
  if target:view['target']=target
  self.doc['bufferViews'].append(view);self.data.extend(a.tobytes());ai=len(self.doc['accessors'])
  v={'bufferView':vi,'componentType':component,'count':count,'type':kind}
  if kind=='VEC3':v.update(min=a.min(0).astype(float).tolist(),max=a.max(0).astype(float).tolist())
  self.doc['accessors'].append(v);return ai
 def targets(self,base,shapes,indices,base_normals=None):
  result=[];geo0=normals(base,indices)
  if base_normals is None:base_normals=geo0
  for positions in shapes:
   delta=positions-base;geo=normals(positions,indices)
   normal=base_normals+geo-geo0;normal/=np.maximum(np.linalg.norm(normal,axis=1)[:,None],1e-8)
   result.append({'POSITION':self.add(delta),'NORMAL':self.add(normal-base_normals)})
  return result
 def save(self,path):
  self.doc['buffers'][0]['byteLength']=len(self.data)
  encoded=json.dumps(self.doc,separators=(',',':')).encode();encoded+=b' '*((-len(encoded))%4)
  raw=struct.pack('<III',0x46546c67,2,12+8+len(encoded)+8+len(self.data))+struct.pack('<II',len(encoded),0x4e4f534a)+encoded+struct.pack('<II',len(self.data),0x004e4942)+self.data
  path.write_bytes(raw)

def sampled_lids(surface_dir):
 a=np.load(surface_dir/'sampling-surface.npz');z=a['z'];uv=a['uv'];xmin,xmax,ymin,ymax=a['bounds'];h,w=z.shape
 def sample(x,y):
  xx=np.clip((x-xmin)/(xmax-xmin)*(w-1),0,w-1);yy=np.clip((ymax-y)/(ymax-ymin)*(h-1),0,h-1)
  x0=int(xx);y0=int(yy);x1=min(x0+1,w-1);y1=min(y0+1,h-1);fx=xx-x0;fy=yy-y0
  zz=(z[y0,x0]*(1-fx)+z[y0,x1]*fx)*(1-fy)+(z[y1,x0]*(1-fx)+z[y1,x1]*fx)*fy
  uu=(uv[y0,x0]*(1-fx)+uv[y0,x1]*fx)*(1-fy)+(uv[y1,x0]*(1-fx)+uv[y1,x1]*fx)*fy
  return float(zz),uu
 # PNG masks come from the measured original projected UV surface, not an
 # invented generic eye sphere. Loading via Blender avoids external packages.
 meshes=[];landmarks={}
 for sign,label in [(1,'Left'),(-1,'Right')]:
  image=bpy.data.images.load(str(surface_dir/(label.lower()+'-paint-mask.png')),check_existing=False)
  pixels=np.array(image.pixels[:]).reshape(h,w,4)[::-1,:,0]>.5
  yy,xx=np.nonzero(pixels);columns=np.arange(xx.min(),xx.max()+1)
  tops=np.array([np.nonzero(pixels[:,c])[0].min() for c in columns]);bottoms=np.array([np.nonzero(pixels[:,c])[0].max() for c in columns])
  kernel=np.ones(7)/7
  tops=np.convolve(np.pad(tops,3,mode='edge'),kernel,mode='valid');bottoms=np.convolve(np.pad(bottoms,3,mode='edge'),kernel,mode='valid')
  xs=np.linspace(xmin+columns[0]/(w-1)*(xmax-xmin)-.0020,xmin+columns[-1]/(w-1)*(xmax-xmin)+.0020,37)
  cols=(xs-xmin)/(xmax-xmin)*(w-1)
  top=ymax-np.interp(cols,columns,tops)/(h-1)*(ymax-ymin)+.0020
  bottom=ymax-np.interp(cols,columns,bottoms)/(h-1)*(ymax-ymin)-.0025
  # Outer tips converge so the attached lid has a curved anatomical boundary.
  for i in [0,len(xs)-1]:top[i]=bottom[i]=(top[i]+bottom[i])*.5
  axis=np.linspace(-1,1,len(xs))
  seam=np.polyval(np.polyfit(axis,bottom+.25*(top-bottom),4),axis)
  seam=np.clip(seam,bottom,top)
  landmarks[label]={'source_mask_columns':[int(columns[0]),int(columns[-1])], 'top_y_range':[float(top.min()),float(top.max())], 'bottom_y_range':[float(bottom.min()),float(bottom.max())], 'head_joint_index':6,'lid_gap_m':.0004,'surface_offset_range_m':[.0012,.0028],'crease_curve':'degree-4 least-squares smoothing of the measured contour-derived seam'}
  for upper in [True,False]:
   stages=[];uvs=[];indices=[]
   rows=13
   for progress in [0,.25,.5,.75,1]:
    points=[]
    for j in range(rows):
     t=j/(rows-1)
     for i,x in enumerate(xs):
      boundary=top[i] if upper else bottom[i]
      edge=seam[i]+(.0002 if upper else -.0002)
      # Tiny open thickness is hidden by the runtime at blink==0.
      y=boundary+(edge-boundary)*max(progress,.0002)*t
      zz,_=sample(x,y)
      # The coarse surface is convex between grid vertices. A bounded inner
      # clearance prevents the original painted specular spots poking through;
      # taper at the measured perimeter keeps the lid attached, not floating.
      clearance=.0012+.0016*math.sin(math.pi*i/(len(xs)-1))*smooth(0,.22,t)
      points.append([x,y,zz+clearance])
      if progress==0:
       # A measured single forehead UV island; never interpolate across the
       # original left/right UV seam, which crosses unrelated atlas regions.
       # Four measured points inside one uninterrupted forehead atlas island.
       # Bilinear UVs avoid raster holes/adjacent UV islands at intermediate
       # samples while retaining the original orange texture and normal map.
       u=i/(len(xs)-1);v=j/(rows-1)
       low=np.array([.75243,.66416])*(1-u)+np.array([.74692,.65350])*u
       high=np.array([.73682,.67116])*(1-u)+np.array([.73235,.66216])*u
       uvs.append(low*(1-v)+high*v)
    stages.append(np.array(points,dtype=np.float32))
   for j in range(rows-1):
    for i in range(len(xs)-1):
     k=j*len(xs)+i
     indices.extend([[k,k+len(xs),k+1],[k+1,k+len(xs),k+len(xs)+1]] if upper else [[k,k+1,k+len(xs)],[k+1,k+len(xs)+1,k+len(xs)]])
   # Force front-facing normal orientation irrespective of signed y traversal.
   indices=np.array(indices,dtype=np.uint32)
   if normals(stages[4],indices)[:,2].mean()<0:indices=indices[:,[0,2,1]]
   shapes=[stages[0].copy() for _ in LIDS]
   
   for stage,positions in zip(LID_STAGES,stages[1:]):shapes[LIDS.index('Blink'+label+stage)]=positions
   meshes.append({'name':label+('UpperLid' if upper else 'LowerLid'),'base':stages[0],'shapes':shapes,'indices':indices,'uv':np.array(uvs,dtype=np.float32),'material':0})
  # A narrow physical crease follows the moving upper edge. It replaces no
  # original eye texture and is fully hidden together with the open lids.
  stages=[];rings=6;radius=.00045
  for progress in [0,.25,.5,.75,1]:
   pts=[]
   for i,x in enumerate(xs):
    y=top[i]+(seam[i]-top[i])*progress;zz,_=sample(x,y)
    for n in range(rings):
     angle=n/rings*math.tau
     clearance=.0012+.0016*math.sin(math.pi*i/(len(xs)-1))
     pts.append([x,y+math.cos(angle)*radius,zz+clearance+.0004+math.sin(angle)*radius])
   stages.append(np.array(pts,dtype=np.float32))
  ids=[]
  for i in range(len(xs)-1):
   for n in range(rings):
    j=i*rings+n;k=i*rings+(n+1)%rings
    ids.extend([[j,k,j+rings],[k,k+rings,j+rings]])
  shapes=[stages[0].copy() for _ in LIDS]
  for stage,positions in zip(LID_STAGES,stages[1:]):shapes[LIDS.index('Blink'+label+stage)]=positions
  meshes.append({'name':label+'LidCrease','base':stages[0],'shapes':shapes,'indices':np.array(ids,dtype=np.uint32),'uv':np.zeros((len(stages[0]),2),dtype=np.float32),'material':1})
 return meshes,landmarks

def main():
 parser=argparse.ArgumentParser();parser.add_argument('--source',required=True);parser.add_argument('--surface',required=True);parser.add_argument('--out',required=True);args=parser.parse_args(sys.argv[sys.argv.index('--')+1:])
 source=Path(args.source).resolve();out=Path(args.out).resolve();out.mkdir(parents=True,exist_ok=True)
 original,doc,binary=read_glb(source);before=copy.deepcopy(doc)
 assert len(doc['skins'][0]['joints'])==65 and len(doc['animations'])==9
 primitive=doc['meshes'][0]['primitives'][0];positions=accessor(doc,binary,primitive['attributes']['POSITION']);original_normals=accessor(doc,binary,primitive['attributes']['NORMAL']);indices=accessor(doc,binary,primitive['indices']).reshape(-1,3)
 bpy.ops.wm.read_factory_settings(use_empty=True);bpy.ops.import_scene.gltf(filepath=str(source),merge_vertices=False)
 rig=next(o for o in bpy.context.scene.objects if o.type=='ARMATURE');mesh=next(o for o in bpy.context.scene.objects if o.type=='MESH')
 shapes=[np.array([body_point(name,p) for p in positions],dtype=np.float32) for name in BODY]
 writer=Writer(doc,binary);primitive['targets']=writer.targets(positions,shapes,indices,original_normals)
 doc['meshes'][0]['weights']=[0.0]*len(BODY);doc['meshes'][0].setdefault('extras',{})['targetNames']=list(BODY)
 mesh.shape_key_add(name='Basis');inverse=mesh.matrix_world.inverted()
 for name in BODY:
  key=mesh.shape_key_add(name=name)
  for vert,result in zip(mesh.data.vertices,key.data):result.co=inverse@(C@Vector(body_point(name,C.inverted()@(mesh.matrix_world@vert.co))))
 lids,landmarks=sampled_lids(Path(args.surface).resolve())
 dark=bpy.data.materials.new('Lid crease — original dark lash tone');dark.use_nodes=True;dark.node_tree.nodes.get('Principled BSDF').inputs['Base Color'].default_value=(.014,.006,.003,1);dark.node_tree.nodes.get('Principled BSDF').inputs['Roughness'].default_value=.8
 darkidx=len(doc['materials']);doc['materials'].append({'name':'LumoLidCrease','pbrMetallicRoughness':{'baseColorFactor':[.014,.006,.003,1],'roughnessFactor':.8,'metallicFactor':0},'doubleSided':True})
 original_mesh_node=next(i for i,n in enumerate(doc['nodes']) if n.get('mesh')==0)
 parent=next(n for n in doc['nodes'] if original_mesh_node in n.get('children',[]))
 blender_lids=[]
 for lid in lids:
  base=lid['base'];ids=lid['indices'];norm=normals(base,ids)
  data=bpy.data.meshes.new(lid['name']);data.from_pydata([C@Vector(p) for p in base],[],ids.tolist());data.update()
  obj=bpy.data.objects.new(lid['name'],data);bpy.context.scene.collection.objects.link(obj);obj.data.materials.append(dark if lid['material'] else mesh.data.materials[0]);obj.parent=rig
  layer=data.uv_layers.new()
  for poly in data.polygons:
   poly.use_smooth=True
   for loop in poly.loop_indices:
    source_uv=lid['uv'][data.loops[loop].vertex_index]
    layer.data[loop].uv=(float(source_uv[0]),1.0-float(source_uv[1]))
  group=obj.vertex_groups.new(name='Head');group.add(list(range(len(base))),1.0,'REPLACE');mod=obj.modifiers.new('Original Head skin','ARMATURE');mod.object=rig
  obj.shape_key_add(name='Basis')
  for name,points in zip(LIDS,lid['shapes']):
   key=obj.shape_key_add(name=name)
   for vertex,p in zip(key.data,points):vertex.co=C@Vector(p)
  blender_lids.append(obj)
 # One skinned attachment with two material surfaces rather than six draws.
 lid_primitives=[]
 for material in [0,1]:
  parts=[p for p in lids if p['material']==material]
  base=np.concatenate([p['base'] for p in parts]);uvs=np.concatenate([p['uv'] for p in parts]);indices=[];offset=0
  for part in parts:indices.append(part['indices']+offset);offset+=len(part['base'])
  indices=np.concatenate(indices);normal=normals(base,indices)
  targets=[np.concatenate([p['shapes'][i] for p in parts]) for i in range(len(LIDS))]
  joint=np.zeros((len(base),4),dtype=np.uint16);joint[:,0]=6;weight=np.zeros((len(base),4),np.float32);weight[:,0]=1
  lid_primitives.append({'attributes':{'POSITION':writer.add(base),'NORMAL':writer.add(normal),'TEXCOORD_0':writer.add(uvs,'VEC2'),'JOINTS_0':writer.add(joint,'VEC4',5123),'WEIGHTS_0':writer.add(weight,'VEC4')},'indices':writer.add(indices.reshape(-1,1),'SCALAR',5125,34963),'material':darkidx if material else 0,'targets':writer.targets(base,targets,indices,normal)})
 mi=len(doc['meshes']);doc['meshes'].append({'name':'LumoEyelids','primitives':lid_primitives,'weights':[0.0]*len(LIDS),'extras':{'targetNames':list(LIDS)}})
 ni=len(doc['nodes']);doc['nodes'].append({'name':'LumoEyelids','mesh':mi,'skin':0});parent['children'].append(ni)
 target=out/'Lumo-Facial-Mobile.glb';writer.save(target)
 for track in list(rig.animation_data.nla_tracks):rig.animation_data.nla_tracks.remove(track)
 rig.animation_data.action=next(a for a in bpy.data.actions if a.name.startswith('idle'))
 bpy.context.scene.frame_set(0);bpy.context.view_layer.update();render_setup(bpy.context.scene,Vector((0,-.15685,1.408)))
 for obj in blender_lids:obj.hide_render=True
 bpy.ops.wm.save_as_mainfile(filepath=str(out/'Lumo-Facial-Authoring.blend'),compress=True)
 for name,bodyvals,blink in [('neutral',{},0),('blink_half',{},.5),('blink',{},1),('blink_intermediate',{},.651515151515),('gaze_right',{'LookRight':1},0),('jaw_articulation',{'JawArticulation':1},0),('blink_three_quarter',{},1)]:
  if name=='blink_three_quarter':
   centre=Vector((0,-.15685,1.408));bpy.context.scene.camera.location=centre+Vector((1.7,-3.4,.12));bpy.context.scene.camera.rotation_euler=(centre-bpy.context.scene.camera.location).to_track_quat('-Z','Y').to_euler()
  for s in BODY:mesh.data.shape_keys.key_blocks[s].value=bodyvals.get(s,0)
  for obj in blender_lids:
   obj.hide_render=blink==0
   for i,s in enumerate(LIDS):obj.data.shape_keys.key_blocks[s].value=max(0.0,1.0-abs(blink*4.0-float(i%4+1)))
  bpy.context.scene.render.filepath=str(out/(name+'.png'));bpy.ops.render.render(write_still=True)
 report={'source_sha256':hashlib.sha256(original).hexdigest(),'derived_sha256':hashlib.sha256(target.read_bytes()).hexdigest(),'source_binary_prefix_equal':bytes(writer.data[:len(binary)])==binary,'original_skin_equal':doc['skins']==before['skins'],'original_animation_metadata_equal':doc['animations']==before['animations'],'original_bones':65,'original_clips':[a['name'] for a in before['animations']],'original_body_vertex_count':len(positions),'authoring_lid_part_count':len(lids),'runtime_lid_mesh_count':1,'runtime_lid_surface_count':len(lid_primitives),'new_lid_vertices':sum(len(x['base']) for x in lids),'new_lid_triangles':sum(len(x['indices']) for x in lids),'body_shapes':list(BODY),'lid_shapes':list(LIDS),'measured_contour_control':landmarks,'blender':bpy.app.version_string,'renderer':'Cycles CPU','samples':48,'denoising':False,'limitations':['Original eye paint remains on original continuous surface; gaze uses restrained surface morphs, not an invented independent eyeball.','Jaw articulation deforms the existing closed muzzle; there is no anatomical mouth cavity and no phoneme/viseme claim.','Additional physical eyelids are new artist-authored geometry fitted to measured original contours.'],'source_unchanged':source.read_bytes()==original}
 (out/'authoring-report.json').write_text(json.dumps(report,indent=2)+'\n');print('LUMO_FACE_GEOMETRY='+json.dumps(report))
if __name__=='__main__':main()
