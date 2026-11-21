-- Mod Menu Mod - your own entries.
-- This is the only file meant for hand edits. The scan finds most menus by itself.
-- Use this file for menus the scan misses, and to hide buttons you don't want.

local ADDON, ns = ...

-- Extra buttons. Each line adds one button to an addon's row.
--   addon = the addon's folder name (as in Interface\AddOns), or any text for a row of its own.
--   label = the button text.
--   slash = a slash command to run, with any words after it.
--   run   = a Lua function to run instead of a slash command.
-- Examples (remove the two dashes at the start of a line to use it):
--   { addon = "Bagnon", label = "Bank", slash = "/bgn bank" },
--   { addon = "Bagnon", label = "Bags", run = function() Bagnon.Frames:Toggle("inventory") end },
ns.Extras = {
}

-- Buttons to hide. Hover over a button in the list: the last line of its tooltip
-- shows the text to put here. Example:
--   ["DBM-Core /dbm-pull"] = true,
ns.Hide = {
}
