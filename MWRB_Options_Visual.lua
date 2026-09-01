-- ===================================================================
-- MWRB_Options_Visual.lua
-- Visual Settings tab using AceConfig (per-stack customization)
-- ===================================================================

-- Class check - Exit if not Shaman
local _, playerClass = UnitClass("player")
if playerClass ~= "SHAMAN" then return end

local ADDON, ns = ...
ns.Options = ns.Options or {}

-- Shape options
local SHAPE_OPTIONS = {
  ["circle1"] = "Circle (Style 1)",
  ["circle2"] = "Circle (Style 2)",
  ["circle3"] = "Circle (Solid)",
  ["circle4"] = "Circle (Style 4)",
  ["square"] = "Square",
  ["lightning1"] = "Lightning (Style 1)",
  ["lightning2"] = "Lightning (Gradient)",
  ["lightning3"] = "Lightning (Old)"
}

-- Track preview
local activePreview = nil

-- Hook ColorPickerFrame
local function SetupColorPickerHook()
  if ColorPickerFrame.mwrbHooked then return end
  ColorPickerFrame.mwrbHooked = true
  
  ColorPickerFrame:HookScript("OnHide", function()
    if activePreview ~= nil then
      activePreview = nil
      -- Get real MSW and restore display
      local realCount = (ns.API.GetMSWCount and ns.API.GetMSWCount()) or 0
      if ns.API.ForceDisplayUpdate then
        ns.API.ForceDisplayUpdate(realCount)
      end
    end
  end)
end

C_Timer.After(0.5, SetupColorPickerHook)

-- ===================================================================
-- VISUAL SETTINGS TAB OPTIONS
-- ===================================================================
function ns.Options.GetVisualTabOptions()
  local db = ns.API.GetDB and ns.API.GetDB()
  if not db then
    return {desc = {type = "description", name = "Loading...", fontSize = "medium", order = 0}}
  end
  
  local options = {
    desc = {
      type = "description",
      name = "Customize the appearance of individual MSW stack icons",
      fontSize = "medium",
      order = 0
    },
    
    -- Bar Mode Colors (shown only in bar mode)
    barColors = {
      type = "group",
      name = "Bar Mode - Colors",
      desc = "Configure bar colors based on stack count",
      inline = true,
      order = 0.5,
      hidden = function() return db.displayMode ~= "bar" end,
      args = {
        -- BAR FILL COLOR SECTION
        fillColorHeader = {
          type = "header",
          name = "Bar Fill Color",
          order = 1
        },
        
        fillColor = {
          type = "color",
          name = "Fill Color",
          desc = "Base bar color (used when gradient is disabled, or below all gradient thresholds)",
          hasAlpha = true,
          order = 2,
          width = "full",
          get = function()
            -- Show preview when color picker opens
            if ColorPickerFrame:IsShown() and activePreview == nil then
              activePreview = 10
              if ns.API.ForceDisplayUpdate then ns.API.ForceDisplayUpdate(10) end
            end
            local color = db.barMode and db.barMode.colorSingle or {r=0.024, g=0, b=1, a=1}
            if not color or type(color) ~= "table" then
              color = {r=0.024, g=0, b=1, a=1}
            end
            return color.r or 0.024, color.g or 0, color.b or 1, color.a or 1
          end,
          set = function(info, r, g, b, a)
            db.barMode = db.barMode or {}
            db.barMode.colorSingle = {r=r, g=g, b=b, a=a}
            -- Live preview during color picking
            activePreview = 10
            if ns.API.RefreshDisplay then
              ns.API.RefreshDisplay()
            end
            if ns.API.ForceDisplayUpdate then
              ns.API.ForceDisplayUpdate(10)
            end
          end
        },
        
        useGradient = {
          type = "toggle",
          name = "Use Color Gradient",
          desc = "Enable gradient coloring based on stack ranges (low/mid/high)",
          order = 3,
          get = function()
            return db.barMode and db.barMode.useGradient ~= false
          end,
          set = function(info, value)
            db.barMode = db.barMode or {}
            db.barMode.useGradient = value
            if ns.API.RefreshDisplay then
              ns.API.RefreshDisplay()
            end
          end
        },
        
        spacer1 = {
          type = "header",
          name = "",
          order = 8,
          hidden = function()
            return not (db.barMode and db.barMode.useGradient ~= false)
          end
        },
      
      -- GRADIENT 1
      lowRangeHeader = {
        type = "header",
        name = "Gradient 1",
        order = 10,
        hidden = function()
          return not (db.barMode and db.barMode.useGradient ~= false)
        end
      },
      
      lowEnabled = {
        type = "toggle",
        name = "Gradient 1",
        desc = "Enable first gradient color threshold",
        order = 11,
        hidden = function()
          return not (db.barMode and db.barMode.useGradient ~= false)
        end,
        get = function()
          return db.barMode and db.barMode.colorRanges and db.barMode.colorRanges.low and db.barMode.colorRanges.low.enabled ~= false
        end,
        set = function(info, value)
          db.barMode = db.barMode or {}
          db.barMode.colorRanges = db.barMode.colorRanges or {}
          db.barMode.colorRanges.low = db.barMode.colorRanges.low or {maxStacks=4, color={r=0.024, g=0, b=1, a=1}}
          db.barMode.colorRanges.low.enabled = value
          if ns.API.RefreshDisplay then
            ns.API.RefreshDisplay()
          end
        end
      },
      
      lowMaxStacks = {
        type = "input",
        name = "At Stacks",
        desc = "Use this gradient color starting at X stacks (base fill color used below this)",
        order = 12,
        width = "normal",
        get = function()
          return tostring(db.barMode and db.barMode.colorRanges and db.barMode.colorRanges.low and db.barMode.colorRanges.low.maxStacks or 1)
        end,
        set = function(info, value)
          local num = tonumber(value)
          if num and num >= 0 and num <= 10 then
            db.barMode = db.barMode or {}
            db.barMode.colorRanges = db.barMode.colorRanges or {}
            db.barMode.colorRanges.low = db.barMode.colorRanges.low or {enabled=true, color={r=0.024, g=0, b=1, a=1}}
            db.barMode.colorRanges.low.maxStacks = math.floor(num)
            if ns.API.RefreshDisplay then
              ns.API.RefreshDisplay()
            end
          else
            print("|cff00ccffMWRB|r |cffff0000ERROR:|r Stack value must be between 0 and 10")
          end
        end,
        hidden = function()
          return not (db.barMode and db.barMode.useGradient ~= false and db.barMode.colorRanges and db.barMode.colorRanges.low and db.barMode.colorRanges.low.enabled ~= false)
        end
      },
      
      lowColor = {
        type = "color",
        name = "Color",
        desc = "Bar color when reaching this stack threshold",
        hasAlpha = true,
        order = 13,
        width = "full",
        hidden = function()
          return not (db.barMode and db.barMode.useGradient ~= false and db.barMode.colorRanges and db.barMode.colorRanges.low and db.barMode.colorRanges.low.enabled ~= false)
        end,
        get = function()
          -- Show preview when color picker opens
          if ColorPickerFrame:IsShown() and activePreview == nil then
            activePreview = 10
            if ns.API.ForceDisplayUpdate then ns.API.ForceDisplayUpdate(10) end
          end
          local color = db.barMode and db.barMode.colorRanges and db.barMode.colorRanges.low and db.barMode.colorRanges.low.color or {r=0.024, g=0, b=1, a=1}
          if not color or type(color) ~= "table" then
            color = {r=0.024, g=0, b=1, a=1}
          end
          return color.r or 0, color.g or 0, color.b or 1, color.a or 1
        end,
        set = function(info, r, g, b, a)
          db.barMode = db.barMode or {}
          db.barMode.colorRanges = db.barMode.colorRanges or {}
          db.barMode.colorRanges.low = db.barMode.colorRanges.low or {enabled=true, maxStacks=4}
          db.barMode.colorRanges.low.color = {r=r, g=g, b=b, a=a}
          -- Live preview during color picking
          activePreview = 10
          if ns.API.RefreshDisplay then
            ns.API.RefreshDisplay()
          end
          if ns.API.ForceDisplayUpdate then
            ns.API.ForceDisplayUpdate(10)
          end
        end
      },
      
      spacer2 = {
        type = "header",
        name = "",
        order = 19,
        hidden = function()
          return not (db.barMode and db.barMode.useGradient ~= false)
        end
      },
      
      -- GRADIENT 2
      midRangeHeader = {
        type = "header",
        name = "Gradient 2",
        order = 20,
        hidden = function()
          return not (db.barMode and db.barMode.useGradient ~= false)
        end
      },
      
      midEnabled = {
        type = "toggle",
        name = "Gradient 2",
        desc = "Enable second gradient color threshold",
        order = 21,
        hidden = function()
          return not (db.barMode and db.barMode.useGradient ~= false)
        end,
        get = function()
          return db.barMode and db.barMode.colorRanges and db.barMode.colorRanges.mid and db.barMode.colorRanges.mid.enabled ~= false
        end,
        set = function(info, value)
          db.barMode = db.barMode or {}
          db.barMode.colorRanges = db.barMode.colorRanges or {}
          db.barMode.colorRanges.mid = db.barMode.colorRanges.mid or {maxStacks=9, color={r=1, g=0.761, b=0.051, a=1}}
          db.barMode.colorRanges.mid.enabled = value
          if ns.API.RefreshDisplay then
            ns.API.RefreshDisplay()
          end
        end
      },
      
      midMaxStacks = {
        type = "input",
        name = "At Stacks",
        desc = "Use this gradient color starting at X stacks (overrides previous gradients)",
        order = 22,
        width = "normal",
        hidden = function()
          return not (db.barMode and db.barMode.useGradient ~= false and db.barMode.colorRanges and db.barMode.colorRanges.mid and db.barMode.colorRanges.mid.enabled ~= false)
        end,
        get = function()
          return tostring(db.barMode and db.barMode.colorRanges and db.barMode.colorRanges.mid and db.barMode.colorRanges.mid.maxStacks or 5)
        end,
        set = function(info, value)
          local num = tonumber(value)
          if num and num >= 0 and num <= 10 then
            db.barMode = db.barMode or {}
            db.barMode.colorRanges = db.barMode.colorRanges or {}
            db.barMode.colorRanges.mid = db.barMode.colorRanges.mid or {enabled=true, color={r=1, g=0.761, b=0.051, a=1}}
            db.barMode.colorRanges.mid.maxStacks = math.floor(num)
            if ns.API.RefreshDisplay then
              ns.API.RefreshDisplay()
            end
          else
            print("|cff00ccffMWRB|r |cffff0000ERROR:|r Stack value must be between 0 and 10")
          end
        end
      },
      
      midColor = {
        type = "color",
        name = "Color",
        desc = "Bar color when reaching this stack threshold",
        hasAlpha = true,
        order = 23,
        width = "full",
        hidden = function()
          return not (db.barMode and db.barMode.useGradient ~= false and db.barMode.colorRanges and db.barMode.colorRanges.mid and db.barMode.colorRanges.mid.enabled ~= false)
        end,
        get = function()
          -- Show preview when color picker opens
          if ColorPickerFrame:IsShown() and activePreview == nil then
            activePreview = 10
            if ns.API.ForceDisplayUpdate then ns.API.ForceDisplayUpdate(10) end
          end
          local color = db.barMode and db.barMode.colorRanges and db.barMode.colorRanges.mid and db.barMode.colorRanges.mid.color or {r=1, g=0.761, b=0.051, a=1}
          if not color or type(color) ~= "table" then
            color = {r=1, g=0.761, b=0.051, a=1}
          end
          return color.r or 1, color.g or 0.761, color.b or 0.051, color.a or 1
        end,
        set = function(info, r, g, b, a)
          db.barMode = db.barMode or {}
          db.barMode.colorRanges = db.barMode.colorRanges or {}
          db.barMode.colorRanges.mid = db.barMode.colorRanges.mid or {enabled=true, maxStacks=9}
          db.barMode.colorRanges.mid.color = {r=r, g=g, b=b, a=a}
          -- Live preview during color picking
          activePreview = 10
          if ns.API.RefreshDisplay then
            ns.API.RefreshDisplay()
          end
          if ns.API.ForceDisplayUpdate then
            ns.API.ForceDisplayUpdate(10)
          end
        end
      },
      
      spacer3 = {
        type = "header",
        name = "",
        order = 29,
        hidden = function()
          return not (db.barMode and db.barMode.useGradient ~= false)
        end
      },
      
      -- GRADIENT 3
      highRangeHeader = {
        type = "header",
        name = "Gradient 3",
        order = 30,
        hidden = function()
          return not (db.barMode and db.barMode.useGradient ~= false)
        end
      },
      
      highEnabled = {
        type = "toggle",
        name = "Gradient 3",
        desc = "Enable third gradient color threshold",
        order = 31,
        hidden = function()
          return not (db.barMode and db.barMode.useGradient ~= false)
        end,
        get = function()
          return db.barMode and db.barMode.colorRanges and db.barMode.colorRanges.high and db.barMode.colorRanges.high.enabled ~= false
        end,
        set = function(info, value)
          db.barMode = db.barMode or {}
          db.barMode.colorRanges = db.barMode.colorRanges or {}
          db.barMode.colorRanges.high = db.barMode.colorRanges.high or {maxStacks=10, color={r=0.875, g=0, b=1, a=1}}
          db.barMode.colorRanges.high.enabled = value
          if ns.API.RefreshDisplay then
            ns.API.RefreshDisplay()
          end
        end
      },
      
      highMaxStacks = {
        type = "input",
        name = "At Stacks",
        desc = "Use this gradient color starting at X stacks (overrides previous gradients)",
        order = 32,
        width = "normal",
        hidden = function()
          return not (db.barMode and db.barMode.useGradient ~= false and db.barMode.colorRanges and db.barMode.colorRanges.high and db.barMode.colorRanges.high.enabled ~= false)
        end,
        get = function()
          return tostring(db.barMode and db.barMode.colorRanges and db.barMode.colorRanges.high and db.barMode.colorRanges.high.maxStacks or 10)
        end,
        set = function(info, value)
          local num = tonumber(value)
          if num and num >= 0 and num <= 10 then
            db.barMode = db.barMode or {}
            db.barMode.colorRanges = db.barMode.colorRanges or {}
            db.barMode.colorRanges.high = db.barMode.colorRanges.high or {enabled=true, color={r=0.875, g=0, b=1, a=1}}
            db.barMode.colorRanges.high.maxStacks = math.floor(num)
            if ns.API.RefreshDisplay then
              ns.API.RefreshDisplay()
            end
          else
            print("|cff00ccffMWRB|r |cffff0000ERROR:|r Stack value must be between 0 and 10")
          end
        end
      },
      
      highColor = {
        type = "color",
        name = "Color",
        desc = "Bar color when reaching this stack threshold",
        hasAlpha = true,
        order = 33,
        width = "full",
        hidden = function()
          return not (db.barMode and db.barMode.useGradient ~= false and db.barMode.colorRanges and db.barMode.colorRanges.high and db.barMode.colorRanges.high.enabled ~= false)
        end,
        get = function()
          -- Show preview when color picker opens
          if ColorPickerFrame:IsShown() and activePreview == nil then
            activePreview = 10
            if ns.API.ForceDisplayUpdate then ns.API.ForceDisplayUpdate(10) end
          end
          local color = db.barMode and db.barMode.colorRanges and db.barMode.colorRanges.high and db.barMode.colorRanges.high.color or {r=0.875, g=0, b=1, a=1}
          if not color or type(color) ~= "table" then
            color = {r=0.875, g=0, b=1, a=1}
          end
          return color.r or 0.875, color.g or 0, color.b or 1, color.a or 1
        end,
        set = function(info, r, g, b, a)
          db.barMode = db.barMode or {}
          db.barMode.colorRanges = db.barMode.colorRanges or {}
          db.barMode.colorRanges.high = db.barMode.colorRanges.high or {enabled=true, maxStacks=10}
          db.barMode.colorRanges.high.color = {r=r, g=g, b=b, a=a}
          -- Live preview during color picking
          activePreview = 10
          if ns.API.RefreshDisplay then
            ns.API.RefreshDisplay()
          end
          if ns.API.ForceDisplayUpdate then
            ns.API.ForceDisplayUpdate(10)
          end
        end
      },
      
      spacer4 = {
        type = "header",
        name = "",
        order = 39
      },
      
      -- BACKGROUND COLOR
      backgroundHeader = {
        type = "header",
        name = "Background & Border",
        order = 40
      },
      
      showBackground = {
        type = "toggle",
        name = "Show Background",
        desc = "Display a background behind the bar",
        order = 41,
        get = function()
          return db.barMode and db.barMode.showBackground ~= false
        end,
        set = function(info, value)
          db.barMode = db.barMode or {}
          db.barMode.showBackground = value
          if ns.API.RefreshDisplay then
            ns.API.RefreshDisplay()
          end
        end
      },
      
      backgroundColor = {
        type = "color",
        name = "Background Color",
        desc = "Color of the bar background",
        hasAlpha = true,
        order = 42,
        width = "full",
        hidden = function()
          return not (db.barMode and db.barMode.showBackground ~= false)
        end,
        get = function()
          local color = db.barMode and db.barMode.backgroundColor or {r=0.2, g=0.2, b=0.2, a=0.8}
          if not color or type(color) ~= "table" then
            color = {r=0.2, g=0.2, b=0.2, a=0.8}
          end
          return color.r or 0.2, color.g or 0.2, color.b or 0.2, color.a or 0.8
        end,
        set = function(info, r, g, b, a)
          db.barMode = db.barMode or {}
          db.barMode.backgroundColor = {r=r, g=g, b=b, a=a}
          if ns.API.RefreshDisplay then
            ns.API.RefreshDisplay()
          end
        end
      },
      
      showBorder = {
        type = "toggle",
        name = "Show Border",
        desc = "Display a border around the bar",
        order = 43,
        get = function()
          return db.barMode and db.barMode.showBorder ~= false
        end,
        set = function(info, value)
          db.barMode = db.barMode or {}
          db.barMode.showBorder = value
          if ns.API.RefreshDisplay then
            ns.API.RefreshDisplay()
          end
        end
      },
      
      borderColor = {
        type = "color",
        name = "Border Color",
        desc = "Color of the bar border",
        hasAlpha = true,
        order = 44,
        width = "full",
        hidden = function()
          return not (db.barMode and db.barMode.showBorder ~= false)
        end,
        get = function()
          local color = db.barMode and db.barMode.borderColor or {r=0, g=0, b=0, a=1}
          if not color or type(color) ~= "table" then color = {r=0, g=0, b=0, a=1} end
          return color.r or 0, color.g or 0, color.b or 0, color.a or 1
        end,
        set = function(info, r, g, b, a)
          db.barMode = db.barMode or {}
          db.barMode.borderColor = {r=r, g=g, b=b, a=a}
          if ns.API.RefreshDisplay then
            ns.API.RefreshDisplay()
          end
        end
      }
    }
  },
  
  -- Bar Mode Tick Marks (shown only in bar mode)
  barTickMarks = {
    type = "group",
    name = "Bar Mode - Tick Marks / Dividers",
    desc = "Add vertical divider lines to segment the bar at specific stack positions",
    inline = true,
    order = 0.6,
    hidden = function() return db.displayMode ~= "bar" end,
    args = {
      showTickMarks = {
        type = "toggle",
        name = "Show All Tick Marks (1-9)",
        desc = "Display all 9 divider lines on the bar (divides into 10 equal segments)",
        order = 1,
        width = "full",
        get = function()
          return db.barMode and db.barMode.showTickMarks or false
        end,
        set = function(info, value)
          db.barMode = db.barMode or {}
          db.barMode.showTickMarks = value
          -- Disable custom ticks if enabling all ticks
          if value then
            db.barMode.showCustomTicks = false
          end
          if ns.API.ApplyLayout then
            ns.API.ApplyLayout()
          end
        end
      },
      
      spacer1 = {
        type = "header",
        name = "Custom Tick Marks",
        order = 5
      },
      
      showCustomTicks = {
        type = "toggle",
        name = "Enable Custom Tick Marks",
        desc = "Show dividers only at specific stack positions you choose",
        order = 6,
        width = "full",
        get = function()
          return db.barMode and db.barMode.showCustomTicks or false
        end,
        set = function(info, value)
          db.barMode = db.barMode or {}
          db.barMode.showCustomTicks = value
          -- Disable all ticks if enabling custom ticks
          if value then
            db.barMode.showTickMarks = false
          end
          if ns.API.ApplyLayout then
            ns.API.ApplyLayout()
          end
        end
      },
      
      customTicksInput = {
        type = "input",
        name = "Custom Tick Positions",
        desc = "Enter stack positions separated by commas (e.g., '2,5,8' for dividers after stacks 2, 5, and 8)",
        order = 7,
        width = "full",
        multiline = false,
        hidden = function()
          return not (db.barMode and db.barMode.showCustomTicks)
        end,
        get = function()
          if not db.barMode or not db.barMode.customTicks then
            return ""
          end
          return table.concat(db.barMode.customTicks, ", ")
        end,
        set = function(info, value)
          db.barMode = db.barMode or {}
          db.barMode.customTicks = {}
          
          -- Parse comma-separated values
          for numStr in string.gmatch(value, "[^,]+") do
            local num = tonumber(strtrim(numStr))
            if num and num >= 1 and num <= 9 then
              table.insert(db.barMode.customTicks, num)
            end
          end
          
          -- Sort the ticks
          table.sort(db.barMode.customTicks)
          
          if ns.API.ApplyLayout then
            ns.API.ApplyLayout()
          end
        end
      },
      
      customTicksExample = {
        type = "description",
        name = "|cffaaaaaa Examples:\n  '5' = One divider after stack 5\n  '2, 5, 8' = Three dividers at stacks 2, 5, and 8\n  '3, 6' = Two dividers at stacks 3 and 6|r",
        fontSize = "medium",
        order = 8,
        hidden = function()
          return not (db.barMode and db.barMode.showCustomTicks)
        end
      },
      
      spacer2 = {
        type = "header",
        name = "Tick Appearance",
        order = 10
      },
      
      tickColor = {
        type = "color",
        name = "Tick Color",
        desc = "Color of the tick mark dividers",
        hasAlpha = true,
        order = 11,
        width = "full",
        hidden = function()
          return not (db.barMode and (db.barMode.showTickMarks or db.barMode.showCustomTicks))
        end,
        get = function()
          local color = db.barMode and db.barMode.tickColor or {r=0, g=0, b=0, a=1}
          if not color or type(color) ~= "table" then color = {r=0, g=0, b=0, a=1} end
          return color.r or 0, color.g or 0, color.b or 0, color.a or 1
        end,
        set = function(info, r, g, b, a)
          db.barMode = db.barMode or {}
          db.barMode.tickColor = {r=r, g=g, b=b, a=a}
          if ns.API.ApplyLayout then
            ns.API.ApplyLayout()
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
        width = "full",
        hidden = function()
          return not (db.barMode and (db.barMode.showTickMarks or db.barMode.showCustomTicks))
        end,
        get = function()
          return db.barMode and db.barMode.tickThickness or 2
        end,
        set = function(info, value)
          db.barMode = db.barMode or {}
          db.barMode.tickThickness = value
          if ns.API.ApplyLayout then
            ns.API.ApplyLayout()
          end
        end
      },
      
      useIndividualTickColors = {
        type = "toggle",
        name = "Individual Tick Colors",
        desc = "Enable custom colors for each tick mark (overrides global tick color)",
        order = 13,
        width = "full",
        hidden = function()
          return not (db.barMode and (db.barMode.showTickMarks or db.barMode.showCustomTicks))
        end,
        get = function()
          return db.barMode and db.barMode.useIndividualTickColors or false
        end,
        set = function(info, value)
          db.barMode = db.barMode or {}
          db.barMode.useIndividualTickColors = value
          
          -- Initialize tickColors if not present
          if value and not db.barMode.tickColors then
            db.barMode.tickColors = {}
            for i = 1, 9 do
              db.barMode.tickColors[i] = {r=0, g=0, b=0, a=1}
            end
          end
          
          if ns.API.ApplyLayout then
            ns.API.ApplyLayout()
          end
        end
      },
      
      tickColorsHeader = {
        type = "header",
        name = "Individual Tick Mark Colors",
        order = 14,
        hidden = function()
          return not (db.barMode and db.barMode.useIndividualTickColors and (db.barMode.showTickMarks or db.barMode.showCustomTicks))
        end
      },
      
      tickColor1 = {
        type = "color",
        name = "Tick 1 (at 1 stack)",
        desc = "Color for the first tick mark",
        hasAlpha = true,
        order = 15,
        width = "full",
        hidden = function()
          if not (db.barMode and db.barMode.useIndividualTickColors) then return true end
          if db.barMode.showTickMarks then return false end
          if db.barMode.showCustomTicks and db.barMode.customTicks then
            for _, tickPos in ipairs(db.barMode.customTicks) do
              if tickPos == 1 then return false end
            end
          end
          return true
        end,
        get = function()
          local color = db.barMode and db.barMode.tickColors and db.barMode.tickColors[1] or {r=0, g=0, b=0, a=1}
          if not color or type(color) ~= "table" then color = {r=0, g=0, b=0, a=1} end
          return color.r or 0, color.g or 0, color.b or 0, color.a or 1
        end,
        set = function(info, r, g, b, a)
          db.barMode = db.barMode or {}
          db.barMode.tickColors = db.barMode.tickColors or {}
          db.barMode.tickColors[1] = {r=r, g=g, b=b, a=a}
          if ns.API.ApplyLayout then ns.API.ApplyLayout() end
        end
      },
      
      tickColor2 = {
        type = "color",
        name = "Tick 2 (at 2 stacks)",
        desc = "Color for the second tick mark",
        hasAlpha = true,
        order = 16,
        width = "full",
        hidden = function()
          if not (db.barMode and db.barMode.useIndividualTickColors) then return true end
          if db.barMode.showTickMarks then return false end
          if db.barMode.showCustomTicks and db.barMode.customTicks then
            for _, tickPos in ipairs(db.barMode.customTicks) do
              if tickPos == 2 then return false end
            end
          end
          return true
        end,
        get = function()
          local color = db.barMode and db.barMode.tickColors and db.barMode.tickColors[2] or {r=0, g=0, b=0, a=1}
          if not color or type(color) ~= "table" then color = {r=0, g=0, b=0, a=1} end
          return color.r or 0, color.g or 0, color.b or 0, color.a or 1
        end,
        set = function(info, r, g, b, a)
          db.barMode = db.barMode or {}
          db.barMode.tickColors = db.barMode.tickColors or {}
          db.barMode.tickColors[2] = {r=r, g=g, b=b, a=a}
          if ns.API.ApplyLayout then ns.API.ApplyLayout() end
        end
      },
      
      tickColor3 = {
        type = "color",
        name = "Tick 3 (at 3 stacks)",
        desc = "Color for the third tick mark",
        hasAlpha = true,
        order = 17,
        width = "full",
        hidden = function()
          if not (db.barMode and db.barMode.useIndividualTickColors) then return true end
          if db.barMode.showTickMarks then return false end
          if db.barMode.showCustomTicks and db.barMode.customTicks then
            for _, tickPos in ipairs(db.barMode.customTicks) do
              if tickPos == 3 then return false end
            end
          end
          return true
        end,
        get = function()
          local color = db.barMode and db.barMode.tickColors and db.barMode.tickColors[3] or {r=0, g=0, b=0, a=1}
          if not color or type(color) ~= "table" then color = {r=0, g=0, b=0, a=1} end
          return color.r or 0, color.g or 0, color.b or 0, color.a or 1
        end,
        set = function(info, r, g, b, a)
          db.barMode = db.barMode or {}
          db.barMode.tickColors = db.barMode.tickColors or {}
          db.barMode.tickColors[3] = {r=r, g=g, b=b, a=a}
          if ns.API.ApplyLayout then ns.API.ApplyLayout() end
        end
      },
      
      tickColor4 = {
        type = "color",
        name = "Tick 4 (at 4 stacks)",
        desc = "Color for the fourth tick mark",
        hasAlpha = true,
        order = 18,
        width = "full",
        hidden = function()
          if not (db.barMode and db.barMode.useIndividualTickColors) then return true end
          if db.barMode.showTickMarks then return false end
          if db.barMode.showCustomTicks and db.barMode.customTicks then
            for _, tickPos in ipairs(db.barMode.customTicks) do
              if tickPos == 4 then return false end
            end
          end
          return true
        end,
        get = function()
          local color = db.barMode and db.barMode.tickColors and db.barMode.tickColors[4] or {r=0, g=0, b=0, a=1}
          if not color or type(color) ~= "table" then color = {r=0, g=0, b=0, a=1} end
          return color.r or 0, color.g or 0, color.b or 0, color.a or 1
        end,
        set = function(info, r, g, b, a)
          db.barMode = db.barMode or {}
          db.barMode.tickColors = db.barMode.tickColors or {}
          db.barMode.tickColors[4] = {r=r, g=g, b=b, a=a}
          if ns.API.ApplyLayout then ns.API.ApplyLayout() end
        end
      },
      
      tickColor5 = {
        type = "color",
        name = "Tick 5 (at 5 stacks)",
        desc = "Color for the fifth tick mark",
        hasAlpha = true,
        order = 19,
        width = "full",
        hidden = function()
          if not (db.barMode and db.barMode.useIndividualTickColors) then return true end
          if db.barMode.showTickMarks then return false end
          if db.barMode.showCustomTicks and db.barMode.customTicks then
            for _, tickPos in ipairs(db.barMode.customTicks) do
              if tickPos == 5 then return false end
            end
          end
          return true
        end,
        get = function()
          local color = db.barMode and db.barMode.tickColors and db.barMode.tickColors[5] or {r=0, g=0, b=0, a=1}
          if not color or type(color) ~= "table" then color = {r=0, g=0, b=0, a=1} end
          return color.r or 0, color.g or 0, color.b or 0, color.a or 1
        end,
        set = function(info, r, g, b, a)
          db.barMode = db.barMode or {}
          db.barMode.tickColors = db.barMode.tickColors or {}
          db.barMode.tickColors[5] = {r=r, g=g, b=b, a=a}
          if ns.API.ApplyLayout then ns.API.ApplyLayout() end
        end
      },
      
      tickColor6 = {
        type = "color",
        name = "Tick 6 (at 6 stacks)",
        desc = "Color for the sixth tick mark",
        hasAlpha = true,
        order = 20,
        width = "full",
        hidden = function()
          if not (db.barMode and db.barMode.useIndividualTickColors) then return true end
          if db.barMode.showTickMarks then return false end
          if db.barMode.showCustomTicks and db.barMode.customTicks then
            for _, tickPos in ipairs(db.barMode.customTicks) do
              if tickPos == 6 then return false end
            end
          end
          return true
        end,
        get = function()
          local color = db.barMode and db.barMode.tickColors and db.barMode.tickColors[6] or {r=0, g=0, b=0, a=1}
          if not color or type(color) ~= "table" then color = {r=0, g=0, b=0, a=1} end
          return color.r or 0, color.g or 0, color.b or 0, color.a or 1
        end,
        set = function(info, r, g, b, a)
          db.barMode = db.barMode or {}
          db.barMode.tickColors = db.barMode.tickColors or {}
          db.barMode.tickColors[6] = {r=r, g=g, b=b, a=a}
          if ns.API.ApplyLayout then ns.API.ApplyLayout() end
        end
      },
      
      tickColor7 = {
        type = "color",
        name = "Tick 7 (at 7 stacks)",
        desc = "Color for the seventh tick mark",
        hasAlpha = true,
        order = 21,
        width = "full",
        hidden = function()
          if not (db.barMode and db.barMode.useIndividualTickColors) then return true end
          if db.barMode.showTickMarks then return false end
          if db.barMode.showCustomTicks and db.barMode.customTicks then
            for _, tickPos in ipairs(db.barMode.customTicks) do
              if tickPos == 7 then return false end
            end
          end
          return true
        end,
        get = function()
          local color = db.barMode and db.barMode.tickColors and db.barMode.tickColors[7] or {r=0, g=0, b=0, a=1}
          if not color or type(color) ~= "table" then color = {r=0, g=0, b=0, a=1} end
          return color.r or 0, color.g or 0, color.b or 0, color.a or 1
        end,
        set = function(info, r, g, b, a)
          db.barMode = db.barMode or {}
          db.barMode.tickColors = db.barMode.tickColors or {}
          db.barMode.tickColors[7] = {r=r, g=g, b=b, a=a}
          if ns.API.ApplyLayout then ns.API.ApplyLayout() end
        end
      },
      
      tickColor8 = {
        type = "color",
        name = "Tick 8 (at 8 stacks)",
        desc = "Color for the eighth tick mark",
        hasAlpha = true,
        order = 22,
        width = "full",
        hidden = function()
          if not (db.barMode and db.barMode.useIndividualTickColors) then return true end
          if db.barMode.showTickMarks then return false end
          if db.barMode.showCustomTicks and db.barMode.customTicks then
            for _, tickPos in ipairs(db.barMode.customTicks) do
              if tickPos == 8 then return false end
            end
          end
          return true
        end,
        get = function()
          local color = db.barMode and db.barMode.tickColors and db.barMode.tickColors[8] or {r=0, g=0, b=0, a=1}
          if not color or type(color) ~= "table" then color = {r=0, g=0, b=0, a=1} end
          return color.r or 0, color.g or 0, color.b or 0, color.a or 1
        end,
        set = function(info, r, g, b, a)
          db.barMode = db.barMode or {}
          db.barMode.tickColors = db.barMode.tickColors or {}
          db.barMode.tickColors[8] = {r=r, g=g, b=b, a=a}
          if ns.API.ApplyLayout then ns.API.ApplyLayout() end
        end
      },
      
      tickColor9 = {
        type = "color",
        name = "Tick 9 (at 9 stacks)",
        desc = "Color for the ninth tick mark",
        hasAlpha = true,
        order = 23,
        width = "full",
        hidden = function()
          if not (db.barMode and db.barMode.useIndividualTickColors) then return true end
          if db.barMode.showTickMarks then return false end
          if db.barMode.showCustomTicks and db.barMode.customTicks then
            for _, tickPos in ipairs(db.barMode.customTicks) do
              if tickPos == 9 then return false end
            end
          end
          return true
        end,
        get = function()
          local color = db.barMode and db.barMode.tickColors and db.barMode.tickColors[9] or {r=0, g=0, b=0, a=1}
          if not color or type(color) ~= "table" then color = {r=0, g=0, b=0, a=1} end
          return color.r or 0, color.g or 0, color.b or 0, color.a or 1
        end,
        set = function(info, r, g, b, a)
          db.barMode = db.barMode or {}
          db.barMode.tickColors = db.barMode.tickColors or {}
          db.barMode.tickColors[9] = {r=r, g=g, b=b, a=a}
          if ns.API.ApplyLayout then ns.API.ApplyLayout() end
        end
      }
    }
  }
  }
  
  -- Per-stack configuration
  for i = 1, 10 do
    options["stack" .. i] = {
      type = "group",
      name = "Stack " .. i,
      inline = true,
      order = 10 + i,
      hidden = function() return db.displayMode == "bar" end,
      icon = 237584,
      args = {
        shape = {
          type = "select",
          name = "Shape",
          desc = "Icon shape for stack " .. i,
          values = SHAPE_OPTIONS,
          order = 1,
          width = 1.0,
          get = function() return db.stacks[i] and db.stacks[i].shape or "square" end,
          set = function(info, value)
            db.stacks[i] = db.stacks[i] or {}
            db.stacks[i].shape = value
            activePreview = i
            if ns.API.ForceDisplayUpdate then ns.API.ForceDisplayUpdate(i) end
            C_Timer.After(1.5, function()
              if activePreview == i then
                activePreview = nil
                local realCount = (ns.API.GetMSWCount and ns.API.GetMSWCount()) or 0
                if ns.API.ForceDisplayUpdate then ns.API.ForceDisplayUpdate(realCount) end
              end
            end)
          end
        },
        
        size = {
          type = "range",
          name = "Size",
          desc = "Size multiplier for this stack",
          min = 0.25,
          max = 2.0,
          step = 0.05,
          order = 2,
          width = 1.0,
          get = function() return db.stacks[i] and db.stacks[i].size or 1.0 end,
          set = function(info, value)
            db.stacks[i] = db.stacks[i] or {}
            db.stacks[i].size = value
            activePreview = i
            if ns.API.ForceDisplayUpdate then ns.API.ForceDisplayUpdate(i) end
            if ns.API.ApplyLayout then ns.API.ApplyLayout() end
            C_Timer.After(1.5, function()
              if activePreview == i then
                activePreview = nil
                local realCount = (ns.API.GetMSWCount and ns.API.GetMSWCount()) or 0
                if ns.API.ForceDisplayUpdate then ns.API.ForceDisplayUpdate(realCount) end
              end
            end)
          end
        },
        
        tint = {
          type = "color",
          name = "Filled Color",
          desc = "Color when this stack is filled",
          hasAlpha = true,
          order = 3,
          width = 1.0,
          get = function()
            local color = db.stacks[i] and db.stacks[i].tint or {r=0.024, g=0, b=1, a=1}
            if not color or type(color) ~= "table" then color = {r=0, g=0, b=0, a=1} end
          return color.r or 0, color.g or 0, color.b or 0, color.a or 1
          end,
          set = function(info, r, g, b, a)
            db.stacks[i] = db.stacks[i] or {}
            db.stacks[i].tint = {r=r, g=g, b=b, a=a}
            activePreview = i
            if ns.API.ForceDisplayUpdate then ns.API.ForceDisplayUpdate(i) end
          end
        },
        
        emptyTint = {
          type = "color",
          name = "Empty Color",
          desc = "Color when this stack is empty",
          hasAlpha = true,
          order = 4,
          width = 1.0,
          get = function()
            local color = db.stacks[i] and db.stacks[i].emptyTint or {r=0.9, g=0.9, b=1, a=0.25}
            if not color or type(color) ~= "table" then color = {r=0, g=0, b=0, a=1} end
          return color.r or 0, color.g or 0, color.b or 0, color.a or 1
          end,
          set = function(info, r, g, b, a)
            db.stacks[i] = db.stacks[i] or {}
            db.stacks[i].emptyTint = {r=r, g=g, b=b, a=a}
            activePreview = 0
            if ns.API.ForceDisplayUpdate then ns.API.ForceDisplayUpdate(0) end
          end
        },
        
        borderEnabled = {
          type = "toggle",
          name = "Enable Border",
          desc = "Show border around this stack icon",
          order = 5,
          width = 1.0,
          get = function() return db.stacks[i] and db.stacks[i].borderEnabled or false end,
          set = function(info, value)
            db.stacks[i] = db.stacks[i] or {}
            db.stacks[i].borderEnabled = value
            activePreview = i
            if ns.API.ForceDisplayUpdate then ns.API.ForceDisplayUpdate(i) end
            C_Timer.After(1.5, function()
              if activePreview == i then
                activePreview = nil
                local realCount = (ns.API.GetMSWCount and ns.API.GetMSWCount()) or 0
                if ns.API.ForceDisplayUpdate then ns.API.ForceDisplayUpdate(realCount) end
              end
            end)
          end
        },
        
        borderType = {
          type = "select",
          name = "Border Type",
          desc = "Texture: Uses border texture files\nColored Outline: Creates border from icon shape (works for ALL shapes)",
          values = {
            ["texture"] = "Texture Border",
            ["outline"] = "Colored Outline"
          },
          order = 5.1,
          width = 0.7,
          hidden = function() return not (db.stacks[i] and db.stacks[i].borderEnabled) end,
          get = function() 
            return db.stacks[i] and db.stacks[i].borderType or "outline"
          end,
          set = function(info, value)
            db.stacks[i] = db.stacks[i] or {}
            db.stacks[i].borderType = value
            activePreview = i
            if ns.API.ForceDisplayUpdate then ns.API.ForceDisplayUpdate(i) end
          end
        },
        
        borderTexture = {
          type = "select",
          name = "Border Texture",
          desc = "Select which border texture to use (for square shapes)",
          values = {
            ["Square_Border1"] = "Square Border 1",
            ["Square_Border2"] = "Square Border 2",
            ["Sqaure_Border3"] = "Square Border 3"
          },
          order = 5.2,
          width = 0.8,
          hidden = function() 
            local cfg = db.stacks[i]
            if not cfg or not cfg.borderEnabled then return true end
            if cfg.borderType ~= "texture" then return true end
            local shape = cfg.shape or "square"
            return shape ~= "square"
          end,
          get = function()
            return db.stacks[i] and db.stacks[i].borderTexture or "Square_Border1"
          end,
          set = function(info, value)
            db.stacks[i] = db.stacks[i] or {}
            db.stacks[i].borderTexture = value
            activePreview = i
            if ns.API.ForceDisplayUpdate then ns.API.ForceDisplayUpdate(i) end
          end
        },
        
        borderColor = {
          type = "color",
          name = "Border Color",
          desc = "Color of the border",
          hasAlpha = true,
          order = 5.3,
          width = 0.6,
          hidden = function() return not (db.stacks[i] and db.stacks[i].borderEnabled) end,
          get = function()
            local color = db.stacks[i] and db.stacks[i].borderColor or {r=1, g=1, b=1, a=1}
            if not color or type(color) ~= "table" then color = {r=0, g=0, b=0, a=1} end
          return color.r or 0, color.g or 0, color.b or 0, color.a or 1
          end,
          set = function(info, r, g, b, a)
            db.stacks[i] = db.stacks[i] or {}
            db.stacks[i].borderColor = {r=r, g=g, b=b, a=a}
            activePreview = i
            if ns.API.ForceDisplayUpdate then ns.API.ForceDisplayUpdate(i) end
          end
        },
        
        borderThickness = {
          type = "range",
          name = "Border Thickness",
          desc = "Width of the border ring (in pixels)",
          min = 1,
          max = 10,
          step = 1,
          order = 6.1,
          width = 1.1,
          hidden = function()
            local cfg = db.stacks[i]
            if not cfg or not cfg.borderEnabled then return true end
            return false  -- Available for all border types
          end,
          get = function()
            return db.stacks[i] and db.stacks[i].borderThickness or 2
          end,
          set = function(info, value)
            db.stacks[i] = db.stacks[i] or {}
            db.stacks[i].borderThickness = value
            activePreview = i
            if ns.API.ForceDisplayUpdate then ns.API.ForceDisplayUpdate(i) end
          end
        },
        
        borderOffset = {
          type = "range",
          name = "Border Offset (Gap)",
          desc = "Space between icon and border (squares in outline mode, all shapes in texture mode)",
          min = -20,
          max = 20,
          step = 1,
          order = 6.2,
          width = 1.1,
          hidden = function()
            local cfg = db.stacks[i]
            if not cfg or not cfg.borderEnabled then return true end
            local shape = cfg.shape or "square"
            -- Show for squares in outline mode OR all shapes in texture mode
            if cfg.borderType == "outline" then
              return shape ~= "square"  -- Only show for squares in outline mode
            else
              return false  -- Show for all shapes in texture mode
            end
          end,
          get = function()
            return db.stacks[i] and db.stacks[i].borderOffset or 0
          end,
          set = function(info, value)
            db.stacks[i] = db.stacks[i] or {}
            db.stacks[i].borderOffset = value
            activePreview = i
            if ns.API.ForceDisplayUpdate then ns.API.ForceDisplayUpdate(i) end
          end
        },
        
        glowEnabled = {
          type = "toggle",
          name = "Enable Glow",
          desc = "Show glow effect when this stack is filled",
          order = 7,
          width = 1.0,
          get = function() return db.stacks[i] and db.stacks[i].glowEnabled or false end,
          set = function(info, value)
            db.stacks[i] = db.stacks[i] or {}
            db.stacks[i].glowEnabled = value
            activePreview = i
            if ns.API.ForceDisplayUpdate then ns.API.ForceDisplayUpdate(i) end
            C_Timer.After(1.5, function()
              if activePreview == i then
                activePreview = nil
                local realCount = (ns.API.GetMSWCount and ns.API.GetMSWCount()) or 0
                if ns.API.ForceDisplayUpdate then ns.API.ForceDisplayUpdate(realCount) end
              end
            end)
          end
        },
        
        glowColor = {
          type = "color",
          name = "Glow Color",
          desc = "Color of the glow effect",
          hasAlpha = true,
          order = 8,
          width = 1.0,
          hidden = function() return not (db.stacks[i] and db.stacks[i].glowEnabled) end,
          get = function()
            local color = db.stacks[i] and db.stacks[i].glowColor or {r=0.5, g=0.7, b=1, a=1}
            if not color or type(color) ~= "table" then color = {r=0, g=0, b=0, a=1} end
          return color.r or 0, color.g or 0, color.b or 0, color.a or 1
          end,
          set = function(info, r, g, b, a)
            db.stacks[i] = db.stacks[i] or {}
            db.stacks[i].glowColor = {r=r, g=g, b=b, a=a}
            activePreview = i
            if ns.API.ForceDisplayUpdate then ns.API.ForceDisplayUpdate(i) end
          end
        },
        
        -- Copy Settings Toggle
        copyHeader = {
          type = "header",
          name = "",
          order = 100
        },
        
        showCopy = {
          type = "toggle",
          name = "Copy Settings",
          desc = "Show copy settings for this stack",
          order = 101,
          get = function() return db.stacks[i] and db.stacks[i]._showCopy or false end,
          set = function(info, value)
            db.stacks[i] = db.stacks[i] or {}
            db.stacks[i]._showCopy = value
          end
        },
        
        -- Copy Target
        copyTarget = {
          type = "select",
          name = "Copy To",
          desc = "Select which stacks to copy these settings to",
          order = 102,
          hidden = function() return not (db.stacks[i] and db.stacks[i]._showCopy) end,
          values = {
            ["1-5"] = "Stacks 1-5",
            ["6-10"] = "Stacks 6-10",
            ["all"] = "All Stacks (1-10)"
          },
          get = function() return db.stacks[i] and db.stacks[i]._copyTarget or "1-5" end,
          set = function(info, value)
            db.stacks[i] = db.stacks[i] or {}
            db.stacks[i]._copyTarget = value
          end
        },
        
        -- Multi-select for what to copy
        copyOptions = {
          type = "multiselect",
          name = "What to Copy",
          desc = "Select which settings to copy",
          order = 103,
          hidden = function() return not (db.stacks[i] and db.stacks[i]._showCopy) end,
          values = {
            shape = "Shape",
            size = "Size",
            filledColor = "Filled Color",
            emptyColor = "Empty Color",
            border = "Border Settings",
            glow = "Glow Settings"
          },
          get = function(info, key)
            return db.stacks[i] and db.stacks[i]["_copy_" .. key] or false
          end,
          set = function(info, key, value)
            db.stacks[i] = db.stacks[i] or {}
            db.stacks[i]["_copy_" .. key] = value
          end
        },
        
        -- Select All button
        copySelectAll = {
          type = "execute",
          name = "Select All",
          desc = "Select all copy options",
          order = 104,
          width = 0.5,
          hidden = function() return not (db.stacks[i] and db.stacks[i]._showCopy) end,
          func = function()
            db.stacks[i] = db.stacks[i] or {}
            db.stacks[i]._copy_shape = true
            db.stacks[i]._copy_size = true
            db.stacks[i]._copy_filledColor = true
            db.stacks[i]._copy_emptyColor = true
            db.stacks[i]._copy_border = true
            db.stacks[i]._copy_glow = true
          end
        },
        
        -- Copy Now button
        copyExecute = {
          type = "execute",
          name = "Copy Now",
          desc = "Copy selected settings to target stacks",
          order = 105,
          width = 0.5,
          hidden = function() return not (db.stacks[i] and db.stacks[i]._showCopy) end,
          func = function()
            local source = db.stacks[i]
            if not source then return end
            
            local target = source._copyTarget or "1-5"
            local startIdx, endIdx
            if target == "1-5" then
              startIdx, endIdx = 1, 5
            elseif target == "6-10" then
              startIdx, endIdx = 6, 10
            else -- "all"
              startIdx, endIdx = 1, 10
            end
            
            local copiedCount = 0
            
            for j = startIdx, endIdx do
              if j ~= i then -- Don't copy to self
                db.stacks[j] = db.stacks[j] or {}
                
                if source._copy_shape and source.shape then
                  db.stacks[j].shape = source.shape
                  copiedCount = copiedCount + 1
                end
                
                if source._copy_size and source.size then
                  db.stacks[j].size = source.size
                end
                
                if source._copy_filledColor and source.tint then
                  db.stacks[j].tint = {r=source.tint.r, g=source.tint.g, b=source.tint.b, a=source.tint.a}
                end
                
                if source._copy_emptyColor and source.emptyTint then
                  db.stacks[j].emptyTint = {r=source.emptyTint.r, g=source.emptyTint.g, b=source.emptyTint.b, a=source.emptyTint.a}
                end
                
                if source._copy_border then
                  db.stacks[j].borderEnabled = source.borderEnabled
                  db.stacks[j].borderType = source.borderType or "outline"
                  db.stacks[j].borderTexture = source.borderTexture or "Square_Border1"
                  db.stacks[j].borderThickness = source.borderThickness or 2
                  db.stacks[j].borderOffset = source.borderOffset or 0
                  if source.borderColor then
                    db.stacks[j].borderColor = {r=source.borderColor.r, g=source.borderColor.g, b=source.borderColor.b, a=source.borderColor.a}
                  end
                end
                
                if source._copy_glow then
                  db.stacks[j].glowEnabled = source.glowEnabled
                  if source.glowColor then
                    db.stacks[j].glowColor = {r=source.glowColor.r, g=source.glowColor.g, b=source.glowColor.b, a=source.glowColor.a}
                  end
                end
              end
            end
            
            -- Count what was actually selected
            local selectedItems = {}
            if source._copy_shape then table.insert(selectedItems, "shape") end
            if source._copy_size then table.insert(selectedItems, "size") end
            if source._copy_filledColor then table.insert(selectedItems, "filled color") end
            if source._copy_emptyColor then table.insert(selectedItems, "empty color") end
            if source._copy_border then table.insert(selectedItems, "border") end
            if source._copy_glow then table.insert(selectedItems, "glow") end
            
            if #selectedItems > 0 then
              print("|cff00ccffMWRB|r Copied " .. table.concat(selectedItems, ", ") .. " from Stack " .. i .. " to " .. target)
              if ns.API.ApplyLayout then ns.API.ApplyLayout() end
              if ns.API.RefreshDisplay then ns.API.RefreshDisplay() end
            else
              print("|cffff0000MWRB|r No settings selected to copy!")
            end
            
            -- Auto-disable the copy settings checkbox after copying
            db.stacks[i]._showCopy = false
          end
        }
      }
    }
  end
  
  -- Glow Animation
  options.glowSettings = {
    type = "group",
    name = "Glow Animation",
    desc = "Control the glow pulse animation speed",
    inline = true,
    order = 100,
    hidden = function() return db.displayMode == "bar" end,
    args = {
      pulseSpeed = ns.Options.CreateSliderOption(
        "Glow Pulse Speed",
        "Speed of glow pulsing animation (0.5 = slow, 1.0 = normal, 2.0 = fast, 3.0 = very fast)",
        0.5, 3.0, 0.1,
        function() return db.glowPulseSpeed or 2.0 end,
        function(value) db.glowPulseSpeed = value end
      )
    }
  }
  
  return options
end

-- ===================================================================
-- END OF MWRB_Options_Visual.lua
-- ===================================================================