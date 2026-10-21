# Backyard football training field

Created in Blender through Blender MCP from the approved narrow-lane reference.

Latest cartoon palette: restored four green vertical turf sides while the wide earth foundation stays entirely brown. Grass stripes use vivid lime/green, earth uses dark warm brown, wood uses warm orange-brown, markings pure white. Studs overlays rebaked to these colors; all FBX exports updated, including standalone ball. Render checked. Script: cartoon_palette_revision.py. Backup: backups/before-cartoon-colors.

Earth is 9.6 × 21.6, surrounding the unchanged 8 × 20 pitch with a 0.8-unit brown border. Every base face uses earth material; turf sides are green. Textured studs retained as flat diffuse detail. `widen_earth_base.py` records the earlier widening; backup under backups/before-wide-earth.

Latest revision: supplied `studtexture.png` is tiled over grass and earth as a diffuse color overlay, with no bump/displacement or geometric studs. Transparent source overlay baked through Blender to `studs-tinted-0.png` (earth), `studs-tinted-1.png` and `studs-tinted-2.png` (grass), so FBX carries ordinary image materials. One 4×4-stud tile spans 2 units, giving 0.5-unit stud spacing, continuous across grass strips. Wood, white markings, net and separate ball retain their original materials. `apply_stud_texture.py` records this revision. Blender render checked; texture-backed exports saved. Backup: backups/before-stud-texture.

- `backyard-field.blend`: editable source; original Blender scene preserved separately.
- `backyard-field.fbx`: 10 named field meshes, including a white penalty spot; no ball, camera or lights; embedded palette texture.
- `football.fbx`: standalone ball mesh with origin at its center, exported at (0,0,0).
- `backyard-field-with-ball.fbx`: optional combined scene export with separate ball mesh.
- `backyard-palette.png`: eight-color UV palette.
- `backyard-preview.png`: checked Blender render.
- `build_backyard.py`: original generation source; creates a new scene when run in Blender.
- `replace_start_with_penalty.py`: applies the penalty-spot revision after the original generator.
- `smooth_earth_revision.py`: removes studs, converts the gray base to brown earth with a green top, and moves the ball outside the field.

Asset bounds: 9.6 wide × 21.6 long × 3.98 tall, bottom Z=0. Unitless coordinates; choose import scale to fit the actual Roblox lane. Field origin at center of platform base. Ball is in its own Football_Asset collection with a centered origin, beside the near right edge with 0.908 units clearance. The pad, chevron and all geometric studs are removed. Striped grass and white penalty spot remain. Entire base is brown earth, with no green border. Earlier backups are under backups/before-penalty and backups/before-smooth-earth.

Current 10 field meshes and separate ball passed closed-mesh and degenerate-face checks. Blender render checked: no studs, no gray base, ball outside field, visible penalty spot. Import via Roblox Studio 3D Importer; use simple gameplay floor/goal proxies and disable collision on net, markings and decoration. Studio import and gameplay integration have not been performed.
