-- Combined Addon Menus - slash commands, keybinding, saved settings and start-up.

local ADDON, ns = ...

local PREFIX = "|cff66ccffCombined Addon Menus|r: "
function ns.say(msg) print(PREFIX .. tostring(msg)) end

ns.BROKER_NAME = "CombinedAddonMenus"

-- Keybinding names (Key Bindings > AddOns).
BINDING_HEADER_COMBINEDADDONMENUS = "Combined Addon Menus"
BINDING_NAME_COMBINEDADDONMENUS_TOGGLE = "Open or close the mod list"

-- Called by the keybinding and by the minimap dropdown entry (.toc AddonCompartmentFunc).
function CombinedAddonMenus_Toggle() ns.UI.toggle() end
function CombinedAddonMenus_OnCompartmentClick(_, mouseButton)
  if mouseButton == "RightButton" then ns.UI.openOptions() else ns.UI.toggle() end
end

---------------------------------------------------------------------------
-- Saved settings (CombinedAddonMenusDB, one per account)
---------------------------------------------------------------------------
local DEFAULTS = {
  skin = "classic",
  button = { show = true },   -- the M button; pos is set when the user moves it
  hiddenIcons = {},           -- other addons' minimap icons the user hid (LibDBIcon names)
  blacklist = {},             -- rows (addon keys) hidden from the list
  effects = {},               -- what each button opens, learned on click (duplicate hiding)
}

local function fill(db, defaults)
  for k, v in pairs(defaults) do
    if db[k] == nil then
      if type(v) == "table" then
        db[k] = {}
        fill(db[k], v)
      else
        db[k] = v
      end
    elseif type(v) == "table" and type(db[k]) == "table" then
      fill(db[k], v)
    end
  end
end

---------------------------------------------------------------------------
-- /cam
---------------------------------------------------------------------------
local function help()
  ns.say("commands:")
  print("  /cam - open or close the list")
  print("  /cam settings - open the settings page")
  print("  /cam button - show or hide the M button")
  print("  /cam reset - show buttons again that were hidden as duplicates")
  print("  /cam debug - show what the scan found in each place")
end

SLASH_COMBINEDADDONMENUS1 = "/cam"
SlashCmdList.COMBINEDADDONMENUS = function(msg)
  msg = (msg or ""):lower():gsub("^%s+", ""):gsub("%s+$", "")
  if msg == "" then
    ns.UI.toggle()
  elseif msg == "settings" or msg == "options" then
    ns.UI.openOptions()
  elseif msg == "button" or msg == "minimap" then
    ns.Button.setShown(not ns.db.button.show)
    ns.say(ns.db.button.show and "M button shown." or "M button hidden. Type /cam button to show it again.")
  elseif msg == "reset" then
    if ns.db then ns.db.effects = {} end
    ns.say("Forgot which buttons do the same thing. All buttons show again until you use them.")
    if ns.UI.isShown() then ns.UI.refresh() end
  elseif msg == "debug" then
    local rows = ns.Scan.run()
    ns.say("scan found " .. #rows .. " addons with at least one button.")
    for _, line in ipairs(ns.Scan.report()) do print("  " .. line) end
    -- Saved to the SavedVariables file (written on /reload or logout) so it can be read outside the game.
    local saved = { time = date and date("%Y-%m-%d %H:%M:%S"), report = {}, rows = {} }
    for _, line in ipairs(ns.Scan.report()) do saved.report[#saved.report + 1] = line end
    for _, r in ipairs(rows) do
      local ids = {}
      for _, a in ipairs(r.actions) do ids[#ids + 1] = a.label .. "  <" .. a.id .. ">" end
      saved.rows[#saved.rows + 1] = { title = r.title, key = r.key, buttons = ids }
    end
    if not ns.db then ns.say("Saved settings are not ready, so the report was not saved.") return end
    ns.db.debug = saved
    ns.say("Report saved. Type /reload so the game writes it to its file.")
  else
    help()
  end
end

---------------------------------------------------------------------------
-- Events
---------------------------------------------------------------------------
local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_LOGIN")
events:SetScript("OnEvent", function(self, event, arg1)
  if event == "ADDON_LOADED" and arg1 == ADDON then
    CombinedAddonMenusDB = type(CombinedAddonMenusDB) == "table" and CombinedAddonMenusDB or {}
    ns.db = CombinedAddonMenusDB
    ns.db.minimap = nil   -- 0.1.x stored its LibDBIcon gear icon here; replaced by the M button
    fill(ns.db, DEFAULTS)
    -- 0.2.3 made duplicate learning stricter. Matches learned by the older rules can be wrong,
    -- so they are cleared once.
    if (ns.db.effectsVersion or 1) < 2 then
      ns.db.effects = {}
      ns.db.effectsVersion = 2
    end
    local ok, err = pcall(ns.Options.register)
    if not ok then ns.say("The settings page could not be made: " .. tostring(err)) end
  elseif event == "PLAYER_LOGIN" then
    if not ns.db then
      ns.db = {}
      fill(ns.db, DEFAULTS)
    end
    local ok, err = pcall(ns.Button.update)
    if not ok then ns.say("The M button could not be made: " .. tostring(err)) end
    pcall(ns.Options.hookIcons)
    pcall(ns.Options.applyIconHiding)
    -- Some addons make their minimap icon a little after login.
    if C_Timer and C_Timer.After then
      C_Timer.After(3, function() pcall(ns.Options.hookIcons) pcall(ns.Options.applyIconHiding) end)
    end
  end
end)
