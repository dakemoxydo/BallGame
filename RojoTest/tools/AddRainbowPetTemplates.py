"""Add the four selected, already imported pet assets to the Rojo template registry."""
from copy import deepcopy
from pathlib import Path
import xml.etree.ElementTree as ET

path = Path(__file__).resolve().parents[1] / 'assets/pets/pack36/UncommonPetTemplates.rbxmx'
assets = {
    'Butterfly': ('77787103036779', (3.5999999046325685, 2.5144290924072267, 1.5939990282058716)),
    'MoonCat': ('114882986098354', (2.25, 2.854999542236328, 1.5940008163452149)),
    'GalaxyCat': ('98199500064199', (1.9399999380111695, 2.4749999046325685, 1.8899999856948853)),
    'CrystalCat': ('102713818480793', (2.25, 2.8550000190734865, 1.5939990282058716)),
}
tree = ET.parse(path)
folder = tree.getroot().find("Item[@class='Folder']")
assert folder is not None
sample = folder.find("Item[@class='Model']")
assert sample is not None
for pet_id, (mesh_id, size) in assets.items():
    existing = next((m for m in folder.findall('Item') if m.findtext("Properties/string[@name='Name']") == pet_id), None)
    if existing is not None:
        assert existing.findtext("Item/Properties/Content[@name='MeshId']/url") == f'rbxassetid://{mesh_id}'
        continue
    model = deepcopy(sample)
    model.set('referent', pet_id)
    model.find("Properties/string[@name='Name']").text = pet_id
    body = model.find("Item[@class='MeshPart']")
    body.set('referent', pet_id + 'Body')
    props = body.find('Properties')
    props.find("Content[@name='MeshId']/url").text = 'rbxassetid://' + mesh_id
    for property_name in ('Size', 'MeshSize'):
        for axis, value in zip('XYZ', size):
            props.find(f"Vector3[@name='{property_name}']/{axis}").text = str(value)
    surface = body.find("Item[@class='SurfaceAppearance']")
    surface.set('referent', pet_id + 'Surface')
    folder.append(model)
tree.write(path, encoding='utf-8', xml_declaration=False)
print('Pet template registry:', len(folder.findall('Item')), 'models; four rainbow pets present')
