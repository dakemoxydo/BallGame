"""Build five primitive-based upgrade balls in a second display row."""
import bpy, math, os, ast
from mathutils import Vector
OUT=os.path.dirname(os.path.abspath(__file__))
scene=bpy.context.scene
assert bpy.data.objects.get('Ball_05_MechanicalReactor')
assert not bpy.data.objects.get('Ball_06_PlasmaSatellite')
if bpy.context.object and bpy.context.object.mode!='OBJECT':bpy.ops.object.mode_set(mode='OBJECT')
backup=os.path.join(OUT,'before-second-row.blend')
if not os.path.exists(backup):bpy.ops.wm.save_as_mainfile(filepath=backup,copy=True)
protected={o.name:o.matrix_world.copy() for o in scene.objects if o.type=='MESH' or o.name.startswith('Ball_')}
# Reuse creation helpers only; never execute the earlier scene generator.
source=open(os.path.join(OUT,'add_tiers_3_5.py'),encoding='utf-8').read()
tree=ast.parse(source)
helpers=[n for n in tree.body if isinstance(n,ast.FunctionDef) and n.name in ('mat','begin','adopt','ico','uv','mesh','cube')]
exec(compile(ast.Module(body=helpers,type_ignores=[]),'ball_helpers','exec'))
purple=mat('Satellite_Purple',(.32,.01,.85),rough=.35)
cyan=mat('Satellite_Cyan',(.01,.7,.9),rough=.32)
pink=mat('Satellite_Pink',(.95,.035,.47),rough=.35)
yellow=mat('Thunder_Yellow',(1,.65,.015),rough=.45,emission=.15)
navy=mat('Thunder_Navy',(.035,.025,.20),rough=.5)
gold=mat('Dragon_Gold',(.85,.48,.025),metal=.2,rough=.4)
orange=mat('Dragon_Orange',(1,.22,.015),rough=.45)
red=mat('Dragon_Eyes',(.8,.01,.02),rough=.4)
black=mat('BlackHole_Black',(.004,.004,.009),rough=.8)
diskmat=mat('BlackHole_Orange',(1,.32,.015),rough=.45)
halo=mat('BlackHole_Purple',(.43,.015,.85),rough=.4)
planetblue=mat('WorldCreator_Blue',(.005,.35,.85),rough=.4)
green=mat('WorldCreator_Green',(.06,.7,.06),rough=.5)
moonmat=mat('WorldCreator_Moon',(.55,.6,.65),rough=.6)
glass=bpy.data.materials['CrystalIce_Shell'].copy();glass.name='WorldCreator_ClearShell'

def torus(name,major,minor,material,location=(0,0,0),rotation=(0,0,0)):
    bpy.ops.mesh.primitive_torus_add(major_segments=48,minor_segments=10,major_radius=major,minor_radius=minor)
    o=adopt(bpy.context.object,name,material);o.location=location;o.rotation_euler=rotation
    for p in o.data.polygons:p.use_smooth=True
    return o
def cone(name,location,radius,depth,material,direction=(0,0,1)):
    bpy.ops.mesh.primitive_cone_add(vertices=8,radius1=radius,radius2=0,depth=depth)
    o=adopt(bpy.context.object,name,material);o.location=location
    o.rotation_euler=Vector(direction).to_track_quat('Z','Y').to_euler();return o
def sphere(name,radius,material,location=(0,0,0),scale=None):
    o=uv(name,radius,material);o.location=location
    if scale:o.scale=scale
    return o
reports=[]
def finish(tier):
    root.location.y=4.6
    bpy.context.view_layer.update()
    lowest=min((o.matrix_world@v.co).z for o in parts for v in o.data.vertices)
    root.location.z+=.22-lowest
    stand=bpy.data.objects['Display_Pedestal'].copy();stand.data=stand.data.copy()
    stand.name='Display_Pedestal_%02d'%tier;collection.objects.link(stand)
    stand.location=(root.location.x,root.location.y,.11)
    root['tier']=tier
    bpy.context.view_layer.update()
    reports.append({'name':root.name,'center':list(root.location),'meshes':len(parts)})

begin('Ball_06_PlasmaSatellite',0)
sphere('Satellite_Core',1.03,purple)
torus('Satellite_Orbit_A',1.30,.085,cyan,rotation=(.65,.55,0))
torus('Satellite_Orbit_B',1.30,.085,cyan,rotation=(-.65,-.55,0))
for i,p in enumerate([(-1.13,-.48,.40),(.84,-.70,.72),(.95,-.58,-.63)]):sphere('Satellite_Moon_%d'%i,.20,pink,p)
finish(6)

begin('Ball_07_ThunderSplit',3.2)
sphere('Thunder_Core',1.02,yellow)
for index,direction in enumerate([(1,0,0),(-1,0,0),(0,0,1),(0,0,-1)]):
    n=Vector(direction);a=Vector((0,1,0));b=n.cross(a)
    verts=[tuple(n*1.30)];faces=[];rings=4;segments=12
    for j in range(1,rings+1):
        angle=.64*j/rings
        for i in range(segments):
            phase=2*math.pi*i/segments
            p=n*math.cos(angle)+(a*math.cos(phase)+b*math.sin(phase))*math.sin(angle)
            verts.append(tuple(p*1.30))
    for i in range(segments):faces.append((0,1+i,1+(i+1)%segments))
    for j in range(rings-1):
        for i in range(segments):
            v=1+j*segments+i;w=1+j*segments+(i+1)%segments
            faces.append((v,v+segments,w+segments,w))
    o=mesh('Thunder_Shell_%d'%index,verts,faces,navy)
    mod=o.modifiers.new('Shell thickness','SOLIDIFY');mod.thickness=.10;mod.offset=-1
for index,points in enumerate([[(-.72,-1.04,.64),(-.90,-1.04,.25),(-.61,-1.04,.05),(-.78,-1.04,-.45)],[(.52,-1.04,.92),(.40,-1.04,.55),(.68,-1.04,.34),(.53,-1.04,.02)],[(.79,-1.01,-.35),(.61,-1.01,-.61),(.85,-1.01,-.75),(.60,-1.01,-.98)]]):
    for j in range(3):
        start,end=Vector(points[j]),Vector(points[j+1]);delta=end-start
        o=cube('Thunder_Bolt_%d_%d'%(index,j),(start+end)/2,(.115,.10,delta.length+.045),yellow,.008)
        o.rotation_euler=delta.to_track_quat('Z','Y').to_euler()
finish(7)

begin('Ball_08_DragonSun',6.4)
sphere('DragonSun_Core',1.06,orange)
torus('DragonSun_Body',1.17,.14,gold,rotation=(math.pi/2,0,0))
cube('DragonSun_Head',(0,-.20,1.20),(.68,.56,.40),gold,.035)
cube('DragonSun_Muzzle',(0,-.52,1.07),(.40,.33,.23),gold,.025)
for i,x in enumerate((-.23,.23)):
    cone('DragonSun_Horn_%d'%i,(x,-.16,1.59),.095,.42,gold)
    sphere('DragonSun_Eye_%d'%i,.075,red,(x,-.491,1.23),(.95,.48,.95))
cone('DragonSun_Tail',(.74,-.06,-.87),.19,.43,gold,(1,0,-.3))
finish(8)

begin('Ball_09_BlackHole',9.6)
sphere('BlackHole_Core',1.02,black)
verts=[];faces=[];steps=64
for z in (-.045,.045):
    for radius in (1.10,1.57):
        for i in range(steps):
            t=2*math.pi*i/steps;verts.append((radius*math.cos(t),radius*math.sin(t),z))
for i in range(steps):
    j=(i+1)%steps
    faces.extend([(i,j,steps+j,steps+i),(2*steps+i,3*steps+i,3*steps+j,2*steps+j),
        (i,2*steps+i,2*steps+j,j),(steps+i,steps+j,3*steps+j,3*steps+i)])
o=mesh('BlackHole_AccretionDisk',verts,faces,diskmat);o.rotation_euler=(.33,-.25,0)
torus('BlackHole_VioletHalo',1.22,.055,halo,rotation=(math.pi/2,.20,0))
finish(9)

begin('Ball_10_WorldCreator',12.8)
sphere('WorldCreator_ClearSphere',1.18,glass)
sphere('WorldCreator_Planet',.68,planetblue,(0,-.1,0))
for i,(p,scale) in enumerate([((-.30,-.66,.24),(.22,.055,.31)),((.35,-.63,.1),(.17,.055,.27)),((-.03,-.70,-.31),(.22,.055,.21))]):
    sphere('WorldCreator_Continent_%d'%i,1,green,p,scale)
sphere('WorldCreator_Moon',.16,moonmat,(.75,-.15,.47))
torus('WorldCreator_GoldRing',1.30,.045,gold)
for i,(p,direction) in enumerate([((0,0,1.43),(0,0,1)),((-.86,0,1.02),(-.4,0,1)),((.86,0,1.02),(.4,0,1))]):
    cone('WorldCreator_Crown_%d'%i,p,.16,.42,gold,direction)
finish(10)

bpy.context.view_layer.update()
for name,m in protected.items():assert all(abs(bpy.data.objects[name].matrix_world[i][j]-m[i][j])<1e-6 for i in range(4) for j in range(4)),name
camera=scene.camera;target=Vector((6.4,2.25,1.0))
camera.location=target+Vector((0,-16,13));camera.rotation_euler=(target-camera.location).to_track_quat('-Z','Y').to_euler();camera.data.ortho_scale=17.3
scene.render.resolution_x=2200;scene.render.resolution_y=1200;scene.cycles.samples=48
scene.render.filepath=os.path.join(OUT,'ten-balls-preview.png')
data=bpy.data.lights.new('SecondRow_Softbox','AREA');data.energy=1800;data.shape='RECTANGLE';data.size=14;data.size_y=5
light=bpy.data.objects.new(data.name,data);scene.collection.objects.link(light);light.location=(6.4,3,8)
light.rotation_euler=(Vector((6.4,4.6,1))-light.location).to_track_quat('-Z','Y').to_euler()
for area in bpy.context.screen.areas:
    if area.type=='VIEW_3D':area.spaces.active.region_3d.view_perspective='CAMERA'
bpy.ops.object.select_all(action='DESELECT');root.select_set(True);bpy.context.view_layer.objects.active=root
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(OUT,'ball-display.blend'))
result={'added':reports,'first_row_preserved':True,'saved':bpy.data.filepath}
