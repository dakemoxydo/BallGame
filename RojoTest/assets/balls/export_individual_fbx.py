"""Package the already verified FBX as individual centered ball files."""
import bpy,os,json
ROOT=os.path.dirname(os.path.abspath(__file__))
OUT=os.path.join(ROOT,'roblox-import-v3')
os.makedirs(OUT,exist_ok=True)
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.fbx(filepath=os.path.join(ROOT,'roblox-import-v2','roblox-balls-10.fbx'))
roots=sorted([o for o in bpy.context.scene.objects if o.type=='EMPTY' and o.name.startswith('Ball_')],key=lambda o:o.name)
assert len(roots)==10
reports=[]
for i,root in enumerate(roots,1):
    bpy.ops.object.select_all(action='DESELECT')
    root.select_set(True)
    children=[o for o in root.children_recursive if o.type=='MESH']
    for obj in children:obj.select_set(True)
    bpy.context.view_layer.objects.active=children[0]
    location=root.location.copy();root.location=(0,0,0)
    path=os.path.join(OUT,'Ball_%02d.fbx'%i)
    bpy.ops.export_scene.fbx(filepath=path,use_selection=True,object_types={'MESH','EMPTY'},
        apply_unit_scale=False,axis_forward='-Z',axis_up='Y',path_mode='COPY',embed_textures=True,
        bake_anim=False,use_triangles=True,add_leaf_bones=False)
    root.location=location
    reports.append({'file':os.path.basename(path),'meshes':len(children),'bytes':os.path.getsize(path)})
with open(os.path.join(OUT,'individual_manifest.json'),'w') as f:json.dump(reports,f,indent=2)
print(json.dumps(reports))
