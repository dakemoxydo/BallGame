"""Evaluate the 36 numbered pets without changing their source geometry."""
import bpy
import json
import math
import re
from pathlib import Path
from mathutils import Vector

output=Path(__file__).resolve().parents[1]/'assets'/'pets'/'pack36'
output.mkdir(parents=True, exist_ok=True)
collections=sorted((c for c in bpy.data.collections if re.match(r'^\d\d ', c.name)), key=lambda c:c.name)
assert len(collections)==36
graph=bpy.context.evaluated_depsgraph_get()
export_collection=bpy.data.collections.new('PetPack36Export_TEMP')
bpy.context.scene.collection.children.link(export_collection)
exports=[]
manifest=[]

def srgb(value):
    return 12.92*value if value<=0.0031308 else 1.055*max(value,0)**(1/2.4)-0.055

def material_color(material):
    if material and material.use_nodes:
        node=next((n for n in material.node_tree.nodes if n.type=='BSDF_PRINCIPLED'),None)
        if node:
            return tuple(node.inputs['Base Color'].default_value)
    return tuple(material.diffuse_color) if material else (1,1,1,1)

normal_image=next((i for i in bpy.data.images if i.packed_file),None)
if normal_image:
    (output/'pets-normal.png').write_bytes(normal_image.packed_file.data)
material=bpy.data.materials.new('PetPack36VertexColors_TEMP')
material.use_nodes=True
shader=material.node_tree.nodes.get('Principled BSDF')
color_node=material.node_tree.nodes.new('ShaderNodeVertexColor')
color_node.layer_name='PetColor'
material.node_tree.links.new(color_node.outputs['Color'],shader.inputs['Base Color'])
if normal_image:
    texture=material.node_tree.nodes.new('ShaderNodeTexImage')
    texture.image=normal_image
    normal=material.node_tree.nodes.new('ShaderNodeNormalMap')
    material.node_tree.links.new(texture.outputs['Color'],normal.inputs['Color'])
    material.node_tree.links.new(normal.outputs['Normal'],shader.inputs['Normal'])

for index,collection in enumerate(collections,1):
    vertices=[]
    faces=[]
    normals=[]
    uvs=[]
    colors=[]
    palette=[]
    palette_lookup={}
    face_colors=[]
    for source in collection.objects:
        if source.type!='MESH':
            continue
        evaluated=source.evaluated_get(graph)
        mesh=evaluated.to_mesh(preserve_all_data_layers=True,depsgraph=graph)
        mesh.calc_loop_triangles()
        offset=len(vertices)
        vertices.extend(tuple(source.matrix_world@v.co) for v in mesh.vertices)
        normal_matrix=source.matrix_world.to_3x3().inverted().transposed()
        active_uv=mesh.uv_layers.active
        for triangle in mesh.loop_triangles:
            mat=mesh.materials[triangle.material_index] if triangle.material_index<len(mesh.materials) else None
            color=material_color(mat)
            key=tuple(round(x,6) for x in color)
            if key not in palette_lookup:
                palette_lookup[key]=len(palette)+1
                palette.append([round(srgb(x),6) for x in color[:3]]+[color[3]])
            faces.append([offset+v+1 for v in triangle.vertices])
            face_colors.append(palette_lookup[key])
            for loop in triangle.loops:
                n=(normal_matrix@mesh.corner_normals[loop].vector).normalized()
                normals.append(tuple(n))
                uvs.append(tuple(active_uv.data[loop].uv) if active_uv else (0,0))
                colors.append(color)
        evaluated.to_mesh_clear()
    minimum=Vector(tuple(min(v[i] for v in vertices) for i in range(3)))
    maximum=Vector(tuple(max(v[i] for v in vertices) for i in range(3)))
    origin=Vector(((minimum.x+maximum.x)/2,(minimum.y+maximum.y)/2,minimum.z))
    vertices=[Vector(v)-origin for v in vertices]
    pet_id=re.sub(r'[^A-Za-z0-9]+','',collection.name[3:])
    data={
        'index':index,'name':collection.name[3:],'id':pet_id,
        'vertices':[[round(v.x,6),round(v.z,6),round(-v.y,6)] for v in vertices],
        'faces':faces,'colors':palette,'faceColors':face_colors,
        'normals':[[round(n[0],6),round(n[2],6),round(-n[1],6)] for n in normals],
        'uvs':[[round(u,6),round(v,6)] for u,v in uvs],
        'size':[maximum.x-minimum.x,maximum.z-minimum.z,maximum.y-minimum.y],
    }
    assert len(faces)<20000, f'{pet_id} exceeds triangle limit'
    (output/f'{index:02d}-{pet_id}.json').write_text(json.dumps(data,separators=(',',':')),encoding='utf-8')
    geometry=bpy.data.meshes.new(f'{index:02d}_{pet_id}_Geometry')
    geometry.from_pydata(vertices,[],[[v-1 for v in f] for f in faces])
    geometry.update()
    geometry.normals_split_custom_set(normals)
    uv=geometry.uv_layers.new(name='UVMap')
    uv.data.foreach_set('uv',[x for pair in uvs for x in pair])
    color=geometry.color_attributes.new(name='PetColor',type='FLOAT_COLOR',domain='CORNER')
    color.data.foreach_set('color',[x for rgba in colors for x in rgba])
    geometry.materials.append(material)
    obj=bpy.data.objects.new(f'{index:02d}_{pet_id}',geometry)
    export_collection.objects.link(obj)
    obj.location=((index-1)%6*5,(index-1)//6*5,0)
    exports.append(obj)
    manifest.append({'index':index,'id':pet_id,'name':data['name'],'vertices':len(vertices),'triangles':len(faces),'size':data['size']})

old_selected=list(bpy.context.selected_objects)
old_active=bpy.context.view_layer.objects.active
bpy.ops.object.select_all(action='DESELECT')
for obj in exports:
    obj.select_set(True)
bpy.context.view_layer.objects.active=exports[0]
bpy.ops.export_scene.fbx(filepath=str(output/'pets36.fbx'),use_selection=True,object_types={'MESH'},axis_forward='-Z',axis_up='Y',apply_unit_scale=True,bake_anim=False,path_mode='COPY',embed_textures=True,colors_type='SRGB')
(output/'manifest.json').write_text(json.dumps({'source':bpy.data.filepath,'pets':manifest,'normal':'pets-normal.png','fbx':'pets36.fbx'},ensure_ascii=False,indent=2),encoding='utf-8')
for obj in exports:
    mesh=obj.data
    bpy.data.objects.remove(obj,do_unlink=True)
    bpy.data.meshes.remove(mesh)
bpy.data.collections.remove(export_collection)
bpy.data.materials.remove(material)
for obj in old_selected:
    obj.select_set(True)
bpy.context.view_layer.objects.active=old_active
result={'pets':len(manifest),'triangles':sum(p['triangles'] for p in manifest),'maxTriangles':max(p['triangles'] for p in manifest),'fbx':str(output/'pets36.fbx'),'bytes':(output/'pets36.fbx').stat().st_size}
