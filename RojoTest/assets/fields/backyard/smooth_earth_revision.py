
import bpy,bmesh
out=r'C:/Users/userr/OneDrive/Документы/PROJECTS/roblox/111/RojoTest/assets/fields/backyard'
scene=bpy.context.scene
assert scene.name=='Backyard_Field_Reference'
studs=bpy.data.objects.get('BF_Grass_Studs')
if studs:bpy.data.objects.remove(studs,do_unlink=True)
# Brown earth replaces pale gray platform, grass cap remains on top
palette=bpy.data.images['Backyard_Palette']
pixels=list(palette.pixels);pixels[:4]=[.34,.205,.105,1];palette.pixels=pixels
palette.filepath_raw=out+'/backyard-palette.png';palette.save();palette.pack()
bpy.data.materials['Backyard_Base'].diffuse_color=(.34,.205,.105,1)
base=bpy.data.objects['BF_Platform'];base.name='BF_Earth_Base'
for p in base.data.polygons:
 p.material_index=1 if p.normal.z>.5 else 0
uv=base.data.uv_layers.active
for p in base.data.polygons:
 for i in p.loop_indices:uv.data[i].uv=((p.material_index+.5)/8,.5)
# Lower white paint to lie directly on now-smooth grass
marks=bpy.data.objects['BF_White_Markings'];marks.location.z=-.03
ball=bpy.data.objects['BF_Football']
ball.location=(6.2,-7.4,-min(v.co.z for v in ball.data.vertices))
field=bpy.data.collections['Backyard_Field_Asset']
def export(obs,filename):
 bpy.ops.object.select_all(action='DESELECT')
 for ob in obs:ob.select_set(True)
 bpy.context.view_layer.objects.active=obs[0]
 bpy.ops.export_scene.fbx(filepath=out+'/'+filename,use_selection=True,object_types={'MESH'},apply_unit_scale=False,axis_forward='-Z',axis_up='Y',path_mode='COPY',embed_textures=True,add_leaf_bones=False)
export(list(field.objects),'backyard-field.fbx')
loc=ball.location.copy();ball.location=(0,0,0);export([ball],'football.fbx');ball.location=loc
export(list(field.objects)+[ball],'backyard-field-with-ball.fbx')
bpy.context.view_layer.update()
audit=[]
for ob in list(field.objects)+[ball]:
 bm=bmesh.new();bm.from_mesh(ob.data)
 audit.append({'name':ob.name,'open_edges':sum(e.is_boundary for e in bm.edges),'degenerate':sum(f.calc_area()<1e-10 for f in bm.faces)})
 bm.free()
bpy.ops.wm.save_as_mainfile(filepath=out+'/backyard-field.blend')
result={'field_meshes':len(field.objects),'studs_removed':bpy.data.objects.get('BF_Grass_Studs') is None,'ball_location':list(ball.location),'ball_clearance_from_field':min((ball.matrix_world@v.co).x for v in ball.data.vertices)-4.3,'audit':audit}

