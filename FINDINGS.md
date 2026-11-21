# Mod Menu Mod: feasibility findings (2026-11-20)

Goal: one place in game that opens the menu of every other installed addon.

## Checked (read the addon files in D:\World of Warcraft\_forever_\Interface\AddOns, read-only)

- ~120 addon folders installed. Most common `## Interface:` is 16001 (WoW Forever).
- Ways the installed addons expose a menu, and how many use each:
  - Settings page under ESC > Options > AddOns (`Settings.RegisterCanvasLayoutCategory` / `RegisterAddOnCategory`): 32 addons. Old style `InterfaceOptions_AddCategory`: 10.
  - Minimap launcher via LibDataBroker (`NewDataObject`): 22 addons.
  - Addon Compartment (minimap dropdown), `AddonCompartmentFunc` in the .toc: 13 addons; 19 touch `AddonCompartmentFrame` in Lua.
  - Slash commands (`SLASH_xxx1`): 37 addons.
  - ESC (Game Menu) buttons: none found. Only GearQuestForever and Plater mention `GameMenuFrame`, and neither adds a button.
- ForeverCore guards `Settings.RegisterCanvasLayoutCategory` with an existence check, so the API may be missing on some clients.
- MinimapButtonButton (installed) already collects loose minimap buttons by scanning Minimap children: prior art.

## Planned discovery sources (all readable at run time)

1. Settings panel categories -> open with `Settings.OpenToCategory`.
2. `AddonCompartmentFrame.registeredAddons` and .toc `AddonCompartmentFunc`.
3. `LibStub("LibDataBroker-1.1"):DataObjectIterator()` -> call the object's `OnClick`.
4. `SlashCmdList` + `SLASH_*` globals; owner addon from `issecurevariable(SlashCmdList, key)`.
5. Loose minimap buttons (scan `Minimap` children).
6. Hand-written override list for anything the above misses.

## Checked in game (user ran a probe, 2026-11-20)

- `AddonCompartmentFrame`, `Settings.OpenToCategory`, LibDataBroker-1.1 via `LibStub`, and `issecurevariable` all exist on the client.
- The client UI uses `Blizzard_ChatFrameBase` (modern retail-style code), seen in an error stack.
- The chat box cuts `/run` lines at 255 characters. Keep probe commands shorter.

- `SlashCmdList` is a proxy: `pairs(SlashCmdList)` returns nothing. `getmetatable(SlashCmdList).__index` is the real table, and `SlashCmdList.DUMP` still resolves.
  - Real table: 193 entries. `issecurevariable(realTable, key)` names an addon for 92 of them (example: Bartender4). The rest are the game's own commands.
  - `_G` holds 1139 `SLASH_*` strings (fallback for the command words: `SLASH_<KEY>1`, `SLASH_<KEY>2`, ...).
  - LoreForever/Core.lua:348 still does `pairs(SlashCmdList)`, so on this client its rival-command check finds nothing. Not our problem; note only.

## Conclusion (2026-11-20)

Fully automatic discovery is possible for all four sources: Settings pages, LibDataBroker minimap launchers, the Addon Compartment, and slash commands (owner known). A hand-written override list covers gaps.

## Not tested yet

- Whether `Settings.OpenToCategory` opens addon pages from addon code on this client.
- Whether running an addon's slash command with no arguments opens its menu (varies by addon).
- Whether `Settings.OpenToCategory` opens addon pages from addon code on this client.
