import bpy
from pathlib import Path

out = Path(__file__).resolve().parent
root = bpy.data.objects.get("Tree")
assert root is not None, "Missing oak root"
objects = [o for o in root.children_recursive if o.type == "MESH"]
bpy.ops.object.select_all(action="DESELECT")
for obj in objects:
    obj.select_set(True)
bpy.context.view_layer.objects.active = objects[0]
bpy.ops.export_scene.fbx(
    filepath=str(out / "oak.fbx"),
    use_selection=True,
    object_types={"MESH"},
    axis_forward="-Z",
    axis_up="Y",
    global_scale=1.0,
    apply_unit_scale=True,
    use_mesh_modifiers=True,
    add_leaf_bones=False,
    bake_anim=False,
    path_mode="AUTO",
)
print("Exported", out / "oak.fbx")
