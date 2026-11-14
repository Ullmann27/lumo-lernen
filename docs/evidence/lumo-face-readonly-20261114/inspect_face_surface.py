"""Two diagnostic renders of the original surface; never save or export assets."""
import hashlib
import json
from pathlib import Path

import bpy
from mathutils import Vector

ROOT = Path('/workspace/scratch/5987865ae883/lumo-godot')
OUT = Path('/workspace/scratch/5987865ae883/qa/lumo-face-readonly-20261114')
GLB = ROOT / 'assets/characters/lumo_animated/Lumo-Animated-Mobile.glb'
BLEND = ROOT / 'docs/evidence/studio-character-20261113/Lumo-Studio-Actions.blend'
before = {str(p): hashlib.sha256(p.read_bytes()).hexdigest() for p in (GLB, BLEND)}
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=str(GLB))
rig = next(o for o in bpy.context.scene.objects if o.type == 'ARMATURE')
mesh = next(o for o in bpy.context.scene.objects if o.type == 'MESH' and o.vertex_groups)
helpers = [{'name': o.name, 'hide_render': o.hide_render,
            'collections': [c.name for c in o.users_collection],
            'used_as_custom_shape_by_bones': [p.name for p in rig.pose.bones if p.custom_shape == o]}
           for o in bpy.data.objects if o.type == 'MESH' and o != mesh]
head_index = mesh.vertex_groups['Head'].index
head_weights = [g.weight for v in mesh.data.vertices for g in v.groups if g.group == head_index]
scene = bpy.context.scene
scene.render.engine = 'CYCLES'
scene.cycles.device = 'CPU'
scene.cycles.samples = 24
scene.cycles.use_denoising = False
scene.render.threads_mode = 'FIXED'
scene.render.threads = 4
scene.render.resolution_x = 512
scene.render.resolution_y = 512
scene.render.resolution_percentage = 100
scene.render.image_settings.file_format = 'PNG'
scene.world = bpy.data.worlds.new('DiagnosticWorld')
scene.world.use_nodes = True
scene.world.node_tree.nodes['Background'].inputs['Color'].default_value = (0.14, 0.17, 0.23, 1)
scene.world.node_tree.nodes['Background'].inputs['Strength'].default_value = 0.4
camera_data = bpy.data.cameras.new('DiagnosticCamera')
camera = bpy.data.objects.new('DiagnosticCamera', camera_data)
scene.collection.objects.link(camera)
camera.location = (0.32, -2.4, 1.52)
target = Vector((0, -0.08, 1.36))
camera.rotation_euler = (target - camera.location).to_track_quat('-Z', 'Y').to_euler()
camera_data.type = 'ORTHO'
camera_data.ortho_scale = 0.96
scene.camera = camera
for name, pos, energy, size in [('Key', (-2, -3, 4), 400, 3), ('Fill', (2, -1, 2), 180, 2)]:
    light_data = bpy.data.lights.new(name, 'AREA')
    light_data.energy = energy
    light_data.shape = 'DISK'
    light_data.size = size
    light = bpy.data.objects.new(name, light_data)
    scene.collection.objects.link(light)
    light.location = pos
    light.rotation_euler = (target - light.location).to_track_quat('-Z', 'Y').to_euler()
scene.render.filepath = str(OUT / 'original-face-textured.png')
bpy.ops.render.render(write_still=True)
clay = bpy.data.materials.new('DiagnosticClayOnly')
clay.use_nodes = True
node = clay.node_tree.nodes.get('Principled BSDF')
node.inputs['Base Color'].default_value = (0.55, 0.55, 0.55, 1)
node.inputs['Roughness'].default_value = 0.8
scene.view_layers[0].material_override = clay
scene.render.filepath = str(OUT / 'original-face-geometry-only.png')
bpy.ops.render.render(write_still=True)
bpy.ops.wm.open_mainfile(filepath=str(BLEND), load_ui=False)
library = {name: len(getattr(bpy.data, name)) for name in ('objects', 'meshes', 'armatures', 'materials', 'actions', 'shape_keys')}
after = {str(p): hashlib.sha256(p.read_bytes()).hexdigest() for p in (GLB, BLEND)}
assert before == after
report = {'blender_version': bpy.app.version_string, 'source_hashes_before': before,
          'source_hashes_after': after, 'sources_unchanged': True, 'helper_meshes': helpers,
          'head_influenced_vertices': len(head_weights), 'head_weight_min': min(head_weights),
          'head_weight_max': max(head_weights), 'existing_blend_data_block_counts': library,
          'render': {'engine': 'Cycles', 'device': 'CPU', 'samples': 24, 'denoising': False,
                     'dimensions': [512, 512], 'camera': [0.32, -2.4, 1.52],
                     'scope': 'Actual original surface. The second render disables textures/materials in memory to inspect geometry. No face animation or product change.'},
          'images': [{'file': p.name, 'bytes': p.stat().st_size,
                      'sha256': hashlib.sha256(p.read_bytes()).hexdigest()}
                     for p in (OUT / 'original-face-textured.png', OUT / 'original-face-geometry-only.png')]}
(OUT / 'surface-inspection.json').write_text(json.dumps(report, ensure_ascii=False, indent=2) + '\n')
print('[LumoFaceReadOnly] Original and geometry-only surface views saved; sources unchanged')
