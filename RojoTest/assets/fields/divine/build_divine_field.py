
import bpy,math,bmesh
from mathutils import Vector
root=r'C:/Users/userr/OneDrive/Документы/PROJECTS/roblox/111/RojoTest/assets/fields'
scene=bpy.context.scene
assert not bpy.data.collections.get('Divine_Field_Asset'),'Divine field already exists'
col=bpy.data.collections.new('Divine_Field_Asset');scene.collection.children.link(col)
for source in bpy.data.collections['Club_Field_Asset'].objects:
 if any(tag in source.name for tag in ['Bench_','Goal_Foot','Goal_Corner']):continue
 ob=source.copy();ob.data=source.data.copy();ob.name=source.name.replace('CF_','GF_')
 col.objects.link(ob);ob.location.x+=60
colors=[(.94,.96,.87,1),(.78,.43,.050,1),(.31,.15,.018,1),(.99,.79,.30,1),(.18,.36,.20,1)]
pal=bpy.data.images.new('Divine_Palette',width=5,height=1);pal.pixels=[v for c in colors for v in c]
pal.filepath_raw=root+'/divine/divine-palette.png';pal.file_format='PNG';pal.save();pal.pack()
mats=[]
for i,name in enumerate(['IvoryMarble','Gold','DarkGold','PaleGold','Sage']):
 m=bpy.data.materials.new('Divine_'+name);m.use_nodes=True;m.diffuse_color=colors[i]
 bs=m.node_tree.nodes['Principled BSDF'];bs.inputs['Roughness'].default_value=.6
 tex=m.node_tree.nodes.new('ShaderNodeTexImage');tex.image=pal;tex.interpolation='Closest'
 m.node_tree.links.new(tex.outputs['Color'],bs.inputs['Base Color']);mats.append(m)
def assign(ob,index):
 ob.data.materials.clear();ob.data.materials.append(mats[index])
 uv=ob.data.uv_layers.active or ob.data.uv_layers.new(name='PaletteUV')
 for p in ob.data.polygons:
  p.material_index=0
  for li in p.loop_indices:uv.data[li].uv=((index+.5)/5,.5)
for ob in col.objects:
 if any(tag in ob.name for tag in ['Steel_Goal','Goal_Supports','Net_Rear_Frame']):assign(ob,0)
 elif 'Steel_Rails' in ob.name:assign(ob,1)
 elif 'Fence_Posts' in ob.name:assign(ob,0)
 elif 'Sideline_Panel' in ob.name:assign(ob,0)
def cube(name,c,d,index):
 bpy.ops.mesh.primitive_cube_add(size=1,location=c);ob=bpy.context.object;ob.name=name;ob.dimensions=d
 bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
 for coll in list(ob.users_collection):coll.objects.unlink(ob)
 col.objects.link(ob);assign(ob,index);return ob
def prism(name,outline,center_y,depth,index):
 n=len(outline)
 vs=[(x,center_y-depth/2,z) for x,z in outline]+[(x,center_y+depth/2,z) for x,z in outline]
 fs=[tuple(reversed(range(n))),tuple(range(n,2*n))]
 fs += [(k,(k+1)%n,(k+1)%n+n,k+n) for k in range(n)]
 mesh=bpy.data.meshes.new(name);mesh.from_pydata(vs,[],fs);mesh.update()
 ob=bpy.data.objects.new(name,mesh);col.objects.link(ob);assign(ob,index);return ob
joins=[]
for side in [-1,1]:
 for j in [0,3,6,9]:
  x=72+side*3.78;y=-8.7+j*1.95
  cap=cube('GF_Gold_Post_Cap',(x,y,1.98),(.42,.42,.24),1)
  leaf=prism('GF_Laurel_Post',[(x-.17,2.03),(x-.14,2.31),(x,2.57),(x+.14,2.31),(x+.17,2.03)],y,.14,3)
  joins.append((leaf.name,cap.name))
 for j in range(9):
  y=-7.72+j*1.95
  # Gold inset trims touch ivory boards and keep the side silhouette elegant.
  cube('GF_Panel_Gold_Inlay',(72+side*3.70,y,1.14),(.08,1.2,.09),1)
for x in [72-2.90,72+2.90]:
 pillar=cube('GF_Marble_Pillar',(x,8.65,2.29),(.58,.62,3.34),0)
 cube('GF_Column_Base',(x,8.65,.88),(.82,.85,.52),1)
 cap=cube('GF_Column_Capital',(x,8.65,3.96),(.82,.84,.28),1)
 for dx in [-.17,.17]:
  flute=cube('GF_Column_Gold_Flute',(x+dx,8.335,2.30),(.055,.06,2.75),3);joins.append((flute.name,pillar.name))
# Golden trim overlaps the front of the structural marble beam.
trim=cube('GF_Goal_Gold_Trim',(72,8.42,3.81),(5.86,.12,.12),1)
joins.append((trim.name,'GF_Steel_Goal'))
crest=cube('GF_Wing_Crest',(72,8.40,4.34),(.98,.35,.90),1)
joins.append((crest.name,'GF_Steel_Goal'))
inlay=prism('GF_Crest_Ivory',[(71.62,4.15),(72,3.99),(72.38,4.15),(72.38,4.65),(71.62,4.65)],8.20,.09,0)
joins.append((inlay.name,crest.name))
# One closed, jagged feather silhouette per wing avoids detached feather pieces.
wing_outline=[(.30,4.10),(.74,4.10),(1.32,4.38),(1.84,4.88),(2.36,5.64),
 (1.86,5.40),(1.48,4.91),(1.64,5.42),(1.24,5.20),(.94,4.74),
 (1.02,5.15),(.72,4.92),(.47,4.44),(.30,4.48)]
for side in [-1,1]:
 outline=[(72+side*x,z) for x,z in wing_outline]
 if side<0:outline.reverse()
 wing=prism('GF_White_Wing',outline,8.40,.16,0);joins.append((wing.name,crest.name))
 rootplate=prism('GF_Gold_Wing_Root',[(72+side*.32,4.12),(72+side*.78,4.18),(72+side*1.02,4.47),(72+side*.72,4.42),(72+side*.32,4.38)],8.30,.11,3)
 joins.append((rootplate.name,wing.name))
# A static laurel ring sits embedded on the crest; no glow/emission.
bpy.ops.mesh.primitive_torus_add(major_segments=24,minor_segments=6,major_radius=.27,minor_radius=.047,location=(72,8.17,4.42),rotation=(math.pi/2,0,0))
ring=bpy.context.object;ring.name='GF_Crest_Laurel_Ring'
for coll in list(ring.users_collection):coll.objects.unlink(ring)
col.objects.link(ring);assign(ring,3);joins.append((ring.name,inlay.name))
# Pale fresh green turf, using the same baked flat studs overlay.
oldengine=scene.render.engine;scene.render.engine='CYCLES';scene.cycles.samples=1
bpy.ops.mesh.primitive_plane_add(size=2);plane=bpy.context.object
source=bpy.data.images.load(root+'/backyard/studtexture.png',check_existing=True);grass=[]
for index,color in enumerate([(.28,.62,.28,1),(.48,.86,.42,1)]):
 m=bpy.data.materials.new('DivineBake_'+str(index));m.use_nodes=True;nt=m.node_tree;nt.nodes.clear()
 tex=nt.nodes.new('ShaderNodeTexImage');tex.image=source
 mul=nt.nodes.new('ShaderNodeMixRGB');mul.blend_type='MULTIPLY';mul.inputs[0].default_value=1;mul.inputs[1].default_value=color;nt.links.new(tex.outputs['Color'],mul.inputs[2])
 mix=nt.nodes.new('ShaderNodeMixRGB');mix.inputs[1].default_value=color;nt.links.new(tex.outputs['Alpha'],mix.inputs[0]);nt.links.new(mul.outputs[0],mix.inputs[2])
 em=nt.nodes.new('ShaderNodeEmission');nt.links.new(mix.outputs[0],em.inputs[0]);output=nt.nodes.new('ShaderNodeOutputMaterial');nt.links.new(em.outputs[0],output.inputs[0])
 image=bpy.data.images.new('Divine_Grass_'+str(index),width=500,height=500,alpha=False)
 target=nt.nodes.new('ShaderNodeTexImage');target.image=image;nt.nodes.active=target
 plane.data.materials.clear();plane.data.materials.append(m)
 bpy.ops.object.select_all(action='DESELECT');plane.select_set(True);bpy.context.view_layer.objects.active=plane
 bpy.ops.object.bake(type='EMIT')
 image.filepath_raw=root+'/divine/divine-grass-'+str(index)+'.png';image.file_format='PNG';image.save();image.pack()
 mat=bpy.data.materials.new('Divine_Turf_'+str(index));mat.use_nodes=True;mat.diffuse_color=color
 tex=mat.node_tree.nodes.new('ShaderNodeTexImage');tex.image=image
 mat.node_tree.links.new(tex.outputs['Color'],mat.node_tree.nodes['Principled BSDF'].inputs['Base Color']);grass.append(mat)
bpy.data.objects.remove(plane,do_unlink=True);scene.render.engine=oldengine
bed=bpy.data.objects['GF_Grass_Bed'];bed.data.materials[1]=grass[0];bed.data.materials[2]=grass[1]
bpy.data.objects.remove(bpy.data.objects['GF_Grass_Stripes'],do_unlink=True)
source=bpy.data.objects['RF_Diamond_Turf'];ob=source.copy();ob.data=source.data.copy();ob.name='GF_Diamond_Turf'
ob.location.x+=48;col.objects.link(ob);ob.data.materials.clear()
for m in grass:ob.data.materials.append(m)
scene.camera.location=(82,-46,46)
scene.camera.rotation_euler=(Vector((36,0,1))-scene.camera.location).to_track_quat('-Z','Y').to_euler()
scene.render.resolution_x=2600;scene.render.resolution_y=1200
bpy.context.view_layer.update()
cam=scene.camera
points=[cam.matrix_world.inverted()@(o.matrix_world@v.co) for o in scene.objects if o.type=='MESH' for v in o.data.vertices]
xmin,xmax=min(v.x for v in points),max(v.x for v in points);ymin,ymax=min(v.y for v in points),max(v.y for v in points)
cam.location+=cam.rotation_euler.to_quaternion()@Vector(((xmin+xmax)/2,(ymin+ymax)/2,0))
cam.data.ortho_scale=max(xmax-xmin,(ymax-ymin)*scene.render.resolution_x/scene.render.resolution_y)*1.10
obs=list(col.objects)
def export(items,path):
 bpy.ops.object.select_all(action='DESELECT')
 for o in items:o.select_set(True)
 bpy.context.view_layer.objects.active=items[0]
 bpy.ops.export_scene.fbx(filepath=path,use_selection=True,object_types={'MESH'},apply_unit_scale=False,axis_forward='-Z',axis_up='Y',path_mode='COPY',embed_textures=True,add_leaf_bones=False)
for o in obs:o.location.x-=72
export(obs,root+'/divine/divine-field.fbx')
for o in obs:o.location.x+=72
allfields=[]
for name in ['Backyard_Field_Asset','Club_Field_Asset','Royal_Field_Asset','Diamond_Field_Asset','Mythic_Field_Asset','Cosmic_Field_Asset','Divine_Field_Asset']:allfields+=list(bpy.data.collections[name].objects)
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

