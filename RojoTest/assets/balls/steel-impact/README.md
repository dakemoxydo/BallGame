# Steel Impact — ball tier 2

Added via Blender MCP to the existing starter ball display. The current combined
scene is `../ball-display.blend`; the original tier-1 blend remains unchanged.

The second ball stands 3.2 Blender units to the right of the first, on a matching
separate pedestal. The first ball's geometry and transform were preserved.
The second ball has twelve large closed panels, a dark seam core, a broad red
belt, and eight round rivets. Its center pivot is the `Ball_02_SteelImpact` parent.
Geometry totals 8,736 triangles across 21 mesh objects, excluding the pedestal.

- `build_steel_impact.py`: additive build script, with duplicate prevention.
- `steel-impact.fbx`: second ball only, exported with its parent at world zero.
- `two-balls-preview.png`: visually checked render of both balls.

The second ball uses plain steel, red paint, and dark seam materials, without
external texture dependencies. Its lowest vertex rests on the pedestal at Z=0.22.
Roblox Studio import and gameplay appearance have not been checked.
