# Combined Addon Menus

A WoW Forever addon that opens one list of every installed addon, with a button for each way to open that addon's menu.

## Where things are

- `FINDINGS.md`: what the client supports, proved by in-game probes on 2026-11-20. Read it before changing the scan code.
- **The repo root IS the addon** (changed 2026-11-21 so CurseForge's automatic packaging finds the `.toc` in the root). `.pkgmeta` sets `package-as: CombinedAddonMenus` and ignores `CLAUDE.md`, `CURSEFORGE.md`, `FINDINGS.md`, `PLAN.md`, `tools`, `dist`. Anything new that must not ship goes in the `.pkgmeta` ignore list. Older notes below that say `addon/CombinedAddonMenus/` mean the repo root.
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

## Release process (user, 2026-11-21)

1. **While changing or testing:** every change or test build gets a commit and a version bump (0.3.x, `## Version:` in the `.toc`, plus a Status line below). Do not touch the CurseForge description or version history in this stage. Different tries are not release notes.
2. **When the user says testing passed and the change is fully understood:** push to GitHub, update `CURSEFORGE.md` (description if features changed), add an entry to the **Version history** at the bottom of `CURSEFORGE.md`, rebuild the zip with `python tools/build_zip.py` (forward-slash paths, honors `.pkgmeta`; never `Compress-Archive`), and commit. If CurseForge's GitHub webhook is set up, push a git tag `v<version>` (a tag containing `alpha` or `beta` makes that release type; any other tag is a release) after the user confirms.
3. Version history lists only what the user can see or feel, in plain words, for versions that passed testing. Never write a history entry for a build that is still being tried.
4. Ask the user if unsure whether testing has passed.

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

- 0.3.21 (2026-11-22): no code change. Test release to check CurseForge automatic packaging. Cause of the earlier no-file pushes: the CurseForge project had no Source (repository) set (log: "No Source information found for the project"). The user set it in the author console. The GitHub webhook (push event, project 1820321) was already right.
- 0.3.20 (2026-11-22): the "M button" is now called the "menu button" in all player text (help line, chat messages, settings page, tooltip, CurseForge description) because the new picture is not an M. The saved setting `button` keeps its name so positions are kept. Pushed with the tag `v0.3.20-beta`.
- 0.3.19 (2026-11-22): new picture for the addon icon (`Icon.tga`, 64x64) and the M button (all six `Logo_*.tga`, 128x128), made from `Pictures/Untitled.png` (80x82, padded to square). `tools/make_icon.py` still makes the old gold M; do not rerun it or it overwrites these files. Sent to GitHub with the tag `v0.3.19-beta` (a beta release, like v0.3.18-beta) so CurseForge can pick it up.
- 0.3.4: CAUSE FOUND from the 0.3.3 chat line "Slash: 0 addon commands via proxy table, 97 game commands skipped" (first list after /reload): the table behind the SlashCmdList proxy had only the game's ~97 commands; the addons' commands were not there yet (guess: still in the proxy itself). `slashEntries()` in Scan.lua now reads both the proxy and the table behind it; the debug note says how many came from the proxy itself. Mock test added. Not yet confirmed in game.
- 0.3.3: user log (2026-11-21 07:06) shows the FIRST list after each /reload has 0 slash buttons (36 rows, 58 buttons) while `/cam debug` in the same session finds 92 and the second open shows 90. Not timing (the 1.5 s rescan also had 0). Cause unknown. The list now prints and saves (`db.view.notes`, `db.viewRetry`) what the scan said about slash commands when it finds none.
- 0.3.2 (user report: buttons missing until `/cam debug` was typed; cause NOT found, the scan has no state between runs): the list scans again 1.5 s after it opens; `UI.refresh` saves `db.view` (rows, buttons, slash) and `db.late` (first vs second count) for `/cam debug`; layout errors are printed. If `db.late` ever shows up, the data is late.
- 0.3.18: with 0.3.17 Esc closed X-Perl but its move-me preview frames (party, raid) stayed, because Esc is a plain Hide and X-Perl cleans up in its Close button. General fix in UI.lua (`hookCloseButton`): when Esc hides a lent window, that window's own Close button OnClick runs once (next frame); skipped if the Close button itself closed it (PreClick flag). Looks for `f.CloseButton`, `<name>_CloseButton`, `<name>CloseButton`. Not yet confirmed in game.
- 0.3.17: user wanted Esc to close X-Perl's window, not the list. A window one level below UIParent is lent to Esc only if large (>= 350x250, `isLargeWindow` in UI.lua); the burst guard (more than 3 new frames) applies to small frames only. General rule, no addon names. Mock test with options window plus 6 preview bars. Not yet confirmed in game.
- 0.3.16: removed the X-Perl-only NO_LEND line (user did not want mod-specific code). X-Perl's options window (child of XPerl_OptionsAnchor) is not lent to Esc, so Esc closes the list first; accepted.
- 0.3.15 (ROOT CAUSE, found by an Opus review + `/cam nowatch` test; earlier 0.3.12-0.3.14 theories were wrong): the 0.3.10 deeper `topWindows` scan made X-Perl's preview child frames (target health/mana bars, boss, arena, party placeholders) look like new windows after the click, and `lendEsc` wrote them into UISpecialFrames; Esc then hid them and the game menu did not open. Fix: `lendEsc` lends only direct UIParent children that are not shared frames, and `look()` lends nothing if more than 3 new frames appear from one click. Mock test added (fails on old code). Not yet confirmed in game.
- 0.3.14 (superseded; user: via the list X-Perl opens, then Esc does NOT open the game menu and frames lose health/mana; X-Perl opened normally is fine): `table.remove(UISpecialFrames, i)` moved the entries after ours, tainting other addons' windows for the game's Esc code. UISpecialFrames entries are now never removed or moved: a slot is switched to the name `CombinedAddonMenusNoEsc` and reused (`claimSlot`/`freeSlots` in UI.lua). Mock test fails with the old code (index 4 -> 3). Guess at the cause, not confirmed in game. NO_LEND for X-Perl stays until this is confirmed.
- 0.3.13 (user: still broken after 0.3.12; only when X-Perl is closed with Esc, fine with its X; sometimes target and target-of-target): X-Perl's window is no longer lent to Esc (`NO_LEND` in UI.lua). The list steps aside while it is open, so Esc does nothing until the user clicks its X. Guess for the real cause: Esc closing went through UISpecialFrames, which we had written to, so the close ran tainted. Not proven.
- 0.3.12 (superseded by 0.3.13; user report: X-Perl target-of-target showed the name but no health/mana after leaving X-Perl settings): Esc hid `XPerl_Options` (lent to UISpecialFrames) without XPerl_LockFrames(), which its Close button calls and which resets the unit frames. `CLOSERS` in UI.lua runs XPerl_LockFrames after Esc hides it (OnHide hook on lent windows, only if XPerlLocked == 0). Guess, from reading X-Perl code; not confirmed in game. Mock test added.
- 0.3.11 (user error, XPerl click): the 0.3.10 deeper scan met frames whose IsShown answers with a SECRET boolean ("attempt to perform boolean test on local shown ... secret boolean value"). `secret()` in UI.lua skips secret answers (IsShown, IsForbidden, IsProtected, name, size). The watcher now runs inside pcall (`safeLook`) and tells the user once if it fails. Mock test added.
- 0.3.10 (user): text shadows are off in every skin. X-Perl: its options window (`XPerl_Options`) is parented to `XPerl_OptionsAnchor`, not UIParent, so `topWindows` never saw it and Esc closed the list. `topWindows` now also looks one level below each UIParent child. Mock test added (fails without the fix). Not yet confirmed in game.
- 0.3.9: Parchment still looked blurry (user screenshot): the game's default text shadow smudges dark text on light paper. `skin.noShadow` turns the shadow off (Skins.setFont sets it for every skin).
- 0.3.8: Frostglass more opaque and darker (frame alpha 0.3 -> 0.58); Parchment uses Friz Quadrata (Morpheus looked blurry); the combined-button joiner is back to " = ".
- 0.3.1 (user request): buttons that open the same thing are now ONE button, labelled with all names ("Minimap = /ttwin"; `action.display`). The joiner is " = ": tried and dropped were "||" (low in the game font), "-" (too small) and an em dash. Tooltip lists them; Shift-click splits them. Long labels are cut to the row width.
88`; a pipe looked low in the game font, a hyphen too small). Tooltip lists them; Shift-click splits them. Long labels are cut to the row width.
- 0.3.0: renamed (user request). Folder `CombinedAddonMenus`, saved variable `CombinedAddonMenusDB` (old settings were not carried over), command `/cam`. The project folder on disk is still named `ModMenuMod`. The junction `D:\World of Warcraft\_forever_\Interface\AddOns\CombinedAddonMenus` now points to `addon\CombinedAddonMenus` (user approved 2026-11-21). Git repo (`main`) pushed to the private GitHub repo `johndodge/CombinedAddonMenus`.

- Version 0.3.18. `tools/smoke_test.py` passes against the mock.
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
- **Linked into the game** (user approved 2026-11-20): `D:\World of Warcraft\_forever_\Interface\AddOns\CombinedAddonMenus` is a junction to the project root `C:\Users\paint\claudeprojects\Games\WorldOfWarcraftMods\ModMenuMod` (re-pointed 2026-11-21 with the user's approval; the game also sees the non-addon files, which it ignores). Anything else under `D:\World of Warcraft\` still needs a new ask. To unlink, use `cmd /c rmdir "<link>"` with no `/s`. NEVER use PowerShell `rmdir` or `Remove-Item -Recurse` on a junction.
- Not built: loose minimap buttons that don't use LibDataBroker (MinimapButtonButton already gathers those).
