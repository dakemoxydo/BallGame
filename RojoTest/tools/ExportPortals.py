import bpy, runpy, sys
from pathlib import Path
root = Path(r'C:\Users\userr\OneDrive\Документы\PROJECTS\roblox\111\RojoTest')
out = root / 'assets/studio/portals-v6'
out.mkdir(parents=True, exist_ok=True)
floor = bpy.data.objects.get('Presentation floor')
if floor:
    floor.hide_render = True
for image in bpy.data.images:
    if image.packed_file:
        image.filepath_raw = str(out / 'stone-normal.png')
        image.file_format = 'PNG'
        image.save()
sys.argv = ['ExportRobloxPack.py', '--', str(out / 'portals-v6.fbx')]
runpy.run_path(str(root / 'tools/ExportRobloxPack.py'), run_name='__main__')
