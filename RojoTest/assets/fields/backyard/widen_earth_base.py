
import bpy
out=r'C:/Users/userr/OneDrive/Документы/PROJECTS/roblox/111/RojoTest/assets/fields/backyard'
scene=bpy.context.scene
base=bpy.data.objects['BF_Earth_Base']
for v in base.data.vertices:
 v.co.x*=9.6/8.6
 v.co.y*=21.6/21
for p in base.data.polygons:p.material_index=0
# Reproject earth texture at the original world density on every face.
uv=base.data.uv_layers.active
for p in base.data.polygons:
 axis=max(range(3),key=lambda k:abs(p.normal[k]))
 axes=(0,1) if axis==2 else ((0,2) if axis==1 else (1,2))
 for li in p.loop_indices:
  v=base.data.vertices[base.data.loops[li].vertex_index].co
  uv.data[li].uv=(v[axes[0]]/2,v[axes[1]]/2)
base.data.update()
# The vertical support beneath turf is earth too; green exists only on pitch top.
bed=bpy.data.objects['BF_Grass_Bed']
for p in bed.data.polygons:p.material_index=1 if p.normal.z>.5 else 0
bed.data.update()
field=list(bpy.data.collections['Backyard_Field_Asset'].objects)
ball=bpy.data.objects['BF_Football']
def export(obs,filename):
 bpy.ops.object.select_all(action='DESELECT')
 for ob in obs:ob.select_set(True)
 bpy.context.view_layer.objects.active=obs[0]
 bpy.ops.export_scene.fbx(filepath=out+'/'+filename,use_selection=True,object_types={'MESH'},apply_unit_scale=False,axis_forward='-Z',axis_up='Y',path_mode='COPY',embed_textures=True,add_leaf_bones=False)
export(field,'backyard-field.fbx');export(field+[ball],'backyard-field-with-ball.fbx')
bpy.context.view_layer.update()
bpy.ops.wm.save_as_mainfile(filepath=out+'/backyard-field.blend')
result={'earth_dimensions':list(base.dimensions),'grass_dimensions':list(bed.dimensions),'earth_border_width':.8,'base_green_faces':sum(p.material_index!=0 for p in base.data.polygons)}

