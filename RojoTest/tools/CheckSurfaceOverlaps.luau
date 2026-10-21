-- Read-only Studio audit. Wedge side rectangles conservatively enclose their triangles.
-- Ignores fully occluded faces and reports coincident or close parallel exposed faces.
local root = workspace.ProgressionMap
local axes = { Vector3.xAxis, Vector3.yAxis, Vector3.zAxis }
local bins = {}
local parts = 0
local solid = {}
for _, p in root:GetDescendants() do
	if ((p:IsA("Part") and p.Shape == Enum.PartType.Block) or p:IsA("WedgePart")) and p.Transparency < 1 then
		parts += 1
		if p:IsA("Part") then
			table.insert(solid, p)
		end
		local sizes = { p.Size.X, p.Size.Y, p.Size.Z }
		for a = 1, 3 do
			for _, sign in { -1, 1 } do
				if p:IsA("WedgePart") and ((a == 2 and sign == 1) or (a == 3 and sign == -1)) then
					continue
				end
				local n = p.CFrame:VectorToWorldSpace(axes[a]) * sign
				local c = p.Position + n * sizes[a] / 2
				local u = p.CFrame:VectorToWorldSpace(axes[a % 3 + 1])
				local v = p.CFrame:VectorToWorldSpace(axes[(a + 1) % 3 + 1])
				local h = sizes[a % 3 + 1] / 2
				local k = sizes[(a + 1) % 3 + 1] / 2
				local function clean(x)
					return if math.abs(x) < 0.0001 then 0 else x
				end
				local key = string.format("%.4f,%.4f,%.4f", clean(n.X), clean(n.Y), clean(n.Z))
				bins[key] = bins[key] or {}
				table.insert(bins[key], { p = p, n = n, c = c, u = u, v = v, h = h, k = k, a = a, sign = sign })
			end
		end
		if p:IsA("WedgePart") then
			local n = p.CFrame:VectorToWorldSpace(Vector3.new(0, p.Size.Z, -p.Size.Y).Unit)
			local u = p.CFrame.RightVector
			local v = p.CFrame:VectorToWorldSpace(Vector3.new(0, p.Size.Y, p.Size.Z).Unit)
			local function clean(x)
				return if math.abs(x) < 0.0001 then 0 else x
			end
			local key = string.format("%.4f,%.4f,%.4f", clean(n.X), clean(n.Y), clean(n.Z))
			bins[key] = bins[key] or {}
			table.insert(bins[key], {
				p = p,
				n = n,
				c = p.Position,
				u = u,
				v = v,
				h = p.Size.X / 2,
				k = math.sqrt(p.Size.Y ^ 2 + p.Size.Z ^ 2) / 2,
				a = 4,
				sign = 1,
			})
		end
	end
end
local hits = {}
local counts = {}
local function overlap(f, g)
	for _, axis in { f.u, f.v, g.u, g.v } do
		local r = f.h * math.abs(f.u:Dot(axis))
			+ f.k * math.abs(f.v:Dot(axis))
			+ g.h * math.abs(g.u:Dot(axis))
			+ g.k * math.abs(g.v:Dot(axis))
		if r - math.abs((g.c - f.c):Dot(axis)) < 0.015 then
			return false
		end
	end
	return true
end

local function exposed(f, g)
	local poly = { { -f.h, -f.k }, { f.h, -f.k }, { f.h, f.k }, { -f.h, f.k } }
	local delta = g.c - f.c
	for _, plane in { { g.u, g.h }, { -g.u, g.h }, { g.v, g.k }, { -g.v, g.k } } do
		local axis, limit = plane[1], plane[2]
		local function distance(q)
			return q[1] * f.u:Dot(axis) + q[2] * f.v:Dot(axis) - delta:Dot(axis) - limit
		end
		local nextPoly = {}
		for i, q in poly do
			local r = poly[i % #poly + 1]
			local dq, dr = distance(q), distance(r)
			if dq <= 0 then
				table.insert(nextPoly, q)
			end
			if (dq < 0) ~= (dr < 0) then
				local t = dq / (dq - dr)
				table.insert(nextPoly, { q[1] + (r[1] - q[1]) * t, q[2] + (r[2] - q[2]) * t })
			end
		end
		poly = nextPoly
		if #poly < 3 then
			return false
		end
	end
	local x, y = 0, 0
	for _, q in poly do
		x += q[1] / #poly
		y += q[2] / #poly
	end
	local samples = { { x, y } }
	for _, q in poly do
		table.insert(samples, { x + (q[1] - x) * 0.9, y + (q[2] - y) * 0.9 })
	end
	for _, q in samples do
		local point = f.c + f.u * q[1] + f.v * q[2] + f.n * 0.025
		local hidden = false
		for _, p in solid do
			if p ~= f.p and p ~= g.p and p.Transparency < 0.5 then
				local t = p.CFrame:PointToObjectSpace(point)
				local s = p.Size / 2
				if math.abs(t.X) < s.X - 0.001 and math.abs(t.Y) < s.Y - 0.001 and math.abs(t.Z) < s.Z - 0.001 then
					hidden = true
					break
				end
			end
		end
		if not hidden then
			return true
		end
	end
	return false
end

for _, faces in bins do
	table.sort(faces, function(a, b)
		return a.n:Dot(a.c) < b.n:Dot(b.c)
	end)
	for i = 1, #faces do
		for j = i + 1, #faces do
			local f, g = faces[i], faces[j]
			if g.n:Dot(g.c) - f.n:Dot(f.c) > 0.035 then
				break
			end
			if f.p ~= g.p and overlap(f, g) and exposed(f, g) then
				local pair = f.p.Name .. " / " .. g.p.Name .. " axis" .. f.a
				counts[pair] = (counts[pair] or 0) + 1
				if #hits < 70 then
					table.insert(
						hits,
						{ a = f.p:GetFullName(), b = g.p:GetFullName(), normal = tostring(f.n), plane = f.n:Dot(f.c) }
					)
				end
			end
		end
	end
end
return { parts = parts, counts = counts, samples = hits, tolerance = 0.035 }
