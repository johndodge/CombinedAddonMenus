# Combined Addon Menus

A WoW Forever addon that opens one list of every installed addon, with a button for each way to open that addon's menu.

## Where things are

- `FINDINGS.md`: what the client supports, proved by in-game probes on 2026-11-20. Read it before changing the scan code.
- `addon/CombinedAddonMenus/`: the addon itself.
  - `CombinedAddonMenus.toc`: `## Interface: 16001, 120105, 120107` (same as Sprocket Speak).
  - `Scan.lua`: finds the menus. Four sources: Settings pages, Addon Compartment (minimap dropdown), LibDataBroker launchers (minimap buttons), slash commands.
  - `Skins.lua`: six skins (Classic, Gnomish Workshop, Midnight, Parchment, Fel Terminal, Frostglass) and the paint helpers.
  - `UI.lua`: the list window (custom BackdropTemplate frame, painted by the skin).
  - `Button.lua`: the small square "M" button. Click = list, right-click = settings page, Alt+drag = move.
  - `Options.lua`: the settings page (ESC > Options > AddOns > Combined Addon Menus): skin, M button, other addons' minimap icons, blacklist.
  - `Core.lua`: `/cam` (user dropped `/mods` 2026-11-20 as too generic), keybinding, saved settings defaults, start-up.
  - `media/Icon.tga`: 64x64 gold "M" icon, made by `tools/make_icon.py`.
  - `Extras.lua`: the user's own hand-made entries and hide list. The only file meant for hand edits per user.
  - `Bindings.xml`: one keybinding under Key Bindings > AddOns.
- `PLAN.md`: the 0.2.0 plan (fixes, skins, M button, settings page).
- `tools/smoke_test.py`: runs the addon in Lua 5.1 (lupa) against a small mock of the game. Needs a venv with `lupa` (`python -m venv X; X/Scripts/python -m pip install lupa`).
- WoW Forever is at `D:\World of Warcraft\_forever_`. Don't create or change anything under `D:\World of Warcraft\` without asking.

## Decisions (user, 2026-11-20)

- Published on CurseForge under the **MIT** license, author **Tieme** (`addon/CombinedAddonMenus/LICENSE.txt`, `## Author` in the .toc). Third-party access allowed was recommended. Description text: `CURSEFORGE.md`.

- Name: **Combined Addon Menus** (folder `CombinedAddonMenus`).
- Automatic scan plus a small hand-made list for gaps.
- Slash command buttons **run the command at once** (option B). If that causes problems, switch to option A: put the command in the chat box for the user to send.

## Client facts that shape the code (see FINDINGS.md)

- `SlashCmdList` is a proxy. Iterate `getmetatable(SlashCmdList).__index`, not `SlashCmdList`.
- `issecurevariable(realTable, key)` gives the owning addon for addon slash commands. Ace3 addons share one AceConsole copy, so `ACECONSOLE_*` keys are matched by name first.
- The chat box cuts `/run` lines at 255 characters.
- Settings pages: owner = name match, else the stack owner for pages registered after load, else `issecurevariable(category, "name")` (the addon whose code made the page). The taint method is a guess until tested in game. `/cam debug` prints what each source found and saves it to `WTF\Account\TIEME\SavedVariables\CombinedAddonMenus.lua` (written on `/reload`), because the user can't copy text out of the chat window.

## Status (2026-11-21)

- 0.3.0: renamed from Mod Menu Mod (user request, "Everything"). Folder `CombinedAddonMenus`, saved variable `CombinedAddonMenusDB` (copied once from the old `ModMenuModDB`), command `/cam` (`/mmm` still works). The project folder itself is still named `ModMenuMod`. The junction `D:\World of Warcraft\_forever_\Interface\AddOns\CombinedAddonMenus` now points to `addon\CombinedAddonMenus` (user approved 2026-11-21; the old `ModMenuMod` link was removed). Git repo (`main`) pushed to the private GitHub repo `johndodge/CombinedAddonMenus`.

- Version 0.2.3. `tools/smoke_test.py` passes against the mock.
- 0.2.3 (user report: buttons hidden as duplicates when they did different things, often slash commands that show nothing or need a value): duplicate learning is stricter.
  - Shared windows never count (`SHARED` in UI.lua: StaticPopup, ScriptErrors, BugSack, alerts, toasts, zone text, unit frames...). Guess at the cause: two failing slash commands both showed the same popup.
  - Top-level windows must be at least 120x60. The decision is made once, at the last look (0.3 s), from windows still open; if more than one different window opened, nothing is learned.
  - Tooltip says what a button opens. Shift-click a kept button to forget its row's matches (`UI.forgetRow`). The chat message names what both buttons open.
  - Saved matches from older versions are cleared once (`CombinedAddonMenusDB.effectsVersion = 2`).
- Scrap's Dropdown error is confirmed as Scrap's bug: the user's stack starts in the game's own dropdown (`Blizzard_Menu`). Sushi `Group.GetCategory` calls `DoesAncestryInclude` with Scrap's Options class table (not a frame). Upload zip: `dist/CombinedAddonMenus-<version>.zip` (one `CombinedAddonMenus/` folder).
- 0.2.2 (user report): a window with no Esc support opened from the list (TomTom Paste) is lent to `UISpecialFrames` while open (never protected frames), so Esc closes it before the list; the name is removed when it closes.
- Scrap's Dropdown entry errors in `frameutil.lua:200` (GetParent, wrong object type). Its func ignores our arguments and calls Sushi-3.2 `Group:Open()` -> `Group.GetCategory` -> `DoesAncestryInclude`. Guess: a Scrap/Sushi bug on this client, not ours. Not confirmed with the game's own dropdown entry yet.
- User test of 0.2.0 (2026-11-20): M button, list and settings page work; skins "look good". Two in-game errors fixed: FontString:SetText "Font not set" (every font string now gets `GameFontNormal` at creation) and IsShown on a forbidden frame (CommunitiesAddDialog) while diffing UIParent children (`isShownFrame` now checks `IsForbidden` and uses pcall).
- 0.2.1 (user request):
  - Settings pages with a text ID (ForeverDungeonJournal sets `category.ID = "DungeonJournal"`) failed: `Settings.OpenToCategory` only takes numbers on this client ("outside of expected range"). `Scan.openCategory` falls back to `SettingsPanel:Open()` + `SettingsPanel:SelectCategory(cat)`. The fallback is not yet tested in game.
  - Chat says when a button is newly hidden as a duplicate (user saw Atlas Minimap/Dropdown vanish and couldn't tell if it was a bug).
  - Logo per skin (`media/Logo_<skin>.tga`, 128x128, `tools/make_icon.py`); the M button shows it (30x30). `Icon.tga` = Classic logo.
  - Settings page: live preview of the list window in the skin; pointing at a skin previews it, clicking applies it.
- 0.2.0 (user request, see PLAN.md):
  - A LibDataBroker launcher is "Minimap" only if LibDBIcon has a visible icon for it. Otherwise it is a "Launcher" button with a short name (TomTom-Paste -> "Paste"). Cause of the user's report: TomTom registers a Paste icon but hides it.
  - Learning what a button opens now also watches named top-level windows (children of UIParent), so windows Esc can't close (TomTom's Paste window) are found. Only left-clicks teach.
  - Skins, the M button (replaces the 0.1.x LibDBIcon gear icon; `CombinedAddonMenusDB.minimap` is deleted at load), the settings page, hiding other addons' minimap icons (`CombinedAddonMenusDB.hiddenIcons`, re-hidden when the addon shows them), blacklist (`CombinedAddonMenusDB.blacklist`, by row key).
  - Saved settings: `skin`, `button = {show, pos}`, `hiddenIcons`, `blacklist`, `effects`, `pos` (list window), `debug`.
  - `/cam settings` opens the settings page. `/cam button` shows or hides the M button.
- User test of 0.1.3 (2026-11-20): settings return and Esc step-aside "seem to work".
- 0.1.4 (user request):
  - Any button that opens the settings window (e.g. `/tomtom`) gets the settings return path, not only Settings buttons. All button clicks go through `UI.runAction`.
  - Ace3 option windows (`AceConfigDialog-3.0.OpenFrames`) count as Esc windows.
  - Button order: Settings, Minimap, Dropdown, slash, extras (user choice).
  - Duplicates: the addon learns what each button opens (`CombinedAddonMenusDB.effects`: action id -> `settings:<top page id>` / `window:<frame name>` / `ace:<app>`). A later button with the same effect is hidden; the kept button's tooltip says "Same as: ...". It needs one click per button to learn; there is no way to know without running it. `/cam reset` forgets.
- 0.1.3 (user request): after a non-Settings button, if a new window appears in `UISpecialFrames` or `GetUIPanel(...)`, the list leaves `UISpecialFrames` until that window closes (checked every 0.2 s). So Esc closes the other window first, then the list. Windows that handle Esc themselves are not detected. Not yet tested in game.
- User test of 0.1.1 (2026-11-20): "looks pretty good, stuff seems to work."
- 0.1.2: a Settings button hides the list; when the settings window closes, the addon hides the game's ESC menu (`HideUIPanel(GameMenuFrame)`, one frame later) and shows the list again. Only when the settings window was opened from the list. Not yet tested in game.
- First in-game scan (0.1.0, 2026-11-20): 22 addon settings pages (via `SettingsPanel:GetAllCategories`, 22 game pages skipped), 11 .toc dropdown entries, 22 minimap launchers, 5 runtime dropdown entries, 92 addon slash commands. 45 rows.
  - Bug found and fixed in 0.1.1: Ace3 short commands (`/bt`, `/bt4`, `/dcr`, `/spq`) landed under Atlas (the AceConsole host). Now matched by abbreviation. Slash buttons now sort best fit first.
  - Bartender4 shows no Settings button. Cause not checked.
- **Linked into the game** (user approved 2026-11-20): `D:\World of Warcraft\_forever_\Interface\AddOns\CombinedAddonMenus` is a junction to `addon\CombinedAddonMenus`. Anything else under `D:\World of Warcraft\` still needs a new ask. To unlink, use `cmd /c rmdir "<link>"` with no `/s`. NEVER use PowerShell `rmdir` or `Remove-Item -Recurse` on a junction.
- Not built: loose minimap buttons that don't use LibDataBroker (MinimapButtonButton already gathers those).
