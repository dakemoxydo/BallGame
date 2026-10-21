"""Replace only tiers 6–9 with the approved faceted Roblox designs."""
import bpy, math, os, ast
from mathutils import Vector
OUT=os.path.dirname(os.path.abspath(__file__))
scene=bpy.context.scene
names=['Ball_06_PlasmaSatellite','Ball_07_ThunderSplit','Ball_08_DragonSun','Ball_09_BlackHole']
roots=[bpy.data.objects[n] for n in names]
assert all(o.name in scene.objects for o in roots)
if bpy.context.object and bpy.context.object.mode!='OBJECT':bpy.ops.object.mode_set(mode='OBJECT')
backup=os.path.join(OUT,'before-low-poly-6-9.blend')
if not os.path.exists(backup):bpy.ops.wm.save_as_mainfile(filepath=backup,copy=True)
targets=set(roots)
for r in roots:targets.update(r.children_recursive)
protected={o.name:(o.matrix_world.copy(),len(o.data.vertices) if o.type=='MESH' else None) for o in scene.objects if o not in targets}
source=open(os.path.join(OUT,'add_tiers_3_5.py'),encoding='utf-8').read()
helper_nodes=[n for n in ast.parse(source).body if isinstance(n,ast.FunctionDef) and n.name in ('adopt','ico','mesh','cube','mat')]
exec(compile(ast.Module(body=helper_nodes,type_ignores=[]),'ball_helpers','exec'))
def material(name,color):
    m=mat('LowPoly_'+name,color,rough=.72)
    m.node_tree.nodes.get('Principled BSDF').inputs['Specular IOR Level'].default_value=.12
    return m
purple=material('PlasmaPurple',(.28,.014,.68));cyan=material('OrbitCyan',(.008,.5,.75))
pink=material('SatellitePink',(.85,.018,.35));yellow=material('ThunderYellow',(.83,.48,.005))
navy=material('ThunderNavy',(.024,.025,.16));gold=material('DragonGold',(.78,.40,.025))
thunder_core=material('ThunderCoreGolden',(.65,.34,.005))
orange=material('SolarOrange',(.9,.16,.008));red=material('DragonEyes',(.7,.003,.005))
black=material('VoidCharcoal',(.017,.019,.027));diskmat=material('DiskOrange',(.95,.23,.008))
disktone=material('DiskOrangeAlternate',(.8,.145,.005));halo=material('VoidPurple',(.35,.015,.75))
records=[]
def start(root_obj):
    global root,collection,parts
    root=root_obj;collection=root.users_collection[0];parts=[]
    # Only replace the explicitly requested four balls' component meshes.
    for o in list(root.children_recursive):
        data=o.data if o.type=='MESH' else None
        bpy.data.objects.remove(o,do_unlink=True)
        if data and data.users==0:bpy.data.meshes.remove(data)
def ring(name,radius,width,material,rotation=(0,0,0),location=(0,0,0),segments=12):
    bpy.ops.mesh.primitive_torus_add(major_segments=segments,minor_segments=4,major_radius=radius,minor_radius=width)
    o=adopt(bpy.context.object,name,material);o.rotation_euler=rotation;o.location=location
    return o
def cone(name,location,radius,depth,material,direction=(0,0,1)):
    bpy.ops.mesh.primitive_cone_add(vertices=4,radius1=radius,radius2=0,depth=depth)
    o=adopt(bpy.context.object,name,material);o.location=location
    o.rotation_euler=Vector(direction).to_track_quat('Z','Y').to_euler();return o
def diamond(name,location):
    verts=[(0,0,.27),(0,0,-.27),(.20,0,0),(0,.20,0),(-.20,0,0),(0,-.20,0)]
    faces=[(0,2,3),(0,3,4),(0,4,5),(0,5,2),(1,3,2),(1,4,3),(1,5,4),(1,2,5)]
    o=mesh(name,verts,faces,pink);o.location=location
def finish(tier):
    bpy.context.view_layer.update()
    stand=bpy.data.objects['Display_Pedestal_%02d'%tier]
    top=stand.location.z+stand.dimensions.z/2
    lowest=min((o.matrix_world@v.co).z for o in parts for v in o.data.vertices)
    root.location.z+=top-lowest
    bpy.context.view_layer.update()
    triangles=0
    for o in parts:o.data.calc_loop_triangles();triangles+=len(o.data.loop_triangles)
    root['visual_revision']='low-poly-roblox-v2'
    records.append({'ball':root.name,'triangles':triangles,'meshes':len(parts),'x':root.location.x,'y':root.location.y})

start(roots[0])
ico('Satellite_Core',1.0,purple,2)
ring('Satellite_Orbit_A',1.25,.085,cyan,(.80,.45,.1))
ring('Satellite_Orbit_B',1.25,.085,cyan,(-.80,-.45,-.1))
for i,p in enumerate([(-1.13,-.38,.35),(.77,-.56,.79),(.89,-.50,-.74)]):diamond('Satellite_Diamond_%d'%i,p)
finish(6)

start(roots[1])
ico('Thunder_Core',1.0,thunder_core,2)
for index,axis in enumerate([(0,-.65,.8),(-.8,-.65,0),(.8,-.65,0),(0,-.65,-.8)]):
    n=Vector(axis).normalized();a=Vector((0,-1,0));a=(a-n*a.dot(n)).normalized();b=n.cross(a)
    sides=5;verts=[]
    for inner in (False,True):
        for i in range(sides):
            t=2*math.pi*i/sides
            p=n*(1.12 if not inner else .97)+(a*math.cos(t)+b*math.sin(t))*(.60 if not inner else .53)
            verts.append(tuple(p))
    verts.append(tuple(n*1.25))
    faces=[(2*sides,i,(i+1)%sides) for i in range(sides)]
    faces.append(tuple(reversed(range(sides,2*sides))))
    faces.extend((i,i+sides,(i+1)%sides+sides,(i+1)%sides) for i in range(sides))
    mesh('Thunder_Armor_%d'%index,verts,faces,navy)
def bolt(name,outline,y):
    count=len(outline);verts=[(x,plane,z) for plane in (y,y+.09) for x,z in outline]
    faces=[tuple(range(count)),tuple(reversed(range(count,2*count)))]
    faces.extend((i,(i+1)%count,(i+1)%count+count,i+count) for i in range(count))
    return mesh(name,verts,faces,yellow)
bolt('Thunder_Lightning_Left',[(-.58,.71),(-.75,.39),(-.45,.13),(-.67,-.41),(-.51,-.48),(-.26,.17),(-.55,.43),(-.42,.65)],-1.02)
bolt('Thunder_Lightning_Upper',[(.33,1.05),(.23,.63),(.54,.40),(.37,.04),(.53,-.03),(.75,.47),(.43,.70),(.50,1.05)],-1.0)
bolt('Thunder_Lightning_Lower',[(.74,-.30),(.55,-.53),(.78,-.72),(.63,-.92),(.77,-1.0),(.97,-.71),(.73,-.53),(.89,-.38)],-.92)
finish(7)

start(roots[2])
ico('DragonSun_Core',1.03,orange,2)
ring('DragonSun_AngularBody',1.10,.15,gold,(math.pi/2,0,0),(0,-.30,0),12)
# Three tapered cross-sections form a wedge muzzle and broad geometric cheeks.
verts=[]
for y,w,low,high in [(.03,.39,.93,1.26),(-.33,.33,.92,1.23),(-.70,.16,.85,1.05)]:
    verts.extend([(-w,y,low),(w,y,low),(w,y,high),(-w,y,high)])
faces=[(0,3,2,1),(8,9,10,11)]
for j in range(2):
    for i in range(4):faces.append((j*4+i,j*4+(i+1)%4,(j+1)*4+(i+1)%4,(j+1)*4+i))
mesh('DragonSun_WedgeHead',verts,faces,gold)
for i,x in enumerate((-.25,.25)):
    cone('DragonSun_TriangularHorn_%d'%i,(x,-.02,1.46),.12,.45,gold,(x*.5,0,1))
    eye=cube('DragonSun_RectangularEye_%d'%i,(x,-.53,1.14),(.145,.035,.13),red,0)
    eye.rotation_euler.y=math.radians(-12 if x<0 else 12)
for i,t in enumerate((math.radians(52),math.radians(24),math.radians(-5),math.radians(-34))):
    n=Vector((math.cos(t),0,math.sin(t)))
    cone('DragonSun_DorsalFin_%d'%i,n*1.31+Vector((0,-.3,0)),.14,.36,gold,n)
mesh('DragonSun_WedgeTail',[(.61,-.50,-.70),(1.01,-.5,-.68),(.79,-.50,-1.05),(.61,-.12,-.70),(1.01,-.12,-.68),(.79,-.12,-1.05)],[(0,1,2),(5,4,3),(0,3,4,1),(1,4,5,2),(2,5,3,0)],gold)
finish(8)

start(roots[3])
ico('BlackHole_Core',.98,black,2)
segments=12;verts=[];faces=[]
for z in (-.045,.045):
    for r in (1.065,1.46):
        for i in range(segments):
            t=2*math.pi*i/segments;verts.append((r*math.cos(t),r*math.sin(t),z))
for i in range(segments):
    j=(i+1)%segments
    faces.extend([(i,j,segments+j,segments+i),(2*segments+i,3*segments+i,3*segments+j,2*segments+j),
        (i,2*segments+i,2*segments+j,j),(segments+i,segments+j,3*segments+j,3*segments+i)])
o=mesh('BlackHole_PolygonDisk',verts,faces,diskmat);o.data.materials.append(disktone)
for p in o.data.polygons:p.material_index=(p.index//4)%2
o.rotation_euler=(.28,-.28,0)
ring('BlackHole_PolygonHalo',1.18,.065,halo,(math.pi/2,.22,0),segments=12)
finish(9)

for name,(matrix,count) in protected.items():
    o=bpy.data.objects[name]
    assert all(abs(o.matrix_world[i][j]-matrix[i][j])<1e-6 for i in range(4) for j in range(4)),name
    if count is not None:assert len(o.data.vertices)==count,name
# A second scene makes the four revised designs easy to inspect independently.
preview=bpy.data.scenes.new('LowPoly_6_9_Review');preview.world=scene.world
for r in roots:
    preview.collection.objects.link(r)
    for o in r.children_recursive:preview.collection.objects.link(o)
for tier in range(6,10):preview.collection.objects.link(bpy.data.objects['Display_Pedestal_%02d'%tier])
for o in scene.objects:
    if o.type=='LIGHT' or o.name=='Studio_Floor':preview.collection.objects.link(o)
camera_data=bpy.data.cameras.new('LowPoly_ReviewCamera');camera=bpy.data.objects.new(camera_data.name,camera_data)
preview.collection.objects.link(camera)
target=Vector((4.8,4.6,1.3));camera.location=target+Vector((0,-12,3.6));camera.rotation_euler=(target-camera.location).to_track_quat('-Z','Y').to_euler()
camera_data.type='ORTHO';camera_data.ortho_scale=12.7;preview.camera=camera
preview.render.engine='CYCLES';preview.cycles.samples=48;preview.cycles.use_denoising=True
preview.render.resolution_x=1800;preview.render.resolution_y=720;preview.render.resolution_percentage=100
preview.view_settings.view_transform='Standard';preview.view_settings.look='None';preview.view_settings.exposure=-1.1
preview.render.filepath=os.path.join(OUT,'low-poly-6-9-preview.png')
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(OUT,'ball-display.blend'))
result={'revised':records,'other_models_preserved':True,'backup':backup,'saved':bpy.data.filepath,'review_scene':preview.name}
