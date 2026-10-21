# Imported training field visuals

## Imported portals v6

SakuraCourtyard.apply builds the approved Japanese courtyard around the World 1
portal: a flat stepped-outline pink studded patch, six approach slabs connecting
to MainPlazaPath, two low stone lanterns, two short dark wood rails, four compact
flower groups and scattered petals. Its model is nested under World2Portal and
guards against duplicate creation. All 156 new parts exclude collisions, touches
and queries. The 9,521 existing part transforms, sizes and collision flags were
preserved; ten courtyard/path floor samples and the Edit overview passed.
Rojo build passed. Play was not run. Save the Studio place to retain scene edits.

World 1's World2Portal now uses the imported Rose Blossom sakura visual.
ImportedPortalVisuals.rbxmx preserves its 140 colored meshes as a Rojo-managed
ServerStorage template. SakuraPortal.apply adds a 30-stud-wide clone at the
existing gate's ground position and facing, hides the cyan frame/field/beams,
and places the WORLD 2 / 100K WINS label above the arch. PortalField and its
ground-level prompt retain position, size, settings and gameplay references.
The visual excludes collision, touch and queries. The original portal is backed
up in WorldBackups.BeforeSakuraPortal. Startup applies the visual after rankings
positioning. Rojo build and marker checks passed; Edit view inspected. Play travel
was not exercised. Save the open Studio place to retain scene edits.

The six portals are imported in Workspace.portals-v6-no-textures. The edit-time
tools/ColorImportedPortals.luau assigns violet, green, fire, ice, gold and pink
palettes separately to masonry, dark bases, crystals, ornaments and centers.
684 part transforms, sizes and collision flags were preserved. BeforePortalColoring
in ServerStorage.WorldBackups contains the uncolored source. Final Studio views
were inspected. Procedural Blender spiral shaders and animation are not reproduced
by this color pass. Portal placement and gameplay were not changed. Save the place.

ImportedTrainingFields.rbxmx contains normalized snapshots of the user's successfully imported no-texture MeshParts, using their real Roblox MeshIds and stored vertex colors. Seven template Models contain 406 decorative meshes. Rojo maps this folder to ServerStorage.ImportedTrainingFields.

ImportedFields.luau clones each template into ProgressionMap.TrainingZone.TrainingLane1–7.ImportedField. Pitch footprints match original 34,38,42,46,50,54,58 × 13 studs; earth base matches existing Foundations exactly. Turf bed matches existing TrainingStrip CFrame and Size. Gates face +X. TrainingStrip, Foundation and StartingPad CFrame/Size are preserved; original floor collision remains while decorative meshes are non-collidable/non-queryable. Old overlays, pads, arrows, stones and board slabs are hidden. Rebirth labels retained and raised above gates. Penalty spot matches original StartingPad position in XZ.

Studio backup: ServerStorage.WorldBackups.BeforeImportedFields contains previous TrainingZone, SkippingWorld, SurfaceRepairs and the imported source model (originally positioned ~114 studs below map). Original imported source is no longer in Workspace. User must save the current place to preserve live edits. World2 existing arena intentionally unchanged; freshly generated World2 can clone new visuals.

Validation: all 7 gameplay marker sizes/positions compared to backup, 63 floor raycasts passed, Play first-lane skill increased from 231 to 245 in 2 seconds, console clean. Edit screenshot checked. Rojo build succeeded with templates. The screenshot-derived field geometry, not game mechanics, is changed. This no-texture import lacks studs bitmap detail.
