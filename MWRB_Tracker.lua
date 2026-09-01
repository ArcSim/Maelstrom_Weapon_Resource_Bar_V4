-- ===================================================================
-- MWRB_Tracker.lua
-- Maelstrom Weapon Resource Bar v4 - Tracker Module (Direct Aura Query)
-- 
-- This module handles MSW stack tracking using direct aura queries.
-- MSW stacks read via GetPlayerAuraBySpellID (Blizzard whitelists MSW as
-- non-secret on 12.1; the read is issecretvalue-guarded for edge states).
-- Output: One integer value (0-10) pushed via ns.API.OnMSWChanged()
-- ===================================================================

-- ===================================================================
-- SECTION 01 - Namespace & State
-- ===================================================================
-- Class check - Exit if not Shaman
local _, playerClass = UnitClass("player")
if playerClass ~= "SHAMAN" then return end

local ADDON, ns = ...
ns = ns or {}
ns.API = ns.API or {}

-- ===================================================================
-- SECTION 02 - Constants
-- ===================================================================
local MSW_SPELL_ID = 344179  -- Maelstrom Weapon buff ID
local MAELSTROM_WEAPON_TALENT_ID = 187880
local ENHANCEMENT_SPEC_ID = 263

-- Dynamic sound path based on addon folder
local SOUND_PATH = "Interface/AddOns/" .. ADDON .. "/Sounds/"

-- ===================================================================
-- SECTION 03 - State Variables
-- ===================================================================
-- MSW count: 0-10
local mswCount = 0
local previousMswCount = 0  -- Track previous count for threshold sound triggers

-- Threshold trigger tracking
local lastTriggerTime1 = 0
local lastTriggerTime2 = 0
local lastTriggerCount1 = -1
local lastTriggerCount2 = -1
local lastTriggerCondition1 = false
local lastTriggerCondition2 = false
local THRESHOLD_DEBOUNCE_TIME = 0.5

-- ===================================================================
-- SECTION 04 - Spec and Talent Check
-- ===================================================================
local function ShouldShowUI()
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
  
  local configInfo = C_Traits.GetConfigInfo(configID)
  if not configInfo then return false end
  
  for _, treeID in ipairs(configInfo.treeIDs or {}) do
    local nodes = C_Traits.GetTreeNodes(treeID)
    for _, nodeID in ipairs(nodes or {}) do
      local nodeInfo = C_Traits.GetNodeInfo(configID, nodeID)
      if nodeInfo and nodeInfo.activeRank and nodeInfo.activeRank > 0 then
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

local function IsEnhancementSpec()
  local specID = GetSpecialization()
  if not specID then return false end
  local id = GetSpecializationInfo(specID)
  return id == ENHANCEMENT_SPEC_ID
end

-- ===================================================================
-- SECTION 05 - Debug Helpers
-- ===================================================================
local function dprint(...)
  local db = ns.API.GetDB()
  if db and (db.debugMSW or db.debug) then
    print("|cff00ccffMWRB|r[TRACKER]", ...)
  end
end

local function dprintf(fmt, ...)
  local db = ns.API.GetDB()
  if db and (db.debugMSW or db.debug) then
    print("|cff00ccffMWRB|r[TRACKER]", fmt:format(...))
  end
end

-- ===================================================================
-- SECTION 06 - MSW Query Function
-- ===================================================================
local function GetMSWStacks()
  local aura = C_UnitAuras.GetPlayerAuraBySpellID(MSW_SPELL_ID)
  -- 12.1: GetPlayerAuraBySpellID returns a SECRET AuraData for non-whitelisted
  -- spells (and in forced-restriction states); reading .applications and the
  -- `or 0` truthiness are unsafe on a secret. Maelstrom Weapon is on
  -- Blizzard's non-secret whitelist, so in normal play this guard is inert --
  -- it only protects the edge states. Same pattern as ArcUI's resource bars.
  if aura and not (issecretvalue and issecretvalue(aura)) then
    return aura.applications or 0
  end
  return 0
end

-- Export for other modules
function ns.API.GetMSWCount()
  return mswCount
end

-- ===================================================================
-- SECTION 07 - Threshold Sound & Visual Triggers
-- ===================================================================
local function CheckThresholds(count, prevCount)
  local db = ns.API.GetDB()
  if not db then return end
  
  local currentTime = GetTime()
  
  -- Threshold comparison function
  local function meetsThreshold(value, threshold, operator)
    if operator == ">=" then
      return value >= threshold
    elseif operator == "<=" then
      return value <= threshold
    elseif operator == ">" then
      return value > threshold
    elseif operator == "<" then
      return value < threshold
    elseif operator == "==" then
      return value == threshold
    end
    return false
  end
  
  -- Check Threshold 1
  if db.threshold1 and db.threshold1.soundEnabled then
    local threshold = db.threshold1.stacks or 5
    local operator = db.threshold1.operator or ">="
    local conditionMet = meetsThreshold(count, threshold, operator)
    local wasConditionMet = lastTriggerCondition1
    
    -- Only trigger on rising edge (condition becomes true)
    if conditionMet and not wasConditionMet then
      -- Check debounce
      if (currentTime - lastTriggerTime1) >= THRESHOLD_DEBOUNCE_TIME then
        -- Play sound
        local soundFile = db.threshold1.sound or "Sound1"
        local soundPath = SOUND_PATH .. soundFile .. ".ogg"
        PlaySoundFile(soundPath, "Master")
        
        lastTriggerTime1 = currentTime
        lastTriggerCount1 = count
        dprintf("Threshold 1 triggered: %d %s %d", count, operator, threshold)
      end
    end
    
    lastTriggerCondition1 = conditionMet
  end
  
  -- Check Threshold 2
  if db.threshold2 and db.threshold2.soundEnabled then
    local threshold = db.threshold2.stacks or 10
    local operator = db.threshold2.operator or ">="
    local conditionMet = meetsThreshold(count, threshold, operator)
    local wasConditionMet = lastTriggerCondition2
    
    -- Only trigger on rising edge
    if conditionMet and not wasConditionMet then
      if (currentTime - lastTriggerTime2) >= THRESHOLD_DEBOUNCE_TIME then
        local soundFile = db.threshold2.sound or "Sound2"
        local soundPath = SOUND_PATH .. soundFile .. ".ogg"
        PlaySoundFile(soundPath, "Master")
        
        lastTriggerTime2 = currentTime
        lastTriggerCount2 = count
        dprintf("Threshold 2 triggered: %d %s %d", count, operator, threshold)
      end
    end
    
    lastTriggerCondition2 = conditionMet
  end
end

-- ===================================================================
-- SECTION 08 - Push MSW Count to Display
-- ===================================================================
local function PushMSWCount()
  local db = ns.API.GetDB()
  
  -- Check thresholds before updating
  CheckThresholds(mswCount, previousMswCount)
  previousMswCount = mswCount
  
  -- Debug output
  if db and db.debugMSW then
    dprintf("MSW count: %d", mswCount)
  end
  
  -- Push to display module
  if ns.API.OnMSWChanged then
    ns.API.OnMSWChanged(mswCount)
  end
end

-- ===================================================================
-- SECTION 09 - Update MSW from Aura
-- ===================================================================
local function UpdateMSW()
  if not IsEnhancementSpec() then
    if mswCount ~= 0 then
      mswCount = 0
      PushMSWCount()
    end
    return
  end
  
  local newCount = GetMSWStacks()
  
  if newCount ~= mswCount then
    dprintf("MSW changed: %d -> %d", mswCount, newCount)
    mswCount = newCount
    PushMSWCount()
  end
end

-- ===================================================================
-- SECTION 10 - Event Handler
-- ===================================================================
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("UNIT_AURA")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
eventFrame:RegisterEvent("TRAIT_CONFIG_UPDATED")
eventFrame:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")

eventFrame:SetScript("OnEvent", function(self, event, ...)
  -- UNIT_AURA for player
  if event == "UNIT_AURA" then
    local unit = ...
    if unit == "player" then
      UpdateMSW()
    end
    return
  end
  
  -- Initial load or zone change
  if event == "PLAYER_ENTERING_WORLD" then
    C_Timer.After(0.1, function()
      -- Check if we should show UI
      if ShouldShowUI() then
        UpdateMSW()
        if ns.API.ShowDisplay then
          ns.API.ShowDisplay()
        end
      else
        mswCount = 0
        PushMSWCount()
        if ns.API.HideDisplay then
          ns.API.HideDisplay()
        end
      end
    end)
    return
  end
  
  -- Spec/talent changes
  if event == "PLAYER_SPECIALIZATION_CHANGED" or 
     event == "TRAIT_CONFIG_UPDATED" or 
     event == "ACTIVE_TALENT_GROUP_CHANGED" then
    C_Timer.After(0.1, function()
      if ShouldShowUI() then
        UpdateMSW()
        if ns.API.ShowDisplay then
          ns.API.ShowDisplay()
        end
      else
        mswCount = 0
        PushMSWCount()
        if ns.API.HideDisplay then
          ns.API.HideDisplay()
        end
      end
    end)
    return
  end
end)

-- ===================================================================
-- SECTION 11 - Public API
-- ===================================================================
-- Force refresh (for testing or external triggers)
function ns.API.RefreshMSW()
  UpdateMSW()
end

-- Manual set (for testing only)
function ns.API.SetMSWCount(count)
  if count >= 0 and count <= 10 then
    mswCount = count
    PushMSWCount()
  end
end

-- Reset threshold triggers (useful when changing specs)
function ns.API.ResetThresholdTriggers()
  lastTriggerTime1 = 0
  lastTriggerTime2 = 0
  lastTriggerCount1 = -1
  lastTriggerCount2 = -1
  lastTriggerCondition1 = false
  lastTriggerCondition2 = false
end

-- ===================================================================
-- END OF MWRB_Tracker.lua
-- ===================================================================