
import bpy,math
from mathutils import Vector
root=r'C:/Users/userr/OneDrive/Документы/PROJECTS/roblox/111/RojoTest/assets/fields'
royal=bpy.data.collections['Royal_Field_Asset']
moved=[]
for ob in royal.objects:
 if ob.name.startswith('RF_Laurel_Leaf'):
  points=[ob.matrix_world@v.co for v in ob.data.vertices]
  center=sum(v.x for v in points)/len(points)
  ob.location.x+=.15 if center<24 else -.15
  ob.location.y+=.035;moved.append(ob.name)
for name,dy in [('RF_Goal_Crest',.07),('RF_Crest_Inlay',.09),('RF_Crown',.18)]:
 ob=bpy.data.objects[name];ob.location.y+=dy;ob.location.z-=.065;moved.append(name)
# Add connected rear frame to each goal: two rear posts, rear crossbar and two top ties.
for prefix,colname,center,material,u in [
 ('BF','Backyard_Field_Asset',0,'Backyard_White',5.5/8),
 ('CF','Club_Field_Asset',12,'Club_White_Steel',.5/3),
 ('RF','Royal_Field_Asset',24,'Royal_Gold',.5/4)]:
 collection=bpy.data.collections[colname]
 assert not bpy.data.objects.get(prefix+'_Net_Rear_Frame')
 vs=[];fs=[]
 def rod(a,b,r=.035):
  a,b=Vector(a),Vector(b);axis=(b-a).normalized();uvec=axis.cross(Vector((0,0,1)))
  if uvec.length<.01:uvec=axis.cross(Vector((0,1,0)))
  uvec.normalize();vvec=axis.cross(uvec);off=len(vs);n=8
  for p in [a,b]:
   for k in range(n):vs.append(tuple(p+r*(uvec*math.cos(k*2*math.pi/n)+vvec*math.sin(k*2*math.pi/n))))
  fs.extend([tuple(off+k for k in reversed(range(n))),tuple(off+n+k for k in range(n))])
  fs.extend([(off+k,off+(k+1)%n,off+n+(k+1)%n,off+n+k) for k in range(n)])
 for x in [center-2.73,center+2.73]:
  rod((x,9.56,.62),(x,9.56,3.61))
  rod((x,8.80,3.61),(x,9.56,3.61))
 rod((center-2.73,9.56,3.61),(center+2.73,9.56,3.61))
 mesh=bpy.data.meshes.new(prefix+'_Net_Rear_Frame');mesh.from_pydata(vs,[],fs);mesh.materials.append(bpy.data.materials[material])
 uv=mesh.uv_layers.new(name='PaletteUV')
 for p in mesh.polygons:
  for li in p.loop_indices:uv.data[li].uv=(u,.5)
 mesh.update();ob=bpy.data.objects.new(prefix+'_Net_Rear_Frame',mesh);collection.objects.link(ob)
def export(obs,path):
 bpy.ops.object.select_all(action='DESELECT')
 for ob in obs:ob.select_set(True)
 bpy.context.view_layer.objects.active=obs[0]
 bpy.ops.export_scene.fbx(filepath=path,use_selection=True,object_types={'MESH'},apply_unit_scale=False,axis_forward='-Z',axis_up='Y',path_mode='COPY',embed_textures=True,add_leaf_bones=False)
allfields=[]
for colname,cx,path in [('Backyard_Field_Asset',0,'backyard/backyard-field.fbx'),('Club_Field_Asset',12,'club/club-field.fbx'),('Royal_Field_Asset',24,'royal/royal-field.fbx')]:
 obs=list(bpy.data.collections[colname].objects);allfields+=obs
 for ob in obs:ob.location.x-=cx
 export(obs,root+'/'+path)
 for ob in obs:ob.location.x+=cx
export(allfields,root+'/training-fields.fbx')
bpy.context.view_layer.update()
bpy.ops.wm.save_as_mainfile(filepath=root+'/training-fields.blend')
result={'attached_royal_details':moved,'rear_goal_frames':3}

