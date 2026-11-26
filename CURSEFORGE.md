# Combined Addon Menus

**One window for every addon menu you have.**

Some addons hide their options behind a slash command. Others put them on a minimap button, in the minimap dropdown, or deep in Options > AddOns. Combined Addon Menus finds all of them by itself and puts them in one list. Type `/cam` or click the small **menu** button. Each addon gets one button for each way to open it.

## Features

- **Finds menus automatically.** No setup and no list to keep up to date. It finds:
  - addon settings pages in Options > AddOns
  - minimap buttons (LibDataBroker launchers, and addons that make their own button)
  - minimap dropdown entries (the Addon Compartment)
  - slash commands, sorted under the addon that owns them
- **Every button works in one click.** Slash command buttons run the command for you. Right-click a button to get that addon's right-click action.
- **Takes you back to the list.** Close a settings page you opened from the list, and you return to the list, not the game menu. Press Esc in a window you opened from the list, and only that window closes.
- **No duplicate buttons.** If two buttons open the same thing, the addon notices the first time you use them and joins them into one button. The button shows every name, for example `Minimap = /ttwin`, and it tells you in chat when it does this. Shift-click a combined button to split it again, or type `/cam reset` to split all of them.
- **Clean up your minimap.** Other addons' minimap icons are hidden by default. Tick the ones you want to see on the settings page, or use Select all / Deselect all. You can still open those addons from the list.
- **Blacklist.** Hide addons you never want to see in the list.
- **14 skins.** Pick one from a numbered list on the settings page. A live preview shows each skin before you choose it. Every skin has its own look, not just its own colours.
  - **Classic:** the game's dialog look, with gold text
  - **Gnomish Workshop:** dark slate, brass edges, teal buttons
  - **Frostglass:** smoky icy blue glass
  - **Ocean Depths, Arctic Frost, Smoked Glass:** see-through glass in three moods
  - **Forest Canopy, Moss and Stone:** old-fashioned bordered frames in greens
  - **Sunset:** dusky plum with a coral glow that scrolls with the list
  - **Teal and Orange:** a clean panel with one orange bar
  - **Ledger:** cream bookkeeping paper with green ruled lines and a red margin
  - **Foundry:** a bolted iron plate lit from below
  - **Porcelain:** blue-and-white china
  - **Warpaint:** a rough orc banner
- **Small menu button.** Click it for a drop-down of your addons, in your chosen skin. Scroll it with the mouse wheel. Point at an addon to see its buttons. Ctrl-click it to open the big list. Right-click it to open the settings. Hold **Alt** and drag it to move it. You can hide it from the settings page.
- **Search box** to filter the list by addon name or button name.
- **Keybinding** under Key Bindings > AddOns.

## Commands

| Command | What it does |
|---|---|
| `/cam` | Opens or closes the list |
| `/cam settings` | Opens the settings page |
| `/cam button` | Shows or hides the menu button |
| `/cam reset` | Splits combined buttons into separate buttons again |
| `/cam debug` | Shows what the scan found in each place |

## Missing a menu?

Some addons open their menu in a way the scan can't see. You can add your own buttons, or hide ones you don't want, in `Extras.lua` inside the addon folder. The file has examples. Each button's tooltip shows the exact text needed to hide it.

## Good to know

- Made and tested on **WoW Forever**.
- Settings pages can't open during combat. This is a limit set by the game.
- Minimap buttons that another addon has gathered into its own bar are not found.

## Feedback

Found an addon whose menu doesn't show up? Please report it in the comments. Include the result of `/cam debug`.

## Patch notes

See what changed in each version: [Patch notes on GitHub](https://github.com/johndodge/CombinedAddonMenus/blob/main/CHANGELOG.md).
