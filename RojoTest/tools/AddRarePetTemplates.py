"""Append the four selected blue-egg pets from the user's imported pet pack."""
from copy import deepcopy
from pathlib import Path
import xml.etree.ElementTree as ET

path = Path(__file__).resolve().parents[1] / 'assets/pets/pack36/UncommonPetTemplates.rbxmx'
assets = {
    'Shark': ('115063071575500', (3.6399998664855959, 2.5049991607666017, 1.625)),
    'CloudBird': ('139156573296911', (3.6399998664855959, 2.325000286102295, 1.5939990282058716)),
    'AngelCat': ('132477174820706', (3.6399998664855959, 2.4750003814697267, 1.594000220298767)),
    'IceCat': ('107246809876827', (2.25, 2.8550004959106447, 1.5939998626708985)),
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
    body.find("Item[@class='SurfaceAppearance']").set('referent', pet_id + 'Surface')
    folder.append(model)
tree.write(path, encoding='utf-8', xml_declaration=False)
print('Pet template registry:', len(folder.findall('Item')), 'models; four blue-egg pets present')
