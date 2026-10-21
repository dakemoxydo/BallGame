# Royal field — third progression tier

Attachment repair: ten laurel leaves now intersect the goal posts; crest embeds in crossbar and crown/inlay overlap their backing. Numerical bounding overlap checks passed for all 13 joins. Added thin rear goal frames to all three nets with ground-reaching rear posts. Main Blender scene and all field FBX exports updated; new royal export has 54 meshes. Preview checked. Script: fix_attachments.py; backup: before-attachment-fix.blend.

Created beside Club_Field_Asset at X=24 through Blender MCP. Same 8 × 20 pitch, 9.6 × 21.6 brown earth foundation, green turf sides, white penalty spot and flat studs texture. Gold goal and rails, emerald sideline panels, darker gold posts, goal laurel leaves and crown crest, diamond-pattern emerald turf. No effects. Earlier fields preserved.

- `royal-field.fbx`: standalone third field, centered at origin, 53 named mesh objects and embedded textures.
- `royal-palette.png`, `royal-grass-0.png`, `royal-grass-1.png`: packed textures.
- `../training-fields.blend`: editable scene with all three fields and independent ball.
- `../training-fields.fbx`: all three fields; excludes ball/camera/lights.
- `../training-fields-preview.png`: checked render.
- `build_royal_field.py`: build source, guarded against duplicate royal collection.
- `before-third-field.blend`: pre-change scene backup.

Verified royal geometry has zero degenerate faces and open boundary edges. FBX reimport checked mesh count, UVs and bounds. Spacing between consecutive bases is 2.4 units. Not imported into Roblox Studio; set scale and gameplay collision proxies during integration.
