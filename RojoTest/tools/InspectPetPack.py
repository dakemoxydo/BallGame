import bpy
import json
from pathlib import Path
from mathutils import Vector

output = Path(__file__).resolve().parents[1] / 'assets' / 'pets' / 'pack36'
output.mkdir(parents=True, exist_ok=True)
objects = []
for obj in bpy.context.scene.objects:
    points = [obj.matrix_world @ Vector(v) for v in obj.bound_box]
    objects.append({
        'name': obj.name, 'type': obj.type,
        'parent': obj.parent.name if obj.parent else None,
        'collections': [c.name for c in obj.users_collection],
        'position': list(obj.matrix_world.translation),
        'dimensions': list(obj.dimensions),
        'bounds': [[min(v[i] for v in points) for i in range(3)], [max(v[i] for v in points) for i in range(3)]],
        'vertices': len(obj.data.vertices) if obj.type == 'MESH' else 0,
        'triangles': sum(len(p.vertices)-2 for p in obj.data.polygons) if obj.type == 'MESH' else 0,
        'materials': [m.name if m else None for m in obj.data.materials] if obj.type == 'MESH' else [],
        'modifiers': [{'name': m.name, 'type': m.type} for m in obj.modifiers],
        'hidden': obj.hide_render,
    })
summary = {
    'source': bpy.data.filepath, 'blender': bpy.app.version_string,
    'units': bpy.context.scene.unit_settings.system,
    'objects': objects,
    'collections': [{'name': c.name, 'objects': len(c.objects), 'children': [x.name for x in c.children]} for c in bpy.data.collections],
    'images': [{'name': i.name, 'path': i.filepath, 'packed': bool(i.packed_file)} for i in bpy.data.images],
    'materials': [{'name': m.name, 'color': list(m.diffuse_color), 'nodes': [n.type for n in m.node_tree.nodes] if m.use_nodes else []} for m in bpy.data.materials],
}
(output / 'inspection.json').write_text(json.dumps(summary, ensure_ascii=False, indent=2), encoding='utf-8')
print(json.dumps({'objects': len(objects), 'meshes': sum(o['type']=='MESH' for o in objects), 'collections': summary['collections'], 'images': summary['images']}, ensure_ascii=False))
