
import bpy,math,bmesh
from mathutils import Vector
root=r'C:/Users/userr/OneDrive/Документы/PROJECTS/roblox/111/RojoTest/assets/fields'
scene=bpy.context.scene
assert not bpy.data.collections.get('Club_Field_Asset'),'Club field already exists'
club=bpy.data.collections.new('Club_Field_Asset');scene.collection.children.link(club)
original=list(bpy.data.collections['Backyard_Field_Asset'].objects)
for source in original:
 ob=source.copy();ob.data=source.data.copy();ob.name=source.name.replace('BF_','CF_')
 club.objects.link(ob);ob.location.x+=12
def flat(name,c):
 m=bpy.data.materials.new(name);m.use_nodes=True;m.diffuse_color=c
 m.node_tree.nodes['Principled BSDF'].inputs['Base Color'].default_value=c
 m.node_tree.nodes['Principled BSDF'].inputs['Roughness'].default_value=.6
 return m
white=flat('Club_White_Steel',(.95,.98,1,1));blue=flat('Club_Deep_Blue',(.008,.045,.20,1));cyan=flat('Club_Blue_Accent',(.005,.26,.65,1))
# Small texture palette for standard FBX-compatible materials.
pal=bpy.data.images.new('Club_Palette',width=3,height=1)
pal.pixels=[v for c in [(.95,.98,1,1),(.008,.045,.20,1),(.005,.26,.65,1)] for v in c]
pal.filepath_raw=root+'/club/club-palette.png';pal.file_format='PNG';pal.save();pal.pack()
for i,m in enumerate([white,blue,cyan]):
 tex=m.node_tree.nodes.new('ShaderNodeTexImage');tex.image=pal;tex.interpolation='Closest'
 m.node_tree.links.new(tex.outputs['Color'],m.node_tree.nodes['Principled BSDF'].inputs['Base Color'])
def assign(ob,mat,slot):
 ob.data.materials.clear();ob.data.materials.append(mat)
 uv=ob.data.uv_layers.active or ob.data.uv_layers.new(name='PaletteUV')
 for p in ob.data.polygons:
  p.material_index=0
  for li in p.loop_indices:uv.data[li].uv=((slot+.5)/3,.5)
for ob in club.objects:
 if ob.name in ['CF_Fence_Rails','CF_Goal_Timber','CF_Goal_Supports']:assign(ob,white,0)
 if ob.name=='CF_Fence_Posts':assign(ob,blue,1)
bpy.data.objects['CF_Goal_Timber'].name='CF_Steel_Goal'
bpy.data.objects['CF_Fence_Rails'].name='CF_Steel_Rails'
# Club turf uses deeper emerald stripes with the same flat studs overlay.
oldengine=scene.render.engine;scene.render.engine='CYCLES';scene.cycles.samples=1
bpy.ops.mesh.primitive_plane_add(size=2);plane=bpy.context.object
source=bpy.data.images.load(root+'/backyard/studtexture.png',check_existing=True)
grass=[]
for index,color in enumerate([(.008,.34,.023,1),(.025,.64,.035,1)]):
 bake=bpy.data.materials.new('ClubBake_'+str(index));bake.use_nodes=True;nt=bake.node_tree;nt.nodes.clear()
 tex=nt.nodes.new('ShaderNodeTexImage');tex.image=source
 mult=nt.nodes.new('ShaderNodeMixRGB');mult.blend_type='MULTIPLY';mult.inputs[0].default_value=1;mult.inputs[1].default_value=color;nt.links.new(tex.outputs['Color'],mult.inputs[2])
 mix=nt.nodes.new('ShaderNodeMixRGB');mix.inputs[1].default_value=color;nt.links.new(tex.outputs['Alpha'],mix.inputs[0]);nt.links.new(mult.outputs[0],mix.inputs[2])
 em=nt.nodes.new('ShaderNodeEmission');nt.links.new(mix.outputs[0],em.inputs[0])
 output=nt.nodes.new('ShaderNodeOutputMaterial');nt.links.new(em.outputs[0],output.inputs[0])
 image=bpy.data.images.new('Club_Grass_'+str(index),width=500,height=500,alpha=False)
 target=nt.nodes.new('ShaderNodeTexImage');target.image=image;nt.nodes.active=target
 plane.data.materials.clear();plane.data.materials.append(bake)
 bpy.ops.object.select_all(action='DESELECT');plane.select_set(True);bpy.context.view_layer.objects.active=plane
 bpy.ops.object.bake(type='EMIT')
 image.filepath_raw=root+'/club/club-grass-'+str(index)+'.png';image.file_format='PNG';image.save();image.pack()
 mat=flat('Club_Grass_'+str(index),color)
 tex=mat.node_tree.nodes.new('ShaderNodeTexImage');tex.image=image
 mat.node_tree.links.new(tex.outputs['Color'],mat.node_tree.nodes['Principled BSDF'].inputs['Base Color'])
 grass.append(mat)
bpy.data.objects.remove(plane,do_unlink=True);scene.render.engine=oldengine
for name in ['CF_Grass_Bed','CF_Grass_Stripes']:
 ob=bpy.data.objects[name];ob.data.materials[1]=grass[0];ob.data.materials[2]=grass[1]
def cube(name,center,size,mat,slot):
 bpy.ops.mesh.primitive_cube_add(size=1,location=center)
 ob=bpy.context.object;ob.name=name;ob.dimensions=size
 bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
 for c in list(ob.users_collection):c.objects.unlink(ob)
 club.objects.link(ob);assign(ob,mat,slot);return ob
# Solid low sideline panels distinguish club fencing from starter timber.
for side in [-1,1]:
 for j in range(9):
  cube('CF_Sideline_Panel',(12+side*3.78,-7.72+j*1.95,1.13),(.12,1.65,.36),cyan if j%3==1 else blue,2 if j%3==1 else 1)
for x in [12-2.90,12+2.90]:
 cube('CF_Goal_Foot',(x,8.65,.85),(.37,.43,.44),blue,1)
 cube('CF_Goal_Corner',(x,8.65,3.82),(.39,.46,.25),cyan,2)
# Compact spectator benches behind the goal, outside the playing lane.
for x in [12-2,12+2]:
 cube('CF_Bench_Seat',(x,10.12,.99),(1.65,.48,.13),cyan,2)
 for dx in [-.55,.55]:cube('CF_Bench_Leg',(x+dx,10.12,.67),(.12,.34,.50),blue,1)
scene.camera.location=(27,-33,30)
scene.camera.rotation_euler=(Vector((6,0,1))-scene.camera.location).to_track_quat('-Z','Y').to_euler()
scene.camera.data.ortho_scale=35
scene.render.resolution_x=1600;scene.render.resolution_y=1100
clubobs=list(club.objects)
def export(obs,path):
 bpy.ops.object.select_all(action='DESELECT')
 for o in obs:o.select_set(True)
 bpy.context.view_layer.objects.active=obs[0]
 bpy.ops.export_scene.fbx(filepath=path,use_selection=True,object_types={'MESH'},apply_unit_scale=False,axis_forward='-Z',axis_up='Y',path_mode='COPY',embed_textures=True,add_leaf_bones=False)
for ob in clubobs:ob.location.x-=12
export(clubobs,root+'/club/club-field.fbx')
for ob in clubobs:ob.location.x+=12
export(original+clubobs,root+'/training-fields.fbx')
bpy.context.view_layer.update()
audit=[]
for ob in clubobs:
 bm=bmesh.new();bm.from_mesh(ob.data)
 audit.append({'object':ob.name,'degenerate':sum(f.calc_area()<1e-10 for f in bm.faces),'boundary':sum(e.is_boundary for e in bm.edges)})
 bm.free()
bpy.ops.wm.save_as_mainfile(filepath=root+'/training-fields.blend')
result={'club_objects':len(clubobs),'center_offset':12,'gap_between_bases':2.4,'audit_pass':all(a['degenerate']==0 and a['boundary']==0 for a in audit),'standalone':root+'/club/club-field.fbx','scene_file':root+'/training-fields.blend'}

