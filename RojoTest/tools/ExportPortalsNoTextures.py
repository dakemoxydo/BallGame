import bpy, runpy, sys
from pathlib import Path
root = Path(r'C:\Users\userr\OneDrive\Документы\PROJECTS\roblox\111\RojoTest')
floor = bpy.data.objects.get('Presentation floor')
if floor:
    floor.hide_render = True
# Preserve color-only shader values, including procedural portal color ramps.
for m in bpy.data.materials:
    if not m.use_nodes:
        continue
    ramps = [n for n in m.node_tree.nodes if n.type == 'VALTORGB']
    if ramps and 'swirling' in m.name.lower():
        m.diffuse_color = ramps[0].color_ramp.elements[-1].color[:]
        shader = next((n for n in m.node_tree.nodes if n.type == 'BSDF_PRINCIPLED'), None)
        if shader:
            shader.inputs['Base Color'].default_value = m.diffuse_color
    elif not any(n.type == 'BSDF_PRINCIPLED' for n in m.node_tree.nodes):
        emission = next((n for n in m.node_tree.nodes if n.type == 'EMISSION'), None)
        if emission and not emission.inputs['Color'].is_linked:
            m.diffuse_color = emission.inputs['Color'].default_value[:]
sys.argv = ['ExportRobloxPack.py', '--', str(root / 'assets/studio/portals-v6/portals-v6-no-textures.fbx'), '--simple-materials']
runpy.run_path(str(root / 'tools/ExportRobloxPack.py'), run_name='__main__')
assert not any(n.type == 'TEX_IMAGE' for o in bpy.context.selected_objects for m in o.data.materials if m and m.use_nodes for n in m.node_tree.nodes)
print('Verified exported materials contain no image textures')
