import bpy
import json
from pathlib import Path

output = Path(__file__).resolve().parents[1] / 'assets/imports/DecoratedEggs15.fbx'
output.parent.mkdir(parents=True, exist_ok=True)
roots = sorted((o for o in bpy.context.scene.objects if o.type == 'EMPTY' and not o.parent), key=lambda o: o.name)
assert len(roots) == 15, 'Expected 15 egg groups'
models = []
for root in roots:
    bpy.ops.object.select_all(action='DESELECT')
    objects = [o for o in root.children_recursive if o.type in {'MESH', 'CURVE'} and not o.hide_render]
    assert objects, root.name
    for obj in objects:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = objects[0]
    bpy.ops.object.convert(target='MESH')
    bpy.context.view_layer.objects.active = next(iter(bpy.context.selected_objects))
    bpy.ops.object.join()
    mesh = bpy.context.object
    mesh.name = root.name
    world = mesh.matrix_world.copy()
    mesh.parent = None
    mesh.matrix_world = world
    mesh.data.calc_loop_triangles()
    models.append(mesh)
bpy.ops.object.select_all(action='DESELECT')
for mesh in models:
    mesh.select_set(True)
bpy.context.view_layer.objects.active = models[0]
bpy.ops.export_scene.fbx(filepath=str(output), use_selection=True, object_types={'MESH'}, axis_forward='-Z', axis_up='Y', apply_unit_scale=True, bake_anim=False, path_mode='COPY', embed_textures=True)
summary = [{'name':o.name, 'triangles':len(o.data.loop_triangles), 'materials':len(o.data.materials)} for o in models]
output.with_suffix('.json').write_text(json.dumps(summary, indent=2), encoding='utf-8')
print(json.dumps({'file':str(output), 'bytes':output.stat().st_size, 'models':summary}))
