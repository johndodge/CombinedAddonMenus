# Mod Menu Mod

**One window for every addon menu you have.**

Some addons hide their options behind a slash command. Others put them on a minimap button, in the minimap dropdown, or deep in Options > AddOns. Mod Menu Mod finds all of them by itself and puts them in one list. Type `/mmm` or click the small **M** button. Each addon gets one button for each way to open it.

## Features

- **Finds menus automatically.** No setup and no list to keep up to date. It finds:
  - addon settings pages in Options > AddOns
  - minimap buttons (LibDataBroker launchers)
  - minimap dropdown entries (the Addon Compartment)
  - slash commands, sorted under the addon that owns them
- **Every button works in one click.** Slash command buttons run the command for you. Right-click a button to get that addon's right-click action.
- **Takes you back to the list.** Close a settings page you opened from the list, and you return to the list, not the game menu. Press Esc in a window you opened from the list, and only that window closes.
- **No duplicate buttons.** If two buttons open the same thing, the addon notices the first time you use them and keeps just one. It tells you in chat when it hides a button. Shift-click the button that stayed to bring the hidden ones back, or type `/mmm reset` to bring back all of them.
- **Clean up your minimap.** Hide other addons' minimap icons (any addon that uses LibDBIcon) from the settings page. You can still open those addons from the list.
- **Blacklist.** Hide addons you never want to see in the list.
- **Six skins.** Each skin has its own logo. A live preview on the settings page shows each skin before you pick it.
  - **Classic:** the game's dialog look, with gold text
  - **Gnomish Workshop:** dark slate, brass edges, teal buttons
  - **Midnight:** flat black with violet lines
  - **Parchment:** light paper, dark ink, quest-book font
  - **Fel Terminal:** black screen with neon green text
  - **Frostglass:** see-through icy blue glass
- **Small M button.** Click it to open the list. Right-click it to open the settings. Hold **Alt** and drag it to move it. You can hide it from the settings page.
- **Search box** to filter the list by addon name or button name.
- **Keybinding** under Key Bindings > AddOns.

## Commands

| Command | What it does |
|---|---|
| `/mmm` | Opens or closes the list |
| `/mmm settings` | Opens the settings page |
| `/mmm button` | Shows or hides the M button |
| `/mmm reset` | Shows buttons that were hidden as duplicates again |
| `/mmm debug` | Shows what the scan found in each place |

## Missing a menu?

Some addons open their menu in a way the scan can't see. You can add your own buttons, or hide ones you don't want, in `Extras.lua` inside the addon folder. The file has examples. Each button's tooltip shows the exact text needed to hide it.

## Good to know

- Made and tested on **WoW Forever**.
- Settings pages can't open during combat. This is a limit set by the game.
- Minimap buttons that don't use LibDataBroker are not found.

## Feedback

Found an addon whose menu doesn't show up? Please report it in the comments. Include the result of `/mmm debug`.
