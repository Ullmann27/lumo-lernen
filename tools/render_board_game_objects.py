"""Original mobile board-game meshes, PBR materials and transparent renders.

Run Blender 4.3: blender -b --threads 4 --python tools/render_board_game_objects.py
Editable .blend and GLB sources are kept outside the shipped Flutter assets.
No external model, generation API, altered user photo or paid service is used.
"""
import json
import math
from pathlib import Path

import bpy
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets/lumo_design/board_games"
SOURCE = ROOT / "docs/design/2026-10-12-board-games/source"
OUT.mkdir(parents=True, exist_ok=True)
SOURCE.mkdir(parents=True, exist_ok=True)
bpy.ops.wm.read_factory_settings(use_empty=True)
scene = bpy.context.scene
scene.render.engine = "CYCLES"
scene.cycles.samples = 24
# The installed CPU-only Blender has no OpenImageDenoise build.
scene.cycles.use_denoising = False
scene.render.resolution_x = scene.render.resolution_y = 384
scene.render.resolution_percentage = 100
scene.render.film_transparent = True
scene.render.image_settings.file_format = "PNG"
scene.render.image_settings.color_mode = "RGBA"
scene.view_settings.view_transform = "AgX"
scene.world = bpy.data.worlds.new("Soft studio")
scene.world.use_nodes = True
scene.world.node_tree.nodes["Background"].inputs[0].default_value = (.22, .3, .44, 1)
scene.world.node_tree.nodes["Background"].inputs[1].default_value = .45


def material(name, color, roughness=.3, metallic=0):
    result = bpy.data.materials.new(name)
    result.use_nodes = True
    bsdf = result.node_tree.nodes["Principled BSDF"]
    bsdf.inputs["Base Color"].default_value = (*color, 1)
    bsdf.inputs["Roughness"].default_value = roughness
    bsdf.inputs["Metallic"].default_value = metallic
    return result


ivory = material("Ivory enamel", (.86, .92, .96), .22)
navy = material("Deep blue pips", (.007, .036, .082), .28)
gold = material("Warm brass", (.8, .41, .065), .26, .72)
blue = material("Child cyan enamel", (.012, .42, .6), .22, .15)
amber = material("Lumo amber enamel", (.9, .22, .027), .24, .12)
teal = material("Island teal enamel", (.055, .25, .24), .48)


def finish(obj, name, mat, parent):
    obj.name = name
    obj.parent = parent
    obj.data.materials.append(mat)
    for polygon in obj.data.polygons:
        polygon.use_smooth = True
    return obj


def cube(name, pos, dimensions, mat, parent, bevel=.1):
    bpy.ops.mesh.primitive_cube_add(size=1, location=pos)
    obj = finish(bpy.context.object, name, mat, parent)
    obj.dimensions = dimensions
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    modifier = obj.modifiers.new("Rounded tactile edges", "BEVEL")
    modifier.width = bevel
    modifier.segments = 3
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.modifier_apply(modifier=modifier.name)
    obj.modifiers.new("Weighted corner normals", "WEIGHTED_NORMAL")
    return obj


def sphere(name, pos, radius, mat, parent, scale=(1, 1, 1)):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=20, ring_count=12, radius=radius, location=pos)
    obj = finish(bpy.context.object, name, mat, parent)
    obj.scale = scale
    return obj


def cylinder(name, pos, radius, depth, mat, parent):
    bpy.ops.mesh.primitive_cylinder_add(vertices=32, radius=radius, depth=depth, location=pos)
    obj = finish(bpy.context.object, name, mat, parent)
    modifier = obj.modifiers.new("Rounded rim", "BEVEL")
    modifier.width = .055
    modifier.segments = 3
    return obj


def group(name):
    obj = bpy.data.objects.new(name, None)
    scene.collection.objects.link(obj)
    return obj


die = group("Lumo Dice — opposite faces sum to seven")
cube("Rounded die", (0, 0, 0), (1.6, 1.6, 1.6), ivory, die, .17)
corners = [(-.36, -.36), (.36, .36)]
patterns = {1: [(0, 0)], 2: corners, 3: corners + [(0, 0)],
            4: corners + [(-.36, .36), (.36, -.36)],
            5: corners + [(-.36, .36), (.36, -.36), (0, 0)],
            6: [(x, y) for x in [-.36, .36] for y in [-.4, 0, .4]]}
normals = {1: (0, 0, 1), 6: (0, 0, -1), 2: (0, -1, 0),
           5: (0, 1, 0), 3: (1, 0, 0), 4: (-1, 0, 0)}
for number, normal in normals.items():
    n = Vector(normal)
    axis = Vector((1, 0, 0)) if abs(n.x) < .5 else Vector((0, 1, 0))
    second = n.cross(axis)
    for index, (x, y) in enumerate(patterns[number]):
        point = n * .792 + axis * x + second * y
        pip = sphere(f"Face {number} pip {index+1}", point, .112, navy, die)
        pip.rotation_mode = "QUATERNION"
        pip.rotation_quaternion = Vector((0, 0, 1)).rotation_difference(n)
        pip.scale = (1, 1, .16)

pawns = []
for name, mat in [("pawn_child", blue), ("pawn_lumo", amber)]:
    pawn = group(name)
    cylinder("Brass foot", (0, 0, -.68), .7, .16, gold, pawn)
    cylinder("Enamel foot", (0, 0, -.55), .64, .16, mat, pawn)
    sphere("Curved body", (0, 0, -.08), .54, mat, pawn, (.68, .68, 1.2))
    cylinder("Brass collar", (0, 0, .36), .28, .085, gold, pawn)
    sphere("Rounded head", (0, 0, .65), .36, mat, pawn)
    pawns.append(pawn)
tile = group("tile")
cube("Island tile", (0, 0, 0), (2, 2, .34), teal, tile, .18)
cube("Brass tile inset", (0, 0, .15), (1.68, 1.68, .08), gold, tile, .13)
cube("Teal playable face", (0, 0, .2), (1.56, 1.56, .06), teal, tile, .12)
groups = [die, *pawns, tile]

for at, energy, size in [((2, -4, 6), 700, 4), ((-4, -1, 3), 420, 3), ((1, 4, 4), 850, 3)]:
    light = bpy.data.lights.new("Softbox", "AREA")
    light.energy = energy
    light.shape = "DISK"
    light.size = size
    obj = bpy.data.objects.new("Softbox", light)
    scene.collection.objects.link(obj)
    obj.location = at
    obj.rotation_euler = (-obj.location).to_track_quat('-Z', 'Y').to_euler()
camera = bpy.data.objects.new("Asset orthographic camera", bpy.data.cameras.new("Camera"))
scene.collection.objects.link(camera)
scene.camera = camera
camera.data.type = "ORTHO"
camera.data.ortho_scale = 2.7


def view(at):
    camera.location = at
    camera.rotation_euler = (-camera.location).to_track_quat('-Z', 'Y').to_euler()


def show(target):
    for item in groups:
        for child in item.children:
            child.hide_render = item != target


manifest = []
for item in groups:
    bpy.ops.object.select_all(action="DESELECT")
    for child in item.children:
        child.select_set(True)
    item.select_set(True)
    filename = "die.glb" if item == die else item.name + ".glb"
    bpy.ops.export_scene.gltf(filepath=str(SOURCE / filename), export_format="GLB",
                              use_selection=True, export_yup=True, export_animations=False)
    manifest.append({"file": filename, "objects": len(item.children),
                     "mesh_vertices": sum(len(child.data.vertices) for child in item.children)})

show(die)
view((.5, -7, 1.1))
for number, normal in normals.items():
    die.rotation_mode = "QUATERNION"
    die.rotation_quaternion = Vector(normal).rotation_difference(Vector((0, -1, 0)))
    scene.render.filepath = str(OUT / f"die_{number}.png")
    bpy.ops.render.render(write_still=True)
die.rotation_quaternion.identity()
for item in [*pawns, tile]:
    show(item)
    view((3, -6, 3.4) if item != tile else (0, -4, 8))
    scene.render.filepath = str(OUT / (item.name + ".png"))
    bpy.ops.render.render(write_still=True)
for item in groups:
    for child in item.children:
        child.hide_render = False
bpy.ops.wm.save_as_mainfile(filepath=str(SOURCE / "Lumo-Board-Game-Objects.blend"))
(SOURCE / "MANIFEST.json").write_text(json.dumps({"author": "Lumo project / Ullmann27",
    "source": "Original procedural Blender geometry, no external assets",
    "license": "Project-owned source, no third-party attribution required",
    "renderer": "Blender 4.3 / Cycles CPU / 24 samples / transparent 384px",
    "runtime": "Flutter uses pre-rendered PNGs; these are not a new 3D game runtime",
    "models": manifest}, indent=2) + "\n")
