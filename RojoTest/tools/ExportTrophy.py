import bpy
import json
from pathlib import Path
from mathutils import Vector, Matrix

out = Path(__file__).resolve().parents[1] / 'assets' / 'trophy'
out.mkdir(parents=True, exist_ok=True)
objects = [o for o in bpy.context.scene.objects if o.type == 'MESH' and not o.hide_render and not o.name.startswith('Studio floor')]
points = [o.matrix_world @ v.co for o in objects for v in o.data.vertices]
lo = Vector([min(p[i] for p in points) for i in range(3)])
hi = Vector([max(p[i] for p in points) for i in range(3)])
base = Vector(((lo.x + hi.x) / 2, (lo.y + hi.y) / 2, lo.z))
factor = 8 / (hi.z - lo.z)
groups = {}
degenerate = 0
for obj in objects:
    mesh = obj.data
    mesh.calc_loop_triangles()
    normal_matrix = obj.matrix_world.to_3x3().inverted().transposed()
    for tri in mesh.loop_triangles:
        material = mesh.materials[tri.material_index]
        group = groups.setdefault(material.name, {'name': material.name, 'color': list(material.diffuse_color[:3]), 'vertices': [], 'triangles': [], 'normals': []})
        coords = [(obj.matrix_world @ mesh.vertices[i].co - base) * factor for i in tri.vertices]
        if (coords[1] - coords[0]).cross(coords[2] - coords[0]).length < 1e-8:
            degenerate += 1
            continue
        start = len(group['vertices'])
        group['vertices'].extend([[round(p.x, 6), round(p.z, 6), round(-p.y, 6)] for p in coords])
        group['triangles'].append([start + 1, start + 2, start + 3])
        normals = []
        for loop in tri.loops:
            n = (normal_matrix @ mesh.corner_normals[loop].vector).normalized()
            normals.append([round(n.x, 6), round(n.z, 6), round(-n.y, 6)])
        group['normals'].append(normals)
data = {'source': str(bpy.data.filepath), 'height': 8, 'objects': len(objects), 'groups': list(groups.values()), 'degenerateExcluded': degenerate}
(out / 'trophy-geometry.json').write_text(json.dumps(data, separators=(',', ':')), encoding='utf-8')
bpy.ops.object.select_all(action='DESELECT')
transform = Matrix.Scale(factor, 4) @ Matrix.Translation(-base)
for obj in objects:
    obj.matrix_world = transform @ obj.matrix_world
    obj.select_set(True)
bpy.context.view_layer.objects.active = objects[0]
bpy.context.view_layer.update()
bpy.ops.export_scene.fbx(filepath=str(out / 'golden-trophy.fbx'), use_selection=True, object_types={'MESH'}, axis_forward='-Z', axis_up='Y', apply_unit_scale=True, bake_anim=False, path_mode='COPY', embed_textures=True)
summary = {'source': data['source'], 'objects': len(objects), 'heightStuds': 8, 'triangles': sum(len(g['triangles']) for g in groups.values()), 'materialGroups': list(groups), 'degenerateExcluded': degenerate}
(out / 'manifest.json').write_text(json.dumps(summary, indent=2), encoding='utf-8')
print(json.dumps(summary))
