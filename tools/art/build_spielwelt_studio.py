"""Build LUMO's original ten portal dioramas with Blender and transparent WebP.

Run with Blender 4.3 or newer:
  blender -b -t 4 --python tools/art/build_spielwelt_studio.py -- --output-root PATH

The output is actual Cycles rendering of editable geometry, not Android evidence.
No character mesh or third-party art is used. External Python needs Pillow for
lossless RGBA WebP encoding. Source scenes and GLB models accompany each render.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import math
from pathlib import Path
import shutil
import subprocess
import sys

import bpy
from mathutils import Vector


PALETTE = {
    "cream": "fff2d7", "navy": "243a56", "orange": "f18a42",
    "gold": "e7b74f", "yellow": "ffda63", "teal": "37aead",
    "blue": "3e83cf", "coral": "ee7079", "green": "72b66b",
    "purple": "9570c2", "wood": "986441", "sand": "edcb91",
}
MATS: dict = {}


def linear(hexadecimal):
    values = [int(hexadecimal[i:i + 2], 16) / 255 for i in (0, 2, 4)]
    return tuple(v / 12.92 if v <= 0.04045 else ((v + .055) / 1.055) ** 2.4 for v in values)


def material(name, hexadecimal, roughness=.33, metal=0.0):
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    color = (*linear(hexadecimal), 1.0)
    mat.diffuse_color = color
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = color
    bsdf.inputs["Roughness"].default_value = roughness
    bsdf.inputs["Metallic"].default_value = metal
    bsdf.inputs["Coat Weight"].default_value = .16 if metal < .5 else .05
    bsdf.inputs["Coat Roughness"].default_value = .28
    MATS[name] = mat
    return mat


def setup():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    MATS.clear()
    for name, value in PALETTE.items():
        material(name, value, .31 if name != "sand" else .7, .65 if name == "gold" else 0.0)


def assign(obj, name, mat, parent=None):
    obj.name = name
    obj.data.materials.clear()
    obj.data.materials.append(MATS[mat])
    if parent:
        obj.parent = parent
    return obj


def bevel(obj, width=.05, segments=3):
    if not width:
        return obj
    bpy.context.view_layer.objects.active = obj
    mod = obj.modifiers.new("Soft manufactured edges", "BEVEL")
    mod.width = width
    mod.segments = segments
    mod.harden_normals = True
    bpy.ops.object.modifier_apply(modifier=mod.name)
    normals = obj.modifiers.new("Stable corner normals", "WEIGHTED_NORMAL")
    normals.keep_sharp = True
    bpy.ops.object.modifier_apply(modifier=normals.name)
    return obj


def box(name, pos, size, mat, radius=.05, parent=None):
    bpy.ops.mesh.primitive_cube_add(size=1, location=pos)
    obj = assign(bpy.context.object, name, mat, parent)
    obj.scale = size
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    return bevel(obj, min(radius, min(size) * .35))


def sphere(name, pos, size, mat, parent=None):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=24, ring_count=12, radius=1, location=pos)
    obj = assign(bpy.context.object, name, mat, parent)
    obj.scale = size
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    for polygon in obj.data.polygons:
        polygon.use_smooth = True
    return obj


def cylinder(name, pos, radius, depth, mat, vertices=48, parent=None):
    bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=radius, depth=depth, location=pos)
    obj = assign(bpy.context.object, name, mat, parent)
    bevel(obj, min(.035, depth * .15))
    return obj


def torus(name, pos, radius, tube, mat, parent=None):
    bpy.ops.mesh.primitive_torus_add(major_segments=40, minor_segments=10,
                                   location=pos, major_radius=radius, minor_radius=tube)
    obj = assign(bpy.context.object, name, mat, parent)
    for polygon in obj.data.polygons:
        polygon.use_smooth = True
    return obj


def rod(name, start, end, radius, mat, parent=None):
    a, b = Vector(start), Vector(end)
    obj = cylinder(name, (a + b) * .5, radius, (b - a).length, mat, 16, parent)
    obj.rotation_mode = "QUATERNION"
    obj.rotation_quaternion = (b - a).to_track_quat("Z", "Y")
    return obj


def mesh_object(name, vertices, faces, mat, parent=None):
    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata(vertices, [], faces)
    mesh.update()
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.collection.objects.link(obj)
    assign(obj, name, mat, parent)
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    bpy.context.view_layer.objects.active = obj
    bpy.ops.object.mode_set(mode="EDIT")
    bpy.ops.mesh.select_all(action="SELECT")
    bpy.ops.mesh.normals_make_consistent(inside=False)
    bpy.ops.object.mode_set(mode="OBJECT")
    obj.select_set(False)
    return obj


def extrude_xy(name, points, z, depth, mat, parent=None, soft=.025):
    count = len(points)
    vertices = [(x, y, z - depth / 2) for x, y in points]
    vertices += [(x, y, z + depth / 2) for x, y in points]
    faces = [tuple(reversed(range(count))), tuple(range(count, count * 2))]
    faces += [(i, (i + 1) % count, (i + 1) % count + count, i + count) for i in range(count)]
    return bevel(mesh_object(name, vertices, faces, mat, parent), soft)


def star(name, pos, radius, mat, parent=None, depth=.08):
    points = []
    for i in range(10):
        angle = math.pi / 2 + i * math.pi / 5
        r = radius if i % 2 == 0 else radius * .46
        points.append((math.cos(angle) * r, math.sin(angle) * r))
    obj = extrude_xy(name, points, 0, depth, mat, parent, min(.025, radius * .08))
    obj.rotation_euler.x = math.pi / 2
    obj.location = pos
    return obj


def group(name, pos=(0, 0, 0), rotation=(0, 0, 0)):
    obj = bpy.data.objects.new(name, None)
    bpy.context.collection.objects.link(obj)
    obj.location = pos
    obj.rotation_euler = rotation
    return obj


def pedestal(color="teal", radius=1.55):
    cylinder("Floating beveled island", (0, 0, .13), radius, .24, color, 64)
    cylinder("Warm ivory deck", (0, 0, .265), radius * .94, .11, "cream", 64)
    torus("Fine metallic rim", (0, 0, .205), radius * .987, .025, "gold")


def card(name, pos, face="blue", lean=0.0, yaw=0.0, scale=1.0):
    root = group(name, pos, (0, lean, yaw))
    root.scale = (scale, scale, scale)
    box("Rounded card body", (0, 0, .88), (1.15, .14, 1.7), "cream", .1, root)
    box("Colored card face", (0, -.079, .88), (.99, .035, 1.53), face, .07, root)
    star("Raised star emblem", (0, -.114, .96), .33, "yellow", root)
    for x, z in [(-.34, .29), (.34, 1.47)]:
        sphere("Card corner jewel", (x, -.11, z), (.055, .025, .055), "cream", root)
    return root


def cards():
    pedestal("purple")
    card("Left coral card", (-.49, .30, .35), "coral", -.25, -.18)
    card("Right teal card", (.45, .28, .34), "teal", .25, .15)
    card("Hero blue card", (0, -.18, .34), "blue")


def memory():
    pedestal("coral")
    card("Matching left star card", (-.69, .02, .34), "teal", -.08, -.12, .95)
    card("Matching right star card", (.65, .11, .34), "teal", .08, .12, .95)
    for i in range(3):
        box("Face-down memory stack", (-.65 + i * .05, -.78, .39 + i * .075),
            (.76, .55, .07), "purple" if i % 2 == 0 else "cream", .035)


def roof(name, pos, width, depth, height, mat):
    x, y, z = pos
    verts = [(x - width / 2, y - depth / 2, z), (x + width / 2, y - depth / 2, z),
             (x, y - depth / 2, z + height), (x - width / 2, y + depth / 2, z),
             (x + width / 2, y + depth / 2, z), (x, y + depth / 2, z + height)]
    return bevel(mesh_object(name, verts, [(0, 2, 1), (3, 4, 5), (0, 1, 4, 3),
                                          (0, 3, 5, 2), (1, 2, 5, 4)], mat), .035)


def tree(pos, scale=1.0):
    x, y, z = pos
    cylinder("Rounded tree trunk", (x, y, z + .35 * scale), .095 * scale, .7 * scale, "wood", 16)
    for dx, dy, dz, s in [(-.19, 0, .82, .35), (.18, .06, .94, .4), (0, -.1, 1.17, .35)]:
        sphere("Sculpted tree crown", (x + dx * scale, y + dy * scale, z + dz * scale),
               (s * scale, s * scale, s * 1.03 * scale), "green")


def build():
    pedestal("green")
    box("Little ivory house", (-.35, .30, .85), (1.15, 1.0, 1.05), "cream", .06)
    roof("Terracotta pitched roof", (-.35, .3, 1.36), 1.39, 1.22, .60, "coral")
    box("Friendly turquoise door", (-.43, -.214, .70), (.30, .045, .59), "teal", .06)
    for x in (-.73, .03):
        box("Blue house window", (x, -.217, 1.02), (.24, .045, .27), "blue", .035)
        box("Window crossbar", (x, -.248, 1.02), (.20, .02, .025), "cream", .008)
    box("Tiny chimney", (.04, .51, 1.80), (.25, .25, .55), "wood", .03)
    box("Vegetable field", (.61, -.62, .38), (.77, .67, .12), "wood", .04)
    for row in range(3):
        for col in range(3):
            x, y = .36 + col * .24, -.83 + row * .22
            sphere("Carrot bed leaf", (x, y, .49), (.075, .075, .13), "green")
    tree((.85, .55, .32), .72)
    for i in range(4):
        box("Stepping stone", (-.43, -.49 - i * .20, .348), (.27, .13, .045), "sand", .025)


def puzzle_shape(sides):
    corners = [(-.5, -.5), (.5, -.5), (.5, .5), (-.5, .5)]
    out = []
    for i, (x, y) in enumerate(corners):
        ex, ey = corners[(i + 1) % 4]
        dx, dy = ex - x, ey - y
        nx, ny = dy, -dx
        out.append((x, y))
        kind = sides[i]
        if kind:
            r = .16
            out.append((x + dx * (.5 - r), y + dy * (.5 - r)))
            for step in range(1, 13):
                a = math.pi - step * math.pi / 12
                t = .5 + r * math.cos(a)
                offset = kind * r * math.sin(a)
                out.append((x + dx * t + nx * offset, y + dy * t + ny * offset))
    return out


def puzzle():
    pedestal("blue")
    specs = [(-.54, -.54, (0, 1, 1, 0), "orange", .47),
             (.54, -.54, (0, 0, -1, -1), "teal", .47),
             (-.54, .54, (-1, 1, 0, 0), "purple", .47),
             (.54, .54, (1, 0, 0, -1), "yellow", 1.01)]
    for x, y, sides, mat, z in specs:
        piece = extrude_xy("Sculpted interlocking puzzle piece", puzzle_shape(sides), 0, .23, mat, soft=.035)
        piece.location = (x, y, z)
        if mat == "yellow":
            piece.rotation_euler = (.05, -.15, .1)


def rhythm():
    pedestal("purple")
    cylinder("Enamel drum body", (-.25, -.2, .81), .65, .90, "blue")
    cylinder("Ivory drum skin", (-.25, -.2, 1.29), .66, .065, "cream")
    for z in (.40, 1.26):
        torus("Golden drum hoop", (-.25, -.2, z), .65, .045, "gold")
    for i in range(8):
        a = i * math.tau / 8
        x, y = -.25 + math.cos(a) * .66, -.2 + math.sin(a) * .66
        rod("Drum tuning rod", (x, y, .51), (x, y, 1.16), .022, "cream")
    for start, end in [((-.83, -.37, 1.44), (.35, .18, 1.60)),
                       ((.19, -.63, 1.44), (-.74, .27, 1.63))]:
        rod("Wooden drumstick", start, end, .032, "wood")
        sphere("Drumstick bead", end, (.065, .065, .065), "wood")
    rod("Cymbal stand", (.89, .3, .33), (.89, .3, 1.42), .035, "gold")
    sphere("Brushed golden cymbal", (.89, .3, 1.46), (.51, .51, .065), "gold")
    cylinder("Cymbal bell", (.89, .3, 1.52), .10, .11, "gold")
    for x, z in [(-.78, 1.88), (.15, 2.02)]:
        sphere("Music note oval", (x, .42, z), (.18, .085, .13), "teal")
        rod("Music note stem", (x + .12, .42, z), (x + .12, .42, z + .47), .034, "teal")
    rod("Connected note beam", (-.66, .42, 2.33), (.27, .42, 2.47), .055, "teal")


def connect_four():
    pedestal("blue")
    cell, hole, thickness = .305, .112, .19
    width, height = cell * 7, cell * 6
    vertices, faces = [], []
    segments = 24
    for row in range(6):
        for col in range(7):
            cx, cz = (col - 3) * cell, .63 + row * cell
            base = len(vertices)
            for y in (-thickness / 2, thickness / 2):
                for ring in (0, 1):
                    for i in range(segments):
                        a = i * math.tau / segments
                        co, si = math.cos(a), math.sin(a)
                        r = hole if ring else cell * .5 / max(abs(co), abs(si))
                        vertices.append((cx + co * r, y, cz + si * r))
            for i in range(segments):
                j = (i + 1) % segments
                faces.extend([(base + i, base + j, base + segments + j, base + segments + i),
                              (base + 2 * segments + i, base + 3 * segments + i,
                               base + 3 * segments + j, base + 2 * segments + j),
                              (base + segments + i, base + segments + j,
                               base + 3 * segments + j, base + 3 * segments + i)])
    mesh_object("Seven by six genuine open board", vertices, faces, "blue")
    for x in (-width / 2 - .065, width / 2 + .065):
        box("Rounded board upright", (x, 0, 1.41), (.15, .24, height + .24), "navy", .055)
        box("Stable board foot", (x, -.02, .42), (.32, .75, .16), "navy", .06)
    for z in (.63 - cell / 2 - .045, .63 + 5 * cell + cell / 2 + .045):
        box("Rounded board rail", (0, 0, z), (width + .10, .23, .12), "blue", .04)
    played = [(0, 0, "yellow"), (1, 0, "coral"), (2, 0, "yellow"), (3, 0, "coral"),
              (4, 0, "yellow"), (5, 0, "coral"), (6, 0, "yellow"), (1, 1, "yellow"),
              (2, 1, "coral"), (3, 1, "yellow"), (4, 1, "coral"), (3, 2, "coral"),
              (4, 2, "yellow"), (4, 3, "coral")]
    for col, row, mat in played:
        obj = cylinder("Colored game disc", ((col - 3) * cell, -.012, .63 + row * cell), hole * .89, .13, mat, 32)
        obj.rotation_euler.x = math.pi / 2
    for i in range(3):
        cylinder("Spare golden counter", (.78, -.66, .38 + i * .065), .15, .065, "yellow", 32)


def treasure():
    pedestal("sand")
    box("Treasure chest body", (0, .08, .78), (1.78, 1.14, .84), "wood", .10)
    box("Dark open interior", (0, .08, 1.215), (1.47, .89, .045), "navy", .045)
    for x in (-.69, .69):
        box("Chest brass band", (x, -.505, .79), (.10, .05, .74), "gold", .02)
    lid = group("Open rounded chest lid", (0, .60, 1.15), (math.radians(-30), 0, 0))
    box("Lid wood shell", (0, 0, .49), (1.84, .22, 1.02), "wood", .12, lid)
    box("Lid warm inset", (0, -.131, .49), (1.55, .04, .72), "sand", .07, lid)
    for x in (-.69, .69):
        box("Lid brass band", (x, -.15, .49), (.10, .05, .94), "gold", .02, lid)
    box("Chest latch", (0, -.553, .86), (.23, .08, .31), "gold", .035)
    # Separate surfaces avoid the black reflection wedges of intersecting coins.
    for row in range(3):
        for column in range(4):
            cylinder("Gold treasure coin", (-.48 + column * .32, -.18 + row * .29,
                                            1.25 + row * .025), .14, .055, "gold", 24)
    for level in range(3):
        cylinder("Stacked gold treasure coin", (-.48, .11, 1.335 + level * .060),
                 .14, .055, "gold", 24)
    sphere("Turquoise jewel", (.35, -.10, 1.45), (.18, .14, .18), "teal")
    star("Treasure discovery star", (-.65, -.15, 2.25), .29, "yellow")
    for i in range(3):
        cylinder("Spilled coin", (.76 + .13 * i, -.73, .36 + .035 * i), .14, .055, "gold", 24)


def lathe(name, profile, mat, steps=64):
    vertices = []
    for radius, z in profile:
        for i in range(steps):
            a = i * math.tau / steps
            vertices.append((math.cos(a) * radius, math.sin(a) * radius, z))
    faces = []
    for row in range(len(profile) - 1):
        for i in range(steps):
            j = (i + 1) % steps
            faces.append((row * steps + i, row * steps + j, (row + 1) * steps + j, (row + 1) * steps + i))
    obj = mesh_object(name, vertices, faces, mat)
    for face in obj.data.polygons:
        face.use_smooth = True
    return obj


def quiz_show():
    pedestal("purple")
    box("Trophy marble plinth", (0, 0, .52), (1.2, .9, .38), "navy", .08)
    box("Trophy golden plaque", (0, -.46, .53), (.62, .035, .18), "gold", .025)
    cylinder("Trophy round foot", (0, 0, .76), .46, .13, "gold")
    lathe("Sculpted golden trophy", [(0, .79), (.17, .79), (.14, 1.02), (.23, 1.11),
                                   (.42, 1.26), (.61, 1.55), (.68, 1.86), (.64, 1.90),
                                   (.59, 1.84), (.52, 1.57), (.33, 1.36), (0, 1.28)], "gold")
    for side in (-1, 1):
        handle = torus("Curved trophy handle", (side * .63, .02, 1.50), .34, .075, "gold")
        handle.rotation_euler.x = math.pi / 2
    star("Trophy emblem", (0, -.59, 1.57), .22, "cream")
    star("Winner floating star", (0, .02, 2.38), .39, "yellow", depth=.14)


def kart():
    pedestal("orange")
    chassis = group("Original toy kart", (0, 0, .4), (0, 0, -.18))
    box("Low aerodynamic chassis", (0, 0, .37), (1.32, 1.96, .30), "teal", .13, chassis)
    box("Orange front bonnet", (0, -.52, .59), (1.10, .91, .36), "orange", .16, chassis)
    box("Ivory racing stripe", (0, -.51, .787), (.19, .83, .025), "cream", .01, chassis)
    box("Bucket seat cushion", (0, .32, .63), (.63, .65, .17), "navy", .07, chassis)
    back = box("Bucket seat back", (0, .62, .94), (.72, .18, .69), "navy", .08, chassis)
    back.rotation_euler.x = -.15
    for x in (-.78, .78):
        for y in (-.60, .62):
            wheel = cylinder("Soft rubber kart tyre", (x, y, .35), .34, .27, "navy", 40, chassis)
            wheel.rotation_euler.y = math.pi / 2
            rim = cylinder("Bright wheel rim", (x + math.copysign(.145, x), y, .35), .20, .035, "cream", 32, chassis)
            rim.rotation_euler.y = math.pi / 2
            hub = cylinder("Teal wheel hub", (x + math.copysign(.17, x), y, .35), .075, .04, "teal", 24, chassis)
            hub.rotation_euler.y = math.pi / 2
    rod("Steering column", (0, -.03, .5), (0, -.13, 1.03), .045, "navy", chassis)
    wheel = torus("Round steering wheel", (0, -.13, 1.05), .22, .045, "navy", chassis)
    wheel.rotation_euler.x = .42
    for x in (-.46, .46):
        box("Kart headlight", (x, -1.003, .57), (.24, .07, .13), "cream", .045, chassis)
        rod("Rear wing strut", (x, .77, .46), (x, .77, 1.04), .035, "navy", chassis)
    box("Swept rear spoiler", (0, .79, 1.07), (1.51, .31, .11), "orange", .045, chassis)


def jump_run():
    pedestal("teal")
    for x, y, z, radius in [(-.72, -.28, .64, .59), (.55, .45, 1.17, .62), (-.58, .80, 1.67, .38)]:
        cylinder("Floating island earth", (x, y, z), radius, .35, "wood", 24)
        cylinder("Floating island turf", (x, y, z + .20), radius * 1.04, .13, "green", 32)
        for i in range(4):
            a = i * math.tau / 4
            sphere("Rounded island rock", (x + math.cos(a) * radius * .6, y + math.sin(a) * radius * .6,
                                           z - .20), (.16, .15, .20), "sand")
    start, end = Vector((-.54, -.13, .93)), Vector((.40, .30, 1.46))
    for i in range(7):
        t = i / 6
        p = start.lerp(end, t)
        plank = box("Little suspended bridge plank", p, (.37, .14, .07), "cream", .025)
        plank.rotation_euler.z = -.65
    star("Floating adventure star", (.55, .44, 2.18), .41, "yellow", depth=.14)
    tree((-.64, .80, 1.88), .34)


BUILDERS = {
    "kart": kart, "cards": cards, "build": build, "puzzle": puzzle,
    "memory": memory, "jumpRun": jump_run, "rhythm": rhythm,
    "treasure": treasure, "connectFour": connect_four, "quizShow": quiz_show,
}


def consolidate():
    bpy.context.view_layer.update()
    # Preserve world transforms while removing authoring groups before batching.
    for obj in list(bpy.context.scene.objects):
        if obj.type == "MESH" and obj.parent is not None:
            transform = obj.matrix_world.copy()
            obj.parent = None
            obj.matrix_world = transform
    for mat in list(MATS.values()):
        meshes = [o for o in bpy.context.scene.objects if o.type == "MESH" and o.active_material == mat]
        if not meshes:
            continue
        bpy.ops.object.select_all(action="DESELECT")
        for obj in meshes:
            obj.select_set(True)
        bpy.context.view_layer.objects.active = meshes[0]
        bpy.ops.object.join()
        obj = bpy.context.object
        obj.name = "Lumo_" + mat.name
        bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    for obj in list(bpy.context.scene.objects):
        if obj.type == "EMPTY":
            bpy.data.objects.remove(obj, do_unlink=True)
    bpy.ops.object.select_all(action="DESELECT")


def lights_and_camera(size, samples):
    scene = bpy.context.scene
    bpy.ops.object.camera_add(location=(5.8, -8.8, 6.5))
    camera = bpy.context.object
    camera.name = "Portal studio orthographic camera"
    camera.rotation_euler = (Vector((0, 0, 1.07)) - camera.location).to_track_quat("-Z", "Y").to_euler()
    camera.data.type = "ORTHO"
    camera.data.ortho_scale = 4.3
    scene.camera = camera
    for name, pos, energy, color, light_size in [
        ("Warm key softbox", (-3.8, -4.7, 7.2), 600, (1, .88, .72), 5.0),
        ("Cool broad fill", (4.8, -1.3, 4.6), 440, (.72, .87, 1), 4.0),
        ("Cream rim softbox", (0, 5, 5.8), 780, (1, .94, .78), 3.8),
    ]:
        bpy.ops.object.light_add(type="AREA", location=pos)
        lamp = bpy.context.object
        lamp.name = name
        lamp.data.energy = energy
        lamp.data.color = color
        lamp.data.shape = "DISK"
        lamp.data.size = light_size
        lamp.rotation_euler = (Vector((0, 0, .8)) - lamp.location).to_track_quat("-Z", "Y").to_euler()
    scene.world = bpy.data.worlds.new("Soft neutral studio world")
    scene.world.use_nodes = True
    scene.world.node_tree.nodes["Background"].inputs[0].default_value = (.24, .30, .37, 1)
    scene.world.node_tree.nodes["Background"].inputs[1].default_value = .35
    scene.render.engine = "CYCLES"
    scene.cycles.device = "CPU"
    scene.cycles.samples = samples
    # Distribution builds can omit OpenImageDenoise; do not fail after rendering.
    scene.cycles.use_denoising = bool(getattr(bpy.app.build_options, "openimagedenoise", False))
    scene.cycles.max_bounces = 6
    scene.cycles.diffuse_bounces = 3
    scene.cycles.glossy_bounces = 3
    scene.render.resolution_x = size
    scene.render.resolution_y = size
    scene.render.resolution_percentage = 100
    scene.render.film_transparent = True
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGBA"
    scene.view_settings.view_transform = "AgX"


def mesh_stats():
    meshes = [o for o in bpy.context.scene.objects if o.type == "MESH"]
    triangles = 0
    for obj in meshes:
        obj.data.calc_loop_triangles()
        triangles += len(obj.data.loop_triangles)
    return {"mesh_nodes": len(meshes), "surfaces": sum(len(o.data.materials) for o in meshes),
            "triangles": triangles}


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def render_one(identity, args):
    setup()
    BUILDERS[identity]()
    consolidate()
    stats = mesh_stats()
    source = args.source_root / identity
    source.mkdir(parents=True, exist_ok=True)
    glb = source / (identity + ".glb")
    bpy.ops.export_scene.gltf(filepath=str(glb), export_format="GLB", export_animations=False,
                             export_cameras=False, export_lights=False, export_extras=True)
    lights_and_camera(args.size, args.samples)
    blend = source / (identity + ".blend")
    bpy.ops.wm.save_as_mainfile(filepath=str(blend), compress=True)
    png = source / (identity + ".png")
    bpy.context.scene.render.filepath = str(png)
    bpy.ops.render.render(write_still=True)
    target = args.output_root / (identity + ".webp")
    subprocess.run([args.python, "-c",
        "from PIL import Image; import sys; im=Image.open(sys.argv[1]).convert('RGBA'); "
        "im.save(sys.argv[2],format='WEBP',lossless=True,method=6,exact=True)",
        str(png), str(target)], check=True)
    receipt = {"id": identity, "tool": "Blender " + bpy.app.version_string,
               "renderer": "Cycles CPU", "samples": args.samples, "dimensions": [args.size, args.size],
               "transparent_background": True, "original_scripted_geometry": True,
               "character_assets_used": False, "file": target.name, "bytes": target.stat().st_size,
               "sha256": digest(target), "png_sha256": digest(png), "blend_sha256": digest(blend),
               "glb_sha256": digest(glb), **stats}
    (source / "receipt.json").write_text(json.dumps(receipt, indent=2) + "\n")
    print("LUMO_STUDIO_PORTAL " + json.dumps(receipt), flush=True)
    return receipt


def main():
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    root = Path(__file__).resolve().parents[2]
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output-root", type=Path, default=root / "assets/lumo_design/spielwelt/studio")
    parser.add_argument("--source-root", type=Path, default=root / "docs/design/spielwelt-studio-20261114")
    parser.add_argument("--ids", nargs="+", choices=list(BUILDERS), default=list(BUILDERS))
    parser.add_argument("--size", type=int, default=512)
    parser.add_argument("--samples", type=int, default=256)
    parser.add_argument("--python", default=shutil.which("python") or "python3")
    args = parser.parse_args(argv)
    if args.size < 256 or args.samples < 8:
        parser.error("Production images require at least 256 pixels and 8 samples")
    args.output_root = args.output_root.resolve()
    args.source_root = args.source_root.resolve()
    args.output_root.mkdir(parents=True, exist_ok=True)
    args.source_root.mkdir(parents=True, exist_ok=True)
    manifest_path = args.source_root / "render_manifest.json"
    previous = {}
    if manifest_path.exists():
        for receipt in json.loads(manifest_path.read_text()).get("renders", []):
            identity = receipt.get("id")
            target = args.output_root / (str(identity) + ".webp")
            if identity in BUILDERS and target.is_file() and digest(target) == receipt.get("sha256"):
                previous[identity] = receipt
    for identity in args.ids:
        previous[identity] = render_one(identity, args)
    receipts = [previous[identity] for identity in BUILDERS if identity in previous]
    manifest_path.write_text(json.dumps({
        "schema": 1, "source": "Original LUMO Blender geometry", "renders": receipts,
        "evidence_scope": "Asset renders; physical Android performance is not measured"
    }, indent=2) + "\n")
    print("LUMO_STUDIO_ALL_RENDERED " + str(len(receipts)), flush=True)


if __name__ == "__main__":
    main()
