# Club field — second progression tier

Built beside the approved backyard field through Blender MCP. Matching 8 × 20 pitch and 9.6 × 21.6 earth base, green turf sides, flat studs texture, white penalty spot, no effects. Upgrades: deeper emerald turf stripes, white steel goal, blue goal corner/foot details, white metal rails with navy posts and blue sideline panels, two small benches behind the net.

- `../training-fields.blend`: editable scene containing both fields and independent ball.
- `../training-fields.fbx`: both fields as named meshes, excludes ball/camera/lights.
- `../training-fields-preview.png`: checked render.
- `club-field.fbx`: standalone second field centered at origin, 38 mesh objects.
- `club-palette.png`, `club-grass-0.png`, `club-grass-1.png`: textures embedded in FBX and packed in .blend.
- `build_club_field.py`: build source, refuses to duplicate an existing Club_Field_Asset collection.

Scene second-field center X=12, gap between earth bases=2.4. First field geometry/materials preserved. Ball remains independent in the gap. Club geometry passed zero open-boundary/degenerate-face checks and render checked. FBX reimport verified mesh count, UVs and dimensions. Not imported into Roblox Studio; choose scale during import to match gameplay lane.
