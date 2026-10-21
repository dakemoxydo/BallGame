# Approved Collector UI artwork

`icons.png` is the transparent 4×2 source atlas generated from the user's approved
combined concept on 2026-10-20. The eight cells are Pets, Egg, Trails, Shop,
Skill, Wins, WhiteTrail and RedTrail. Roblox asset: `120359311191738`.
The logged-in Studio user and experience creator were both verified as
`11792184677` before uploading through Studio MCP. The served atlas uses
1024×512 coordinates, with 256×256 cells; Blue/Purple variants tint the white
trail, and Rainbow reuses the rainbow navigation artwork.

`src/client/CollectorUI/Art.luau` is the canonical source-to-ID mapping.
`Icons.luau` also uses these images for matching existing HUD subjects. Other
HUD subjects continue to use the previous checked atlas. No world meshes or
pet progression data were changed for this UI work. Pet cards render real
project templates in ViewportFrames, with a local block-pet fallback for IDs
that lack a template; they do not substitute invented concept pets.
