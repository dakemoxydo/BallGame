
import bpy,math,bmesh
from mathutils import Vector
root=r'C:/Users/userr/OneDrive/Документы/PROJECTS/roblox/111/RojoTest/assets/fields'
scene=bpy.context.scene
assert not bpy.data.collections.get('Cosmic_Field_Asset'),'Cosmic field already exists'
col=bpy.data.collections.new('Cosmic_Field_Asset');scene.collection.children.link(col)
for source in bpy.data.collections['Club_Field_Asset'].objects:
 if any(tag in source.name for tag in ['Bench_','Goal_Foot','Goal_Corner']):continue
 ob=source.copy();ob.data=source.data.copy();ob.name=source.name.replace('CF_','SF_')
 col.objects.link(ob);ob.location.x+=48
colors=[(.66,.78,.92,1),(.010,.028,.090,1),(.015,.50,.82,1),(.11,.22,.70,1),(.36,.09,.66,1),(.83,.36,.065,1)]
pal=bpy.data.images.new('Cosmic_Palette',width=6,height=1);pal.pixels=[v for c in colors for v in c]
pal.filepath_raw=root+'/cosmic/cosmic-palette.png';pal.file_format='PNG';pal.save();pal.pack()
mats=[]
for i,name in enumerate(['Chrome','Navy','Cyan','BluePlanet','PurplePlanet','Saturn']):
 m=bpy.data.materials.new('Cosmic_'+name);m.use_nodes=True;m.diffuse_color=colors[i]
 bs=m.node_tree.nodes['Principled BSDF'];bs.inputs['Roughness'].default_value=.4
 tex=m.node_tree.nodes.new('ShaderNodeTexImage');tex.image=pal;tex.interpolation='Closest'
 m.node_tree.links.new(tex.outputs['Color'],bs.inputs['Base Color']);mats.append(m)
def assign(ob,index):
 ob.data.materials.clear();ob.data.materials.append(mats[index])
 uv=ob.data.uv_layers.active or ob.data.uv_layers.new(name='PaletteUV')
 for p in ob.data.polygons:
  p.material_index=0
  for li in p.loop_indices:uv.data[li].uv=((index+.5)/6,.5)
for ob in col.objects:
 if any(tag in ob.name for tag in ['Steel_Goal','Steel_Rails','Goal_Supports','Net_Rear_Frame']):assign(ob,0)
 elif 'Fence_Posts' in ob.name:assign(ob,1)
 elif 'Sideline_Panel' in ob.name:assign(ob,3 if ob.name.endswith(('.001','.004','.007','.010','.013','.016')) else 1)
def link(ob,name,index):
 ob.name=name
 for coll in list(ob.users_collection):coll.objects.unlink(ob)
 col.objects.link(ob);assign(ob,index);return ob
def cube(name,c,d,index):
 bpy.ops.mesh.primitive_cube_add(size=1,location=c);ob=bpy.context.object;ob.dimensions=d
 bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
 return link(ob,name,index)
def sphere(name,c,r,index):
 bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=2,radius=r,location=c)
 return link(bpy.context.object,name,index)
def torus(name,c,r,t,index):
 bpy.ops.mesh.primitive_torus_add(major_segments=24,minor_segments=6,major_radius=r,minor_radius=t,location=c)
 return link(bpy.context.object,name,index)
def rod(name,a,b,r,index):
 a,b=Vector(a),Vector(b);delta=b-a
 bpy.ops.mesh.primitive_cylinder_add(vertices=8,radius=r,depth=delta.length,location=(a+b)/2)
 ob=bpy.context.object;ob.rotation_euler=delta.to_track_quat('Z','Y').to_euler()
 return link(ob,name,index)
joins=[]
# Post globes and their orbit rings have physical spokes.
for side in [-1,1]:
 for j in [0,3,6,9]:
  x=60+side*3.78;y=-8.7+j*1.95
  cap=cube('SF_Post_Cap',(x,y,1.98),(.38,.38,.23),0)
  planet=sphere('SF_Post_Planet',(x,y,2.22),.19,3 if j%2==0 else 4);joins.append((planet.name,cap.name))
  orbit=torus('SF_Post_Orbit',(x,y,2.22),.30,.025,2)
  spoke=rod('SF_Post_Orbit_Spoke',(x-.30,y,2.22),(x+.30,y,2.22),.024,0)
  joins.extend([(orbit.name,spoke.name),(planet.name,spoke.name)])
# Silver goal column armor with cyan insets attached to each pillar.
for x in [60-2.90,60+2.90]:
 cube('SF_Goal_Foot',(x,8.65,.88),(.62,.66,.52),1)
 column=cube('SF_Goal_Column',(x,8.65,2.31),(.50,.55,3.38),0)
 strip=cube('SF_Goal_Inlay',(x,8.36,2.31),(.15,.06,2.9),2);joins.append((strip.name,column.name))
 cube('SF_Goal_Cap',(x,8.65,3.92),(.64,.62,.28),1)
# Central Saturn crest: mount connects to crossbar, planet and orbit connect to mount.
mount=cube('SF_Saturn_Mount',(60,8.65,4.08),(.48,.46,.35),1)
stem=rod('SF_Saturn_Stem',(60,8.65,4.12),(60,8.65,4.85),.085,0)
planet=sphere('SF_Saturn',(60,8.65,5.02),.53,5)
orbit=torus('SF_Saturn_Orbit',(60,8.65,5.02),.91,.065,0)
spoke=rod('SF_Saturn_Orbit_Spoke',(59.09,8.65,5.02),(60.91,8.65,5.02),.035,2)
joins.extend([(mount.name,'SF_Steel_Goal'),(stem.name,mount.name),(planet.name,stem.name),(orbit.name,spoke.name),(planet.name,spoke.name)])
# Dark blue/cobalt turf, tiled with flat studs.
oldengine=scene.render.engine;scene.render.engine='CYCLES';scene.cycles.samples=1
bpy.ops.mesh.primitive_plane_add(size=2);plane=bpy.context.object
source=bpy.data.images.load(root+'/backyard/studtexture.png',check_existing=True);grass=[]
for index,color in enumerate([(.018,.038,.16,1),(.055,.10,.34,1)]):
 m=bpy.data.materials.new('CosmicBake_'+str(index));m.use_nodes=True;nt=m.node_tree;nt.nodes.clear()
 tex=nt.nodes.new('ShaderNodeTexImage');tex.image=source
 mul=nt.nodes.new('ShaderNodeMixRGB');mul.blend_type='MULTIPLY';mul.inputs[0].default_value=1;mul.inputs[1].default_value=color;nt.links.new(tex.outputs['Color'],mul.inputs[2])
 mix=nt.nodes.new('ShaderNodeMixRGB');mix.inputs[1].default_value=color;nt.links.new(tex.outputs['Alpha'],mix.inputs[0]);nt.links.new(mul.outputs[0],mix.inputs[2])
 em=nt.nodes.new('ShaderNodeEmission');nt.links.new(mix.outputs[0],em.inputs[0]);output=nt.nodes.new('ShaderNodeOutputMaterial');nt.links.new(em.outputs[0],output.inputs[0])
 image=bpy.data.images.new('Cosmic_Grass_'+str(index),width=500,height=500,alpha=False)
 target=nt.nodes.new('ShaderNodeTexImage');target.image=image;nt.nodes.active=target
 plane.data.materials.clear();plane.data.materials.append(m)
 bpy.ops.object.select_all(action='DESELECT');plane.select_set(True);bpy.context.view_layer.objects.active=plane
 bpy.ops.object.bake(type='EMIT')
 image.filepath_raw=root+'/cosmic/cosmic-grass-'+str(index)+'.png';image.file_format='PNG';image.save();image.pack()
 mat=bpy.data.materials.new('Cosmic_Turf_'+str(index));mat.use_nodes=True;mat.diffuse_color=color
 tex=mat.node_tree.nodes.new('ShaderNodeTexImage');tex.image=image
 mat.node_tree.links.new(tex.outputs['Color'],mat.node_tree.nodes['Principled BSDF'].inputs['Base Color']);grass.append(mat)
bpy.data.objects.remove(plane,do_unlink=True);scene.render.engine=oldengine
bed=bpy.data.objects['SF_Grass_Bed'];bed.data.materials[1]=grass[0];bed.data.materials[2]=grass[1]
bpy.data.objects.remove(bpy.data.objects['SF_Grass_Stripes'],do_unlink=True)
source=bpy.data.objects['RF_Diamond_Turf'];ob=source.copy();ob.data=source.data.copy();ob.name='SF_Diamond_Turf'
ob.location.x+=36;col.objects.link(ob);ob.data.materials.clear()
for m in grass:ob.data.materials.append(m)
scene.camera.location=(70,-46,46)
scene.camera.rotation_euler=(Vector((30,0,1))-scene.camera.location).to_track_quat('-Z','Y').to_euler()
scene.camera.data.ortho_scale=80;scene.render.resolution_x=2400;scene.render.resolution_y=1100
obs=list(col.objects)
def export(items,path):
 bpy.ops.object.select_all(action='DESELECT')
 for o in items:o.select_set(True)
 bpy.context.view_layer.objects.active=items[0]
 bpy.ops.export_scene.fbx(filepath=path,use_selection=True,object_types={'MESH'},apply_unit_scale=False,axis_forward='-Z',axis_up='Y',path_mode='COPY',embed_textures=True,add_leaf_bones=False)
for o in obs:o.location.x-=60
export(obs,root+'/cosmic/cosmic-field.fbx')
for o in obs:o.location.x+=60
allfields=[]
for name in ['Backyard_Field_Asset','Club_Field_Asset','Royal_Field_Asset','Diamond_Field_Asset','Mythic_Field_Asset','Cosmic_Field_Asset']:allfields+=list(bpy.data.collections[name].objects)
export(allfields,root+'/training-fields.fbx')
bpy.context.view_layer.update()
def bounds(o):
 pts=[o.matrix_world@v.co for v in o.data.vertices]
 return [min(v[i] for v in pts) for i in range(3)],[max(v[i] for v in pts) for i in range(3)]
def overlap(a,b):
 amin,amax=bounds(a);bmin,bmax=bounds(b)
 return all(min(amax[i],bmax[i])>max(amin[i],bmin[i]) for i in range(3))
checks={a+' -> '+b:overlap(bpy.data.objects[a],bpy.data.objects[b]) for a,b in joins}
audit=[]
for o in obs:
 bm=bmesh.new();bm.from_mesh(o.data);audit.append({'name':o.name,'degenerate':sum(f.calc_area()<1e-10 for f in bm.faces),'boundary':sum(e.is_boundary for e in bm.edges)});bm.free()
bpy.ops.wm.save_as_mainfile(filepath=root+'/training-fields.blend')
result={'mesh_count':len(obs),'attachment_failures':[a for a,ok in checks.items() if not ok],'geometry_issues':[a for a in audit if a['degenerate'] or a['boundary']]}

