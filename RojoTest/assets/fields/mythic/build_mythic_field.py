
import bpy,math,bmesh
from mathutils import Vector
root=r'C:/Users/userr/OneDrive/Документы/PROJECTS/roblox/111/RojoTest/assets/fields'
scene=bpy.context.scene
assert not bpy.data.collections.get('Mythic_Field_Asset'),'Mythic field already exists'
col=bpy.data.collections.new('Mythic_Field_Asset');scene.collection.children.link(col)
for source in bpy.data.collections['Club_Field_Asset'].objects:
 if any(tag in source.name for tag in ['Bench_','Goal_Foot','Goal_Corner']):continue
 ob=source.copy();ob.data=source.data.copy();ob.name=source.name.replace('CF_','MF_')
 col.objects.link(ob);ob.location.x+=36
colors=[(.022,.016,.044,1),(.09,.028,.16,1),(.38,.075,.65,1),(.64,.29,.90,1),(.90,.50,.035,1),(.72,.62,.45,1)]
pal=bpy.data.images.new('Mythic_Palette',width=6,height=1);pal.pixels=[v for c in colors for v in c]
pal.filepath_raw=root+'/mythic/mythic-palette.png';pal.file_format='PNG';pal.save();pal.pack()
mats=[]
for i,name in enumerate(['Obsidian','DarkViolet','Amethyst','Lavender','GoldEye','Bone']):
 m=bpy.data.materials.new('Mythic_'+name);m.use_nodes=True;m.diffuse_color=colors[i]
 bs=m.node_tree.nodes['Principled BSDF'];bs.inputs['Roughness'].default_value=.75
 tex=m.node_tree.nodes.new('ShaderNodeTexImage');tex.image=pal;tex.interpolation='Closest'
 m.node_tree.links.new(tex.outputs['Color'],bs.inputs['Base Color']);mats.append(m)
def assign(ob,index):
 ob.data.materials.clear();ob.data.materials.append(mats[index])
 uv=ob.data.uv_layers.active or ob.data.uv_layers.new(name='PaletteUV')
 for p in ob.data.polygons:
  p.material_index=0
  for li in p.loop_indices:uv.data[li].uv=((index+.5)/6,.5)
for ob in col.objects:
 if 'Steel_Goal' in ob.name:assign(ob,0)
 elif 'Steel_Rails' in ob.name:assign(ob,2)
 elif 'Fence_Posts' in ob.name:assign(ob,0)
 elif 'Sideline_Panel' in ob.name:assign(ob,1)
 elif any(tag in ob.name for tag in ['Goal_Supports','Net_Rear_Frame']):assign(ob,1)
def cube(name,c,d,index):
 bpy.ops.mesh.primitive_cube_add(size=1,location=c);ob=bpy.context.object;ob.name=name;ob.dimensions=d
 bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
 for coll in list(ob.users_collection):coll.objects.unlink(ob)
 col.objects.link(ob);assign(ob,index);return ob
def cone(name,c,r,h,index):
 bpy.ops.mesh.primitive_cone_add(vertices=5,radius1=r,radius2=0,depth=h,location=c)
 ob=bpy.context.object;ob.name=name
 for coll in list(ob.users_collection):coll.objects.unlink(ob)
 col.objects.link(ob);assign(ob,index);return ob
joins=[]
for side in [-1,1]:
 for j in [0,3,6,9]:
  x=48+side*3.78;y=-8.7+j*1.95
  cap=cube('MF_Stone_Post_Cap',(x,y,1.96),(.40,.40,.20),1)
  tip=cone('MF_Post_Spire',(x,y,2.22),.20,.50,2);joins.append((tip.name,cap.name))
 for j in range(9):
  y=-7.72+j*1.95
  glyph=cube('MF_Carved_Diamond',(48+side*3.70,y,1.15),(.08,.18,.18),3)
  glyph.rotation_euler.x=math.pi/4
# Chunky goal pillars with attached stylized dragon-head statues.
for x in [48-2.90,48+2.90]:
 pillar=cube('MF_Obsidian_Pillar',(x,8.65,2.28),(.58,.62,3.32),0)
 foot=cube('MF_Goal_Foot',(x,8.65,.85),(.76,.80,.46),1)
 cap=cube('MF_Goal_Capital',(x,8.65,3.94),(.78,.78,.26),2)
 head=cube('MF_Dragon_Head',(x,8.55,4.30),(.76,.76,.72),1);joins.append((head.name,cap.name))
 snout=cube('MF_Dragon_Snout',(x,8.04,4.19),(.64,.74,.30),0);joins.append((snout.name,head.name))
 jaw=cube('MF_Dragon_Jaw',(x,8.08,3.99),(.60,.70,.14),1);joins.append((jaw.name,head.name))
 for dx in [-.25,.25]:
  horn=cone('MF_Dragon_Horn',(x+dx,8.65,4.88),.13,.63,5);joins.append((horn.name,head.name))
  eye=cube('MF_Dragon_Eye',(x+dx,8.18,4.43),(.15,.08,.10),4);joins.append((eye.name,head.name))
  brow=cube('MF_Dragon_Brow',(x+dx,8.15,4.53),(.22,.12,.09),2);joins.append((brow.name,head.name))
 for dx in [-.17,.17]:
  nostril=cube('MF_Dragon_Nostril',(x+dx,7.685,4.24),(.07,.04,.05),1);joins.append((nostril.name,snout.name))
# Carved purple trim follows the solid crossbar instead of floating.
trim=cube('MF_Goal_Trim',(48,8.425,3.79),(5.85,.10,.13),2)
joins.append((trim.name,bpy.data.objects['MF_Steel_Goal'].name))
# Dark violet diamond turf with flat studs.
oldengine=scene.render.engine;scene.render.engine='CYCLES';scene.cycles.samples=1
bpy.ops.mesh.primitive_plane_add(size=2);plane=bpy.context.object
source=bpy.data.images.load(root+'/backyard/studtexture.png',check_existing=True);grass=[]
for index,color in enumerate([(.18,.018,.40,1),(.37,.06,.70,1)]):
 m=bpy.data.materials.new('MythicBake_'+str(index));m.use_nodes=True;nt=m.node_tree;nt.nodes.clear()
 tex=nt.nodes.new('ShaderNodeTexImage');tex.image=source
 mul=nt.nodes.new('ShaderNodeMixRGB');mul.blend_type='MULTIPLY';mul.inputs[0].default_value=1;mul.inputs[1].default_value=color;nt.links.new(tex.outputs['Color'],mul.inputs[2])
 mix=nt.nodes.new('ShaderNodeMixRGB');mix.inputs[1].default_value=color;nt.links.new(tex.outputs['Alpha'],mix.inputs[0]);nt.links.new(mul.outputs[0],mix.inputs[2])
 em=nt.nodes.new('ShaderNodeEmission');nt.links.new(mix.outputs[0],em.inputs[0]);output=nt.nodes.new('ShaderNodeOutputMaterial');nt.links.new(em.outputs[0],output.inputs[0])
 image=bpy.data.images.new('Mythic_Grass_'+str(index),width=500,height=500,alpha=False)
 target=nt.nodes.new('ShaderNodeTexImage');target.image=image;nt.nodes.active=target
 plane.data.materials.clear();plane.data.materials.append(m)
 bpy.ops.object.select_all(action='DESELECT');plane.select_set(True);bpy.context.view_layer.objects.active=plane
 bpy.ops.object.bake(type='EMIT')
 image.filepath_raw=root+'/mythic/mythic-grass-'+str(index)+'.png';image.file_format='PNG';image.save();image.pack()
 mat=bpy.data.materials.new('Mythic_Turf_'+str(index));mat.use_nodes=True;mat.diffuse_color=color
 tex=mat.node_tree.nodes.new('ShaderNodeTexImage');tex.image=image
 mat.node_tree.links.new(tex.outputs['Color'],mat.node_tree.nodes['Principled BSDF'].inputs['Base Color']);grass.append(mat)
bpy.data.objects.remove(plane,do_unlink=True);scene.render.engine=oldengine
bed=bpy.data.objects['MF_Grass_Bed'];bed.data.materials[1]=grass[0];bed.data.materials[2]=grass[1]
bpy.data.objects.remove(bpy.data.objects['MF_Grass_Stripes'],do_unlink=True)
source=bpy.data.objects['RF_Diamond_Turf'];ob=source.copy();ob.data=source.data.copy();ob.name='MF_Diamond_Turf'
ob.location.x+=24;col.objects.link(ob);ob.data.materials.clear()
for m in grass:ob.data.materials.append(m)
scene.camera.location=(58,-43,42)
scene.camera.rotation_euler=(Vector((24,0,1))-scene.camera.location).to_track_quat('-Z','Y').to_euler()
scene.camera.data.ortho_scale=68;scene.render.resolution_x=2200;scene.render.resolution_y=1100
obs=list(col.objects)
def export(items,path):
 bpy.ops.object.select_all(action='DESELECT')
 for o in items:o.select_set(True)
 bpy.context.view_layer.objects.active=items[0]
 bpy.ops.export_scene.fbx(filepath=path,use_selection=True,object_types={'MESH'},apply_unit_scale=False,axis_forward='-Z',axis_up='Y',path_mode='COPY',embed_textures=True,add_leaf_bones=False)
for o in obs:o.location.x-=48
export(obs,root+'/mythic/mythic-field.fbx')
for o in obs:o.location.x+=48
allfields=[]
for name in ['Backyard_Field_Asset','Club_Field_Asset','Royal_Field_Asset','Diamond_Field_Asset','Mythic_Field_Asset']:allfields+=list(bpy.data.collections[name].objects)
export(allfields,root+'/training-fields.fbx')
bpy.context.view_layer.update()
def bounds(o):
 pts=[o.matrix_world@v.co for v in o.data.vertices]
 return [min(v[i] for v in pts) for i in range(3)],[max(v[i] for v in pts) for i in range(3)]
def overlap(a,b):
 amin,amax=bounds(a);bmin,bmax=bounds(b)
 return all(min(amax[i],bmax[i])>max(amin[i],bmin[i]) for i in range(3))
checks={a:overlap(bpy.data.objects[a],bpy.data.objects[b]) for a,b in joins}
audit=[]
for o in obs:
 bm=bmesh.new();bm.from_mesh(o.data);audit.append({'name':o.name,'degenerate':sum(f.calc_area()<1e-10 for f in bm.faces),'boundary':sum(e.is_boundary for e in bm.edges)});bm.free()
bpy.ops.wm.save_as_mainfile(filepath=root+'/training-fields.blend')
result={'mesh_count':len(obs),'attachment_failures':[a for a,ok in checks.items() if not ok],'geometry_issues':[a for a in audit if a['degenerate'] or a['boundary']]}

