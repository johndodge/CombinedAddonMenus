-- Combined Addon Menus - finds the menus of the other addons.
-- Four sources, all read at the moment the list opens:
--   1. Settings pages (ESC > Options > AddOns)
--   2. The minimap dropdown (Addon Compartment): .toc AddonCompartmentFunc and runtime entries
--   3. Minimap buttons made with LibDataBroker (launchers with an OnClick)
--   4. Slash commands made by addons (owner from issecurevariable)
-- Plus the hand-made entries in Extras.lua.

local ADDON, ns = ...
local Scan = {}
ns.Scan = Scan

-- Button order in a row (user choice 2026-11-20): Settings, Minimap, Dropdown, slash commands, your own.
-- A "launcher" is a LibDataBroker launcher with no visible minimap icon (its addon hides it).
local KIND_ORDER = { settings = 1, minimap = 2, dropdown = 3, launcher = 4, slash = 5, extra = 6 }
local KIND_LABEL = { settings = "Settings", dropdown = "Dropdown", minimap = "Minimap" }

---------------------------------------------------------------------------
-- Text helpers
---------------------------------------------------------------------------
local function plain(s)
  if type(s) ~= "string" then return "" end
  s = s:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("|T.-|t", ""):gsub("|A.-|a", "")
  s = s:gsub("^%s+", ""):gsub("%s+$", "")
  return s
end
Scan.plain = plain

local function norm(s)
  return (plain(s):lower():gsub("[^%w]", ""))
end
Scan.norm = norm

---------------------------------------------------------------------------
-- Installed addons and name matching
---------------------------------------------------------------------------
local C = C_AddOns or {}
local GetNumAddOnsF = C.GetNumAddOns or GetNumAddOns
local GetAddOnInfoF = C.GetAddOnInfo or GetAddOnInfo
local IsAddOnLoadedF = C.IsAddOnLoaded or IsAddOnLoaded
local GetMetaF = C.GetAddOnMetadata or GetAddOnMetadata

local function isLoaded(name)
  if not IsAddOnLoadedF then return true end
  local ok, a, b = pcall(IsAddOnLoadedF, name)
  if not ok then return false end
  if b ~= nil then return b and true or false end
  return a and true or false
end

local function meta(name, field)
  if not GetMetaF then return nil end
  local ok, v = pcall(GetMetaF, name, field)
  if ok and type(v) == "string" and v ~= "" then return v end
  return nil
end

local addons = {}   -- folder name -> { name, title, icon }
local byKey = {}    -- normalized name or title -> folder name

function Scan.buildIndex()
  wipe(addons)
  wipe(byKey)
  local n = GetNumAddOnsF and GetNumAddOnsF() or 0
  for i = 1, n do
    local name, title = GetAddOnInfoF(i)
    if type(name) == "string" and isLoaded(name) then
      local t = plain(title)
      if t == "" then t = name end
      addons[name] = { name = name, title = t, icon = meta(name, "IconTexture") }
      local k1, k2 = norm(name), norm(t)
      if k1 ~= "" and not byKey[k1] then byKey[k1] = name end
      if k2 ~= "" and not byKey[k2] then byKey[k2] = name end
    end
  end
end

function Scan.addons() return addons end

-- Finds the addon a piece of text (a menu name, a command word) belongs to.
-- Exact match first, then "<text>core" (DBM -> DBM-Core), then the shortest addon
-- whose name starts with the text, then the longest addon name the text starts with.
function Scan.match(text)
  local k = norm(text)
  if #k < 3 then return nil end
  if byKey[k] then return byKey[k] end
  if byKey[k .. "core"] then return byKey[k .. "core"] end
  local best, bestKey
  for key, name in pairs(byKey) do
    if #key > #k and key:sub(1, #k) == k then
      if not best or #key < #bestKey or (#key == #bestKey and key < bestKey) then
        best, bestKey = name, key
      end
    end
  end
  if best then return best end
  for key, name in pairs(byKey) do
    if #key >= 4 and #key < #k and k:sub(1, #key) == key then
      if not best or #key > #bestKey or (#key == #bestKey and key < bestKey) then
        best, bestKey = name, key
      end
    end
  end
  return best
end

-- When the letters of `short` appear in order in `long`, starting with the same letter,
-- returns how far into `long` the match reaches (smaller = tighter fit). Else nil.
-- "bt4" -> "bartender4", "dcr" -> "decursive".
local function isAbbrev(short, long)
  if #short < 2 or #long <= #short or short:sub(1, 1) ~= long:sub(1, 1) then return nil end
  local pos = 1
  for i = 1, #short do
    pos = long:find(short:sub(i, i), pos, true)
    if not pos then return nil end
    pos = pos + 1
  end
  return pos - 1
end

-- Finds the addon a short command word stands for, such as "bt4" for Bartender4.
-- The tightest fit wins ("bt" fits Bartender4 better than BagBrother), then the shorter name.
function Scan.abbrev(text)
  local k = norm(text)
  local best, bestSpan
  for name, a in pairs(addons) do
    if name ~= ADDON then
      local s1, s2 = isAbbrev(k, norm(name)), isAbbrev(k, norm(a.title))
      local span = (s1 and s2) and math.min(s1, s2) or s1 or s2
      if span and (not best or span < bestSpan or (span == bestSpan and (#name < #best or (#name == #best and name < best)))) then
        best, bestSpan = name, span
      end
    end
  end
  return best
end

-- How well a command word fits its addon: 0 = it is the name (/decursive, /dbm),
-- 1 = a short form of the name (/dcr), 2 = anything else. Close fits sort first.
local function slashRank(word, owner)
  local w = norm(word)
  local a = addons[owner]
  for _, n in ipairs({ norm(owner), a and norm(a.title) or "" }) do
    if n ~= "" and (n:sub(1, #w) == w or w:sub(1, #n) == n) then return 0 end
  end
  for _, n in ipairs({ norm(owner), a and norm(a.title) or "" }) do
    if isAbbrev(w, n) then return 1 end
  end
  return 2
end

---------------------------------------------------------------------------
-- Rows and actions
---------------------------------------------------------------------------
-- A row is one addon. An action is one button: { kind, detail, tip, id, run(button, mouseButton) }.
local function getRow(rows, owner, fallbackTitle)
  if owner == ADDON then return nil end
  local key = owner
  if not key then
    local t = plain(fallbackTitle)
    if t == "" then return nil end
    key = "~" .. t
  end
  local r = rows[key]
  if not r then
    local a = owner and addons[owner]
    r = {
      key = key,
      title = (a and a.title) or (owner and plain(owner)) or plain(fallbackTitle),
      icon = a and a.icon,
      actions = {},
    }
    rows[key] = r
  end
  return r
end

local function addAction(rows, owner, fallbackTitle, action)
  local r = getRow(rows, owner, fallbackTitle)
  if not r then return end
  action.id = (owner or plain(fallbackTitle)) .. " " .. (action.detail or action.kind)
  if ns.Hide and ns.Hide[action.id] then return end
  r.actions[#r.actions + 1] = action
  return r
end

local report = {}   -- what each source found, for /cam debug
local function note(source, text) report[#report + 1] = source .. ": " .. text end

---------------------------------------------------------------------------
-- Source 1: Settings pages
---------------------------------------------------------------------------
local function callMethod(obj, method, ...)
  if type(obj) ~= "table" or type(obj[method]) ~= "function" then return nil end
  local ok, v = pcall(obj[method], obj, ...)
  if ok then return v end
  return nil
end

local function asCategoryArray(t)
  if type(t) ~= "table" then return nil end
  if type(t.categories) == "table" then return t.categories end
  if t[1] ~= nil then return t end
  return nil
end

-- Returns a list of categories and how it was found.
-- Tries the AddOns set first; if that fails, all categories (then only names that match an addon are kept).
local function settingsCategories()
  local panel = SettingsPanel
  if type(panel) ~= "table" then return nil, "SettingsPanel missing", false end
  local list = callMethod(panel, "GetCategoryList")
  local addonSet = Settings and Settings.CategorySet and Settings.CategorySet.AddOns
  if list and addonSet ~= nil then
    local cats = asCategoryArray(callMethod(list, "GetCategorySet", addonSet))
    if cats then return cats, "CategoryList:GetCategorySet(AddOns)", true end
    if type(list.categorySets) == "table" then
      cats = asCategoryArray(list.categorySets[addonSet])
      if cats then return cats, "CategoryList.categorySets[AddOns]", true end
    end
  end
  local cats = asCategoryArray(callMethod(panel, "GetAllCategories"))
  if cats then return cats, "SettingsPanel:GetAllCategories", false end
  cats = asCategoryArray(callMethod(list, "GetAllCategories"))
  if cats then return cats, "CategoryList:GetAllCategories", false end
  return nil, "no category list found", false
end

-- Categories registered after this addon loaded: owner from the call stack.
local lateOwner = {}
local function ownerFromStack()
  if type(debugstack) ~= "function" then return nil end
  local ok, stack = pcall(debugstack, 3, 30, 0)
  if not ok or type(stack) ~= "string" then return nil end
  for folder in stack:gmatch("[Ii]nterface[/\\][Aa]dd[Oo]ns[/\\]([^/\\]+)[/\\]") do
    if folder ~= ADDON and not folder:find("^Blizzard_") then return folder end
  end
  return nil
end
-- Which settings page a button opened: Settings.OpenToCategory is watched while a button runs.
local captured = nil
local catKey = {}   -- category table, name or ID (also of child pages) -> top page ID
if type(Settings) == "table" and type(Settings.OpenToCategory) == "function" and hooksecurefunc then
  hooksecurefunc(Settings, "OpenToCategory", function(arg) captured = arg end)
end
function Scan.beginCapture() captured = nil end

if type(Settings) == "table" and type(Settings.RegisterAddOnCategory) == "function" and hooksecurefunc then
  hooksecurefunc(Settings, "RegisterAddOnCategory", function(category)
    if type(category) == "table" then lateOwner[category] = ownerFromStack() or false end
  end)
end

local function categoryId(cat)
  local id = callMethod(cat, "GetID")
  if id == nil then id = cat.ID end
  return id
end

-- The addon whose code created a category: its fields were written while that addon ran.
-- The game's own pages are secure and give nil.
local function taintOwner(cat)
  if type(issecurevariable) ~= "function" then return nil end
  for _, field in ipairs({ "name", "ID", "categoryID" }) do
    if rawget(cat, field) ~= nil then
      local ok, secure, owner = pcall(issecurevariable, cat, field)
      if ok and not secure and type(owner) == "string" and owner ~= "" then return owner end
    end
  end
  return nil
end

local function rootOf(cat)
  for _ = 1, 10 do
    local parent = callMethod(cat, "GetParentCategory") or cat.parentCategory
    if type(parent) ~= "table" then return cat end
    cat = parent
  end
  return cat
end

-- "settings:<top page ID>" for the page the last button opened, or nil if unknown.
function Scan.settingsEffect()
  local a = captured
  if a == nil then
    a = callMethod(SettingsPanel, "GetCurrentCategory")
  end
  if a == nil then return nil end
  local id = catKey[a]
  if id == nil and type(a) == "table" then id = catKey[categoryId(a)] or categoryId(rootOf(a)) end
  if id == nil and type(a) ~= "table" then id = a end
  if id == nil then return nil end
  return "settings:" .. tostring(id)
end

-- Opens one settings page. The game's open call only takes number IDs, but some addons
-- give their page a text ID (ForeverDungeonJournal uses "DungeonJournal"). For those,
-- open the settings window and pick the page directly.
function Scan.openCategory(cat, id)
  if InCombatLockdown and InCombatLockdown() then
    ns.say("Settings pages can't open during combat. Try again after combat.")
    return
  end
  if type(id) == "number" and pcall(Settings.OpenToCategory, id) then return end
  local panel = SettingsPanel
  if type(panel) == "table" then
    if not (panel.IsShown and panel:IsShown()) then
      if type(panel.Open) == "function" then pcall(panel.Open, panel) else pcall(ShowUIPanel, panel) end
    end
    if type(panel.SelectCategory) == "function" and pcall(panel.SelectCategory, panel, cat) then return end
  end
  ns.say("Could not open the settings page " .. tostring(callMethod(cat, "GetName") or cat.name or id)
    .. ". Open it from ESC > Options > AddOns.")
end

local function scanSettings(rows)
  local cats, how, isAddonSet = settingsCategories()
  if not cats then note("Settings", how) return end
  for _, cat in ipairs(cats) do
    if type(cat) == "table" then
      local rootId = categoryId(rootOf(cat))
      if rootId ~= nil then
        catKey[cat] = rootId
        local cid = categoryId(cat)
        if cid ~= nil then catKey[cid] = rootId end
        local nm = callMethod(cat, "GetName") or cat.name
        if type(nm) == "string" and catKey[nm] == nil then catKey[nm] = rootId end
      end
    end
  end
  local found, skipped, skippedNames = 0, 0, {}
  for _, cat in ipairs(cats) do
    local parent = type(cat) == "table" and (callMethod(cat, "GetParentCategory") or cat.parentCategory)
    if type(cat) == "table" and not parent then
      local name = plain(callMethod(cat, "GetName") or cat.name)
      local id = categoryId(cat)
      local tainted = taintOwner(cat)
      local owner = Scan.match(name) or lateOwner[cat] or tainted
      if owner and not addons[owner] then owner = Scan.match(owner) or owner end
      if name ~= "" and id ~= nil and (owner or isAddonSet or lateOwner[cat] ~= nil) then
        found = found + 1
        addAction(rows, owner, name, {
          kind = "settings",
          detail = name,
          effect = "settings:" .. tostring(id),
          tip = "Opens this addon's page in ESC > Options > AddOns. Closing it brings you back to this list.",
          run = function() Scan.openCategory(cat, id) end,
        })
      else
        skipped = skipped + 1
        skippedNames[#skippedNames + 1] = name
      end
    end
  end
  note("Settings", found .. " pages via " .. how .. " (" .. skipped .. " skipped)")
  if #skippedNames > 0 then note("Settings skipped", table.concat(skippedNames, ", ")) end
end

---------------------------------------------------------------------------
-- Source 2: the minimap dropdown (Addon Compartment)
---------------------------------------------------------------------------
local tocCompartment = {}   -- normalized title -> true, so runtime duplicates are skipped

local function scanCompartmentToc(rows)
  wipe(tocCompartment)
  local found = 0
  for name, a in pairs(addons) do
    local fname = meta(name, "AddonCompartmentFunc")
    if fname and name ~= ADDON then
      tocCompartment[norm(a.title)] = true
      tocCompartment[norm(name)] = true
      found = found + 1
      addAction(rows, name, a.title, {
        kind = "dropdown",
        detail = "Dropdown",
        tip = "Same as clicking this addon in the minimap dropdown. Right-click works too.",
        run = function(_, mouseButton)
          local f = _G[fname]
          if type(f) ~= "function" then
            ns.say(a.title .. ": its dropdown function " .. fname .. " is missing.")
            return
          end
          f(name, mouseButton or "LeftButton")
        end,
      })
    end
  end
  note("Dropdown (.toc)", found .. " entries")
end

local function scanCompartmentRuntime(rows, ldbNames)
  local frame = AddonCompartmentFrame
  local list = type(frame) == "table" and frame.registeredAddons
  if type(list) ~= "table" then note("Dropdown (runtime)", "no registeredAddons list") return end
  local found, dup = 0, 0
  for _, d in ipairs(list) do
    if type(d) == "table" and type(d.func) == "function" then
      local text = plain(d.text)
      local k = norm(text)
      if text == "" or tocCompartment[k] or ldbNames[k] then
        dup = dup + 1
      else
        found = found + 1
        addAction(rows, Scan.match(text), text, {
          kind = "dropdown",
          detail = "Dropdown: " .. text,
          tip = "Same as clicking this entry in the minimap dropdown. Right-click works too.",
          run = function(button, mouseButton)
            d.func(button, { buttonName = mouseButton or "LeftButton" }, button)
          end,
        })
      end
    end
  end
  note("Dropdown (runtime)", found .. " entries, " .. dup .. " duplicates skipped")
end

---------------------------------------------------------------------------
-- Source 3: minimap buttons (LibDataBroker launchers)
---------------------------------------------------------------------------
local function scanBroker(rows, ldbNames)
  local ldb = LibStub and LibStub("LibDataBroker-1.1", true)
  if not ldb then note("Minimap", "LibDataBroker not loaded") return end
  local found = 0
  for name, obj in ldb:DataObjectIterator() do
    if type(obj) == "table" and type(obj.OnClick) == "function" and name ~= ns.BROKER_NAME then
      ldbNames[norm(name)] = true
      local owner = Scan.match(obj.tocname) or Scan.match(name) or Scan.match(obj.label)
      found = found + 1
      -- "Minimap" only when LibDBIcon has an icon for it that its addon has not hidden.
      -- An icon this addon hides (settings page) still counts: the user hid it on purpose.
      local dbicon = LibStub("LibDBIcon-1.0", true)
      local icon = dbicon and type(dbicon.GetMinimapButton) == "function" and dbicon:GetMinimapButton(name)
      local addonHid = icon and type(icon.db) == "table" and icon.db.hide
      local onMinimap = icon and not addonHid
      local r = addAction(rows, owner, name, {
        kind = onMinimap and "minimap" or "launcher",
        detail = (onMinimap and "Minimap: " or "Launcher: ") .. plain(name),
        ldbName = plain(name),
        tip = onMinimap and "Same as clicking this addon's minimap icon. Right-click works too."
          or "This addon's launcher. It has no icon on the minimap. Right-click works too.",
        run = function(button, mouseButton)
          obj.OnClick(button, mouseButton or "LeftButton")
        end,
      })
      if r and not r.icon and type(obj.icon) == "string" then r.icon = obj.icon end
    end
  end
  note("Minimap", found .. " launchers")
end

---------------------------------------------------------------------------
-- Source 4: slash commands
---------------------------------------------------------------------------
local function realSlashTable()
  local mt = getmetatable(SlashCmdList)
  if type(mt) == "table" and type(mt.__index) == "table" then return mt.__index, "proxy" end
  return SlashCmdList, "plain"
end

local function aliases(key)
  local out = {}
  for i = 1, 20 do
    local c = _G["SLASH_" .. key .. i]
    if type(c) ~= "string" then break end
    out[#out + 1] = c
  end
  return out
end

-- Finds the handler for a typed command such as "/dbm". Returns handler, key.
function Scan.findSlash(word)
  word = word:lower()
  local real = realSlashTable()
  for key, fn in pairs(real) do
    if type(key) == "string" and type(fn) == "function" then
      for _, c in ipairs(aliases(key)) do
        if c:lower() == word then return fn, key end
      end
    end
  end
  return nil
end

local function chatEditBox()
  if ChatFrameUtil and type(ChatFrameUtil.GetActiveWindow) == "function" then
    local ok, eb = pcall(ChatFrameUtil.GetActiveWindow)
    if ok and eb then return eb end
  end
  if DEFAULT_CHAT_FRAME and DEFAULT_CHAT_FRAME.editBox then return DEFAULT_CHAT_FRAME.editBox end
  return ChatFrame1EditBox
end

-- Runs a slash command right away (decision: option B).
local function runSlash(fn, label, msg)
  local ok, err = pcall(fn, msg or "", chatEditBox())
  if not ok then ns.say(label .. " stopped with an error: " .. tostring(err)) end
end
Scan.runSlash = runSlash

function Scan.runSlashText(text)
  local word, rest = text:match("^%s*(/%S+)%s*(.-)%s*$")
  if not word then ns.say("Not a slash command: " .. tostring(text)) return end
  local fn = Scan.findSlash(word)
  if not fn then ns.say(word .. " is not a known command.") return end
  runSlash(fn, word, rest)
end

local function scanSlash(rows)
  local real, how = realSlashTable()
  local found, game = 0, 0
  for key, fn in pairs(real) do
    if type(key) == "string" and type(fn) == "function" then
      local _, owner = issecurevariable(real, key)
      local list = aliases(key)
      if owner and owner ~= ADDON and #list > 0 then
        local target = owner
        if key:find("^ACECONSOLE_") then
          -- Ace3 addons share one AceConsole copy, so the owner can be the wrong addon.
          target = Scan.match(key:sub(12)) or Scan.abbrev(key:sub(12)) or owner
        elseif not addons[owner] then
          target = Scan.match(key) or Scan.match(list[1]) or owner
        end
        found = found + 1
        local cmd = list[1]
        addAction(rows, target, target, {
          kind = "slash",
          detail = cmd,
          rank = slashRank(cmd, target),
          tip = "Runs " .. table.concat(list, ", ") .. " with nothing after it.",
          run = function()
            local f = SlashCmdList[key] or real[key]
            runSlash(f, cmd, "")
          end,
        })
      else
        game = game + 1
      end
    end
  end
  note("Slash", found .. " addon commands via " .. how .. " table, " .. game .. " game commands skipped")
end

---------------------------------------------------------------------------
-- Hand-made entries (Extras.lua)
---------------------------------------------------------------------------
local function scanExtras(rows)
  local found = 0
  for _, e in ipairs(ns.Extras or {}) do
    if type(e) == "table" and type(e.addon) == "string" and (type(e.slash) == "string" or type(e.run) == "function") then
      local owner = addons[e.addon] and e.addon or nil
      found = found + 1
      addAction(rows, owner, e.addon, {
        kind = "extra",
        detail = e.label or e.slash or "Open",
        tip = e.slash and ("Runs " .. e.slash .. " (from Extras.lua).") or "Your own entry from Extras.lua.",
        run = function()
          if e.run then
            local ok, err = pcall(e.run)
            if not ok then ns.say((e.label or "Extra") .. " stopped with an error: " .. tostring(err)) end
          else
            Scan.runSlashText(e.slash)
          end
        end,
      })
    end
  end
  note("Extras", found .. " entries")
end

---------------------------------------------------------------------------
-- The full scan
---------------------------------------------------------------------------
local function sortActions(a, b)
  local oa, ob = KIND_ORDER[a.kind] or 9, KIND_ORDER[b.kind] or 9
  if oa ~= ob then return oa < ob end
  if a.kind == "slash" and b.kind == "slash" then
    if a.rank ~= b.rank then return (a.rank or 2) < (b.rank or 2) end
    if #a.detail ~= #b.detail then return #a.detail < #b.detail end
  end
  return (a.detail or "") < (b.detail or "")
end

-- Returns the sorted list of rows that have at least one action.
-- Returns the rows to show. With includeBlacklisted, rows on the blacklist come too
-- (each row has .blacklisted), for the settings page.
function Scan.run(includeBlacklisted)
  wipe(report)
  Scan.buildIndex()
  local rows, ldbNames = {}, {}
  local steps = {
    function() scanSettings(rows) end,
    function() scanCompartmentToc(rows) end,
    function() scanBroker(rows, ldbNames) end,
    function() scanCompartmentRuntime(rows, ldbNames) end,
    function() scanSlash(rows) end,
    function() scanExtras(rows) end,
  }
  for i, step in ipairs(steps) do
    local ok, err = pcall(step)
    if not ok then note("Step " .. i, "error: " .. tostring(err)) end
  end
  local out = {}
  for _, r in pairs(rows) do
    if #r.actions > 0 then
      table.sort(r.actions, sortActions)
      -- Buttons that open the same thing as an earlier button are hidden (the first one stays).
      local effects = ns.db and ns.db.effects or {}
      local seen, kept = {}, {}
      for _, a in ipairs(r.actions) do
        local e = a.effect or effects[a.id]
        if a.kind ~= "extra" and e and seen[e] then
          local keep = seen[e]
          keep.sameAs = keep.sameAs or {}
          keep.sameIds = keep.sameIds or {}
          keep.sameIds[#keep.sameIds + 1] = a.id
          keep.sameAs[#keep.sameAs + 1] = (a.kind == "launcher" and Scan.shortName(a.ldbName, r))
            or (a.kind ~= "slash" and KIND_LABEL[a.kind]) or a.detail or a.kind
        else
          if e then seen[e] = a end
          a.sameAs, a.sameIds = nil, nil
          kept[#kept + 1] = a
        end
      end
      r.actions = kept
      -- Button text: the plain kind name when a row has one of that kind, else the detail.
      local count = {}
      for _, a in ipairs(r.actions) do count[a.kind] = (count[a.kind] or 0) + 1 end
      for _, a in ipairs(r.actions) do
        if a.kind == "launcher" then
          a.label = Scan.shortName(a.ldbName, r)
        elseif a.kind == "slash" or a.kind == "extra" or count[a.kind] > 1 then
          a.label = a.detail
        else
          a.label = KIND_LABEL[a.kind] or a.detail
        end
      end
      r.blacklisted = ns.db and ns.db.blacklist and ns.db.blacklist[r.key] and true or false
      if includeBlacklisted or not r.blacklisted then out[#out + 1] = r end
    end
  end
  table.sort(out, function(a, b) return a.title:lower() < b.title:lower() end)
  return out
end

-- "TomTom-Paste" in TomTom's row -> "Paste". A launcher named like its addon -> "Launcher".
function Scan.shortName(name, row)
  name = plain(name)
  for _, prefix in ipairs({ row.title, row.key }) do
    if type(prefix) == "string" and prefix ~= "" and name:lower():sub(1, #prefix) == prefix:lower() then
      local rest = name:sub(#prefix + 1):gsub("^[%s%-_:%.]+", "")
      if rest == "" then return "Launcher" end
      return rest
    end
  end
  return name
end

function Scan.report() return report end
