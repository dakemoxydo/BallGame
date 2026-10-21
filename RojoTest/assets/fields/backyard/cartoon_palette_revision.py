
import bpy
out=r'C:/Users/userr/OneDrive/Документы/PROJECTS/roblox/111/RojoTest/assets/fields/backyard'
scene=bpy.context.scene
assert scene.name=='Backyard_Field_Reference'
# Restore green turf thickness independently from the brown earth foundation.
bed=bpy.data.objects['BF_Grass_Bed']
for p in bed.data.polygons:p.material_index=1
source=bpy.data.images.load(out+'/studtexture.png',check_existing=True)
tints={0:(.115,.033,.009,1),1:(.025,.50,.002,1),2:(.085,.82,.004,1)}
old_engine=scene.render.engine;scene.render.engine='CYCLES';scene.cycles.samples=1
bpy.ops.mesh.primitive_plane_add(size=2);plane=bpy.context.object
for index,color in tints.items():
 mat=bpy.data.materials.new('CartoonBake_'+str(index));mat.use_nodes=True
 nt=mat.node_tree;nt.nodes.clear()
 tex=nt.nodes.new('ShaderNodeTexImage');tex.image=source
 mult=nt.nodes.new('ShaderNodeMixRGB');mult.blend_type='MULTIPLY';mult.inputs[0].default_value=1;mult.inputs[1].default_value=color
 nt.links.new(tex.outputs['Color'],mult.inputs[2])
 mix=nt.nodes.new('ShaderNodeMixRGB');mix.inputs[1].default_value=color
 nt.links.new(tex.outputs['Alpha'],mix.inputs[0]);nt.links.new(mult.outputs[0],mix.inputs[2])
 emission=nt.nodes.new('ShaderNodeEmission');nt.links.new(mix.outputs[0],emission.inputs[0])
 output=nt.nodes.new('ShaderNodeOutputMaterial');nt.links.new(emission.outputs[0],output.inputs[0])
 image=bpy.data.images['Studs_'+str(index)]
 target=nt.nodes.new('ShaderNodeTexImage');target.image=image;nt.nodes.active=target
 plane.data.materials.clear();plane.data.materials.append(mat)
 bpy.ops.object.select_all(action='DESELECT');plane.select_set(True);bpy.context.view_layer.objects.active=plane
 bpy.ops.object.bake(type='EMIT')
 image.filepath_raw=out+'/studs-tinted-'+str(index)+'.png';image.save();image.pack()
 bpy.data.materials['Backyard_Textured_'+str(index)].diffuse_color=color
bpy.data.objects.remove(plane,do_unlink=True);scene.render.engine=old_engine
palette=bpy.data.images['Backyard_Palette']
colors=[tints[0],tints[1],tints[2],(.35,.095,.018,1),(.62,.24,.035,1),(1,1,1,1),(.02,.45,.015,1),(.002,.003,.008,1)]
palette.pixels=[v for c in colors for v in c];palette.filepath_raw=out+'/backyard-palette.png';palette.save();palette.pack()
for i,name in enumerate(['Base','Grass','GrassLight','Timber','TimberLight','White','StartPad','BallBlack']):
 m=bpy.data.materials['Backyard_'+name];m.diffuse_color=colors[i]
scene.world.node_tree.nodes['Background'].inputs[1].default_value=.4
bpy.data.lights['Backyard_Sun'].energy=2.2
field=list(bpy.data.collections['Backyard_Field_Asset'].objects);ball=bpy.data.objects['BF_Football']
def export(obs,filename):
 bpy.ops.object.select_all(action='DESELECT')
 for o in obs:o.select_set(True)
 bpy.context.view_layer.objects.active=obs[0]
 bpy.ops.export_scene.fbx(filepath=out+'/'+filename,use_selection=True,object_types={'MESH'},apply_unit_scale=False,axis_forward='-Z',axis_up='Y',path_mode='COPY',embed_textures=True,add_leaf_bones=False)
export(field,'backyard-field.fbx')
loc=ball.location.copy();ball.location=(0,0,0);export([ball],'football.fbx');ball.location=loc
export(field+[ball],'backyard-field-with-ball.fbx')
bpy.ops.wm.save_as_mainfile(filepath=out+'/backyard-field.blend')
result={'green_turf_side_faces':sum(p.material_index==1 and abs(p.normal.z)<.5 for p in bed.data.polygons),'earth_green_faces':sum(p.material_index!=0 for p in bpy.data.objects['BF_Earth_Base'].data.polygons),'tints':tints,'field_meshes':len(field)}

