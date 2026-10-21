"""Read the supplied oak scene and export evaluated geometry for Studio MCP."""
import bpy
import json
from pathlib import Path
from mathutils import Vector

OUT = Path(__file__).resolve().parent
root = bpy.data.objects.get("Tree")
assert root is not None, "Expected oak root named Tree"
objects = sorted((o for o in root.children_recursive if o.type == "MESH"), key=lambda o: o.name)
assert objects, "Oak contains no meshes"
graph = bpy.context.evaluated_depsgraph_get()
vertices, triangles, colors, names = [], [], [], []

def srgb(value):
    value = max(0.0, min(1.0, value))
    return 12.92 * value if value <= 0.0031308 else 1.055 * value ** (1 / 2.4) - 0.055

def vec(value):
    return [round(value.x, 6), round(value.z, 6), round(-value.y, 6)]

for obj in objects:
    evaluated = obj.evaluated_get(graph)
    mesh = evaluated.to_mesh()
    mesh.calc_loop_triangles()
    world = evaluated.matrix_world
    normal_matrix = world.to_3x3().inverted().transposed()
    offset = len(vertices)
    vertices.extend(vec(world @ v.co) for v in mesh.vertices)
    for tri in mesh.loop_triangles:
        material = obj.material_slots[tri.material_index].material if obj.material_slots else None
        color = list(material.diffuse_color[:3]) if material else [0.7, 0.7, 0.7]
        if material and material.use_nodes:
            node = next((n for n in material.node_tree.nodes if n.type == "BSDF_PRINCIPLED"), None)
            if node:
                assert not node.inputs["Base Color"].is_linked, "Textured material requires baking: " + material.name
                color = list(node.inputs["Base Color"].default_value[:3])
        color = [round(srgb(c), 6) for c in color]
        if color not in colors:
            colors.append(color)
        normals = [vec((normal_matrix @ mesh.corner_normals[i].vector).normalized()) for i in tri.loops]
        triangles.append([*[offset + i + 1 for i in tri.vertices], colors.index(color) + 1, *[c for n in normals for c in n]])
    names.append({"name": obj.name, "vertices": len(mesh.vertices), "triangles": len(mesh.loop_triangles)})
    evaluated.to_mesh_clear()

minimum = [min(v[i] for v in vertices) for i in range(3)]
maximum = [max(v[i] for v in vertices) for i in range(3)]
height = maximum[1] - minimum[1]
scale = 24.0 / height
origin = vec(root.matrix_world.translation)
base = [origin[0], minimum[1], origin[2]]
vertices = [[round((v[i] - base[i]) * scale, 6) for i in range(3)] for v in vertices]
data = {"name": "Oak", "source": bpy.data.filepath, "heightStuds": 24, "vertices": vertices, "triangles": triangles, "colors": colors, "objects": names}
OUT.mkdir(parents=True, exist_ok=True)
(OUT / "oak-geometry.json").write_text(json.dumps(data, separators=(",", ":")), encoding="utf-8")
summary = {"objects": len(objects), "vertices": len(vertices), "triangles": len(triangles), "colors": colors, "sourceBounds": [minimum, maximum], "heightStuds": 24}
(OUT / "export-summary.json").write_text(json.dumps(summary, indent=2), encoding="utf-8")
print(json.dumps(summary))
