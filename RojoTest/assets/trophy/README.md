# Golden trophy import

Source: `C:/Users/userr/Downloads/кубак.blend` (unchanged).
`golden-trophy.fbx` exports the 28 trophy objects without the studio floor,
camera or lights, normalized to height 8 and a bottom-center origin.
There are 1,114 nondegenerate triangles, using the source's two assigned
materials (Royal gold and Golden highlights). 22 degenerate source triangles
are omitted. `trophy-geometry.json` preserves positions and corner normals for
the exact Studio MCP geometry transfer; Blender Z-up becomes Roblox Y-up.

`tools/ExportTrophy.py` produces both files. `tools/ImportTrophy.luau` consumes
the data transferred to `_G.TrophyImportData` in batches through Studio MCP.
It creates only a local EditableMesh preview named `Workspace.ImportedTrophy`
at (25,20.26,220), with height 8, no collisions/touches/queries, metal material,
and the source colors converted from linear RGB to sRGB. Two material meshes
share the same geometry origin. Base height, dimensions and an Edit screenshot
were checked. No existing map geometry was edited. Play was not run.

Persistent Roblox mesh upload is pending explicit user approval. An attempted
upload was rejected by automatic review before execution. No Roblox assets
were uploaded. The preview has `PendingMeshUpload=true`; it must not be treated
as a saved, published mesh asset. Retain FBX/JSON for recovery. Once approved,
upload the two EditableMeshes to the game creator's Roblox inventory and
replace the preview content with the resulting durable mesh asset IDs.

The user subsequently requested fivefold enlargement and placement on the grass
behind the low-tier pitches. `tools/PlaceTrophyBehindLanes.luau` sets the existing
preview to scale 5 (height 40), base (139,20,194.600037), with its front facing
the lanes (-X). Nine ground samples were inspected before placement; the base,
dimensions and overview were checked afterward. Original trophy state is in
`ServerStorage.WorldBackups.BeforeTrophyPlacement_20261020`. Upload remains pending.
