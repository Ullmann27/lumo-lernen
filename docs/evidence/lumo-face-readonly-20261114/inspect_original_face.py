"""Read original GLB and existing authoring blend; write only a QA inventory."""
import collections
import hashlib
import json
import struct
from pathlib import Path

import bpy

ROOT = Path('/workspace/scratch/5987865ae883/lumo-godot')
OUT = Path('/workspace/scratch/5987865ae883/qa/lumo-face-readonly-20261114')
GLB = ROOT / 'assets/characters/lumo_animated/Lumo-Animated-Mobile.glb'
BLEND = ROOT / 'docs/evidence/studio-character-20261113/Lumo-Studio-Actions.blend'


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def bounds(points):
    if not points:
        return None
    return [[min(p[i] for p in points) for i in range(3)],
            [max(p[i] for p in points) for i in range(3)]]


def components(mesh, weld=False):
    parents = list(range(len(mesh.vertices)))

    def find(i):
        while parents[i] != i:
            parents[i] = parents[parents[i]]
            i = parents[i]
        return i

    def join(a, b):
        parents[find(a)] = find(b)

    if weld:
        seen = {}
        for v in mesh.vertices:
            key = tuple(round(float(x), 6) for x in v.co)
            if key in seen:
                join(v.index, seen[key])
            else:
                seen[key] = v.index
    for edge in mesh.edges:
        join(*edge.vertices)
    groups = collections.defaultdict(list)
    for v in mesh.vertices:
        groups[find(v.index)].append(v)
    return sorted([{'vertices': len(group),
                    'bounds_mesh_local': bounds([tuple(v.co) for v in group])}
                   for group in groups.values()], key=lambda row: row['vertices'], reverse=True)


def inventory(label):
    result = {'label': label, 'objects': [], 'meshes': [], 'armatures': [],
              'actions': [{'name': a.name, 'frame_range': list(a.frame_range)} for a in bpy.data.actions]}
    for obj in bpy.context.scene.objects:
        result['objects'].append({'name': obj.name, 'type': obj.type})
        if obj.type == 'ARMATURE':
            result['armatures'].append({'name': obj.name, 'bones': [
                {'name': b.name, 'parent': b.parent.name if b.parent else None,
                 'head_local': list(b.head_local), 'tail_local': list(b.tail_local)}
                for b in obj.data.bones]})
        if obj.type != 'MESH':
            continue
        mesh = obj.data
        groups = {v.index: v.name for v in obj.vertex_groups}
        by_bone = collections.defaultdict(list)
        for vertex in mesh.vertices:
            if vertex.groups:
                strongest = max(vertex.groups, key=lambda g: g.weight)
                by_bone[groups[strongest.group]].append(tuple(vertex.co))
        h = hashlib.sha256()
        for v in mesh.vertices:
            h.update(struct.pack('<3f', *v.co))
        for p in mesh.polygons:
            h.update(struct.pack('<I', len(p.vertices)))
            h.update(struct.pack('<' + 'I' * len(p.vertices), *p.vertices))
        materials = []
        for m in mesh.materials:
            materials.append({'name': m.name, 'images': [
                {'node': n.name, 'image': n.image.name, 'size': list(n.image.size)}
                for n in m.node_tree.nodes if n.type == 'TEX_IMAGE' and n.image]})
        result['meshes'].append({
            'object': obj.name, 'mesh': mesh.name, 'vertices': len(mesh.vertices),
            'edges': len(mesh.edges), 'polygons': len(mesh.polygons),
            'geometry_sha256': h.hexdigest(),
            'shape_keys': [k.name for k in mesh.shape_keys.key_blocks] if mesh.shape_keys else [],
            'vertex_groups': list(groups.values()), 'materials': materials,
            'uv_layers': [u.name for u in mesh.uv_layers],
            'dominant_head_groups': {name: {'vertices': len(points), 'bounds_mesh_local': bounds(points)}
                                     for name, points in by_bone.items()
                                     if name in ('Neck', 'Head', 'Crown')},
            'raw_connected_components': components(mesh),
            'position_welded_connected_components_1e_6': components(mesh, weld=True),
        })
    return result


before = {'glb': digest(GLB), 'blend': digest(BLEND)}
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=str(GLB))
original = inventory('original_glb_import')
bpy.ops.wm.open_mainfile(filepath=str(BLEND), load_ui=False)
authoring = inventory('existing_studio_blend_read_only')
after = {'glb': digest(GLB), 'blend': digest(BLEND)}
assert before == after
report = {'blender_version': bpy.app.version_string, 'source_paths': {'glb': str(GLB), 'blend': str(BLEND)},
          'before_sha256': before, 'after_sha256': after, 'sources_unchanged': True,
          'original': original, 'existing_blend': authoring,
          'scope': 'Read/import only; no object, mesh, material, bone, shape key, saved asset or product file was authored.'}
(OUT / 'blender-face-inventory.json').write_text(json.dumps(report, ensure_ascii=False, indent=2) + '\n')
print('[LumoFaceReadOnly] Inventory saved; original asset bytes unchanged')
