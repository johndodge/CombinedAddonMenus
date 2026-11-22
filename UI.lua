-- Combined Addon Menus - the list window.
-- One row per addon: icon, name, then one button per way to open its menu.
-- The list is scanned again each time the window opens. Every part is painted by the current skin.

local ADDON, ns = ...
local UI = {}
ns.UI = UI

local WIDTH, HEIGHT = 640, 500
local TITLE_W = 170
local BTN_H, GAP, LINE_H = 20, 4, 24
local MAX_SHOWN = 8                   -- buttons shown before "+N more"
local FRAME_NAME = "CombinedAddonMenusFrame"

local frame, scroll, content, search, placeholder, emptyText, titleText, hint, closeBtn, optionsBtn
local contentW = WIDTH - 60
local btnX = 28 + TITLE_W + 8
local rowPool, btnPool = {}, {}
local rows = {}                       -- last scan result
local expanded = {}                   -- row key -> true when "+N more" was clicked

local function try(frameType, name, parent, ...)
  for i = 1, select("#", ...) do
    local template = select(i, ...)
    local ok, f = pcall(CreateFrame, frameType, name, parent, template)
    if ok and f then return f end
  end
  return CreateFrame(frameType, name, parent)
end
UI.try = try

-- A plain button that skins can paint: backdrop + one centered label.
local function makeButton(parent)
  local b = try("Button", nil, parent, "BackdropTemplate")
  b:SetHeight(BTN_H)
  b.label = b:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  b.label:SetPoint("CENTER", 0, 0)
  b.label:SetWordWrap(false)
  b.SetLabel = function(self, t) self.label:SetText(t) end
  ns.Skins.hookHover(b)
  return b
end
UI.makeButton = makeButton

---------------------------------------------------------------------------
-- Tooltips
---------------------------------------------------------------------------
local function showTooltip(self)
  local a = self.action
  GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
  if a then
    GameTooltip:AddLine(a.label or "", 1, 1, 1)
    if a.tip then GameTooltip:AddLine(a.tip, nil, nil, nil, true) end
    local opens = UI.describeEffect(a.kind ~= "settings" and ns.db and ns.db.effects and ns.db.effects[a.id])
    if opens then GameTooltip:AddLine("Opens " .. opens .. ".", 0.6, 0.8, 1, true) end
    if a.sameAs and #a.sameAs > 0 then
      GameTooltip:AddLine("One button for all of these, because they open the same thing: " .. a.label .. ", "
        .. table.concat(a.sameAs, ", ") .. ".", 0.6, 0.8, 1, true)
      GameTooltip:AddLine("Shift-click: split them into separate buttons again.", 0.6, 0.8, 1, true)
    end
    GameTooltip:AddLine("To hide this button, add to Extras.lua: " .. a.id, 0.5, 0.5, 0.5, true)
  elseif self.tipText then
    GameTooltip:AddLine(self.tipText, 1, 1, 1, true)
  end
  GameTooltip:Show()
end

---------------------------------------------------------------------------
-- Esc handling. Esc normally closes every open window at once, this list too.
-- When a button opens another window that Esc can close, this list leaves the
-- Esc list (UISpecialFrames) until that window closes. So the first Esc closes
-- only that window, and the next Esc closes this list.
---------------------------------------------------------------------------
local watching = nil     -- windows opened from this list that are still open
local watcher            -- frame whose OnUpdate checks `watching`

-- The game's own Esc code reads UISpecialFrames. Any entry this addon writes, or moves, is marked as
-- touched by this addon, and the game's Esc code then runs tainted for it. table.remove() moves every
-- entry after the removed one, so it marks other addons' windows too (user report 2026-11-21: after a
-- button opened X-Perl, Esc no longer opened the game menu, and X-Perl's frames lost health and mana).
-- So entries are never removed or moved. A slot is switched to a name that is not a window, and reused.
local NO_WINDOW = "CombinedAddonMenusNoEsc"

local function claimSlot(name)
  for i = 1, #UISpecialFrames do
    if UISpecialFrames[i] == NO_WINDOW then UISpecialFrames[i] = name return end
  end
  table.insert(UISpecialFrames, name)
end

local function freeSlots(match)
  for i = 1, #UISpecialFrames do
    if match(UISpecialFrames[i]) then UISpecialFrames[i] = NO_WINDOW end
  end
end

local function setEscClosable(on)
  freeSlots(function(n) return n == FRAME_NAME end)
  if on then claimSlot(FRAME_NAME) end
end

-- The game can answer with a "secret" value (a hidden answer that addon code may not test).
-- Testing one is an error, so a secret answer counts as "unknown" and the frame is skipped.
local function secret(v)
  return type(issecretvalue) == "function" and issecretvalue(v) and true or false
end

-- Protected ("forbidden") game windows raise an error if an addon touches them, so skip them.
local function isShownFrame(f)
  if type(f) ~= "table" or type(f.IsShown) ~= "function" then return false end
  if type(f.IsForbidden) == "function" then
    local ok, forbidden = pcall(f.IsForbidden, f)
    if not ok or secret(forbidden) or forbidden then return false end
  end
  local ok, shown = pcall(f.IsShown, f)
  if not ok or secret(shown) then return false end
  return shown and true or false
end

local function nameOf(f)
  local ok, n = pcall(f.GetName, f)
  if ok and not secret(n) and type(n) == "string" and n ~= "" then return n end
  return nil
end

-- The windows Esc can close that are open right now (not counting this list).
-- Returns frame -> name (a string when the window has a name, else true).
local function escWindows()
  local set = {}
  for _, name in ipairs(UISpecialFrames) do
    if name ~= FRAME_NAME and isShownFrame(_G[name]) then set[_G[name]] = name end
  end
  if type(GetUIPanel) == "function" then
    for _, side in ipairs({ "left", "center", "right", "doublewide", "fullscreen" }) do
      local ok, f = pcall(GetUIPanel, side)
      if ok and isShownFrame(f) then set[f] = nameOf(f) or true end
    end
  end
  -- Ace3 option windows close on Esc through their own code, not UISpecialFrames.
  local acd = LibStub and LibStub("AceConfigDialog-3.0", true)
  if acd and type(acd.OpenFrames) == "table" then
    for app, widget in pairs(acd.OpenFrames) do
      local f = type(widget) == "table" and widget.frame
      if isShownFrame(f) then set[f] = "ace:" .. tostring(app) end
    end
  end
  return set
end

-- Named windows shown at the top level (children of UIParent), for learning what a
-- button opens even when Esc can't close that window (TomTom's Paste window).
local IGNORE = { "Tooltip", "^DropDownList", "^L_DropDownList", "^Lib_DropDownList", "^LibQTip",
                 "^CombinedAddonMenus", "^GameMenuFrame$", "^ChatFrame", "^Menu" }
local function ignored(n)
  for _, pat in ipairs(IGNORE) do
    if n:find(pat) then return true end
  end
  return false
end

-- Shared windows that many different buttons can make appear: popups ("this needs a value"),
-- error windows, alerts, zone text, unit frames. Seeing one says nothing about what a
-- button opens, so they never count when learning duplicates.
local SHARED = { "^StaticPopup", "^ScriptErrors", "^BugSack", "^UIErrors", "ZoneText", "^RaidWarning",
                 "^RaidBossEmote", "Toast", "Alert", "^TalkingHead", "^ObjectiveTracker", "^PlayerFrame",
                 "^TargetFrame", "^FocusFrame", "^Party", "^Compact", "^Minimap", "^ItemRef", "^LevelUp",
                 "^GameTime", "^Buff", "^Help", "^Ticket" }
local function shared(n)
  if type(n) ~= "string" then return true end
  if ignored(n) then return true end
  for _, pat in ipairs(SHARED) do
    if n:find(pat) then return true end
  end
  return false
end

-- A real window is not tiny. Unknown sizes pass.
local function bigEnough(f)
  local okW, w = pcall(f.GetWidth, f)
  local okH, h = pcall(f.GetHeight, f)
  if okW and okH and (secret(w) or secret(h)) then return false end
  if okW and okH and type(w) == "number" and type(h) == "number" then
    return w >= 120 and h >= 60
  end
  return true
end

-- Words for a learned effect, for tooltips and chat.
function UI.describeEffect(e)
  if type(e) ~= "string" then return nil end
  if e:find("^settings:") then return "its settings page" end
  if e:find("^ace:") then return "the options window " .. e:sub(5) end
  if e:find("^window:") then return "the window " .. e:sub(8) end
  return e
end

local function topWindows()
  local set = {}
  local ok, kids = pcall(function() return { UIParent:GetChildren() } end)
  if not ok then return set end
  for _, f in ipairs(kids) do
    if isShownFrame(f) then
      local n = nameOf(f)
      if n and not ignored(n) then set[f] = n end
      -- One level deeper too: X-Perl's options window sits under a helper frame (XPerl_OptionsAnchor).
      local okSub, sub = pcall(function() return { f:GetChildren() } end)
      if okSub then
        for _, g in ipairs(sub) do
          if isShownFrame(g) then
            local gn = nameOf(g)
            if gn and not ignored(gn) then set[g] = gn end
          end
        end
      end
    end
  end
  return set
end

-- Some addon windows don't close on Esc (TomTom's Paste window), so Esc skipped them and
-- closed this list instead. While such a window, opened from this list, is open, its name
-- is lent to the Esc list (UISpecialFrames). It is taken back when the window closes.
-- Protected game windows are never lent.
local lent = {}

-- A window one level below UIParent (X-Perl's options sit under a helper frame) counts only when it is
-- large. Preview bars and unit-frame parts are small; options windows are not.
local function isLargeWindow(f)
  local okW, w = pcall(f.GetWidth, f)
  local okH, h = pcall(f.GetHeight, f)
  if not (okW and okH) or secret(w) or secret(h) then return false end
  return type(w) == "number" and type(h) == "number" and w >= 350 and h >= 250
end

-- Esc hides a window with a plain Hide. Many windows do cleanup in their Close button instead (X-Perl's
-- Close button puts its unit frames back to normal; a plain Hide leaves its move-me preview frames on
-- screen). So when Esc hides a lent window, that window's own Close button script runs once afterwards.
-- If the Close button itself closed the window, it is not run a second time.
local function closeButtonOf(f, name)
  local a, b, c = f.CloseButton, _G[name .. "_CloseButton"], _G[name .. "CloseButton"]
  for _, btn in pairs({ a = a, b = b, c = c }) do
    if type(btn) == "table" and type(btn.GetScript) == "function" then return btn end
  end
end

local function hookCloseButton(f, name)
  if f.camCloseHooked or type(f.HookScript) ~= "function" then return end
  local b = closeButtonOf(f, name)
  if not b or type(b.HookScript) ~= "function" then return end
  f.camCloseHooked = true
  b:HookScript("PreClick", function() f.camClosedByButton = true end)
  f:HookScript("OnHide", function()
    if not lent[name] then return end
    if f.camClosedByButton then f.camClosedByButton = nil return end

    C_Timer.After(0, function()
      local fn = b:GetScript("OnClick")
      if type(fn) == "function" then pcall(fn, b, "LeftButton") end
    end)
  end)
end

local function lendEsc(f, name)
  if type(name) ~= "string" or lent[name] or _G[name] ~= f then return false end
  -- Only real windows: direct children of UIParent, not a shared game frame. Child frames that
  -- an addon shows in bulk (X-Perl's preview health/mana bars) must never reach the Esc list: Esc hid them
  -- and the game menu did not open (found by review 2026-11-21, confirmed by /cam nowatch).
  local okP, parent = pcall(f.GetParent, f)
  if not okP or secret(parent) or type(parent) ~= "table" then return false end
  if parent ~= UIParent then
    local okG, grand = pcall(parent.GetParent, parent)
    if not (okG and grand == UIParent and isLargeWindow(f)) then return false end
  end
  if shared(name) then return false end
  local ok, protected = pcall(f.IsProtected, f)
  if not ok or secret(protected) or protected then return false end
  for _, n in ipairs(UISpecialFrames) do
    if n == name then return false end
  end
  claimSlot(name)
  lent[name] = true
  hookCloseButton(f, name)
  return true
end

local function returnEsc()
  freeSlots(function(n) return lent[n] end)
  wipe(lent)
end

function UI.checkWatch()
  if not watching then return end
  local open = frame and frame:IsShown()
  if open then
    for f in pairs(watching) do
      if isShownFrame(f) then return end
    end
  end
  watching = nil
  returnEsc()
  setEscClosable(true)
  if watcher then watcher:Hide() end
end

local function ensureWatcher()
  if watcher then return end
  watcher = CreateFrame("Frame")
  local wait = 0
  watcher:SetScript("OnUpdate", function(_, elapsed)
    wait = wait + (elapsed or 0)
    if wait < 0.2 then return end
    wait = 0
    UI.checkWatch()
  end)
end

---------------------------------------------------------------------------
-- The settings window. When a button opens it (a Settings button, or a slash
-- command such as /tomtom that opens a settings page), this list hides. When the
-- settings window closes, the game shows its ESC menu. We close that again and
-- show this list instead.
---------------------------------------------------------------------------
local cameFromList = false
local hooked = false

local function backToList()
  if GameMenuFrame and GameMenuFrame:IsShown() then HideUIPanel(GameMenuFrame) end
  if frame and not frame:IsShown() then frame:Show() end
end

local function hookSettingsPanel()
  if hooked or type(SettingsPanel) ~= "table" or type(SettingsPanel.HookScript) ~= "function" then return end
  hooked = true
  SettingsPanel:HookScript("OnHide", function()
    if not cameFromList then return end
    cameFromList = false
    -- Wait one frame: the game shows its ESC menu right after the settings window hides.
    if C_Timer and C_Timer.After then C_Timer.After(0, backToList) else backToList() end
  end)
end

local function enterSettings(listWasShown)
  hookSettingsPanel()
  if not listWasShown then return end
  cameFromList = true
  if frame and frame:IsShown() then frame:Hide() end
end

---------------------------------------------------------------------------
-- Learning what each button opens, so buttons that open the same thing show once.
-- Saved per account in CombinedAddonMenusDB.effects (action id -> "settings:<id>" or "window:<name>").
-- Only left clicks teach: a right click often opens a different menu. /cam reset forgets it all.
---------------------------------------------------------------------------
local function learn(action, effect, mouseButton)
  if not effect or not ns.db or action.kind == "settings" or action.kind == "extra" then return false end
  if mouseButton and mouseButton ~= "LeftButton" then return false end
  ns.db.effects = ns.db.effects or {}
  if ns.db.effects[action.id] == effect then return false end
  ns.db.effects[action.id] = effect
  return true
end

function UI.runAction(action, button, mouseButton)
  local listWasShown = frame and frame:IsShown()
  local settingsBefore = isShownFrame(SettingsPanel)
  local before = escWindows()
  local topBefore = topWindows()
  ns.Scan.beginCapture()
  local ok, err = pcall(action.run, button, mouseButton)
  if not ok then
    ns.say((action.label or "Button") .. " stopped with an error: " .. tostring(err))
    return
  end
  local done = false
  local cands = {}   -- frame -> { effect =, esc = true when Esc can close it }
  local function look(final)
    if done then return end
    if not settingsBefore and isShownFrame(SettingsPanel) then
      done = true
      learn(action, ns.Scan.settingsEffect(), mouseButton)
      enterSettings(listWasShown)
      return
    end
    local found
    for f, name in pairs(escWindows()) do
      if not before[f] then
        found = true
        before[f] = name
        watching = watching or {}
        watching[f] = true
        if type(name) == "string" and not shared(name:gsub("^ace:", "")) then
          cands[f] = { effect = name:find("^ace:") and name or ("window:" .. name), esc = true }
        end
      end
    end
    local nowShown, newCount = topWindows(), 0
    for f in pairs(nowShown) do if not topBefore[f] and not isLargeWindow(f) then newCount = newCount + 1 end end
    for f, name in pairs(nowShown) do
      if not topBefore[f] then
        topBefore[f] = name
        -- More than 3 new small frames from one click is a mass show (a preview), not a window: lend none of them.
        if listWasShown and (newCount <= 3 or isLargeWindow(f)) and lendEsc(f, name) then
          found = true
          watching = watching or {}
          watching[f] = true
        end
        if not cands[f] and not shared(name) and bigEnough(f) then
          cands[f] = { effect = "window:" .. name }
        end
      end
    end
    if found then
      setEscClosable(false)
      ensureWatcher()
      watcher:Show()
    end
    if not final then return end
    done = true
    -- Learn only when the answer is clear: one window that is still open at the end.
    -- Prefer a window Esc can close; if several different windows opened, learn nothing.
    local escSet, topSet, nEsc, nTop = {}, {}, 0, 0
    for f, c in pairs(cands) do
      if isShownFrame(f) then
        if c.esc then
          if not escSet[c.effect] then escSet[c.effect] = true nEsc = nEsc + 1 end
        elseif not topSet[c.effect] then
          topSet[c.effect] = true nTop = nTop + 1
        end
      end
    end
    local effect
    if nEsc == 1 then
      effect = next(escSet)
    elseif nEsc == 0 and nTop == 1 then
      effect = next(topSet)
    end
    if learn(action, effect, mouseButton) and frame and frame:IsShown() then UI.refresh() end
  end
  -- Watching is a convenience. If it ever fails, the click must still work and the user is told once.
  local told = false
  local function safeLook(final)
    local ok, err = pcall(look, final)
    if not ok and not told then
      told = true
      ns.say("Could not watch what that button opened: " .. tostring(err))
    end
  end
  -- Some addons build their window a moment after the click, so look again.
  if C_Timer and C_Timer.After then
    safeLook(false)
    C_Timer.After(0, function() safeLook(false) end)
    C_Timer.After(0.3, function() safeLook(true) end)
  else
    safeLook(true)
  end
end

-- Forgets what one addon's buttons open, so its hidden buttons show again.
function UI.forgetRow(action)
  if not ns.db or not ns.db.effects then return end
  ns.db.effects[action.id] = nil
  for _, id in ipairs(action.sameIds or {}) do ns.db.effects[id] = nil end
  ns.say("Showing the hidden buttons again. They hide again only if they open the same thing the next time you use them.")
  UI.refresh()
end

-- Opens this addon's own settings page, with the same return path as other settings pages.
function UI.openOptions()
  if not (ns.Options and ns.Options.categoryID) then
    ns.say("The settings page is not ready.")
    return
  end
  UI.runAction({
    kind = "settings", id = "CombinedAddonMenus Settings", label = "Settings",
    run = function()
      if InCombatLockdown and InCombatLockdown() then
        ns.say("Settings pages can't open during combat. Try again after combat.")
        return
      end
      Settings.OpenToCategory(ns.Options.categoryID)
    end,
  })
end

---------------------------------------------------------------------------
-- Buttons and rows (pooled, so a rescan reuses frames)
---------------------------------------------------------------------------
local function onClick(self, mouseButton)
  if self.action and self.action.sameAs and IsShiftKeyDown and IsShiftKeyDown() then
    UI.forgetRow(self.action)
  elseif self.action then
    UI.runAction(self.action, self, mouseButton)
  elseif self.onMore then
    self.onMore()
  end
end

local function getButton(i)
  local b = btnPool[i]
  if not b then
    b = makeButton(content)
    b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    b:SetScript("OnClick", onClick)
    b:HookScript("OnEnter", showTooltip)
    b:HookScript("OnLeave", function() GameTooltip:Hide() end)
    btnPool[i] = b
  end
  b.action, b.onMore, b.tipText = nil, nil, nil
  return b
end

local function getRow(i)
  local r = rowPool[i]
  if not r then
    r = CreateFrame("Frame", nil, content)
    r.icon = r:CreateTexture(nil, "ARTWORK")
    r.icon:SetSize(18, 18)
    r.icon:SetPoint("TOPLEFT", 4, -3)
    r.title = r:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    r.title:SetPoint("TOPLEFT", 28, -5)
    r.title:SetWidth(TITLE_W)
    r.title:SetJustifyH("LEFT")
    r.title:SetWordWrap(false)
    r.line = r:CreateTexture(nil, "BACKGROUND")
    r.line:SetPoint("BOTTOMLEFT", 0, 0)
    r.line:SetPoint("BOTTOMRIGHT", 0, 0)
    r.line:SetHeight(1)
    rowPool[i] = r
  end
  return r
end

---------------------------------------------------------------------------
-- Layout
---------------------------------------------------------------------------
local function matches(row, q)
  if q == "" then return true end
  if row.title:lower():find(q, 1, true) then return true end
  for _, a in ipairs(row.actions) do
    if (a.label or ""):lower():find(q, 1, true) then return true end
    for _, other in ipairs(a.sameAs or {}) do
      if other:lower():find(q, 1, true) then return true end
    end
  end
  return false
end

function UI.layout()
  if not frame then return end
  local skin = ns.Skins.current()
  for _, r in ipairs(rowPool) do r:Hide() end
  for _, b in ipairs(btnPool) do b:Hide() end
  local q = search and (search:GetText() or ""):lower() or ""
  local y, nRow, nBtn = 0, 0, 0
  for _, data in ipairs(rows) do
    if matches(data, q) then
      nRow = nRow + 1
      local r = getRow(nRow)
      r:SetWidth(contentW)
      r:ClearAllPoints()
      r:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -y)
      ns.Skins.setFont(r.title, skin)
      ns.Skins.setTextColor(r.title, skin.text)
      r.title:SetText(data.title)
      r.line:SetColorTexture(skin.line[1], skin.line[2], skin.line[3], skin.line[4])
      r.icon:SetTexture(data.icon or "Interface\\Icons\\INV_Misc_QuestionMark")
      local list = data.actions
      local limit = #list
      if limit > MAX_SHOWN and not expanded[data.key] then limit = MAX_SHOWN - 1 end
      local x, line = btnX, 0
      local function place(b)
        ns.Skins.paintButton(b, skin, skin.button)
        b.label:SetWidth(0)   -- measure the whole text first
        local w = math.max(56, math.floor((b.label:GetStringWidth() or 40) + 18))
        local maxW = contentW - btnX - 4
        if w > maxW then
          w = maxW
          b.label:SetWidth(w - 10)   -- a very long combined name is cut with "..."
        end
        b:SetWidth(w)
        if x > btnX and x + w > contentW - 4 then
          x, line = btnX, line + 1
        end
        b:SetParent(r)
        b:ClearAllPoints()
        b:SetPoint("TOPLEFT", r, "TOPLEFT", x, -2 - line * LINE_H)
        b:Show()
        x = x + w + GAP
      end
      for i = 1, limit do
        nBtn = nBtn + 1
        local b = getButton(nBtn)
        b.action = list[i]
        b:SetLabel(list[i].display or list[i].label or "?")
        place(b)
      end
      if limit < #list then
        nBtn = nBtn + 1
        local b = getButton(nBtn)
        local key = data.key
        b:SetLabel("+" .. (#list - limit) .. " more")
        b.tipText = "Show all buttons for this addon."
        b.onMore = function() expanded[key] = true UI.layout() end
        place(b)
      end
      local h = (line + 1) * LINE_H + 2
      r:SetHeight(h)
      r:Show()
      y = y + h
    end
  end
  content:SetHeight(math.max(y, 1))
  if nRow == 0 then
    emptyText:SetText(#rows == 0 and "No addon menus found. Type /cam debug and send the result to the addon author."
      or "No addon matches your search.")
    emptyText:Show()
  else
    emptyText:Hide()
  end
end

-- Says in chat when a button is newly hidden because it opens the same thing as another,
-- so a button that disappears is clearly on purpose. The first scan of a session only records.
local knownHidden
local function reportNewHidden(list)
  local now, news = {}, {}
  for _, r in ipairs(list) do
    for _, a in ipairs(r.actions) do
      for _, other in ipairs(a.sameAs or {}) do
        local k = r.key .. "|" .. other
        now[k] = true
        if knownHidden and not knownHidden[k] then
          local what = UI.describeEffect(a.effect or (ns.db and ns.db.effects and ns.db.effects[a.id]))
          news[#news + 1] = r.title .. ": \"" .. other .. "\" opens the same thing as \""
            .. (a.label or "?") .. "\"" .. (what and (" (" .. what .. ")") or "") .. ", so they are one button now."
        end
      end
    end
  end
  knownHidden = now
  for _, m in ipairs(news) do ns.say(m) end
  if #news > 0 then
    ns.say("If that is wrong, Shift-click the combined button to split them again.")
  end
end

local lastCount = 0
function UI.refresh(isRetry)
  local ok, result = pcall(ns.Scan.run)
  if ok then
    rows = result
    pcall(reportNewHidden, rows)
  else
    rows = {}
    ns.say("The scan stopped with an error: " .. tostring(result))
  end
  local okL, errL = pcall(UI.layout)
  if not okL then ns.say("The list stopped drawing with an error: " .. tostring(errL)) end
  -- Saved for /cam debug: how many buttons the list had, and whether the second look found more.
  local n, slash = 0, 0
  for _, r in ipairs(rows) do
    for _, a in ipairs(r.actions) do
      n = n + 1
      if a.kind == "slash" then slash = slash + 1 end
    end
  end
  if ns.db then
    local t = date and date("%H:%M:%S") or nil
    -- What the scan said about slash commands, for the saved report and for chat when it found none.
    local notes = {}
    for _, line in ipairs(ns.Scan.report()) do
      if line:find("^Slash") or line:find("^Step") then notes[#notes + 1] = line end
    end
    if isRetry then
      if n ~= lastCount then ns.db.late = { first = lastCount, later = n, time = t } end
      ns.db.viewRetry = { buttons = n, slash = slash, time = t, notes = notes }
    else
      ns.db.view = { rows = #rows, buttons = n, slash = slash, time = t, notes = notes }
    end
    if slash == 0 and not isRetry then
      ns.say("No slash command buttons were found this time. The scan said: "
        .. (#notes > 0 and table.concat(notes, " | ") or "nothing"))
    end
  end
  lastCount = n
end

---------------------------------------------------------------------------
-- The window
---------------------------------------------------------------------------
local function savePosition()
  if not ns.db then return end
  local point, _, relPoint, x, y = frame:GetPoint(1)
  ns.db.pos = { point, relPoint, x, y }
end

-- Paints the window with the current skin and places its parts by the skin's padding.
function UI.applySkin()
  if not frame then return end
  local skin = ns.Skins.current()
  local pad = skin.pad
  ns.Skins.paintFrame(frame, skin)

  ns.Skins.setFont(titleText, skin, skin.titleSize)
  ns.Skins.setTextColor(titleText, skin.title)
  titleText:ClearAllPoints()
  titleText:SetPoint("TOPLEFT", pad + 4, -pad - 2)

  closeBtn:ClearAllPoints()
  closeBtn:SetPoint("TOPRIGHT", -pad, -pad + 2)
  ns.Skins.paintButton(closeBtn, skin, skin.button)
  optionsBtn:ClearAllPoints()
  optionsBtn:SetPoint("RIGHT", closeBtn, "LEFT", -4, 0)
  ns.Skins.paintButton(optionsBtn, skin, skin.button)
  optionsBtn:SetWidth(math.floor((optionsBtn.label:GetStringWidth() or 50) + 18))

  search:ClearAllPoints()
  search:SetPoint("TOPLEFT", pad + 2, -pad - 26)
  ns.Skins.paintButton(search, skin, skin.input)
  ns.Skins.setFont(search, skin)
  ns.Skins.setTextColor(search, skin.input.text)
  if search.SetTextColor then
    local c = skin.input.text
    search:SetTextColor(c[1], c[2], c[3])
  end
  ns.Skins.setFont(placeholder, skin)
  ns.Skins.setTextColor(placeholder, skin.muted)

  ns.Skins.setFont(hint, skin, skin.size - 1)
  ns.Skins.setTextColor(hint, skin.muted)
  hint:ClearAllPoints()
  hint:SetPoint("LEFT", search, "RIGHT", 12, 0)
  hint:SetPoint("RIGHT", frame, "RIGHT", -pad - 4, 0)

  scroll:ClearAllPoints()
  scroll:SetPoint("TOPLEFT", pad, -pad - 54)
  scroll:SetPoint("BOTTOMRIGHT", -pad - 24, pad)
  contentW = WIDTH - pad * 2 - 30
  content:SetWidth(contentW)

  ns.Skins.setFont(emptyText, skin)
  ns.Skins.setTextColor(emptyText, skin.text)
  UI.layout()
end

local function create()
  frame = try("Frame", FRAME_NAME, UIParent, "BackdropTemplate")
  frame:SetSize(WIDTH, HEIGHT)
  local p = ns.db and ns.db.pos
  if p then
    frame:SetPoint(p[1], UIParent, p[2], p[3], p[4])
  else
    frame:SetPoint("CENTER")
  end
  frame:SetFrameStrata("MEDIUM")
  frame:SetToplevel(true)
  frame:SetClampedToScreen(true)
  frame:SetMovable(true)
  frame:EnableMouse(true)
  frame:RegisterForDrag("LeftButton")
  frame:SetScript("OnDragStart", frame.StartMoving)
  frame:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() savePosition() end)
  frame:Hide()
  setEscClosable(true)   -- Esc closes it (see the Esc handling above)
  frame:HookScript("OnHide", function() UI.checkWatch() end)

  titleText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  titleText:SetText("Combined Addon Menus")

  closeBtn = makeButton(frame)
  closeBtn:SetSize(22, 20)
  closeBtn:SetLabel("X")
  closeBtn:SetScript("OnClick", function() frame:Hide() end)

  optionsBtn = makeButton(frame)
  optionsBtn:SetLabel("Settings")
  optionsBtn.tipText = "Skins, the menu button, other addons' minimap icons, and the blacklist."
  optionsBtn:HookScript("OnEnter", showTooltip)
  optionsBtn:HookScript("OnLeave", function() GameTooltip:Hide() end)
  optionsBtn:SetScript("OnClick", function() UI.openOptions() end)

  search = try("EditBox", nil, frame, "BackdropTemplate")
  search:SetSize(220, 22)
  search:SetAutoFocus(false)
  search:SetFontObject("ChatFontNormal")   -- the game refuses text in an edit box with no font
  search:SetTextInsets(6, 6, 0, 0)
  search.label = nil
  placeholder = search:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  placeholder:SetPoint("LEFT", 7, 0)
  placeholder:SetText("Search...")
  local function updatePlaceholder()
    placeholder:SetShown((search:GetText() or "") == "" and not search:HasFocus())
  end
  search:SetScript("OnTextChanged", function() updatePlaceholder() UI.layout() end)
  search:SetScript("OnEditFocusGained", updatePlaceholder)
  search:SetScript("OnEditFocusLost", updatePlaceholder)
  search:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
  search:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)

  hint = frame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  hint:SetJustifyH("RIGHT")
  hint:SetText("Right-click a button for its right-click action.")

  scroll = try("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate", "ScrollFrameTemplate")
  content = CreateFrame("Frame", nil, scroll)
  content:SetSize(contentW, 1)
  scroll:SetScrollChild(content)

  emptyText = frame:CreateFontString(nil, "ARTWORK", "GameFontNormal")
  emptyText:SetPoint("TOP", scroll, "TOP", 0, -30)
  emptyText:SetWidth(WIDTH - 80)

  frame:SetScript("OnShow", function()
    UI.refresh()
    -- Look once more a moment later, in case something was not ready at the first look.
    if C_Timer and C_Timer.After then
      C_Timer.After(1.5, function() if frame and frame:IsShown() then UI.refresh(true) end end)
    end
  end)
  UI.applySkin()
end

function UI.toggle()
  if not frame then create() end
  if frame:IsShown() then frame:Hide() else frame:Show() end
end

function UI.isShown() return frame and frame:IsShown() end
