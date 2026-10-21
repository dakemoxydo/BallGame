"""Build a textured starter ball and isolated presentation scene via Blender MCP."""
import bpy
import math
import os
import numpy as np
from mathutils import Vector, Quaternion

OUT = os.path.dirname(os.path.abspath(__file__))
os.makedirs(OUT, exist_ok=True)
if bpy.context.object and bpy.context.object.mode != 'OBJECT':
    bpy.ops.object.mode_set(mode='OBJECT')
scene = bpy.data.scenes.new('RubberRookie_Display')
bpy.context.window.scene = scene
assets = bpy.data.collections.new('RubberRookie_Assets')
studio = bpy.data.collections.new('RubberRookie_Studio')
scene.collection.children.link(assets)
scene.collection.children.link(studio)

def move_to(obj, collection):
    for old in list(obj.users_collection):
        old.objects.unlink(obj)
    collection.objects.link(obj)

def material(name, color, roughness):
    mat = bpy.data.materials.new(name)
    mat.diffuse_color = (*color, 1)
    mat.use_nodes = True
    shader = mat.node_tree.nodes.get('Principled BSDF')
    shader.inputs['Base Color'].default_value = (*color, 1)
    shader.inputs['Roughness'].default_value = roughness
    return mat, shader

# A UV texture carries seams and scuffs into FBX, independently of Blender nodes.
size = 1024
u, v = np.meshgrid((np.arange(size)+.5)/size, (np.arange(size)+.5)/size)
phi = u*2*math.pi
lat = (v-.5)*math.pi
x, y, z = np.cos(lat)*np.cos(phi), np.cos(lat)*np.sin(phi), np.sin(lat)
d = np.minimum(np.minimum(np.abs(x), np.abs(y)), np.abs(z))
seam = np.clip((d-.030)/.008, 0, 1)
seam = seam*seam*(3-2*seam)
rng = np.random.default_rng(19)
grain = rng.random((size, size)).astype(np.float32)
orange = np.array([.97, .315, .035], dtype=np.float32)
dark = np.array([.105, .112, .12], dtype=np.float32)
rgb = dark[None,None,:]*(1-seam[:,:,None])+orange[None,None,:]*seam[:,:,None]
rgb *= (.94+.085*grain)[:,:,None]
wear = np.zeros((size,size), dtype=np.float32)
for i in range(32):
    cx, cy = rng.uniform(.04,.96), rng.uniform(.12,.88)
    du = ((u-cx+.5)%1)-.5
    dv = v-cy
    angle = rng.uniform(0, math.pi)
    a, b = du*math.cos(angle)+dv*math.sin(angle), -du*math.sin(angle)+dv*math.cos(angle)
    mark = np.exp(-((a/rng.uniform(.003,.014))**2+(b/.0012)**2)*2)
    wear = np.maximum(wear, mark*rng.uniform(.12,.45))
rgb *= 1-(wear*seam)[:,:,None]
rgba = np.ones((size,size,4), dtype=np.float32)
rgba[:,:,:3] = rgb
image = bpy.data.images.new('RubberRookie_BaseColor', width=size, height=size, alpha=True)
image.pixels.foreach_set(rgba.ravel())
image.filepath_raw = os.path.join(OUT, 'rubber-rookie-color.png')
image.file_format = 'PNG'
image.save()
image.pack()
rubber, shader = material('RubberRookie_OrangeRubber', (.97,.315,.035), .72)
nodes, links = rubber.node_tree.nodes, rubber.node_tree.links
tex = nodes.new('ShaderNodeTexImage')
tex.image = image
links.new(tex.outputs['Color'], shader.inputs['Base Color'])
coord = nodes.new('ShaderNodeTexCoord')
noise = nodes.new('ShaderNodeTexNoise')
noise.inputs['Scale'].default_value = 175
noise.inputs['Detail'].default_value = 2
links.new(coord.outputs['Generated'], noise.inputs['Vector'])
bump = nodes.new('ShaderNodeBump')
bump.inputs['Strength'].default_value = .27
bump.inputs['Distance'].default_value = .009
links.new(noise.outputs['Fac'], bump.inputs['Height'])
links.new(bump.outputs['Normal'], shader.inputs['Normal'])

bpy.ops.mesh.primitive_uv_sphere_add(segments=96, ring_count=48, radius=1, calc_uvs=True)
ball = bpy.context.object
ball.name = 'Ball_01_RubberRookie'
move_to(ball, assets)
# Recessed grooves are actual geometry; color boundaries remain smooth in the texture.
directions = [vertex.co.normalized() for vertex in ball.data.vertices]
for vertex, normal in zip(ball.data.vertices, directions):
    distance = min(abs(normal.x), abs(normal.y), abs(normal.z))
    t = max(0, min(1, (distance-.020)/.040))
    t = t*t*(3-2*t)
    vertex.co = normal*(1.2-.018*(1-t))
uv = ball.data.uv_layers.active.data
for face in ball.data.polygons:
    coords = []
    for index in face.loop_indices:
        n = directions[ball.data.loops[index].vertex_index]
        coords.append([(math.atan2(n.y,n.x)/(2*math.pi))%1, .5+math.asin(max(-1,min(1,n.z)))/math.pi, abs(n.z)>.99999])
    nonpoles = [c[0] for c in coords if not c[2]]
    if max(nonpoles)-min(nonpoles)>.5:
        for c in coords:
            if c[0]<.5:
                c[0]+=1
    pole_u = sum(c[0] for c in coords if not c[2])/len(nonpoles)
    for index,c in zip(face.loop_indices,coords):
        uv[index].uv = (pole_u if c[2] else c[0], c[1])
    face.use_smooth = True
ball.data.materials.append(rubber)
ball.location = (0,0,1.415)
ball.rotation_euler = tuple(math.radians(a) for a in (12,-18,23))
ball['tier'] = 1
ball['pivot_note'] = 'Object origin is ball center; FBX ball exported at world origin.'

stand_mat, _ = material('RubberRookie_StandGraphite', (.085,.095,.11), .63)
bpy.ops.mesh.primitive_cylinder_add(vertices=96, radius=1.12, depth=.22, location=(0,0,.11))
stand = bpy.context.object
stand.name = 'Display_Pedestal'
move_to(stand, assets)
stand.data.materials.append(stand_mat)
bevel = stand.modifiers.new('Soft pedestal edges', 'BEVEL')
bevel.width = .035
bevel.segments = 3
stand.modifiers.new('Weighted pedestal normals', 'WEIGHTED_NORMAL')
for p in stand.data.polygons:
    p.use_smooth = True

floor_mat, _ = material('RubberRookie_Backdrop', (.42,.45,.49), .9)
bpy.ops.mesh.primitive_plane_add(size=200)
floor = bpy.context.object
floor.name = 'Studio_Floor'
move_to(floor, studio)
floor.location.z = -.006
floor.data.materials.append(floor_mat)

def aim(obj, target):
    obj.rotation_euler = (Vector(target)-obj.location).to_track_quat('-Z','Y').to_euler()

bpy.ops.object.camera_add(location=(4,-6,3.45))
camera = bpy.context.object
camera.name = 'RubberRookie_Camera'
move_to(camera, studio)
aim(camera, (0,0,1.29))
camera.data.type = 'ORTHO'
camera.data.ortho_scale = 3.65
scene.camera = camera
for name, position, energy, shape_size in [
    ('Key', (1,-4,6), 650, 4),
    ('Fill', (-4,-1,3), 350, 3),
    ('Rim', (2,3,5), 750, 3),
]:
    data = bpy.data.lights.new('RubberRookie_'+name, 'AREA')
    data.energy = energy
    data.shape = 'DISK'
    data.size = shape_size
    obj = bpy.data.objects.new(data.name, data)
    studio.objects.link(obj)
    obj.location = position
    aim(obj, (0,0,1.2))
world = bpy.data.worlds.new('RubberRookie_StudioWorld')
world.use_nodes = True
world.node_tree.nodes['Background'].inputs['Color'].default_value = (.45,.48,.52,1)
world.node_tree.nodes['Background'].inputs['Strength'].default_value = .35
scene.world = world
scene.render.engine = 'CYCLES'
scene.cycles.samples = 32
scene.cycles.use_denoising = True
scene.render.resolution_x = 1000
scene.render.resolution_y = 1000
scene.render.resolution_percentage = 100
scene.render.image_settings.file_format = 'PNG'
scene.render.filepath = os.path.join(OUT, 'rubber-rookie-preview.png')
scene.view_settings.view_transform = 'Standard'
scene.view_settings.look = 'None'
scene.view_settings.exposure = -.65
shader.inputs['Specular IOR Level'].default_value = .25

# Export only the ball, centered, with its texture. Presentation assets stay in .blend.
bpy.ops.object.select_all(action='DESELECT')
ball.select_set(True)
bpy.context.view_layer.objects.active = ball
saved_location = ball.location.copy()
ball.location = (0,0,0)
bpy.ops.export_scene.fbx(filepath=os.path.join(OUT, 'rubber-rookie.fbx'), use_selection=True,
    object_types={'MESH'}, apply_unit_scale=True, bake_anim=False, path_mode='COPY',
    embed_textures=True, axis_forward='-Z', axis_up='Y', use_mesh_modifiers=True)
ball.location = saved_location
bpy.context.view_layer.update()
for area in bpy.context.screen.areas:
    if area.type == 'VIEW_3D':
        area.spaces.active.region_3d.view_perspective = 'CAMERA'
        area.spaces.active.shading.type = 'MATERIAL'
ball.data.calc_loop_triangles()
bpy.ops.wm.save_as_mainfile(filepath=os.path.join(OUT, 'rubber-rookie.blend'))
result = {'scene': scene.name, 'ball': ball.name, 'vertices': len(ball.data.vertices),
    'triangles': len(ball.data.loop_triangles), 'dimensions': list(ball.dimensions),
    'output': OUT, 'uv_layers': len(ball.data.uv_layers), 'original_scene_preserved': True}
