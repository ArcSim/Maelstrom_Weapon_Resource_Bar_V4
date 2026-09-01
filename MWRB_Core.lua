-- ===================================================================
-- MWRB_Core.lua
-- Maelstrom Weapon Resource Bar v4 - Core namespace and DB
-- ===================================================================

-- ===================================================================
-- CLASS CHECK - Exit immediately if not a Shaman
-- ===================================================================
local _, playerClass = UnitClass("player")
if playerClass ~= "SHAMAN" then
  return  -- Don't load the addon for non-Shamans
end

-- ===================================================================
-- SECTION 01 – Namespace & API Setup
-- ===================================================================
local ADDON, ns = ...
ns = ns or {}
ns.API = ns.API or {}
ns.devMode = false  -- Hidden debug tab mode, toggle with /mwrb dev

-- ===================================================================
-- SPEC AND TALENT CONSTANTS
-- ===================================================================
local MAELSTROM_WEAPON_TALENT_ID = 187880
local ENHANCEMENT_SPEC_ID = 263

-- ===================================================================
-- SPEC CHECK UTILITY
-- ===================================================================
function ns.API.ShouldShowUI()
  -- Check if player is Enhancement spec
  local specID = GetSpecialization()
  if not specID then return false end
  
  local currentSpecID = GetSpecializationInfo(specID)
  if currentSpecID ~= ENHANCEMENT_SPEC_ID then
    return false
  end
  
  -- Check if Maelstrom Weapon talent is active by spell ID
  local configID = C_ClassTalents.GetActiveConfigID()
  if not configID then return false end
  
  -- Get the tree info
  local configInfo = C_Traits.GetConfigInfo(configID)
  if not configInfo then return false end
  
  -- Search through all nodes in the tree to find Maelstrom Weapon
  for _, treeID in ipairs(configInfo.treeIDs or {}) do
    local nodes = C_Traits.GetTreeNodes(treeID)
    for _, nodeID in ipairs(nodes or {}) do
      local nodeInfo = C_Traits.GetNodeInfo(configID, nodeID)
      if nodeInfo and nodeInfo.activeRank and nodeInfo.activeRank > 0 then
        -- Check if this node contains Maelstrom Weapon spell
        for _, entryID in ipairs(nodeInfo.entryIDs or {}) do
          local entryInfo = C_Traits.GetEntryInfo(configID, entryID)
          if entryInfo and entryInfo.definitionID then
            local definitionInfo = C_Traits.GetDefinitionInfo(entryInfo.definitionID)
            if definitionInfo and definitionInfo.spellID == MAELSTROM_WEAPON_TALENT_ID then
              return true
            end
          end
        end
      end
    end
  end
  
  return false
end

-- ===================================================================
-- SECTION 02 – Database Defaults
-- ===================================================================
local DB_DEFAULTS = {
  profile = {
    -- Config version for migration
    configVersion = 3,
    
    -- Display mode: "5icons", "10spaces", "freeform", "bar", or "realMSW"
    displayMode = "5icons",
    
    -- Global size multiplier (0.25 to 1.25)
    globalSize = 0.8,
    
    -- Global width and height multipliers for icons (0.25 to 2.0)
    globalWidth = 1.0,
    globalHeight = 1.0,
    
    -- Global spacing in pixels (used in 5spaces and 10spaces modes)
    spacing = 8,
    
    -- Free form positions: stores {x=, y=} for each stack 1–10
    slotsPos = {},
    
    -- Bar Mode Configuration
    barMode = {
      -- Bar dimensions
      width = 200,
      height = 30,
      scale = 1.0,
      
      -- Bar opacity
      opacity = 1.0,
      
      -- Bar direction: "HORIZONTAL" or "VERTICAL"
      direction = "HORIZONTAL",
      
      -- Fill direction: "LEFT_TO_RIGHT", "RIGHT_TO_LEFT", "BOTTOM_TO_TOP", "TOP_TO_BOTTOM"
      fillDirection = "LEFT_TO_RIGHT",
      
      -- Texture (LSM registered name)
      texture = "Blizzard",
      
      -- Bar color
      barColor = {r=0.024, g=0, b=1, a=1},
      
      -- Background
      showBackground = true,
      backgroundColor = {r=0.2, g=0.2, b=0.2, a=0.8},
      
      -- Border
      showBorder = true,
      borderColor = {r=0, g=0, b=0, a=1},
      borderThickness = 2,
      
      -- Tick marks / dividers
      showTickMarks = false,
      showCustomTicks = false,
      customTicks = {},
      tickColor = {r=0, g=0, b=0, a=1},
      tickThickness = 2,
      
      -- Individual tick mark colors
      tickColors = {
        [1] = {r=0, g=0, b=0, a=1},
        [2] = {r=0, g=0, b=0, a=1},
        [3] = {r=0, g=0, b=0, a=1},
        [4] = {r=0, g=0, b=0, a=1},
        [5] = {r=0, g=0, b=0, a=1},
        [6] = {r=0, g=0, b=0, a=1},
        [7] = {r=0, g=0, b=0, a=1},
        [8] = {r=0, g=0, b=0, a=1},
        [9] = {r=0, g=0, b=0, a=1},
      },
      useIndividualTickColors = false,
    },
    
    -- Real MSW Bar Mode
    realMSWBar = {
      -- Master enable toggle
      enabled = false,
      
      -- Show bar toggle
      showBar = true,
      
      -- Bar dimensions
      width = 200,
      height = 20,
      
      -- Display mode: "single" or "layered"
      displayMode = "single",
      
      -- Bar appearance
      texture = "Blizzard",
      barColor = {r=0, g=0.5, b=1, a=1},
      useGradient = false,
      layeredBarColors = {
        [1] = {r=0.024, g=0, b=1, a=1},
        [2] = {r=0.024, g=0, b=1, a=1},
        [3] = {r=0.024, g=0, b=1, a=1},
        [4] = {r=0.024, g=0, b=1, a=1},
        [5] = {r=0.024, g=0, b=1, a=1},
        [6] = {r=1, g=0.761, b=0.051, a=1},
        [7] = {r=1, g=0.761, b=0.051, a=1},
        [8] = {r=1, g=0.761, b=0.051, a=1},
        [9] = {r=1, g=0.761, b=0.051, a=1},
        [10] = {r=0.875, g=0, b=1, a=1},
      },
      
      -- Gradient settings
      colorRanges = {
        low = {enabled=false, maxStacks=3, color={r=0.024, g=0, b=1, a=1}},
        mid = {enabled=false, maxStacks=7, color={r=1, g=0.761, b=0.051, a=1}},
        high = {enabled=false, maxStacks=10, color={r=0.875, g=0, b=1, a=1}},
      },
      
      -- Background
      showBackground = true,
      backgroundColor = {r=0, g=0, b=0, a=0.5},
      
      -- Border
      showBorder = true,
      borderStyle = "Drawn",
      borderColor = {r=0.5, g=0.5, b=0.5, a=1},
      drawnBorderThickness = 2,
      
      -- Fill options
      fillDirection = "HORIZONTAL",
      reverseFill = false,
      orientation = "HORIZONTAL",
      
      -- Effects
      opacity = 1.0,
      desaturated = false,
      desaturation = 0,
      
      -- Positioning
      barPosition = {point="CENTER", relPoint="CENTER", x=0, y=200},
      textPosition = {point="CENTER", relPoint="CENTER", x=0, y=230},
      barMovable = true,
      textMovable = true,
      
      -- Text settings
      showText = true,
      fontSize = 32,
      font = "Fonts\\FRIZQT__.TTF",
      textColor = {r=1, g=1, b=1, a=1},
      
      -- Integration
      hideBuffIconMSW = false,
      
      -- Manual tracking fallback
      showManualTracking = false,
      manualCooldownID = nil,
      
      -- Tick marks
      showTickMarks = false,
      showCustomTicks = false,
      customTicks = {},
      tickColor = {r=0, g=0, b=0, a=1},
      tickThickness = 2,
    },
    
    -- Per-stack configuration (stacks 1–10)
    stacks = {
      [1] = {shape="circle3", size=1.0, tint={r=0.024, g=0, b=1, a=1}, emptyTint={r=0.3, g=0.3, b=0.3, a=0.5}},
      [2] = {shape="circle3", size=1.0, tint={r=0.024, g=0, b=1, a=1}, emptyTint={r=0.3, g=0.3, b=0.3, a=0.5}},
      [3] = {shape="circle3", size=1.0, tint={r=0.024, g=0, b=1, a=1}, emptyTint={r=0.3, g=0.3, b=0.3, a=0.5}},
      [4] = {shape="circle3", size=1.0, tint={r=0.024, g=0, b=1, a=1}, emptyTint={r=0.3, g=0.3, b=0.3, a=0.5}},
      [5] = {shape="circle3", size=1.0, tint={r=0.024, g=0, b=1, a=1}, emptyTint={r=0.3, g=0.3, b=0.3, a=0.5}},
      [6] = {shape="circle3", size=1.0, tint={r=1, g=0.761, b=0.051, a=1}, emptyTint={r=0.3, g=0.3, b=0.3, a=0.5}},
      [7] = {shape="circle3", size=1.0, tint={r=1, g=0.761, b=0.051, a=1}, emptyTint={r=0.3, g=0.3, b=0.3, a=0.5}},
      [8] = {shape="circle3", size=1.0, tint={r=1, g=0.761, b=0.051, a=1}, emptyTint={r=0.3, g=0.3, b=0.3, a=0.5}},
      [9] = {shape="circle3", size=1.0, tint={r=1, g=0.761, b=0.051, a=1}, emptyTint={r=0.3, g=0.3, b=0.3, a=0.5}},
      [10] = {shape="circle3", size=1.0, tint={r=0.875, g=0, b=1, a=1}, emptyTint={r=0.3, g=0.3, b=0.3, a=0.5}},
    },
    
    -- Threshold settings
    threshold1 = {
      stacks = 5,
      operator = ">=",
      soundEnabled = false,
      sound = "Sound1",
      colorEnabled = false,
      color = {r=1, g=0.5, b=0, a=1},
      textColorEnabled = false,
      textColor = {r=1, g=0.5, b=0, a=1},
      glowEnabled = false,
      glowColor = {r=1, g=0.5, b=0, a=1},
    },
    
    threshold2 = {
      stacks = 10,
      operator = ">=",
      soundEnabled = false,
      sound = "Sound2",
      colorEnabled = false,
      color = {r=1, g=0, b=0, a=1},
      textColorEnabled = false,
      textColor = {r=1, g=0, b=0, a=1},
      glowEnabled = false,
      glowColor = {r=1, g=0, b=0, a=1},
    },
  },
  
  global = {
    -- Minimap button
    minimap = {
      x = 40,
      y = -40,
      locked = false,
      show = true,
    },
    
    -- Profile snapshots
    profileSnapshots = {},
  }
}

-- ===================================================================
-- SECTION 03 – Accessor Functions
-- ===================================================================
function ns.API.GetDB()
  return ns.db and ns.db.profile or DB_DEFAULTS.profile
end

function ns.API.GetGlobalDB()
  return ns.db and ns.db.global or DB_DEFAULTS.global
end

-- Expose defaults for AceDB initialization
ns.DB_DEFAULTS = DB_DEFAULTS

-- ===================================================================
-- SECTION 04 – Global Helper Functions
-- ===================================================================
function ns.API.DebugPrint(module, ...)
  local db = ns.API.GetDB()
  if db.debug then
    print("|cff00ccffMWRB|r[" .. (module or "CORE") .. "]", ...)
  end
end

-- Legacy debug functions for Display module compatibility
function ns.API.DebugPrintOverlay(...)
  local db = ns.API.GetDB()
  if db.debug then
    print("|cff00ccffMWRB|r[DISPLAY]", ...)
  end
end

function ns.API.DebugPrintPredictor(...)
  local db = ns.API.GetDB()
  if db.debug then
    print("|cff00ccffMWRB|r[DEBUG]", ...)
  end
end

-- ===================================================================
-- SECTION 05 – Slash Commands
-- ===================================================================
SLASH_MWRB1 = "/mwrb"
SLASH_MWRB2 = "/mwr"

SlashCmdList["MWRB"] = function(msg)
  msg = (msg or ""):lower()
  local db = ns.API.GetDB()
  
  if msg == "options" or msg == "opt" or msg == "config" then
    if ns.API.OpenOptions then
      ns.API.OpenOptions()
    end
    
  elseif msg == "test" then
    if ns.API.OnMSWChanged then
      ns.API.OnMSWChanged(5)
    end
    if db.debug then
      print("|cff00ccffMWRB|r Test: set to 5 stacks")
    end
    
  elseif msg == "test0" or msg == "test 0" then
    if ns.API.OnMSWChanged then
      ns.API.OnMSWChanged(0)
    end
    if db.debug then
      print("|cff00ccffMWRB|r Test: set to 0 stacks (empty)")
    end
    
  elseif msg == "hide" then
    if ns.API.HideDisplay then
      ns.API.HideDisplay()
    end
    if db.debug then
      print("|cff00ccffMWRB|r Display hidden")
    end
    
  elseif msg == "show" then
    if ns.API.ShowDisplay then
      ns.API.ShowDisplay()
    end
    if db.debug then
      print("|cff00ccffMWRB|r Display shown")
    end
    
  elseif msg == "debug on" then
    db.debug = true
    db.debugMSW = true
    print("|cff00ccffMWRB|r debug ON")
    
  elseif msg == "debug off" then
    db.debug = false
    db.debugMSW = false
    print("|cff00ccffMWRB|r debug OFF")
    
  elseif msg:match("^debug%s+msw") then
    local state = msg:match("^debug%s+msw%s+(%S+)")
    if state == "on" then
      db.debugMSW = true
      print("|cff00ccffMWRB|r MSW count debug ON")
    elseif state == "off" then
      db.debugMSW = false
      print("|cff00ccffMWRB|r MSW count debug OFF")
    else
      db.debugMSW = not db.debugMSW
      print("|cff00ccffMWRB|r MSW count debug " .. (db.debugMSW and "ON" or "OFF"))
    end
    
  elseif msg == "status" then
    local msw = (ns.API.GetMSWCount and ns.API.GetMSWCount()) or 0
    local shouldShow = ns.API.ShouldShowUI()
    print("|cff00ccffMWRB|r Current MSW count:", msw)
    print("|cff00ccffMWRB|r Should show UI:", shouldShow and "YES" or "NO")
    
  elseif msg == "refresh" then
    if ns.API.RefreshMSW then
      ns.API.RefreshMSW()
    end
    local msw = (ns.API.GetMSWCount and ns.API.GetMSWCount()) or 0
    print("|cff00ccffMWRB|r Refreshed MSW count:", msw)
    
  elseif msg == "resetlayout" or msg == "reset layout" then
    if ns.API.ResetLayoutPositions then
      ns.API.ResetLayoutPositions()
      if db.debug then
        print("|cff00ccffMWRB|r Layout reset. Close and reopen options panel.")
      end
    end
    
  elseif msg == "dev" then
    ns.devMode = not ns.devMode
    print("|cff00ccffMWRB|r Dev mode " .. (ns.devMode and "|cff00ff00ENABLED|r" or "|cffff0000DISABLED|r"))
    if ns.devMode then
      print("|cff00ccffMWRB|r Debug tab is now visible in options panel. Reopen options to see it.")
    end
    
  else
    print("|cff00ccffMWRB|r v4 commands:")
    print("  /mwrb options   - Open options panel")
    print("  /mwrb test      - Test display (5 stacks)")
    print("  /mwrb test0     - Test display (0 stacks)")
    print("  /mwrb status    - Show current MSW count and spec status")
    print("  /mwrb refresh   - Force refresh MSW from aura")
    print("  /mwrb show|hide - Show/hide display")
    print("  /mwrb resetlayout - Reset layout to defaults")
    print("  /mwrb debug on|off - Toggle debug")
    print("  /mwrb debug msw [on|off] - MSW count debug only")
  end
end

-- ===================================================================
-- SECTION 06 – Initialization Event
-- ===================================================================
local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("ADDON_LOADED")
initFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
initFrame:RegisterEvent("TRAIT_CONFIG_UPDATED")
initFrame:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")

initFrame:SetScript("OnEvent", function(_, event, addonName)
  if event == "ADDON_LOADED" and addonName == ADDON then
    ns.API.DebugPrint("CORE", "Addon loaded")
  elseif event == "PLAYER_SPECIALIZATION_CHANGED" or event == "TRAIT_CONFIG_UPDATED" or event == "ACTIVE_TALENT_GROUP_CHANGED" then
    -- Spec or talent changed - check if we should show/hide
    local shouldShow = ns.API.ShouldShowUI()
    local db = ns.API.GetDB()
    
    if db and db.debug then
      print("|cff00ccffMWRB|r[CORE] Spec/talent changed. Should show UI:", shouldShow and "YES" or "NO")
    end
    
    if not shouldShow then
      -- Hide all displays
      if ns.API.HideDisplay then
        ns.API.HideDisplay()
      end
      if ns.RealMSW and ns.RealMSW.Disable then
        ns.RealMSW.Disable()
      end
    else
      -- Show displays based on mode
      local db = ns.API.GetDB()
      if db and db.displayMode == "realMSW" then
        -- Real MSW Bar mode
        if ns.API.HideDisplay then
          ns.API.HideDisplay()
        end
        if ns.RealMSW and ns.RealMSW.Enable then
          ns.RealMSW.Enable()
        end
      else
        -- Normal icon/bar modes
        if ns.API.ShowDisplay then
          ns.API.ShowDisplay()
        end
        if ns.RealMSW and ns.RealMSW.Disable then
          ns.RealMSW.Disable()
        end
      end
    end
  end
end)

-- ===================================================================
-- END OF MWRB_Core.lua
-- ===================================================================