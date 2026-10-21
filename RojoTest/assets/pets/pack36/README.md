# Imported pet pack preparation

Source: `C:/Users/userr/Downloads/36 петов.blend`.

`pets36.fbx` contains the 36 numbered pet collections, with one evaluated mesh
per pet. Camera, lights and the unnumbered Square Dog reference are excluded.
Rounded edges and weighted normals are evaluated. Each pet has a centered ground
origin and a distinct ASCII name. Color values are stored in the PetColor corner
attribute; the source packed normal map is embedded and also included separately.
The original Blender file is not overwritten.

`manifest.json` records names, evaluated mesh counts, bounds and triangle counts.
The pack has 143,094 triangles total; the largest pet has 9,252 triangles. Each
numbered JSON contains evaluated positions, faces, corner normals/UVs and colors
for future supported programmatic import. These are data files, not asset IDs.

Blender MCP successfully opened the source and exported the FBX. The user then
imported all 36 pets into `Workspace.pets36` through Studio's 3D Importer.

The green Uncommon egg now uses four selected meshes: Cactus (75691898082182),
Frog (84181357395199), Watermelon (87603658394189), Green Dragon (95208390767071).
Their original normal map is 87849863436690. `UncommonPetTemplates.rbxmx` maps to
ReplicatedStorage.Shared.PetTemplates through Rojo. `PetVisuals.prepare` uses
CreateMeshPartAsync/ApplyMesh at startup to hydrate engine-owned MeshSize data;
Rojo alone cannot set that read-only property. Templates retain vertex colors.

GameConfig.eggPets and rollEggPet share the same four-pet pool between server
hatching and egg cards. Chances are 45/30/20/5 percent, World 1 boosts are
2.4/3/5/16, and price remains 500 Wins. The Common pool and saved legacy pet IDs
remain valid. PetVisuals supplies real model previews for these cards, inventory,
hatch results, and equipped followers. No existing owned pets are converted.

Follower bodies now match the original Watermelon follower: 2.35514 studs wide
(the imported 1.8-stud body at scale 2.8 / 2.14). The four imported pets use the
same body scale instead of fitting wings, ears and flowers into the same bounding
box. Legacy generated followers use the same body width. Row spacing accounts
for full model widths, with a 0.65-stud gap; height offsets keep larger decorations
from lowering the pet bottoms into the ground. Inventory/card preview framing
continues to fit each full silhouette. Verified in Play with three equipped pets
and the legacy Dragon; their body widths match and no script errors were recorded.

The lilac Rainbow egg additionally uses Butterfly (77787103036779), Moon Cat
(114882986098354), Galaxy Cat (98199500064199), and Crystal Cat (102713818480793)
from the user's marked reference. These four models are appended to the existing
`UncommonPetTemplates.rbxmx` registry. They use
the same native mesh hydration, normal map, shared body scale and previews.
Chances are 45/30/20/5%; World 1 boosts are 18/22.5/37.5/120. Egg price stays
40,000 Wins. Existing pets are not converted. `tools/AddRainbowPetTemplates.py`
is safe to rerun and checks existing template asset IDs before adding anything.

The blue Rare egg uses Shark (115063071575500), Cloud Bird (139156573296911),
Angel Cat (132477174820706) and Ice Cat (107246809876827), also selected in the
user's reference. The same registry now contains twelve imported pet models.
Chances are 45/30/20/5%; World 1 boosts are 6/7.5/12.5/40 and the price remains
5,000 Wins. `tools/AddRarePetTemplates.py` appends those templates safely.
Existing owned pets are retained; cards, hatching and admin grants share the pool.

Character walking speed is 24 studs/second, applied by the server on each spawn
through GameConfig.CharacterWalkSpeed (previous Roblox default: 16).
