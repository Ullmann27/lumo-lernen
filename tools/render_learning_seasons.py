"""Render original offline season dioramas, not screenshots or concept proof.

Run: blender --background --threads 4 --python tools/render_learning_seasons.py
Flutter uses only the four PNGs. The editable Blender source is kept separately.
No online generation, uploaded child data, third-party model or paid API.
"""
import math
from pathlib import Path

import bpy
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / "assets/lumo_design/icons"
SOURCE = ROOT / "docs/design/2026-10-11-learning-adventures/source"
ASSETS.mkdir(parents=True, exist_ok=True)
SOURCE.mkdir(parents=True, exist_ok=True)
bpy.ops.wm.read_factory_settings(use_empty=True)
scene = bpy.context.scene
scene.render.engine = "CYCLES"
scene.cycles.device = "CPU"
scene.cycles.samples = 48
scene.cycles.use_denoising = True
scene.render.resolution_x = 512
scene.render.resolution_y = 512
scene.render.resolution_percentage = 100
scene.render.film_transparent = True
scene.render.image_settings.file_format = "PNG"
scene.render.image_settings.color_mode = "RGBA"
scene.view_settings.view_transform = "AgX"
scene.world = bpy.data.worlds.new("Offline diorama studio")
scene.world.use_nodes = True
scene.world.node_tree.nodes["Background"].inputs[0].default_value = (
    .28, .38, .58, 1
)
scene.world.node_tree.nodes["Background"].inputs[1].default_value = .45


def material(name, color, roughness=.42, metallic=0):
    mat = bpy.data.materials.new(name)
    mat.diffuse_color = (*color, 1)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = (*color, 1)
    bsdf.inputs["Roughness"].default_value = roughness
    bsdf.inputs["Metallic"].default_value = metallic
    return mat


mats = {
    "bark": material("Warm tree bark", (.20, .075, .029)),
    "rock": material("Blue island stone", (.09, .19, .35)),
    "grass": material("Fresh grass", (.045, .28, .095)),
    "spring": material("Cherry blossom", (.86, .21, .42)),
    "pink_light": material("Pale blossom petals", (1, .59, .74)),
    "summer": material("Leaf green", (.06, .38, .095)),
    "autumn": material("Autumn leaf orange", (.89, .20, .018)),
    "gold": material("Autumn gold", (.95, .55, .035)),
    "snow": material("Clean snow", (.88, .95, 1)),
    "ice": material("Icy edge", (.18, .53, .77)),
    "yellow": material("Warm sunshine", (1, .66, .07)),
    "white": material("Cloud", (.96, .98, 1)),
    "black": material("Snowman eyes", (.015, .023, .045)),
    "carrot": material("Carrot", (.94, .22, .025)),
    "scarf": material("Lumo blue scarf", (.012, .18, .58)),
}
collections = {}
current = None


def assign(obj, name, mat):
    obj.name = name
    for old in list(obj.users_collection):
        old.objects.unlink(obj)
    current.objects.link(obj)
    obj.data.materials.append(mat)
    for polygon in getattr(obj.data, "polygons", []):
        polygon.use_smooth = True
    return obj


def sphere(name, position, scale, mat):
    bpy.ops.mesh.primitive_uv_sphere_add(
        segments=32, ring_count=20, location=position
    )
    obj = assign(bpy.context.object, name, mat)
    obj.scale = scale
    return obj


def cylinder(name, start, end, radius, mat):
    direction = Vector(end) - Vector(start)
    bpy.ops.mesh.primitive_cylinder_add(
        vertices=24, radius=radius, depth=direction.length,
        location=(Vector(start) + Vector(end)) / 2
    )
    obj = assign(bpy.context.object, name, mat)
    obj.rotation_euler = direction.to_track_quat("Z", "Y").to_euler()
    bevel = obj.modifiers.new("Soft edges", "BEVEL")
    bevel.width = radius * .28
    bevel.segments = 3
    return obj


def island(season):
    sphere("Floating island stone", (0, 0, -.18), (1.36, .97, .33),
           mats["ice" if season == "winter" else "rock"])
    sphere("Season ground", (0, 0, .045), (1.34, .96, .13),
           mats["snow" if season == "winter" else "grass"])
    for x, y in [(-.78, .55), (.88, .15), (.25, .66)]:
        sphere("Island rim stone", (x, y, -.06), (.26, .22, .20),
               mats["ice" if season == "winter" else "rock"])


def tree(position, season, small=False):
    x, y = position
    scale = .70 if small else 1
    cylinder("Tree trunk", (x, y, .09), (x, y, 1.65 * scale),
             .085 * scale, mats["bark"])
    for dx, dy, dz in [(-.42, .02, 1.50), (.36, .04, 1.62),
                       (.13, .24, 1.86)]:
        cylinder("Branch", (x, y, .91 * scale),
                 (x + dx * scale, y + dy * scale, dz * scale),
                 .038 * scale, mats["bark"])
    if season == "winter":
        for dx, dy, dz in [(-.40, .01, 1.50), (.36, .03, 1.62)]:
            sphere("Snow on branch",
                   (x + dx * scale, y + dy * scale, dz * scale),
                   (.20 * scale, .075 * scale, .045 * scale),
                   mats["snow"])
        return
    for i, (dx, dy, z, s) in enumerate([
        (-.32, 0, 1.64, .48), (.25, .02, 1.83, .51),
        (.01, .22, 2.02, .42), (0, -.16, 1.96, .45)
    ]):
        mat = mats[season]
        if season == "spring" and i % 2:
            mat = mats["pink_light"]
        if season == "autumn" and i % 2:
            mat = mats["gold"]
        sphere("Season crown",
               (x + dx * scale, y + dy * scale, z * scale),
               (s * scale, s * .76 * scale, s * .77 * scale), mat)


def flower(position, petal):
    x, y = position
    cylinder("Flower stalk", (x, y, .09), (x, y, .29), .012,
             mats["summer"])
    for i in range(5):
        a = i * math.tau / 5
        sphere("Flower petal",
               (x + .073 * math.cos(a), y + .073 * math.sin(a), .31),
               (.052, .042, .026), petal)
    sphere("Flower centre", (x, y, .32), (.032, .032, .03),
           mats["yellow"])


for season in ["spring", "summer", "autumn", "winter"]:
    current = bpy.data.collections.new(f"Original {season} diorama")
    scene.collection.children.link(current)
    collections[season] = current
    island(season)
    tree((-.36, .23), season)
    if season != "winter":
        tree((.57, .35), season, small=True)
    if season == "spring":
        for point in [(-.83, -.37), (-.58, -.62), (.12, -.48),
                      (.45, -.55), (.91, -.1)]:
            flower(point, mats["pink_light"])
    elif season == "summer":
        for point in [(-.80, -.41), (.15, -.56), (.56, -.47)]:
            flower(point, mats["yellow"])
        sphere("Summer sun", (.84, .53, 2.35), (.25, .25, .25),
               mats["yellow"])
        for i in range(8):
            a = i * math.tau / 8
            start = (.84 + .32 * math.cos(a), .53,
                     2.35 + .32 * math.sin(a))
            end = (.84 + .42 * math.cos(a), .53,
                   2.35 + .42 * math.sin(a))
            cylinder("Sun ray", start, end, .024, mats["yellow"])
    elif season == "autumn":
        for i, (x, y) in enumerate([
            (-.83, -.34), (-.44, -.66), (.03, -.55), (.48, -.47),
            (.85, -.15), (-.77, .07), (.38, -.70)
        ]):
            leaf = sphere("Fallen autumn leaf", (x, y, .18),
                          (.15, .065, .016),
                          mats["autumn" if i % 2 else "gold"])
            leaf.rotation_euler.z = i * .8
        for x, y in [(.78, -.32), (.58, -.52)]:
            sphere("Autumn pumpkin", (x, y, .24), (.15, .13, .13),
                   mats["autumn"])
            cylinder("Pumpkin stem", (x, y, .33), (x + .01, y, .40),
                     .019, mats["bark"])
    else:
        x, y = .58, -.33
        sphere("Snowman base", (x, y, .39), (.29, .28, .29), mats["snow"])
        sphere("Snowman body", (x, y, .76), (.22, .21, .22), mats["snow"])
        sphere("Snowman head", (x, y, 1.05), (.17, .16, .17), mats["snow"])
        for dx in [-.063, .063]:
            sphere("Snowman eye", (x + dx, y - .144, 1.09),
                   (.022, .020, .022), mats["black"])
        bpy.ops.mesh.primitive_cone_add(
            vertices=24, radius1=.041, radius2=0, depth=.16,
            location=(x, y - .18, 1.03), rotation=(math.pi / 2, 0, 0)
        )
        assign(bpy.context.object, "Carrot nose", mats["carrot"])
        bpy.ops.mesh.primitive_torus_add(
            major_radius=.165, minor_radius=.045, major_segments=32,
            minor_segments=12, location=(x, y, .93)
        )
        assign(bpy.context.object, "Blue snowman scarf", mats["scarf"])
        cylinder("Snowman left arm", (x - .18, y, .77),
                 (x - .44, y - .01, .96), .026, mats["bark"])
        cylinder("Snowman right arm", (x + .18, y, .77),
                 (x + .41, y + .01, .94), .026, mats["bark"])
        for px, py in [(-.77, -.37), (-.12, -.54), (.31, .54)]:
            sphere("Snow mound", (px, py, .14), (.18, .14, .075),
                   mats["snow"])


def aim(obj, target):
    obj.rotation_euler = (Vector(target) - obj.location).to_track_quat(
        "-Z", "Y"
    ).to_euler()


for name, location, power, size, color in [
    ("Soft warm key", (-3, -4, 6), 700, 4, (1, .88, .76)),
    ("Cyan fill", (4, -2, 4), 420, 3, (.72, .87, 1)),
    ("Sky rim", (1, 3, 5), 800, 3, (.90, .95, 1)),
]:
    data = bpy.data.lights.new(name, "AREA")
    data.energy = power
    data.shape = "DISK"
    data.size = size
    data.color = color
    obj = bpy.data.objects.new(name, data)
    scene.collection.objects.link(obj)
    obj.location = location
    aim(obj, (0, 0, .8))
data = bpy.data.cameras.new("Offline season illustration camera")
camera = bpy.data.objects.new("Offline season illustration camera", data)
scene.collection.objects.link(camera)
camera.location = (3, -5.7, 3.6)
data.type = "ORTHO"
data.ortho_scale = 3.6
scene.camera = camera
aim(camera, (0, 0, 1))
for season, collection in collections.items():
    for other in collections.values():
        other.hide_render = other != collection
    scene.render.filepath = str(ASSETS / f"season_{season}.png")
    bpy.ops.render.render(write_still=True)
for collection in collections.values():
    collection.hide_render = False
bpy.ops.wm.save_as_mainfile(
    filepath=str(SOURCE / "learning_season_dioramas.blend"), compress=True
)
print("LUMO_OFFLINE_SEASONS_PASS: four original 512px PNGs and editable Blender source")
