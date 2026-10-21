# Sakura gateway panorama

`portal-avenue-v1.png` is the transparent arch-shaped sakura avenue panorama,
generated with the built-in ImageGen tool on 2026-10-15. The exact generation
prompt is in `portal-avenue-v1.prompt.txt`. Original generation files are retained.

Roblox image asset: `rbxassetid://72399615078966`.

`SakuraJapaneseScenery.luau` displays the image inside the endpoint arch using
SurfaceGui `PortalInteriorView`, Face Back (+Z, toward the lobby). Its ImageLabel
has no background and does not receive input. The image is static and subject
to ordinary world occlusion. It creates a preview of the next sakura world;
no teleportation or live portal rendering is implemented.

The image was confirmed loaded and visible in Studio Edit. Published access
and mobile performance have not been tested. The temporary local upload server
was stopped after the Roblox upload; Rojo remains available on port 34872.
