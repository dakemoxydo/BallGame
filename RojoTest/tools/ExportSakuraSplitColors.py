import bpy, json
from pathlib import Path
root=Path(r'C:\Users\userr\OneDrive\Документы\PROJECTS\roblox\111\RojoTest\assets\studio\sakura-v1')
objects=[o for o in bpy.context.scene.objects if o.type=='MESH' and 'preview' not in o.name.lower() and 'pedestal' not in o.name.lower()]
bpy.ops.object.select_all(action='DESELECT')
for o in objects:
    o.data=o.data.copy()
    o.select_set(True)
bpy.context.view_layer.objects.active=objects[-1]
bpy.ops.object.mode_set(mode='EDIT')
bpy.ops.mesh.select_all(action='SELECT')
bpy.ops.mesh.separate(type='MATERIAL')
bpy.ops.object.mode_set(mode='OBJECT')
export=list(bpy.context.selected_objects)
manifest={}
for i,o in enumerate(export):
    mat=o.data.materials[0] if o.data.materials else None
    name=mat.name.lower() if mat else ''
    if 'leaf' in o.name.lower():
        color=(1.0,0.62+(i%3)*0.08,0.79+(i%2)*0.08,1)
        label='SakuraPetal'
    elif any(s in name for s in ['trunk','bark','branch','wood']):
        color=(0.31,0.13,0.085,1)
        label='SakuraWood'
    else:
        color=(1.0,0.56+(i%3)*0.08,0.75+(i%2)*0.09,1)
        label='SakuraBlossoms'
    o.name=f'{label}_{i:03d}'
    m=bpy.data.materials.new(o.name+'_Color')
    m.diffuse_color=color
    o.data.materials.clear()
    o.data.materials.append(m)
    for p in o.data.polygons:p.material_index=0
    manifest[o.name]=[round(c*255) for c in color[:3]]
path=root/'sakura-split-colors.fbx'
bpy.ops.export_scene.fbx(filepath=str(path),use_selection=True,object_types={'MESH'},axis_forward='-Z',axis_up='Y',apply_unit_scale=True,bake_anim=False,path_mode='AUTO',embed_textures=False)
(root/'sakura-colors.json').write_text(json.dumps(manifest,indent=2),encoding='utf-8')
print(json.dumps({'objects':len(export),'wood':sum(n.startswith('SakuraWood') for n in manifest),'blossoms':sum(n.startswith('SakuraBlossoms') for n in manifest),'bytes':path.stat().st_size}))
