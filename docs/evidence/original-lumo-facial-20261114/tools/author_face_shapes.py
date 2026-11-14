"""Bounded face-shape authoring on original vertices, UVs and skin.

The sculpt control regions are artist-selected from the original UV/mesh
inspection. They are not represented as pre-existing facial anatomy/rigs.
The GLB writer adds only morph targets; original buffers, skin and nine
animation payloads remain byte-identical prefixes of the derived asset.
"""
import argparse
import hashlib
import json
import math
import struct
import sys
from pathlib import Path

import bpy
import numpy as np
from mathutils import Matrix, Vector

C = Matrix(((1, 0, 0), (0, 0, -1), (0, 1, 0)))
SHAPES = ('BlinkLeft', 'BlinkRight', 'LookLeft', 'LookRight', 'LookUp', 'LookDown', 'JawOpen')


def smooth(a, b, x):
    t = max(0.0, min(1.0, (x-a)/(b-a)))
    return t*t*(3-2*t)


def shape_point(name, point):
    """Godot/model metres; all changes vanish outside the measured face."""
    x, y, z = point
    result = Vector(point)
    for sign, blink in ((1, 'BlinkLeft'), (-1, 'BlinkRight')):
        centre_x, centre_y = sign*0.108, 1.352
        dx, dy = (x-centre_x)/0.063, (y-centre_y)/0.062
        front = smooth(.17, .22, z) * (1-smooth(.35, .39, z))
        if name == blink:
            influence = (1-smooth(1.0, 1.48, max(abs(dx), abs(dy))))*front
            line = 1.337 + .006*min(1, dx*dx)
            result.y += (line-y)*.985*influence
        elif name.startswith('Look'):
            # Original iris texture travels with its original surface vertices.
            # This is a restrained surface morph, not a newly invented eyeball.
            radial = math.sqrt(dx*dx + dy*dy)
            influence = (1-smooth(.38, 1.04, radial))*front
            if name in ('LookLeft','LookRight'):
                result.x += (-1 if name == 'LookLeft' else 1)*.008*influence
            else:
                result.y += (1 if name == 'LookUp' else -1)*.006*influence
    if name == 'JawOpen':
        lip_line = 1.218 + .42*min(abs(x), .14)
        influence = (1-smooth(lip_line-.006, lip_line+.009, y))
        influence *= smooth(1.105, 1.15, y)*(1-smooth(.105, .18, abs(x)))*smooth(.20,.27,z)
        pivot_y, pivot_z, angle = 1.25, .195, .24
        cy, cz = y-pivot_y, z-pivot_z
        rotated_y = pivot_y+cy*math.cos(angle)-cz*math.sin(angle)
        rotated_z = pivot_z+cy*math.sin(angle)+cz*math.cos(angle)
        result.y += (rotated_y-y)*influence
        result.z += (rotated_z-z)*influence
    return result


def read_glb(path):
    raw=path.read_bytes(); length=struct.unpack_from('<I',raw,12)[0]
    document=json.loads(raw[20:20+length]); offset=20+length
    size, kind=struct.unpack_from('<II',raw,offset);assert kind==0x004e4942
    return raw, document, raw[offset+8:offset+8+size]


def accessor(document, data, index):
    a=document['accessors'][index];v=document['bufferViews'][a['bufferView']]
    dtype={5126:'<f4',5123:'<u2',5121:'u1',5125:'<u4'}[a['componentType']]
    width={'VEC3':3,'VEC2':2,'VEC4':4,'SCALAR':1,'MAT4':16}[a['type']]
    stride=v.get('byteStride',np.dtype(dtype).itemsize*width)
    return np.ndarray((a['count'],width),np.dtype(dtype),data,
        v.get('byteOffset',0)+a.get('byteOffset',0),
        strides=(stride,np.dtype(dtype).itemsize)).copy()


def add_targets(original, document, data, target, deltas):
    combined=bytearray(data)
    primitive=document['meshes'][0]['primitives'][0]
    assert 'targets' not in primitive
    targets=[]
    for name in SHAPES:
        values=deltas[name].astype('<f4')
        while len(combined)%4:combined.append(0)
        view=len(document['bufferViews'])
        document['bufferViews'].append({'buffer':0,'byteOffset':len(combined),
                                       'byteLength':values.nbytes,'target':34962})
        combined.extend(values.tobytes())
        index=len(document['accessors'])
        document['accessors'].append({'bufferView':view,'componentType':5126,
            'count':len(values),'type':'VEC3','min':values.min(0).astype(float).tolist(),
            'max':values.max(0).astype(float).tolist()})
        targets.append({'POSITION':index})
    primitive['targets']=targets
    document['meshes'][0]['weights']=[0.0]*len(SHAPES)
    document['meshes'][0].setdefault('extras',{})['targetNames']=list(SHAPES)
    document['buffers'][0]['byteLength']=len(combined)
    encoded=json.dumps(document,separators=(',',':')).encode()
    encoded+=b' '*((-len(encoded))%4)
    result=struct.pack('<III',0x46546c67,2,12+8+len(encoded)+8+len(combined))
    result+=struct.pack('<II',len(encoded),0x4e4f534a)+encoded
    result+=struct.pack('<II',len(combined),0x004e4942)+combined
    target.parent.mkdir(parents=True,exist_ok=True);target.write_bytes(result)
    assert bytes(combined[:len(data)])==data


def render_setup(scene, centre):
    scene.render.engine='CYCLES';scene.cycles.device='CPU'
    scene.cycles.samples=48;scene.cycles.use_denoising=False
    scene.render.resolution_x=640;scene.render.resolution_y=640;scene.render.resolution_percentage=100
    scene.world=bpy.data.worlds.new('FacialStudioWorld');scene.world.color=(.13,.16,.20)
    scene.view_settings.view_transform='AgX'
    for location,power,size in [((2,-4,5),500,4),((-3,-2,3),350,3),((0,3,3),450,3)]:
        light=bpy.data.lights.new('Softbox','AREA');light.energy=power;light.shape='DISK';light.size=size
        obj=bpy.data.objects.new(light.name,light);scene.collection.objects.link(obj);obj.location=location
        obj.rotation_euler=(centre-obj.location).to_track_quat('-Z','Y').to_euler()
    camera_data=bpy.data.cameras.new('FaceCamera');camera=bpy.data.objects.new('FaceCamera',camera_data)
    scene.collection.objects.link(camera);scene.camera=camera
    camera_data.type='ORTHO';camera_data.ortho_scale=.73
    camera.location=centre+Vector((.15,-4,0));camera.rotation_euler=(centre-camera.location).to_track_quat('-Z','Y').to_euler()


def main():
    parser=argparse.ArgumentParser();parser.add_argument('--source',required=True)
    parser.add_argument('--out',required=True);args=parser.parse_args(sys.argv[sys.argv.index('--')+1:])
    source=Path(args.source).resolve();out=Path(args.out).resolve();out.mkdir(parents=True,exist_ok=True)
    original,document,binary=read_glb(source);original_document=json.loads(json.dumps(document))
    assert len(document['skins'][0]['joints'])==65 and len(document['animations'])==9
    positions=accessor(document,binary,document['meshes'][0]['primitives'][0]['attributes']['POSITION'])
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=str(source),merge_vertices=False)
    rig=next(o for o in bpy.context.scene.objects if o.type=='ARMATURE')
    mesh=next(o for o in bpy.context.scene.objects if o.type=='MESH' and any(m.type=='ARMATURE' and m.object==rig for m in o.modifiers))
    assert len(rig.data.bones)==65 and not mesh.data.shape_keys
    imported=[a.name for a in bpy.data.actions]
    mesh.shape_key_add(name='Basis')
    inverse=mesh.matrix_world.inverted()
    for name in SHAPES:
        key=mesh.shape_key_add(name=name)
        for original_vertex,vertex in zip(mesh.data.vertices,key.data):
            world=mesh.matrix_world@original_vertex.co
            godot=C.inverted()@world
            vertex.co=inverse@(C@shape_point(name,godot))
    deltas={name:np.array([list(shape_point(name,p)-Vector(p)) for p in positions],dtype=np.float32) for name in SHAPES}
    # Preserve seam duplicates: the deformation depends on original position,
    # not UV island/index; the neutral weights remain exactly zero.
    add_targets(original,document,binary,out/'Lumo-Facial-Mobile.glb',deltas)
    for track in list(rig.animation_data.nla_tracks):rig.animation_data.nla_tracks.remove(track)
    rig.animation_data.action=next(a for a in bpy.data.actions if a.name.startswith('idle'))
    bpy.context.scene.frame_set(0);bpy.context.view_layer.update()
    report={'source':str(source),'source_sha256':hashlib.sha256(original).hexdigest(),
        'derived_sha256':hashlib.sha256((out/'Lumo-Facial-Mobile.glb').read_bytes()).hexdigest(),
        'original_buffer_prefix_byte_equal':True,'original_bones':65,'original_clips':[a['name'] for a in original_document['animations']],
        'original_animations_metadata_equal':document['animations']==original_document['animations'],
        'skin_metadata_equal':document['skins']==original_document['skins'],
        'blender':bpy.app.version_string,'shapes':{},
        'anatomy_limit':'Original is one welded textured surface, not separate eye/jaw anatomy. Shapes are bounded surface sculpt deformations; no phoneme visemes are claimed.'}
    for name,data in deltas.items():
        lengths=np.linalg.norm(data,axis=1);ids=np.flatnonzero(lengths>1e-7)
        report['shapes'][name]={'moved_vertices':len(ids),'maximum_displacement_metres':float(lengths.max()),
            'source_bounds':[positions[ids].min(0).astype(float).tolist(),positions[ids].max(0).astype(float).tolist()]}
    render_setup(bpy.context.scene,Vector((0,-.15685,1.408)))
    bpy.ops.wm.save_as_mainfile(filepath=str(out/'Lumo-Facial-Authoring.blend'),compress=True)
    for name,values in [('neutral',{}),('blink',{'BlinkLeft':1,'BlinkRight':1}),
                        ('gaze_right',{'LookRight':1}),('jaw_open',{'JawOpen':1})]:
        for shape in SHAPES:mesh.data.shape_keys.key_blocks[shape].value=values.get(shape,0)
        bpy.context.scene.render.filepath=str(out/(name+'.png'));bpy.ops.render.render(write_still=True)
    report['source_unchanged']=source.read_bytes()==original
    (out/'authoring-report.json').write_text(json.dumps(report,indent=2)+'\n')
    print('LUMO_FACIAL_AUTHORING='+json.dumps(report))


if __name__=='__main__':main()
