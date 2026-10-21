
import bpy,math,bmesh
from mathutils import Vector
root=r'C:/Users/userr/OneDrive/Документы/PROJECTS/roblox/111/RojoTest/assets/fields'
scene=bpy.context.scene
assert not bpy.data.collections.get('Royal_Field_Asset'),'Royal field already exists'
royal=bpy.data.collections.new('Royal_Field_Asset');scene.collection.children.link(royal)
# Core footprints follow the previous tier; upgraded decoration is built separately.
for source in bpy.data.collections['Club_Field_Asset'].objects:
 if any(tag in source.name for tag in ['Sideline_Panel','Bench_','Goal_Foot','Goal_Corner']):continue
 ob=source.copy();ob.data=source.data.copy();ob.name=source.name.replace('CF_','RF_')
 royal.objects.link(ob);ob.location.x+=12
colors=[(.82,.43,.035,1),(.25,.10,.008,1),(.005,.095,.032,1),(.98,.77,.20,1)]
pal=bpy.data.images.new('Royal_Palette',width=4,height=1);pal.pixels=[v for c in colors for v in c]
pal.filepath_raw=root+'/royal/royal-palette.png';pal.file_format='PNG';pal.save();pal.pack()
mats=[]
for i,name in enumerate(['Gold','DarkGold','Emerald','LightGold']):
 m=bpy.data.materials.new('Royal_'+name);m.use_nodes=True;m.diffuse_color=colors[i]
 bs=m.node_tree.nodes['Principled BSDF'];bs.inputs['Roughness'].default_value=.55
 tex=m.node_tree.nodes.new('ShaderNodeTexImage');tex.image=pal;tex.interpolation='Closest'
 m.node_tree.links.new(tex.outputs['Color'],bs.inputs['Base Color']);mats.append(m)
def assign(ob,index):
 ob.data.materials.clear();ob.data.materials.append(mats[index]);uv=ob.data.uv_layers.active or ob.data.uv_layers.new(name='PaletteUV')
 for p in ob.data.polygons:
  p.material_index=0
  for li in p.loop_indices:uv.data[li].uv=((index+.5)/4,.5)
for ob in royal.objects:
 if ob.name in ['RF_Steel_Rails','RF_Steel_Goal']:assign(ob,0)
 if ob.name=='RF_Fence_Posts':assign(ob,1)
def cube(name,c,d,mi):
 bpy.ops.mesh.primitive_cube_add(size=1,location=c);ob=bpy.context.object;ob.name=name;ob.dimensions=d
 bpy.ops.object.transform_apply(location=False,rotation=False,scale=True)
 for coll in list(ob.users_collection):coll.objects.unlink(ob)
 royal.objects.link(ob);assign(ob,mi);return ob
def polyprism(name,coords,depth,mi):
 # planar outline in XZ with depth along Y
 vs=[(x,y-depth/2,z) for x,y,z in coords]+[(x,y+depth/2,z) for x,y,z in coords];n=len(coords)
 fs=[tuple(reversed(range(n))),tuple(range(n,n*2))]
 fs += [(i,(i+1)%n,(i+1)%n+n,i+n) for i in range(n)]
 mesh=bpy.data.meshes.new(name);mesh.from_pydata(vs,[],fs);mesh.update()
 ob=bpy.data.objects.new(name,mesh);royal.objects.link(ob);assign(ob,mi);return ob
# Royal green inset side boards, with regular gold shields visible from the front.
for side in [-1,1]:
 for j in range(9):
  y=-7.72+j*1.95
  cube('RF_Emerald_Panel',(24+side*3.78,y,1.15),(.13,1.65,.40),2)
 # Gold caps increase silhouette without narrowing pitch.
 for j in [0,3,6,9]:
  y=-8.7+j*1.95
  cube('RF_Post_Cap',(24+side*3.78,y,1.95),(.34,.34,.16),0)
for x in [24-2.90,24+2.90]:
 cube('RF_Goal_Base',(x,8.65,.90),(.48,.55,.50),1)
 cube('RF_Goal_Cap',(x,8.65,3.86),(.50,.55,.32),3)
 # faceted laurel leaves climb along outside edge of the posts
 for k in range(5):
  z=1.2+k*.43;outer=x+(-.27 if x<24 else .27)
  polyprism('RF_Laurel_Leaf',[(outer,8.42,z),(outer+(-.30 if x<24 else .30),8.42,z+.12),(outer+(-.36 if x<24 else .36),8.42,z+.40),(outer,8.42,z+.25)],.06,0)
# Simple heraldic shield and crown above crossbar; no text and no effects.
polyprism('RF_Goal_Crest',[(23.48,8.36,4.28),(24,8.36,3.97),(24.52,8.36,4.28),(24.52,8.36,4.82),(23.48,8.36,4.82)],.16,1)
polyprism('RF_Crest_Inlay',[(23.61,8.25,4.33),(24,8.25,4.10),(24.39,8.25,4.33),(24.39,8.25,4.70),(23.61,8.25,4.70)],.06,2)
polyprism('RF_Crown',[(23.60,8.18,4.38),(24.40,8.18,4.38),(24.49,8.18,4.72),(24.20,8.18,4.57),(24,8.18,4.83),(23.80,8.18,4.57),(23.51,8.18,4.72)],.07,3)
# Bake richer emerald turf colors with the user's flat studs texture.
oldengine=scene.render.engine;scene.render.engine='CYCLES';scene.cycles.samples=1
bpy.ops.mesh.primitive_plane_add(size=2);plane=bpy.context.object
source=bpy.data.images.load(root+'/backyard/studtexture.png',check_existing=True)
grass=[]
for index,color in enumerate([(.005,.27,.025,1),(.020,.57,.050,1)]):
 m=bpy.data.materials.new('RoyalBake_'+str(index));m.use_nodes=True;nt=m.node_tree;nt.nodes.clear()
 tex=nt.nodes.new('ShaderNodeTexImage');tex.image=source
 mul=nt.nodes.new('ShaderNodeMixRGB');mul.blend_type='MULTIPLY';mul.inputs[0].default_value=1;mul.inputs[1].default_value=color;nt.links.new(tex.outputs['Color'],mul.inputs[2])
 mix=nt.nodes.new('ShaderNodeMixRGB');mix.inputs[1].default_value=color;nt.links.new(tex.outputs['Alpha'],mix.inputs[0]);nt.links.new(mul.outputs[0],mix.inputs[2])
 em=nt.nodes.new('ShaderNodeEmission');nt.links.new(mix.outputs[0],em.inputs[0])
 output=nt.nodes.new('ShaderNodeOutputMaterial');nt.links.new(em.outputs[0],output.inputs[0])
 image=bpy.data.images.new('Royal_Grass_'+str(index),width=500,height=500,alpha=False)
 target=nt.nodes.new('ShaderNodeTexImage');target.image=image;nt.nodes.active=target
 plane.data.materials.clear();plane.data.materials.append(m)
 bpy.ops.object.select_all(action='DESELECT');plane.select_set(True);bpy.context.view_layer.objects.active=plane
 bpy.ops.object.bake(type='EMIT')
 image.filepath_raw=root+'/royal/royal-grass-'+str(index)+'.png';image.file_format='PNG';image.save();image.pack()
 mat=bpy.data.materials.new('Royal_Turf_'+str(index));mat.use_nodes=True;mat.diffuse_color=color
 tex=mat.node_tree.nodes.new('ShaderNodeTexImage');tex.image=image
 mat.node_tree.links.new(tex.outputs['Color'],mat.node_tree.nodes['Principled BSDF'].inputs['Base Color']);grass.append(mat)
bpy.data.objects.remove(plane,do_unlink=True);scene.render.engine=oldengine
bed=bpy.data.objects['RF_Grass_Bed'];bed.data.materials[1]=grass[0];bed.data.materials[2]=grass[1]
old=bpy.data.objects['RF_Grass_Stripes'];bpy.data.objects.remove(old,do_unlink=True)
# Diamond-cut turf grid clipped to exact pitch bounds.
def clip(poly,axis,bound,sign):
 out=[]
 for a,b in zip(poly,poly[1:]+poly[:1]):
  ina=sign*(a[axis]-bound)>=-1e-7;inb=sign*(b[axis]-bound)>=-1e-7
  if ina:out.append(a)
  if ina!=inb:
   t=(bound-a[axis])/(b[axis]-a[axis]);out.append((a[0]+t*(b[0]-a[0]),a[1]+t*(b[1]-a[1])))
 return out
vs=[];fs=[];mis=[]
for row in range(-11,12):
 for col in range(-4,5):
  x=col*2.4+(row%2)*1.2;y=row
  poly=[(x-1.2,y),(x,y-1),(x+1.2,y),(x,y+1)]
  for axis,bound,sign in [(0,-3.99,1),(0,3.99,-1),(1,-9.999,1),(1,9.999,-1)]:
   if poly:poly=clip(poly,axis,bound,sign)
  # eliminate repeated boundary vertices
  clean=[]
  for p in poly:
   if not clean or Vector(p).__sub__(Vector(clean[-1])).length>1e-6:clean.append(p)
  if len(clean)>2 and (Vector(clean[0])-Vector(clean[-1])).length<1e-6:clean.pop()
  if len(clean)<3:continue
  n=len(clean);off=len(vs)
  vs += [(px,py,z) for z in [.620,.630] for px,py in clean]
  cellfaces=[tuple(off+i for i in reversed(range(n))),tuple(off+n+i for i in range(n))]
  cellfaces += [(off+i,off+(i+1)%n,off+n+(i+1)%n,off+n+i) for i in range(n)]
  fs+=cellfaces;mis += [(row+col)%2]*len(cellfaces)
mesh=bpy.data.meshes.new('RF_Diamond_Turf');mesh.from_pydata(vs,[],fs)
for mat in grass:mesh.materials.append(mat)
uv=mesh.uv_layers.new(name='TurfUV')
for p,index in zip(mesh.polygons,mis):
 p.material_index=index
 for li in p.loop_indices:
  v=mesh.vertices[mesh.loops[li].vertex_index].co;uv.data[li].uv=(v.x/2,v.y/2)
mesh.update();ob=bpy.data.objects.new('RF_Diamond_Turf',mesh);royal.objects.link(ob);ob.location.x=24
# Wider camera frames progression across all three adjacent lanes.
scene.camera.location=(36,-36,34)
scene.camera.rotation_euler=(Vector((12,0,1))-scene.camera.location).to_track_quat('-Z','Y').to_euler()
scene.camera.data.ortho_scale=44
scene.render.resolution_x=1800;scene.render.resolution_y=1100
obs=list(royal.objects)
def export(items,path):
 bpy.ops.object.select_all(action='DESELECT')
 for o in items:o.select_set(True)
 bpy.context.view_layer.objects.active=items[0]
 bpy.ops.export_scene.fbx(filepath=path,use_selection=True,object_types={'MESH'},apply_unit_scale=False,axis_forward='-Z',axis_up='Y',path_mode='COPY',embed_textures=True,add_leaf_bones=False)
for o in obs:o.location.x-=24
export(obs,root+'/royal/royal-field.fbx')
for o in obs:o.location.x+=24
allfields=list(bpy.data.collections['Backyard_Field_Asset'].objects)+list(bpy.data.collections['Club_Field_Asset'].objects)+obs
export(allfields,root+'/training-fields.fbx')
bpy.context.view_layer.update()
audit=[]
for o in obs:
 bm=bmesh.new();bm.from_mesh(o.data)
 audit.append({'name':o.name,'degenerate':sum(f.calc_area()<1e-10 for f in bm.faces),'boundary':sum(e.is_boundary for e in bm.edges)})
 bm.free()
bpy.ops.wm.save_as_mainfile(filepath=root+'/training-fields.blend')
result={'royal_meshes':len(obs),'center_x':24,'audit_issues':[a for a in audit if a['degenerate'] or a['boundary']],'files':[root+'/training-fields.blend',root+'/royal/royal-field.fbx']}

