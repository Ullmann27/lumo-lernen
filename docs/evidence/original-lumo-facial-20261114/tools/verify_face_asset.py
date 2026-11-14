"""Verify derived GLB provenance and curved lid interpolation against measured source.

This validates actual source/derived bytes and the original projected surface.
It is not an Android performance test, a facial landmark detector or proof of
mouth anatomy. Surface samples are vertices plus triangle centroids at 101
blink amounts; raster inspection remains a separate required evidence step.
"""
from __future__ import annotations
import argparse
import hashlib
import json
import struct
from pathlib import Path
import numpy as np


def glb(path: Path):
    raw = path.read_bytes()
    magic, version, length = struct.unpack_from('<III', raw)
    assert (magic, version, length) == (0x46546C67, 2, len(raw))
    json_size, kind = struct.unpack_from('<II', raw, 12)
    assert kind == 0x4E4F534A
    document = json.loads(raw[20:20 + json_size])
    binary_size, kind = struct.unpack_from('<II', raw, 20 + json_size)
    assert kind == 0x004E4942
    binary = raw[28 + json_size:]
    assert len(binary) == binary_size
    return raw, document, binary


def accessor(document, binary, index):
    a = document['accessors'][index]
    view = document['bufferViews'][a['bufferView']]
    dim = {'SCALAR': 1, 'VEC2': 2, 'VEC3': 3, 'VEC4': 4, 'MAT4': 16}[a['type']]
    dtype = {5126: '<f4', 5123: '<u2', 5125: '<u4'}[a['componentType']]
    assert 'byteStride' not in view
    return np.frombuffer(binary, dtype=dtype, count=a['count'] * dim,
                         offset=view.get('byteOffset', 0) + a.get('byteOffset', 0)).reshape(-1, dim)


def run(source: Path, derived: Path, surface: Path, curves: Path):
    src, original, original_bin = glb(source)
    dst, doc, binary = glb(derived)
    checks = {}
    checks['source_original_sha'] = hashlib.sha256(src).hexdigest() == '3559f700784bc1006905ee3aae01e8bcfbffb95b4f621f7430ce771ba0e3efd5'
    checks['all_original_binary_bytes_preserved'] = binary[:len(original_bin)] == original_bin
    checks['original_65_joint_skin_preserved'] = doc['skins'] == original['skins'] and len(doc['skins'][0]['joints']) == 65
    checks['nine_original_animation_definitions_preserved'] = doc['animations'] == original['animations'] and len(doc['animations']) == 9
    checks['original_material_and_textures_preserved'] = doc['materials'][:len(original['materials'])] == original['materials'] and doc['images'] == original['images'] and doc['textures'] == original['textures']
    for index, node in enumerate(original['nodes']):
        actual = dict(doc['nodes'][index])
        if 'children' in actual:
            actual['children'] = [n for n in actual['children'] if n < len(original['nodes'])]
        checks[f'original_node_{index}_unchanged'] = actual == node
    original_primitive = original['meshes'][0]['primitives'][0]
    primitive = doc['meshes'][0]['primitives'][0]
    checks['original_body_attributes_indices_material_preserved'] = all(primitive[k] == v for k, v in original_primitive.items())
    checks['neutral_morph_weights_zero'] = all(not any(mesh['weights']) for mesh in doc['meshes'])
    curve_bytes = curves.read_bytes()
    curve_blob = hashlib.sha1(f'blob {len(curve_bytes)}\0'.encode() + curve_bytes).hexdigest()
    # Exact published original six Studio body clips remain a separate module.
    checks['studio_six_clip_module_unchanged'] = curve_blob == '10b38ae0590626db40b24080e8a55edcb47ecf2b'
    mesh = doc['meshes'][1]
    checks['single_batched_lid_mesh_two_surfaces'] = len(doc['meshes']) == 2 and len(mesh['primitives']) == 2
    checks['eight_curved_lid_morphs'] = len(mesh['weights']) == 8
    for i, part in enumerate(mesh['primitives']):
        joints = accessor(doc, binary, part['attributes']['JOINTS_0'])
        weights = accessor(doc, binary, part['attributes']['WEIGHTS_0'])
        checks[f'lid_surface_{i}_fully_head_skinned'] = bool(np.all(joints[:, 0] == 6) and np.all(weights[:, 0] == 1) and not np.any(weights[:, 1:]))
    surface_data = np.load(surface)
    z = surface_data['z']
    xmin, xmax, ymin, ymax = surface_data['bounds']
    height, width = z.shape
    def sample(points):
        x = np.clip((points[:, 0] - xmin) / (xmax - xmin) * (width - 1), 0, width - 1)
        y = np.clip((ymax - points[:, 1]) / (ymax - ymin) * (height - 1), 0, height - 1)
        x0, y0 = x.astype(int), y.astype(int)
        x1, y1 = np.minimum(x0 + 1, width - 1), np.minimum(y0 + 1, height - 1)
        fx, fy = x - x0, y - y0
        return (z[y0, x0] * (1 - fx) + z[y0, x1] * fx) * (1 - fy) + (z[y1, x0] * (1 - fx) + z[y1, x1] * fx) * fy
    lid = mesh['primitives'][0]
    base = accessor(doc, binary, lid['attributes']['POSITION'])
    targets = [accessor(doc, binary, t['POSITION']) for t in lid['targets']]
    indices = accessor(doc, binary, lid['indices']).reshape(-1, 3)
    scans = []
    for amount in np.linspace(0, 1, 101):
        shape = base.copy()
        for index, delta in enumerate(targets):
            shape += delta * max(0, 1 - abs(amount * 4 - (index % 4 + 1)))
        points = np.concatenate([shape, shape[indices].mean(1)])
        clearance = points[:, 2] - sample(points)
        scans.append({'blink': float(amount), 'minimum_clearance_m': float(clearance.min()),
                      'penetrating_sample_count': int((clearance < 0).sum())})
    checks['all_101_vertex_and_centroid_scans_outside_measured_original'] = all(s['penetrating_sample_count'] == 0 for s in scans)
    return {'checks': checks, 'all_checks_passed': all(checks.values()),
            'original_sha256': hashlib.sha256(src).hexdigest(),
            'derived_sha256': hashlib.sha256(dst).hexdigest(), 'derived_bytes': len(dst),
            'studio_curve_gitblob': curve_blob, 'lid_interpolation_scans': scans,
            'minimum_sampled_clearance_m': min(s['minimum_clearance_m'] for s in scans),
            'scope': 'Exact asset and original-curve preservation; neutral projected surface samples, not device performance or phonemes.'}


def main():
    parser = argparse.ArgumentParser()
    for name in ('source', 'derived', 'surface', 'curves', 'out'):
        parser.add_argument('--' + name, type=Path, required=True)
    args = parser.parse_args()
    report = run(args.source, args.derived, args.surface, args.curves)
    args.out.write_text(json.dumps(report, indent=2) + '\n')
    print(json.dumps({k: v for k, v in report.items() if k != 'lid_interpolation_scans'}))
    raise SystemExit(0 if report['all_checks_passed'] else 1)

if __name__ == '__main__':
    main()
