"""Render the actual reimported FBX, rather than the source Blender scene."""
import bpy,os
from mathutils import Vector
OUT=os.path.join(os.path.dirname(os.path.abspath(__file__)),'roblox-import-v2')
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.fbx(filepath=os.path.join(OUT,'roblox-balls-10.fbx'))
scene=bpy.context.scene
for obj in scene.objects:
    if obj.type=='MESH' and obj.name.endswith('_Shell'):
        material=obj.data.materials[0]
        alpha=material.node_tree.nodes.get('Principled BSDF').inputs['Alpha']
        for link in list(alpha.links):material.node_tree.links.remove(link)
        alpha.default_value=.26
        material.surface_render_method='BLENDED'
bpy.ops.mesh.primitive_plane_add(size=200,location=(6,2,0))
floor=bpy.context.object;floor.name='PreviewFloor'
material=bpy.data.materials.new('Floor');material.diffuse_color=(.22,.24,.27,1);floor.data.materials.append(material)
world=bpy.data.worlds.new('PreviewWorld');world.use_nodes=True
world.node_tree.nodes['Background'].inputs['Color'].default_value=(.4,.45,.5,1)
world.node_tree.nodes['Background'].inputs['Strength'].default_value=.5;scene.world=world
target=Vector((6.4,2.25,1.2))
bpy.ops.object.camera_add(location=target+Vector((0,-16,13)))
camera=bpy.context.object;camera.rotation_euler=(target-camera.location).to_track_quat('-Z','Y').to_euler()
camera.data.type='ORTHO';camera.data.ortho_scale=17.1;scene.camera=camera
for name,power,location in [('Key',1600,(6,-4,10)),('Fill',1100,(6,6,8))]:
    data=bpy.data.lights.new(name,'AREA');data.energy=power;data.shape='RECTANGLE';data.size=12;data.size_y=6
    light=bpy.data.objects.new(name,data);scene.collection.objects.link(light);light.location=location
    light.rotation_euler=(target-light.location).to_track_quat('-Z','Y').to_euler()
scene.render.engine='CYCLES';scene.cycles.samples=12;scene.cycles.use_denoising=True
scene.render.resolution_x=1200;scene.render.resolution_y=700;scene.render.resolution_percentage=100
scene.view_settings.view_transform='Standard';scene.view_settings.look='None';scene.view_settings.exposure=-.75
scene.render.filepath=os.path.join(OUT,'fbx-reimport-preview.png')
bpy.ops.render.render(write_still=True)
print('PREVIEW='+scene.render.filepath)
