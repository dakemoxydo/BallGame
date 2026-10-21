"""Remove texture-upload dependency by encoding colors in the FBX mesh."""
import bpy,os,json
ROOT=os.path.dirname(os.path.abspath(__file__))
OUT=r'C:\Users\userr\Documents\RobloxBalls_VertexColor'
os.makedirs(OUT,exist_ok=True)
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.fbx(filepath=os.path.join(ROOT,'roblox-import-v2','roblox-balls-10.fbx'))
scene=bpy.context.scene
records=[]
for obj in list(scene.objects):
    if obj.type!='MESH':continue
    data=obj.data;material=data.materials[0]
    image=next(n.image for n in material.node_tree.nodes if n.type=='TEX_IMAGE' and n.image)
    pixels=list(image.pixels);width,height=image.size;uv=data.uv_layers.active
    layer=data.color_attributes.new(name='Col',type='BYTE_COLOR',domain='CORNER')
    for loop in data.loops:
        point=uv.data[loop.index].uv
        x=min(width-1,max(0,int(point.x*width)));y=min(height-1,max(0,int(point.y*height)))
        index=(y*width+x)*4
        layer.data[loop.index].color_srgb=(*pixels[index:index+3],1)
    data.color_attributes.active_color=layer
    data.color_attributes.render_color_index=data.color_attributes.find(layer.name)
    white=bpy.data.materials.new(obj.name+'_VertexColor');white.use_nodes=True;white.diffuse_color=(1,1,1,1)
    shader=white.node_tree.nodes.get('Principled BSDF');shader.inputs['Base Color'].default_value=(1,1,1,1)
    shader.inputs['Roughness'].default_value=.7
    vertex=white.node_tree.nodes.new('ShaderNodeVertexColor');vertex.layer_name='Col'
    white.node_tree.links.new(vertex.outputs['Color'],shader.inputs['Base Color'])
    data.materials.clear();data.materials.append(white)
    records.append({'mesh':obj.name,'colors':len(set(tuple(round(c,2) for c in q.color_srgb[:3]) for q in layer.data))})
bpy.ops.object.select_all(action='SELECT')
path=os.path.join(OUT,'AllBalls_NoTextures.fbx')
bpy.ops.export_scene.fbx(filepath=path,use_selection=True,object_types={'MESH','EMPTY'},
    apply_unit_scale=False,axis_forward='-Z',axis_up='Y',path_mode='STRIP',
    embed_textures=False,bake_anim=False,use_triangles=True,add_leaf_bones=False,colors_type='SRGB')
# Round-trip the actual exported file and ensure every mesh retains color data.
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.fbx(filepath=path)
meshes=[o for o in bpy.context.scene.objects if o.type=='MESH']
assert len(meshes)==14
for obj in meshes:
    assert obj.data.color_attributes,obj.name
    assert not any(n.type=='TEX_IMAGE' for m in obj.data.materials if m and m.use_nodes for n in m.node_tree.nodes),obj.name
    obj.data.calc_loop_triangles();assert len(obj.data.loop_triangles)<=10000
result={'file':path,'meshes':len(meshes),'image_textures':0,'color_attributes_verified':True,'details':records}
with open(os.path.join(OUT,'validation.json'),'w') as f:json.dump(result,f,indent=2)
print(json.dumps(result))
