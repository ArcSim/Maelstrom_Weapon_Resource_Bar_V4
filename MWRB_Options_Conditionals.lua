-- ===================================================================
-- MWRB_Options_Conditionals.lua
-- Conditionals tab (threshold triggers, sounds, etc.)
-- Uses real MSW stacks from direct aura query
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
-- CONDITIONALS TAB OPTIONS
-- ===================================================================

-- Custom sound files from addon Sounds folder
local SOUND_OPTIONS = {
  ["none"] = "None",
  ["AcousticGuitar"] = "Acoustic Guitar",
  ["AirHorn"] = "Air Horn",
  ["Applause"] = "Applause",
  ["BananaPeelSlip"] = "Banana Peel Slip",
  ["BatmanPunch"] = "Batman Punch",
  ["BikeHorn"] = "Bike Horn",
  ["Blast"] = "Blast",
  ["Bleat"] = "Bleat",
  ["BoxingArenaSound"] = "Boxing Arena Sound",
  ["Brass"] = "Brass",
  ["CartoonVoiceBartone"] = "Cartoon Voice Baritone",
  ["CartoonWalking"] = "Cartoon Walking",
  ["CatMeow2"] = "Cat Meow",
  ["ChickenAlarm"] = "Chicken Alarm",
  ["CowMooing"] = "Cow Mooing",
  ["DoubleWhoosh"] = "Double Whoosh",
  ["Drums"] = "Drums",
  ["ElectricalSpark"] = "Electrical Spark",
  ["ErrorBeep"] = "Error Beep",
  ["Glass"] = "Glass",
  ["GoatBleating"] = "Goat Bleating",
  ["HeartbeatSingle"] = "Heartbeat Single",
  ["KittenMeow"] = "Kitten Meow",
  ["OhNo"] = "Oh No",
  ["RingingPhone"] = "Ringing Phone",
  ["RoaringLion"] = "Roaring Lion",
  ["RobotBlip"] = "Robot Blip",
  ["RoosterChickenCalls"] = "Rooster Chicken Calls",
  ["SharpPunch"] = "Sharp Punch",
  ["SheepBleat"] = "Sheep Bleat",
  ["Shotgun"] = "Shotgun",
  ["SqueakyToyShort"] = "Squeaky Toy Short",
  ["SquishFart"] = "Squish Fart",
  ["SynthChord"] = "Synth Chord",
  ["TaDaFanfare"] = "Ta-Da Fanfare",
  ["TempleBellHuge"] = "Temple Bell Huge",
  ["Thunder"] = "Thunder",
  ["Torch"] = "Torch",
  ["WarningSiren"] = "Warning Siren",
  ["WaterDrop"] = "Water Drop",
  ["Xylophone"] = "Xylophone"
}

-- Helper function to play custom sound
local function PlayCustomSound(soundName)
  if soundName == "none" or not soundName then
    return
  end
  
  -- Determine file extension (most are .ogg, some are .mp3)
  local extension = "ogg"
  if soundName == "Brass" or soundName == "Glass" then
    extension = "mp3"
  end
  
  -- Get addon folder name dynamically
  local addonName = ADDON or "Maelstrom_Weapon_Resource_Bar_V4"
  local soundPath = "Interface\\AddOns\\" .. addonName .. "\\Sounds\\" .. soundName .. "." .. extension
  PlaySoundFile(soundPath, "Master")
end

-- Helper to check if in Real MSW mode
local function IsRealMSWMode()
  local db = GetDB()
  return db and db.displayMode == "realMSW"
end

-- Helper to trigger display updates
local function TriggerDisplayUpdate()
  if ns.API.RefreshDisplay then
    ns.API.RefreshDisplay()
  end
  if ns.RealMSW and ns.RealMSW.UpdateDisplay then
    ns.RealMSW.UpdateDisplay()
  end
  if ns.RealMSW and ns.RealMSW.UpdateBarAppearance then
    ns.RealMSW.UpdateBarAppearance()
  end
end

function ns.Options.GetConditionalsTabOptions()
  local db = GetDB()
  
  return {
    desc = {
      type = "description",
      name = "Configure conditions that trigger sounds, colors, and glows based on MSW stack counts. Use operators to define when conditions are met (==, >=, <=, >, <).",
      fontSize = "medium",
      order = 0
    },
    
    -- Condition 1
    threshold1 = {
      type = "group",
      name = "Condition 1",
      inline = true,
      order = 1,
      args = {
        enabled = {
          type = "toggle",
          name = "Enable Condition 1",
          desc = "Enable first condition (uses operator to compare MSW stacks)",
          order = 1,
          get = function()
            return db.threshold1Enabled or false
          end,
          set = function(info, value)
            db.threshold1Enabled = value
            if value then
              db.threshold1 = db.threshold1 or {}
              if not db.threshold1.stacks then
                db.threshold1.stacks = 5
              end
              if not db.threshold1.operator then
                db.threshold1.operator = ">="
              end
            end
            TriggerDisplayUpdate()
          end
        },
        
        -- Stack count slider
        stacks = {
          type = "range",
          name = "Stack Count",
          desc = "MSW stack count value to compare against (1-10)",
          order = 2,
          min = 1,
          max = 10,
          step = 1,
          hidden = function() return not db.threshold1Enabled end,
          get = function()
            return db.threshold1 and db.threshold1.stacks or 5
          end,
          set = function(info, value)
            db.threshold1 = db.threshold1 or {}
            db.threshold1.stacks = value
            TriggerDisplayUpdate()
          end
        },
        
        -- Operator
        operator = {
          type = "select",
          name = "Operator",
          desc = "When to trigger this condition",
          values = {
            ["=="] = "== (equals)",
            [">="] = ">= (at least)",
            ["<="] = "<= (at most)",
            [">"] = "> (greater than)",
            ["<"] = "< (less than)",
          },
          order = 3,
          hidden = function() return not db.threshold1Enabled end,
          get = function()
            return db.threshold1 and db.threshold1.operator or ">="
          end,
          set = function(info, value)
            db.threshold1 = db.threshold1 or {}
            db.threshold1.operator = value
          end
        },
        
        spacer1 = {
          type = "header",
          name = "Color Override",
          order = 10,
          hidden = function() return not db.threshold1Enabled end
        },
        
        colorEnabled = {
          type = "toggle",
          name = "Fill Color Override",
          desc = "Override fill color when condition is met",
          order = 11,
          hidden = function() return not db.threshold1Enabled end,
          get = function()
            return db.threshold1 and db.threshold1.colorEnabled or false
          end,
          set = function(info, value)
            db.threshold1 = db.threshold1 or {}
            db.threshold1.colorEnabled = value
            TriggerDisplayUpdate()
          end
        },
        
        color = {
          type = "color",
          name = "Fill Color",
          desc = "Fill color to use when condition is met",
          hasAlpha = true,
          order = 12,
          width = "full",
          hidden = function() return not (db.threshold1Enabled and db.threshold1 and db.threshold1.colorEnabled) end,
          get = function()
            local color = db.threshold1 and db.threshold1.color or {r=1, g=0.5, b=0, a=1}
            return color.r, color.g, color.b, color.a
          end,
          set = function(info, r, g, b, a)
            db.threshold1 = db.threshold1 or {}
            db.threshold1.color = {r=r, g=g, b=b, a=a}
            TriggerDisplayUpdate()
          end
        },
        
        -- Text color override
        textColorEnabled = {
          type = "toggle",
          name = "Text Color Override",
          desc = "Change stack text color when condition is met",
          order = 13,
          hidden = function() return not db.threshold1Enabled end,
          get = function()
            return db.threshold1 and db.threshold1.textColorEnabled or false
          end,
          set = function(info, value)
            db.threshold1 = db.threshold1 or {}
            db.threshold1.textColorEnabled = value
            TriggerDisplayUpdate()
          end
        },
        
        textColor = {
          type = "color",
          name = "Text Color",
          desc = "Text color when condition is met",
          hasAlpha = true,
          order = 14,
          width = "full",
          hidden = function() return not (db.threshold1Enabled and db.threshold1 and db.threshold1.textColorEnabled) end,
          get = function()
            local color = db.threshold1 and db.threshold1.textColor or {r=1, g=0.5, b=0, a=1}
            return color.r, color.g, color.b, color.a
          end,
          set = function(info, r, g, b, a)
            db.threshold1 = db.threshold1 or {}
            db.threshold1.textColor = {r=r, g=g, b=b, a=a}
            TriggerDisplayUpdate()
          end
        },
        
        -- Border color (for icon modes)
        borderColorEnabled = {
          type = "toggle",
          name = "Border Color Override",
          desc = "Override icon border colors when condition is met",
          order = 15,
          hidden = function() return not db.threshold1Enabled or IsRealMSWMode() end,
          get = function()
            return db.threshold1 and db.threshold1.borderColorEnabled or false
          end,
          set = function(info, value)
            db.threshold1 = db.threshold1 or {}
            db.threshold1.borderColorEnabled = value
            TriggerDisplayUpdate()
          end
        },
        
        borderColor = {
          type = "color",
          name = "Border Color",
          desc = "Border color when condition is met",
          hasAlpha = true,
          order = 16,
          width = "full",
          hidden = function() return not (db.threshold1Enabled and db.threshold1 and db.threshold1.borderColorEnabled) or IsRealMSWMode() end,
          get = function()
            local color = db.threshold1 and db.threshold1.borderColor or {r=1, g=0.5, b=0, a=1}
            return color.r, color.g, color.b, color.a
          end,
          set = function(info, r, g, b, a)
            db.threshold1 = db.threshold1 or {}
            db.threshold1.borderColor = {r=r, g=g, b=b, a=a}
            TriggerDisplayUpdate()
          end
        },
        
        spacer2 = {
          type = "header",
          name = "Sound",
          order = 20,
          hidden = function() return not db.threshold1Enabled end
        },
        
        soundEnabled = {
          type = "toggle",
          name = "Play Sound",
          desc = "Play a sound when this condition is first met",
          order = 21,
          hidden = function() return not db.threshold1Enabled end,
          get = function()
            return db.threshold1 and db.threshold1.soundEnabled or false
          end,
          set = function(info, value)
            db.threshold1 = db.threshold1 or {}
            db.threshold1.soundEnabled = value
          end
        },
        
        sound = {
          type = "select",
          name = "Sound File",
          desc = "Choose which sound to play",
          values = SOUND_OPTIONS,
          order = 22,
          hidden = function() return not (db.threshold1Enabled and db.threshold1 and db.threshold1.soundEnabled) end,
          get = function()
            return db.threshold1 and db.threshold1.sound or "none"
          end,
          set = function(info, value)
            db.threshold1 = db.threshold1 or {}
            db.threshold1.sound = value
            -- Play sound preview
            PlayCustomSound(value)
          end
        },
        
        -- Glow section (for icon modes)
        spacer3 = {
          type = "header",
          name = "Glow Effect",
          order = 30,
          hidden = function() return not db.threshold1Enabled or IsRealMSWMode() end
        },
        
        glowEnabled = {
          type = "toggle",
          name = "Enable Glow",
          desc = "Show glow effect when condition is met",
          order = 31,
          hidden = function() return not db.threshold1Enabled or IsRealMSWMode() end,
          get = function()
            return db.threshold1 and db.threshold1.glowEnabled or false
          end,
          set = function(info, value)
            db.threshold1 = db.threshold1 or {}
            db.threshold1.glowEnabled = value
            TriggerDisplayUpdate()
          end
        },
        
        glowColor = {
          type = "color",
          name = "Glow Color",
          desc = "Glow color for this condition",
          hasAlpha = true,
          order = 32,
          width = "full",
          hidden = function() return not (db.threshold1Enabled and db.threshold1 and db.threshold1.glowEnabled) or IsRealMSWMode() end,
          get = function()
            local color = db.threshold1 and db.threshold1.glowColor or {r=1, g=1, b=1, a=1}
            return color.r, color.g, color.b, color.a
          end,
          set = function(info, r, g, b, a)
            db.threshold1 = db.threshold1 or {}
            db.threshold1.glowColor = {r=r, g=g, b=b, a=a}
            TriggerDisplayUpdate()
          end
        }
      }
    },
    
    -- Condition 2
    threshold2 = {
      type = "group",
      name = "Condition 2",
      inline = true,
      order = 2,
      args = {
        enabled = {
          type = "toggle",
          name = "Enable Condition 2",
          desc = "Enable second condition (uses operator to compare MSW stacks)",
          order = 1,
          get = function()
            return db.threshold2Enabled or false
          end,
          set = function(info, value)
            db.threshold2Enabled = value
            if value then
              db.threshold2 = db.threshold2 or {}
              if not db.threshold2.stacks then
                db.threshold2.stacks = 10
              end
              if not db.threshold2.operator then
                db.threshold2.operator = ">="
              end
            end
            TriggerDisplayUpdate()
          end
        },
        
        -- Stack count slider
        stacks = {
          type = "range",
          name = "Stack Count",
          desc = "MSW stack count value to compare against (1-10)",
          order = 2,
          min = 1,
          max = 10,
          step = 1,
          hidden = function() return not db.threshold2Enabled end,
          get = function()
            return db.threshold2 and db.threshold2.stacks or 10
          end,
          set = function(info, value)
            db.threshold2 = db.threshold2 or {}
            db.threshold2.stacks = value
            TriggerDisplayUpdate()
          end
        },
        
        -- Operator
        operator = {
          type = "select",
          name = "Operator",
          desc = "When to trigger this condition",
          values = {
            ["=="] = "== (equals)",
            [">="] = ">= (at least)",
            ["<="] = "<= (at most)",
            [">"] = "> (greater than)",
            ["<"] = "< (less than)",
          },
          order = 3,
          hidden = function() return not db.threshold2Enabled end,
          get = function()
            return db.threshold2 and db.threshold2.operator or ">="
          end,
          set = function(info, value)
            db.threshold2 = db.threshold2 or {}
            db.threshold2.operator = value
          end
        },
        
        spacer1 = {
          type = "header",
          name = "Color Override",
          order = 10,
          hidden = function() return not db.threshold2Enabled end
        },
        
        colorEnabled = {
          type = "toggle",
          name = "Fill Color Override",
          desc = "Override fill color when condition is met",
          order = 11,
          hidden = function() return not db.threshold2Enabled end,
          get = function()
            return db.threshold2 and db.threshold2.colorEnabled or false
          end,
          set = function(info, value)
            db.threshold2 = db.threshold2 or {}
            db.threshold2.colorEnabled = value
            TriggerDisplayUpdate()
          end
        },
        
        color = {
          type = "color",
          name = "Fill Color",
          desc = "Fill color to use when condition is met",
          hasAlpha = true,
          order = 12,
          width = "full",
          hidden = function() return not (db.threshold2Enabled and db.threshold2 and db.threshold2.colorEnabled) end,
          get = function()
            local color = db.threshold2 and db.threshold2.color or {r=1, g=0, b=0, a=1}
            return color.r, color.g, color.b, color.a
          end,
          set = function(info, r, g, b, a)
            db.threshold2 = db.threshold2 or {}
            db.threshold2.color = {r=r, g=g, b=b, a=a}
            TriggerDisplayUpdate()
          end
        },
        
        -- Text color override
        textColorEnabled = {
          type = "toggle",
          name = "Text Color Override",
          desc = "Change stack text color when condition is met",
          order = 13,
          hidden = function() return not db.threshold2Enabled end,
          get = function()
            return db.threshold2 and db.threshold2.textColorEnabled or false
          end,
          set = function(info, value)
            db.threshold2 = db.threshold2 or {}
            db.threshold2.textColorEnabled = value
            TriggerDisplayUpdate()
          end
        },
        
        textColor = {
          type = "color",
          name = "Text Color",
          desc = "Text color when condition is met",
          hasAlpha = true,
          order = 14,
          width = "full",
          hidden = function() return not (db.threshold2Enabled and db.threshold2 and db.threshold2.textColorEnabled) end,
          get = function()
            local color = db.threshold2 and db.threshold2.textColor or {r=1, g=0, b=0, a=1}
            return color.r, color.g, color.b, color.a
          end,
          set = function(info, r, g, b, a)
            db.threshold2 = db.threshold2 or {}
            db.threshold2.textColor = {r=r, g=g, b=b, a=a}
            TriggerDisplayUpdate()
          end
        },
        
        -- Border color (for icon modes)
        borderColorEnabled = {
          type = "toggle",
          name = "Border Color Override",
          desc = "Override icon border colors when condition is met",
          order = 15,
          hidden = function() return not db.threshold2Enabled or IsRealMSWMode() end,
          get = function()
            return db.threshold2 and db.threshold2.borderColorEnabled or false
          end,
          set = function(info, value)
            db.threshold2 = db.threshold2 or {}
            db.threshold2.borderColorEnabled = value
            TriggerDisplayUpdate()
          end
        },
        
        borderColor = {
          type = "color",
          name = "Border Color",
          desc = "Border color when condition is met",
          hasAlpha = true,
          order = 16,
          width = "full",
          hidden = function() return not (db.threshold2Enabled and db.threshold2 and db.threshold2.borderColorEnabled) or IsRealMSWMode() end,
          get = function()
            local color = db.threshold2 and db.threshold2.borderColor or {r=1, g=0, b=0, a=1}
            return color.r, color.g, color.b, color.a
          end,
          set = function(info, r, g, b, a)
            db.threshold2 = db.threshold2 or {}
            db.threshold2.borderColor = {r=r, g=g, b=b, a=a}
            TriggerDisplayUpdate()
          end
        },
        
        spacer2 = {
          type = "header",
          name = "Sound",
          order = 20,
          hidden = function() return not db.threshold2Enabled end
        },
        
        soundEnabled = {
          type = "toggle",
          name = "Play Sound",
          desc = "Play a sound when this condition is first met",
          order = 21,
          hidden = function() return not db.threshold2Enabled end,
          get = function()
            return db.threshold2 and db.threshold2.soundEnabled or false
          end,
          set = function(info, value)
            db.threshold2 = db.threshold2 or {}
            db.threshold2.soundEnabled = value
          end
        },
        
        sound = {
          type = "select",
          name = "Sound File",
          desc = "Choose which sound to play",
          values = SOUND_OPTIONS,
          order = 22,
          hidden = function() return not (db.threshold2Enabled and db.threshold2 and db.threshold2.soundEnabled) end,
          get = function()
            return db.threshold2 and db.threshold2.sound or "none"
          end,
          set = function(info, value)
            db.threshold2 = db.threshold2 or {}
            db.threshold2.sound = value
            -- Play sound preview
            PlayCustomSound(value)
          end
        },
        
        -- Glow section (for icon modes)
        spacer3 = {
          type = "header",
          name = "Glow Effect",
          order = 30,
          hidden = function() return not db.threshold2Enabled or IsRealMSWMode() end
        },
        
        glowEnabled = {
          type = "toggle",
          name = "Enable Glow",
          desc = "Show glow effect when condition is met",
          order = 31,
          hidden = function() return not db.threshold2Enabled or IsRealMSWMode() end,
          get = function()
            return db.threshold2 and db.threshold2.glowEnabled or false
          end,
          set = function(info, value)
            db.threshold2 = db.threshold2 or {}
            db.threshold2.glowEnabled = value
            TriggerDisplayUpdate()
          end
        },
        
        glowColor = {
          type = "color",
          name = "Glow Color",
          desc = "Glow color for this condition",
          hasAlpha = true,
          order = 32,
          width = "full",
          hidden = function() return not (db.threshold2Enabled and db.threshold2 and db.threshold2.glowEnabled) or IsRealMSWMode() end,
          get = function()
            local color = db.threshold2 and db.threshold2.glowColor or {r=1, g=1, b=1, a=1}
            return color.r, color.g, color.b, color.a
          end,
          set = function(info, r, g, b, a)
            db.threshold2 = db.threshold2 or {}
            db.threshold2.glowColor = {r=r, g=g, b=b, a=a}
            TriggerDisplayUpdate()
          end
        }
      }
    }
  }
end

-- ===================================================================
-- END OF MWRB_Options_Conditionals.lua
-- ===================================================================