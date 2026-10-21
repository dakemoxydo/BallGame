# Ball display

## Current Studio stand placement

The active game now uses the ten true ball names in tier order, increasing
multipliers from ×1 through ×10, and Crowns prices. Labels follow the levitation.
`src/server/BallStand.luau` and `src/shared/GameConfig.luau` maintain this current
display; the one-off placement/label scripts below describe its earlier setup.
All ten models are available as gameplay templates in
`src/shared/BallTemplates.rbxmx`. Purchase and animation validation is documented
in the project README.

All ten balls now have labels above their bounds with a 0.65-stud gap.
The lower row labels now use Rubber Rookie, Steel Impact, Crystal Ice,
Volcano Heart, and Mechanical Reactor from left to right. Upper-right
labels use Black Hole and World Creator. Existing multipliers are preserved. Slots 8–10
have new decorative labels Dragon Stone, Thunder Stone, and Plasma Stone;
no progression entries or multipliers were added. `tools/LabelImportedBalls.luau`
applies this once and saves the seven original anchors to
`ServerStorage.WorldBackups.BeforeBallStandLabels`. All ten label positions
were checked above their balls and an Edit screenshot was inspected.

The imported `Workspace.AllBalls_NoTextures` models are now arranged on
`Workspace.ProgressionMap.EmptyItemStand` in the reference order: balls 1–5
left to right on the lower tier, balls 6–10 left to right on the upper tier,
when viewed from the plaza (+X). Slots are 5–1 and 10–6 respectively.
Models use 2.5 times their imported scale, centered pivots, and a quarter-turn
toward the plaza. Each bounding box rests 0.025 studs above its DisplayTop;
all ten fit their tiles. Display meshes are anchored and exclude collisions,
touches, and queries. Existing stone proxies are hidden; their prompts and
the existing stone names/progression are retained.

`tools/PlaceImportedBalls.luau` applies this placement once. Studio backup
`ServerStorage.WorldBackups.BeforeBallStandPlacement` preserves the imported
models, stand, and original stone proxies. All 23 stand parts retain their
transforms, sizes, and collision flags. An Edit screenshot confirmed both
rows and the order. Play was not run. Save the place to retain these edits.

`ball-display.blend` is the current editable scene containing ten upgrade balls.
Each row is placed left to right at X=0, 3.2, 6.4, 9.6, and 12.8, on separate pedestals.
The original five are at Y=0; tiers 6–10 form a second row at Y=4.6.
Ball roots are named `Ball_01_RubberRookie`, `Ball_02_SteelImpact`,
`Ball_03_CrystalIce`, `Ball_04_VolcanoHeart`, and `Ball_05_MechanicalReactor`.

The three newest models use simplified Roblox-style forms: a translucent faceted
ice sphere with a central diamond and three points; twelve dark pentagonal plates
over an orange core; and large reactor panels, a chunky belt, and a cyan front lens.
Their components remain separate and editable under their respective root empties.

`add_tiers_3_5.py` adds tiers 3–5 to a scene containing tiers 1–2, preventing duplicates.
`before-tiers-3-5.blend` preserves the prior two-ball scene. The first two balls'
mesh-object transforms were checked unchanged. Pedestal contact and the final
camera render were checked. `five-balls-preview.png` is the final render.

Tiers 3–5 have not been exported or imported into Roblox Studio. Blender glass and
emission materials will need equivalent Roblox materials during import.

The ice shell uses blue alpha transparency with the BLENDED surface method instead
of transmission/refraction. This keeps the central crystal visible in Material
Preview and avoids the dark tinted shell and dither grain. The pre-fix scene is
saved as `before-ice-color-fix.blend`.

`add_tiers_6_10.py` adds the second row using simple editable primitives. Their roots
are `Ball_06_PlasmaSatellite`, `Ball_07_ThunderSplit`, `Ball_08_DragonSun`,
`Ball_09_BlackHole`, and `Ball_10_WorldCreator`. The first row's mesh transforms
were checked unchanged. `before-second-row.blend` is the pre-addition backup.
`ten-balls-preview.png` shows the final two-row composition from the scene camera.
Tiers 6–10 have not been exported or imported into Roblox Studio.

Tiers 6–9 now use the revised faceted Roblox reference
`references/06-09-low-poly-roblox-v2.png`. Their ball geometry totals 296, 236,
264, and 272 triangles respectively, excluding their separate pedestals.
They use flat-shaded spheres, polygonal hoops, faceted satellites, closed armor
wedges, a geometric dragon head with rectangular eyes and dorsal fins, and a
segmented accretion disk. Their row X/Y positions are preserved; only their
height is adjusted to rest on the pedestal after rebuilding.
`rebuild_low_poly_6_9.py` implements this revision, and `before-low-poly-6-9.blend`
preserves the preceding scene. Models 1–5 and 10 were checked unchanged.
`LowPoly_6_9_Review` is an additional scene for inspection, sharing the four models
with the main display. `low-poly-6-9-preview.png` is the checked final render.
The earlier ten-ball preview predates this revision.

## Roblox import pack

`roblox-import/roblox-balls-10.fbx` contains the final ten balls without display
pedestals or studio objects. The pack includes fourteen mesh objects under ten
named ball roots. Transparent shells and the larger reactor/world components
are separate; every individual mesh is below 10,000 triangles. Colors are stored
in PNG textures with UVs, preserving the starter ball's existing rubber texture.
Modifiers are evaluated on export copies; the source blend is unchanged.
`export_roblox_pack.py` builds the pack and `validate_roblox_pack.py` checks a fresh
FBX import for all ten roots, mesh counts, UVs, triangles, and texture file links.
The validation passed in Blender; Roblox Studio import is not yet verified.
`roblox-balls-10.zip` bundles the FBX, textures, and Russian import instructions.
Set the two transparent shell MeshParts to Transparency=0.74 after import.

The original import pack is superseded by `roblox-balls-10-v2.zip` and
`roblox-import-v2/`. The original exporter compared evaluated material datablock
identities against original datablocks, incorrectly mapping all faces to the
first color swatch. The revised exporter matches material names and gives every
polygon positive UV area within its own color tile. Validation now samples the
texture at triangle UV centroids and verifies the expected color-region counts
after FBX reimport, in addition to geometry and texture-file checks. These checks
passed. Roblox Studio is not connected, so Studio validation remains pending.

The user's next import failed specifically with `base_color_texture: Upload failed`.
The PNG files were checked as valid 8-bit RGBA. The error does not identify why
Roblox rejected the image upload. `export_vertex_colors.py` creates an alternative
`roblox-vertex-colors/AllBalls_NoTextures.fbx` with colors stored as CORNER color
attributes, removing all image texture nodes and external image dependencies.
The file is also available under the ASCII-only path
`C:/Users/userr/Documents/RobloxBalls_VertexColor/AllBalls_NoTextures.fbx`.
FBX round-trip checks passed for fourteen meshes, retained color attributes, and
zero image texture nodes. Set MeshPart.Color to white and shell Transparency to
0.74 after import. The starter ball's original texture is approximated by vertex
colors in this alternate pack; fine rubber grain cannot be retained exactly.
Roblox Studio validation remains pending.
