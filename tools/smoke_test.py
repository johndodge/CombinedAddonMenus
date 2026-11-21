"""Smoke test for Combined Addon Menus: loads the addon in Lua 5.1 against a small mock of the game.

Run with a Python that has lupa:  python tools/smoke_test.py
It checks that every file loads, the scan finds each source, the window builds,
and buttons run their actions. It does not prove the real game behaves the same.
"""
import pathlib
import sys

from lupa import lua51

HERE = pathlib.Path(__file__).resolve().parent
ADDON = HERE.parent / "addon" / "CombinedAddonMenus"

MOCK = r"""
calls = {}
local function log(s) calls[#calls+1] = s end
function print(...) local t = {} for i=1,select("#",...) do t[#t+1]=tostring(select(i,...)) end log("print: "..table.concat(t," ")) end
function wipe(t) for k in pairs(t) do t[k]=nil end return t end
function hooksecurefunc(t, name, fn) local orig=t[name] t[name]=function(...) local r={orig(...)} fn(...) return unpack(r) end end
function debugstack() return '[string "@Interface/AddOns/LateAddon/Options.lua"]:10: in main chunk\n' end
function InCombatLockdown() return false end
UISpecialFrames = {}
function inEsc(name) for _, n in ipairs(UISpecialFrames) do if n == name then return true end end return false end

-- Frames
allFrames = {}
local function newObj(name)
  local o = { scripts = {}, shown = false, text = "", points = {}, children = {}, name = name }
  local methods = {
    SetScript = function(self, k, f) self.scripts[k] = f end,
    GetScript = function(self, k) return self.scripts[k] end,
    HookScript = function(self, k, f) local old = self.scripts[k] self.scripts[k] = function(...) if old then old(...) end f(...) end end,
    Show = function(self) local was = self.shown self.shown = true if not was and self.scripts.OnShow then self.scripts.OnShow(self) end end,
    Hide = function(self) local was = self.shown self.shown = false if was and self.scripts.OnHide then self.scripts.OnHide(self) end end,
    IsShown = function(self) return self.shown end,
    SetText = function(self, t)
      if self.needsFont and not self.font then error("FontString:SetText(): Font not set") end
      self.text = t
    end,
    SetFont = function(self, path) self.font = path return true end,
    SetFontObject = function(self, o) self.font = o end,
    GetFont = function(self) return self.font end,
    GetText = function(self) return self.text end,
    GetFontString = function(self) return { GetStringWidth = function() return 50 end } end,
    CreateTexture = function(self) return newObj() end,
    CreateFontString = function(self, name, layer, template)
      local fs = newObj() fs.needsFont = true fs.font = template return fs
    end,
    GetPoint = function(self) return "CENTER", nil, "CENTER", 0, 0 end,
    Click = function(self, b) if self.scripts.OnClick then self.scripts.OnClick(self, b or "LeftButton") end end,
    GetName = function(self) return self.name end,
    GetChildren = function(self) return unpack(self.children) end,
    GetChecked = function(self) return self.checked end,
    SetChecked = function(self, v) self.checked = v end,
  }
  -- Game methods start with a capital letter; any other unknown field is nil, like a real frame.
  return setmetatable(o, { __index = function(t, k)
    if methods[k] then return methods[k] end
    if type(k) == "string" and k:find("^%u") then return function() end end
  end })
end
function CreateFrame(kind, name, parent)
  local f = newObj(name)
  if kind == "EditBox" then f.needsFont = true end
  if name then _G[name] = f end
  if parent and parent.children then table.insert(parent.children, f) end
  table.insert(allFrames, f)
  return f
end
function fire(event, arg)
  for _, f in ipairs(allFrames) do
    if f.scripts.OnEvent then f.scripts.OnEvent(f, event, arg) end
  end
end
function IsAltKeyDown() return altDown end
function GetTime() return 100 end
UIParent = newObj("UIParent")
GameTooltip = newObj()

-- Addons
local list = {
  { "DBM-Core", "|cffffe00a<|r|cffff7d0aDBM Core|r|cffffe00a>|r" },
  { "DBM-GUI", "DBM GUI" },
  { "Atlas", "Atlas" },
  { "Bartender4", "Bartender4" },
  { "TomTom", "TomTom" },
  { "BagBrother", "BagBrother" },
  { "Lueur", "Lueur" },
  { "ForeverDungeonJournal", "DungeonJournal" },
  { "LateAddon", "Late Addon" },
  { "CombinedAddonMenus", "Combined Addon Menus" },
}
local metaData = {
  Atlas = { AddonCompartmentFunc = "Atlas_Toggle", IconTexture = "atlas.tga" },
  Lueur = { AddonCompartmentFunc = "Lueur_Missing" },
  CombinedAddonMenus = { AddonCompartmentFunc = "CombinedAddonMenus_OnCompartmentClick" },
}
C_AddOns = {
  GetNumAddOns = function() return #list end,
  GetAddOnInfo = function(i) return list[i][1], list[i][2] end,
  IsAddOnLoaded = function(n) return true, true end,
  GetAddOnMetadata = function(n, f) return metaData[n] and metaData[n][f] end,
}
function Atlas_Toggle(name, button) log("atlas toggle "..name.." "..button) end

-- Settings: one Blizzard page, three addon pages (one a child page)
local function cat(name, id, parent) return { name = name, ID = id, GetName = function(s) return s.name end, GetID = function(s) return s.ID end, GetParentCategory = function() return parent end } end
local bt = cat("Bartender4", 11)
local cats = { cat("Gameplay", 1), bt, cat("Bar 1", 12, bt), (function() local c = cat("Deadly Boss Mods", 13) c._taint = "DBM-GUI" return c end)(), cat("TomTom", 14),
  cat("Dungeon Journal", "DungeonJournal") }   -- a text ID, like ForeverDungeonJournal
SettingsPanel = newObj()
SettingsPanel.GetCategoryList = function() return { GetAllCategories = function() return cats end } end
SettingsPanel.Open = function(self) self:Show() end
SettingsPanel.SelectCategory = function(self, c) log("select page "..c:GetName()) end
GameMenuFrame = newObj()
function HideUIPanel(f) f:Hide() log("hide game menu") end
C_Timer = { After = function(t, f) f() end }
Settings = { CategorySet = { AddOns = 2 },
  OpenToCategory = function(id)
    if type(id) ~= "number" then error("bad argument #1 to 'OpenSettingsPanel' (outside of expected range)") end
    log("open settings "..tostring(id)) SettingsPanel:Show()
  end,
  RegisterAddOnCategory = function(c) cats[#cats+1] = c end,
  RegisterCanvasLayoutCategory = function(panel, name) canvasPanel = panel return cat(name, 50) end }

-- LibDataBroker and LibDBIcon
local objects = {}
local ldb = {
  NewDataObject = function(self, name, o) objects[name] = o return o end,
  DataObjectIterator = function(self) return pairs(objects) end,
}
objects["DBM"] = { type = "launcher", icon = "dbm.tga", OnClick = function(f, b) log("dbm click "..b) end }
objects["TomTom"] = { type = "launcher", OnClick = function(f, b) log("tomtom click "..b) TomTomWindow:Show() end }
TomTomWindow = newObj()
table.insert(UISpecialFrames, "TomTomWindow")
objects["TomTom-Paste"] = { type = "launcher", OnClick = function(f, b) log("paste click "..b) TomTomPaste:Show() end }
objects["Mystery Broker"] = { type = "launcher", OnClick = function(f, b) log("mystery click") end }
objects["NoClick"] = { type = "data source" }
local function iconBtn(hide) local b = newObj() b.db = { hide = hide } b.shown = not hide return b end
dbicon = { objects = { DBM = iconBtn(false), TomTom = iconBtn(false), ["TomTom-Paste"] = iconBtn(true) } }
function dbicon:GetMinimapButton(n) return self.objects[n] end
function dbicon:Register(n) log("dbicon register "..n) end
function dbicon:Hide(n) log("dbicon hide "..n) if self.objects[n] then self.objects[n]:Hide() end end
function dbicon:Show(n) log("dbicon show "..n) if self.objects[n] then self.objects[n]:Show() end end
function LibStub(name, silent)
  if name == "LibDataBroker-1.1" then return ldb end
  if name == "LibDBIcon-1.0" then return dbicon end
end

-- Addon Compartment: one LDB duplicate, one toc duplicate, one new entry
AddonCompartmentFrame = { registeredAddons = {
  { text = "TomTom", func = function() log("dup") end },
  { text = "|cffffffffAtlas|r", func = function() log("dup2") end },
  { text = "Bartender4", func = function(btn, input, menu) log("bt compartment "..input.buttonName) end },
} }

-- Slash commands behind a proxy, like the real client
local real = {}
local owners = {}
SlashCmdList = setmetatable({}, { __index = real, __newindex = function(t, k, v) real[k] = v owners[k] = CURRENT_ADDON end })
rawowners = {}
function issecurevariable(t, k)
  if t == SlashCmdList and rawget(t, k) and rawowners[k] then return false, rawowners[k] end
  if t == real then if owners[k] then return false, owners[k] end return true, nil end
  if type(t) == "table" and rawget(t, "_taint") then return false, t._taint end
  return true, nil
end
CURRENT_ADDON = nil
SLASH_DUMP1 = "/dump" SlashCmdList.DUMP = function() log("dump") end
CURRENT_ADDON = "DBM-Core"
SLASH_DEADLYBOSSMODS1 = "/dbm" SlashCmdList.DEADLYBOSSMODS = function(msg) log("dbm slash ["..msg.."]") end
SLASH_DBMPULL1 = "/pull" SLASH_DBMPULL2 = "/dbmpull" SlashCmdList.DBMPULL = function(msg) error("boom") end
CURRENT_ADDON = "Atlas"
SLASH_ACECONSOLE_BARTENDER1 = "/bartender" SlashCmdList.ACECONSOLE_BARTENDER = function(msg) log("bt slash") end
SLASH_ACECONSOLE_BT1 = "/bt" SlashCmdList.ACECONSOLE_BT = function(msg) log("bt short") end
SLASH_ACECONSOLE_BT41 = "/bt4" SlashCmdList.ACECONSOLE_BT4 = function(msg) log("bt4 slash") end
CURRENT_ADDON = "SomeLibHost"
SLASH_TOMTOMWAY1 = "/way" SlashCmdList.TOMTOMWAY = function(msg) log("way") end
CURRENT_ADDON = "TomTom"
SLASH_TOMTOM1 = "/tomtom" SlashCmdList.TOMTOM = function(msg) Settings.OpenToCategory(14) end
SLASH_TTWIN1 = "/ttwin" SlashCmdList.TTWIN = function(msg) TomTomWindow:Show() end
SLASH_TTPASTE1 = "/ttpaste" SlashCmdList.TTPASTE = function(msg) TomTomPaste:Show() end
CURRENT_ADDON = "Lueur"
SLASH_LUEA1 = "/luea" SlashCmdList.LUEA = function() StaticPopup1:Show() end
SLASH_LUEB1 = "/lueb" SlashCmdList.LUEB = function() StaticPopup1:Show() end
SLASH_LUEC1 = "/luec" SlashCmdList.LUEC = function() LueurMain:Show() LueurHelp:Show() end
SLASH_LUED1 = "/lued" SlashCmdList.LUED = function() LueurMain:Show() LueurHelp:Show() end
CURRENT_ADDON = "CombinedAddonMenus"
DEFAULT_CHAT_FRAME = { editBox = newObj() }
TomTomPaste = CreateFrame("Frame", "TomTomPaste", UIParent)   -- not Esc-closable
StaticPopup1 = CreateFrame("Frame", "StaticPopup1", UIParent)  -- the game's shared popup
table.insert(UISpecialFrames, "StaticPopup1")
LueurMain = CreateFrame("Frame", "LueurMain", UIParent)
LueurHelp = CreateFrame("Frame", "LueurHelp", UIParent)
-- A protected game window: touching it from addon code is an error (like CommunitiesAddDialog).
local forbidden = CreateFrame("Frame", "ForbiddenDialog", UIParent)
forbidden.IsForbidden = function() return true end
forbidden.IsShown = function() error("Attempt to access forbidden object from code tainted by an AddOn") end
forbidden.GetName = forbidden.IsShown
"""


def main():
    lua = lua51.LuaRuntime(unpack_returned_tuples=True)
    lua.execute(MOCK)
    ns = lua.table()
    run_file = lua.eval("function(src, name, ns) local f = assert(loadstring(src, '@'..name)) f('CombinedAddonMenus', ns) end")
    toc = (ADDON / "CombinedAddonMenus.toc").read_text(encoding="utf-8").splitlines()
    files = [l.strip() for l in toc if l.strip().endswith(".lua")]
    for name in files:
        run_file((ADDON / name).read_text(encoding="utf-8"), name, ns)
    lua.execute("fire('ADDON_LOADED', 'CombinedAddonMenus') fire('PLAYER_LOGIN')")
    # Extra entry and hide entry, as a user would add them
    lua.execute("CURRENT_ADDON = nil")
    lua.eval("""function(ns)
        ns.Extras[1] = { addon = "TomTom", label = "Way", slash = "/way 10 20" }
        ns.Hide["DBM-Core /pull"] = true
    end""")(ns)
    # Late settings registration (after our load): owner from the call stack
    lua.execute("""local c = { name = 'Late Thing', ID = 99, GetName = function(s) return s.name end, GetID = function(s) return s.ID end }
                   Settings.RegisterAddOnCategory(c)""")

    rows = ns.Scan.run()
    out = {}
    for i in range(1, len(rows) + 1):
        r = rows[i]
        out[r.title] = [r.actions[j].label for j in range(1, len(r.actions) + 1)]
    for line in ns.Scan.report().values():
        print("  report:", line)
    for k, v in out.items():
        print(f"  row {k!r}: {v}")

    failures = []
    TT_ALL = ["Settings", "Minimap", "Paste", "/tomtom", "/way", "/ttwin", "/ttpaste", "Way"]

    def check(cond, msg):
        if not cond:
            failures.append(msg)

    check("Gameplay" not in out, "Blizzard page 'Gameplay' must not show")
    check("Combined Addon Menus" not in out, "our own addon must not show")
    check(out.get("Bartender4") == ["Settings", "Dropdown", "/bartender", "/bt", "/bt4"], f"Bartender4 row wrong: {out.get('Bartender4')}")
    check(out.get("<DBM Core>") == ["Minimap", "/dbm"], f"DBM row wrong (hide list should drop /pull): {out.get('<DBM Core>')}")
    check(out.get("DBM GUI") == ["Settings"], f"settings page must use the taint owner: {out.get('DBM GUI')}")
    check(out.get("Atlas") == ["Dropdown"], f"Atlas row wrong (runtime duplicate must be skipped): {out.get('Atlas')}")
    check(out.get("TomTom") == TT_ALL, f"TomTom row wrong: {out.get('TomTom')}")
    check(out.get("Mystery Broker") == ["Launcher"], f"broker with no minimap icon must be a Launcher: {out.get('Mystery Broker')}")
    check(out.get("Late Addon") == ["Settings"], f"late settings page must use the stack owner: {out.get('Late Addon')}")
    check(out.get("Lueur") == ["Dropdown", "/luea", "/lueb", "/luec", "/lued"], f"Lueur row wrong: {out.get('Lueur')}")
    check(out.get("DungeonJournal") == ["Settings"], f"text-ID settings page row wrong: {out.get('DungeonJournal')}")

    # Run every action and look at the log
    for i in range(1, len(rows) + 1):
        acts = rows[i].actions
        for j in range(1, len(acts) + 1):
            acts[j].run(lua.table(), "RightButton")
    calls = list(lua.globals().calls.values())
    for expected in ["open settings 11", "open settings 13", "dbm click RightButton", "atlas toggle Atlas RightButton",
                     "bt compartment RightButton", "dbm slash []", "bt slash", "way", "open settings 99",
                     "select page Dungeon Journal"]:
        check(expected in calls, f"action did not run: {expected}")
    check(any("Lueur_Missing is missing" in c for c in calls), "missing dropdown function must print a message")

    # The window, the debug command and the keybinding path
    lua.globals().CombinedAddonMenus_Toggle()
    check(ns.UI.isShown(), "window must open")
    lua.globals().SlashCmdList.COMBINEDADDONMENUS("debug")
    lua.globals().SlashCmdList.COMBINEDADDONMENUS("")
    check(not ns.UI.isShown(), "/cam must close the open window")
    lua.globals().CombinedAddonMenus_OnCompartmentClick()
    check(ns.UI.isShown(), "dropdown entry must open the window")

    # Esc: a window opened from the list takes the list off the Esc list until it closes
    lua.execute("TomTomWindow:Hide() TomTomPaste:Hide() SettingsPanel:Hide()")
    check(ns.UI.isShown(), "list must be open before the Esc test")
    check(lua.eval("inEsc('CombinedAddonMenusFrame')"), "list must be on the Esc list at first")
    tt_row = [rows[i] for i in range(1, len(rows) + 1) if rows[i].title == "TomTom"][0]
    tt_minimap = [tt_row.actions[j] for j in range(1, len(tt_row.actions) + 1) if tt_row.actions[j].kind == "minimap"][0]
    ns.UI.runAction(tt_minimap, lua.table(), "LeftButton")
    check(not lua.eval("inEsc('CombinedAddonMenusFrame')"), "list must leave the Esc list while TomTom's window is open")
    ns.UI.checkWatch()
    check(not lua.eval("inEsc('CombinedAddonMenusFrame')"), "list must stay off the Esc list while TomTom's window is still open")
    lua.execute("TomTomWindow:Hide()")
    ns.UI.checkWatch()
    check(lua.eval("inEsc('CombinedAddonMenusFrame')"), "list must return to the Esc list when TomTom's window closes")
    check(lua.eval("#UISpecialFrames") == 3, "list must be on the Esc list only once")
    # A button that opens no Esc-closable window must not change anything
    dbm_row = [rows[i] for i in range(1, len(rows) + 1) if rows[i].title == "<DBM Core>"][0]
    ns.UI.runAction(dbm_row.actions[1], lua.table(), "LeftButton")
    check(lua.eval("inEsc('CombinedAddonMenusFrame')"), "list must stay on the Esc list when nothing Esc-closable opened")

    # Settings round trip: list hides, settings closes, game menu pops up, list comes back
    bt_row = [rows[i] for i in range(1, len(rows) + 1) if rows[i].title == "Bartender4"][0]
    ns.UI.runAction(bt_row.actions[1], lua.table(), "LeftButton")
    check(not ns.UI.isShown(), "list must hide while the settings window is open")
    lua.execute("GameMenuFrame:Show() SettingsPanel:Hide()")
    check(not lua.eval("GameMenuFrame:IsShown()"), "ESC menu must be closed after leaving settings")
    check(ns.UI.isShown(), "list must come back after leaving settings")
    # Settings opened the normal way (not from our list) must leave the ESC menu alone
    lua.execute("SettingsPanel:Show() GameMenuFrame:Show() SettingsPanel:Hide()")
    check(lua.eval("GameMenuFrame:IsShown()"), "ESC menu must stay when settings was not opened from our list")

    # /tomtom opens TomTom's settings page: same return path as a Settings button
    def row_actions(title):
        rs = ns.Scan.run()
        for i in range(1, len(rs) + 1):
            if rs[i].title == title:
                return rs[i].actions
        return None
    acts = row_actions("TomTom")
    tomtom_cmd = [acts[j] for j in range(1, len(acts) + 1) if acts[j].label == "/tomtom"][0]
    ns.UI.runAction(tomtom_cmd, lua.table(), "LeftButton")
    check(not ns.UI.isShown(), "/tomtom: list must hide while its settings page is open")
    lua.execute("GameMenuFrame:Show() SettingsPanel:Hide()")
    check(ns.UI.isShown() and not lua.eval("GameMenuFrame:IsShown()"), "/tomtom: list must come back without the ESC menu")
    # /ttwin opens the same window as the minimap button
    acts = row_actions("TomTom")
    tt_minimap = [acts[j] for j in range(1, len(acts) + 1) if acts[j].kind == "minimap"][0]
    ns.UI.runAction(tt_minimap, lua.table(), "LeftButton")
    lua.execute("TomTomWindow:Hide()")
    ns.UI.checkWatch()
    ttwin = [acts[j] for j in range(1, len(acts) + 1) if acts[j].label == "/ttwin"][0]
    ns.UI.runAction(ttwin, lua.table(), "LeftButton")
    lua.execute("TomTomWindow:Hide()")
    ns.UI.checkWatch()
    acts = row_actions("TomTom")
    labels = [acts[j].label for j in range(1, len(acts) + 1)]
    check(labels == ["Settings", "Minimap", "Paste", "/way", "/ttpaste", "Way"], f"duplicates must be hidden after use: {labels}")
    calls = list(lua.globals().calls.values())
    check(any('"/ttwin" opens the same thing as "Minimap" (the window TomTomWindow), so they are one button now' in c for c in calls),
          "chat must say when a button is hidden as a duplicate")
    # Paste (a window Esc can't close) and /ttpaste open the same window.
    # A right-click must not teach anything; a left-click must.
    paste = [acts[j] for j in range(1, len(acts) + 1) if acts[j].label == "Paste"][0]
    ns.UI.runAction(paste, lua.table(), "RightButton")
    lua.execute("TomTomPaste:Hide()")
    check(ns.db.effects[paste.id] is None, "a right-click must not teach what a button opens")
    lua.execute("if not CombinedAddonMenusFrame:IsShown() then CombinedAddonMenusFrame:Show() end")
    ns.UI.runAction(paste, lua.table(), "LeftButton")
    # Esc must close the Paste window first, not the list
    check(lua.eval("inEsc('TomTomPaste')") and not lua.eval("inEsc('CombinedAddonMenusFrame')"),
          "a window with no Esc support, opened from the list, must close on Esc before the list")
    lua.execute("TomTomPaste:Hide()")
    ns.UI.checkWatch()
    check(not lua.eval("inEsc('TomTomPaste')") and lua.eval("inEsc('CombinedAddonMenusFrame')"),
          "after the Paste window closes, it must leave the Esc list and the list must return to it")
    check(ns.db.effects[paste.id] == "window:TomTomPaste", f"Paste must learn its window: {ns.db.effects[paste.id]}")
    # A window that sits under a helper frame, not directly under UIParent (X-Perl's options window)
    lua.execute('XPerlAnchor = CreateFrame("Frame", "XPerl_OptionsAnchor", UIParent) XPerlAnchor:Show() '
                'XPerlOptions = CreateFrame("Frame", "XPerl_Options", XPerlAnchor) XPerlOptions:Hide()')
    lua.execute("if not CombinedAddonMenusFrame:IsShown() then CombinedAddonMenusFrame:Show() end")
    lua.execute('XPerlLocked = 0 function XPerl_LockFrames() XPerlLocked = 1 log("xperl lock") end')
    fake = lua.eval('{ id = "XPerl Launcher", kind = "launcher", label = "X-Perl", run = function() XPerl_Options:Show() end }')
    ns.UI.runAction(fake, lua.table(), "LeftButton")
    check(lua.eval("inEsc('XPerl_Options')") and not lua.eval("inEsc('CombinedAddonMenusFrame')"),
          "a window under a helper frame must close on Esc before the list")
    lua.execute("XPerl_Options:Hide()")   # what Esc does
    check(lua.eval("XPerlLocked") == 1, "hiding X-Perl's window with Esc must also run its own close step (XPerl_LockFrames)")
    ns.UI.checkWatch()
    check(lua.eval("inEsc('CombinedAddonMenusFrame')") and not lua.eval("inEsc('XPerl_Options')"),
          "after the X-Perl window closes, the list must be on the Esc list again")
    # A frame that answers IsShown with a secret value must be skipped, not tested
    lua.execute('issecretvalue = function(v) return type(v) == "table" and v.secret == true end '
                'SecretF = CreateFrame("Frame", "SecretF", UIParent) SecretF:Hide() '
                'SecretF.IsShown = function(self) if self.flag then return { secret = true } end return false end')
    lua.execute("if not CombinedAddonMenusFrame:IsShown() then CombinedAddonMenusFrame:Show() end")
    fake2 = lua.eval('{ id = "Secret", kind = "launcher", label = "Secret", run = function() SecretF.flag = true end }')
    ns.UI.runAction(fake2, lua.table(), "LeftButton")
    check(not lua.eval("inEsc('SecretF')"), "a frame with a secret IsShown answer must be skipped")
    ttp = [acts[j] for j in range(1, len(acts) + 1) if acts[j].label == "/ttpaste"][0]
    ns.UI.runAction(ttp, lua.table(), "LeftButton")
    lua.execute("TomTomPaste:Hide()")
    acts = row_actions("TomTom")
    labels = [acts[j].label for j in range(1, len(acts) + 1)]
    check(labels == ["Settings", "Minimap", "Paste", "/way", "Way"], f"/ttpaste must hide behind Paste: {labels}")
    disp = {acts[j].label: acts[j].display for j in range(1, len(acts) + 1) if acts[j].display}
    check(disp.get("Paste") == "Paste = /ttpaste", f"combined button must show all names: {disp}")
    check(all(acts[j].display is None for j in range(1, len(acts) + 1) if not acts[j].sameAs), "plain buttons need no display text")
    same = sorted(acts[j].sameAs[k] for j in range(1, len(acts) + 1) if acts[j].sameAs for k in range(1, len(acts[j].sameAs) + 1))
    check(same == ["/tomtom", "/ttpaste", "/ttwin"], f"kept buttons must list what they replace: {same}")
    lua.globals().SlashCmdList.COMBINEDADDONMENUS("reset")
    acts = row_actions("TomTom")
    check(len(acts) == len(TT_ALL), "/cam reset must show all buttons again")

    # A slash command that errors must not break anything
    ns.Scan.runSlashText("/dbmpull")
    calls = list(lua.globals().calls.values())
    check(any("/dbmpull stopped with an error" in c for c in calls), "slash error must be caught and printed")

    # Shared popups and unclear results must never make buttons look the same
    lua.execute("for _, f in ipairs({StaticPopup1, LueurMain, LueurHelp}) do f:Hide() end")
    for cmd in ["/luea", "/lueb", "/luec", "/lued"]:
        acts = row_actions("Lueur")
        a = [acts[j] for j in range(1, len(acts) + 1) if acts[j].label == cmd][0]
        ns.UI.runAction(a, lua.table(), "LeftButton")
        lua.execute("for _, f in ipairs({StaticPopup1, LueurMain, LueurHelp}) do f:Hide() end")
        ns.UI.checkWatch()
    acts = row_actions("Lueur")
    labels = [acts[j].label for j in range(1, len(acts) + 1)]
    check(labels == ["Dropdown", "/luea", "/lueb", "/luec", "/lued"],
          f"a shared popup or two windows at once must not hide buttons: {labels}")

    # Shift-click on a kept button shows its hidden twins again
    acts = row_actions("TomTom")
    tt_min = [acts[j] for j in range(1, len(acts) + 1) if acts[j].kind == "minimap"][0]
    ns.UI.runAction(tt_min, lua.table(), "LeftButton")
    lua.execute("TomTomWindow:Hide()")
    ns.UI.checkWatch()
    ttwin = [acts[j] for j in range(1, len(acts) + 1) if acts[j].label == "/ttwin"][0]
    ns.UI.runAction(ttwin, lua.table(), "LeftButton")
    lua.execute("TomTomWindow:Hide()")
    ns.UI.checkWatch()
    acts = row_actions("TomTom")
    kept = [acts[j] for j in range(1, len(acts) + 1) if acts[j].sameAs]
    check(len(kept) == 1 and "/ttwin" not in [acts[j].label for j in range(1, len(acts) + 1)], "setup: /ttwin must be hidden")
    if kept:
        ns.UI.forgetRow(kept[0])
        acts = row_actions("TomTom")
        check("/ttwin" in [acts[j].label for j in range(1, len(acts) + 1)], "Shift-click must show hidden buttons again")

    # Right after a reload the addons' commands can sit in the proxy itself, not behind it
    lua.execute('rawowners.LATE = "Late Addon" SLASH_LATE1 = "/latecmd" rawset(SlashCmdList, "LATE", function() log("late") end)')
    acts = row_actions("Late Addon")
    check("/latecmd" in [acts[j].label for j in range(1, len(acts) + 1)], "commands held in the proxy itself must be found")

    # Saved settings got their defaults
    check(ns.db.skin == "classic" and ns.db.button.show is True, "defaults must be filled at load")

    # Blacklist: hidden from the list, still on the settings page
    atlas_key = [r.key for r in (ns.Scan.run()[i] for i in range(1, len(ns.Scan.run()) + 1)) if r.title == "Atlas"][0]
    ns.db.blacklist[atlas_key] = True
    shown = [ns.Scan.run()[i].title for i in range(1, len(ns.Scan.run()) + 1)]
    allrows = ns.Scan.run(True)
    allt = {allrows[i].title: allrows[i].blacklisted for i in range(1, len(allrows) + 1)}
    check("Atlas" not in shown, "a blacklisted addon must not show in the list")
    check(allt.get("Atlas") is True, "the settings page must still list a blacklisted addon, ticked")
    check("Combined Addon Menus" not in allt, "our own settings page must not make a row")
    ns.db.blacklist[atlas_key] = None

    # The M button: exists, left-click toggles the list, right-click opens our settings page
    G = lua.globals()
    mbtn = G.CombinedAddonMenusButton
    check(mbtn is not None and mbtn.shown, "the M button must exist and show at login")
    if mbtn is not None:
        lua.execute("SettingsPanel:Hide()")
        was = bool(ns.UI.isShown())
        mbtn.Click(mbtn, "LeftButton")
        check(bool(ns.UI.isShown()) != was, "left-click on the M button must toggle the list")
        if not ns.UI.isShown():
            mbtn.Click(mbtn, "LeftButton")
        mbtn.Click(mbtn, "RightButton")
        calls = list(G.calls.values())
        check("open settings 50" in calls, "right-click on the M button must open our settings page")
        check(not ns.UI.isShown(), "the list must step aside for our settings page")
        lua.execute("GameMenuFrame:Show() SettingsPanel:Hide()")
        check(ns.UI.isShown(), "the list must come back after our settings page closes")
        # Alt+drag moves it and saves the spot; a plain drag does nothing
        mbtn.scripts.OnDragStart(mbtn)
        check(not mbtn.moving, "a drag without Alt must not move the button")
        G.altDown = True
        mbtn.scripts.OnDragStart(mbtn)
        mbtn.scripts.OnDragStop(mbtn)
        G.altDown = False
        check(ns.db.button.pos is not None, "Alt+drag must save the position")
        ns.Button.resetPosition()
        check(ns.db.button.pos is None, "reset must clear the position")
        G.SlashCmdList.COMBINEDADDONMENUS("button")
        check(not mbtn.shown and ns.db.button.show is False, "/cam button must hide the M button")
        G.SlashCmdList.COMBINEDADDONMENUS("button")
        check(mbtn.shown, "/cam button must show it again")

    # The settings page builds, and every skin applies without errors
    panel = G.canvasPanel
    check(panel is not None, "the settings page must register")
    if panel is not None:
        panel.Show(panel)
        for i in range(1, len(ns.Skins.order) + 1):
            ns.Skins.set(ns.Skins.order[i])
        check(ns.db.skin == ns.Skins.order[len(ns.Skins.order)], "Skins.set must save the skin")
        ns.Skins.set("classic")

    # Other addons' minimap icons: hide, stays hidden if the addon shows it again, show again
    ns.Options.setIconShown("DBM", False)
    check(ns.db.hiddenIcons.DBM is True and not G.dbicon.objects.DBM.shown, "hiding an icon must hide it and save it")
    G.dbicon.Show(G.dbicon, "DBM")
    check(not G.dbicon.objects.DBM.shown, "an icon the user hid must stay hidden when its addon shows it")
    ns.Options.setIconShown("DBM", True)
    check(ns.db.hiddenIcons.DBM is None and G.dbicon.objects.DBM.shown, "showing an icon must show it and forget it")
    ns.Options.setIconShown("TomTom-Paste", True)
    check(not G.dbicon.objects["TomTom-Paste"].shown, "an icon its own addon hides must not be forced on")

    if failures:
        print("FAILED:")
        for f in failures:
            print("  -", f)
        sys.exit(1)
    print("ALL CHECKS PASSED")


if __name__ == "__main__":
    main()
