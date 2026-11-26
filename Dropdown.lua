-- Combined Addon Menus - our own drop-down, drawn in our own frames (0.3.28).
-- Why: the game's menu (MenuUtil.CreateContextMenu) has no way to scroll for an addon. SetScrollMode made the game do math on a
-- "secret" scroll bar width under our taint (Menu.lua:1865, user report 2026-11-26). Without it the menu was 45 rows long.
-- This drop-down uses no game menu code. Each level scrolls with the mouse wheel and is painted with the current skin.
--
-- Dropdown.open(anchor, entries): entries = { { text = "Name", func = function() end }, { text = "Name", children = { ...entries } } }
-- An entry with children opens a side menu when the mouse is on it. An entry with func runs it on click and closes everything.

local ADDON, ns = ...
local Dropdown = {}
ns.Dropdown = Dropdown

local ROW, MAXH, PAD, MINW, MAXW = 22, 400, 4, 130, 340
local SMOOTH = 16   -- glide speed: higher is snappier
local WHITE = "Interface\\Buttons\\WHITE8X8"
local ESC_NAME = "CombinedAddonMenusDrop1"

local levels = {}      -- levels[i] = frame for depth i
local catcher          -- full-screen click catcher behind the menu: a click outside closes everything
local measure          -- hidden font string used to measure label widths

local function closeFrom(i)
  for k = #levels, i, -1 do levels[k]:Hide() end
end

function Dropdown.close()
  closeFrom(1)
  if catcher then catcher:Hide() end
end

function Dropdown.isOpen()
  return levels[1] and levels[1]:IsShown() or false
end

local function makeCatcher()
  catcher = CreateFrame("Button", nil, UIParent)
  catcher:SetAllPoints(UIParent)
  catcher:SetFrameStrata("FULLSCREEN")
  catcher:RegisterForClicks("AnyDown", "AnyUp")
  catcher:SetScript("OnClick", function() Dropdown.close() end)
  catcher:Hide()
end

local function updateThumb(f)
  local range = f.scroll:GetVerticalScrollRange() or 0
  if range <= 0 then f.thumb:Hide() return end
  local h = f.scroll:GetHeight()
  local total = h + range
  local th = math.max(16, h * h / total)
  local y = (f.scroll:GetVerticalScroll() / range) * (h - th)
  f.thumb:ClearAllPoints()
  f.thumb:SetPoint("TOPRIGHT", f.scroll, "TOPRIGHT", 0, -y)
  f.thumb:SetSize(3, th)
  f.thumb:Show()
end

local function level(i)
  local f = levels[i]
  if f then return f end
  f = ns.UI.try("Frame", "CombinedAddonMenusDrop" .. i, UIParent, "BackdropTemplate")
  f:SetFrameStrata("FULLSCREEN_DIALOG")
  f:SetClampedToScreen(true)
  f:EnableMouse(true)
  f:Hide()
  f.depth = i
  f.scroll = CreateFrame("ScrollFrame", nil, f)
  f.scroll:SetPoint("TOPLEFT", PAD, -PAD)
  f.scroll:SetPoint("BOTTOMRIGHT", -PAD, PAD)
  f.body = CreateFrame("Frame", nil, f.scroll)
  f.body:SetSize(10, 10)
  f.scroll:SetScrollChild(f.body)
  f.scroll:EnableMouseWheel(true)
  -- Smooth scrolling: the wheel moves a target spot, and every frame the list glides a share of the way there.
  f.target = 0
  f.scroll:SetScript("OnMouseWheel", function(self, delta)
    local range = self:GetVerticalScrollRange() or 0
    f.target = math.max(0, math.min(range, (f.target or self:GetVerticalScroll()) - delta * ROW * 2))
  end)
  f.scroll:SetScript("OnUpdate", function(self, elapsed)
    local target = f.target
    if not target then return end
    local cur = self:GetVerticalScroll() or 0
    if cur == target then return end
    local nxt = cur + (target - cur) * math.min(1, (elapsed or 0.016) * SMOOTH)
    if math.abs(target - nxt) < 0.5 then nxt = target end
    self:SetVerticalScroll(nxt)
    updateThumb(f)
  end)
  f.thumb = f:CreateTexture(nil, "OVERLAY")
  f.thumb:SetTexture(WHITE)
  f.thumb:Hide()
  f.rows = {}
  f:SetScript("OnHide", function(self)
    closeFrom(self.depth + 1)
    if self.depth == 1 then
      if catcher then catcher:Hide() end
      if ns.UI.freeEscSlot then ns.UI.freeEscSlot(ESC_NAME) end
    end
  end)
  levels[i] = f
  return f
end

local function makeRow(f)
  local b = ns.UI.makeButton(f.body)
  b:SetHeight(ROW)
  b.label:ClearAllPoints()
  b.label:SetPoint("LEFT", 8, 0)
  b.label:SetPoint("RIGHT", -16, 0)
  b.label:SetJustifyH("LEFT")
  b.arrow = b:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  b.arrow:SetPoint("RIGHT", -5, 0)
  b.arrow:SetText(">")
  b:RegisterForClicks("LeftButtonUp")
  b:HookScript("OnEnter", function(self)
    closeFrom(self.depth + 1)
    if self.entry and self.entry.children then Dropdown.open(self, self.entry.children, self.depth + 1) end
  end)
  b:SetScript("OnClick", function(self)
    local e = self.entry
    if not e or e.children then return end
    Dropdown.close()
    if e.func then e.func() end
  end)
  return b
end

local function paintRow(b, skin)
  local style = {
    backdrop = { bgFile = WHITE },
    bg = { 0, 0, 0, 0 },
    hover = skin.button.hover,
    text = skin.text,
  }
  ns.Skins.paintButton(b, skin, style)
  ns.Skins.setFont(b.arrow, skin)
  ns.Skins.setTextColor(b.arrow, skin.muted)
end

-- anchor: the menu button (depth 1) or the row that was pointed at (deeper levels).
function Dropdown.open(anchor, entries, depth)
  depth = depth or 1
  if not catcher then makeCatcher() end
  if depth == 1 then closeFrom(1) end
  local f = level(depth)
  local skin = ns.Skins.current()
  ns.Skins.paintFrame(f, skin)
  if f.thumb.SetColorTexture and skin.muted then
    f.thumb:SetColorTexture(skin.muted[1], skin.muted[2], skin.muted[3], 0.8)
  end

  if not measure then measure = UIParent:CreateFontString(nil, "OVERLAY", "GameFontNormal") measure:Hide() end
  ns.Skins.setFont(measure, skin)
  local widest = 0
  for i, e in ipairs(entries) do
    local r = f.rows[i]
    if not r then r = makeRow(f) f.rows[i] = r end
    r.depth, r.entry = depth, e
    r:ClearAllPoints()
    r:SetPoint("TOPLEFT", f.body, "TOPLEFT", 0, -(i - 1) * ROW)
    r:SetPoint("TOPRIGHT", f.body, "TOPRIGHT", 0, -(i - 1) * ROW)
    paintRow(r, skin)
    r:SetLabel(e.text or "")
    r.arrow:SetShown(e.children and true or false)
    r:Show()
    measure:SetText(e.text or "")
    local w = measure:GetStringWidth() or 0
    if w > widest then widest = w end
  end
  for i = #entries + 1, #f.rows do f.rows[i]:Hide() end

  local width = math.max(MINW, math.min(MAXW, math.ceil(widest) + 40))
  local contentH = #entries * ROW
  f:SetSize(width, math.min(contentH, MAXH) + PAD * 2)
  f.body:SetSize(width - PAD * 2, contentH)
  f.scroll:SetVerticalScroll(0)
  f.target = 0

  f:ClearAllPoints()
  local scale = UIParent:GetHeight() or 768
  if depth == 1 then
    local _, y = anchor:GetCenter()
    if y and y > scale / 2 then
      f:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -2)
    else
      f:SetPoint("BOTTOMLEFT", anchor, "TOPLEFT", 0, 2)
    end
    catcher:Show()
    if ns.UI.claimEscSlot then ns.UI.claimEscSlot(ESC_NAME) end
  else
    local right = anchor:GetRight() or 0
    if right + width > (UIParent:GetWidth() or 1024) then
      f:SetPoint("TOPRIGHT", anchor, "TOPLEFT", -2, PAD)
    else
      f:SetPoint("TOPLEFT", anchor, "TOPRIGHT", 2, PAD)
    end
  end
  f:Show()
  updateThumb(f)
  -- The scroll range is only known after the first layout pass, so look again next frame.
  if C_Timer and C_Timer.After then C_Timer.After(0, function() if f:IsShown() then updateThumb(f) end end) end
end
