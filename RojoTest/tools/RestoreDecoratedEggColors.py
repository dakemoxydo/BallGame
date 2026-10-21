import bpy, json, math
from pathlib import Path
from mathutils import Vector

out = Path(__file__).resolve().parents[1] / 'assets/imports/decorated-egg-colors'
out.mkdir(parents=True, exist_ok=True)
bpy.ops.import_scene.fbx(filepath=str(out.parent / 'DecoratedEggs15.fbx'))
report = []
def srgb(v):
    return 12.92*v if v <= 0.0031308 else 1.055*v**(1/2.4)-0.055
for obj in sorted((o for o in bpy.data.objects if o.type == 'MESH' and o.name[:2].isdigit()), key=lambda o:o.name):
    mesh = obj.data
    mesh.calc_loop_triangles()
    coords = [obj.matrix_world @ v.co for v in mesh.vertices]
    coords = [Vector((v.x, v.z, -v.y)) for v in coords]
    low = Vector(tuple(min(v[k] for v in coords) for k in range(3)))
    high = Vector(tuple(max(v[k] for v in coords) for k in range(3)))
    center = (low + high) / 2
    colors = []
    for mat in mesh.materials:
        color = mat.diffuse_color[:3]
        if mat.use_nodes:
            bsdf = next((n for n in mat.node_tree.nodes if n.type == 'BSDF_PRINCIPLED'), None)
            if bsdf: color = bsdf.inputs['Base Color'].default_value[:3]
        colors.append([round(srgb(c), 6) for c in color])
    data = {'name':obj.name,'size':list(high-low),'vertices':[[round(x,7) for x in v-center] for v in coords],
            'colors':colors,'materials':[m.name for m in mesh.materials],
            'triangles':[[*[i+1 for i in t.vertices], t.material_index+1] for t in mesh.loop_triangles]}
    path = out / (obj.name[:2]+'.json')
    path.write_text(json.dumps(data,separators=(',',':')),encoding='utf-8')
    report.append({'name':obj.name,'file':path.name,'triangles':len(mesh.loop_triangles),'materials':data['materials']})
(out/'manifest.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
print(json.dumps({'eggs':len(report),'triangles':sum(x['triangles'] for x in report),'output':str(out)}))

# A palette texture makes the material colours survive Studio's single-material import.
objects = sorted((o for o in bpy.data.objects if o.type == 'MESH' and o.name[:2].isdigit()), key=lambda o:o.name)
materials = sorted({m for o in objects for m in o.data.materials}, key=lambda m:m.name)
palette = bpy.data.images.new('DecoratedEggsOriginalPalette', width=256, height=256, alpha=True)
palette.colorspace_settings.name = 'Non-Color'
pixels = [0.0] * (256*256*4)
for y in range(256):
    for x in range(256):
        slot = (y//32)*8 + x//32
        m = materials[min(slot, len(materials)-1)]
        bsdf = next((n for n in m.node_tree.nodes if n.type=='BSDF_PRINCIPLED'), None) if m.use_nodes else None
        c = bsdf.inputs['Base Color'].default_value[:3] if bsdf else m.diffuse_color[:3]
        index = (y*256+x)*4
        pixels[index:index+4] = [srgb(v) for v in c]+[1.0]
palette.pixels.foreach_set(pixels)
palette.filepath_raw = str(out/'original-palette.png')
palette.file_format = 'PNG'
palette.save()
material = bpy.data.materials.new('Original Egg Colors')
material.use_nodes = True
bsdf = next(n for n in material.node_tree.nodes if n.type=='BSDF_PRINCIPLED')
texture = material.node_tree.nodes.new('ShaderNodeTexImage')
texture.image = palette
material.node_tree.links.new(texture.outputs['Color'],bsdf.inputs['Base Color'])
for obj in objects:
    old = list(obj.data.materials)
    uv = obj.data.uv_layers.active or obj.data.uv_layers.new(name='UVMap')
    for p in obj.data.polygons:
        i = materials.index(old[p.material_index])
        for loop in p.loop_indices: uv.data[loop].uv = ((i%8+0.5)/8,(i//8+0.5)/8)
        p.material_index = 0
    obj.data.materials.clear()
    obj.data.materials.append(material)
bpy.ops.object.select_all(action='DESELECT')
for obj in objects: obj.select_set(True)
bpy.context.view_layer.objects.active = objects[0]
fbx = out/'DecoratedEggs15-OriginalColors.fbx'
bpy.ops.export_scene.fbx(filepath=str(fbx),use_selection=True,object_types={'MESH'},axis_forward='-Z',axis_up='Y',apply_unit_scale=True,bake_anim=False,path_mode='COPY',embed_textures=True)
print(json.dumps({'coloredFBX':str(fbx),'bytes':fbx.stat().st_size}))
