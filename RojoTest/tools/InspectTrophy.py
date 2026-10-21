import bpy
import json
from pathlib import Path

out = Path(__file__).resolve().parents[1] / 'assets' / 'trophy'
out.mkdir(parents=True, exist_ok=True)
objects = []
depsgraph = bpy.context.evaluated_depsgraph_get()
for obj in bpy.context.scene.objects:
    info = {'name': obj.name, 'type': obj.type, 'dimensions': list(obj.dimensions),
            'hidden_render': obj.hide_render, 'modifiers': [m.type for m in obj.modifiers]}
    if obj.type == 'MESH':
        evaluated = obj.evaluated_get(depsgraph)
        mesh = evaluated.to_mesh()
        mesh.calc_loop_triangles()
        info.update(vertices=len(mesh.vertices), triangles=len(mesh.loop_triangles),
                    materials=[{'name': m.name, 'color': list(m.diffuse_color),
                                'nodes': [n.type for n in m.node_tree.nodes] if m.use_nodes else []}
                               for m in mesh.materials if m])
        evaluated.to_mesh_clear()
    objects.append(info)
result = {'objects': objects, 'images': [{'name': i.name, 'path': i.filepath, 'packed': bool(i.packed_file)} for i in bpy.data.images]}
(out / 'inspection.json').write_text(json.dumps(result, ensure_ascii=False, indent=2), encoding='utf-8')
print(json.dumps(result, ensure_ascii=False))
