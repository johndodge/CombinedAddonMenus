-- Combined Addon Menus - skins for the list window and the M button.
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
local MORPHEUS = "Fonts\\MORPHEUS.TTF"

local function flat(edge)
  return { bgFile = WHITE, edgeFile = WHITE, edgeSize = edge, insets = { left = edge, right = edge, top = edge, bottom = edge } }
end
local function tipEdge()
  return { bgFile = WHITE, edgeFile = TOOLTIP_EDGE, edgeSize = 12, insets = { left = 3, right = 3, top = 3, bottom = 3 } }
end

-- Order shown on the settings page.
Skins.order = { "classic", "gnomish", "midnight", "parchment", "fel", "frost" }

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
  midnight = {
    name = "Midnight",
    desc = "Flat near-black with thin violet lines and white text.",
    font = ARIALN, size = 13, titleSize = 16, pad = 10,
    frame = flat(1),
    frameBg = { 0.035, 0.035, 0.05, 0.97 }, frameBorder = { 0.45, 0.3, 0.85, 1 },
    title = { 0.78, 0.68, 1 }, text = { 0.95, 0.95, 1 }, muted = { 0.5, 0.48, 0.6 }, line = { 0.45, 0.3, 0.85, 0.2 },
    button = { backdrop = flat(1), bg = { 0.1, 0.08, 0.16, 1 }, border = { 0.35, 0.25, 0.6, 1 },
               hover = { 0.24, 0.17, 0.42, 1 }, text = { 1, 1, 1 } },
    input = { backdrop = flat(1), bg = { 0.07, 0.06, 0.1, 1 }, border = { 0.35, 0.25, 0.6, 1 }, text = { 1, 1, 1 } },
  },
  parchment = {
    name = "Parchment",
    desc = "Light paper, dark ink and a quest-book font.",
    font = MORPHEUS, size = 14, titleSize = 18, pad = 10,
    frame = flat(2),
    frameBg = { 0.92, 0.85, 0.69, 1 }, frameBorder = { 0.36, 0.22, 0.1, 1 },
    title = { 0.36, 0.14, 0.04 }, text = { 0.2, 0.12, 0.05 }, muted = { 0.45, 0.35, 0.25 }, line = { 0.36, 0.22, 0.1, 0.25 },
    button = { backdrop = flat(1), bg = { 0.8, 0.69, 0.48, 1 }, border = { 0.45, 0.3, 0.15, 1 },
               hover = { 0.7, 0.57, 0.36, 1 }, text = { 0.2, 0.1, 0.02 } },
    input = { backdrop = flat(1), bg = { 0.97, 0.93, 0.82, 1 }, border = { 0.45, 0.3, 0.15, 1 }, text = { 0.2, 0.12, 0.05 } },
  },
  fel = {
    name = "Fel Terminal",
    desc = "Black screen and neon green text, like an old computer.",
    font = ARIALN, size = 13, titleSize = 16, pad = 10,
    frame = flat(1),
    frameBg = { 0, 0.03, 0, 0.96 }, frameBorder = { 0.2, 1, 0.2, 1 },
    title = { 0.45, 1, 0.45 }, text = { 0.3, 0.95, 0.3 }, muted = { 0.15, 0.55, 0.15 }, line = { 0.2, 1, 0.2, 0.15 },
    button = { backdrop = flat(1), bg = { 0, 0.1, 0, 1 }, border = { 0.2, 0.8, 0.2, 1 },
               hover = { 0, 0.28, 0, 1 }, text = { 0.55, 1, 0.55 } },
    input = { backdrop = flat(1), bg = { 0, 0, 0, 1 }, border = { 0.2, 0.8, 0.2, 1 }, text = { 0.55, 1, 0.55 } },
  },
  frost = {
    name = "Frostglass",
    desc = "See-through icy blue glass with white text.",
    font = FRIZ, size = 12, titleSize = 15, pad = 10,
    frame = tipEdge(),
    frameBg = { 0.45, 0.68, 0.92, 0.3 }, frameBorder = { 0.82, 0.95, 1, 1 },
    title = { 1, 1, 1 }, text = { 0.9, 0.97, 1 }, muted = { 0.7, 0.82, 0.92 }, line = { 1, 1, 1, 0.15 },
    button = { backdrop = tipEdge(), bg = { 0.6, 0.8, 1, 0.25 }, border = { 0.85, 0.95, 1, 0.9 },
               hover = { 0.7, 0.88, 1, 0.5 }, text = { 1, 1, 1 } },
    input = { backdrop = tipEdge(), bg = { 0.1, 0.2, 0.35, 0.5 }, border = { 0.85, 0.95, 1, 0.9 }, text = { 1, 1, 1 } },
  },
}

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
  local ok = pcall(fs.SetFont, fs, skin.font, size or skin.size, "")
  local f = fs.GetFont and fs:GetFont()
  if not ok or not f then pcall(fs.SetFont, fs, FRIZ, size or skin.size, "") end
end

function Skins.setTextColor(fs, c)
  if fs and c then fs:SetTextColor(c[1], c[2], c[3], c[4] or 1) end
end

-- Paints a frame made with BackdropTemplate.
function Skins.paintFrame(f, skin)
  if not f.SetBackdrop then return end
  f:SetBackdrop(skin.frame)
  color(f.SetBackdropColor, f, skin.frameBg)
  color(f.SetBackdropBorderColor, f, skin.frameBorder)
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
