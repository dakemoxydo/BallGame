import bpy
import json
import sys
from pathlib import Path
from mathutils import Vector

output = Path(sys.argv[sys.argv.index('--') + 1])
output.parent.mkdir(parents=True, exist_ok=True)
objects = [o for o in bpy.context.scene.objects
           if o.type in {'MESH', 'CURVE', 'FONT', 'SURFACE'} and not o.hide_render
           and not o.name.startswith('Studio floor')]
assert objects, 'No visible geometry found'
bpy.ops.object.select_all(action='DESELECT')
for obj in objects:
    obj.select_set(True)
bpy.context.view_layer.objects.active = objects[0]
bpy.ops.object.convert(target='MESH')
bpy.context.view_layer.update()
meshes = list(bpy.context.selected_objects)
if '--simple-materials' in sys.argv:
    replacements = {}
    for obj in meshes:
        for slot in obj.material_slots:
            original = slot.material
            if original is None:
                continue
            if original.name not in replacements:
                color = original.diffuse_color[:]
                if original.use_nodes:
                    shader = next((n for n in original.node_tree.nodes if n.type == 'BSDF_PRINCIPLED'), None)
                    if shader:
                        color = shader.inputs['Base Color'].default_value[:]
                material = bpy.data.materials.new('RobloxColor_' + str(len(replacements) + 1))
                material.diffuse_color = color
                material.use_nodes = True
                shader = material.node_tree.nodes.get('Principled BSDF')
                shader.inputs['Base Color'].default_value = color
                shader.inputs['Roughness'].default_value = 0.5
                replacements[original.name] = material
            slot.material = replacements[original.name]
points = [o.matrix_world @ Vector(v) for o in meshes for v in o.bound_box]
summary = {
    'source': bpy.data.filepath,
    'objects': len(meshes),
    'triangles': sum(sum(len(p.vertices) - 2 for p in o.data.polygons) for o in meshes),
    'bounds': [[min(p[i] for p in points) for i in range(3)],
               [max(p[i] for p in points) for i in range(3)]],
    'collections': [c.name for c in bpy.data.collections],
    'materials': sorted({m.name for o in meshes for m in o.data.materials if m}),
    'names': [o.name for o in meshes],
}
bpy.ops.export_scene.fbx(filepath=str(output), use_selection=True,
    object_types={'MESH'}, axis_forward='-Z', axis_up='Y',
    apply_unit_scale=True, bake_anim=False, path_mode='COPY', embed_textures=True)
summary['bytes'] = output.stat().st_size
output.with_suffix('.json').write_text(json.dumps(summary, ensure_ascii=False, indent=2), encoding='utf-8')
print(json.dumps({k: summary[k] for k in ['objects', 'triangles', 'bounds', 'bytes']}, ensure_ascii=False))
