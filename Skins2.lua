-- Combined Addon Menus - ten more skins (0.3.37), designed by an Opus agent from the skin rules alone.
-- Loaded after Skins.lua. Each one is a full table (no theme() helper). Numbers continue after the skins in Skins.lua.
-- Extra (below) adds two drawing parts the first skins did not need: deco.margin and deco.shadow.

local ADDON, ns = ...
local Skins = ns.Skins

-- engine_additions.lua: two new deco primitives (Lua 5.1, textures only).
--
--   deco.margin  (used by: Ledger)
--     A vertical rule, or a double rule, down the left side of the frame, like
--     the red margin on ledger or exercise-book paper. It sits in the left
--     padding, so it never crosses row text.
--     spec = { x = px from the left edge, th = line width, gap = px between two
--              lines (omit for one line), inset = px kept clear at top and
--              bottom, a = alpha, color = colour name }
--
--   deco.shadow  (used by: Toybox at full strength, Broadsheet soft)
--     A hard drop shadow offset down and right, with no blur. Drawn as two
--     strips OUTSIDE the frame (right side and bottom), so it stays correct
--     under a see-through frame and does not depend on layer order.
--     spec = { x = px right (> 0), y = px down (< 0), a = alpha, color = name }
--
-- Colour names follow the existing deco rule: "white", "black", "accent",
-- or nil for the frame border colour.
--
-- How to wire it in (the existing paint code is not known to this file):
-- after the existing deco parts are drawn, call Extra.apply(frame, skin).
-- It hides its own old textures first, so switching skins is safe.

local Extra = {}

local function rgb(skin, name)
	if name == "white" then return 1, 1, 1 end
	if name == "black" then return 0, 0, 0 end
	local c = (name == "accent") and skin.accent or skin.frameBorder
	return c[1], c[2], c[3]
end

-- One texture per key, kept on the frame and reused on the next skin change.
local function tex(frame, key, layer, sub)
	local pool = frame.camExtraTex
	if not pool then
		pool = {}
		frame.camExtraTex = pool
	end
	local t = pool[key]
	if not t then
		t = frame:CreateTexture(nil, layer, nil, sub)
		pool[key] = t
	end
	t:ClearAllPoints()
	t:Show()
	return t
end

function Extra.hide(frame)
	if frame.camExtraTex then
		for _, t in pairs(frame.camExtraTex) do t:Hide() end
	end
end

function Extra.margin(frame, spec, skin)
	local r, g, b = rgb(skin, spec.color)
	local a = spec.a or 1
	local th = spec.th or 1
	local inset = spec.inset or 0
	local xs = { spec.x or 6 }
	if spec.gap then xs[2] = xs[1] + th + spec.gap end
	for i, x in ipairs(xs) do
		-- BACKGROUND sublevel 1: above the backdrop fill (-8), below text.
		local t = tex(frame, "margin" .. i, "BACKGROUND", 1)
		t:SetColorTexture(r, g, b, a)
		t:SetPoint("TOPLEFT", frame, "TOPLEFT", x, -inset)
		t:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", x, inset)
		t:SetWidth(th)
	end
end

function Extra.shadow(frame, spec, skin)
	local r, g, b = rgb(skin, spec.color or "black")
	local a = spec.a or 1
	local x = spec.x or 4
	local y = spec.y or -4
	-- Right strip: beside the frame, from y below its top down to y below its bottom.
	local right = tex(frame, "shadowR", "BACKGROUND", -8)
	right:SetColorTexture(r, g, b, a)
	right:SetPoint("TOPLEFT", frame, "TOPRIGHT", 0, y)
	right:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", x, y)
	-- Bottom strip: under the frame, from x right of its left edge to its right edge.
	local bottom = tex(frame, "shadowB", "BACKGROUND", -8)
	bottom:SetColorTexture(r, g, b, a)
	bottom:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", x, 0)
	bottom:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, y)
end

function Extra.apply(frame, skin, small)
	Extra.hide(frame)
	local d = skin.deco
	if not d then return end
	if d.margin and not small then Extra.margin(frame, d.margin, skin) end
	if d.shadow then Extra.shadow(frame, d.shadow, skin) end
end

-- new_skins.lua: ten window skins for Combined Addon Menus.
-- Returns an array of skin tables. Colours are {r,g,b} or {r,g,b,a}, 0..1.
--
-- Two skins use decorations that are not in the engine yet (see
-- engine_additions.lua): deco.margin (Ledger) and deco.shadow (Toybox,
-- Broadsheet). An engine without them simply skips those keys; the skin
-- still draws, it only loses that one touch.
--
-- Button styles with "no border" use a 1px edge with a fully clear border
-- colour, so they look the same whether the engine treats a nil border as
-- "no border" or not.

local WHITE    = "Interface\\Buttons\\WHITE8X8"
local TIP_BG   = "Interface\\Tooltips\\UI-Tooltip-Background"
local TIP_EDGE = "Interface\\Tooltips\\UI-Tooltip-Border"
local DLG_BG   = "Interface\\DialogFrame\\UI-DialogBox-Background"
local DLG_EDGE = "Interface\\DialogFrame\\UI-DialogBox-Border"
local FRIZ     = "Fonts\\FRIZQT__.TTF"
local ARIALN   = "Fonts\\ARIALN.TTF"
local SKURRI   = "Fonts\\SKURRI.TTF"

-- A flat backdrop: solid fill plus a solid edge `px` thick. New table each call.
local function flat(px)
	return {
		bgFile = WHITE, edgeFile = WHITE, tile = false, tileSize = 0, edgeSize = px,
		insets = { left = px, right = px, top = px, bottom = px },
	}
end

-- A fully clear colour. New table each call so no skin shares a colour table.
local function clear()
	return { 0, 0, 0, 0 }
end

local NEW = {

	---------------------------------------------------------------- 1
	{
		name = "Ledger",
		desc = "Cream bookkeeping paper with green ruled lines, a red ink margin and underlined entries.",
		logo = "classic",
		font = ARIALN, flags = "", size = 13, titleSize = 16, pad = 13,
		frame = flat(1),
		frameBg     = { 0.97, 0.95, 0.86, 1 },
		frameBorder = { 0.42, 0.55, 0.42, 1 },
		title  = { 0.08, 0.30, 0.18 },
		text   = { 0.12, 0.12, 0.10 },
		muted  = { 0.36, 0.38, 0.32 },
		line   = { 0.50, 0.70, 0.56, 0.90 },
		accent = { 0.78, 0.14, 0.14 },
		button = {
			backdrop = flat(1), bg = clear(), border = clear(),
			hover = { 0.50, 0.70, 0.56, 0.30 },
			text = { 0.08, 0.30, 0.18 },
			underline = { 0.78, 0.14, 0.14, 1 },
		},
		input = {
			backdrop = flat(1), bg = { 1, 1, 1, 0.55 }, border = clear(),
			hover = { 1, 1, 1, 0.90 },
			text = { 0.12, 0.12, 0.10 },
			underline = { 0.42, 0.55, 0.42, 1 },
		},
		deco = {
			bar    = { h = 2, inset = 3, color = "accent" },                        -- red top rule
			margin = { x = 5, th = 1, gap = 2, inset = 0, a = 0.85, color = "accent" }, -- NEW: red double margin
		},
	},

	---------------------------------------------------------------- 2
	{
		name = "Foundry",
		desc = "A bolted iron plate in bronze bands, lit orange from the forge below.",
		logo = "classic",
		font = FRIZ, flags = "OUTLINE", size = 12, titleSize = 17, pad = 16,
		frame = {
			bgFile = DLG_BG, edgeFile = DLG_EDGE, tile = true, tileSize = 32, edgeSize = 32,
			insets = { left = 11, right = 12, top = 12, bottom = 11 },
		},
		frameBg     = { 0.62, 0.62, 0.66, 1 },   -- multiplies the dark dialog texture
		frameBorder = { 0.78, 0.74, 0.70, 1 },   -- dulls the gold border towards bronze
		title  = { 1.00, 0.76, 0.32 },
		text   = { 0.92, 0.90, 0.86 },
		muted  = { 0.72, 0.69, 0.64 },
		line   = { 0.42, 0.34, 0.28, 0.85 },
		accent = { 1.00, 0.45, 0.10 },
		button = {
			backdrop = flat(1), bg = { 0.27, 0.26, 0.26, 1 }, border = { 0.06, 0.05, 0.05, 1 },
			hover = { 0.46, 0.24, 0.09, 1 },
			text = { 1.00, 0.88, 0.66 },
			bevel = true,
		},
		input = {
			backdrop = flat(1), bg = { 0.05, 0.05, 0.05, 0.92 }, border = { 0.40, 0.35, 0.30, 1 },
			hover = { 0.09, 0.08, 0.07, 0.95 },
			text = { 0.95, 0.92, 0.85 },
		},
		deco = {
			inner   = { inset = 13, th = 1, a = 0.70, color = "black" },     -- groove inside the band
			corners = { kind = "square", inset = 12, size = 3, th = 1 },      -- bolt heads on the groove, border colour
			sheen   = { top = 0, bot = 0.22, color = "accent" },             -- forge light from below
		},
	},

	---------------------------------------------------------------- 3
	{
		name = "Amber Monitor",
		desc = "A 1980s amber phosphor terminal: black glass, glowing letters and scan lines.",
		logo = "classic",
		font = ARIALN, flags = "MONOCHROME", size = 13, titleSize = 15, pad = 12,
		frame = flat(2),
		frameBg     = { 0.04, 0.03, 0.01, 0.97 },
		frameBorder = { 0.62, 0.38, 0.03, 1 },
		title  = { 1.00, 0.76, 0.22 },
		text   = { 1.00, 0.69, 0.00 },
		muted  = { 0.74, 0.50, 0.06 },
		line   = { 0.62, 0.38, 0.03, 0.45 },
		accent = { 1.00, 0.62, 0.00 },
		button = {
			backdrop = flat(1), bg = clear(), border = { 0.85, 0.55, 0.05, 1 },
			hover = { 0.40, 0.24, 0.00, 1 },
			text = { 1.00, 0.72, 0.10 },
		},
		input = {
			backdrop = flat(1), bg = { 0, 0, 0, 1 }, border = { 0.62, 0.38, 0.03, 1 },
			hover = { 0.12, 0.07, 0.00, 1 },
			text = { 1.00, 0.69, 0.00 },
		},
		deco = {
			inner = { inset = 5, th = 1, a = 0.35, color = "accent" },       -- tube bezel
			glow  = {                                                        -- phosphor bloom
				{ inset = -1, a = 0.45, color = "accent" },
				{ inset = -2, a = 0.22, color = "accent" },
				{ inset = -3, a = 0.10, color = "accent" },
			},
			sheen = { top = 0.07, bot = 0, color = "white" },               -- curved glass catching light
			scan  = { gap = 3, a = 0.35 },
		},
	},

	---------------------------------------------------------------- 4
	{
		name = "Blueprint",
		desc = "A draftsman's cyanotype: white ink lines on blue, with registration marks at the corners.",
		logo = "classic",
		font = ARIALN, flags = "", size = 13, titleSize = 16, pad = 14,
		frame = flat(1),
		frameBg     = { 0.09, 0.27, 0.55, 1 },
		frameBorder = { 0.85, 0.92, 1.00, 0.90 },
		title  = { 1.00, 1.00, 1.00 },
		text   = { 0.93, 0.96, 1.00 },
		muted  = { 0.72, 0.82, 0.95 },
		line   = { 0.85, 0.92, 1.00, 0.30 },
		accent = { 0.70, 0.90, 1.00 },
		button = {
			backdrop = flat(1), bg = clear(), border = { 0.85, 0.92, 1.00, 0.85 },
			hover = { 1, 1, 1, 0.16 },
			text = { 1.00, 1.00, 1.00 },
		},
		input = {
			backdrop = flat(1), bg = { 0.05, 0.18, 0.40, 1 }, border = { 0.85, 0.92, 1.00, 0.60 },
			hover = { 0.07, 0.22, 0.47, 1 },
			text = { 1.00, 1.00, 1.00 },
		},
		deco = {
			inner   = { inset = 4, th = 1, a = 0.40, color = "white" },             -- drawing border
			corners = { kind = "bracket", inset = 4, len = 16, th = 2, color = "white" }, -- registration marks
			scan    = { gap = 12, a = 0.12 },                                      -- faint ruled grid
		},
	},

	---------------------------------------------------------------- 5
	{
		name = "Smoked Glass",
		desc = "A tinted glass pane floating over the world, with a soft shadow and light across its top.",
		logo = "classic",
		font = FRIZ, flags = "", size = 12, titleSize = 15, pad = 12,
		frame = flat(1),
		frameBg     = { 0.05, 0.06, 0.08, 0.82 },
		frameBorder = { 1, 1, 1, 0.22 },
		title  = { 1.00, 1.00, 1.00 },
		text   = { 0.94, 0.95, 0.97 },
		muted  = { 0.84, 0.86, 0.90 },
		line   = { 1, 1, 1, 0.10 },
		accent = { 0.55, 0.80, 1.00 },
		button = {
			backdrop = flat(1), bg = { 1, 1, 1, 0.06 }, border = { 1, 1, 1, 0.16 },
			hover = { 1, 1, 1, 0.15 },
			text = { 1.00, 1.00, 1.00 },
		},
		input = {
			backdrop = flat(1), bg = { 0, 0, 0, 0.35 }, border = { 1, 1, 1, 0.12 },
			hover = { 0, 0, 0, 0.50 },
			text = { 1.00, 1.00, 1.00 },
			underline = { 0.55, 0.80, 1.00, 0.90 },
		},
		deco = {
			inner = { inset = 1, th = 1, a = 0.10, color = "white" },        -- polished glass edge
			sheen = { top = 0.10, bot = 0, color = "white" },
			glow  = {                                                        -- soft drop shadow
				{ inset = -1, a = 0.35, color = "black" },
				{ inset = -2, a = 0.22, color = "black" },
				{ inset = -3, a = 0.12, color = "black" },
				{ inset = -4, a = 0.05, color = "black" },
			},
		},
	},

	---------------------------------------------------------------- 6
	{
		name = "Porcelain",
		desc = "Delft blue-and-white china: glazed white with a cobalt double rim and glossy blue tiles.",
		logo = "classic",
		font = FRIZ, flags = "", size = 12, titleSize = 16, pad = 13,
		frame = flat(3),
		frameBg     = { 0.98, 0.98, 0.97, 1 },
		frameBorder = { 0.12, 0.25, 0.62, 1 },
		title  = { 0.10, 0.22, 0.58 },
		text   = { 0.10, 0.13, 0.22 },
		muted  = { 0.35, 0.40, 0.52 },
		line   = { 0.12, 0.25, 0.62, 0.22 },
		accent = { 0.12, 0.25, 0.62 },
		button = {
			backdrop = flat(1), bg = { 0.16, 0.30, 0.66, 1 }, border = { 0.08, 0.17, 0.45, 1 },
			hover = { 0.24, 0.40, 0.78, 1 },
			text = { 1.00, 1.00, 1.00 },
			bevel = true,
		},
		input = {
			backdrop = flat(1), bg = { 1, 1, 1, 1 }, border = { 0.12, 0.25, 0.62, 0.60 },
			hover = { 0.94, 0.96, 1.00, 1 },
			text = { 0.10, 0.13, 0.22 },
		},
		deco = {
			inner   = { inset = 6, th = 1, a = 1, color = "accent" },            -- second, thin rim
			corners = { kind = "square", inset = 9, size = 3, th = 1, color = "accent" }, -- painted dots
			sheen   = { top = 0, bot = 0.06, color = "accent" },                -- glaze pooling at the foot
		},
	},

	---------------------------------------------------------------- 7
	{
		name = "Toybox",
		desc = "A chunky plastic toy: primary colours, fat black outlines and a cartoon shadow.",
		logo = "classic",
		font = FRIZ, flags = "THICKOUTLINE", size = 13, titleSize = 18, pad = 14,
		frame = flat(4),
		frameBg     = { 0.10, 0.32, 0.78, 1 },
		frameBorder = { 0, 0, 0, 1 },
		title  = { 1.00, 0.86, 0.12 },
		text   = { 1.00, 1.00, 1.00 },
		muted  = { 0.85, 0.92, 1.00 },
		line   = { 0, 0, 0, 0.40 },
		accent = { 1.00, 0.84, 0.08 },
		button = {
			backdrop = flat(2), bg = { 0.84, 0.12, 0.10, 1 }, border = { 0, 0, 0, 1 },
			hover = { 0.62, 0.07, 0.05, 1 },            -- pressed-in darker red
			text = { 1.00, 1.00, 1.00 },
			bevel = true,
		},
		input = {
			backdrop = flat(2), bg = { 0.03, 0.12, 0.36, 1 }, border = { 0, 0, 0, 1 },
			hover = { 0.05, 0.17, 0.46, 1 },
			text = { 1.00, 1.00, 1.00 },
		},
		deco = {
			bar    = { h = 5, inset = 4, color = "accent" },               -- yellow top stripe
			shadow = { x = 5, y = -5, a = 1, color = "black" },            -- NEW: hard offset shadow
		},
	},

	---------------------------------------------------------------- 8
	{
		name = "Warpaint",
		desc = "A war-camp hide banner: rough-cut letters, a blood-red slash and iron clamps on the corners.",
		logo = "classic",
		font = SKURRI, flags = "OUTLINE", size = 13, titleSize = 18, pad = 14,
		frame = {
			bgFile = TIP_BG, edgeFile = TIP_EDGE, tile = true, tileSize = 16, edgeSize = 16,
			insets = { left = 4, right = 4, top = 4, bottom = 4 },
		},
		frameBg     = { 0.19, 0.11, 0.07, 0.97 },
		frameBorder = { 0.82, 0.72, 0.56, 1 },
		title  = { 1.00, 0.40, 0.25 },
		text   = { 0.93, 0.87, 0.75 },
		muted  = { 0.74, 0.66, 0.54 },
		line   = { 0.55, 0.15, 0.10, 0.60 },
		accent = { 0.70, 0.10, 0.08 },
		button = {
			backdrop = flat(2), bg = { 0.50, 0.08, 0.06, 1 }, border = { 0.08, 0.03, 0.02, 1 },
			hover = { 0.66, 0.12, 0.08, 1 },
			text = { 0.95, 0.90, 0.80 },
		},
		input = {
			backdrop = flat(1), bg = { 0.08, 0.05, 0.03, 1 }, border = { 0.55, 0.45, 0.35, 1 },
			hover = { 0.12, 0.07, 0.05, 1 },
			text = { 0.93, 0.87, 0.75 },
			underline = { 0.70, 0.10, 0.08, 1 },
		},
		deco = {
			corners = { kind = "bracket", inset = 2, len = 20, th = 4, color = "black" }, -- iron clamps
			bar     = { h = 3, inset = 5, color = "accent" },                          -- blood slash
			sheen   = { top = 0, bot = 0.35, color = "black" },                       -- smoke-dark foot
		},
	},

	---------------------------------------------------------------- 9
	{
		name = "Moonweave",
		desc = "Night-elf silk under the moon: sheer indigo, silver filigree and a faint blue halo.",
		logo = "classic",
		font = FRIZ, flags = "", size = 12, titleSize = 16, pad = 14,
		frame = {
			bgFile = TIP_BG, edgeFile = TIP_EDGE, tile = true, tileSize = 16, edgeSize = 12,
			insets = { left = 3, right = 3, top = 3, bottom = 3 },
		},
		frameBg     = { 0.07, 0.07, 0.18, 0.88 },
		frameBorder = { 0.78, 0.82, 0.95, 1 },
		title  = { 0.85, 0.88, 1.00 },
		text   = { 0.88, 0.89, 0.95 },
		muted  = { 0.72, 0.74, 0.88 },
		line   = { 0.78, 0.82, 0.95, 0.14 },
		accent = { 0.60, 0.70, 1.00 },
		button = {
			backdrop = flat(1), bg = { 1, 1, 1, 0.03 }, border = clear(),
			hover = { 0.60, 0.70, 1.00, 0.16 },
			text = { 0.85, 0.88, 1.00 },
			underline = { 0.60, 0.70, 1.00, 0.70 },
		},
		input = {
			backdrop = flat(1), bg = { 0, 0, 0, 0.25 }, border = clear(),
			hover = { 0, 0, 0, 0.35 },
			text = { 0.88, 0.89, 0.95 },
			underline = { 0.78, 0.82, 0.95, 0.60 },
		},
		deco = {
			inner = { inset = 7, th = 1, a = 0.18, color = "white" },        -- fine filigree thread
			sheen = { top = 0.16, bot = 0, color = "accent" },              -- moonlight from above
			glow  = {
				{ inset = -1, a = 0.30, color = "accent" },
				{ inset = -2, a = 0.12, color = "accent" },
			},
		},
	},

	---------------------------------------------------------------- 10
	{
		name = "Broadsheet",
		desc = "A morning newspaper: grey newsprint under a black masthead rule, with reversed-out buttons.",
		logo = "classic",
		font = FRIZ, flags = "", size = 12, titleSize = 18, pad = 12,
		frame = flat(1),
		frameBg     = { 0.91, 0.90, 0.87, 1 },
		frameBorder = { 0.10, 0.10, 0.10, 1 },
		title  = { 0.00, 0.00, 0.00 },
		text   = { 0.08, 0.08, 0.08 },
		muted  = { 0.34, 0.34, 0.32 },
		line   = { 0.10, 0.10, 0.10, 0.45 },
		accent = { 0.06, 0.06, 0.06 },
		button = {
			backdrop = flat(1), bg = { 0.10, 0.10, 0.10, 1 }, border = { 0, 0, 0, 1 },
			hover = { 0.30, 0.30, 0.29, 1 },
			text = { 0.97, 0.96, 0.93 },
		},
		input = {
			backdrop = flat(1), bg = { 0.98, 0.97, 0.95, 1 }, border = { 0.10, 0.10, 0.10, 1 },
			hover = { 1, 1, 1, 1 },
			text = { 0.05, 0.05, 0.05 },
		},
		deco = {
			bar    = { h = 6, inset = 1, color = "accent" },               -- masthead rule
			shadow = { x = 3, y = -3, a = 0.30, color = "black" },         -- NEW: paper lying on a desk
		},
	},
}

Skins.extra = Extra

for _, sk in ipairs(NEW) do
  local id = "n_" .. sk.name:lower():gsub("[^%w]", "")
  Skins.list[id] = sk
  table.insert(Skins.order, id)
end
Skins.number = {}
for i, id in ipairs(Skins.order) do Skins.number[id] = i end
