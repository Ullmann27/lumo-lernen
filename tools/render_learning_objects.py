"""Render two original, locally modelled quantity illustrations with Blender.

No external generator, API, user image modification or paid modelling service.
The small transparent PNGs are used by Flutter; the editable source is retained.
Run: blender --background --threads 4 --python tools/render_learning_objects.py
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
scene.render.image_settings.color_depth = "8"
scene.view_settings.view_transform = "AgX"
scene.world = bpy.data.worlds.new("Neutral studio")
scene.world.use_nodes = True
scene.world.node_tree.nodes["Background"].inputs[0].default_value = (
    .3, .38, .5, 1
)
scene.world.node_tree.nodes["Background"].inputs[1].default_value = .35


def material(name, color, roughness=.3, metallic=0):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = (*color, 1)
    bsdf.inputs["Roughness"].default_value = roughness
    bsdf.inputs["Metallic"].default_value = metallic
    return mat


def mesh(name, vertices, faces, mat, collection):
    data = bpy.data.meshes.new(name)
    data.from_pydata(vertices, [], faces)
    data.update()
    obj = bpy.data.objects.new(name, data)
    collection.objects.link(obj)
    obj.data.materials.append(mat)
    for polygon in obj.data.polygons:
        polygon.use_smooth = True
    return obj


def curve(name, points, radius, mat, collection):
    data = bpy.data.curves.new(name, "CURVE")
    data.dimensions = "3D"
    data.bevel_depth = radius
    data.bevel_resolution = 4
    spline = data.splines.new("BEZIER")
    spline.bezier_points.add(len(points) - 1)
    for point, position in zip(spline.bezier_points, points):
        point.co = position
        point.handle_left_type = "AUTO"
        point.handle_right_type = "AUTO"
    obj = bpy.data.objects.new(name, data)
    collection.objects.link(obj)
    obj.data.materials.append(mat)
    return obj


apple = bpy.data.collections.new("Original red apple")
candy = bpy.data.collections.new("Original blue gold candy")
scene.collection.children.link(apple)
scene.collection.children.link(candy)
red = material("Glossy red apple skin", (.64, .018, .032), .27)
nodes = red.node_tree.nodes
noise = nodes.new("ShaderNodeTexNoise")
noise.inputs["Scale"].default_value = 4
ramp = nodes.new("ShaderNodeValToRGB")
ramp.color_ramp.elements[0].color = (.28, .006, .012, 1)
ramp.color_ramp.elements[1].color = (.8, .035, .045, 1)
red.node_tree.links.new(noise.outputs["Fac"], ramp.inputs[0])
red.node_tree.links.new(ramp.outputs["Color"],
                       nodes["Principled BSDF"].inputs["Base Color"])
nodes["Principled BSDF"].inputs["Subsurface Weight"].default_value = .04
stem_mat = material("Natural stem", (.14, .064, .025), .55)
green = material("Leaf green", (.035, .25, .018), .4)
vein = material("Leaf vein", (.16, .36, .04), .5)
vertices = []
faces = []
segments = 64
rings = 48
for j in range(rings + 1):
    theta = math.pi * j / rings
    sine = math.sin(theta)
    cosine = math.cos(theta)
    for i in range(segments):
        phi = 2 * math.pi * i / segments
        radius = sine * (1 + .1 * cosine) * (
            1 + .045 * math.cos(5 * phi) * sine
        )
        z = .84 * cosine
        if cosine > 0:
            z -= .19 * math.exp(-(sine / .26) ** 2)
        else:
            z += .08 * math.exp(-(sine / .28) ** 2)
        vertices.append((radius * math.cos(phi),
                         radius * math.sin(phi), z))
for j in range(rings):
    for i in range(segments):
        n = (i + 1) % segments
        faces.append((j * segments + i, j * segments + n,
                      (j + 1) * segments + n, (j + 1) * segments + i))
mesh("Lobed apple body", vertices, faces, red, apple)
curve("Curved apple stem",
      [(0, 0, .64), (.035, .015, .9), (.12, .03, 1.12)],
      .047, stem_mat, apple)
leaf_vertices = []
for i in range(13):
    t = i / 12
    x = .04 + .65 * t
    z = .94 + .21 * math.sin(math.pi * t)
    w = .17 * math.sin(math.pi * t)
    leaf_vertices.extend([(x, .035 - w, z),
                          (x, .035, z + .038 * math.sin(math.pi * t)),
                          (x, .035 + w, z)])
leaf_faces = []
for i in range(12):
    for edge in range(2):
        leaf_faces.append((i * 3 + edge, (i + 1) * 3 + edge,
                           (i + 1) * 3 + edge + 1, i * 3 + edge + 1))
leaf = mesh("Folded leaf", leaf_vertices, leaf_faces, green, apple)
subdivision = leaf.modifiers.new("Soft leaf edges", "SUBSURF")
subdivision.levels = 2
solid = leaf.modifiers.new("Leaf thickness", "SOLIDIFY")
solid.thickness = .006
curve("Leaf centre vein",
      [(v[0], v[1], v[2] + .005) for v in leaf_vertices[1::3]],
      .008, vein, apple)

blue = material("Candy lacquer blue", (.015, .19, .56), .23, .16)
gold = material("Candy gold ribbon", (.83, .49, .10), .28, .55)
wrapper = material("Folded cyan wrapper", (.045, .38, .6), .3, .22)
bpy.ops.mesh.primitive_uv_sphere_add(segments=48, ring_count=32)
body = bpy.context.object
body.name = "Rounded blue candy"
body.scale = (.65, .29, .29)
for collection in list(body.users_collection):
    collection.objects.unlink(body)
candy.objects.link(body)
body.data.materials.append(blue)
for polygon in body.data.polygons:
    polygon.use_smooth = True
points = []
for i in range(100):
    x = -.59 + 1.18 * i / 99
    angle = 4 * math.pi * i / 99 + .4
    radius = .29 * math.sqrt(max(.05, 1 - (x / .65) ** 2))
    points.append((x, (radius + .011) * math.cos(angle),
                   (radius + .011) * math.sin(angle)))
curve("Gold candy spiral", points, .039, gold, candy)
for sign in (-1, 1):
    verts = []
    faces = []
    count = 32
    for row in range(4):
        t = row / 3
        x = sign * (.59 + .43 * t)
        base = .073 + .19 * t
        for i in range(count):
            angle = 2 * math.pi * i / count
            radius = base * (1 + .22 * math.cos(8 * angle) * t)
            verts.append((x, radius * math.cos(angle),
                          radius * math.sin(angle)))
    for row in range(3):
        for i in range(count):
            n = (i + 1) % count
            faces.append((row * count + i, row * count + n,
                          (row + 1) * count + n, (row + 1) * count + i))
    obj = mesh(f"Pleated wrapper {sign}", verts, faces, wrapper, candy)
    solid = obj.modifiers.new("Thin wrapper", "SOLIDIFY")
    solid.thickness = .01


def aim(obj, target):
    obj.rotation_euler = (Vector(target) - obj.location).to_track_quat(
        "-Z", "Y"
    ).to_euler()


for name, location, power, size, color in [
    ("Soft key", (-3.2, -4, 5), 550, 4, (1, .88, .76)),
    ("Cool fill", (3.5, -2, 2.3), 350, 3, (.72, .86, 1)),
    ("Clean rim", (1.5, 3, 4), 650, 3, (.9, .96, 1)),
]:
    data = bpy.data.lights.new(name, "AREA")
    data.energy = power
    data.shape = "DISK"
    data.size = size
    data.color = color
    obj = bpy.data.objects.new(name, data)
    scene.collection.objects.link(obj)
    obj.location = location
    aim(obj, (0, 0, .1))
camera_data = bpy.data.cameras.new("Quantity illustration camera")
camera = bpy.data.objects.new("Quantity illustration camera", camera_data)
scene.collection.objects.link(camera)
camera.location = (2.4, -5.0, 3.0)
camera_data.type = "ORTHO"
camera_data.ortho_scale = 2.7
scene.camera = camera
aim(camera, (0, 0, .1))
for collection, filename in [
    (apple, "apple_red.png"), (candy, "candy_blue.png")
]:
    apple.hide_render = collection != apple
    candy.hide_render = collection != candy
    scene.render.filepath = str(ASSETS / filename)
    bpy.ops.render.render(write_still=True)
apple.hide_render = False
candy.hide_render = True
bpy.ops.wm.save_as_mainfile(
    filepath=str(SOURCE / "learning_quantity_objects.blend"), compress=True
)
print("LUMO_LOCAL_QUANTITY_ART_PASS: two original 512px RGBA PNGs and editable Blender source")
