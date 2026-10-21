
import bpy, math, os
from mathutils import Vector
out=r'C:/Users/userr/OneDrive/Документы/PROJECTS/roblox/111/RojoTest/assets/fields/backyard'
scene=bpy.data.scenes.new('Backyard_Field_Reference')
bpy.context.window.scene=scene
scene.unit_settings.system='NONE'
asset=bpy.data.collections.new('Backyard_Field_Asset');scene.collection.children.link(asset)
presentation=bpy.data.collections.new('Presentation');scene.collection.children.link(presentation)
colors=[(.76,.83,.87,1),(.24,.57,.08,1),(.29,.64,.10,1),(.38,.21,.09,1),(.48,.29,.12,1),(.94,.97,.91,1),(.12,.48,.23,1),(.025,.035,.04,1)]
image=bpy.data.images.new('Backyard_Palette',width=8,height=1)
image.pixels=[v for c in colors for v in c]
image.filepath_raw=out+'/backyard-palette.png';image.file_format='PNG';image.save();image.pack()
materials=[]
for i,n in enumerate(['Base','Grass','GrassLight','Timber','TimberLight','White','StartPad','BallBlack']):
 m=bpy.data.materials.new('Backyard_'+n);m.diffuse_color=colors[i];m.use_nodes=True
 bs=m.node_tree.nodes.get('Principled BSDF');bs.inputs['Roughness'].default_value=.78
 tex=m.node_tree.nodes.new('ShaderNodeTexImage');tex.image=image;tex.interpolation='Closest'
 m.node_tree.links.new(tex.outputs['Color'],bs.inputs['Base Color']);materials.append(m)
groups={}
def geo(name,vs,fs,mi):
 g=groups.setdefault(name,[[],[],[]]);off=len(g[0]);g[0].extend(vs);g[1].extend([tuple(k+off for k in f) for f in fs]);g[2].extend([mi]*len(fs))
def box(name,c,d,mi):
 x,y,z=c;a,b,h=[v/2 for v in d]
 vs=[(x+sx*a,y+sy*b,z+sz*h) for sx,sy,sz in [(-1,-1,-1),(1,-1,-1),(1,1,-1),(-1,1,-1),(-1,-1,1),(1,-1,1),(1,1,1),(-1,1,1)]]
 geo(name,vs,[(0,3,2,1),(0,1,5,4),(1,2,6,5),(2,3,7,6),(3,0,4,7),(4,5,6,7)],mi)
def rod(name,a,b,r,mi,sides=6):
 a,b=Vector(a),Vector(b);axis=(b-a).normalized();u=axis.cross(Vector((0,0,1)))
 if u.length<.01:u=axis.cross(Vector((0,1,0)))
 u.normalize();v=axis.cross(u);vs=[]
 for p in (a,b):
  for k in range(sides):vs.append(tuple(p+r*(u*math.cos(k*2*math.pi/sides)+v*math.sin(k*2*math.pi/sides))))
 fs=[tuple(reversed(range(sides))),tuple(range(sides,sides*2))]
 fs += [(k,(k+1)%sides,(k+1)%sides+sides,k+sides) for k in range(sides)]
 geo(name,vs,fs,mi)
box('Platform',(0,0,.20),(8.6,21,.40),0)
box('Grass_Bed',(0,0,.51),(8,20,.22),1)
for y in range(10):
 box('Grass_Stripes',(0,-9+y*2,.625),(7.98,1.998,.01),1+y%2)
# low cylinders express studs as actual mesh, spaced regularly
for ix in range(16):
 for iy in range(40):
  x=-3.75+ix*.5;y=-9.75+iy*.5
  if abs(x)<2.55 and -8.85<y<-5.15:continue
  rod('Grass_Studs',(x,y,.634),(x,y,.665),.11,1+(iy//4)%2,8)
for x in [-3.37,3.37]:box('White_Markings',(x,0,.68),(.09,19.2,.035),5)
for y in [-9.55,9.55]:box('White_Markings',(0,y,.68),(6.82,.09,.035),5)
for y in [-3.5,.5,4.5]:box('White_Markings',(0,y,.68),(6.65,.07,.035),5)
box('Start_Pad',(0,-7,.76),(5.1,3.5,.25),6)
rod('Start_Chevron',(-1.4,-7.35,.902),(0,-6.65,.902),.065,5,4)
rod('Start_Chevron',(0,-6.65,.902),(1.4,-7.35,.902),.065,5,4)
for x in [-3.78,3.78]:
 for j in range(10):
  box('Fence_Posts',(x,-8.7+j*1.95,1.27),(.24,.24,1.30),3)
 for z in [.94,1.53]:box('Fence_Rails',(x,.075,z),(.14,17.9,.18),4)
# Goal opening width 5.5, timber and recessed net
for x in [-2.9,2.9]:
 box('Goal_Timber',(x,8.65,2.20),(.34,.40,3.16),4)
box('Goal_Timber',(0,8.65,3.80),(6.15,.42,.36),4)
for x in [-2.73,2.73]:
 rod('Goal_Supports',(x,8.8,3.62),(x,9.55,.70),.055,5)
 rod('Goal_Supports',(x,8.8,.70),(x,9.55,.70),.055,5)
# Back, side and roof rope meshes; all net strands closed six-sided cylinders
for i in range(23):
 x=-2.73+i*(5.46/22)
 rod('Goal_Net',(x,9.56,.72),(x,9.56,3.61),.015,5)
 rod('Goal_Net',(x,8.86,3.61),(x,9.56,3.61),.015,5)
for j in range(13):
 z=.72+j*(2.89/12)
 rod('Goal_Net',(-2.73,9.56,z),(2.73,9.56,z),.015,5)
 for x in [-2.73,2.73]:rod('Goal_Net',(x,8.86,z),(x,9.56,z),.015,5)
for y in [9.05,9.3]:rod('Goal_Net',(-2.73,y,3.61),(2.73,y,3.61),.015,5)
# Construct real truncated icosahedron football: 12 black pentagons,20 white hexagons
bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1,radius=1)
tmp=bpy.context.object
verts=[v.co.copy() for v in tmp.data.vertices];faces=[list(p.vertices) for p in tmp.data.polygons]
edges=set()
for f in faces:
 for k in range(3):
  a,b=f[k],f[(k+1)%3];edges.add((a,b));edges.add((b,a))
coords={(a,b):(verts[a]*2+verts[b])/3 for a,b in edges}
keys=list(coords);ids={e:i for i,e in enumerate(keys)}
ballvs=[tuple(Vector((0,-6.85,1.42))+coords[e].normalized()*.51) for e in keys]
for f in faces:
 a,b,c=f
 geo('Football',ballvs,[(ids[(a,b)],ids[(b,a)],ids[(b,c)],ids[(c,b)],ids[(c,a)],ids[(a,c)])],5)
# do not duplicate vertex array for pentagon part beyond mesh helper simplicity
for a in range(len(verts)):
 neighbors=[e for e in keys if e[0]==a];n=verts[a].normalized()
 u=(coords[neighbors[0]]-verts[a]);u=(u-n*u.dot(n)).normalized();v=n.cross(u)
 neighbors.sort(key=lambda e:math.atan2((coords[e]-verts[a]).dot(v),(coords[e]-verts[a]).dot(u)))
 geo('Football',ballvs,[tuple(ids[e] for e in neighbors)],7)
bpy.data.objects.remove(tmp,do_unlink=True)
objects=[]
for name,(vs,fs,mis) in groups.items():
 mesh=bpy.data.meshes.new('BF_'+name);mesh.from_pydata(vs,[],fs);mesh.materials.clear()
 for m in materials:mesh.materials.append(m)
 for p,mi in zip(mesh.polygons,mis):p.material_index=mi
 uv=mesh.uv_layers.new(name='PaletteUV')
 for p in mesh.polygons:
  for li in p.loop_indices:uv.data[li].uv=((p.material_index+.5)/8,.5)
 mesh.update()
 ob=bpy.data.objects.new('BF_'+name,mesh);asset.objects.link(ob);objects.append(ob)
# presentation camera and illumination in separate export-excluded collection
world=bpy.data.worlds.new('Backyard_Daylight');world.use_nodes=True
world.node_tree.nodes['Background'].inputs[0].default_value=(.60,.78,.94,1)
world.node_tree.nodes['Background'].inputs[1].default_value=.65;scene.world=world
camdata=bpy.data.cameras.new('Backyard_Preview_Camera');cam=bpy.data.objects.new('Backyard_Preview_Camera',camdata);presentation.objects.link(cam)
cam.location=(17,-26,22);cam.rotation_euler=(Vector((0,0,1))-cam.location).to_track_quat('-Z','Y').to_euler()
camdata.type='ORTHO';camdata.ortho_scale=28;scene.camera=cam
lightdata=bpy.data.lights.new('Backyard_Sun','SUN');lightdata.energy=2.5;lightdata.angle=.12
light=bpy.data.objects.new('Backyard_Sun',lightdata);presentation.objects.link(light);light.rotation_euler=(.45,-.6,-.4)
scene.render.engine='BLENDER_EEVEE';scene.render.resolution_x=1400;scene.render.resolution_y=1000;scene.render.resolution_percentage=100
scene.view_settings.view_transform='Standard'
bpy.ops.object.select_all(action='DESELECT')
for ob in objects:ob.select_set(True)
bpy.context.view_layer.objects.active=objects[0]
for area in bpy.context.screen.areas:
 if area.type=='VIEW_3D':
  area.spaces.active.region_3d.view_perspective='CAMERA'
  area.spaces.active.shading.type='MATERIAL'
bpy.context.view_layer.update()
bpy.ops.wm.save_as_mainfile(filepath=out+'/backyard-field.blend')
bpy.ops.export_scene.fbx(filepath=out+'/backyard-field.fbx',use_selection=True,object_types={'MESH'},apply_unit_scale=False,axis_forward='-Z',axis_up='Y',path_mode='COPY',embed_textures=True,add_leaf_bones=False)
result={'scene':scene.name,'objects':len(objects),'triangles':sum(sum(len(p.vertices)-2 for p in o.data.polygons) for o in objects),'bounds':[8.6,21,3.98],'blend':out+'/backyard-field.blend','fbx':out+'/backyard-field.fbx'}

