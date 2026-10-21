import bpy, runpy, sys, json
from pathlib import Path
root = Path(r'C:\Users\userr\OneDrive\Документы\PROJECTS\roblox\111\RojoTest')
for o in bpy.context.scene.objects:
    if o.type == 'MESH' and o.data.users > 1:
        o.data = o.data.copy()
    if o.type == 'MESH':
        materials = [slot.material for slot in o.material_slots]
        for slot, material in zip(o.material_slots, materials):
            slot.link = 'DATA'
            slot.material = material
for o in bpy.context.scene.objects:
    if o.type == 'MESH' and (o.name.lower().startswith(('presentation floor', 'studio floor')) or (min(o.dimensions) < 0.2 and max(o.dimensions) > 50)):
        o.hide_render = True
sys.argv = ['ExportRobloxPack.py', '--', str(root / 'assets/studio/sakura-v1/sakura-no-textures.fbx'), '--simple-materials']
runpy.run_path(str(root / 'tools/ExportRobloxPack.py'), run_name='__main__')
assert not any(n.type == 'TEX_IMAGE' for o in bpy.context.selected_objects for m in o.data.materials if m and m.use_nodes for n in m.node_tree.nodes)
print('Verified: no image textures in exported materials')
