# Diamond field — fourth progression tier

Built via Blender MCP next to Royal_Field_Asset at center X=36. Same 8 × 20 pitch and 9.6 × 21.6 brown earth foundation with green/mint turf sides; white markings and penalty spot. Silver goal and rails, cyan panels, faceted blue crystal caps and goal crest. Mint/aqua diamond-pattern turf with flat studs texture. No emission, particles or effects; crystals are opaque colored geometry attached to mounts.

- `diamond-field.fbx`: standalone fourth field centered at origin; 55 mesh objects with embedded textures.
- `diamond-palette.png`, `diamond-grass-0.png`, `diamond-grass-1.png`: textures packed into Blender scene.
- `../training-fields.blend`: all four fields and independent ball.
- `../training-fields.fbx`: all four fields, no ball/camera/lights.
- `../training-fields-preview.png`: checked render.
- `build_diamond_field.py`: reproducible source; refuses duplicate Diamond_Field_Asset.
- `before-fourth-field.blend`: pre-change scene backup.

Geometry: zero open boundary edges and degenerate faces. Thirteen crystal-to-mount bounding-overlap checks passed. Existing rear frame supports net. FBX reimport verified 55 meshes, UVs and bounds. First three fields unchanged. Studio import/gameplay integration not performed.
