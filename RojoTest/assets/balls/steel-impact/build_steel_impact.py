"""Add the simplified second ball beside the existing starter ball via Blender MCP."""
import bpy
import math
import os
from mathutils import Vector

OUT = os.path.dirname(os.path.abspath(__file__))
os.makedirs(OUT, exist_ok=True)
scene = bpy.context.scene
first = bpy.data.objects.get('Ball_01_RubberRookie')
assert first and first.name in scene.objects, 'Open the starter ball display first.'
assert not bpy.data.objects.get('Ball_02_SteelImpact'), 'Second ball already exists; do not duplicate.'
if bpy.context.object and bpy.context.object.mode != 'OBJECT':
    bpy.ops.object.mode_set(mode='OBJECT')
first_transform = first.matrix_world.copy()
first_vertex_count = len(first.data.vertices)
collection = bpy.data.collections.new('SteelImpact_Assets')
scene.collection.children.link(collection)

def move_to(obj):
    for previous in list(obj.users_collection):
        previous.objects.unlink(obj)
    collection.objects.link(obj)

def make_material(name, color, metallic, roughness):
    mat = bpy.data.materials.new(name)
    mat.diffuse_color = (*color, 1)
    mat.use_nodes = True
    shader = mat.node_tree.nodes.get('Principled BSDF')
    shader.inputs['Base Color'].default_value = (*color, 1)
    shader.inputs['Metallic'].default_value = metallic
    shader.inputs['Roughness'].default_value = roughness
    return mat

steel = make_material('SteelImpact_SatinSteel', (.38,.42,.47), .82, .31)
red = make_material('SteelImpact_RedPaint', (.55,.012,.019), .32, .37)
dark = make_material('SteelImpact_RecessedSeams', (.022,.027,.034), .4, .55)
root = bpy.data.objects.new('Ball_02_SteelImpact', None)
collection.objects.link(root)
root.empty_display_type = 'PLAIN_AXES'
root.empty_display_size = .18
root.location = first.location + Vector((3.2,0,0))
root.rotation_euler = tuple(math.radians(a) for a in (-4,10,-12))
root['tier'] = 2
root['description'] = 'Simple steel panels, broad red belt, eight round rivets.'

bpy.ops.mesh.primitive_uv_sphere_add(segments=48, ring_count=24, radius=1.176)
core = bpy.context.object
core.name = 'SteelImpact_SeamCore'
move_to(core)
core.parent = root
core.location = (0,0,0)
core.data.materials.append(dark)
for polygon in core.data.polygons:
    polygon.use_smooth = True
parts = [core]

def panel(name, start_lon, end_lon, start_lat, end_lat, rows, mat):
    columns = 12
    vertices, faces = [], []
    width = columns+1
    outer_count = width*(rows+1)
    for inner in (False, True):
        for j in range(rows+1):
            lat = start_lat+(end_lat-start_lat)*j/rows
            for i in range(columns+1):
                lon = start_lon+(end_lon-start_lon)*i/columns
                border = i in (0,columns) or j in (0,rows)
                radius = 1.177 if inner else (1.195 if border else 1.2)
                vertices.append((radius*math.cos(lat)*math.cos(lon),
                    radius*math.cos(lat)*math.sin(lon), radius*math.sin(lat)))
    for j in range(rows):
        for i in range(columns):
            a = j*width+i
            faces.append((a,a+1,a+width+1,a+width))
            b = a+outer_count
            faces.append((b+width,b+width+1,b+1,b))
    boundary = list(range(width))
    boundary += [j*width+columns for j in range(1,rows+1)]
    boundary += [rows*width+i for i in range(columns-1,-1,-1)]
    boundary += [j*width for j in range(rows-1,0,-1)]
    for a,b in zip(boundary,boundary[1:]+boundary[:1]):
        faces.append((a,a+outer_count,b+outer_count,b))
    mesh = bpy.data.meshes.new(name+'_Mesh')
    mesh.from_pydata(vertices, [], faces)
    mesh.update()
    obj = bpy.data.objects.new(name, mesh)
    collection.objects.link(obj)
    obj.parent = root
    mesh.materials.append(mat)
    outer_and_inner = columns*rows*2
    for face in mesh.polygons:
        face.use_smooth = face.index < outer_and_inner
    parts.append(obj)
    return obj

for quadrant in range(4):
    left = quadrant*math.pi/2+.009
    right = (quadrant+1)*math.pi/2-.009
    panel('SteelImpact_Upper_%02d'%quadrant, left,right,.342,math.pi/2-.018,8,steel)
    panel('SteelImpact_Belt_%02d'%quadrant, left,right,-.319,.319,4,red)
    panel('SteelImpact_Lower_%02d'%quadrant, left,right,-math.pi/2+.018,-.342,8,steel)

# Eight domed rivets total: four above the belt and four on the belt.
for quadrant in range(4):
    for row, latitude in enumerate((.47,-.18)):
        longitude = quadrant*math.pi/2 + (.23 if row==0 else 1.25)
        direction = Vector((math.cos(latitude)*math.cos(longitude),
            math.cos(latitude)*math.sin(longitude), math.sin(latitude)))
        bpy.ops.mesh.primitive_uv_sphere_add(segments=16, ring_count=8, radius=1)
        obj = bpy.context.object
        obj.name = 'SteelImpact_Rivet_%02d_%d'%(quadrant,row)
        move_to(obj)
        obj.parent = root
        obj.location = direction*1.198
        obj.rotation_euler = direction.to_track_quat('Z','Y').to_euler()
        obj.scale = (.087,.087,.035)
        obj.data.materials.append(steel)
        for face in obj.data.polygons:
            face.use_smooth = True
        parts.append(obj)

first_stand = bpy.data.objects['Display_Pedestal']
stand = first_stand.copy()
stand.data = first_stand.data.copy()
stand.name = 'Display_Pedestal_02'
collection.objects.link(stand)
stand.location = first_stand.location + Vector((3.2,0,0))
bpy.context.view_layer.update()
# Rest the new ball on the pedestal using evaluated world-space bounds.
lowest = min((obj.matrix_world @ vertex.co).z for obj in parts for vertex in obj.data.vertices)
root.location.z += first_stand.location.z+first_stand.dimensions.z/2-lowest
bpy.context.view_layer.update()

camera = scene.camera
target = first.location + Vector((1.6,0,-.1))
camera.location = target + Vector((0,-8,2.45))
camera.rotation_euler = (target-camera.location).to_track_quat('-Z','Y').to_euler()
camera.data.ortho_scale = 6.65
scene.render.resolution_x = 1400
scene.render.resolution_y = 800
scene.render.resolution_percentage = 100
scene.cycles.samples = 48
scene.render.filepath = os.path.join(OUT, 'two-balls-preview.png')
for obj in scene.objects:
    if obj.type=='LIGHT' and obj.name.startswith('RubberRookie_'):
        obj.location.x += 1.6
        obj.rotation_euler = (target-obj.location).to_track_quat('-Z','Y').to_euler()
        obj.data.size = max(obj.data.size,4)

bpy.ops.object.select_all(action='DESELECT')
for obj in parts:
    obj.select_set(True)
root.select_set(True)
bpy.context.view_layer.objects.active = core
saved_location = root.location.copy()
root.location = (0,0,0)
bpy.ops.export_scene.fbx(filepath=os.path.join(OUT,'steel-impact.fbx'),use_selection=True,
    object_types={'MESH','EMPTY'},bake_anim=False,path_mode='COPY',axis_forward='-Z',axis_up='Y')
root.location = saved_location
bpy.context.view_layer.update()
assert all(abs(first.matrix_world[i][j]-first_transform[i][j])<1e-6 for i in range(4) for j in range(4))
assert len(first.data.vertices)==first_vertex_count
for area in bpy.context.screen.areas:
    if area.type=='VIEW_3D':
        area.spaces.active.region_3d.view_perspective='CAMERA'
        area.spaces.active.shading.type='MATERIAL'
for obj in parts:
    obj.data.calc_loop_triangles()
triangles = sum(len(obj.data.loop_triangles) for obj in parts)
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(os.path.dirname(OUT),'ball-display.blend'))
result = {'filepath':bpy.data.filepath,'triangles':triangles,'new_meshes':len(parts),
    'first_ball_preserved':True,'second_ball_center':list(root.location),'rivets':8}
