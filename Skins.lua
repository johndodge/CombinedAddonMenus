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
    desc = "Light paper and dark ink, in the game's own sharp font.",
    font = FRIZ, size = 13, titleSize = 17, pad = 10,
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

---------------------------------------------------------------------------
-- Colour themes #7 to #56 (added 0.3.34). Each one is a few colours; theme() works out the rest.
-- The number is the position in Skins.order and is shown in the settings page drop-down, so a theme can be
-- removed by number. They reuse the Classic logo (media\Logo_classic).
---------------------------------------------------------------------------
local function hex(str)
  local r, g, b = str:match("#(%x%x)(%x%x)(%x%x)")
  return { tonumber(r, 16) / 255, tonumber(g, 16) / 255, tonumber(b, 16) / 255 }
end
local function mix(a, b, t)
  return { a[1] + (b[1] - a[1]) * t, a[2] + (b[2] - a[2]) * t, a[3] + (b[3] - a[3]) * t }
end
local function withAlpha(c, a) return { c[1], c[2], c[3], a } end
local BLACK, WHITE_C = { 0, 0, 0 }, { 1, 1, 1 }

-- o: alpha (frame opacity), style ("flat1" default, "flat2", "tip"), font ("arial"), title (hex)
local function theme(name, desc, bgHex, accHex, textHex, o)
  o = o or {}
  local bg, acc, tx = hex(bgHex), hex(accHex), hex(textHex)
  local light = (0.299 * bg[1] + 0.587 * bg[2] + 0.114 * bg[3]) > 0.55
  local alpha = o.alpha or 0.97
  local glass = alpha < 0.9
  local function edge() return o.style == "tip" and tipEdge() or flat(o.style == "flat2" and 2 or 1) end
  local arial = o.font == "arial"
  local title = o.title and hex(o.title) or mix(acc, light and BLACK or WHITE_C, 0.25)
  local btnBg = mix(bg, acc, light and 0.25 or 0.28)
  local hover = mix(bg, acc, light and 0.5 or 0.55)
  local inBg = light and mix(bg, WHITE_C, 0.6) or mix(bg, BLACK, 0.45)
  local id = "t" .. (#Skins.order + 1)
  Skins.list[id] = {
    name = name, desc = desc, logo = "classic",
    font = arial and ARIALN or FRIZ, size = arial and 13 or 12, titleSize = arial and 16 or 15, pad = 10,
    frame = edge(),
    frameBg = withAlpha(bg, alpha), frameBorder = withAlpha(acc, 1),
    title = title, text = tx, muted = mix(tx, bg, 0.45), line = withAlpha(acc, 0.25),
    button = { backdrop = edge(), bg = withAlpha(btnBg, glass and 0.5 or 1), border = withAlpha(acc, 1),
               hover = withAlpha(hover, glass and 0.7 or 1), text = tx },
    input = { backdrop = edge(), bg = withAlpha(inBg, glass and 0.6 or 1), border = withAlpha(acc, 1), text = tx },
  }
  table.insert(Skins.order, id)
end

theme("Ocean Depths", "Deep sea blue with a bright teal edge.", "#06202e", "#2aa6c9", "#d7f2fb")
theme("Forest Canopy", "Dark leaf green with fresh green trim.", "#0f2416", "#5fae5a", "#e3f2dc")
theme("Desert Dusk", "Baked brown with a warm orange glow.", "#2b1b12", "#e0914a", "#f7e3cf")
theme("Blood Moon", "Near-black red with a crimson edge.", "#1d0606", "#c0282d", "#f3d7d7")
theme("Royal Purple", "Deep violet with lilac trim.", "#1c0f2e", "#9b6bd6", "#eadcf8")
theme("Arctic Frost", "Light icy white with steel blue trim.", "#e8f2f8", "#5b9bc4", "#1c3446")
theme("Sunset", "Dusky plum with a coral edge.", "#2b1230", "#ff7a59", "#ffe6d6")
theme("Moss and Stone", "Grey-green stone with sage trim.", "#20241d", "#8a9a6b", "#e4e8d8")
theme("Cherry Blossom", "Pale pink paper with rose trim.", "#fbe8ee", "#d9608a", "#4a1f2f")
theme("Midnight Gold", "Black with a gold edge.", "#0b0b14", "#d4af37", "#f4ecd0")
theme("Copper Steam", "Dark brown with copper trim.", "#241710", "#c87533", "#f2dcc4")
theme("Neon Cyber", "Black with electric cyan lines.", "#0a0a12", "#00f0ff", "#e0fbff", { font = "arial" })
theme("Synthwave", "Dark purple with hot pink lines.", "#1a0a2e", "#ff2bd6", "#ffe0fa", { font = "arial" })
theme("Mint Chocolate", "Dark chocolate with mint trim.", "#1f1712", "#5fd6a8", "#e6fff4")
theme("Slate Minimal", "Quiet grey with a thin steel edge.", "#22262b", "#7d8b99", "#e6eaee", { font = "arial" })
theme("Ember", "Charcoal brown with a glowing orange edge.", "#1a0c05", "#ff5a1f", "#ffe0cc")
theme("Lavender Fields", "Light lilac with violet trim.", "#efe9f8", "#8a6fc4", "#2b2142")
theme("Golden Hour", "Warm cream with amber trim.", "#f6e7bf", "#c9891a", "#3b2a08")
theme("Toxic Waste", "Black-green with acid green trim.", "#0c1406", "#9dff1a", "#eaffc2", { font = "arial" })
theme("Steel Blue", "Dark navy grey with steel blue trim.", "#15202c", "#4b7fb5", "#dce8f5")
theme("Rose Gold", "Dark rosewood with a rose gold edge.", "#2a1a1c", "#e0a8a0", "#fbe9e5")
theme("Obsidian", "Almost black with a graphite edge.", "#08080a", "#5c5c66", "#d9d9de", { font = "arial" })
theme("Emerald City", "Deep green with a bright emerald edge.", "#06241c", "#1fcf8e", "#d6fff0")
theme("Candy", "Pale pink with a bubblegum edge.", "#fff0f6", "#ff5fa2", "#4a1a33")
theme("Storm Cloud", "Grey-blue with a pale blue edge.", "#2a2f38", "#8fb0d6", "#eef3fa")
theme("Autumn Leaves", "Dark brown with a pumpkin edge.", "#2a1608", "#d9741a", "#fbe3c4")
theme("Pine and Snow", "Snow white with pine green trim.", "#f3f7f4", "#2f6b4a", "#14291d")
theme("Violet Ember", "Dark violet with an ember orange edge.", "#170a24", "#ff6a3d", "#f6e2ff")
theme("Ice Cave", "Clear icy glass with a bright cyan edge.", "#0a1c26", "#8be9ff", "#e8fbff", { alpha = 0.75, style = "tip" })
theme("Honey", "Dark amber with a honey gold edge.", "#2a1f08", "#f2b526", "#fff0c2")
theme("Plum Wine", "Dark wine with a magenta edge.", "#240b1a", "#b03a78", "#f7dcea")
theme("Dusty Rose", "Muted mauve with a pink edge.", "#3a2a2e", "#c98a97", "#f6e8ea")
theme("Sandstone", "Light sand with a bronze edge.", "#e9dcc2", "#a86a2e", "#3a2612")
theme("Deep Space", "Near-black blue with a periwinkle edge.", "#03030a", "#6a7bff", "#dfe3ff")
theme("Aurora", "Dark teal with green lines and violet titles.", "#07181a", "#4cf0a0", "#e0fff0", { title = "#b58cff" })
theme("Coffee House", "Espresso brown with a latte edge.", "#1e140d", "#a47148", "#f0e0d0")
theme("Lemon Lime", "Pale lemon with a lime green edge.", "#f7fbe0", "#7cb518", "#26340a")
theme("Crimson Knight", "Black with a bold red edge.", "#14090c", "#d41f3c", "#f5dde1", { style = "flat2" })
theme("Teal and Orange", "Teal background with an orange edge.", "#0b2a30", "#ff8a3d", "#e0f5f5")
theme("Graphite Mint", "Graphite grey with a mint edge.", "#1b1f1e", "#3ddc97", "#e5f0eb", { font = "arial" })
theme("Parchment Night", "Dark old paper with a pale gold edge.", "#2a2418", "#cbb27a", "#f1e6c8")
theme("Sky", "Light sky blue with a clear blue edge.", "#dff0fb", "#2d86c8", "#0f2f47")
theme("Monochrome", "Black and white, nothing else.", "#111111", "#ffffff", "#eeeeee", { font = "arial" })
theme("Bubblegum Dark", "Dark purple with a pink edge.", "#1a1020", "#ff77c8", "#ffe3f5")
theme("Jade Temple", "Dark jade with a pale gold edge.", "#0e2a24", "#d8c37a", "#f1eddc")
theme("Volcano", "Black with a molten red edge.", "#140606", "#ff3b1f", "#ffd9c9", { style = "flat2" })
theme("Twilight Blue", "Evening blue with a soft blue edge.", "#121a3a", "#7fa0ff", "#e6ecff")
theme("Terminal Amber", "Black screen with amber text, like an old terminal.", "#0a0600", "#ffb000", "#ffcf66", { font = "arial", title = "#ffb000" })
theme("Orchid", "Pale orchid with a purple edge.", "#f6ecf8", "#b24bd1", "#38154a")
theme("Sage", "Pale sage green with a green edge.", "#dfe6d3", "#5f7a4a", "#25301c")

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
  local ok = pcall(fs.SetFont, fs, skin.font, size or skin.size, "")
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
