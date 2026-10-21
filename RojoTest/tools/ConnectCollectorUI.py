"""One-time source migration; the previous client is preserved under backups/."""
from pathlib import Path

path = Path(__file__).resolve().parents[1] / 'src/client/init.client.luau'
source = path.read_text(encoding='utf-8')
assert 'local collectorUI' not in source, 'Already migrated'
source = source.replace('local adminUI\n', 'local adminUI\nlocal collectorUI\n', 1)
source = source.replace('local function closePanel()\n', 'local function closePanel()\n\tif collectorUI then collectorUI:close() collectorUI:setHidden(false) end\n', 1)
anchor = 'local function shell(name,kind,width,height)'
source = source.replace(anchor, '''local function openCollector(name, kind, eggId)
	closePanel() currentPanel=name hud.Visible=false
	TweenService:Create(blur,TweenInfo.new(0.18),{Size=14}):Play()
	collectorUI:setHidden(false) collectorUI:open(kind,eggId)
end
''' + anchor, 1)
source = source.replace('closePanel() currentPanel=name hud.Visible=false\n\tTweenService', 'closePanel() currentPanel=name hud.Visible=false\n\tif collectorUI then collectorUI:setHidden(true) end\n\tTweenService', 1)
# Keep new React windows visible; the previous replacement targets openCollector.
source = source.replace('collectorUI:setHidden(false) collectorUI:open(kind,eggId)', 'collectorUI:setHidden(false) collectorUI:open(kind,eggId)', 1)
source = source.replace('local function shell(name,kind,width,height)\n\tclosePanel() currentPanel=name hud.Visible=false', 'local function shell(name,kind,width,height)\n\tclosePanel() currentPanel=name hud.Visible=false\n\tif collectorUI then collectorUI:setHidden(true) end', 1)
def replace_between(start, end, value):
    global source
    a, b = source.index(start), source.index(end, source.index(start))
    source = source[:a] + value + '\n' + source[b:]
replace_between('local function openTrails()', 'local function openSettings()', 'local function openTrails() openCollector("Trails","Trails") end')
replace_between('local function openPets()', 'local function openGifts()', 'local function openPets() openCollector("Pets","Pets") end')
replace_between('local function openShop()', 'local function openEgg(id)', 'local function openShop() openCollector("Shop","Shop") end')
replace_between('local function openEgg(id)', 'openPanel=function(name)', '''local function openEgg(id)
	local egg=Config.find(Config.Eggs,id) if not egg then return end
	activeEgg=id openCollector(egg.name,"Eggs",id)
end''')
source = source.replace('openPanel=function(name)\n', 'openPanel=function(name)\n\tif currentPanel==name then closePanel() return end\n\tif name=="Eggs" then openEgg(activeEgg) return end\n', 1)
replace_between('-- HUD matches the proportions', 'local auto=button', '''collectorUI=require(script.CollectorUI).mount({send=send,close=closePanel,
	open=function(name) if name=="Eggs" and currentPanel==Config.find(Config.Eggs,activeEgg).name then closePanel() else openPanel(name) end end,
	selectEgg=function(id) activeEgg=id currentPanel=Config.find(Config.Eggs,id).name end})
-- Legacy stats continue to update without a second navigation surface.
hudRefs.rebirthPercent=text(hud,"RebirthProgress","0%",0,0,1,1,17)
hudRefs.rebirthPercent.Visible=false
''')
replace_between('local function hatchAnimation(pets)', 'local trainingStone=nil', '''local function hatchAnimation(pets)
	if hatchBusy then return end
	closePanel() hatchBusy=true currentPanel="Hatch" hud.Visible=false
	TweenService:Create(blur,TweenInfo.new(0.2),{Size=18}):Play()
	collectorUI:setHidden(false) collectorUI:hatch(pets)
end''')
source = source.replace('latest=info if adminUI then adminUI.update(info) end', 'latest=info if adminUI then adminUI.update(info) end\n\tcollectorUI:update(info)\n\tcollectorUI:setHidden(flight~=nil or (currentPanel~=nil and currentPanel~="Pets" and currentPanel~="Trails" and currentPanel~="Shop" and currentPanel~="Hatch" and currentPanel~=Config.find(Config.Eggs,activeEgg).name))', 1)
source = source.replace('if me then restoreTrainingCamera() closePanel() flight=token powerText.Visible=false end', 'if me then restoreTrainingCamera() closePanel() flight=token powerText.Visible=false collectorUI:setHidden(true) end', 1)
source = source.replace('closePanel() currentPanel="Admin" hud.Visible=false', 'closePanel() currentPanel="Admin" hud.Visible=false collectorUI:setHidden(true)', 1)
path.write_text(source, encoding='utf-8')
