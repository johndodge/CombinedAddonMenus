-- Combined Addon Menus - skins for the list window and the menu button.
-- A skin is only data: backdrops, colors and a font. Skins.apply* functions paint frames with it.

local ADDON, ns = ...
local Skins = {}
ns.Skins = Skins

local WHITE = "Interface\\Buttons\\WHITE8X8"
local TOOLTIP_EDGE = "Interface\\Tooltips\\UI-Tooltip-Border"
local DIALOG_BG = "Interface\\DialogFrame\\UI-DialogBox-Background"
local DIALOG_EDGE = "Interface\\DialogFrame\\UI-DialogBox-Border"
local FRIZ = "Fonts\\FRIZQT__.TTF"
local ARIALN = "Fonts\\ARIALN.TTF"

local function flat(edge)
  return { bgFile = WHITE, edgeFile = WHITE, edgeSize = edge, insets = { left = edge, right = edge, top = edge, bottom = edge } }
end
local function tipEdge()
  return { bgFile = WHITE, edgeFile = TOOLTIP_EDGE, edgeSize = 12, insets = { left = 3, right = 3, top = 3, bottom = 3 } }
end

-- Order shown on the settings page.
Skins.order = { "classic", "gnomish", "frost" }

Skins.list = {
  classic = {
    name = "Classic",
    desc = "Blizzard dialog border, dark background, gold text.",
    font = FRIZ, size = 12, titleSize = 15, pad = 16,
    frame = { bgFile = DIALOG_BG, edgeFile = DIALOG_EDGE, tile = true, tileSize = 32, edgeSize = 32,
              insets = { left = 11, right = 12, top = 12, bottom = 11 } },
    frameBg = { 1, 1, 1, 1 }, frameBorder = { 1, 1, 1, 1 },
    title = { 1, 0.82, 0 }, text = { 1, 0.82, 0 }, muted = { 0.65, 0.65, 0.65 }, line = { 1, 1, 1, 0.08 },
    button = { backdrop = tipEdge(), bg = { 0.3, 0.05, 0.03, 0.95 }, border = { 0.8, 0.65, 0.3, 1 },
               hover = { 0.55, 0.1, 0.05, 1 }, text = { 1, 0.86, 0.35 } },
    input = { backdrop = tipEdge(), bg = { 0, 0, 0, 0.7 }, border = { 0.6, 0.6, 0.6, 1 }, text = { 1, 1, 1 } },
  },
  gnomish = {
    name = "Gnomish Workshop",
    desc = "Dark slate, brass edges, teal buttons.",
    font = FRIZ, size = 12, titleSize = 15, pad = 10,
    frame = flat(2),
    frameBg = { 0.1, 0.12, 0.14, 0.97 }, frameBorder = { 0.78, 0.56, 0.25, 1 },
    title = { 0.9, 0.68, 0.32 }, text = { 0.86, 0.92, 0.94 }, muted = { 0.55, 0.62, 0.66 }, line = { 0.78, 0.56, 0.25, 0.25 },
    button = { backdrop = flat(1), bg = { 0.04, 0.33, 0.36, 1 }, border = { 0.78, 0.56, 0.25, 1 },
               hover = { 0.07, 0.5, 0.54, 1 }, text = { 1, 1, 1 } },
    input = { backdrop = flat(1), bg = { 0.05, 0.06, 0.07, 1 }, border = { 0.78, 0.56, 0.25, 1 }, text = { 0.86, 0.92, 0.94 } },
  },
  frost = {
    name = "Frostglass",
    desc = "Smoky icy blue glass with white text.",
    font = FRIZ, size = 12, titleSize = 15, pad = 10,
    frame = tipEdge(),
    frameBg = { 0.3, 0.5, 0.72, 0.58 }, frameBorder = { 0.82, 0.95, 1, 1 },
    title = { 1, 1, 1 }, text = { 0.9, 0.97, 1 }, muted = { 0.7, 0.82, 0.92 }, line = { 1, 1, 1, 0.15 },
    button = { backdrop = tipEdge(), bg = { 0.45, 0.66, 0.9, 0.38 }, border = { 0.85, 0.95, 1, 0.9 },
               hover = { 0.55, 0.78, 1, 0.58 }, text = { 1, 1, 1 } },
    input = { backdrop = tipEdge(), bg = { 0.06, 0.13, 0.25, 0.7 }, border = { 0.85, 0.95, 1, 0.9 }, text = { 1, 1, 1 } },
  },
}

-- Extra drawing on a skinned frame: inner lines, glow, corners, a top bar, a gradient and scan lines.
-- Everything is a texture on the frame, made once and reused. Features a skin does not use are hidden.
local BLACK, WHITE_C = { 0, 0, 0 }, { 1, 1, 1 }

local function dtex(f, key, layer)
  f._deco = f._deco or {}
  local t = f._deco[key]
  if not t then
    t = f:CreateTexture(nil, layer or "BORDER")
    t:SetTexture(WHITE)
    f._deco[key] = t
  end
  return t
end

local function dhide(f, prefix)
  if not f._deco then return end
  for k, t in pairs(f._deco) do
    if k:sub(1, #prefix) == prefix then t:Hide() end
  end
end

local function dcolor(skin, name, a)
  local c = skin.frameBorder
  if name == "white" then c = WHITE_C elseif name == "black" then c = BLACK elseif name == "accent" then c = skin.accent or c end
  return c[1], c[2], c[3], a
end

local function dbox(f, key, skin, inset, th, colorName, a)
  for _, side in ipairs({ "t", "b", "l", "r" }) do
    local t = dtex(f, key .. side)
    t:ClearAllPoints()
    if side == "t" then
      t:SetPoint("TOPLEFT", f, "TOPLEFT", inset, -inset) t:SetPoint("TOPRIGHT", f, "TOPRIGHT", -inset, -inset) t:SetHeight(th)
    elseif side == "b" then
      t:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", inset, inset) t:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -inset, inset) t:SetHeight(th)
    elseif side == "l" then
      t:SetPoint("TOPLEFT", f, "TOPLEFT", inset, -inset) t:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", inset, inset) t:SetWidth(th)
    else
      t:SetPoint("TOPRIGHT", f, "TOPRIGHT", -inset, -inset) t:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -inset, inset) t:SetWidth(th)
    end
    t:SetColorTexture(dcolor(skin, colorName, a))
    t:Show()
  end
end

local CORNERS = {
  { "TOPLEFT", 1, -1 }, { "TOPRIGHT", -1, -1 }, { "BOTTOMLEFT", 1, 1 }, { "BOTTOMRIGHT", -1, 1 },
}

local function gradient(t, top, bot)
  t:SetColorTexture(1, 1, 1, 1)
  local ok = false
  if t.SetGradient and CreateColor then
    ok = pcall(t.SetGradient, t, "VERTICAL", CreateColor(bot[1], bot[2], bot[3], bot[4]), CreateColor(top[1], top[2], top[3], top[4]))
  end
  if not ok and t.SetGradientAlpha then
    ok = pcall(t.SetGradientAlpha, t, "VERTICAL", bot[1], bot[2], bot[3], bot[4], top[1], top[2], top[3], top[4])
  end
  if not ok then t:SetColorTexture(top[1], top[2], top[3], (top[4] + bot[4]) / 2) end
end

local function scanLines(f, skin, cfg)
  local d = f._deco
  d.scan = d.scan or {}
  local h = (f.GetHeight and f:GetHeight()) or 0
  local n = cfg and math.min(math.floor(h / cfg.gap), 200) or 0
  for i = 1, math.max(n, #d.scan) do
    local t = d.scan[i]
    if i <= n then
      if not t then t = f:CreateTexture(nil, "BORDER") t:SetTexture(WHITE) d.scan[i] = t end
      t:ClearAllPoints()
      t:SetPoint("TOPLEFT", f, "TOPLEFT", 3, -3 - i * cfg.gap)
      t:SetPoint("TOPRIGHT", f, "TOPRIGHT", -3, -3 - i * cfg.gap)
      t:SetHeight(1)
      t:SetColorTexture(0, 0, 0, cfg.a)
      t:Show()
    elseif t then
      t:Hide()
    end
  end
end

function Skins.decorate(f, skin, small)
  if not f.CreateTexture then return end
  local cfg = skin.deco or {}
  f._decoSkin, f._decoSmall = skin, small
  -- inner line
  if cfg.inner then
    dbox(f, "inner", skin, cfg.inner.inset, cfg.inner.th, cfg.inner.color, cfg.inner.a)
  else dhide(f, "inner") end
  -- glow: lines outside the frame
  dhide(f, "glow")
  if cfg.glow then
    for i, g in ipairs(cfg.glow) do dbox(f, "glow" .. i, skin, g.inset, 1, g.color or "accent", g.a) end
  end
  -- gradient
  if cfg.sheen then
    local t = dtex(f, "sheen")
    t:ClearAllPoints()
    t:SetPoint("TOPLEFT", f, "TOPLEFT", 2, -2)
    t:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -2, 2)
    local r, g, b = dcolor(skin, cfg.sheen.color, 1)
    gradient(t, { r, g, b, cfg.sheen.top }, { r, g, b, cfg.sheen.bot })
    t:Show()
  else dhide(f, "sheen") end
  -- corners, top bar and scan lines are left off small frames (the drop-down)
  dhide(f, "corner")
  if cfg.corners and not small then
    local c = cfg.corners
    for i, co in ipairs(CORNERS) do
      local sx, sy = co[2], co[3]
      if c.kind == "square" then
        local t = dtex(f, "corner" .. i .. "s", "ARTWORK")
        t:ClearAllPoints() t:SetPoint(co[1], f, co[1], sx * c.inset, sy * c.inset) t:SetSize(c.size, c.size)
        t:SetColorTexture(dcolor(skin, c.color, 1)) t:Show()
      else
        local h = dtex(f, "corner" .. i .. "h", "ARTWORK")
        h:ClearAllPoints() h:SetPoint(co[1], f, co[1], sx * c.inset, sy * c.inset) h:SetSize(c.len, c.th)
        h:SetColorTexture(dcolor(skin, c.color, 1)) h:Show()
        local v = dtex(f, "corner" .. i .. "v", "ARTWORK")
        v:ClearAllPoints() v:SetPoint(co[1], f, co[1], sx * c.inset, sy * c.inset) v:SetSize(c.th, c.len)
        v:SetColorTexture(dcolor(skin, c.color, 1)) v:Show()
      end
    end
  end
  if cfg.bar and not small then
    local t = dtex(f, "bar", "ARTWORK")
    t:ClearAllPoints()
    t:SetPoint("TOPLEFT", f, "TOPLEFT", cfg.bar.inset, -cfg.bar.inset)
    t:SetPoint("TOPRIGHT", f, "TOPRIGHT", -cfg.bar.inset, -cfg.bar.inset)
    t:SetHeight(cfg.bar.h)
    t:SetColorTexture(dcolor(skin, cfg.bar.color, 1))
    t:Show()
  else dhide(f, "bar") end
  if f._deco then
    scanLines(f, skin, (not small) and cfg.scan or nil)
  elseif cfg.scan and not small then
    f._deco = {}
    scanLines(f, skin, cfg.scan)
  end
  if not f._decoHooked and f.HookScript then
    f._decoHooked = true
    f:HookScript("OnSizeChanged", function(self)
      local sk = self._decoSkin
      if sk and sk.deco and sk.deco.scan and not self._decoSmall and self._deco then scanLines(self, sk, sk.deco.scan) end
    end)
  end
end

-- Small raised/underlined look on a button, used by the button styles that ask for it.
local function buttonDeco(b, style)
  local function t(key)
    b._bdeco = b._bdeco or {}
    local x = b._bdeco[key]
    if not x then x = b:CreateTexture(nil, "ARTWORK") x:SetTexture(WHITE) b._bdeco[key] = x end
    return x
  end
  if style.underline then
    local u = t("ul")
    u:ClearAllPoints() u:SetPoint("BOTTOMLEFT", 2, 2) u:SetPoint("BOTTOMRIGHT", -2, 2) u:SetHeight(2)
    u:SetColorTexture(style.underline[1], style.underline[2], style.underline[3], style.underline[4] or 1) u:Show()
  elseif b._bdeco and b._bdeco.ul then b._bdeco.ul:Hide() end
  if style.bevel then
    local hi, lo = t("hi"), t("lo")
    hi:ClearAllPoints() hi:SetPoint("TOPLEFT", 2, -2) hi:SetPoint("TOPRIGHT", -2, -2) hi:SetHeight(1)
    hi:SetColorTexture(1, 1, 1, 0.22) hi:Show()
    lo:ClearAllPoints() lo:SetPoint("BOTTOMLEFT", 2, 2) lo:SetPoint("BOTTOMRIGHT", -2, 2) lo:SetHeight(1)
    lo:SetColorTexture(0, 0, 0, 0.4) lo:Show()
  elseif b._bdeco then
    if b._bdeco.hi then b._bdeco.hi:Hide() end
    if b._bdeco.lo then b._bdeco.lo:Hide() end
  end
end

---------------------------------------------------------------------------
-- Colour themes #7 to #56. Each is three colours plus a "feel" (FEELS below) that sets the frame style:
-- extra lines, corners, bars, gradients, scan lines, glow and button shape. The number is the position in
-- Skins.order, shown in the settings page drop-down, so a theme can be removed by number (delete its theme() line;
-- the numbers after it shift down). They reuse the Classic logo (media\Logo_classic).
---------------------------------------------------------------------------
local function hex(str)
  local r, g, b = str:match("#(%x%x)(%x%x)(%x%x)")
  return { tonumber(r, 16) / 255, tonumber(g, 16) / 255, tonumber(b, 16) / 255 }
end
local function mix(a, b, t)
  return { a[1] + (b[1] - a[1]) * t, a[2] + (b[2] - a[2]) * t, a[3] + (b[3] - a[3]) * t }
end
local function withAlpha(c, a) return { c[1], c[2], c[3], a } end

-- A feel is a bundle of looks. deco = what Skins.decorate draws on the frame. btn = button shape.
local FEELS = {
  etched = { label = "Double line, square corners, raised buttons.", style = "flat2", btn = "bevel",
    deco = { inner = { inset = 4, th = 1, a = 0.65 }, corners = { kind = "square", inset = 1, size = 6 } } },
  terminal = { label = "Pixel font, scan lines, bracket corners, outlined buttons.", style = "flat1", font = "arial", flags = "MONOCHROME", btn = "outline",
    deco = { scan = { gap = 3, a = 0.10 }, corners = { kind = "bracket", inset = 3, len = 9, th = 2 } } },
  glass = { label = "See-through, shiny top, thin light inner line.", style = "tip", alpha = 0.74, btn = "fill",
    deco = { sheen = { top = 0.26, bot = 0.02, color = "white" }, inner = { inset = 4, th = 1, a = 0.28, color = "white" } } },
  paper = { label = "Paper with a soft inner border and raised buttons.", style = "flat1", btn = "bevel",
    deco = { inner = { inset = 4, th = 1, a = 0.45 }, sheen = { top = 0, bot = 0.14, color = "black" } } },
  stationery = { label = "Letterhead bar on top, underlined buttons.", style = "flat1", btn = "underline",
    deco = { bar = { h = 5, inset = 1 }, sheen = { top = 0, bot = 0.10, color = "black" } } },
  forge = { label = "Heavy plate, thick top bar, rivets, raised buttons.", style = "flat2", btn = "bevel",
    deco = { bar = { h = 5, inset = 2 }, inner = { inset = 6, th = 1, a = 0.35 }, corners = { kind = "square", inset = 2, size = 5 } } },
  neon = { label = "Glowing outline and outlined text.", style = "flat1", font = "arial", flags = "OUTLINE", btn = "outline",
    deco = { glow = { { inset = -1, a = 0.55 }, { inset = -3, a = 0.22 } }, sheen = { top = 0, bot = 0.2, color = "accent" } } },
  rustic = { label = "Old border, inner frame, soft light from the top.", style = "tip", btn = "bevel",
    deco = { inner = { inset = 6, th = 1, a = 0.3 }, corners = { kind = "bracket", inset = 6, len = 7, th = 1 }, sheen = { top = 0.10, bot = 0, color = "white" } } },
  minimal = { label = "Faint border, one thin bar, underlined buttons.", style = "flat1", borderA = 0.4, btn = "underline",
    deco = { bar = { h = 2, inset = 0 } } },
  dusk = { label = "Colour glow rising from the bottom edge.", style = "flat1", btn = "fill",
    deco = { sheen = { top = 0, bot = 0.34, color = "accent" }, inner = { inset = 3, th = 1, a = 0.2 } } },
}

local function buttonStyle(kind, bg, acc, tx, light, glass, edge)
  local btnBg = mix(bg, acc, light and 0.25 or 0.28)
  local hover = mix(bg, acc, light and 0.5 or 0.55)
  if kind == "outline" then
    return { backdrop = edge(), bg = withAlpha(bg, 0), border = withAlpha(acc, 1), hover = withAlpha(acc, 0.35), text = tx }
  elseif kind == "underline" then
    return { backdrop = { bgFile = WHITE }, bg = withAlpha(acc, 0), hover = withAlpha(acc, 0.22), text = tx, underline = withAlpha(acc, 1) }
  elseif kind == "bevel" then
    return { backdrop = edge(), bg = btnBg, border = withAlpha(mix(acc, bg, 0.3), 1), hover = hover, text = tx, bevel = true }
  end
  return { backdrop = edge(), bg = withAlpha(btnBg, glass and 0.5 or 1), border = withAlpha(acc, 1),
           hover = withAlpha(hover, glass and 0.7 or 1), text = tx }
end

local function theme(name, desc, bgHex, accHex, textHex, feel, o)
  local f = {}
  for k, v in pairs(FEELS[feel]) do f[k] = v end
  for k, v in pairs(o or {}) do f[k] = v end
  local bg, acc, tx = hex(bgHex), hex(accHex), hex(textHex)
  local light = (0.299 * bg[1] + 0.587 * bg[2] + 0.114 * bg[3]) > 0.55
  local alpha = f.alpha or 0.97
  local glass = alpha < 0.9
  local function edge() return f.style == "tip" and tipEdge() or flat(f.style == "flat2" and 2 or 1) end
  local arial = f.font == "arial"
  local title = f.title and hex(f.title) or mix(acc, light and BLACK or WHITE_C, 0.25)
  local inBg = light and mix(bg, WHITE_C, 0.6) or mix(bg, BLACK, 0.45)
  local btn = buttonStyle(f.btn, bg, acc, tx, light, glass, edge)
  local input = { backdrop = edge(), bg = withAlpha(inBg, glass and 0.6 or 1), border = withAlpha(acc, 1), text = tx }
  local id = "t_" .. name:lower():gsub("[^%w]", "")
  Skins.list[id] = {
    name = name, desc = desc .. " " .. f.label, logo = "classic", feel = feel,
    font = arial and ARIALN or FRIZ, flags = f.flags, size = arial and 13 or 12, titleSize = arial and 16 or 15, pad = 10,
    frame = edge(),
    frameBg = withAlpha(bg, alpha), frameBorder = withAlpha(acc, f.borderA or 1),
    title = title, text = tx, muted = mix(tx, bg, 0.45), line = withAlpha(acc, 0.25),
    button = btn, input = input, deco = f.deco, accent = acc,
  }
  table.insert(Skins.order, id)
end

theme("Ocean Depths", "Clear sea water over a deep blue.", "#06202e", "#2aa6c9", "#d7f2fb", "glass")
theme("Forest Canopy", "Dark leaves and soft green light.", "#0f2416", "#5fae5a", "#e3f2dc", "rustic")
theme("Arctic Frost", "Pale frosted glass with steel blue lines.", "#e8f2f8", "#5b9bc4", "#1c3446", "glass")
theme("Sunset", "Dusky plum warming to coral at the bottom.", "#2b1230", "#ff7a59", "#ffe6d6", "dusk")
theme("Moss and Stone", "Grey stone with moss-green trim.", "#20241d", "#8a9a6b", "#e4e8d8", "rustic")
theme("Teal and Orange", "Teal panel with one orange bar.", "#0b2a30", "#ff8a3d", "#e0f5f5", "minimal")

-- Number of each theme (its place in the list). Skins.label(id) = "[7] Ocean Depths".
Skins.number = {}
for i, id in ipairs(Skins.order) do Skins.number[id] = i end
function Skins.label(id)
  local sk = Skins.list[id]
  return "[" .. (Skins.number[id] or "?") .. "] " .. (sk and sk.name or id)
end

function Skins.current()
  local id = ns.db and ns.db.skin
  return Skins.list[id] or Skins.list.classic, (Skins.list[id] and id or "classic")
end

local function color(fn, obj, c)
  if c then fn(obj, c[1], c[2], c[3], c[4] or 1) end
end

-- Sets a font, and falls back to the game's default font if the skin's font can't load.
function Skins.setFont(fs, skin, size)
  if type(fs) ~= "table" or not fs.SetFont then return end
  local ok = pcall(fs.SetFont, fs, skin.font, size or skin.size, skin.flags or "")
  local f = fs.GetFont and fs:GetFont()
  if not ok or not f then pcall(fs.SetFont, fs, FRIZ, size or skin.size, "") end
  -- The game's default text has a black shadow. It looked like blur (on Parchment most), so it is off in every skin.
  if fs.SetShadowOffset and fs.SetShadowColor then
    fs:SetShadowOffset(0, 0)
    fs:SetShadowColor(0, 0, 0, 0)
  end
end

function Skins.setTextColor(fs, c)
  if fs and c then fs:SetTextColor(c[1], c[2], c[3], c[4] or 1) end
end

-- Paints a frame made with BackdropTemplate.
function Skins.paintFrame(f, skin, small)
  if not f.SetBackdrop then return end
  f:SetBackdrop(skin.frame)
  color(f.SetBackdropColor, f, skin.frameBg)
  color(f.SetBackdropBorderColor, f, skin.frameBorder)
  Skins.decorate(f, skin, small)
end

-- Paints a button (BackdropTemplate + a font string in b.label).
-- style is skin.button or skin.input. Hover colors work after Skins.hookHover(b).
function Skins.paintButton(b, skin, style, size)
  style = style or skin.button
  b._style = style
  if b.SetBackdrop then
    b:SetBackdrop(style.backdrop)
    color(b.SetBackdropColor, b, b._hover and style.hover or style.bg)
    color(b.SetBackdropBorderColor, b, style.border)
  end
  if type(b.label) == "table" then
    Skins.setFont(b.label, skin, size)
    Skins.setTextColor(b.label, style.text)
  end
  buttonDeco(b, style)
end

function Skins.hookHover(b)
  b:HookScript("OnEnter", function(self)
    self._hover = true
    if self._style and self.SetBackdropColor then color(self.SetBackdropColor, self, self._style.hover) end
  end)
  b:HookScript("OnLeave", function(self)
    self._hover = false
    if self._style and self.SetBackdropColor then color(self.SetBackdropColor, self, self._style.bg) end
  end)
end

-- Called when the skin changes: every part of the addon repaints itself.
function Skins.set(id)
  if not Skins.list[id] or not ns.db then return end
  ns.db.skin = id
  if ns.UI and ns.UI.applySkin then ns.UI.applySkin() end
  if ns.Button and ns.Button.applySkin then ns.Button.applySkin() end
  if ns.Options and ns.Options.applySkin then ns.Options.applySkin() end
end
