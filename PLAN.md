# Combined Addon Menus - plan for version 0.2.0 (2026-11-20)

The user asked for two fixes and five features. Each item: what, how, test, done when.

## 1. Fix: "Minimap" button for an icon that isn't on the minimap

- **What:** TomTom shows `Minimap`, but no TomTom icon is on the minimap.
- **Cause (checked):** TomTom's `TomTom-Paste` launcher is registered with LibDBIcon, but TomTom keeps that icon hidden (its own `db.hide`).
- **How:** Call a launcher `Minimap` only when its LibDBIcon icon exists and its addon has not hidden it. Every other launcher gets the kind `launcher` and a short name, such as `Paste`.
- **Test:** Smoke test with a hidden-by-addon icon.
- **Done when:** TomTom's row shows `Paste`, not `Minimap`.

## 2. Fix: duplicates not caught (TomTom `Paste` and `/ttpaste`)

- **What:** Both open the TomTom Paste window, but both stay listed.
- **Cause (checked):** That window is not in the game's Esc list, so the addon did not see it open.
- **How:** On a left click, compare the named, shown top-level windows (children of `UIParent`) before and after. A new one becomes the button's effect. Ignore tooltips and dropdown lists.
- **Test:** Smoke test: launcher and slash command open the same non-Esc window.
- **Done when:** After one click on each, only the first button shows.

## 3. Own button: small, square, "M"

- **What:** A small square button with a capital M. Left-click opens the list. Right-click opens the settings page. Hold Alt and drag to move it.
- **How:** `Button.lua`. A 26x26 frame drawn in the current skin. The position is saved. It replaces the gear minimap icon (no LibDBIcon icon for this addon any more). Also a 64x64 `media\Icon.tga` (an M) for the minimap dropdown and the AddOns list.
- **Test:** Smoke test: click, right-click, Alt-drag saves a position, hide/show.
- **Done when:** The button works in game and remembers its place after `/reload`.

## 4. Settings page (ESC > Options > AddOns > Combined Addon Menus)

- **What:** One page with four sections:
  1. Skin: one button per skin, each drawn in its own skin as a preview.
  2. The M button: show or hide it, and reset its position.
  3. Minimap icons of other addons: a tick box per icon. Untick to hide it from the minimap. You still reach it through Combined Addon Menus.
  4. Blacklist: a tick box per addon in the list. Tick to hide that addon from Combined Addon Menus.
- **How:** `Options.lua`, a canvas page registered with `Settings.RegisterCanvasLayoutCategory`. Hidden icons are saved by this addon and applied at login with `LibDBIcon:Hide`. A hook re-hides an icon if its addon shows it again. A `Settings` button in the list window opens this page (with the same return path as other settings pages).
- **Test:** Smoke test for each section's saved value and its effect.
- **Done when:** Each setting works in game and survives `/reload`.

## 5. Skins (6)

- **What:** Six looks for the list window and the M button. Each one is clearly different:
  1. **Classic**: Blizzard dialog border, dark background, gold text.
  2. **Gnomish Workshop**: dark slate, brass edges, teal buttons.
  3. **Midnight**: flat near-black, thin violet lines, white text.
  4. **Parchment**: light paper, dark ink, quest-book font. The only light skin.
  5. **Fel Terminal**: black screen, neon green text, like an old computer.
  6. **Frostglass**: see-through icy blue glass, white text.
- **How:** `Skins.lua` holds each skin as data (backdrop, colors, font). The list window is rebuilt with plain frames, so a skin can color every part. Fonts that fail to load fall back to the default font.
- **Test:** Smoke test switches through all skins without errors.
- **Done when:** The user has tried the skins in game.

## Order of work

Fixes 1 and 2, then skins (the window must be rebuilt for them), then the M button, then the settings page. Run the smoke test after each.
