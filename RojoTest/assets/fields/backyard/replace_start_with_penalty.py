
import bpy,bmesh,math
from mathutils import Vector
out=r'C:/Users/userr/OneDrive/Документы/PROJECTS/roblox/111/RojoTest/assets/fields/backyard'
scene=bpy.context.scene
assert scene.name=='Backyard_Field_Reference'
field=bpy.data.collections['Backyard_Field_Asset']
ball=bpy.data.objects['BF_Football']
for name in ['BF_Start_Pad','BF_Start_Chevron']:
 ob=bpy.data.objects.get(name)
 if ob:bpy.data.objects.remove(ob,do_unlink=True)
# Independent ball collection, centered local mesh origin for rotation/physics
ballcol=bpy.data.collections.get('Football_Asset') or bpy.data.collections.new('Football_Asset')
if ballcol.name not in scene.collection.children:scene.collection.children.link(ballcol)
for c in list(ball.users_collection):c.objects.unlink(ball)
ballcol.objects.link(ball)
if not ball.get('centered_origin'):
 center=Vector((0,-6.85,1.42))
 for v in ball.data.vertices:v.co-=center
 ball['centered_origin']=True
ball.location=(0,-6.85,.659-min(v.co.z for v in ball.data.vertices))
# White penalty dot just above grass, under ball
bpy.ops.mesh.primitive_cylinder_add(vertices=32,radius=.28,depth=.024,location=(0,-6.85,.647))
dot=bpy.context.object;dot.name='BF_Penalty_Spot'
for c in list(dot.users_collection):c.objects.unlink(dot)
field.objects.link(dot)
mat=bpy.data.materials['Backyard_White'];dot.data.materials.clear();dot.data.materials.append(mat)
uv=dot.data.uv_layers.active or dot.data.uv_layers.new(name='PaletteUV')
for l in uv.data:l.uv=(5.5/8,.5)
# Restore regular grass studs in the former pad area, leaving spot and ball base clear
studs=bpy.data.objects['BF_Grass_Studs']
bm=bmesh.new();bm.from_mesh(studs.data)
for ix in range(16):
 for iy in range(40):
  x=-3.75+ix*.5;y=-9.75+iy*.5
  if not(abs(x)<2.55 and -8.85<y<-5.15):continue
  if math.hypot(x,y+6.85)<.48:continue
  ring=[]
  for z in [.634,.665]:
   ring.append([bm.verts.new((x+.11*math.cos(k*math.pi/4),y+.11*math.sin(k*math.pi/4),z)) for k in range(8)])
  faces=[bm.faces.new(list(reversed(ring[0]))),bm.faces.new(ring[1])]
  for k in range(8):faces.append(bm.faces.new([ring[0][k],ring[0][(k+1)%8],ring[1][(k+1)%8],ring[1][k]]))
  for f in faces:f.material_index=1+(iy//4)%2
bm.to_mesh(studs.data);bm.free()
uv=studs.data.uv_layers.active
for p in studs.data.polygons:
 for i in p.loop_indices:uv.data[i].uv=((p.material_index+.5)/8,.5)
studs.data.update()
def export(items,path):
 bpy.ops.object.select_all(action='DESELECT')
 for ob in items:ob.select_set(True)
 bpy.context.view_layer.objects.active=items[0]
 bpy.ops.export_scene.fbx(filepath=path,use_selection=True,object_types={'MESH'},apply_unit_scale=False,axis_forward='-Z',axis_up='Y',path_mode='COPY',embed_textures=True,add_leaf_bones=False)
export(list(field.objects),out+'/backyard-field.fbx')
position=ball.location.copy();ball.location=(0,0,0)
export([ball],out+'/football.fbx')
ball.location=position
export(list(field.objects)+[ball],out+'/backyard-field-with-ball.fbx')
bpy.context.view_layer.update()
bpy.ops.wm.save_as_mainfile(filepath=out+'/backyard-field.blend')
result={'field_meshes':len(field.objects),'ball_collection':ballcol.name,'ball_local_center':[sum(v.co[i] for v in ball.data.vertices)/len(ball.data.vertices) for i in range(3)],'ball_bottom':min((ball.matrix_world@v.co).z for v in ball.data.vertices),'spot_top':.659,'files':['backyard-field.blend','backyard-field.fbx','football.fbx','backyard-field-with-ball.fbx']}

