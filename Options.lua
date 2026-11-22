-- Combined Addon Menus - the settings page (ESC > Options > AddOns > Combined Addon Menus).
-- Four sections: skin, the menu button, other addons' minimap icons, and the blacklist.
-- Also owns hiding other addons' minimap icons (LibDBIcon), which this page controls.

local ADDON, ns = ...
local Options = {}
ns.Options = Options

local PAGE_W = 600
local COL_W = 290

---------------------------------------------------------------------------
-- Other addons' minimap icons (LibDBIcon). Hidden names are saved in CombinedAddonMenusDB.hiddenIcons.
---------------------------------------------------------------------------
local function dbicon() return LibStub and LibStub("LibDBIcon-1.0", true) end

local function iconButton(name)
  local lib = dbicon()
  return lib and type(lib.GetMinimapButton) == "function" and lib:GetMinimapButton(name) or nil
end

-- True when the icon's own addon hides it (its own setting), so a tick box can't show it.
local function hiddenByAddon(name)
  local b = iconButton(name)
  return b and type(b.db) == "table" and b.db.hide and true or false
end

function Options.iconNames()
  local lib, out = dbicon(), {}
  if lib and type(lib.objects) == "table" then
    for name in pairs(lib.objects) do
      if type(name) == "string" then out[#out + 1] = name end
    end
  end
  table.sort(out, function(a, b) return a:lower() < b:lower() end)
  return out
end

function Options.applyIconHiding()
  local lib = dbicon()
  if not lib or not ns.db then return end
  for name in pairs(ns.db.hiddenIcons) do
    if iconButton(name) then lib:Hide(name) end
  end
end

-- If an addon shows its icon again (or registers it late), hide it again.
local hookedLib
function Options.hookIcons()
  local lib = dbicon()
  if not lib or hookedLib == lib or not hooksecurefunc then return end
  hookedLib = lib
  local function rehide(_, name)
    if ns.db and ns.db.hiddenIcons[name] then
      local b = iconButton(name)
      if b then b:Hide() end
    end
  end
  if type(lib.Show) == "function" then hooksecurefunc(lib, "Show", rehide) end
  if type(lib.Register) == "function" then hooksecurefunc(lib, "Register", rehide) end
end

function Options.setIconShown(name, show)
  local lib = dbicon()
  ns.db.hiddenIcons[name] = (not show) and true or nil
  if not lib then return end
  if show then
    if not hiddenByAddon(name) then lib:Show(name) end
  else
    lib:Hide(name)
  end
end

---------------------------------------------------------------------------
-- The page: built again each time it is shown, from small frame pools.
---------------------------------------------------------------------------
local panel, scroll, content
local pools = { fs = {}, check = {}, skin = {}, btn = {} }
local used = { fs = 0, check = 0, skin = 0, btn = 0 }
local y = 0

local function resetPools()
  for kind, list in pairs(pools) do
    for _, o in ipairs(list) do o:Hide() end
    used[kind] = 0
  end
end

local function take(kind, make)
  used[kind] = used[kind] + 1
  local o = pools[kind][used[kind]]
  if not o then
    o = make()
    pools[kind][used[kind]] = o
  end
  o:ClearAllPoints()
  o:Show()
  return o
end

local function text(str, fontObject, width, x)
  local fs = take("fs", function() return content:CreateFontString(nil, "ARTWORK", "GameFontNormal") end)
  fs:SetFontObject(fontObject or "GameFontHighlight")
  fs:SetJustifyH("LEFT")
  fs:SetWordWrap(true)
  fs:SetWidth(width or (PAGE_W - 40))
  fs:SetPoint("TOPLEFT", x or 16, -y)
  fs:SetText(str)
  local h = fs:GetStringHeight() or 14
  return fs, h
end

local function header(str)
  y = y + 10
  local _, h = text(str, "GameFontNormalLarge")
  y = y + h + 8
end

local function para(str)
  local _, h = text(str, "GameFontHighlightSmall")
  y = y + h + 8
end

local function check(label, checked, onToggle, x, rowY)
  local c = take("check", function()
    local cb = ns.UI.try("CheckButton", nil, content, "UICheckButtonTemplate", "InterfaceOptionsCheckButtonTemplate")
    cb:SetSize(24, 24)
    cb.labelFS = cb:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    cb.labelFS:SetPoint("LEFT", cb, "RIGHT", 2, 0)
    cb.labelFS:SetWidth(COL_W - 34)
    cb.labelFS:SetJustifyH("LEFT")
    cb.labelFS:SetWordWrap(false)
    cb:SetScript("OnClick", function(self)
      if self.onToggle then self.onToggle(self:GetChecked() and true or false) end
    end)
    return cb
  end)
  c:SetPoint("TOPLEFT", x or 16, -(rowY or y))
  c.labelFS:SetText(label)
  c:SetChecked(checked and true or false)
  c.onToggle = onToggle
  return c
end

-- Two columns of tick boxes. items: { label, checked, onToggle }.
local function checkList(items)
  for i, it in ipairs(items) do
    local col = (i - 1) % 2
    local rowY = y + math.floor((i - 1) / 2) * 26
    check(it[1], it[2], it[3], 16 + col * COL_W, rowY)
  end
  y = y + math.ceil(#items / 2) * 26 + 6
end

local function plainButton(label, onClick, x)
  local b = take("btn", function()
    local nb = ns.UI.try("Button", nil, content, "UIPanelButtonTemplate")
    nb:SetHeight(22)
    nb:SetScript("OnClick", function(self) if self.onClickFn then self.onClickFn() end end)
    return nb
  end)
  b:SetText(label)
  b:SetWidth(180)
  b:SetPoint("TOPLEFT", x or 16, -y)
  b.onClickFn = onClick
  return b
end

-- A small copy of the list window, painted in a skin, so a skin can be seen before and after it is picked.
local preview
local PREVIEW_ROWS = {
  { "Interface\\Icons\\INV_Misc_Map_01", "TomTom", { "Settings", "Minimap", "/way" } },
  { "Interface\\Icons\\INV_Misc_Book_09", "Atlas", { "Settings", "Minimap", "/atlas" } },
}

local function makePreview()
  local f = ns.UI.try("Frame", nil, content, "BackdropTemplate")
  f:SetSize(PAGE_W - 40, 150)
  f.logo = f:CreateTexture(nil, "ARTWORK")
  f.logo:SetSize(30, 30)
  f.title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  f.title:SetText("Combined Addon Menus")
  f.search = ns.UI.try("Frame", nil, f, "BackdropTemplate")
  f.search:SetSize(170, 20)
  f.search.text = f.search:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  f.search.text:SetPoint("LEFT", 6, 0)
  f.search.text:SetText("Search...")
  f.rows = {}
  for i, def in ipairs(PREVIEW_ROWS) do
    local r = { buttons = {} }
    r.icon = f:CreateTexture(nil, "ARTWORK")
    r.icon:SetSize(18, 18)
    r.icon:SetTexture(def[1])
    r.name = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    r.name:SetText(def[2])
    r.line = f:CreateTexture(nil, "BACKGROUND")
    r.line:SetHeight(1)
    for j, label in ipairs(def[3]) do
      local b = ns.UI.makeButton(f)
      b:SetLabel(label)
      b:SetSize(70, 20)
      r.buttons[j] = b
    end
    f.rows[i] = r
  end
  return f
end

local function paintPreview(skinId)
  if not preview then return end
  local skin = ns.Skins.list[skinId] or ns.Skins.current()
  local pad = skin.pad
  ns.Skins.paintFrame(preview, skin)
  preview.logo:ClearAllPoints()
  preview.logo:SetPoint("TOPLEFT", pad, -pad + 4)
  preview.logo:SetTexture(ns.Button.logoPath(skinId))
  preview.title:ClearAllPoints()
  preview.title:SetPoint("LEFT", preview.logo, "RIGHT", 8, 0)
  ns.Skins.setFont(preview.title, skin, skin.titleSize)
  ns.Skins.setTextColor(preview.title, skin.title)
  preview.search:ClearAllPoints()
  preview.search:SetPoint("TOPRIGHT", -pad, -pad)
  ns.Skins.paintButton(preview.search, skin, skin.input)
  ns.Skins.setFont(preview.search.text, skin)
  ns.Skins.setTextColor(preview.search.text, skin.muted)
  for i, r in ipairs(preview.rows) do
    local top = -pad - 34 - (i - 1) * 28
    r.icon:ClearAllPoints()
    r.icon:SetPoint("TOPLEFT", pad + 4, top - 1)
    r.name:ClearAllPoints()
    r.name:SetPoint("LEFT", r.icon, "RIGHT", 8, 0)
    ns.Skins.setFont(r.name, skin)
    ns.Skins.setTextColor(r.name, skin.text)
    r.line:ClearAllPoints()
    r.line:SetPoint("TOPLEFT", pad, top - 24)
    r.line:SetPoint("TOPRIGHT", -pad, top - 24)
    r.line:SetColorTexture(skin.line[1], skin.line[2], skin.line[3], skin.line[4])
    for j, b in ipairs(r.buttons) do
      ns.Skins.paintButton(b, skin, skin.button)
      b:ClearAllPoints()
      b:SetPoint("TOPLEFT", pad + 150 + (j - 1) * 76, top)
    end
  end
  preview.h = pad * 2 + 34 + #preview.rows * 28
  preview:SetHeight(preview.h)
end

local function skinGrid()
  local _, currentId = ns.Skins.current()
  for i, id in ipairs(ns.Skins.order) do
    local skin = ns.Skins.list[id]
    local b = take("skin", function()
      local nb = ns.UI.makeButton(content)
      nb:SetSize(180, 28)
      nb.logo = nb:CreateTexture(nil, "OVERLAY")
      nb.logo:SetSize(20, 20)
      nb.logo:SetPoint("LEFT", 5, 0)
      nb.label:ClearAllPoints()
      nb.label:SetPoint("CENTER", 11, 0)   -- leave room for the logo
      nb:SetScript("OnClick", function(self) ns.Skins.set(self.skinId) end)
      nb:HookScript("OnEnter", function(self)
        paintPreview(self.skinId)   -- pointing at a skin shows it in the preview
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine(ns.Skins.list[self.skinId].name)
        GameTooltip:AddLine(ns.Skins.list[self.skinId].desc, 1, 1, 1, true)
        GameTooltip:Show()
      end)
      nb:HookScript("OnLeave", function()
        GameTooltip:Hide()
        local _, id = ns.Skins.current()
        paintPreview(id)
      end)
      return nb
    end)
    b.skinId = id
    -- Each button is drawn in the skin it picks, as a preview.
    ns.Skins.paintButton(b, skin, skin.button)
    b.logo:SetTexture(ns.Button.logoPath(id))
    b:SetLabel(id == currentId and ("> " .. skin.name .. " <") or skin.name)
    local col, row = (i - 1) % 3, math.floor((i - 1) / 3)
    b:SetPoint("TOPLEFT", 16 + col * 190, -(y + row * 34))
  end
  y = y + math.ceil(#ns.Skins.order / 3) * 34 + 4
  local current = ns.Skins.list[currentId]
  para("Current skin: " .. current.name .. ". " .. current.desc)
  preview = preview or makePreview()
  preview:ClearAllPoints()
  preview:SetPoint("TOPLEFT", 16, -y)
  preview:Show()
  paintPreview(currentId)
  y = y + preview.h + 8
end

function Options.build()
  if not panel or not ns.db then return end
  resetPools()
  y = 12
  text("Combined Addon Menus", "GameFontNormalHuge")
  y = y + 34

  header("Skin")
  para("Click a skin to use it. It changes at once. Point at a skin to see it in the preview below.")
  skinGrid()

  header("The menu button")
  check("Show the menu button", ns.db.button.show, function(on) ns.Button.setShown(on) end)
  y = y + 30
  para("Click it to open the list. Right-click it to open this page. Hold Alt and drag it to move it.")
  plainButton("Reset its position", function() ns.Button.resetPosition() end)
  y = y + 30

  header("Minimap icons of other addons")
  local names = Options.iconNames()
  if #names == 0 then
    para("No addon uses the shared minimap icon library (LibDBIcon), so there is nothing to show here.")
  else
    para("Untick an addon to hide its icon from the minimap. You can still open it from Combined Addon Menus. "
      .. "Icons marked (hidden by its addon) are switched off in that addon's own settings.")
    local items = {}
    for _, name in ipairs(names) do
      local label = name
      if hiddenByAddon(name) then label = name .. " (hidden by its addon)" end
      items[#items + 1] = { label, not ns.db.hiddenIcons[name], function(on) Options.setIconShown(name, on) end }
    end
    checkList(items)
  end

  header("Blacklist")
  para("Tick an addon to hide it from the Combined Addon Menus list.")
  local ok, rows = pcall(ns.Scan.run, true)
  local items = {}
  if ok then
    for _, r in ipairs(rows) do
      local key = r.key
      items[#items + 1] = { r.title, r.blacklisted, function(on) ns.db.blacklist[key] = on and true or nil end }
    end
  end
  checkList(items)

  content:SetHeight(y + 20)
end

function Options.applySkin()
  if panel and panel:IsShown() then Options.build() end
end

function Options.register()
  if panel or type(Settings) ~= "table" or type(Settings.RegisterCanvasLayoutCategory) ~= "function" then return end
  panel = CreateFrame("Frame")
  panel.name = "Combined Addon Menus"
  scroll = ns.UI.try("ScrollFrame", nil, panel, "UIPanelScrollFrameTemplate", "ScrollFrameTemplate")
  scroll:SetPoint("TOPLEFT", 0, -4)
  scroll:SetPoint("BOTTOMRIGHT", -28, 4)
  content = CreateFrame("Frame", nil, scroll)
  content:SetSize(PAGE_W, 1)
  scroll:SetScrollChild(content)
  panel:SetScript("OnShow", function() Options.build() end)
  local category = Settings.RegisterCanvasLayoutCategory(panel, "Combined Addon Menus")
  Settings.RegisterAddOnCategory(category)
  Options.category = category
  Options.categoryID = (type(category.GetID) == "function" and category:GetID()) or category.ID
end
