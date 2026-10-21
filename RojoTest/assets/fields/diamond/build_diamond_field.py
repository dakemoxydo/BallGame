
import bpy,math,bmesh
from mathutils import Vector
root=r'C:/Users/userr/OneDrive/Документы/PROJECTS/roblox/111/RojoTest/assets/fields'
scene=bpy.context.scene
assert not bpy.data.collections.get('Diamond_Field_Asset'),'Diamond field already exists'
col=bpy.data.collections.new('Diamond_Field_Asset');scene.collection.children.link(col)
for source in bpy.data.collections['Club_Field_Asset'].objects:
 if any(tag in source.name for tag in ['Bench_','Goal_Foot','Goal_Corner']):continue
 ob=source.copy();ob.data=source.data.copy();ob.name=source.name.replace('CF_','DF_')
 col.objects.link(ob);ob.location.x+=24
colors=[(.65,.78,.86,1),(.10,.22,.30,1),(.012,.43,.72,1),(.18,.85,1,1),(.004,.16,.36,1)]
pal=bpy.data.images.new('Diamond_Palette',width=5,height=1);pal.pixels=[v for c in colors for v in c]
pal.filepath_raw=root+'/diamond/diamond-palette.png';pal.file_format='PNG';pal.save();pal.pack()
mats=[]
for i,name in enumerate(['Silver','DarkSilver','CrystalBlue','CrystalLight','CrystalShade']):
 m=bpy.data.materials.new('Diamond_'+name);m.use_nodes=True;m.diffuse_color=colors[i]
 bs=m.node_tree.nodes['Principled BSDF'];bs.inputs['Roughness'].default_value=.42
 tex=m.node_tree.nodes.new('ShaderNodeTexImage');tex.image=pal;tex.interpolation='Closest'
 m.node_tree.links.new(tex.outputs['Color'],bs.inputs['Base Color']);mats.append(m)
def assign(ob,index):
 ob.data.materials.clear();ob.data.materials.append(mats[index])
 uv=ob.data.uv_layers.active or ob.data.uv_layers.new(name='PaletteUV')
 for p in ob.data.polygons:
  p.material_index=0
  for li in p.loop_indices:uv.data[li].uv=((index+.5)/5,.5)
for ob in col.objects:
 if any(tag in ob.name for tag in ['Steel_Goal','Steel_Rails','Goal_Supports','Net_Rear_Frame']):assign(ob,0)
 elif 'Fence_Posts' in ob.name:assign(ob,1)
 elif 'Sideline_Panel' in ob.name:assign(ob,2)
def cube(name,c,d,index):
 bpy.ops.mesh.primitive_cube_add(size=1,location=c);ob=bpy.context.object;ob.name=name;ob.dimensions=d
 bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
 for coll in list(ob.users_collection):coll.objects.unlink(ob)
 col.objects.link(ob);assign(ob,index);return ob
attachments=[]
def crystal(name,c,r,h):
 x,y,z=c;n=6
 vs=[(x+math.cos(k*2*math.pi/n)*r*.62,y+math.sin(k*2*math.pi/n)*r*.62,z) for k in range(n)]
 vs += [(x+math.cos(k*2*math.pi/n)*r,y+math.sin(k*2*math.pi/n)*r,z+h*.40) for k in range(n)]
 vs += [(x+math.cos(k*2*math.pi/n)*r*.72,y+math.sin(k*2*math.pi/n)*r*.72,z+h*.72) for k in range(n)]
 vs.append((x+.04*r,y,z+h))
 fs=[tuple(reversed(range(n)))]
 for ring in range(2):
  fs += [(ring*n+k,ring*n+(k+1)%n,(ring+1)*n+(k+1)%n,(ring+1)*n+k) for k in range(n)]
 fs += [(2*n+k,2*n+(k+1)%n,3*n) for k in range(n)]
 mesh=bpy.data.meshes.new(name);mesh.from_pydata(vs,[],fs)
 for m in mats:mesh.materials.append(m)
 uv=mesh.uv_layers.new(name='PaletteUV')
 for p in mesh.polygons:
  index=[2,3,2,4,2,3][p.index%6];p.material_index=index
  for li in p.loop_indices:uv.data[li].uv=((index+.5)/5,.5)
 mesh.update();ob=bpy.data.objects.new(name,mesh);col.objects.link(ob);return ob
for side in [-1,1]:
 for j in [0,3,6,9]:
  x=36+side*3.78;y=-8.7+j*1.95
  pedestal=cube('DF_Crystal_Post_Cap',(x,y,1.96),(.38,.38,.20),0)
  ornament=crystal('DF_Fence_Crystal',(x,y,2.01),.21,.65)
  attachments.append((ornament.name,pedestal.name))
for x in [36-2.90,36+2.90]:
 cube('DF_Goal_Foot',(x,8.65,.86),(.50,.56,.48),1)
 pedestal=cube('DF_Goal_Cap',(x,8.65,3.89),(.55,.56,.30),0)
 ornament=crystal('DF_Goal_Corner_Crystal',(x,8.65,3.99),.32,.90)
 attachments.append((ornament.name,pedestal.name))
pedestal=cube('DF_Central_Crystal_Mount',(36,8.65,4.06),(1.4,.50,.25),0)
for x,r,h in [(35.58,.24,.65),(36,.42,1.22),(36.42,.24,.72)]:
 ornament=crystal('DF_Goal_Crest_Crystal',(x,8.65,4.12),r,h);attachments.append((ornament.name,pedestal.name))
# Mint/aqua turf retains the user's flat stud pattern.
oldengine=scene.render.engine;scene.render.engine='CYCLES';scene.cycles.samples=1
bpy.ops.mesh.primitive_plane_add(size=2);plane=bpy.context.object
source=bpy.data.images.load(root+'/backyard/studtexture.png',check_existing=True)
grass=[]
for index,color in enumerate([(.008,.50,.32,1),(.030,.80,.58,1)]):
 m=bpy.data.materials.new('DiamondBake_'+str(index));m.use_nodes=True;nt=m.node_tree;nt.nodes.clear()
 tex=nt.nodes.new('ShaderNodeTexImage');tex.image=source
 mul=nt.nodes.new('ShaderNodeMixRGB');mul.blend_type='MULTIPLY';mul.inputs[0].default_value=1;mul.inputs[1].default_value=color;nt.links.new(tex.outputs['Color'],mul.inputs[2])
 mix=nt.nodes.new('ShaderNodeMixRGB');mix.inputs[1].default_value=color;nt.links.new(tex.outputs['Alpha'],mix.inputs[0]);nt.links.new(mul.outputs[0],mix.inputs[2])
 em=nt.nodes.new('ShaderNodeEmission');nt.links.new(mix.outputs[0],em.inputs[0]);output=nt.nodes.new('ShaderNodeOutputMaterial');nt.links.new(em.outputs[0],output.inputs[0])
 image=bpy.data.images.new('Diamond_Grass_'+str(index),width=500,height=500,alpha=False)
 target=nt.nodes.new('ShaderNodeTexImage');target.image=image;nt.nodes.active=target
 plane.data.materials.clear();plane.data.materials.append(m)
 bpy.ops.object.select_all(action='DESELECT');plane.select_set(True);bpy.context.view_layer.objects.active=plane
 bpy.ops.object.bake(type='EMIT')
 image.filepath_raw=root+'/diamond/diamond-grass-'+str(index)+'.png';image.file_format='PNG';image.save();image.pack()
 mat=bpy.data.materials.new('Diamond_Turf_'+str(index));mat.use_nodes=True;mat.diffuse_color=color
 tex=mat.node_tree.nodes.new('ShaderNodeTexImage');tex.image=image
 mat.node_tree.links.new(tex.outputs['Color'],mat.node_tree.nodes['Principled BSDF'].inputs['Base Color']);grass.append(mat)
bpy.data.objects.remove(plane,do_unlink=True);scene.render.engine=oldengine
bed=bpy.data.objects['DF_Grass_Bed'];bed.data.materials[1]=grass[0];bed.data.materials[2]=grass[1]
# Reuse exact clipped diamond paving geometry with independent mint materials.
old=bpy.data.objects['DF_Grass_Stripes'];bpy.data.objects.remove(old,do_unlink=True)
source=bpy.data.objects['RF_Diamond_Turf'];ob=source.copy();ob.data=source.data.copy();ob.name='DF_Diamond_Turf'
ob.location.x+=12;col.objects.link(ob)
ob.data.materials.clear()
for m in grass:ob.data.materials.append(m)
scene.camera.location=(46,-40,38)
scene.camera.rotation_euler=(Vector((18,0,1))-scene.camera.location).to_track_quat('-Z','Y').to_euler()
scene.camera.data.ortho_scale=56
scene.render.resolution_x=2000;scene.render.resolution_y=1100
obs=list(col.objects)
def export(items,path):
 bpy.ops.object.select_all(action='DESELECT')
 for o in items:o.select_set(True)
 bpy.context.view_layer.objects.active=items[0]
 bpy.ops.export_scene.fbx(filepath=path,use_selection=True,object_types={'MESH'},apply_unit_scale=False,axis_forward='-Z',axis_up='Y',path_mode='COPY',embed_textures=True,add_leaf_bones=False)
for o in obs:o.location.x-=36
export(obs,root+'/diamond/diamond-field.fbx')
for o in obs:o.location.x+=36
allfields=[]
for name in ['Backyard_Field_Asset','Club_Field_Asset','Royal_Field_Asset','Diamond_Field_Asset']:allfields+=list(bpy.data.collections[name].objects)
export(allfields,root+'/training-fields.fbx')
bpy.context.view_layer.update()
def bounds(o):
 pts=[o.matrix_world@v.co for v in o.data.vertices]
 return [min(v[i] for v in pts) for i in range(3)],[max(v[i] for v in pts) for i in range(3)]
def overlap(a,b):
 amin,amax=bounds(a);bmin,bmax=bounds(b)
 return all(min(amax[i],bmax[i])>max(amin[i],bmin[i]) for i in range(3))
attachment_checks={a:overlap(bpy.data.objects[a],bpy.data.objects[b]) for a,b in attachments}
audit=[]
for o in obs:
 bm=bmesh.new();bm.from_mesh(o.data)
 audit.append({'name':o.name,'degenerate':sum(f.calc_area()<1e-10 for f in bm.faces),'boundary':sum(e.is_boundary for e in bm.edges)})
 bm.free()
bpy.ops.wm.save_as_mainfile(filepath=root+'/training-fields.blend')
result={'diamond_meshes':len(obs),'center_x':36,'attachment_checks':attachment_checks,'geometry_issues':[a for a in audit if a['degenerate'] or a['boundary']]}

