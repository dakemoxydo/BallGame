import bpy, json
from pathlib import Path
result = {
    'collections': [{'name':c.name,'count':len(c.all_objects),'types':list(set(o.type for o in c.all_objects))} for c in bpy.data.collections],
    'large': [{'name':o.name,'size':list(o.dimensions),'collections':[c.name for c in o.users_collection]} for o in bpy.context.scene.objects if o.type=='MESH' and max(o.dimensions)>30],
    'images':[{'name':i.name,'path':i.filepath,'packed':bool(i.packed_file)} for i in bpy.data.images],
    'materials':[{'name':m.name,'color':list(m.diffuse_color),'nodes':[n.type for n in m.node_tree.nodes] if m.use_nodes else []} for m in bpy.data.materials]
}
Path(r'C:\Users\userr\OneDrive\Документы\PROJECTS\roblox\111\RojoTest\assets\studio\portals-v6\inspection.json').write_text(json.dumps(result,ensure_ascii=False,indent=2),encoding='utf-8')
