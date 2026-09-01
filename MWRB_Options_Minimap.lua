-- ===================================================================
-- MWRB_Options_Minimap.lua
-- Minimap button integration (using LibDBIcon if available)
-- ===================================================================

-- Class check - Exit if not Shaman
local _, playerClass = UnitClass("player")
if playerClass ~= "SHAMAN" then return end

local ADDON, ns = ...
ns.Options = ns.Options or {}

-- Use global DB for minimap settings (should persist across profiles)
local function GetMinimapDB()
  return ns.API.GetGlobalDB()
end

-- ===================================================================
-- MINIMAP BUTTON INITIALIZATION
-- ===================================================================
function ns.Options.InitMinimapButton()
  local db = GetMinimapDB()
  
  -- Initialize minimap settings if they don't exist
  if not db.minimap then
    db.minimap = {
      x = 40,
      y = -40,
      locked = false,
      show = true
    }
  end
  
  -- Try to use LibDBIcon (LibDataBroker + Icon library)
  local LibDBIcon = LibStub("LibDBIcon-1.0", true)
  local LDB = LibStub("LibDataBroker-1.1", true)
  
  if not (LibDBIcon and LDB) then
    -- Fallback: Create simple minimap button without library
    ns.Options.CreateSimpleMinimapButton()
    return
  end
  
  -- Create LibDataBroker data source
  local dataObj = LDB:NewDataObject("MWRB", {
    type = "launcher",
    icon = "Interface\\Icons\\Spell_Shaman_MaelstromWeapon",
    label = "MWRB",
    text = "MWRB",
    OnClick = function(self, button)
      if button == "LeftButton" then
        -- Open options
        if ns.API.OpenOptions then
          ns.API.OpenOptions()
        end
      elseif button == "RightButton" then
        -- Quick toggle display
        local profileDB = ns.API.GetDB()
        if profileDB then
          profileDB.showStackText = not profileDB.showStackText
          if ns.API.SetStackTextEnabled then
            ns.API.SetStackTextEnabled(profileDB.showStackText)
          end
          -- Only print if debug is enabled
          if profileDB.debug then
            print("|cff00ccffMWRB|r Stack text " .. (profileDB.showStackText and "shown" or "hidden"))
          end
        end
      end
    end,
    OnTooltipShow = function(tooltip)
      tooltip:SetText("Maelstrom Weapon Resource Bar")
      tooltip:AddLine(" ")
      tooltip:AddLine("|cffFFFFFFLeft-click|r to open options")
      tooltip:AddLine("|cffFFFFFFRight-click|r to toggle stack text")
      tooltip:AddLine("|cffFFFFFF/mwrb|r for commands")
    end
  })
  
  -- Register with LibDBIcon
  LibDBIcon:Register("MWRB", dataObj, db.minimap)
  
  -- Show/hide based on settings
  if db.minimap.show then
    LibDBIcon:Show("MWRB")
  else
    LibDBIcon:Hide("MWRB")
  end
end

-- ===================================================================
-- SIMPLE MINIMAP BUTTON (Fallback without libraries)
-- ===================================================================
function ns.Options.CreateSimpleMinimapButton()
  local db = GetMinimapDB()
  
  if not db.minimap.show then return end
  
  -- Create a basic minimap button frame
  local button = CreateFrame("Button", "MWRB_MinimapButton", Minimap)
  button:SetSize(32, 32)
  button:SetFrameStrata("MEDIUM")
  button:SetFrameLevel(8)
  
  -- Position button
  button:SetPoint("TOPLEFT", Minimap, "TOPLEFT", db.minimap.x, db.minimap.y)
  
  -- Button icon
  local icon = button:CreateTexture(nil, "BACKGROUND")
  icon:SetSize(20, 20)
  icon:SetPoint("CENTER", 0, 0)
  icon:SetTexture("Interface\\Icons\\Spell_Shaman_MaelstromWeapon")
  
  -- Border
  local border = button:CreateTexture(nil, "OVERLAY")
  border:SetSize(52, 52)
  border:SetPoint("TOPLEFT", 0, 0)
  border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
  
  -- Make draggable
  button:SetMovable(true)
  button:EnableMouse(true)
  button:RegisterForDrag("LeftButton")
  button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  
  button:SetScript("OnDragStart", function(self)
    if not db.minimap.locked then
      self:StartMoving()
    end
  end)
  
  button:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local x, y = self:GetCenter()
    local mmx, mmy = Minimap:GetCenter()
    db.minimap.x = x - mmx
    db.minimap.y = y - mmy
  end)
  
  button:SetScript("OnClick", function(self, btn)
    if btn == "LeftButton" then
      if ns.API.OpenOptions then
        ns.API.OpenOptions()
      end
    elseif btn == "RightButton" then
      local profileDB = ns.API.GetDB()
      if profileDB then
        profileDB.showStackText = not profileDB.showStackText
        if ns.API.SetStackTextEnabled then
          ns.API.SetStackTextEnabled(profileDB.showStackText)
        end
        -- Only print if debug is enabled
        if profileDB.debug then
          print("|cff00ccffMWRB|r Stack text " .. (profileDB.showStackText and "shown" or "hidden"))
        end
      end
    end
  end)
  
  button:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:SetText("Maelstrom Weapon Resource Bar")
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("|cffFFFFFFLeft-click|r to open options", 1, 1, 1)
    GameTooltip:AddLine("|cffFFFFFFRight-click|r to toggle stack text", 1, 1, 1)
    GameTooltip:AddLine("|cffFFFFFF/mwrb|r for commands", 1, 1, 1)
    GameTooltip:Show()
  end)
  
  button:SetScript("OnLeave", function(self)
    GameTooltip:Hide()
  end)
  
  -- Store reference
  ns.Options.minimapButton = button
end

-- ===================================================================
-- END OF MWRB_Options_Minimap.lua
-- ===================================================================