# Combined Addon Menus

**One window for every addon menu you have.**

Some addons hide their options behind a slash command. Others put them on a minimap button, in the minimap dropdown, or deep in Options > AddOns. Combined Addon Menus finds all of them by itself and puts them in one list. Type `/cam` or click the small **menu** button. Each addon gets one button for each way to open it.

## Features

- **Finds menus automatically.** No setup and no list to keep up to date. It finds:
  - addon settings pages in Options > AddOns
  - minimap buttons (LibDataBroker launchers)
  - minimap dropdown entries (the Addon Compartment)
  - slash commands, sorted under the addon that owns them
- **Every button works in one click.** Slash command buttons run the command for you. Right-click a button to get that addon's right-click action.
- **Takes you back to the list.** Close a settings page you opened from the list, and you return to the list, not the game menu. Press Esc in a window you opened from the list, and only that window closes.
- **No duplicate buttons.** If two buttons open the same thing, the addon notices the first time you use them and joins them into one button. The button shows every name, for example `Minimap = /ttwin`, and it tells you in chat when it does this. Shift-click a combined button to split it again, or type `/cam reset` to split all of them.
- **Clean up your minimap.** Hide other addons' minimap icons (any addon that uses LibDBIcon) from the settings page. You can still open those addons from the list.
- **Blacklist.** Hide addons you never want to see in the list.
- **Six skins.** Each skin has its own logo. A live preview on the settings page shows each skin before you pick it.
  - **Classic:** the game's dialog look, with gold text
  - **Gnomish Workshop:** dark slate, brass edges, teal buttons
  - **Midnight:** flat black with violet lines
  - **Parchment:** light paper, dark ink, the game's sharp serif font
  - **Fel Terminal:** black screen with neon green text
  - **Frostglass:** smoky icy blue glass
- **Small menu button.** Click it to open the list. Right-click it to open the settings. Hold **Alt** and drag it to move it. You can hide it from the settings page.
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
- Minimap buttons that don't use LibDataBroker are not found.

## Feedback

Found an addon whose menu doesn't show up? Please report it in the comments. Include the result of `/cam debug`.

## Version history

**0.3.19**
- New icon for the addon list and the M button. Every skin uses it.

**0.3.18**
- Press Esc in a window you opened from the list and that window now closes, with its own Close step. For example, X-Perl's options window closes and its move-me frames go away.
- Fixed a bug where Esc could hide health and mana on other addons' unit frames, and could stop the game menu opening.
- Esc never hides small preview frames that an addon shows when you open its menu.

**0.3.11**
- Fixed an error ("secret boolean value") when opening some addons' windows.

**0.3.8 - 0.3.10**
- Frostglass skin is darker and less see-through.
- Parchment skin text is sharper.
- Text shadows are off in every skin.
- Esc now finds windows that sit under another frame (such as X-Perl's options).

**0.3.4**
- Fixed slash command buttons missing on the first open after a reload.

**0.3.1**
- Buttons that open the same thing are joined into one button that shows every name, for example `Minimap = /ttwin`. Shift-click splits them.

**0.3.0**
- Renamed to Combined Addon Menus. The command is now `/cam`.

