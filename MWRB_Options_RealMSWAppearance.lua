-- ===================================================================
-- MWRB_Options_RealMSWAppearance.lua
-- Real MSW Bar Appearance Settings - Mode-Aware Edition
-- When in folded mode, settings write to folded-specific keys
-- ===================================================================

-- Class check - Exit if not Shaman
local _, playerClass = UnitClass("player")
if playerClass ~= "SHAMAN" then return end

local ADDON, ns = ...
ns.Options = ns.Options or {}

local function GetDB()
  return ns.API.GetDB()
end

-- Load LibSharedMedia for texture/font dropdowns
local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)

-- ===================================================================
-- HELPER: Check if currently in folded mode
-- ===================================================================
local function IsFoldedMode()
  local db = GetDB()
  return db and db.realMSWBar and db.realMSWBar.displayMode == "folded"
end

-- Helper to get the correct update function based on mode
local function UpdateAppearance()
  if IsFoldedMode() then
    if ns.RealMSW.UpdateFoldedAppearance then
      ns.RealMSW.UpdateFoldedAppearance()
    end
  else
    if ns.RealMSW.UpdateBarAppearance then
      ns.RealMSW.UpdateBarAppearance()
    end
  end
end

-- ===================================================================
-- GET TEXTURE/FONT LISTS
-- ===================================================================
local function GetStatusBarTextures()
  local textures = {
    ["Blizzard"] = "Blizzard",
    ["Blizzard Maelstrom"] = "Blizzard Maelstrom",
    ["Smooth"] = "Smooth",
    ["Blizzard Raid Bar"] = "Blizzard Raid Bar"
  }
  
  if LSM then
    for _, name in pairs(LSM:List("statusbar")) do
      textures[name] = name
    end
  end
  
  return textures
end

local function GetBackgroundTextures()
  local textures = {
    ["Solid"] = "Solid",
    ["None"] = "None"
  }
  
  if LSM then
    for _, name in pairs(LSM:List("background")) do
      textures[name] = name
    end
  end
  
  return textures
end

local function GetFonts()
  local fonts = {
    ["Friz Quadrata TT"] = "Friz Quadrata TT",
    ["Arial Narrow"] = "Arial Narrow"
  }
  
  if LSM then
    for _, name in pairs(LSM:List("font")) do
      fonts[name] = name
    end
  end
  
  return fonts
end

-- ===================================================================
-- REAL MSW APPEARANCE OPTIONS
-- ===================================================================
function ns.Options.GetRealMSWAppearanceOptions()
  local db = GetDB()
  
  return {
    desc = ns.Options.CreateDescription("Customize the appearance of the Status Bar and text display."),
    
    -- BAR STYLE (single or folded)
    barStyleGroup = ns.Options.CreateGroup("Bar Style", nil, true, 0.5, {
      showBar = {
        type = "toggle",
        name = "Show Bar",
        desc = "Display the MSW bar (disable for text-only mode)",
        order = 0,
        get = function()
          return db.realMSWBar and db.realMSWBar.showBar ~= false
        end,
        set = function(info, value)
          db.realMSWBar = db.realMSWBar or {}
          db.realMSWBar.showBar = value
          if ns.RealMSW.Refresh then
            ns.RealMSW.Refresh(true)
          end
        end
      },
      
      displayMode = {
        type = "select",
        name = "Display Style",
        desc = "Choose how the bar displays stacks",
        values = {
          ["single"] = "Single Bar (standard)",
          ["folded"] = "Folded (5+5 stacked)"
        },
        order = 1,
        hidden = function()
          return not (db.realMSWBar and db.realMSWBar.showBar ~= false)
        end,
        get = function()
          return db.realMSWBar and db.realMSWBar.displayMode or "single"
        end,
        set = function(info, value)
          db.realMSWBar = db.realMSWBar or {}
          db.realMSWBar.displayMode = value
          -- Force recreate bar frame to apply new mode
          if ns.RealMSW.Refresh then
            ns.RealMSW.Refresh(true)  -- true = force recreate
          end
        end
      },
      
      foldedNote = {
        type = "description",
        name = "\n|cff00ff00Folded Mode:|r Bottom bar fills for stacks 1-5, top bar fills for stacks 6-10.",
        fontSize = "medium",
        order = 2,
        hidden = function()
          return not IsFoldedMode() or not (db.realMSWBar and db.realMSWBar.showBar ~= false)
        end
      },
      
      foldedStackOrder = {
        type = "select",
        name = "Bar Layer Order",
        desc = "Choose which bar renders in front (both bars are overlaid)",
        order = 2.5,
        hidden = function()
          return not IsFoldedMode() or not (db.realMSWBar and db.realMSWBar.showBar ~= false)
        end,
        values = {
          ["bottom_on_bottom"] = "6-10 Bar in Front",
          ["top_on_bottom"] = "1-5 Bar in Front"
        },
        get = function()
          return db.realMSWBar and db.realMSWBar.foldedStackOrder or "bottom_on_bottom"
        end,
        set = function(info, value)
          db.realMSWBar = db.realMSWBar or {}
          db.realMSWBar.foldedStackOrder = value
          if ns.RealMSW.Refresh then
            ns.RealMSW.Refresh(true)
          end
        end
      },
      
      foldedBottomMovable = {
        type = "toggle",
        name = "Bar Unlocked",
        desc = "Allow dragging the folded bar (both layers move together)",
        order = 3,
        hidden = function()
          return not IsFoldedMode() or not (db.realMSWBar and db.realMSWBar.showBar ~= false)
        end,
        get = function()
          return db.realMSWBar and db.realMSWBar.foldedBottomMovable ~= false
        end,
        set = function(info, value)
          db.realMSWBar = db.realMSWBar or {}
          db.realMSWBar.foldedBottomMovable = value
        end
      },
      
      resetFoldedPositions = {
        type = "execute",
        name = "Reset Position",
        desc = "Reset the folded bar to default position",
        order = 4,
        hidden = function()
          return not IsFoldedMode() or not (db.realMSWBar and db.realMSWBar.showBar ~= false)
        end,
        func = function()
          db.realMSWBar = db.realMSWBar or {}
          db.realMSWBar.foldedBottomPosition = {point="CENTER", relPoint="CENTER", x=0, y=180}
          if ns.RealMSW.Refresh then
            ns.RealMSW.Refresh(true)
          end
        end
      },
    }),
    
    -- BAR SIZE - SINGLE MODE (shown only when NOT in folded mode AND bar is shown)
    barSizeGroup = {
      type = "group",
      name = "Bar Size",
      inline = true,
      order = 1,
      hidden = function()
        return IsFoldedMode() or not (db.realMSWBar and db.realMSWBar.showBar ~= false)
      end,
      args = {
      barScale = {
        type = "range",
        name = "Bar Scale",
        desc = "Scale the entire bar uniformly",
        min = 0.5,
        max = 2.0,
        step = 0.05,
        order = 0,
        get = function()
          return db.realMSWBar and db.realMSWBar.barScale or 1.0
        end,
        set = function(info, value)
          db.realMSWBar = db.realMSWBar or {}
          db.realMSWBar.barScale = value
          UpdateAppearance()
        end
      },
      
      width = {
        type = "range",
        name = "Bar Width",
        desc = "Width of the bar in pixels",
        min = 50,
        max = 500,
        step = 5,
        order = 1,
        get = function()
          return db.realMSWBar and db.realMSWBar.width or 200
        end,
        set = function(info, value)
          db.realMSWBar = db.realMSWBar or {}
          db.realMSWBar.width = value
          UpdateAppearance()
        end
      },
      
      height = {
        type = "range",
        name = "Bar Height",
        desc = "Height of the bar in pixels",
        min = 10,
        max = 100,
        step = 2,
        order = 2,
        get = function()
          return db.realMSWBar and db.realMSWBar.height or 20
        end,
        set = function(info, value)
          db.realMSWBar = db.realMSWBar or {}
          db.realMSWBar.height = value
          UpdateAppearance()
        end
      },
      
      opacity = {
        type = "range",
        name = "Bar Opacity",
        desc = "Transparency of the bar",
        min = 0,
        max = 1,
        step = 0.05,
        order = 3,
        get = function()
          return db.realMSWBar and db.realMSWBar.opacity or 1.0
        end,
        set = function(info, value)
          db.realMSWBar = db.realMSWBar or {}
          db.realMSWBar.opacity = value
          UpdateAppearance()
        end
      },
      
      frameStrata = {
        type = "select",
        name = "Frame Strata",
        desc = "Set the frame strata (layering level) for the status bar. Higher strata appears above other UI elements.",
        order = 4,
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
        set = function(info, value)
          db.realMSWBar = db.realMSWBar or {}
          db.realMSWBar.barFrameStrata = value
          if ns.RealMSW.UpdateFrameStrata then
            ns.RealMSW.UpdateFrameStrata(value)
          end
        end,
      },
    }},
    
    -- FOLDED MODE: UNIFIED BAR SIZE (when individual sizes disabled)
    foldedUnifiedSizeGroup = {
      type = "group",
      name = "Bar Size",
      inline = true,
      order = 1.1,
      hidden = function()
        return not IsFoldedMode() or (db.realMSWBar and db.realMSWBar.foldedIndividualSizes)
      end,
      args = {
        foldedScale = {
          type = "range",
          name = "Scale",
          desc = "Scale both bars uniformly",
          min = 0.5,
          max = 2.0,
          step = 0.05,
          order = 1,
          get = function()
            return db.realMSWBar and db.realMSWBar.foldedBottomScale or 1.0
          end,
          set = function(info, value)
            db.realMSWBar = db.realMSWBar or {}
            db.realMSWBar.foldedBottomScale = value
            db.realMSWBar.foldedTopScale = value
            if ns.RealMSW.UpdateFoldedAppearance then
              ns.RealMSW.UpdateFoldedAppearance()
            end
          end
        },
        
        foldedWidth = {
          type = "range",
          name = "Width",
          desc = "Width of both bars in pixels",
          min = 50,
          max = 500,
          step = 5,
          order = 2,
          get = function()
            return db.realMSWBar and db.realMSWBar.foldedBottomWidth or 200
          end,
          set = function(info, value)
            db.realMSWBar = db.realMSWBar or {}
            db.realMSWBar.foldedBottomWidth = value
            db.realMSWBar.foldedTopWidth = value
            if ns.RealMSW.UpdateFoldedAppearance then
              ns.RealMSW.UpdateFoldedAppearance()
            end
          end
        },
        
        foldedHeight = {
          type = "range",
          name = "Height",
          desc = "Height of both bars in pixels",
          min = 10,
          max = 100,
          step = 2,
          order = 3,
          get = function()
            return db.realMSWBar and db.realMSWBar.foldedBottomHeight or 20
          end,
          set = function(info, value)
            db.realMSWBar = db.realMSWBar or {}
            db.realMSWBar.foldedBottomHeight = value
            db.realMSWBar.foldedTopHeight = value
            if ns.RealMSW.UpdateFoldedAppearance then
              ns.RealMSW.UpdateFoldedAppearance()
            end
          end
        },
        
        foldedOpacity = {
          type = "range",
          name = "Opacity",
          desc = "Transparency of both bars",
          min = 0,
          max = 1,
          step = 0.05,
          order = 4,
          get = function()
            return db.realMSWBar and db.realMSWBar.foldedBottomOpacity or 1.0
          end,
          set = function(info, value)
            db.realMSWBar = db.realMSWBar or {}
            db.realMSWBar.foldedBottomOpacity = value
            db.realMSWBar.foldedTopOpacity = value
            if ns.RealMSW.UpdateFoldedAppearance then
              ns.RealMSW.UpdateFoldedAppearance()
            end
          end
        },
        
        spacer1 = {
          type = "description",
          name = "",
          order = 9
        },
        
        enableIndividualSizes = {
          type = "toggle",
          name = "Individual Bar Sizes",
          desc = "Enable separate size controls for each bar",
          order = 10,
          get = function()
            return db.realMSWBar and db.realMSWBar.foldedIndividualSizes or false
          end,
          set = function(info, value)
            db.realMSWBar = db.realMSWBar or {}
            db.realMSWBar.foldedIndividualSizes = value
          end
        },
      }
    },
    
    -- FOLDED MODE: BAR (1-5) SIZE (when individual sizes enabled)
    foldedBottomSizeGroup = {
      type = "group",
      name = "Bar (1-5) Size",
      inline = true,
      order = 1.2,
      hidden = function()
        return not IsFoldedMode() or not (db.realMSWBar and db.realMSWBar.foldedIndividualSizes)
      end,
      args = {
        foldedBottomScale = {
          type = "range",
          name = "Scale",
          desc = "Scale the 1-5 bar uniformly",
          min = 0.5,
          max = 2.0,
          step = 0.05,
          order = 1,
          get = function()
            return db.realMSWBar and db.realMSWBar.foldedBottomScale or 1.0
          end,
          set = function(info, value)
            db.realMSWBar = db.realMSWBar or {}
            db.realMSWBar.foldedBottomScale = value
            if ns.RealMSW.UpdateFoldedAppearance then
              ns.RealMSW.UpdateFoldedAppearance()
            end
          end
        },
        
        foldedBottomWidth = {
          type = "range",
          name = "Width",
          desc = "Width of the 1-5 bar in pixels",
          min = 50,
          max = 500,
          step = 5,
          order = 2,
          get = function()
            return db.realMSWBar and db.realMSWBar.foldedBottomWidth or 200
          end,
          set = function(info, value)
            db.realMSWBar = db.realMSWBar or {}
            db.realMSWBar.foldedBottomWidth = value
            if ns.RealMSW.UpdateFoldedAppearance then
              ns.RealMSW.UpdateFoldedAppearance()
            end
          end
        },
        
        foldedBottomHeight = {
          type = "range",
          name = "Height",
          desc = "Height of the 1-5 bar in pixels",
          min = 10,
          max = 100,
          step = 2,
          order = 3,
          get = function()
            return db.realMSWBar and db.realMSWBar.foldedBottomHeight or 20
          end,
          set = function(info, value)
            db.realMSWBar = db.realMSWBar or {}
            db.realMSWBar.foldedBottomHeight = value
            if ns.RealMSW.UpdateFoldedAppearance then
              ns.RealMSW.UpdateFoldedAppearance()
            end
          end
        },
        
        foldedBottomOpacity = {
          type = "range",
          name = "Opacity",
          desc = "Transparency of the 1-5 bar",
          min = 0,
          max = 1,
          step = 0.05,
          order = 4,
          get = function()
            return db.realMSWBar and db.realMSWBar.foldedBottomOpacity or 1.0
          end,
          set = function(info, value)
            db.realMSWBar = db.realMSWBar or {}
            db.realMSWBar.foldedBottomOpacity = value
            if ns.RealMSW.UpdateFoldedAppearance then
              ns.RealMSW.UpdateFoldedAppearance()
            end
          end
        },
        
        spacer1 = {
          type = "description",
          name = "",
          order = 9
        },
        
        copyToTop = {
          type = "execute",
          name = "Copy to Bar (6-10)",
          desc = "Copy these size settings to the 6-10 bar",
          order = 10,
          func = function()
            db.realMSWBar = db.realMSWBar or {}
            db.realMSWBar.foldedTopScale = db.realMSWBar.foldedBottomScale or 1.0
            db.realMSWBar.foldedTopWidth = db.realMSWBar.foldedBottomWidth or 200
            db.realMSWBar.foldedTopHeight = db.realMSWBar.foldedBottomHeight or 20
            db.realMSWBar.foldedTopOpacity = db.realMSWBar.foldedBottomOpacity or 1.0
            if ns.RealMSW.UpdateFoldedAppearance then
              ns.RealMSW.UpdateFoldedAppearance()
            end
          end
        },
      }
    },
    
    -- FOLDED MODE: BAR (6-10) SIZE (when individual sizes enabled)
    foldedTopSizeGroup = {
      type = "group",
      name = "Bar (6-10) Size",
      inline = true,
      order = 1.3,
      hidden = function()
        return not IsFoldedMode() or not (db.realMSWBar and db.realMSWBar.foldedIndividualSizes)
      end,
      args = {
        foldedTopScale = {
          type = "range",
          name = "Scale",
          desc = "Scale the 6-10 bar uniformly",
          min = 0.5,
          max = 2.0,
          step = 0.05,
          order = 1,
          get = function()
            return db.realMSWBar and db.realMSWBar.foldedTopScale or 1.0
          end,
          set = function(info, value)
            db.realMSWBar = db.realMSWBar or {}
            db.realMSWBar.foldedTopScale = value
            if ns.RealMSW.UpdateFoldedAppearance then
              ns.RealMSW.UpdateFoldedAppearance()
            end
          end
        },
        
        foldedTopWidth = {
          type = "range",
          name = "Width",
          desc = "Width of the 6-10 bar in pixels",
          min = 50,
          max = 500,
          step = 5,
          order = 2,
          get = function()
            return db.realMSWBar and db.realMSWBar.foldedTopWidth or 200
          end,
          set = function(info, value)
            db.realMSWBar = db.realMSWBar or {}
            db.realMSWBar.foldedTopWidth = value
            if ns.RealMSW.UpdateFoldedAppearance then
              ns.RealMSW.UpdateFoldedAppearance()
            end
          end
        },
        
        foldedTopHeight = {
          type = "range",
          name = "Height",
          desc = "Height of the 6-10 bar in pixels",
          min = 10,
          max = 100,
          step = 2,
          order = 3,
          get = function()
            return db.realMSWBar and db.realMSWBar.foldedTopHeight or 20
          end,
          set = function(info, value)
            db.realMSWBar = db.realMSWBar or {}
            db.realMSWBar.foldedTopHeight = value
            if ns.RealMSW.UpdateFoldedAppearance then
              ns.RealMSW.UpdateFoldedAppearance()
            end
          end
        },
        
        foldedTopOpacity = {
          type = "range",
          name = "Opacity",
          desc = "Transparency of the 6-10 bar",
          min = 0,
          max = 1,
          step = 0.05,
          order = 4,
          get = function()
            return db.realMSWBar and db.realMSWBar.foldedTopOpacity or 1.0
          end,
          set = function(info, value)
            db.realMSWBar = db.realMSWBar or {}
            db.realMSWBar.foldedTopOpacity = value
            if ns.RealMSW.UpdateFoldedAppearance then
              ns.RealMSW.UpdateFoldedAppearance()
            end
          end
        },
        
        spacer1 = {
          type = "description",
          name = "",
          order = 9
        },
        
        copyToBottom = {
          type = "execute",
          name = "Copy to Bar (1-5)",
          desc = "Copy these size settings to the 1-5 bar",
          order = 10,
          func = function()
            db.realMSWBar = db.realMSWBar or {}
            db.realMSWBar.foldedBottomScale = db.realMSWBar.foldedTopScale or 1.0
            db.realMSWBar.foldedBottomWidth = db.realMSWBar.foldedTopWidth or 200
            db.realMSWBar.foldedBottomHeight = db.realMSWBar.foldedTopHeight or 20
            db.realMSWBar.foldedBottomOpacity = db.realMSWBar.foldedTopOpacity or 1.0
            if ns.RealMSW.UpdateFoldedAppearance then
              ns.RealMSW.UpdateFoldedAppearance()
            end
          end
        },
        
        disableIndividualSizes = {
          type = "toggle",
          name = "Individual Bar Sizes",
          desc = "Disable to control both bars with one set of options",
          order = 11,
          get = function()
            return db.realMSWBar and db.realMSWBar.foldedIndividualSizes or false
          end,
          set = function(info, value)
            db.realMSWBar = db.realMSWBar or {}
            db.realMSWBar.foldedIndividualSizes = value
          end
        },
      }
    },
    
    -- FILL SETTINGS (mode-aware) - Colors are here based on display style
    fillGroup = ns.Options.CreateGroup("Fill", nil, true, 2, {
      fillDirection = {
        type = "select",
        name = "Fill Direction",
        desc = "Direction the bar fills as stacks increase",
        values = {
          ["LEFT_TO_RIGHT"] = "Left to Right",
          ["RIGHT_TO_LEFT"] = "Right to Left",
          ["BOTTOM_TO_TOP"] = "Bottom to Top",
          ["TOP_TO_BOTTOM"] = "Top to Bottom"
        },
        order = 1,
        get = function()
          if IsFoldedMode() then
            return db.realMSWBar and db.realMSWBar.foldedFillDirection or "LEFT_TO_RIGHT"
          else
            return db.realMSWBar and db.realMSWBar.fillDirection or "LEFT_TO_RIGHT"
          end
        end,
        set = function(info, value)
          db.realMSWBar = db.realMSWBar or {}
          if IsFoldedMode() then
            db.realMSWBar.foldedFillDirection = value
          else
            db.realMSWBar.fillDirection = value
          end
          UpdateAppearance()
        end
      },
      
      texture = {
        type = "select",
        name = "Bar Texture",
        desc = "Texture style for the bar foreground",
        values = GetStatusBarTextures,
        width = "double",
        order = 2,
        get = function()
          if IsFoldedMode() then
            return db.realMSWBar and db.realMSWBar.foldedTexture or "Blizzard"
          else
            return db.realMSWBar and db.realMSWBar.texture or "Blizzard"
          end
        end,
        set = function(info, value)
          db.realMSWBar = db.realMSWBar or {}
          if IsFoldedMode() then
            db.realMSWBar.foldedTexture = value
          else
            db.realMSWBar.texture = value
          end
          UpdateAppearance()
        end
      },
      
      -- Standard mode: single bar color (shown when NOT in folded mode)
      barColor = {
        type = "color",
        name = "Bar Color",
        desc = "Base color for the bar",
        hasAlpha = true,
        order = 3,
        hidden = function()
          return IsFoldedMode()
        end,
        get = function()
          local c = db.realMSWBar and db.realMSWBar.barColor or {r=0, g=0.5, b=1, a=1}
          return c.r, c.g, c.b, c.a or 1
        end,
        set = function(info, r, g, b, a)
          db.realMSWBar = db.realMSWBar or {}
          db.realMSWBar.barColor = {r=r, g=g, b=b, a=a}
          if ns.RealMSW.UpdateBarAppearance then
            ns.RealMSW.UpdateBarAppearance()
          end
        end
      },
      
      -- Folded mode: bottom bar color (stacks 1-5)
      foldedBottomColor = {
        type = "color",
        name = "Bar Color (1-5)",
        desc = "Color for the bottom bar showing stacks 1-5",
        hasAlpha = true,
        order = 3,
        hidden = function()
          return not IsFoldedMode()
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
      
      -- Folded mode: top bar color (stacks 6-10)
      foldedTopColor = {
        type = "color",
        name = "Bar Color (6-10)",
        desc = "Color for the top bar showing stacks 6-10",
        hasAlpha = true,
        order = 4,
        hidden = function()
          return not IsFoldedMode()
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
    }),
    
    spacer2 = {
      type = "header",
      name = "",
      order = 4.5
    },
    
    -- BACKGROUND - SINGLE BAR MODE (hidden when in folded mode)
    backgroundGroup = {
      type = "group",
      name = "Background",
      inline = true,
      order = 5,
      hidden = function()
        return IsFoldedMode()
      end,
      args = {
      showBackground = {
        type = "toggle",
        name = "Show Background",
        desc = "Display a background behind the bar",
        order = 1,
        get = function()
          return db.realMSWBar and db.realMSWBar.showBackground ~= false
        end,
        set = function(info, value)
          db.realMSWBar = db.realMSWBar or {}
          db.realMSWBar.showBackground = value
          UpdateAppearance()
        end
      },
      
      backgroundTexture = {
        type = "select",
        name = "Background Texture",
        desc = "Texture for the background",
        values = GetBackgroundTextures,
        order = 2,
        get = function()
          return db.realMSWBar and db.realMSWBar.backgroundTexture or "Blizzard Low Health"
        end,
        set = function(info, value)
          db.realMSWBar = db.realMSWBar or {}
          db.realMSWBar.backgroundTexture = value
          UpdateAppearance()
        end
      },
      
      backgroundColor = {
        type = "color",
        name = "Background Color",
        desc = "Color of the bar background",
        hasAlpha = true,
        order = 3,
        get = function()
          local c = db.realMSWBar and db.realMSWBar.backgroundColor or {r=0.2, g=0.2, b=0.2, a=0.8}
          return c.r, c.g, c.b, c.a or 0.8
        end,
        set = function(info, r, g, b, a)
          db.realMSWBar = db.realMSWBar or {}
          db.realMSWBar.backgroundColor = {r=r, g=g, b=b, a=a}
          UpdateAppearance()
        end
      },
    }},
    
    -- BACKGROUND - FOLDED MODE (per-bar controls)
    foldedBackgroundGroup = {
      type = "group",
      name = "Background",
      inline = true,
      order = 5.1,
      hidden = function()
        return not IsFoldedMode()
      end,
      args = {
      -- Bottom bar (1-5) background
      bottomHeader = {
        type = "header",
        name = "Bar (1-5)",
        order = 1
      },
      
      showBackgroundBottom = {
        type = "toggle",
        name = "Show Background",
        desc = "Display a background behind the bottom bar",
        order = 2,
        get = function()
          return db.realMSWBar and db.realMSWBar.foldedBottomShowBackground ~= false
        end,
        set = function(info, value)
          db.realMSWBar = db.realMSWBar or {}
          db.realMSWBar.foldedBottomShowBackground = value
          if ns.RealMSW.UpdateFoldedAppearance then
            ns.RealMSW.UpdateFoldedAppearance()
          end
        end
      },
      
      backgroundTextureBottom = {
        type = "select",
        name = "Texture",
        desc = "Texture for the bottom bar background",
        values = GetBackgroundTextures,
        order = 3,
        get = function()
          return db.realMSWBar and db.realMSWBar.foldedBottomBackgroundTexture or "Solid"
        end,
        set = function(info, value)
          db.realMSWBar = db.realMSWBar or {}
          db.realMSWBar.foldedBottomBackgroundTexture = value
          if ns.RealMSW.UpdateFoldedAppearance then
            ns.RealMSW.UpdateFoldedAppearance()
          end
        end
      },
      
      backgroundColorBottom = {
        type = "color",
        name = "Color",
        desc = "Color of the bottom bar background",
        hasAlpha = true,
        order = 4,
        get = function()
          local c = db.realMSWBar and db.realMSWBar.foldedBottomBackgroundColor or {r=0.2, g=0.2, b=0.2, a=0.8}
          return c.r, c.g, c.b, c.a or 0.8
        end,
        set = function(info, r, g, b, a)
          db.realMSWBar = db.realMSWBar or {}
          db.realMSWBar.foldedBottomBackgroundColor = {r=r, g=g, b=b, a=a}
          if ns.RealMSW.UpdateFoldedAppearance then
            ns.RealMSW.UpdateFoldedAppearance()
          end
        end
      },
      
      -- Top bar (6-10) background
      topHeader = {
        type = "header",
        name = "Bar (6-10)",
        order = 10
      },
      
      showBackgroundTop = {
        type = "toggle",
        name = "Show Background",
        desc = "Display a background behind the top bar",
        order = 11,
        get = function()
          return db.realMSWBar and db.realMSWBar.foldedTopShowBackground ~= false
        end,
        set = function(info, value)
          db.realMSWBar = db.realMSWBar or {}
          db.realMSWBar.foldedTopShowBackground = value
          if ns.RealMSW.UpdateFoldedAppearance then
            ns.RealMSW.UpdateFoldedAppearance()
          end
        end
      },
      
      backgroundTextureTop = {
        type = "select",
        name = "Texture",
        desc = "Texture for the top bar background",
        values = GetBackgroundTextures,
        order = 12,
        get = function()
          return db.realMSWBar and db.realMSWBar.foldedTopBackgroundTexture or "Solid"
        end,
        set = function(info, value)
          db.realMSWBar = db.realMSWBar or {}
          db.realMSWBar.foldedTopBackgroundTexture = value
          if ns.RealMSW.UpdateFoldedAppearance then
            ns.RealMSW.UpdateFoldedAppearance()
          end
        end
      },
      
      backgroundColorTop = {
        type = "color",
        name = "Color",
        desc = "Color of the top bar background",
        hasAlpha = true,
        order = 13,
        get = function()
          local c = db.realMSWBar and db.realMSWBar.foldedTopBackgroundColor or {r=0.2, g=0.2, b=0.2, a=0.8}
          return c.r, c.g, c.b, c.a or 0.8
        end,
        set = function(info, r, g, b, a)
          db.realMSWBar = db.realMSWBar or {}
          db.realMSWBar.foldedTopBackgroundColor = {r=r, g=g, b=b, a=a}
          if ns.RealMSW.UpdateFoldedAppearance then
            ns.RealMSW.UpdateFoldedAppearance()
          end
        end
      },
    }},
    
    -- BORDER - SINGLE BAR MODE (hidden when in folded mode)
    borderGroup = {
      type = "group",
      name = "Border",
      inline = true,
      order = 6,
      hidden = function()
        return IsFoldedMode()
      end,
      args = {
      showBorder = {
        type = "toggle",
        name = "Show Border",
        desc = "Display a border around the bar",
        order = 1,
        get = function()
          return db.realMSWBar and db.realMSWBar.showBorder ~= false
        end,
        set = function(info, value)
          db.realMSWBar = db.realMSWBar or {}
          db.realMSWBar.showBorder = value
          UpdateAppearance()
        end
      },
      
      borderColor = {
        type = "color",
        name = "Border Color",
        desc = "Color of the border",
        hasAlpha = true,
        order = 2,
        get = function()
          local c = db.realMSWBar and db.realMSWBar.borderColor or {r=1, g=1, b=1, a=1}
          return c.r, c.g, c.b, c.a or 1
        end,
        set = function(info, r, g, b, a)
          db.realMSWBar = db.realMSWBar or {}
          db.realMSWBar.borderColor = {r=r, g=g, b=b, a=a}
          UpdateAppearance()
        end
      },
      
      drawnBorderThickness = {
        type = "range",
        name = "Border Thickness",
        desc = "Thickness of border lines",
        min = 1,
        max = 10,
        step = 1,
        order = 3,
        get = function()
          return db.realMSWBar and db.realMSWBar.drawnBorderThickness or 2
        end,
        set = function(info, value)
          db.realMSWBar = db.realMSWBar or {}
          db.realMSWBar.drawnBorderThickness = value
          UpdateAppearance()
        end
      },
    }},
    
    -- BORDER - FOLDED MODE (per-bar controls)
    foldedBorderGroup = {
      type = "group",
      name = "Border",
      inline = true,
      order = 6.1,
      hidden = function()
        return not IsFoldedMode()
      end,
      args = {
      -- Bottom bar (1-5) border
      bottomHeader = {
        type = "header",
        name = "Bar (1-5)",
        order = 1
      },
      
      showBorderBottom = {
        type = "toggle",
        name = "Show Border",
        desc = "Display a border around the bottom bar",
        order = 2,
        get = function()
          return db.realMSWBar and db.realMSWBar.foldedBottomShowBorder ~= false
        end,
        set = function(info, value)
          db.realMSWBar = db.realMSWBar or {}
          db.realMSWBar.foldedBottomShowBorder = value
          if ns.RealMSW.UpdateFoldedAppearance then
            ns.RealMSW.UpdateFoldedAppearance()
          end
        end
      },
      
      borderColorBottom = {
        type = "color",
        name = "Color",
        desc = "Color of the bottom bar border",
        hasAlpha = true,
        order = 3,
        get = function()
          local c = db.realMSWBar and db.realMSWBar.foldedBottomBorderColor or {r=1, g=1, b=1, a=1}
          return c.r, c.g, c.b, c.a or 1
        end,
        set = function(info, r, g, b, a)
          db.realMSWBar = db.realMSWBar or {}
          db.realMSWBar.foldedBottomBorderColor = {r=r, g=g, b=b, a=a}
          if ns.RealMSW.UpdateFoldedAppearance then
            ns.RealMSW.UpdateFoldedAppearance()
          end
        end
      },
      
      borderThicknessBottom = {
        type = "range",
        name = "Thickness",
        desc = "Thickness of the bottom bar border",
        min = 1,
        max = 10,
        step = 1,
        order = 4,
        get = function()
          return db.realMSWBar and db.realMSWBar.foldedBottomBorderThickness or 2
        end,
        set = function(info, value)
          db.realMSWBar = db.realMSWBar or {}
          db.realMSWBar.foldedBottomBorderThickness = value
          if ns.RealMSW.UpdateFoldedAppearance then
            ns.RealMSW.UpdateFoldedAppearance()
          end
        end
      },
      
      -- Top bar (6-10) border
      topHeader = {
        type = "header",
        name = "Bar (6-10)",
        order = 10
      },
      
      showBorderTop = {
        type = "toggle",
        name = "Show Border",
        desc = "Display a border around the top bar",
        order = 11,
        get = function()
          return db.realMSWBar and db.realMSWBar.foldedTopShowBorder ~= false
        end,
        set = function(info, value)
          db.realMSWBar = db.realMSWBar or {}
          db.realMSWBar.foldedTopShowBorder = value
          if ns.RealMSW.UpdateFoldedAppearance then
            ns.RealMSW.UpdateFoldedAppearance()
          end
        end
      },
      
      borderColorTop = {
        type = "color",
        name = "Color",
        desc = "Color of the top bar border",
        hasAlpha = true,
        order = 12,
        get = function()
          local c = db.realMSWBar and db.realMSWBar.foldedTopBorderColor or {r=1, g=1, b=1, a=1}
          return c.r, c.g, c.b, c.a or 1
        end,
        set = function(info, r, g, b, a)
          db.realMSWBar = db.realMSWBar or {}
          db.realMSWBar.foldedTopBorderColor = {r=r, g=g, b=b, a=a}
          if ns.RealMSW.UpdateFoldedAppearance then
            ns.RealMSW.UpdateFoldedAppearance()
          end
        end
      },
      
      borderThicknessTop = {
        type = "range",
        name = "Thickness",
        desc = "Thickness of the top bar border",
        min = 1,
        max = 10,
        step = 1,
        order = 13,
        get = function()
          return db.realMSWBar and db.realMSWBar.foldedTopBorderThickness or 2
        end,
        set = function(info, value)
          db.realMSWBar = db.realMSWBar or {}
          db.realMSWBar.foldedTopBorderThickness = value
          if ns.RealMSW.UpdateFoldedAppearance then
            ns.RealMSW.UpdateFoldedAppearance()
          end
        end
      },
    }},
    
    -- TICK MARKS - SINGLE BAR MODE (shown only when NOT in folded mode)
    tickMarksGroup = {
      type = "group",
      name = "Tick Marks / Dividers",
      inline = true,
      order = 7,
      hidden = function()
        return IsFoldedMode()
      end,
      args = {
      showTickMarks = {
        type = "toggle",
        name = "Show All Tick Marks (1-9)",
        desc = "Display all 9 divider lines on the bar (divides into 10 equal segments)",
        order = 1,
        get = function()
          return db.realMSWBar and db.realMSWBar.showTickMarks or false
        end,
        set = function(info, value)
          db.realMSWBar = db.realMSWBar or {}
          db.realMSWBar.showTickMarks = value
          if value then
            db.realMSWBar.showCustomTicks = false
          end
          if ns.RealMSW.UpdateBarAppearance then
            ns.RealMSW.UpdateBarAppearance()
          end
        end
      },
      
      showCustomTicks = {
        type = "toggle",
        name = "Enable Custom Tick Marks",
        desc = "Show dividers only at specific stack positions you choose",
        order = 2,
        get = function()
          return db.realMSWBar and db.realMSWBar.showCustomTicks or false
        end,
        set = function(info, value)
          db.realMSWBar = db.realMSWBar or {}
          db.realMSWBar.showCustomTicks = value
          if value then
            db.realMSWBar.showTickMarks = false
          end
          if ns.RealMSW.UpdateBarAppearance then
            ns.RealMSW.UpdateBarAppearance()
          end
        end
      },
      
      customTicksInput = {
        type = "input",
        name = "Custom Tick Positions",
        desc = "Enter stack positions separated by commas (e.g., '2,5,8')",
        order = 3,
        width = "full",
        multiline = false,
        hidden = function()
          return not (db.realMSWBar and db.realMSWBar.showCustomTicks)
        end,
        get = function()
          if not db.realMSWBar or not db.realMSWBar.customTicks then
            return ""
          end
          return table.concat(db.realMSWBar.customTicks, ", ")
        end,
        set = function(info, value)
          db.realMSWBar = db.realMSWBar or {}
          db.realMSWBar.customTicks = {}
          
          for numStr in string.gmatch(value, "[^,]+") do
            local num = tonumber(strtrim(numStr))
            if num and num >= 1 and num <= 9 then
              table.insert(db.realMSWBar.customTicks, num)
            end
          end
          
          table.sort(db.realMSWBar.customTicks)
          
          if ns.RealMSW.UpdateBarAppearance then
            ns.RealMSW.UpdateBarAppearance()
          end
        end
      },
      
      spacer1 = {
        type = "header",
        name = "",
        order = 10
      },
      
      tickColor = {
        type = "color",
        name = "Tick Color",
        desc = "Color of the tick mark dividers",
        hasAlpha = true,
        order = 11,
        get = function()
          local c = db.realMSWBar and db.realMSWBar.tickColor or {r=0, g=0, b=0, a=1}
          return c.r, c.g, c.b, c.a or 1
        end,
        set = function(info, r, g, b, a)
          db.realMSWBar = db.realMSWBar or {}
          db.realMSWBar.tickColor = {r=r, g=g, b=b, a=a}
          if ns.RealMSW.UpdateBarAppearance then
            ns.RealMSW.UpdateBarAppearance()
          end
        end
      },
      
      tickThickness = {
        type = "range",
        name = "Tick Thickness",
        desc = "Width of the tick mark lines",
        min = 1,
        max = 10,
        step = 1,
        order = 12,
        get = function()
          return db.realMSWBar and db.realMSWBar.tickThickness or 2
        end,
        set = function(info, value)
          db.realMSWBar = db.realMSWBar or {}
          db.realMSWBar.tickThickness = value
          if ns.RealMSW.UpdateBarAppearance then
            ns.RealMSW.UpdateBarAppearance()
          end
        end
      },
    }},
    
    -- TICK MARKS - FOLDED MODE (shown only in folded mode)
    foldedTickMarksGroup = {
      type = "group",
      name = "Tick Marks / Dividers",
      inline = true,
      order = 7.1,
      hidden = function()
        return not IsFoldedMode()
      end,
      args = {
      foldedTicksDesc = {
        type = "description",
        name = "Choose which bars display tick marks (4 dividers per bar).",
        fontSize = "medium",
        order = 0
      },
      
      foldedTicksBottomEnabled = {
        type = "toggle",
        name = "Show on Bar (1-5)",
        desc = "Display tick marks on the 1-5 bar",
        order = 1,
        get = function()
          return db.realMSWBar and db.realMSWBar.foldedTicksBottomEnabled or false
        end,
        set = function(info, value)
          db.realMSWBar = db.realMSWBar or {}
          db.realMSWBar.foldedTicksBottomEnabled = value
          if ns.RealMSW.UpdateFoldedAppearance then
            ns.RealMSW.UpdateFoldedAppearance()
          end
        end
      },
      
      foldedTicksTopEnabled = {
        type = "toggle",
        name = "Show on Bar (6-10)",
        desc = "Display tick marks on the 6-10 bar",
        order = 2,
        get = function()
          return db.realMSWBar and db.realMSWBar.foldedTicksTopEnabled or false
        end,
        set = function(info, value)
          db.realMSWBar = db.realMSWBar or {}
          db.realMSWBar.foldedTicksTopEnabled = value
          if ns.RealMSW.UpdateFoldedAppearance then
            ns.RealMSW.UpdateFoldedAppearance()
          end
        end
      },
      
      foldedTicksSpacer = {
        type = "header",
        name = "",
        order = 10
      },
      
      foldedTickColor = {
        type = "color",
        name = "Tick Color",
        desc = "Color of the tick mark dividers",
        hasAlpha = true,
        order = 11,
        get = function()
          local c = db.realMSWBar and db.realMSWBar.foldedTickColor or {r=1, g=1, b=1, a=0.8}
          return c.r, c.g, c.b, c.a or 1
        end,
        set = function(info, r, g, b, a)
          db.realMSWBar = db.realMSWBar or {}
          db.realMSWBar.foldedTickColor = {r=r, g=g, b=b, a=a}
          if ns.RealMSW.UpdateFoldedAppearance then
            ns.RealMSW.UpdateFoldedAppearance()
          end
        end
      },
      
      foldedTickThickness = {
        type = "range",
        name = "Tick Thickness",
        desc = "Width of the tick mark lines",
        min = 1,
        max = 10,
        step = 1,
        order = 12,
        get = function()
          return db.realMSWBar and db.realMSWBar.foldedTickThickness or 2
        end,
        set = function(info, value)
          db.realMSWBar = db.realMSWBar or {}
          db.realMSWBar.foldedTickThickness = value
          if ns.RealMSW.UpdateFoldedAppearance then
            ns.RealMSW.UpdateFoldedAppearance()
          end
        end
      },
    }},
    
    -- TEXT SETTINGS (shared between modes)
    textSettingsGroup = ns.Options.CreateGroup("Stack Text", nil, true, 8, {
      showText = ns.Options.CreateToggleOption(
        "Show Stack Text",
        "Display the MSW stack count as a number",
        function()
          return db.realMSWBar and db.realMSWBar.showText ~= false
        end,
        function(value)
          db.realMSWBar = db.realMSWBar or {}
          db.realMSWBar.showText = value
          if ns.RealMSW.UpdateTextAppearance then
            ns.RealMSW.UpdateTextAppearance()
          end
        end
      ),
      
      fontSize = ns.Options.CreateSliderOption(
        "Size",
        "Size of the stack count text",
        12, 72, 1,
        function()
          return db.realMSWBar and db.realMSWBar.fontSize or 32
        end,
        function(value)
          db.realMSWBar = db.realMSWBar or {}
          db.realMSWBar.fontSize = value
          if ns.RealMSW.UpdateTextAppearance then
            ns.RealMSW.UpdateTextAppearance()
          end
        end
      ),
      
      fontFace = ns.Options.CreateSelectOption(
        "Font",
        "Font to use for stack count text",
        GetFonts,
        function()
          return db.realMSWBar and db.realMSWBar.font or "Friz Quadrata TT"
        end,
        function(value)
          db.realMSWBar = db.realMSWBar or {}
          db.realMSWBar.font = value
          if ns.RealMSW.UpdateTextAppearance then
            ns.RealMSW.UpdateTextAppearance()
          end
        end
      ),
      
      textColor = ns.Options.CreateColorOption(
        "Color",
        "Color of the stack count text",
        function()
          return db.realMSWBar and db.realMSWBar.textColor or {r=1, g=1, b=1, a=1}
        end,
        function(color)
          db.realMSWBar = db.realMSWBar or {}
          db.realMSWBar.textColor = color
          if ns.RealMSW.UpdateTextAppearance then
            ns.RealMSW.UpdateTextAppearance()
          end
        end
      ),
    }),
  }
end

-- ===================================================================
-- END OF MWRB_Options_RealMSWAppearance.lua
-- ===================================================================