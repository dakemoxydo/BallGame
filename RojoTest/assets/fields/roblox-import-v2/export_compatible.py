
import bpy,bmesh,os
out=r'C:/Users/userr/OneDrive/Документы/PROJECTS/roblox/111/RojoTest/assets/fields/roblox-import-v2'
main=bpy.context.scene
temp=bpy.data.scenes.new('Roblox_Import_Export_Copy');bpy.context.window.scene=temp
original=[o for c in main.collection.children if c.name.endswith('Field_Asset') for o in c.objects]
materials={};images={};clones=[]
for source in original:
 ob=source.copy();ob.data=source.data.copy();temp.collection.objects.link(ob);clones.append(ob)
 for i,mat in enumerate(list(ob.data.materials)):
  if not mat:continue
  if mat.name not in materials:
   copied=mat.copy();materials[mat.name]=copied
   if copied.use_nodes:
    for node in copied.node_tree.nodes:
     if node.type=='TEX_IMAGE' and node.image:
      old=node.image
      if old.name not in images:
       image=old.copy();image.name='Import_'+old.name
       image.scale(512,512)
       safe=''.join(ch if ch.isalnum() or ch=='_' else '_' for ch in old.name)
       image.filepath_raw=out+'/'+safe+'.png';image.file_format='PNG'
       image.use_view_as_render=False
       # Render export as opaque RGB 8-bit PNG rather than a tiny packed palette.
       image.save()
       images[old.name]=image
      node.image=images[old.name]
   # Material slots reference only their fresh image copies.
  ob.data.materials[i]=materials[mat.name]
 bm=bmesh.new();bm.from_mesh(ob.data);bmesh.ops.triangulate(bm,faces=list(bm.faces));bm.to_mesh(ob.data);bm.free()
 ob.select_set(True)
bpy.context.view_layer.objects.active=clones[0]
bpy.ops.export_scene.fbx(filepath=out+'/training-fields-v2.fbx',use_selection=True,object_types={'MESH'},apply_unit_scale=False,axis_forward='-Z',axis_up='Y',path_mode='RELATIVE',embed_textures=False,add_leaf_bones=False,use_triangles=True)
result={'meshes':len(clones),'images':len(images),'all_512':all(list(i.size)==[512,512] for i in images.values()),'textures':[i.filepath_raw for i in images.values()],'max_triangles':max(len(o.data.polygons) for o in clones),'path':out+'/training-fields-v2.fbx'}
for o in clones:bpy.data.objects.remove(o,do_unlink=True)
bpy.context.window.scene=main;bpy.data.scenes.remove(temp)

