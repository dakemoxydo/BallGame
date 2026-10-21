# Imported oak

Current state: replacement was rolled back because unuploaded EditableMesh
content appears as checkerboard boxes in Play. All 62 original tree groups are
back in Workspace. Pending oak copies and the display preview are parked in
`ServerStorage.WorldBackups.PendingOakReplacement`. Permanent FBX import is
required before trying the replacement again.

Source: `source.blend`, copied from the user's `Downloads/дуб.blend`.
`oak.fbx` is the permanent import file. The model contains 3,792 triangles
across 55 Blender objects. Material colours are preserved.

Studio currently uses an EditableMesh preview. Automated mesh asset upload
returned `CreateAssetAsync and CreateAssetVersionAsync are not available yet`.
The mesh still needs a standard FBX import and upload before it can be relied
on in a saved, published game. Studio Play cannot render this Object content.
A local preview renderer was also blocked by the experience's disabled
EditableMesh API. The experiment was removed without changing security settings.
The current replacement is visible in Edit only; permanent FBX import remains
necessary for both Play and the published game.

The selected right-hand oak supplied the replacement geometry. Its geometry
was centred without editing the source file, and its model pivot was moved to
the base. 62 trees with visible parts were replaced: 31 in each world. Existing positions
and approximate heights were retained; leaves have no collisions or queries.
The previously collidable trunks retain their original narrow proxies.
Fully hidden legacy trees, cactus, crystal and moon decorations were left alone.
The second pass also replaced 24 partially hidden legacy palms whose leaves
were still visible. Verification found zero visible old tree pieces in both
worlds, and all 62 oak pivots match the base of their visual bounding boxes.

Scene locations:

- `ServerStorage.Assets.Environment.Oak`: normalized template.
- `Workspace.ProgressionMap.ImportedOakTrees`: first-world trees.
- `Workspace.World2Map.ImportedOakTrees`: second-world trees.
- `ServerStorage.WorldBackups.BeforeOakTreeReplacement`: original trees with
  their original-parent references, plus the unnormalized preview.

`replacement-manifest.json` records every replacement position and height.
`tools/ReplaceTreesWithOak.luau` performs the scene edit and guards against
accidental repeated replacement. `tools/ReplaceRemainingPalmTrees.luau` handles
the partially hidden palms. Neither script is a runtime map generator.
