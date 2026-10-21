# Roblox importer texture-upload workaround

The Studio screenshot reports `base_color_texture: Upload failed`, without naming an individual image or identifying a cause. The original FBX reads successfully and no mesh exceeds 1,740 triangles. Original textures included 3–8 by 1 pixel palettes and packed images; these may be related but the failure cause is unconfirmed.

`training-fields-v2.fbx` preserves all 406 meshes and positions, explicitly triangulates faces, and uses relative external texture references. All 22 image dependencies are standard 512 × 512 RGB PNG files in this folder. Keep FBX and PNG files together. Original scene/file untouched. `export_compatible.py` records the conversion through Blender MCP.

Validation: every PNG read back as RGB 512 × 512; FBX reimported in Blender, including all image dependencies. Successful Roblox Studio upload remains unverified. If Studio again reports upload failure, retry uploading one PNG separately to determine whether the account/service can currently upload images. The generic screenshot does not establish a geometry fault or specific texture limit violation.
