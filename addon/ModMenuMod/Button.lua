-- Mod Menu Mod - the small square "M" button. It shows the logo of the current skin
-- (media\Logo_<skin>.tga, drawn by tools/make_icon.py).
-- Left-click: open or close the list. Right-click: open the settings page.
-- Hold Alt and drag to move it. The position is saved. The settings page can hide it.

local ADDON, ns = ...
local Button = {}
ns.Button = Button

local SIZE = 30
local btn

local function savePosition()
  local point, _, relPoint, x, y = btn:GetPoint(1)
  ns.db.button.pos = { point, relPoint, x, y }
end

local function place()
  btn:ClearAllPoints()
  local p = ns.db.button.pos
  if p then
    btn:SetPoint(p[1], UIParent, p[2], p[3], p[4])
  elseif Minimap then
    btn:SetPoint("TOPRIGHT", Minimap, "BOTTOMLEFT", 4, 4)
  else
    btn:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -220, -200)
  end
end

local function create()
  btn = CreateFrame("Button", "ModMenuModButton", UIParent)
  btn:SetSize(SIZE, SIZE)
  btn:SetFrameStrata("MEDIUM")
  btn:SetClampedToScreen(true)
  btn:SetMovable(true)
  btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  btn:RegisterForDrag("LeftButton")
  btn.logo = btn:CreateTexture(nil, "ARTWORK")
  btn.logo:SetAllPoints()
  -- Mouse-over: the same logo again, added on top, so it glows.
  btn.glow = btn:CreateTexture(nil, "HIGHLIGHT")
  btn.glow:SetAllPoints()
  btn.glow:SetBlendMode("ADD")
  btn.glow:SetAlpha(0.35)
  btn:SetScript("OnMouseDown", function(self) self.logo:SetPoint("TOPLEFT", 1, -1) self.logo:SetPoint("BOTTOMRIGHT", 1, -1) end)
  btn:SetScript("OnMouseUp", function(self) self.logo:SetAllPoints() end)

  btn:SetScript("OnDragStart", function(self)
    if IsAltKeyDown() then
      self.moving = true
      self:StartMoving()
    end
  end)
  btn:SetScript("OnDragStop", function(self)
    if self.moving then
      self.moving = false
      self:StopMovingOrSizing()
      savePosition()
      self.movedAt = GetTime and GetTime() or 0   -- the mouse-up after a drag must not count as a click
    end
  end)
  btn:SetScript("OnClick", function(self, mouseButton)
    if self.movedAt and GetTime and GetTime() - self.movedAt < 0.3 then return end
    if mouseButton == "RightButton" then
      ns.UI.openOptions()
    else
      ns.UI.toggle()
    end
  end)
  btn:HookScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:AddLine("Mod Menu Mod")
    GameTooltip:AddLine("Click: open the list of your addons.", 1, 1, 1)
    GameTooltip:AddLine("Right-click: settings.", 1, 1, 1)
    GameTooltip:AddLine("Alt + drag: move this button.", 1, 1, 1)
    GameTooltip:Show()
  end)
  btn:HookScript("OnLeave", function() GameTooltip:Hide() end)
  place()
end

function Button.logoPath(skinId)
  return "Interface\\AddOns\\ModMenuMod\\media\\Logo_" .. skinId
end

function Button.applySkin()
  if not btn then return end
  local _, id = ns.Skins.current()
  btn.logo:SetTexture(Button.logoPath(id))
  btn.glow:SetTexture(Button.logoPath(id))
end

function Button.update()
  if not ns.db then return end
  if ns.db.button.show then
    if not btn then create() end
    Button.applySkin()
    btn:Show()
  elseif btn then
    btn:Hide()
  end
end

function Button.setShown(on)
  ns.db.button.show = on and true or false
  Button.update()
end

function Button.resetPosition()
  ns.db.button.pos = nil
  if btn then place() end
end

function Button.frame() return btn end
