"""Add three simple upgrade balls to the existing Blender display."""
import bpy, math, os, shutil
from mathutils import Vector
OUT=os.path.dirname(os.path.abspath(__file__))
scene=bpy.context.scene
assert bpy.data.objects.get('Ball_02_SteelImpact')
assert not any(bpy.data.objects.get(n) for n in ('Ball_03_CrystalIce','Ball_04_VolcanoHeart','Ball_05_MechanicalReactor'))
if bpy.context.object and bpy.context.object.mode!='OBJECT': bpy.ops.object.mode_set(mode='OBJECT')
backup=os.path.join(OUT,'before-tiers-3-5.blend')
if not os.path.exists(backup): bpy.ops.wm.save_as_mainfile(filepath=backup,copy=True)
protected={o.name:o.matrix_world.copy() for o in scene.objects if o.type=='MESH' or o.name.startswith('Ball_')}

def mat(name,color,metal=0,rough=.4,emission=0,transmission=0):
    m=bpy.data.materials.new(name); m.diffuse_color=(*color,1); m.use_nodes=True
    s=m.node_tree.nodes.get('Principled BSDF')
    s.inputs['Base Color'].default_value=(*color,1)
    s.inputs['Metallic'].default_value=metal; s.inputs['Roughness'].default_value=rough
    s.inputs['Emission Color'].default_value=(*color,1); s.inputs['Emission Strength'].default_value=emission
    s.inputs['Transmission Weight'].default_value=transmission
    s.inputs['IOR'].default_value=1.12 if transmission else 1.45
    return m
ice=mat('CrystalIce_Shell',(.075,.62,.95),rough=.3)
ice_shader=ice.node_tree.nodes.get('Principled BSDF')
ice_shader.inputs['Alpha'].default_value=.26
ice_shader.inputs['Emission Color'].default_value=(.06,.48,.85,1)
ice_shader.inputs['Emission Strength'].default_value=.22
ice.diffuse_color=(.075,.62,.95,.26)
ice.surface_render_method='BLENDED'
ice.use_transparent_shadow=True
blue=mat('CrystalIce_Core',(.015,.32,.95),rough=.25,emission=.55)
shardmat=mat('CrystalIce_Points',(.08,.7,.95),rough=.3)
rock=mat('VolcanoHeart_Plates',(.045,.038,.043),rough=.75)
lava=mat('VolcanoHeart_Lava',(1,.15,.006),rough=.4,emission=2.5)
armor=mat('Reactor_Armor',(.11,.135,.17),metal=.35,rough=.4)
cyan=mat('Reactor_CyanCore',(.005,.65,.9),rough=.24,emission=1.5)
orange=mat('Reactor_OrangeAccents',(1,.32,.005),rough=.4)

def begin(name,x):
    global collection,root,parts
    collection=bpy.data.collections.new(name+'_Assets'); scene.collection.children.link(collection)
    root=bpy.data.objects.new(name,None); collection.objects.link(root)
    root.location=(x,0,1.42); root.empty_display_size=.15
    parts=[]
    return root
def adopt(o,name,material):
    o.name=name
    for c in list(o.users_collection): c.objects.unlink(o)
    collection.objects.link(o); o.parent=root
    o.data.materials.append(material); parts.append(o)
    return o
def ico(name,radius,material,sub=2):
    bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=sub,radius=radius)
    return adopt(bpy.context.object,name,material)
def uv(name,radius,material):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=48,ring_count=24,radius=radius)
    o=adopt(bpy.context.object,name,material)
    for p in o.data.polygons:p.use_smooth=True
    return o
def mesh(name,verts,faces,material):
    d=bpy.data.meshes.new(name+'_Mesh'); d.from_pydata(verts,[],faces); d.update()
    o=bpy.data.objects.new(name,d); collection.objects.link(o); o.parent=root
    d.materials.append(material); parts.append(o); return o
def cube(name,location,scale,material,bevel=.04):
    bpy.ops.mesh.primitive_cube_add(size=1)
    o=adopt(bpy.context.object,name,material)
    o.location=location
    for v in o.data.vertices: v.co.x*=scale[0];v.co.y*=scale[1];v.co.z*=scale[2]
    if bevel:
        mod=o.modifiers.new('Large soft edges','BEVEL');mod.width=bevel;mod.segments=2
        o.modifiers.new('Weighted normals','WEIGHTED_NORMAL')
    return o
def finish(tier):
    bpy.context.view_layer.update()
    lowest=min((o.matrix_world@v.co).z for o in parts for v in o.data.vertices)
    root.location.z+=.22-lowest
    stand=bpy.data.objects['Display_Pedestal'].copy();stand.data=stand.data.copy()
    stand.name='Display_Pedestal_%02d'%tier;collection.objects.link(stand)
    stand.location=(root.location.x,0,.11)
    root['tier']=tier
    bpy.context.view_layer.update()
    return {'name':root.name,'center':list(root.location),'mesh_count':len(parts),'contact_z':min((o.matrix_world@v.co).z for o in parts for v in o.data.vertices)}

reports=[]
begin('Ball_03_CrystalIce',6.4)
ico('CrystalIce_FacetedShell',1.19,ice)
verts=[(0,0, .72),(0,0,-.72),(.32,0,0),(0,.32,0),(-.32,0,0),(0,-.32,0)]
faces=[(0,2,3),(0,3,4),(0,4,5),(0,5,2),(1,3,2),(1,4,3),(1,5,4),(1,2,5)]
mesh('CrystalIce_CentralDiamond',verts,faces,blue)
for index,direction in enumerate([(-.65,-.1,.76),(.85,.15,.3),(-.7,-.55,-.3)]):
    direction=Vector(direction).normalized()
    bpy.ops.mesh.primitive_cone_add(vertices=5,radius1=.19,radius2=0,depth=.45)
    o=adopt(bpy.context.object,'CrystalIce_Point_%d'%index,shardmat)
    o.location=direction*1.22;o.rotation_euler=direction.to_track_quat('Z','Y').to_euler()
reports.append(finish(3))

begin('Ball_04_VolcanoHeart',9.6)
uv('VolcanoHeart_OrangeCore',1.0,lava)
# The dual of an icosahedron produces twelve broad pentagonal armor plates.
bpy.ops.mesh.primitive_ico_sphere_add(subdivisions=1,radius=1)
template=bpy.context.object
normals=[v.co.normalized() for v in template.data.vertices]
centers=[sum((template.data.vertices[i].co for i in p.vertices),Vector())/len(p.vertices) for p in template.data.polygons]
for index,n in enumerate(normals):
    corners=[centers[p.index].normalized() for p in template.data.polygons if index in p.vertices]
    tangent=n.cross(Vector((0,0,1)))
    if tangent.length<.1:tangent=n.cross(Vector((0,1,0)))
    tangent.normalize();bitangent=n.cross(tangent)
    corners.sort(key=lambda c:math.atan2(c.dot(bitangent),c.dot(tangent)))
    outer=[(n*.2+c*.8).normalized()*1.205 for c in corners]
    inner=[v.normalized()*1.105 for v in outer]
    verts=[tuple(v) for v in outer+inner]
    count=len(corners)
    faces=[tuple(range(count)),tuple(reversed(range(count,2*count)))]
    faces += [(i,(i+1)%count,(i+1)%count+count,i+count) for i in range(count)]
    o=mesh('VolcanoHeart_Plate_%02d'%index,verts,faces,rock)
    bevel=o.modifiers.new('Chunky plate bevel','BEVEL');bevel.width=.025;bevel.segments=1
    o.modifiers.new('Weighted plate normals','WEIGHTED_NORMAL')
template_mesh=template.data;bpy.data.objects.remove(template,do_unlink=True);bpy.data.meshes.remove(template_mesh)
reports.append(finish(4))

begin('Ball_05_MechanicalReactor',12.8)
uv('Reactor_GlowingSphere',1.11,cyan)
for quadrant in range(4):
    for upper in (True,False):
        verts=[];faces=[];cols=10;rows=7
        for j in range(rows+1):
            lat=.28+(1.5-.28)*j/rows
            if not upper:lat=-lat
            for i in range(cols+1):
                lon=quadrant*math.pi/2+.065+(math.pi/2-.13)*i/cols
                verts.append((1.205*math.cos(lat)*math.cos(lon),1.205*math.cos(lat)*math.sin(lon),1.205*math.sin(lat)))
        for j in range(rows):
            for i in range(cols):
                a=j*(cols+1)+i;f=(a,a+1,a+cols+2,a+cols+1)
                faces.append(f if upper else tuple(reversed(f)))
        o=mesh('Reactor_Plate_%d_%s'%(quadrant,upper),verts,faces,armor)
        for p in o.data.polygons:p.use_smooth=True
        mod=o.modifiers.new('Armor thickness','SOLIDIFY');mod.thickness=.055;mod.offset=-1
        mod=o.modifiers.new('Armor soft edges','BEVEL');mod.width=.015;mod.segments=2
for index in range(8):
    if index in (5,6): continue
    angle=2*math.pi*index/8+math.pi/8
    o=cube('Reactor_BeltBlock_%02d'%index,(1.14*math.cos(angle),1.14*math.sin(angle),0),(.20,.48,.30),armor)
    o.rotation_euler.z=angle
bpy.ops.mesh.primitive_torus_add(major_segments=48,minor_segments=12,major_radius=.46,minor_radius=.075)
rim=adopt(bpy.context.object,'Reactor_FrontWindowRim',armor);rim.location=(0,-1.085,.05);rim.rotation_euler.x=math.pi/2
for p in rim.data.polygons:p.use_smooth=True
window=uv('Reactor_FrontLens',1,cyan);window.location=(0,-1.105,.05);window.scale=(.395,.13,.395)
for index,z in enumerate((.72,-.72)):
    o=cube('Reactor_OrangeStripe_%d'%index,(.52,-.79,z),(.30,.04,.09),orange,.015)
    o.rotation_euler.y=math.radians(20 if index==0 else -20)
reports.append(finish(5))

for name,matrix in protected.items():
    assert all(abs(bpy.data.objects[name].matrix_world[i][j]-matrix[i][j])<1e-6 for i in range(4) for j in range(4)),name
camera=scene.camera;target=Vector((6.4,0,1.35))
camera.location=target+Vector((0,-13,3.6));camera.rotation_euler=(target-camera.location).to_track_quat('-Z','Y').to_euler()
camera.data.ortho_scale=16.3
scene.render.resolution_x=2200;scene.render.resolution_y=650;scene.cycles.samples=48
scene.render.filepath=os.path.join(OUT,'five-balls-preview.png')
# A broad additional area light keeps the added end of the display readable.
data=bpy.data.lights.new('Display_UpgradesSoftbox','AREA');data.energy=1300;data.shape='RECTANGLE';data.size=10;data.size_y=4
light=bpy.data.objects.new(data.name,data);scene.collection.objects.link(light);light.location=(9,-4,7)
light.rotation_euler=(Vector((9,0,1))-light.location).to_track_quat('-Z','Y').to_euler()
for area in bpy.context.screen.areas:
    if area.type=='VIEW_3D':area.spaces.active.region_3d.view_perspective='CAMERA'
bpy.ops.object.select_all(action='DESELECT')
root.select_set(True);bpy.context.view_layer.objects.active=root
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(OUT,'ball-display.blend'))
result={'saved':bpy.data.filepath,'added':reports,'first_two_preserved':True,'backup':backup}
