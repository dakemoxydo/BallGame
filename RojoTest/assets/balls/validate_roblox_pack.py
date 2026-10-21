"""Round-trip FBX verification in a separate background Blender process."""
import bpy,os,json
OUT=os.path.join(os.path.dirname(os.path.abspath(__file__)),'roblox-import-v2')
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.fbx(filepath=os.path.join(OUT,'roblox-balls-10.fbx'))
roots=[o for o in bpy.context.scene.objects if o.type=='EMPTY' and o.name.startswith('Ball_')]
meshes=[o for o in bpy.context.scene.objects if o.type=='MESH']
assert len(roots)==10,len(roots)
assert len(meshes)==14,len(meshes)
checks=[]
for o in meshes:
    o.data.calc_loop_triangles()
    assert len(o.data.loop_triangles)<=10000,o.name
    assert o.parent in roots,o.name
    assert len(o.data.uv_layers)==1,o.name
    assert len(o.data.materials)==1,o.name
    images=[n.image for n in o.data.materials[0].node_tree.nodes if n.type=='TEX_IMAGE' and n.image]
    assert images,o.name
    assert all(os.path.isfile(bpy.path.abspath(i.filepath)) for i in images),o.name
    uv=o.data.uv_layers.active
    colors=set()
    image=images[0];width,height=image.size;pixels=list(image.pixels)
    for triangle in o.data.loop_triangles:
        points=[uv.data[i].uv for i in triangle.loops]
        area=abs((points[1].x-points[0].x)*(points[2].y-points[0].y)-(points[1].y-points[0].y)*(points[2].x-points[0].x))
        assert area>1e-10,('Degenerate UV',o.name)
        u=sum(p.x for p in points)/3;v=sum(p.y for p in points)/3
        px=min(width-1,max(0,int(u*width)));py=min(height-1,max(0,int(v*height)))
        offset=(py*width+px)*4
        colors.add(tuple(round(c,2) for c in pixels[offset:offset+3]))
    required={'Ball_02_SteelImpact_Body':3,'Ball_04_VolcanoHeart_Body':2,
        'Ball_06_PlasmaSatellite_Body':3,'Ball_07_ThunderSplit_Body':3,
        'Ball_08_DragonSun_Body':3,'Ball_09_BlackHole_Body':4}
    if o.name in required:assert len(colors)>=required[o.name],('Lost color regions',o.name,len(colors))
    checks.append({'mesh':o.name,'triangles':len(o.data.loop_triangles),'texture_found':True,'sampled_colors':len(colors),'uv_area_verified':True})
report={'verified':True,'balls':len(roots),'meshes':len(meshes),'checks':checks,'roblox_studio_tested':False}
with open(os.path.join(OUT,'validation.json'),'w',encoding='utf-8') as f:json.dump(report,f,indent=2)
print(json.dumps(report))
