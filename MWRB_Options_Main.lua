-- ===================================================================
-- MWRB_Options_Main.lua
-- Main tab options using AceConfig
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
-- MAIN TAB OPTIONS
-- ===================================================================
function ns.Options.GetMainTabOptions()
  local db = GetDB()
  
  return {
    -- Quick Profiles Section
    quickProfiles = ns.Options.CreateGroup("Quick Profiles", "Load a pre-configured profile setup", true, 1, {
      desc = {
        type = "description",
        name = "Choose from hand-selected profile configurations:",
        order = 1
      },
      
      realMSWBar = {
        type = "execute",
        name = "Status Bar Style",
        desc = "Load the Status Bar style (single bar showing MSW stacks)",
        order = 1.5,
        func = function()
          -- Switch to Status Bar mode
          db.displayMode = "realMSW"
          
          -- Apply Status Bar profile settings
          db.realMSWBar = db.realMSWBar or {}
          db.realMSWBar.enabled = true
          db.realMSWBar.displayMode = "single"  -- Single bar, not folded
          db.realMSWBar.showBar = true
          db.realMSWBar.width = 265
          db.realMSWBar.height = 36
          db.realMSWBar.barScale = 1.1
          db.realMSWBar.opacity = 1
          db.realMSWBar.texture = "Blizzard Raid Bar"
          db.realMSWBar.fillDirection = "LEFT_TO_RIGHT"
          db.realMSWBar.useGradient = false
          db.realMSWBar.barColor = {r=0, g=0.886, b=1, a=1}
          db.realMSWBar.showBackground = true
          db.realMSWBar.backgroundColor = {r=0.239, g=0.251, b=0.259, a=0.64}
          db.realMSWBar.showBorder = true
          db.realMSWBar.borderStyle = "Drawn"
          db.realMSWBar.drawnBorderThickness = 2
          db.realMSWBar.borderColor = {r=0.008, g=0.008, b=0.008, a=1}
          db.realMSWBar.showTickMarks = true
          db.realMSWBar.tickThickness = 2
          db.realMSWBar.tickColor = {r=0, g=0, b=0, a=1}
          db.realMSWBar.showText = true
          db.realMSWBar.font = "2002 Bold"
          db.realMSWBar.fontSize = 44
          db.realMSWBar.textColor = {r=1, g=1, b=1, a=1}
          db.realMSWBar.barMovable = true
          db.realMSWBar.textMovable = true
          
          -- Hide icon display
          if ns.API.HideDisplay then
            ns.API.HideDisplay()
          end
          
          -- Enable Status Bar with refresh
          if ns.RealMSW then
            if ns.RealMSW.Enable then
              ns.RealMSW.Enable()
            end
            if ns.RealMSW.Refresh then
              ns.RealMSW.Refresh(true)
            end
          end
          
          print("|cff00ccffMWRB|r Loaded Status Bar style profile")
        end
      },
      
      foldedBars = {
        type = "execute",
        name = "Folded Bars Style",
        desc = "Load the Folded Bars style (two overlaid 5-stack bars)",
        order = 1.6,
        func = function()
          -- Switch to Status Bar mode with folded display
          db.displayMode = "realMSW"
          
          -- Apply Folded Bars profile settings
          db.realMSWBar = db.realMSWBar or {}
          db.realMSWBar.enabled = true
          db.realMSWBar.displayMode = "folded"
          db.realMSWBar.showBar = true
          
          -- Bar settings
          db.realMSWBar.foldedTexture = "Blizzard Raid Bar"
          db.realMSWBar.foldedFillDirection = "LEFT_TO_RIGHT"
          
          -- Bottom bar (1-5) settings
          db.realMSWBar.foldedBottomWidth = 270
          db.realMSWBar.foldedBottomHeight = 38
          db.realMSWBar.foldedBottomScale = 1.05
          db.realMSWBar.foldedBottomOpacity = 1
          db.realMSWBar.foldedBottomColor = {r=0, g=0.886, b=1, a=1}  -- Blue
          db.realMSWBar.foldedBottomShowBackground = true
          db.realMSWBar.foldedBottomShowBorder = false
          
          -- Top bar (6-10) settings
          db.realMSWBar.foldedTopWidth = 270
          db.realMSWBar.foldedTopHeight = 38
          db.realMSWBar.foldedTopScale = 1.05
          db.realMSWBar.foldedTopOpacity = 1
          db.realMSWBar.foldedTopColor = {r=1, g=0.863, b=0, a=1}  -- Gold/Orange
          db.realMSWBar.foldedTopShowBackground = false
          db.realMSWBar.foldedTopShowBorder = true
          db.realMSWBar.foldedTopBorderColor = {r=0, g=0, b=0, a=1}
          
          -- Background settings
          db.realMSWBar.foldedBackgroundColor = {r=0.792, g=0.792, b=0.792, a=1}
          db.realMSWBar.foldedBackgroundTexture = "Solid"
          
          -- Border settings
          db.realMSWBar.foldedBorderColor = {r=0, g=0, b=0, a=1}
          
          -- Tick marks (only on top bar by default)
          db.realMSWBar.foldedTicksBottomEnabled = false
          db.realMSWBar.foldedTicksTopEnabled = true
          db.realMSWBar.foldedTickColor = {r=0, g=0, b=0, a=1}
          db.realMSWBar.foldedTickThickness = 2
          
          -- Layer order
          db.realMSWBar.foldedStackOrder = "bottom_on_bottom"
          db.realMSWBar.foldedIndividualSizes = false
          
          -- Text settings
          db.realMSWBar.showText = true
          db.realMSWBar.font = "2002 Bold"
          db.realMSWBar.fontSize = 44
          db.realMSWBar.textColor = {r=1, g=1, b=1, a=1}
          
          -- Misc
          db.realMSWBar.barMovable = true
          db.realMSWBar.textMovable = true
          
          -- Hide icon display
          if ns.API.HideDisplay then
            ns.API.HideDisplay()
          end
          
          -- Enable Status Bar with refresh
          if ns.RealMSW then
            if ns.RealMSW.Enable then
              ns.RealMSW.Enable()
            end
            if ns.RealMSW.Refresh then
              ns.RealMSW.Refresh(true)
            end
          end
          
          print("|cff00ccffMWRB|r Loaded Folded Bars style profile")
        end
      },
      
      comboPoint = {
        type = "execute",
        name = "Combo Point Style",
        desc = "Load the Combo Point visual style (blue to pink circles with gray borders)",
        order = 2,
        func = function()
          -- Disable Status Bar if active
          if ns.RealMSW then
            if ns.RealMSW.Disable then
              ns.RealMSW.Disable()
            end
            -- Force hide Status Bar frames
            if ns.RealMSW.Refresh then
              db.displayMode = "5icons"
              ns.RealMSW.Refresh(true)
            end
          end
          
          -- Apply Combo Point profile settings - CIRCLES with blue/pink colors
          db.displayMode = "5icons"
          db.globalSize = 0.8
          db.globalWidth = 1.0
          db.globalHeight = 1.0
          db.spacing = -13
          db.stackTextSize = 26
          
          -- Stacks 1-5: BLUE CIRCLES with gray texture borders
          for i = 1, 5 do
            db.stacks[i] = {
              shape = "circle3",
              size = 1.05,
              tint = {r=0.106, g=0.31, b=0.98, a=1},  -- Blue
              emptyTint = {r=0.322, g=0.322, b=0.357, a=1},
              glowEnabled = false,
              glowColor = {r=0.502, g=0.702, b=1, a=1},
              borderEnabled = true,
              borderType = "texture",
              borderTexture = "Square_Border1",
              borderColor = {r=0.7372549176216125, g=0.7372549176216125, b=0.7372549176216125, a=1},  -- Gray
              borderThickness = 2,
              borderOffset = 0
            }
          end
          
          -- Stacks 6-10: PINK/ORANGE CIRCLES with gray texture borders
          for i = 6, 10 do
            db.stacks[i] = {
              shape = "circle3",
              size = 1.05,
              tint = {r=0.9803922176361084, g=0.760784387588501, b=0, a=1},  -- Pink/Orange
              emptyTint = {r=0.322, g=0.322, b=0.357, a=1},
              glowEnabled = false,
              glowColor = {r=1, g=0.702, b=0.502, a=1},
              borderEnabled = true,
              borderType = "texture",
              borderTexture = "Square_Border1",
              borderColor = {r=0.7372549176216125, g=0.7372549176216125, b=0.7372549176216125, a=1},  -- Gray
              borderThickness = 2,
              borderOffset = 0
            }
          end
          
          -- Reset thresholds
          db.threshold1Enabled = false
          db.threshold2Enabled = false
          
          -- Apply layout first
          if ns.API.ApplyLayout then
            ns.API.ApplyLayout()
          end
          
          -- Then refresh
          if ns.API.RefreshDisplay then
            ns.API.RefreshDisplay()
          end
          
          -- Make sure display is visible
          if ns.API.ShowDisplay then
            ns.API.ShowDisplay()
          end
          
          -- If user has stack text enabled, re-initialize it for text overlay
          if db.realMSWBar and db.realMSWBar.showText then
            if ns.RealMSW and ns.RealMSW.Initialize then
              ns.RealMSW.Initialize()
            end
          end
          
          print("|cff00ccffMWRB|r Loaded Combo Point style profile")
        end
      },
      
      squares = {
        type = "execute",
        name = "Squares Style",
        desc = "Load the Squares visual style (blue squares with dark and blue borders)",
        order = 3,
        func = function()
          -- Disable Status Bar if active
          if ns.RealMSW then
            if ns.RealMSW.Disable then
              ns.RealMSW.Disable()
            end
            -- Force hide Status Bar frames
            if ns.RealMSW.Refresh then
              db.displayMode = "5icons"
              ns.RealMSW.Refresh(true)
            end
          end
          
          -- Apply Squares profile settings - SQUARES with blue colors
          db.displayMode = "5icons"
          db.globalSize = 0.75
          db.globalWidth = 0.95
          db.globalHeight = 1.0
          db.spacing = -11
          db.stackTextSize = 26
          
          -- Stacks 1-5: BLUE SQUARES with dark borders
          for i = 1, 5 do
            db.stacks[i] = {
              shape = "square",
              size = 1.15,
              tint = {r=0.3843137621879578, g=0.8000000715255737, b=0.9960784912109375, a=1},  -- Bright blue
              emptyTint = {r=0.4117647409439087, g=0.4274510145187378, b=0.4392157196998596, a=1},  -- Dark gray
              glowEnabled = false,
              glowColor = {r=0.502, g=0.702, b=1, a=1},
              borderEnabled = true,
              borderType = "outline",
              borderTexture = "Square_Border1",
              borderColor = {r=0.2588235437870026, g=0.2823529541492462, b=0.2745098173618317, a=0.9062501192092896},  -- Very dark border
              borderThickness = 5,
              borderOffset = 6
            }
          end
          
          -- Stacks 6-10: BLUE SQUARES with blue borders
          for i = 6, 10 do
            db.stacks[i] = {
              shape = "square",
              size = 1.15,
              tint = {r=0.3843137621879578, g=0.8000000715255737, b=0.9960784912109375, a=1},  -- Bright blue (same as 1-5)
              emptyTint = {r=0.4117647409439087, g=0.4274510145187378, b=0.4392157196998596, a=1},  -- Dark gray
              glowEnabled = false,
              glowColor = {r=0.502, g=0.702, b=1, a=1},
              borderEnabled = true,
              borderType = "outline",
              borderTexture = "Square_Border1",
              borderColor = {r=0.3764706254005432, g=0.4431372880935669, b=0.803921639919281, a=1},  -- Blue border
              borderThickness = 5,
              borderOffset = 6
            }
          end
          
          -- Reset thresholds
          db.threshold1Enabled = false
          db.threshold2Enabled = false
          
          -- Apply layout first
          if ns.API.ApplyLayout then
            ns.API.ApplyLayout()
          end
          
          -- Then refresh
          if ns.API.RefreshDisplay then
            ns.API.RefreshDisplay()
          end
          
          -- Make sure display is visible
          if ns.API.ShowDisplay then
            ns.API.ShowDisplay()
          end
          
          -- If user has stack text enabled, re-initialize it for text overlay
          if db.realMSWBar and db.realMSWBar.showText then
            if ns.RealMSW and ns.RealMSW.Initialize then
              ns.RealMSW.Initialize()
            end
          end
          
          print("|cff00ccffMWRB|r Loaded Squares style profile")
        end
      },
      
    }),
    
    -- Display Mode Section
    displayMode = ns.Options.CreateGroup("Display Mode", "Choose how MSW stacks are displayed", true, 2, {
      forceHide = ns.Options.CreateToggleOption(
        "Force Hide",
        "Master on/off switch for all displays",
        function()
          return db.forceHide or false
        end,
        function(value)
          db.forceHide = value
          
          if value then
            -- Force hide everything
            if ns.API.HideDisplay then
              ns.API.HideDisplay()
            end
            if ns.RealMSW and ns.RealMSW.Disable then
              ns.RealMSW.Disable()
            end
          else
            -- Re-enable displays immediately
            if ns.API.ShouldShowUI() then
              if db.displayMode == "realMSW" then
                -- Status Bar mode
                if ns.RealMSW and ns.RealMSW.Enable then
                  ns.RealMSW.Enable()
                end
              else
                -- Icon/Bar modes
                if ns.API.ShowDisplay then
                  ns.API.ShowDisplay()
                end
                if ns.API.RefreshDisplay then
                  ns.API.RefreshDisplay()
                end
                
                -- Ensure stack text is running if enabled
                if db.realMSWBar and db.realMSWBar.showText then
                  if ns.RealMSW and ns.RealMSW.Initialize then
                    ns.RealMSW.Initialize()
                  end
                end
              end
            end
            
            -- Update combat visibility
            if ns.API.UpdateCombatVisibility then
              ns.API.UpdateCombatVisibility()
            end
          end
        end
      ),
      
      mode = {
        type = "select",
        name = "Display Mode",
        desc = "Choose how MSW stacks are displayed",
        order = 2,
        values = {
          ["realMSW"] = "Status Bar",
          ["5icons"] = "5 Icons",
          ["10spaces"] = "10 Icons (all visible)",
          ["freeform"] = "Free Form (drag each icon)",
          ["bar"] = "Simple Bar"
        },
        sorting = {"realMSW", "5icons", "10spaces", "freeform", "bar"},
        get = function()
          return db.displayMode or "5icons"
        end,
        set = function(info, value)
          local oldMode = db.displayMode
          db.displayMode = value
          
          -- Handle Status Bar mode transitions
          if value == "realMSW" then
            -- Switching TO Status Bar mode
            -- Ensure defaults exist first (fixes old profiles)
            if ns.RealMSW and ns.RealMSW.EnsureDefaults then
              ns.RealMSW.EnsureDefaults()
            end
            
            if ns.API.HideDisplay then
              ns.API.HideDisplay()
            end
            if ns.RealMSW and ns.RealMSW.Enable then
              ns.RealMSW.Enable()
            end
          else
            -- Switching to icon/bar mode
            
            -- Disable Real MSW when switching to other modes
            if ns.RealMSW and ns.RealMSW.Disable then
              ns.RealMSW.Disable()
            end
            
            -- Apply layout for the new mode
            if ns.API.ApplyLayout then
              ns.API.ApplyLayout()
            end
            
            -- Refresh display
            if ns.API.RefreshDisplay then
              ns.API.RefreshDisplay()
            end
            
            -- Show display for icon/bar modes
            if ns.API.ShowDisplay then
              ns.API.ShowDisplay()
            end
          end
        end
      },
      
      modeNote = {
        type = "description",
        name = "",
        fontSize = "medium",
        order = 3,
        hidden = true
      }
    }),
    
    
    -- Icon Display Settings (for icon modes only)
    displaySettings = {
      type = "group",
      name = "Icon Settings",
      desc = "Icon size and spacing",
      inline = true,
      order = 3,
      hidden = function()
        return db.displayMode == "bar" or db.displayMode == "realMSW"
      end,
      args = {
        globalSize = {
          type = "range",
          name = "Scale",
          desc = "Overall icon scale",
          order = 1,
          width = 1.2,
          min = 0.1,
          max = 2.0,
          step = 0.05,
          get = function()
            return db.globalSize or 1.0
          end,
          set = function(info, value)
            db.globalSize = value
            if ns.API.ApplyLayout then
              ns.API.ApplyLayout()
            end
          end
        },
        
        spacing = {
          type = "range",
          name = "Spacing",
          desc = "Space between icons (negative = overlap)",
          order = 2,
          width = 1.2,
          min = -50,
          max = 50,
          step = 1,
          get = function()
            return db.spacing or 0
          end,
          set = function(info, value)
            db.spacing = value
            if ns.API.ApplyLayout then
              ns.API.ApplyLayout()
            end
          end
        },
        
        globalWidth = {
          type = "range",
          name = "Width",
          desc = "Icon width multiplier",
          order = 3,
          width = 1.2,
          min = 0.25,
          max = 2.0,
          step = 0.05,
          get = function()
            return db.globalWidth or 1.0
          end,
          set = function(info, value)
            db.globalWidth = value
            if ns.API.ApplyLayout then
              ns.API.ApplyLayout()
            end
          end
        },
        
        globalHeight = {
          type = "range",
          name = "Height",
          desc = "Icon height multiplier",
          order = 4,
          width = 1.2,
          min = 0.25,
          max = 2.0,
          step = 0.05,
          get = function()
            return db.globalHeight or 1.0
          end,
          set = function(info, value)
            db.globalHeight = value
            if ns.API.ApplyLayout then
              ns.API.ApplyLayout()
            end
          end
        },
        
        -- More Options button
        moreOptions = {
          type = "execute",
          name = "More Options...",
          desc = "Open Visual Settings for shapes, colors, borders, glows, and more",
          order = 5,
          func = function()
            local AceConfigDialog = LibStub("AceConfigDialog-3.0")
            AceConfigDialog:SelectGroup("MWRB", "visual")
          end
        },
      }
    },
    
    -- Bar Settings (for Status Bar and Simple Bar modes)
    barSettings = {
      type = "group",
      name = "Bar Settings",
      desc = "Bar size and appearance",
      inline = true,
      order = 3.5,
      hidden = function()
        return db.displayMode ~= "bar" and db.displayMode ~= "realMSW"
      end,
      args = {
      -- Show Bar toggle (Real MSW only)
      showBar = {
        type = "toggle",
        name = "Show Bar",
        desc = "Display the MSW bar (disable for text-only mode)",
        order = 0.3,
        hidden = function()
          return db.displayMode ~= "realMSW"
        end,
        get = function()
          db.realMSWBar = db.realMSWBar or {}
          return db.realMSWBar.showBar ~= false
        end,
        set = function(info, value)
          db.realMSWBar = db.realMSWBar or {}
          db.realMSWBar.showBar = value
          if ns.RealMSW and ns.RealMSW.Refresh then
            ns.RealMSW.Refresh(true)
          end
        end
      },
      
      -- Display Style (Real MSW only - single, folded, layered)
      displayStyle = {
        type = "select",
        name = "Display Style",
        desc = "Choose bar display style",
        order = 0.5,
        hidden = function()
          return db.displayMode ~= "realMSW"
        end,
        values = {
          ["single"] = "Single Bar",
          ["folded"] = "Folded (5+5)",
        },
        get = function()
          db.realMSWBar = db.realMSWBar or {}
          return db.realMSWBar.displayMode or "single"
        end,
        set = function(info, value)
          db.realMSWBar = db.realMSWBar or {}
          db.realMSWBar.displayMode = value
          if ns.RealMSW.Refresh then
            ns.RealMSW.Refresh(true)
          end
        end
      },
      
      -- Row 1: Fill Direction, Texture, Fill Color
      fillDirection = {
        type = "select",
        name = "Fill Direction",
        desc = "Bar fill direction",
        order = 1,
        values = {
          ["LEFT_TO_RIGHT"] = "Left to Right",
          ["RIGHT_TO_LEFT"] = "Right to Left",
          ["BOTTOM_TO_TOP"] = "Bottom to Top",
          ["TOP_TO_BOTTOM"] = "Top to Bottom"
        },
        get = function()
          if db.displayMode == "realMSW" then
            return db.realMSWBar and db.realMSWBar.fillDirection or "LEFT_TO_RIGHT"
          else
            return db.barMode and db.barMode.fillDirection or "LEFT_TO_RIGHT"
          end
        end,
        set = function(info, value)
          if db.displayMode == "realMSW" then
            db.realMSWBar = db.realMSWBar or {}
            db.realMSWBar.fillDirection = value
            if ns.RealMSW.UpdateBarAppearance then
              ns.RealMSW.UpdateBarAppearance()
            end
          else
            db.barMode = db.barMode or {}
            db.barMode.fillDirection = value
            if ns.API.RefreshDisplay then
              ns.API.RefreshDisplay()
            end
          end
        end
      },
      
      texture = {
        type = "select",
        name = "Texture",
        desc = "Bar texture style",
        order = 2,
        values = function()
          return ns.LSM and ns.LSM.GetStatusBarList() or {
            ["Blizzard"] = "Blizzard",
            ["Blizzard Maelstrom"] = "Blizzard Maelstrom",
            ["Smooth"] = "Smooth"
          }
        end,
        get = function()
          if db.displayMode == "realMSW" then
            return db.realMSWBar and db.realMSWBar.texture or "Blizzard"
          else
            return db.barMode and db.barMode.texture or "Blizzard"
          end
        end,
        set = function(info, value)
          if db.displayMode == "realMSW" then
            db.realMSWBar = db.realMSWBar or {}
            db.realMSWBar.texture = value
            if ns.RealMSW.UpdateBarAppearance then
              ns.RealMSW.UpdateBarAppearance()
            end
          else
            db.barMode = db.barMode or {}
            db.barMode.texture = value
            if ns.API.RefreshDisplay then
              ns.API.RefreshDisplay()
            end
          end
        end
      },
      
      -- Bar Color (shown when NOT in folded mode)
      barColor = {
        type = "color",
        name = "Color",
        desc = "Bar fill color",
        order = 3,
        hasAlpha = true,
        hidden = function()
          -- Hide when in Real MSW folded mode
          return db.displayMode == "realMSW" and db.realMSWBar and db.realMSWBar.displayMode == "folded"
        end,
        get = function()
          local color
          if db.displayMode == "realMSW" then
            color = db.realMSWBar and db.realMSWBar.barColor or {r=0, g=0.5, b=1, a=1}
          else
            color = db.barMode and db.barMode.barColor or {r=0, g=0.5, b=1, a=1}
          end
          return color.r, color.g, color.b, color.a or 1
        end,
        set = function(info, r, g, b, a)
          local color = {r=r, g=g, b=b, a=a}
          if db.displayMode == "realMSW" then
            db.realMSWBar = db.realMSWBar or {}
            db.realMSWBar.barColor = color
            if ns.RealMSW.UpdateBarAppearance then
              ns.RealMSW.UpdateBarAppearance()
            end
          else
            db.barMode = db.barMode or {}
            db.barMode.barColor = color
            if ns.API.RefreshDisplay then
              ns.API.RefreshDisplay()
            end
          end
        end
      },
      
      -- Bar Color (1-5) - shown only in Real MSW folded mode
      barColorBottom = {
        type = "color",
        name = "Color (1-5)",
        desc = "Color for the bottom bar showing stacks 1-5",
        order = 3.1,
        hasAlpha = true,
        hidden = function()
          -- Only show when in Real MSW folded mode
          return not (db.displayMode == "realMSW" and db.realMSWBar and db.realMSWBar.displayMode == "folded")
        end,
        get = function()
          local c = db.realMSWBar and db.realMSWBar.foldedBottomColor or {r=0, g=0.5, b=1, a=1}
          return c.r, c.g, c.b, c.a or 1
        end,
        set = function(info, r, g, b, a)
          db.realMSWBar = db.realMSWBar or {}
          db.realMSWBar.foldedBottomColor = {r=r, g=g, b=b, a=a}
          if ns.RealMSW.UpdateFoldedAppearance then
            ns.RealMSW.UpdateFoldedAppearance()
          end
        end
      },
      
      -- Bar Color (6-10) - shown only in Real MSW folded mode
      barColorTop = {
        type = "color",
        name = "Color (6-10)",
        desc = "Color for the top bar showing stacks 6-10",
        order = 3.2,
        hasAlpha = true,
        hidden = function()
          -- Only show when in Real MSW folded mode
          return not (db.displayMode == "realMSW" and db.realMSWBar and db.realMSWBar.displayMode == "folded")
        end,
        get = function()
          local c = db.realMSWBar and db.realMSWBar.foldedTopColor or {r=1, g=0.5, b=0, a=1}
          return c.r, c.g, c.b, c.a or 1
        end,
        set = function(info, r, g, b, a)
          db.realMSWBar = db.realMSWBar or {}
          db.realMSWBar.foldedTopColor = {r=r, g=g, b=b, a=a}
          if ns.RealMSW.UpdateFoldedAppearance then
            ns.RealMSW.UpdateFoldedAppearance()
          end
        end
      },
      
      -- Row 2: Scale, Height, Width, Opacity
      scale = {
        type = "range",
        name = "Scale",
        desc = "Scale the bar uniformly",
        order = 4,
        min = 0.5,
        max = 2.0,
        step = 0.05,
        get = function()
          if db.displayMode == "realMSW" then
            return db.realMSWBar and db.realMSWBar.barScale or 1.0
          else
            return db.barMode and db.barMode.scale or 1.0
          end
        end,
        set = function(info, value)
          if db.displayMode == "realMSW" then
            db.realMSWBar = db.realMSWBar or {}
            db.realMSWBar.barScale = value
            if ns.RealMSW.UpdateBarAppearance then
              ns.RealMSW.UpdateBarAppearance()
            end
          else
            db.barMode = db.barMode or {}
            db.barMode.scale = value
            if ns.API.RefreshDisplay then
              ns.API.RefreshDisplay()
            end
          end
        end
      },
      
      height = {
        type = "range",
        name = "Height",
        desc = "Bar height in pixels",
        order = 5,
        min = 10,
        max = 100,
        step = 2,
        get = function()
          if db.displayMode == "realMSW" then
            return db.realMSWBar and db.realMSWBar.height or 20
          else
            return db.barMode and db.barMode.height or 30
          end
        end,
        set = function(info, value)
          if db.displayMode == "realMSW" then
            db.realMSWBar = db.realMSWBar or {}
            db.realMSWBar.height = value
            if ns.RealMSW.UpdateBarAppearance then
              ns.RealMSW.UpdateBarAppearance()
            end
          else
            db.barMode = db.barMode or {}
            db.barMode.height = value
            if ns.API.RefreshDisplay then
              ns.API.RefreshDisplay()
            end
          end
        end
      },
      
      width = {
        type = "range",
        name = "Width",
        desc = "Bar width in pixels",
        order = 6,
        min = 50,
        max = 500,
        step = 5,
        get = function()
          if db.displayMode == "realMSW" then
            return db.realMSWBar and db.realMSWBar.width or 200
          else
            return db.barMode and db.barMode.width or 200
          end
        end,
        set = function(info, value)
          if db.displayMode == "realMSW" then
            db.realMSWBar = db.realMSWBar or {}
            db.realMSWBar.width = value
            if ns.RealMSW.UpdateBarAppearance then
              ns.RealMSW.UpdateBarAppearance()
            end
          else
            db.barMode = db.barMode or {}
            db.barMode.width = value
            if ns.API.RefreshDisplay then
              ns.API.RefreshDisplay()
            end
          end
        end
      },
      
      opacity = {
        type = "range",
        name = "Opacity",
        desc = "Transparency (0=transparent, 1=opaque)",
        order = 7,
        min = 0,
        max = 1,
        step = 0.05,
        get = function()
          if db.displayMode == "realMSW" then
            return db.realMSWBar and db.realMSWBar.opacity or 1.0
          else
            return db.barMode and db.barMode.opacity or 1.0
          end
        end,
        set = function(info, value)
          if db.displayMode == "realMSW" then
            db.realMSWBar = db.realMSWBar or {}
            db.realMSWBar.opacity = value
            if ns.RealMSW.UpdateBarAppearance then
              ns.RealMSW.UpdateBarAppearance()
            end
          else
            db.barMode = db.barMode or {}
            db.barMode.opacity = value
            if ns.API.RefreshDisplay then
              ns.API.RefreshDisplay()
            end
          end
        end
      },
      
      frameStrata = {
        type = "select",
        name = "Frame Strata",
        desc = "Set the frame strata (layering level). Higher strata appears above other UI elements.",
        order = 8,
        hidden = function()
          return db.displayMode ~= "realMSW"
        end,
        values = {
          ["BACKGROUND"] = "Background",
          ["LOW"] = "Low",
          ["MEDIUM"] = "Medium",
          ["HIGH"] = "High",
          ["DIALOG"] = "Dialog",
          ["FULLSCREEN"] = "Fullscreen",
          ["FULLSCREEN_DIALOG"] = "Fullscreen Dialog",
          ["TOOLTIP"] = "Tooltip",
        },
        sorting = {"BACKGROUND", "LOW", "MEDIUM", "HIGH", "DIALOG", "FULLSCREEN", "FULLSCREEN_DIALOG", "TOOLTIP"},
        get = function()
          return db.realMSWBar and db.realMSWBar.barFrameStrata or "MEDIUM"
        end,
        set = function(info, value)
          db.realMSWBar = db.realMSWBar or {}
          db.realMSWBar.barFrameStrata = value
          if ns.RealMSW.UpdateFrameStrata then
            ns.RealMSW.UpdateFrameStrata(value)
          end
        end,
      },
      
      barFrameLevel = {
        type = "range",
        name = "Frame Level",
        desc = "Exact frame level within the selected strata. Higher levels render above lower levels in the same strata. The stack count text always stays 5 levels above the bar automatically.",
        order = 8.5,
        min = 0,
        max = 200,
        step = 1,
        hidden = function()
          return db.displayMode ~= "realMSW"
        end,
        get = function()
          return (db.realMSWBar and db.realMSWBar.barFrameLevel)
            or (ns.RealMSW.GetBarFrameLevel and ns.RealMSW.GetBarFrameLevel())
            or 1
        end,
        set = function(info, value)
          db.realMSWBar = db.realMSWBar or {}
          db.realMSWBar.barFrameLevel = value
          if ns.RealMSW.UpdateFrameLevel then
            ns.RealMSW.UpdateFrameLevel(value)
          end
        end,
      },
      
      -- More Options button
      moreOptions = {
        type = "execute",
        name = "More Options...",
        desc = function()
          if db.displayMode == "realMSW" then
            return "Open Status Bar Appearance settings for borders, tick marks, and more"
          else
            return "Open Visual Settings for borders, tick marks, gradients, and more"
          end
        end,
        order = 9,
        func = function()
          -- Close and reopen to the appropriate tab
          local AceConfigDialog = LibStub("AceConfigDialog-3.0")
          if db.displayMode == "realMSW" then
            AceConfigDialog:SelectGroup("MWRB", "realMSWAppearance")
          else
            AceConfigDialog:SelectGroup("MWRB", "visual")
          end
        end
      }
    }
  },
  
  -- Stack Text Section (Real MSW text - works for all modes)
    stackText = ns.Options.CreateGroup("Stack Count Text", "Show actual MSW count number", true, 4, {
      enabled = ns.Options.CreateToggleOption(
        "Show Stack Text",
        "Display MSW count as a number (works in all modes)",
        function()
          db.realMSWBar = db.realMSWBar or {}
          return db.realMSWBar.showText ~= false
        end,
        function(value)
          db.realMSWBar = db.realMSWBar or {}
          db.realMSWBar.showText = value
          if ns.RealMSW and ns.RealMSW.UpdateTextAppearance then
            ns.RealMSW.UpdateTextAppearance()
          end
        end
      ),
      
      size = ns.Options.CreateSliderOption(
        "Size",
        "Font size",
        12, 72, 1,
        function()
          db.realMSWBar = db.realMSWBar or {}
          return db.realMSWBar.fontSize or 32
        end,
        function(value)
          db.realMSWBar = db.realMSWBar or {}
          db.realMSWBar.fontSize = value
          if ns.RealMSW and ns.RealMSW.UpdateTextAppearance then
            ns.RealMSW.UpdateTextAppearance()
          end
        end
      ),
      
      color = ns.Options.CreateColorOption(
        "Color",
        "Text color",
        function()
          db.realMSWBar = db.realMSWBar or {}
          return db.realMSWBar.textColor or {r=1, g=1, b=1, a=1}
        end,
        function(color)
          db.realMSWBar = db.realMSWBar or {}
          db.realMSWBar.textColor = color
          if ns.RealMSW and ns.RealMSW.UpdateTextAppearance then
            ns.RealMSW.UpdateTextAppearance()
          end
        end,
        true
      ),
      
      frameStrata = {
        type = "select",
        name = "Frame Strata",
        desc = "Controls what layer the text appears on (higher = on top of more things)",
        order = 10,
        values = {
          ["BACKGROUND"] = "Background (lowest)",
          ["LOW"] = "Low",
          ["MEDIUM"] = "Medium",
          ["HIGH"] = "High",
          ["DIALOG"] = "Dialog",
          ["FULLSCREEN"] = "Fullscreen",
          ["FULLSCREEN_DIALOG"] = "Fullscreen Dialog",
          ["TOOLTIP"] = "Tooltip (highest)"
        },
        sorting = {"BACKGROUND", "LOW", "MEDIUM", "HIGH", "DIALOG", "FULLSCREEN", "FULLSCREEN_DIALOG", "TOOLTIP"},
        get = function()
          db.realMSWBar = db.realMSWBar or {}
          return db.realMSWBar.textFrameStrata or "MEDIUM"
        end,
        set = function(info, value)
          db.realMSWBar = db.realMSWBar or {}
          db.realMSWBar.textFrameStrata = value
          if ns.RealMSW and ns.RealMSW.UpdateTextAppearance then
            ns.RealMSW.UpdateTextAppearance()
          end
        end
      }
    }),
    
    -- Position & Movement Section (works for all modes)
    movable = ns.Options.CreateGroup("Position & Movement", "Positioning settings", true, 5, {
      -- Row 1: Toggles
      movableEnabled = {
        type = "toggle",
        name = "Unlocked",
        desc = "Allow dragging to reposition",
        order = 1,
        get = function()
          if db.displayMode == "realMSW" then
            return db.realMSWBar and db.realMSWBar.barMovable ~= false
          else
            return db.movable ~= false
          end
        end,
        set = function(info, value)
          if db.displayMode == "realMSW" then
            db.realMSWBar = db.realMSWBar or {}
            db.realMSWBar.barMovable = value
            if ns.RealMSW.UpdateMovability then
              ns.RealMSW.UpdateMovability(value, nil)
            end
          else
            db.movable = value
            if ns.API.UpdateMovability then
              ns.API.UpdateMovability()
            end
          end
        end
      },
      
      textMovable = {
        type = "toggle",
        name = "Text Unlocked",
        desc = "Drag text separately",
        order = 2,
        hidden = function()
          return db.displayMode ~= "realMSW"
        end,
        get = function()
          return db.realMSWBar and db.realMSWBar.textMovable ~= false
        end,
        set = function(info, value)
          db.realMSWBar = db.realMSWBar or {}
          db.realMSWBar.textMovable = value
          if ns.RealMSW.UpdateMovability then
            ns.RealMSW.UpdateMovability(nil, value)
          end
        end
      },
      
      hideOutOfCombat = {
        type = "toggle",
        name = "Hide Out of Combat",
        desc = "Hide when not in combat",
        order = 3,
        get = function()
          return db.hideOutOfCombat or false
        end,
        set = function(info, value)
          db.hideOutOfCombat = value
          if ns.API.UpdateCombatVisibility then
            ns.API.UpdateCombatVisibility()
          end
        end
      },
      
      -- Row 2: Exact X/Y position inputs (mode-aware)
      posX = {
        type = "input",
        name = "X Position",
        desc = "Exact horizontal position of the display (offset from screen center)",
        order = 3.2,
        width = "half",
        get = function()
          local x = 0
          if db.displayMode == "realMSW" then
            if ns.RealMSW.GetBarPositionXY then
              x = ns.RealMSW.GetBarPositionXY() or 0
            end
          elseif db.displayMode == "bar" then
            x = db.offsetBarMode and db.offsetBarMode.x or 0
          else
            x = db.offsetIconMode and db.offsetIconMode.x or 0
          end
          return string.format("%.1f", x)
        end,
        set = function(info, value)
          local num = tonumber(value)
          if not num then return end
          
          if db.displayMode == "realMSW" then
            if ns.RealMSW.SetBarPositionXY then
              ns.RealMSW.SetBarPositionXY(num, nil)
            end
          elseif db.displayMode == "bar" then
            db.offsetBarMode = db.offsetBarMode or {point="CENTER", relPoint="CENTER", x=0, y=-100}
            db.offsetBarMode.x = num
            if ns.API.ApplyStatusBarPosition then
              ns.API.ApplyStatusBarPosition()
            end
          else
            db.offsetIconMode = db.offsetIconMode or {point="CENTER", relPoint="CENTER", x=0, y=0}
            db.offsetIconMode.x = num
            if ns.API.ApplyBarFramePosition then
              ns.API.ApplyBarFramePosition()
            end
          end
        end,
        validate = function(info, value)
          if tonumber(value) then return true end
          return "Please enter a number"
        end,
      },
      
      posY = {
        type = "input",
        name = "Y Position",
        desc = "Exact vertical position of the display (offset from screen center)",
        order = 3.3,
        width = "half",
        get = function()
          local y = 0
          if db.displayMode == "realMSW" then
            if ns.RealMSW.GetBarPositionXY then
              local _, posY = ns.RealMSW.GetBarPositionXY()
              y = posY or 0
            end
          elseif db.displayMode == "bar" then
            y = db.offsetBarMode and db.offsetBarMode.y or -100
          else
            y = db.offsetIconMode and db.offsetIconMode.y or 0
          end
          return string.format("%.1f", y)
        end,
        set = function(info, value)
          local num = tonumber(value)
          if not num then return end
          
          if db.displayMode == "realMSW" then
            if ns.RealMSW.SetBarPositionXY then
              ns.RealMSW.SetBarPositionXY(nil, num)
            end
          elseif db.displayMode == "bar" then
            db.offsetBarMode = db.offsetBarMode or {point="CENTER", relPoint="CENTER", x=0, y=-100}
            db.offsetBarMode.y = num
            if ns.API.ApplyStatusBarPosition then
              ns.API.ApplyStatusBarPosition()
            end
          else
            db.offsetIconMode = db.offsetIconMode or {point="CENTER", relPoint="CENTER", x=0, y=0}
            db.offsetIconMode.y = num
            if ns.API.ApplyBarFramePosition then
              ns.API.ApplyBarFramePosition()
            end
          end
        end,
        validate = function(info, value)
          if tonumber(value) then return true end
          return "Please enter a number"
        end,
      },
      
      textPosX = {
        type = "input",
        name = "Text X",
        desc = "Exact horizontal position of the stack count text (offset from screen center)",
        order = 3.4,
        width = "half",
        hidden = function()
          return db.displayMode ~= "realMSW" and not (db.realMSWBar and db.realMSWBar.showText)
        end,
        get = function()
          local x = 0
          if ns.RealMSW.GetTextPositionXY then
            x = ns.RealMSW.GetTextPositionXY() or 0
          end
          return string.format("%.1f", x)
        end,
        set = function(info, value)
          local num = tonumber(value)
          if num and ns.RealMSW.SetTextPositionXY then
            ns.RealMSW.SetTextPositionXY(num, nil)
          end
        end,
        validate = function(info, value)
          if tonumber(value) then return true end
          return "Please enter a number"
        end,
      },
      
      textPosY = {
        type = "input",
        name = "Text Y",
        desc = "Exact vertical position of the stack count text (offset from screen center)",
        order = 3.5,
        width = "half",
        hidden = function()
          return db.displayMode ~= "realMSW" and not (db.realMSWBar and db.realMSWBar.showText)
        end,
        get = function()
          local y = 230
          if ns.RealMSW.GetTextPositionXY then
            local _, posY = ns.RealMSW.GetTextPositionXY()
            y = posY or 230
          end
          return string.format("%.1f", y)
        end,
        set = function(info, value)
          local num = tonumber(value)
          if num and ns.RealMSW.SetTextPositionXY then
            ns.RealMSW.SetTextPositionXY(nil, num)
          end
        end,
        validate = function(info, value)
          if tonumber(value) then return true end
          return "Please enter a number"
        end,
      },
      
      -- Row 2: Reset buttons
      resetPosition = {
        type = "execute",
        name = "Reset Position",
        desc = "Reset to center of screen",
        order = 4,
        func = function()
          if db.displayMode == "realMSW" then
            if ns.RealMSW.ResetBarPosition then
              ns.RealMSW.ResetBarPosition()
            end
          else
            db.offsetIconMode = {point="CENTER", relPoint="CENTER", x=0, y=0}
            db.offsetBarMode = {point="CENTER", relPoint="CENTER", x=0, y=-100}
            if ns.API.RefreshDisplay then
              ns.API.RefreshDisplay()
            end
          end
        end
      },
      
      resetTextPosition = {
        type = "execute",
        name = "Reset Text Position",
        desc = "Reset text position to center of screen",
        order = 5,
        hidden = function()
          return db.displayMode ~= "realMSW"
        end,
        func = function()
          if ns.RealMSW.ResetTextPosition then
            ns.RealMSW.ResetTextPosition()
          end
        end
      }
    }),
    
    -- Preview Controls (for icon modes)
    preview = {
      type = "group",
      name = "Preview",
      desc = "Test the display with different stack counts",
      inline = true,
      order = 6,
      hidden = function()
        return db.displayMode == "realMSW"
      end,
      args = {
        desc = ns.Options.CreateDescription("Use these controls to preview how the display looks at different MSW stack counts"),
        
        enable = ns.Options.CreateToggleOption(
          "Enable Preview",
          "Enter preview mode to test appearance",
          function()
            return db.previewMode or false
          end,
          function(value)
            db.previewMode = value
            if value then
              ns.Options.EnterPreview(5)
            else
              ns.Options.ExitPreview()
            end
          end
        ),
        
        stackCount = ns.Options.CreateSliderOption(
          "Preview Stack Count",
          "Number of stacks to display in preview",
          0, 10, 1,
          function()
            return db.previewStack or 0
          end,
          function(value)
            db.previewStack = value
            if db.previewMode then
              ns.Options.EnterPreview(value)
            end
          end
        )
      }
    }
  }
end

-- ===================================================================
-- END OF MWRB_Options_Main.lua
-- ===================================================================