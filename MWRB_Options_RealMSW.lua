-- ===================================================================
-- MWRB_Options_RealMSW.lua
-- Real MSW Display tab - Master toggle and basic settings
-- ===================================================================

-- Class check - Exit if not Shaman
local _, playerClass = UnitClass("player")
if playerClass ~= "SHAMAN" then return end

local ADDON, ns = ...
ns.Options = ns.Options or {}

local function GetDB()
  return ns.API.GetDB()
end

-- ===================================================================
-- REAL MSW DISPLAY TAB OPTIONS
-- ===================================================================
function ns.Options.GetRealMSWTabOptions()
  local db = GetDB()
  
  return {
    desc = ns.Options.CreateDescription("Enable Status Bar mode to display Maelstrom Weapon stacks as a status bar."),
    
    spacer1 = {
      type = "header",
      name = "",
      order = 2
    },
    
    -- MASTER ENABLE TOGGLE
    enableRealMSW = ns.Options.CreateToggleOption(
      "Enable Status Bar Mode",
      "Show Status Bar (hides icon displays when enabled)",
      function()
        return db.realMSWBar and db.realMSWBar.enabled or false
      end,
      function(value)
        db.realMSWBar = db.realMSWBar or {}
        db.realMSWBar.enabled = value
        
        if value then
          -- Enable Status Bar - hide icon displays
          if ns.API.HideDisplay then
            ns.API.HideDisplay()
          end
          if ns.RealMSW.Enable then
            ns.RealMSW.Enable()
          end
        else
          -- Disable Status Bar - show icon displays
          if ns.RealMSW.Disable then
            ns.RealMSW.Disable()
          end
          if ns.API.ShowDisplay then
            ns.API.ShowDisplay()
          end
        end
      end
    ),
    
    warningText = {
      type = "description",
      name = "|cffff6b6bWhen Status Bar is enabled, icon displays are hidden.|r\n|cff00ff00Customize appearance in the Visual Settings tab.|r",
      fontSize = "medium",
      order = 3,
      hidden = function()
        return not (db.realMSWBar and db.realMSWBar.enabled)
      end
    },
    
    spacer2 = {
      type = "header",
      name = "",
      order = 4
    },
    
    -- MOVABILITY SETTINGS
    movabilityGroup = ns.Options.CreateGroup("Movability", nil, true, 5, {
      barMovable = ns.Options.CreateToggleOption(
        "Bar Movable",
        "Allow dragging the bar to reposition it",
        function()
          return db.realMSWBar and db.realMSWBar.barMovable ~= false
        end,
        function(value)
          db.realMSWBar = db.realMSWBar or {}
          db.realMSWBar.barMovable = value
          if ns.RealMSW.UpdateMovability then
            ns.RealMSW.UpdateMovability(value, nil)
          end
        end
      ),
      
      textMovable = ns.Options.CreateToggleOption(
        "Text Movable",
        "Allow dragging the text to reposition it",
        function()
          return db.realMSWBar and db.realMSWBar.textMovable ~= false
        end,
        function(value)
          db.realMSWBar = db.realMSWBar or {}
          db.realMSWBar.textMovable = value
          if ns.RealMSW.UpdateMovability then
            ns.RealMSW.UpdateMovability(nil, value)
          end
        end
      ),
      
      barFrameStrata = {
        type = "select",
        name = "Bar Frame Strata",
        desc = "Set the frame strata (layering level) for the status bar. Higher strata appears above other UI elements.",
        order = 3,
        values = {
          ["BACKGROUND"] = "Background (Lowest)",
          ["LOW"] = "Low",
          ["MEDIUM"] = "Medium (Default)",
          ["HIGH"] = "High",
          ["DIALOG"] = "Dialog",
          ["FULLSCREEN"] = "Fullscreen",
          ["FULLSCREEN_DIALOG"] = "Fullscreen Dialog",
          ["TOOLTIP"] = "Tooltip (Highest)",
        },
        sorting = {"BACKGROUND", "LOW", "MEDIUM", "HIGH", "DIALOG", "FULLSCREEN", "FULLSCREEN_DIALOG", "TOOLTIP"},
        get = function()
          return db.realMSWBar and db.realMSWBar.barFrameStrata or "MEDIUM"
        end,
        set = function(_, value)
          db.realMSWBar = db.realMSWBar or {}
          db.realMSWBar.barFrameStrata = value
          if ns.RealMSW.UpdateFrameStrata then
            ns.RealMSW.UpdateFrameStrata(value)
          end
        end,
      },
      
      barFrameLevel = {
        type = "range",
        name = "Bar Frame Level",
        desc = "Exact frame level within the selected strata. Higher levels render above lower levels in the same strata. The stack count text always stays 5 levels above the bar automatically.",
        order = 3.5,
        min = 0,
        max = 200,
        step = 1,
        get = function()
          return (db.realMSWBar and db.realMSWBar.barFrameLevel)
            or (ns.RealMSW.GetBarFrameLevel and ns.RealMSW.GetBarFrameLevel())
            or 1
        end,
        set = function(_, value)
          db.realMSWBar = db.realMSWBar or {}
          db.realMSWBar.barFrameLevel = value
          if ns.RealMSW.UpdateFrameLevel then
            ns.RealMSW.UpdateFrameLevel(value)
          end
        end,
      },
      
      resetBarPos = ns.Options.CreateExecuteOption(
        "Reset Bar Position",
        "Reset bar position to center of screen",
        function()
          if ns.RealMSW.ResetBarPosition then
            ns.RealMSW.ResetBarPosition()
          end
        end
      ),
      
      resetTextPos = ns.Options.CreateExecuteOption(
        "Reset Text Position",
        "Reset text position to center of screen",
        function()
          if ns.RealMSW.ResetTextPosition then
            ns.RealMSW.ResetTextPosition()
          end
        end
      ),
    }),
    
    -- EXACT POSITION (X/Y INPUTS)
    positionGroup = ns.Options.CreateGroup("Exact Position", nil, true, 5.5, {
      barX = {
        type = "input",
        name = "Bar X",
        desc = "Exact horizontal position of the bar (offset from screen center)",
        order = 1,
        width = "half",
        get = function()
          local x = ns.RealMSW.GetBarPositionXY and ns.RealMSW.GetBarPositionXY() or 0
          return string.format("%.1f", x)
        end,
        set = function(_, value)
          local num = tonumber(value)
          if num and ns.RealMSW.SetBarPositionXY then
            ns.RealMSW.SetBarPositionXY(num, nil)
          end
        end,
        validate = function(_, value)
          if tonumber(value) then return true end
          return "Please enter a number"
        end,
      },
      
      barY = {
        type = "input",
        name = "Bar Y",
        desc = "Exact vertical position of the bar (offset from screen center)",
        order = 2,
        width = "half",
        get = function()
          local y = 200
          if ns.RealMSW.GetBarPositionXY then
            local _, posY = ns.RealMSW.GetBarPositionXY()
            y = posY or 200
          end
          return string.format("%.1f", y)
        end,
        set = function(_, value)
          local num = tonumber(value)
          if num and ns.RealMSW.SetBarPositionXY then
            ns.RealMSW.SetBarPositionXY(nil, num)
          end
        end,
        validate = function(_, value)
          if tonumber(value) then return true end
          return "Please enter a number"
        end,
      },
      
      textX = {
        type = "input",
        name = "Text X",
        desc = "Exact horizontal position of the stack count text (offset from screen center)",
        order = 3,
        width = "half",
        get = function()
          local x = ns.RealMSW.GetTextPositionXY and ns.RealMSW.GetTextPositionXY() or 0
          return string.format("%.1f", x)
        end,
        set = function(_, value)
          local num = tonumber(value)
          if num and ns.RealMSW.SetTextPositionXY then
            ns.RealMSW.SetTextPositionXY(num, nil)
          end
        end,
        validate = function(_, value)
          if tonumber(value) then return true end
          return "Please enter a number"
        end,
      },
      
      textY = {
        type = "input",
        name = "Text Y",
        desc = "Exact vertical position of the stack count text (offset from screen center)",
        order = 4,
        width = "half",
        get = function()
          local y = 230
          if ns.RealMSW.GetTextPositionXY then
            local _, posY = ns.RealMSW.GetTextPositionXY()
            y = posY or 230
          end
          return string.format("%.1f", y)
        end,
        set = function(_, value)
          local num = tonumber(value)
          if num and ns.RealMSW.SetTextPositionXY then
            ns.RealMSW.SetTextPositionXY(nil, num)
          end
        end,
        validate = function(_, value)
          if tonumber(value) then return true end
          return "Please enter a number"
        end,
      },
    }),
    
    spacer3 = {
      type = "header",
      name = "",
      order = 6
    },
    
    -- DEBUG
    debugGroup = ns.Options.CreateGroup("Debug", nil, true, 7, {
      debugRealMSW = ns.Options.CreateToggleOption(
        "Real MSW Debug",
        "Enable debug output for Real MSW system",
        function()
          return db.debugRealMSW or false
        end,
        function(value)
          db.debugRealMSW = value
        end
      ),
    }),
  }
end

-- ===================================================================
-- END OF MWRB_Options_RealMSW.lua
-- ===================================================================