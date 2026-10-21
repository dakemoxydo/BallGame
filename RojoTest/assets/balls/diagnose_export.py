import bpy,os,json,collections
scene=bpy.data.scenes['RubberRookie_Display'];bpy.context.window.scene=scene
dg=bpy.context.evaluated_depsgraph_get()
checks=[]
for name in ['SteelImpact_SeamCore','SteelImpact_Upper_00','SteelImpact_Belt_00','VolcanoHeart_OrangeCore','VolcanoHeart_Plate_00']:
    obj=bpy.data.objects[name];data=obj.evaluated_get(dg).to_mesh(preserve_all_data_layers=True,depsgraph=dg)
    checks.append({'object':name,'original':[m.name for m in obj.data.materials],
        'evaluated':[m.name for m in data.materials],
        'equal':[m in list(obj.data.materials) for m in data.materials]})
print('SOURCE_CHECK='+json.dumps(checks))
path=os.path.join(os.path.dirname(os.path.abspath(__file__)),'roblox-import','roblox-balls-10.fbx')
bpy.ops.import_scene.fbx(filepath=path)
for name in ['Ball_02_SteelImpact_Body','Ball_04_VolcanoHeart_Body','Ball_06_PlasmaSatellite_Body']:
    obj=bpy.data.objects.get(name)
    uv=obj.data.uv_layers.active
    histogram=collections.Counter(tuple(round(x,3) for x in v.uv) for v in uv.data)
    print('UV_CHECK='+json.dumps({'name':name,'uv_values':dict((str(k),v) for k,v in histogram.items())}))
