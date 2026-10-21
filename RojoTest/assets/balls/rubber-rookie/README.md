# Rubber Rookie — ball tier 1

Created in the connected Blender instance through Blender MCP.

- `rubber-rookie.blend`: editable ball, separate pedestal, and presentation studio.
- `rubber-rookie.fbx`: ball only, origin at its center and location at world zero.
- `rubber-rookie-color.png`: 1024 × 1024 color texture, seams, rubber grain, and light scuffs.
- `rubber-rookie-preview.png`: verified Blender render.
- `build_rubber_rookie.py`: reproducible build script; creates a new scene without replacing existing scene objects.

The ball has 4,514 vertices and 9,024 triangles. Grooves are recessed geometry.
The color texture is packed in the blend file and embedded in the FBX. Blender's
procedural bump provides additional fine rubber relief in the preview; it is not
a baked Roblox normal map. The pedestal and studio are excluded from the FBX.

Import the FBX through Roblox Studio's 3D Importer. If the color texture is not
assigned automatically, use `rubber-rookie-color.png` as the mesh color texture.
Roblox Studio import and in-game appearance have not been checked.
