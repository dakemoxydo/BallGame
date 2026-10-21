"""Export the saved display as ten named Roblox assets with color textures."""
import bpy, bmesh, os, math, json
from mathutils import Matrix
OUT=os.path.join(os.path.dirname(os.path.abspath(__file__)),'roblox-import-v2')
os.makedirs(os.path.join(OUT,'textures'),exist_ok=True)
source_scene=bpy.data.scenes['RubberRookie_Display']
bpy.context.window.scene=source_scene
depsgraph=bpy.context.evaluated_depsgraph_get()
roots=sorted([o for o in source_scene.objects if o.name.startswith('Ball_')],key=lambda o:o.name)
assert len(roots)==10, 'Expected all ten ball roots.'
export_scene=bpy.data.scenes.new('Roblox_Balls_Export')
meshes=[];reports=[]

def srgb(value):
    return max(0,min(1,12.92*value if value<=.0031308 else 1.055*value**(1/2.4)-.055))
def base_color(mat):
    if mat and mat.use_nodes:
        shader=next((n for n in mat.node_tree.nodes if n.type=='BSDF_PRINCIPLED'),None)
        if shader:return tuple(shader.inputs['Base Color'].default_value[:3])
    return tuple(mat.diffuse_color[:3]) if mat else (.5,.5,.5)
def is_clear(o):
    for mat in o.data.materials:
        if not mat or not mat.use_nodes:continue
        shader=next((n for n in mat.node_tree.nodes if n.type=='BSDF_PRINCIPLED'),None)
        if shader and shader.inputs['Alpha'].default_value<.95:return True
    return False
def palette(name,materials):
    count=max(1,len(materials));side=math.ceil(math.sqrt(count));size=256;pixels=[]
    for y in range(size):
        row=min(side-1,int(y*side/size))
        for x in range(size):
            col=min(side-1,int(x*side/size));index=min(count-1,row*side+col)
            color=base_color(materials[index]) if materials else (.5,.5,.5)
            pixels.extend([*(srgb(c) for c in color),1])
    image=bpy.data.images.new(name+'_Colors',width=size,height=size,alpha=True)
    image.pixels.foreach_set(pixels)
    image.filepath_raw=os.path.join(OUT,'textures',name+'.png');image.file_format='PNG';image.save()
    return image,[( (i%side+.5)/side,(i//side+.5)/side) for i in range(count)]
def image_material(name,image):
    material=bpy.data.materials.new(name+'_RobloxColor');material.use_nodes=True
    shader=material.node_tree.nodes.get('Principled BSDF');shader.inputs['Roughness'].default_value=.7
    texture=material.node_tree.nodes.new('ShaderNodeTexImage');texture.image=image
    material.node_tree.links.new(texture.outputs['Color'],shader.inputs['Base Color'])
    return material

for index,root in enumerate(roots,1):
    sources=([root] if root.type=='MESH' else [])+[o for o in root.children_recursive if o.type=='MESH']
    assert sources,root.name
    anchor=bpy.data.objects.new(root.name,None);export_scene.collection.objects.link(anchor)
    anchor.matrix_world=root.matrix_world.copy()
    anchor['Tier']=index
    inv=root.matrix_world.inverted()
    opaque=[o for o in sources if not is_clear(o)];clear=[o for o in sources if is_clear(o)]
    groups=[(opaque,'Body'),(clear,'Shell')]
    if index==5:
        core=[o for o in opaque if o.name in ('Reactor_GlowingSphere','Reactor_FrontLens')]
        groups=[([o for o in opaque if o not in core],'Body'),(core,'Core'),(clear,'Shell')]
    if index==10:
        world=[o for o in opaque if o.name in ('WorldCreator_Planet','WorldCreator_Moon')]
        groups=[([o for o in opaque if o not in world],'Body'),(world,'World'),(clear,'Shell')]
    for group,suffix in groups:
        if not group:continue
        name=root.name+'_'+suffix
        material_list=[]
        for o in group:
            for mat in o.data.materials:
                if mat not in material_list:material_list.append(mat)
        textured_first=index==1
        if textured_first:
            original=bpy.data.images['RubberRookie_BaseColor']
            image=original.copy();image.filepath_raw=os.path.join(OUT,'textures',name+'.png')
            image.file_format='PNG';image.save();uv_centers=[]
        else:image,uv_centers=palette(name,material_list)
        material_names=[m.name if m else None for m in material_list]
        vertices=[];faces=[];uvs=[];smooth_faces=[]
        for source in group:
            evaluated=source.evaluated_get(depsgraph)
            data=evaluated.to_mesh(preserve_all_data_layers=True,depsgraph=depsgraph)
            transform=inv@source.matrix_world
            offset=len(vertices)
            vertices.extend(tuple(transform@v.co) for v in data.vertices)
            uv_layer=data.uv_layers.active
            for p in data.polygons:
                faces.append(tuple(offset+i for i in p.vertices))
                smooth_faces.append(p.use_smooth)
                source_mat=data.materials[p.material_index] if len(data.materials)>p.material_index else None
                material_name=source_mat.name if source_mat else None
                assert material_name in material_names,(name,material_name,material_names)
                material_index=material_names.index(material_name)
                for corner,loop in enumerate(p.loop_indices):
                    if textured_first and uv_layer:
                        uvs.append(tuple(uv_layer.data[loop].uv))
                    else:
                        # Give every polygon positive UV area inside its own color tile.
                        # Evaluated material IDs differ from original IDs; match by name.
                        center=uv_centers[material_index]
                        angle=2*math.pi*corner/len(p.loop_indices)
                        radius=.1/math.ceil(math.sqrt(max(1,len(material_list))))
                        uvs.append((center[0]+radius*math.cos(angle),center[1]+radius*math.sin(angle)))
            evaluated.to_mesh_clear()
        data=bpy.data.meshes.new(name+'_Mesh');data.from_pydata(vertices,[],faces);data.update()
        for p,smooth in zip(data.polygons,smooth_faces):p.use_smooth=smooth
        layer=data.uv_layers.new(name='RobloxUV')
        for i,uv in enumerate(uvs):layer.data[i].uv=uv
        bm=bmesh.new();bm.from_mesh(data);bmesh.ops.triangulate(bm,faces=list(bm.faces));bm.to_mesh(data);bm.free()
        obj=bpy.data.objects.new(name,data);export_scene.collection.objects.link(obj)
        obj.parent=anchor;obj.matrix_parent_inverse=Matrix.Identity(4);obj.matrix_basis=Matrix.Identity(4)
        data.materials.append(image_material(name,image))
        data.calc_loop_triangles();triangles=len(data.loop_triangles)
        assert triangles<=10000,(name,triangles)
        obj['RobloxTransparency']=.74 if suffix=='Shell' else 0
        meshes.append(obj)
        reports.append({'name':name,'triangles':triangles,'texture':'textures/'+name+'.png','transparency':.74 if suffix=='Shell' else 0})

bpy.context.window.scene=export_scene
bpy.ops.object.select_all(action='SELECT')
bpy.context.view_layer.objects.active=meshes[0]
fbx=os.path.join(OUT,'roblox-balls-10.fbx')
bpy.ops.export_scene.fbx(filepath=fbx,use_selection=True,object_types={'MESH','EMPTY'},
    apply_unit_scale=False,global_scale=1,axis_forward='-Z',axis_up='Y',
    path_mode='RELATIVE',embed_textures=False,bake_anim=False,use_triangles=True,add_leaf_bones=False)
result={'fbx':fbx,'balls':len(roots),'meshes':len(meshes),'assets':reports,'excluded':'Pedestals, floor, cameras, lights','source_unchanged':True}
with open(os.path.join(OUT,'manifest.json'),'w',encoding='utf-8') as f:json.dump(result,f,ensure_ascii=False,indent=2)
print('EXPORT_RESULT='+json.dumps(result,ensure_ascii=False))
