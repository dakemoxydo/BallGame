
import bpy
out=r'C:/Users/userr/OneDrive/Документы/PROJECTS/roblox/111/RojoTest/assets/fields/backyard'
scene=bpy.context.scene
source=bpy.data.images.load(out+'/studtexture.png',check_existing=True);source.pack()
assert source.size[0]==500
# Bake the transparent overlay over each surface tint, so FBX uses ordinary image materials.
# No displacement/bump and no geometry additions.
old_engine=scene.render.engine
scene.render.engine='CYCLES';scene.cycles.samples=1
bpy.ops.mesh.primitive_plane_add(size=2)
plane=bpy.context.object;plane.name='Temporary_Stud_Bake'
tints={0:(.34,.205,.105,1),1:(.24,.57,.08,1),2:(.29,.64,.10,1)}
mats={}
for index,color in tints.items():
 mat=bpy.data.materials.new('StudBake_'+str(index));mat.use_nodes=True
 nt=mat.node_tree;nt.nodes.clear()
 tex=nt.nodes.new('ShaderNodeTexImage');tex.image=source;tex.interpolation='Linear'
 multiply=nt.nodes.new('ShaderNodeMixRGB');multiply.blend_type='MULTIPLY';multiply.inputs[0].default_value=1
 multiply.inputs[1].default_value=color;nt.links.new(tex.outputs['Color'],multiply.inputs[2])
 mix=nt.nodes.new('ShaderNodeMixRGB');mix.inputs[1].default_value=color
 nt.links.new(tex.outputs['Alpha'],mix.inputs[0]);nt.links.new(multiply.outputs[0],mix.inputs[2])
 emission=nt.nodes.new('ShaderNodeEmission');nt.links.new(mix.outputs[0],emission.inputs[0])
 output=nt.nodes.new('ShaderNodeOutputMaterial');nt.links.new(emission.outputs[0],output.inputs['Surface'])
 image=bpy.data.images.new('Studs_'+str(index),width=500,height=500,alpha=False)
 target=nt.nodes.new('ShaderNodeTexImage');target.image=image;nt.nodes.active=target
 plane.data.materials.clear();plane.data.materials.append(mat)
 bpy.ops.object.select_all(action='DESELECT');plane.select_set(True);bpy.context.view_layer.objects.active=plane
 bpy.ops.object.bake(type='EMIT')
 image.filepath_raw=out+'/studs-tinted-'+str(index)+'.png';image.file_format='PNG';image.save();image.pack()
 final=bpy.data.materials.new('Backyard_Textured_'+str(index));final.use_nodes=True;final.diffuse_color=color
 bs=final.node_tree.nodes.get('Principled BSDF');bs.inputs['Roughness'].default_value=.82
 node=final.node_tree.nodes.new('ShaderNodeTexImage');node.image=image;node.extension='REPEAT'
 final.node_tree.links.new(node.outputs['Color'],bs.inputs['Base Color'])
 mats[index]=final
bpy.data.objects.remove(plane,do_unlink=True)
scene.render.engine=old_engine
for name in ['BF_Earth_Base','BF_Grass_Bed','BF_Grass_Stripes']:
 ob=bpy.data.objects[name];mesh=ob.data
 original=[p.material_index for p in mesh.polygons]
 mesh.materials.clear()
 for i in [0,1,2]:mesh.materials.append(mats[i])
 uv=mesh.uv_layers.active
 for p,index in zip(mesh.polygons,original):
  p.material_index=index
  normal=p.normal
  axis=max(range(3),key=lambda k:abs(normal[k]))
  axes=(0,1) if axis==2 else ((0,2) if axis==1 else (1,2))
  for li in p.loop_indices:
   v=mesh.vertices[mesh.loops[li].vertex_index].co
   uv.data[li].uv=(v[axes[0]]/2,v[axes[1]]/2)
 mesh.update()
def export(items,path):
 bpy.ops.object.select_all(action='DESELECT')
 for o in items:o.select_set(True)
 bpy.context.view_layer.objects.active=items[0]
 bpy.ops.export_scene.fbx(filepath=path,use_selection=True,object_types={'MESH'},apply_unit_scale=False,axis_forward='-Z',axis_up='Y',path_mode='COPY',embed_textures=True,add_leaf_bones=False)
field=list(bpy.data.collections['Backyard_Field_Asset'].objects);ball=bpy.data.objects['BF_Football']
export(field,out+'/backyard-field.fbx');export(field+[ball],out+'/backyard-field-with-ball.fbx')
bpy.ops.wm.save_as_mainfile(filepath=out+'/backyard-field.blend')
result={'textured':['BF_Earth_Base','BF_Grass_Bed','BF_Grass_Stripes'],'tile_world_size':2,'stud_spacing':.5,'mesh_count':len(field),'geometric_studs':bpy.data.objects.get('BF_Grass_Studs') is not None}

