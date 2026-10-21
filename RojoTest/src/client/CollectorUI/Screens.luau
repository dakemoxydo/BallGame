--!strict
local React = require(game.ReplicatedStorage.Packages.React)
local Config = require(game.ReplicatedStorage.Shared.GameConfig)
local U = require(script.Parent.Components)
local T = require(script.Parent.Theme)
local e = React.createElement
local S = {}
-- The delete confirmation covers the whole screen content and opens a dialog
-- on top of it. The overlay has to stay above the content it dims and the
-- dialog has to stay above the overlay, otherwise its buttons are dead.
local LAYER_CONFIRM = 70
local LAYER_CONFIRM_BOX = 75
local function label(text, x, y, w, h, size, color)
	return e(U.Label, {
		Text = text,
		Position = UDim2.fromOffset(x, y),
		Size = UDim2.fromOffset(w, h),
		TextSize = size,
		Color = color,
		Small = size < 20,
	})
end
local function button(name, text, x, y, w, h, callback, color, disabled, size)
	return e(U.Button, {
		Name = name,
		Text = text,
		Position = UDim2.fromOffset(x, y),
		Size = UDim2.fromOffset(w, h),
		OnActivated = callback,
		Color = color,
		Disabled = disabled,
		TextSize = size or 21,
	})
end
local function rarity(value)
	return T.Rarity[value] or T.Colors.Pets
end
local function childrenFrame(children, x, y, w, h)
	return e(
		"Frame",
		{ BackgroundTransparency = 1, Position = UDim2.fromOffset(x, y), Size = UDim2.fromOffset(w, h), ZIndex = 11 },
		children
	)
end
function S.Pets(p)
	local inventory = p.Inventory
	local pets, equipped = inventory.pets, inventory.equipped
	local selected, setSelected = React.useState(nil)
	local confirm, setConfirm = React.useState(false)
	local pet
	for _, item in pets do
		if item.uid == selected then
			pet = item
			break
		end
	end
	pet = pet or pets[1]
	local w, h = p.Width, p.Height
	local compact = w < 730 or p.Short
	local previewWidth = compact and 0 or math.floor(w * 0.31)
	local gap, gridW = 12, w - previewWidth - (compact and 0 or 16)
	local cols = gridW < 380 and 2 or 3
	local cardW = math.floor((gridW - 12 - (cols - 1) * gap) / cols)
	local footer = 62
	local gridH = h - footer
	-- Desktop displays exactly three rows; overflow scrolls within the inventory.
	local cardH = compact and 140 or math.floor((gridH - 24 - gap * 2) / 3)
	local slots, cards = math.max(9, #pets), {}
	for i = 1, slots do
		local item = pets[i]
		local def = item and Config.pet(item.id)
		local isEquipped = item and table.find(equipped, item.uid) ~= nil
		local chosen = item and pet and item.uid == pet.uid
		local content = {}
		if item then
			-- The list only draws a cheap badge: one 3D model for sixty pets
			-- would cost sixty render targets. The badge carries the shape of
			-- the pet and the mark of its rarity.
			local badge = math.max(24, math.min(cardW - 16, cardH - 58))
			content.Preview = e(U.PetBadge, {
				Def = def,
				Rarity = item.rarity,
				Size = UDim2.fromOffset(badge, badge),
				Position = UDim2.fromOffset(math.floor((cardW - badge) / 2), 4),
			})
			content.Name = label(item.name, 5, cardH - 50, cardW - 10, 24, 18)
			content.Power = label("×" .. item.boost .. " Skill", 5, cardH - 26, cardW - 10, 22, 18, T.Gold)
			if isEquipped then
				content.Check = e(U.Surface, {
					Color = T.Colors.Green,
					Radius = 9,
					Size = UDim2.fromOffset(28, 28),
					Position = UDim2.new(1, -32, 0, 4),
					NoShadow = true,
					Studs = false,
					ZIndex = 18,
					Children = { Mark = e(U.Label, { Text = "✓", TextSize = 20, ZIndex = 30 }) },
				})
			end
		end
		cards[tostring(i)] = e(U.Tile, {
			Name = item and "Pet_" .. item.uid or "EmptySlot" .. i,
			Position = UDim2.fromOffset(
				5 + (i - 1) % cols * (cardW + gap),
				6 + math.floor((i - 1) / cols) * (cardH + gap)
			),
			Size = UDim2.fromOffset(cardW, cardH),
			Color = item and T.plate(rarity(item.rarity)) or T.Slot,
			Quiet = item == nil,
			Studs = item ~= nil,
			Selected = chosen,
			Disabled = item == nil,
			OnActivated = function()
				if item then
					setSelected(item.uid)
					setConfirm(false)
				end
			end,
			Children = content,
		})
	end
	-- The counter of the footer. A narrow window has no room for the long
	-- caption, so it keeps the short one.
	local capacityText = #equipped .. " / 3 Equipped  •  " .. #pets .. " / 60 Pets"
	local capacityX, capacityW = math.floor(w * 0.44), math.floor(w * 0.56) - 4
	local bestText, bestWidth = "Equip Best", math.min(230, math.floor(w * 0.42))
	if compact then
		capacityText = #equipped .. "/3  •  " .. #pets .. "/60"
		capacityX, capacityW = 90, math.max(60, w - 94)
		bestText, bestWidth = "Best", 76
	end
	local result = {
		Grid = e(U.Scroll, {
			Name = "PetGrid",
			Size = UDim2.fromOffset(gridW, gridH),
			Height = math.ceil(slots / cols) * (cardH + gap) + 12,
			Children = cards,
		}),
		EquipBest = button("EquipBest", bestText, 4, h - 50, bestWidth, 44, function()
			p.Request("EquipBest")
		end, nil, p.Busy or #pets == 0),
		Capacity = label(capacityText, capacityX, h - 50, capacityW, 44, compact and 16 or 19, T.Muted),
	}
	if not compact then
		local x, pw = gridW + 16, previewWidth
		local detail = {}
		if pet then
			local def = Config.pet(pet.id)
			local isEquipped = table.find(equipped, pet.uid) ~= nil
			local full = not isEquipped and #equipped >= 3
			detail.Name = label(pet.name, 8, 8, pw - 16, 34, 24)
			detail.Rarity = label(pet.rarity, 8, 44, pw - 16, 26, 20, rarity(pet.rarity))
			detail.Preview = e(U.PetView, {
				Def = def,
				Key = pet.uid,
				Position = UDim2.fromOffset(12, 75),
				Size = UDim2.fromOffset(pw - 24, gridH - 224),
				Animated = true,
				ReducedMotion = p.Reduced,
			})
			detail.Power = label("×" .. pet.boost .. " Skill", 8, gridH - 145, pw - 16, 30, 25, T.Gold)
			detail.Equip = button(
				"EquipSelected",
				p.Busy and "Please wait…" or (isEquipped and "Unequip" or full and "Team full (3 / 3)" or "Equip"),
				12,
				gridH - 104,
				pw - 24,
				46,
				function()
					p.Request("Pet", pet.uid)
				end,
				isEquipped and T.Colors.Blue or T.Colors.Green,
				p.Busy or full
			)
			detail.Delete = button("DeleteSelected", "Delete Pet", 12, gridH - 49, pw - 24, 44, function()
				setConfirm(true)
			end, T.Colors.Red, p.Busy, 18)
		else
			detail.Art =
				e(U.Icon, { Kind = "Pets", Position = UDim2.fromOffset(35, 50), Size = UDim2.fromOffset(pw - 70, 165) })
			detail.Hint = e(U.Label, {
				Text = "Hatch an egg to meet your first pet",
				Position = UDim2.fromOffset(12, 220),
				Size = UDim2.fromOffset(pw - 24, 74),
				TextSize = 20,
				Wrap = true,
			})
			detail.Eggs = button("FindEggs", "Find Eggs", 12, gridH - 65, pw - 24, 46, function()
				p.Open("Eggs")
			end, T.Colors.Eggs)
		end
		result.Details = e(U.Slot, {
			Name = "PetDetails",
			Position = UDim2.fromOffset(x, 0),
			Size = UDim2.fromOffset(pw, gridH - 4),
			Color = T.Recess,
			Children = detail,
		})
	elseif pet then
		result.Capacity = nil
		result.EquipBest = button("EquipBest", "Best", 4, h - 50, 76, 44, function()
			p.Request("EquipBest")
		end, nil, p.Busy)
		local yes = table.find(equipped, pet.uid) ~= nil
		local full = not yes and #equipped >= 3
		result.EquipSelected = button(
			"EquipSelected",
			yes and "Unequip" or full and "Team Full" or "Equip",
			90,
			h - 50,
			math.max(100, w - 192),
			44,
			function()
				p.Request("Pet", pet.uid)
			end,
			yes and T.Colors.Blue or T.Colors.Green,
			p.Busy or full,
			18
		)
		result.Delete = button("DeleteSelected", "Delete", w - 92, h - 50, 86, 44, function()
			setConfirm(true)
		end, T.Colors.Red, p.Busy, 18)
	end
	if confirm and pet then
		result.Confirm = e("TextButton", {
			Name = "DeleteConfirmation",
			Text = "",
			AutoButtonColor = false,
			Size = UDim2.fromScale(1, 1),
			BackgroundColor3 = T.Outline,
			BackgroundTransparency = 0.15,
			ZIndex = LAYER_CONFIRM,
		}, {
			Box = e(U.Surface, {
				Size = UDim2.fromOffset(math.min(430, w - 12), 190),
				Position = UDim2.fromScale(0.5, 0.5),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Color = T.Body,
				ZIndex = LAYER_CONFIRM_BOX,
				Children = {
					Title = e(U.Label, {
						Text = "Delete " .. pet.name .. " permanently?",
						Position = UDim2.fromOffset(12, 12),
						Size = UDim2.new(1, -24, 0, 72),
						Wrap = true,
						TextSize = 23,
						ZIndex = 90,
					}),
					Keep = e(U.Button, {
						Text = "Keep",
						Position = UDim2.new(0, 12, 1, -64),
						Size = UDim2.new(0.5, -18, 0, 46),
						ZIndex = 90,
						OnActivated = function()
							setConfirm(false)
						end,
					}),
					Delete = e(U.Button, {
						Text = "Delete",
						Position = UDim2.new(0.5, 6, 1, -64),
						Size = UDim2.new(0.5, -18, 0, 46),
						Color = T.Colors.Red,
						ZIndex = 90,
						OnActivated = function()
							p.Request("DeletePet", pet.uid)
							setConfirm(false)
						end,
					}),
				},
			}),
		})
	end
	return childrenFrame(result, 0, 0, w, h)
end
function S.Eggs(p)
	local w, h = p.Width, p.Height
	local compact = w < 730
	local egg = Config.find(Config.Eggs, p.EggId) or Config.Eggs[1]
	local pool = Config.eggPets(egg.id)
	local cost = egg.cost * (p.Data.world == 2 and 10 or 1)
	local tabs = {}
	local tabW = math.floor((w - 18) / 4)
	for i, item in Config.Eggs do
		tabs[item.id] = button("EggTab" .. item.id, item.id, (i - 1) * (tabW + 6), 0, tabW, 44, function()
			p.SelectEgg(item.id)
		end, item.id == egg.id and T.Colors.Eggs or T.Colors.Slate, false, compact and 15 or 18)
	end
	local leftW = compact and 0 or math.floor(w * 0.34)
	local rightX = compact and 0 or leftW + 20
	local rightW = w - rightX
	local cols = compact and math.min(3, #pool) or #pool <= 4 and 2 or 3
	local rows = math.ceil(#pool / cols)
	local itemW = math.floor((rightW - (cols - 1) * 12 - 12) / cols)
	local itemH = math.floor((h - 184 - (rows - 1) * 12) / rows)
	itemH = math.max(110, itemH)
	local cards = {}
	local total = 0
	for _, item in pool do
		total += item.weight
	end
	for i, item in pool do
		local boost = item.boost * egg.boost * (p.Data.world == 2 and 3 or 1)
		cards[item.id] = e(U.Surface, {
			Color = T.plate(rarity(item.rarity)),
			Position = UDim2.fromOffset(
				(i - 1) % cols * (itemW + 12) + 4,
				math.floor((i - 1) / cols) * (itemH + 12) + 4
			),
			Size = UDim2.fromOffset(itemW, itemH),
			Children = {
				Pet = e(U.PetView, {
					Def = item,
					Key = item.id,
					Position = UDim2.fromOffset(6, 20),
					Size = UDim2.fromOffset(itemW - 12, itemH - 66),
				}),
				Chance = label(string.format("%g%%", item.weight / total * 100), 6, 3, itemW - 12, 24, 19, T.Gold),
				Name = label(item.name, 4, itemH - 45, itemW - 8, 21, 16),
				Boost = label("×" .. boost, 4, itemH - 24, itemW - 8, 20, 17, T.Gold),
			},
		})
	end
	local result = {
		Tabs = childrenFrame(tabs, 0, 0, w, 44),
		Name = label(egg.name, 8, 52, w - 16, 30, 25, T.Gold),
		-- The pool stays a scroll in every window size: it clips the cards, so
		-- they can never cover the hatch buttons, and scrolls the rows that
		-- do not fit.
		Pool = e(U.Scroll, {
			Name = "EggOutcomes",
			Position = UDim2.fromOffset(rightX, 91),
			Size = UDim2.fromOffset(rightW, h - 184),
			Height = rows * (itemH + 12) + 8,
			Children = cards,
		}),
		Hatch = button(
			"Hatch",
			"E • Hatch  /  " .. Config.format(cost) .. " Wins",
			4,
			h - 82,
			math.floor(w / 2) - 12,
			46,
			function()
				p.Request("Hatch", egg.id, 1)
			end,
			nil,
			p.Busy or #p.Inventory.pets >= 60,
			compact and 16 or 21
		),
		Triple = button(
			"Hatch3",
			"R • Hatch 3  /  " .. Config.format(cost * 3) .. " Wins",
			math.floor(w / 2) + 8,
			h - 82,
			math.floor(w / 2) - 12,
			46,
			function()
				p.Request("Hatch", egg.id, 3)
			end,
			T.Colors.Eggs,
			p.Busy or #p.Inventory.pets > 57,
			compact and 16 or 21
		),
		Hint = label("Walk to this egg in the world to hatch it", 5, h - 27, w - 10, 24, 17, T.Muted),
	}
	if not compact then
		result.Egg = e(U.Slot, {
			Position = UDim2.fromOffset(0, 91),
			Size = UDim2.fromOffset(leftW, h - 190),
			Color = T.Recess,
			Children = {
				Art = e(U.FloatingIcon, {
					Kind = "Egg",
					Position = UDim2.fromOffset(16, 14),
					Size = UDim2.new(1, -32, 1, -40),
					Reduced = p.Reduced,
				}),
			},
		})
	end
	return childrenFrame(result, 0, 0, w, h)
end
function S.Trails(p)
	local w, h = p.Width, p.Height
	local cols = w < 520 and 1 or w < 760 and 2 or 3
	local cw = math.floor((w - 20 - 16 * (cols - 1)) / cols)
	local ch = math.max(290, h - 42)
	local cards = {}
	for i = 2, #Config.Trails do
		local item = Config.Trails[i]
		local owned, equipped = p.Data.trails[item.id], p.Data.trail == item.id
		local index = i - 2
		local kind = item.id .. "Trail"
		cards[item.id] = e(U.Surface, {
			Name = "TrailCard" .. item.id,
			Color = T.plate(item.color),
			Selected = equipped,
			Size = UDim2.fromOffset(cw, ch),
			Position = UDim2.fromOffset(5 + index % cols * (cw + 16), 6 + math.floor(index / cols) * (ch + 20)),
			Children = {
				Name = label(item.name, 10, 10, cw - 20, 30, 23),
				Art = e(U.Icon, {
					Kind = kind,
					Position = UDim2.fromOffset(12, 48),
					Size = UDim2.fromOffset(cw - 24, ch - 245),
					Color = (item.id == "Blue" or item.id == "Purple") and item.color or nil,
				}),
				Preview = e(U.TrailPreview, {
					Position = UDim2.fromOffset(12, ch - 195),
					Size = UDim2.fromOffset(cw - 24, 78),
					Color = item.color,
					Rainbow = item.id == "Rainbow",
				}),
				Boost = label("×" .. item.boost .. " Wins", 8, ch - 112, cw - 16, 28, 23, T.Gold),
				State = label(
					equipped and "✓ Equipped" or owned and "Owned" or Config.format(item.cost) .. " Wins",
					8,
					ch - 80,
					cw - 16,
					24,
					18,
					T.Muted
				),
				Action = button(
					"TrailAction" .. item.id,
					p.Busy and "Please wait…"
						or equipped and "✓ Equipped"
						or owned and "Equip"
						or "Buy • " .. Config.format(item.cost),
					12,
					ch - 51,
					cw - 24,
					44,
					function()
						p.Request("Trail", item.id)
					end,
					equipped and T.Colors.Green or owned and T.Colors.Blue or T.Colors.Green,
					p.Busy or equipped,
					20
				),
			},
		})
	end
	return e(U.Scroll, {
		Name = "TrailCollection",
		Size = UDim2.fromOffset(w, h),
		Height = math.ceil((#Config.Trails - 1) / cols) * (ch + 20) + 12,
		Children = cards,
	})
end
function S.Shop(p)
	local w, h = p.Width, p.Height
	local cols = w < 600 and 1 or 2
	local small = w < 600
	local cw = math.floor((w - 16 - 16 * (cols - 1)) / cols)
	local children = {}
	local function buy(key)
		return function()
			p.Request("Product", key)
		end
	end
	local function caption(key)
		local product = Config.Products[key]
		if p.Data.perks[key] then
			return "Owned", true
		end
		if product.id == 0 then
			return "Unavailable", true
		end
		return "Buy • " .. product.price .. " Robux", p.Busy
	end
	local text, disabled = caption("StarterPack")
	children.Starter = e(U.Surface, {
		Color = T.plate(T.Colors.Shop),
		Position = UDim2.fromOffset(5, 6),
		Size = UDim2.fromOffset(w - 16, small and 250 or 180),
		Children = {
			Title = label("STARTER PACK", 16, 10, w - 48, 35, 28),
			Bolt = e(U.Icon, { Kind = "Skill", Position = UDim2.fromOffset(18, 54), Size = UDim2.fromOffset(88, 88) }),
			Trophy = e(
				U.Icon,
				{ Kind = "Wins", Position = UDim2.fromOffset(112, 54), Size = UDim2.fromOffset(88, 88) }
			),
			Contents = label(
				"10K Wins + 2× Skill",
				small and 16 or 222,
				small and 126 or 68,
				small and w - 48 or math.max(190, w - 470),
				30,
				small and 18 or 24,
				T.Gold
			),
			Price = label(
				Config.Products.StarterPack.price .. " Robux",
				small and 16 or w - 235,
				small and 152 or 55,
				small and w - 48 or 194,
				28,
				22,
				T.Gold
			),
			Buy = button(
				"BuyStarterPack",
				text,
				small and 16 or w - 235,
				small and 190 or 113,
				small and w - 48 or 194,
				46,
				buy("StarterPack"),
				nil,
				disabled,
				22
			),
		},
	})
	local offers = {
		{ "DoubleSkill", "2× Skill", "Skill", T.Colors.Green },
		{ "DoubleWins", "2× Wins", "Wins", T.Colors.Gold },
		{ "AutoThrow", "Auto Throw", "Rebirth", T.Colors.Red },
		{ "Skill10M", "+10M Skill", "Skill", T.Colors.Blue },
		{ "Skill100M", "+100M Skill", "Skill", T.Colors.Red },
		{ "Skill1B", "+1B Skill", "Skill", T.Colors.Purple },
	}
	local startY = small and 274 or 208
	for i, info in offers do
		local key, title, kind = info[1], info[2], info[3]
		local buyText, blocked = caption(key)
		children[key] = e(U.Surface, {
			Color = T.plate(info[4]),
			Size = UDim2.fromOffset(cw, 184),
			Position = UDim2.fromOffset(5 + (i - 1) % cols * (cw + 16), startY + math.floor((i - 1) / cols) * 204),
			Children = {
				Art = e(U.Icon, { Kind = kind, Position = UDim2.fromOffset(14, 15), Size = UDim2.fromOffset(88, 88) }),
				Title = label(title, 112, 17, cw - 126, 42, 24),
				Price = label(Config.Products[key].price .. " Robux", 112, 66, cw - 126, 28, 21, T.Gold),
				Buy = button("Buy" .. key, buyText, 12, 122, cw - 24, 46, buy(key), nil, blocked, 22),
			},
		})
	end
	local bottom = startY + math.ceil(#offers / cols) * 204
	children.EarnedAuto = button(
		"EarnAutoThrow",
		p.Data.perks.AutoThrow and "Auto Throw owned" or "Unlock Auto Throw • 2.5K Wins",
		6,
		bottom,
		w - 18,
		46,
		function()
			p.Request("UnlockAuto")
		end,
		T.Colors.Blue,
		p.Busy or p.Data.perks.AutoThrow,
		w < 500 and 17 or 22
	)
	return e(
		U.Scroll,
		{ Name = "ShopOffers", Size = UDim2.fromOffset(w, h), Height = bottom + 60, Children = children }
	)
end
function S.Hatch(p)
	local reveal, setReveal = React.useState(p.Reduced)
	local rotation, updateRotation = React.useBinding(0)
	React.useEffect(function()
		if p.Reduced then
			setReveal(true)
			return
		end
		local start = os.clock()
		local connection = game:GetService("RunService").RenderStepped:Connect(function()
			local t = os.clock() - start
			updateRotation(math.sin(t * 24) * (5 + t * 6))
			if t > 1.05 then
				setReveal(true)
			end
		end)
		local stop = task.delay(1.08, function()
			connection:Disconnect()
			updateRotation(0)
		end)
		return function()
			connection:Disconnect()
			pcall(task.cancel, stop)
		end
	end, {})
	local w, h = p.Width, p.Height
	if not reveal then
		return childrenFrame({
			Egg = e(U.Icon, {
				Kind = "Egg",
				Size = UDim2.fromOffset(250, 280),
				Position = UDim2.fromScale(0.5, 0.5),
				AnchorPoint = Vector2.new(0.5, 0.5),
				Rotation = rotation,
			}),
		}, 0, 0, w, h)
	end
	-- The server sends the pets of the hatch: an empty list must not divide by zero.
	local count = math.max(1, #p.Hatched)
	local cw = math.floor((w - 24 - 16 * (count - 1)) / count)
	local cards = {}
	for i, pet in p.Hatched do
		cards[pet.uid] = e(U.Surface, {
			Size = UDim2.fromOffset(cw, h - 74),
			Position = UDim2.fromOffset(8 + (i - 1) * (cw + 16), 4),
			Color = T.plate(rarity(pet.rarity)),
			Children = {
				Name = label(pet.name, 8, 12, cw - 16, 36, count == 3 and 20 or 28),
				Rarity = label(pet.rarity, 8, 50, cw - 16, 28, 21, rarity(pet.rarity)),
				Pet = e(U.PetView, {
					Def = Config.pet(pet.id),
					Key = pet.uid,
					Position = UDim2.fromOffset(14, 85),
					Size = UDim2.fromOffset(cw - 28, h - 222),
					Animated = true,
					ReducedMotion = p.Reduced,
				}),
				Boost = label("×" .. pet.boost .. " Skill", 8, h - 130, cw - 16, 36, 25, T.Gold),
			},
		})
	end
	cards.Continue = button("Continue", "Continue", math.floor((w - 240) / 2), h - 54, 240, 46, p.Close)
	return childrenFrame(cards, 0, 0, w, h)
end
return S
