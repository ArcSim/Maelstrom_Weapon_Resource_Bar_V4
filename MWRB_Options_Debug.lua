-- ===================================================================
-- MWRB_Options_Debug.lua
-- Debug tab options
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
-- DEBUG TAB OPTIONS
-- ===================================================================
function ns.Options.GetDebugTabOptions()
  local db = GetDB()
  
  return {
    desc = ns.Options.CreateDescription("Debug options for troubleshooting and development"),
    
    -- Debug flags
    debugFlags = ns.Options.CreateGroup("Debug Output", nil, true, 1, {
      debug = ns.Options.CreateToggleOption(
        "General Debug",
        "Enable general debug output",
        function()
          return db.debug or false
        end,
        function(value)
          db.debug = value
        end
      ),
      
      debugMSW = ns.Options.CreateToggleOption(
        "MSW Count Debug",
        "Enable MSW count tracking debug output",
        function()
          return db.debugMSW or false
        end,
        function(value)
          db.debugMSW = value
        end
      ),
      
      debugRealMSW = ns.Options.CreateToggleOption(
        "Real MSW Debug",
        "Enable Real MSW system debug output",
        function()
          return db.debugRealMSW or false
        end,
        function(value)
          db.debugRealMSW = value
        end
      ),
      
      debugImportExport = ns.Options.CreateToggleOption(
        "Import/Export Debug",
        "Enable import/export debug output",
        function()
          return db.debugImportExport or false
        end,
        function(value)
          db.debugImportExport = value
        end
      )
    }),
    
    -- Test commands
    testCommands = ns.Options.CreateGroup("Test Commands", nil, true, 2, {
      test5 = ns.Options.CreateExecuteOption(
        "Test: 5 Stacks",
        "Set display to 5 stacks for testing",
        function()
          if ns.API.OnMSWChanged then
            ns.API.OnMSWChanged(5)
          end
        end
      ),
      
      test10 = ns.Options.CreateExecuteOption(
        "Test: 10 Stacks",
        "Set display to 10 stacks for testing",
        function()
          if ns.API.OnMSWChanged then
            ns.API.OnMSWChanged(10)
          end
        end
      ),
      
      test0 = ns.Options.CreateExecuteOption(
        "Test: 0 Stacks (Empty)",
        "Set display to 0 stacks (empty) for testing",
        function()
          if ns.API.OnMSWChanged then
            ns.API.OnMSWChanged(0)
          end
        end
      ),
      
      status = ns.Options.CreateExecuteOption(
        "Show Current Status",
        "Print current MSW count to chat",
        function()
          local msw = (ns.API.GetMSWCount and ns.API.GetMSWCount()) or 0
          print("|cff00ccffMWRB|r Current MSW count:", msw)
        end
      ),
      
      refreshMSW = ns.Options.CreateExecuteOption(
        "Force Refresh MSW",
        "Force refresh MSW count from aura",
        function()
          if ns.API.RefreshMSW then
            ns.API.RefreshMSW()
          end
          local msw = (ns.API.GetMSWCount and ns.API.GetMSWCount()) or 0
          print("|cff00ccffMWRB|r Refreshed MSW count:", msw)
        end
      )
    }),
    
    -- Reset options
    reset = ns.Options.CreateGroup("Reset", nil, true, 3, {
      resetLayout = ns.Options.CreateExecuteOption(
        "Reset Layout",
        "Reset all layout positions to defaults",
        function()
          if ns.API.ResetLayoutPositions then
            ns.API.ResetLayoutPositions()
            print("|cff00ccffMWRB|r Layout reset. /reload to apply.")
          end
        end
      ),
      
      resetThresholds = ns.Options.CreateExecuteOption(
        "Reset Threshold Triggers",
        "Reset threshold sound trigger states",
        function()
          if ns.API.ResetThresholdTriggers then
            ns.API.ResetThresholdTriggers()
            print("|cff00ccffMWRB|r Threshold triggers reset.")
          end
        end
      )
    })
  }
end

-- ===================================================================
-- END OF MWRB_Options_Debug.lua
-- ===================================================================