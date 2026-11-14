"""Read the original Lumo GLB in Blender; save measured geometry and real views."""
import bpy
import argparse
import json
import math
import sys
from pathlib import Path
from mathutils import Vector


def bounds(points):
    return [[min(p[a] for p in points) for a in range(3)],
            [max(p[a] for p in points) for a in range(3)]] if points else None


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--source', required=True)
    parser.add_argument('--out', required=True)
    args = parser.parse_args(sys.argv[sys.argv.index('--') + 1:])
    out = Path(args.out)
    out.mkdir(parents=True, exist_ok=True)
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=str(Path(args.source).resolve()), merge_vertices=False)
    rigs = [o for o in bpy.context.scene.objects if o.type == 'ARMATURE']
    assert len(rigs) == 1
    rig = rigs[0]
    original_actions = [a.name for a in bpy.data.actions]
    for track in list(rig.animation_data.nla_tracks):
        rig.animation_data.nla_tracks.remove(track)
    rig.animation_data.action = next(a for a in bpy.data.actions if a.name.startswith('idle'))
    bpy.context.scene.frame_set(0)
    bpy.context.view_layer.update()
    report = {'blender': bpy.app.version_string, 'bone_count': len(rig.data.bones),
              'bones': list(rig.data.bones.keys()), 'original_actions': original_actions,
              'meshes': [], 'coordinate_system': 'Blender world: X right, -Y forward, Z up'}
    head_points = []
    for obj in bpy.context.scene.objects:
        if obj.type != 'MESH' or not any(m.type == 'ARMATURE' and m.object == rig for m in obj.modifiers):
            continue
        data = obj.data
        groups = {g.index: g.name for g in obj.vertex_groups}
        verts = [obj.matrix_world @ v.co for v in data.vertices]
        links = [[] for _ in verts]
        for edge in data.edges:
            a, b = edge.vertices
            links[a].append(b); links[b].append(a)
        unseen = set(range(len(verts)))
        components = []
        while unseen:
            queue = [unseen.pop()]; ids = []
            while queue:
                vertex = queue.pop(); ids.append(vertex)
                for other in links[vertex]:
                    if other in unseen:
                        unseen.remove(other); queue.append(other)
            components.append({'vertices': len(ids), 'bounds': bounds([verts[i] for i in ids]),
                               'vertex_ids': ids})
        components.sort(key=lambda c: c['vertices'], reverse=True)
        head_ids = [v.index for v in data.vertices if sum(g.weight for g in v.groups
                    if groups.get(g.group) in ['Head', 'Crown']) >= 0.8]
        head_points.extend(verts[i] for i in head_ids)
        report['meshes'].append({'name': obj.name, 'vertices': len(verts),
            'polygons': len(data.polygons), 'triangles': sum(len(p.vertices)-2 for p in data.polygons),
            'bounds': bounds(verts), 'components': components,
            'head_weighted_vertices': head_ids, 'head_bounds': bounds([verts[i] for i in head_ids]),
            'shape_keys': list(data.shape_keys.key_blocks.keys()) if data.shape_keys else [],
            'uv_layers': list(data.uv_layers.keys()), 'materials': [m.name for m in data.materials]})
    head_bounds = bounds(head_points)
    report['head_bounds'] = head_bounds
    report['head_bone_world'] = list(rig.matrix_world @ rig.pose.bones['Head'].head)
    for img in bpy.data.images:
        if img.type == 'IMAGE' and img.packed_file:
            target = out / (img.name.replace('/', '_') + '.png')
            img.filepath_raw = str(target); img.file_format = 'PNG'; img.save()
    (out / 'geometry-inspection.json').write_text(json.dumps(report, indent=2) + '\n')
    print('LUMO_FACE_INSPECTION=' + json.dumps({
        'bones': report['bone_count'], 'clips': original_actions,
        'head_bounds': head_bounds,
        'meshes': [{k: m[k] for k in ['name','vertices','triangles','shape_keys','uv_layers']}
                   | {'component_sizes': [c['vertices'] for c in m['components'][:20]]}
                   for m in report['meshes']]}))
    scene = bpy.context.scene
    scene.render.engine = 'CYCLES'; scene.cycles.device = 'CPU'
    scene.cycles.samples = 24; scene.cycles.use_denoising = False
    scene.render.resolution_x = 512; scene.render.resolution_y = 512
    scene.render.resolution_percentage = 100
    scene.world = bpy.data.worlds.new('FaceInspectionWorld'); scene.world.color = (.18, .18, .18)
    scene.view_settings.view_transform = 'AgX'
    middle = (Vector(head_bounds[0]) + Vector(head_bounds[1])) / 2
    for location, power, size in [((2,-4,5),500,4),((-3,-2,3),350,3),((0,3,3),450,3)]:
        light=bpy.data.lights.new('InspectionSoftbox','AREA'); light.energy=power;light.shape='DISK';light.size=size
        ob=bpy.data.objects.new(light.name,light);scene.collection.objects.link(ob);ob.location=location
        ob.rotation_euler=(middle-ob.location).to_track_quat('-Z','Y').to_euler()
    camera_data=bpy.data.cameras.new('InspectionCamera');camera=bpy.data.objects.new('InspectionCamera',camera_data)
    scene.collection.objects.link(camera);scene.camera=camera
    camera_data.type='ORTHO';camera_data.ortho_scale=max(head_bounds[1][2]-head_bounds[0][2],head_bounds[1][0]-head_bounds[0][0])*1.15
    for name, offset in [('neutral_front',Vector((0,-4,0))),('neutral_three_quarter',Vector((2.1,-4,0.25)))]:
        camera.location=middle+offset;camera.rotation_euler=(middle-camera.location).to_track_quat('-Z','Y').to_euler()
        scene.render.filepath=str(out/(name+'.png'));bpy.ops.render.render(write_still=True)


if __name__ == '__main__':
    main()
