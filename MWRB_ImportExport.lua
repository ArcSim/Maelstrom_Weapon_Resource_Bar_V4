-- ===================================================================
-- MWRB_ImportExport.lua
-- Profile Import/Export with LibDeflate compression
-- ===================================================================

-- Class check - Exit if not Shaman
local _, playerClass = UnitClass("player")
if playerClass ~= "SHAMAN" then return end

local ADDON, ns = ...
ns.ImportExport = ns.ImportExport or {}

-- Try to load LibDeflate
local LibDeflate = LibStub and LibStub:GetLibrary("LibDeflate", true)

-- Current version for compatibility checking
local EXPORT_VERSION = 2

-- ===================================================================
-- SERIALIZATION HELPERS
-- ===================================================================

-- Compact key mapping (shorter keys = smaller strings)
-- IMPORTANT: Each value must be UNIQUE to avoid collisions
local KEY_MAP = {
  -- Display settings
  displayMode = "dm", globalSize = "gs", globalWidth = "gw", globalHeight = "gh",
  spacing = "sp", predLayerMode = "pl", configVersion = "cv",
  
  -- Positioning
  offset = "off", offsetIconMode = "oim", offsetBarMode = "obm",
  scale = "sc", baseSize = "bs", point = "pt", relPoint = "rpt", x = "x", y = "y",
  
  -- Bar mode
  barMode = "bm", width = "w", height = "h", opacity = "opa", direction = "dir",
  fillDirection = "fd", texture = "tx", useGradient = "ug", showBackground = "sb",
  backgroundColor = "bc", showBorder = "sbo", borderColor = "boc", borderThickness = "bot",
  showTickMarks = "stm", tickColor = "tc", tickThickness = "tt", barColor = "bac",
  showCustomTicks = "sct", customTicks = "cut", tickColors = "tcs", useIndividualTickColors = "uitc",
  
  -- Colors
  colorRanges = "cr", enabled = "en", maxStacks = "ms", color = "c",
  low = "lo", mid = "mi", high = "hi",
  
  -- Stacks
  stacks = "st", shape = "sh", size = "sz", tint = "ti", emptyTint = "et",
  glowEnabled = "ge", glowColor = "gc", borderEnabled = "be", borderType = "bty",
  borderTexture = "btx", borderOffset = "bof",
  
  -- Colors (RGBA)
  r = "r", g = "g", b = "b", a = "a",
  
  -- Text
  showStackText = "sst", stackTextSize = "sts", stackTextColor = "stc", stackTextPos = "stp",
  showText = "sht", fontSize = "fs", font = "fnt", textColor = "txc",
  
  -- Thresholds (unique keys to avoid collision)
  threshold1Enabled = "t1e", threshold2Enabled = "t2e",
  threshold1 = "t1", threshold2 = "t2",
  operator = "opr",  -- Changed from "op" to avoid collision with opacity
  colorEnabled = "ce", soundEnabled = "se", sound = "snd", soundFile = "sf",
  textColorEnabled = "tce",
  
  -- Real MSW Bar
  realMSWBar = "rmb", showBar = "shb", barScale = "bsc",
  layeredBarColors = "lbc", borderStyle = "bst", drawnBorderThickness = "dbt",
  reverseFill = "rf", orientation = "ori", desaturated = "dsa", desaturation = "dsv",
  barPosition = "bpo", textPosition = "tpo", barMovable = "bmv", textMovable = "tmv",
  hideBuffIconMSW = "hbi", showManualTracking = "smt", manualCooldownID = "mci",
  
  -- Other
  emptyTintBack = "etb", glowPulseSpeed = "gps",
  movable = "mv", slotsPos = "slp", layoutPositions = "lp",
  version = "v",
}

-- Reverse map for deserialization
local REVERSE_KEY_MAP = {}
for k, v in pairs(KEY_MAP) do
  REVERSE_KEY_MAP[v] = k
end

-- Round numbers to 2 decimal places
local function RoundNumber(num)
  if type(num) ~= "number" then return num end
  return math.floor(num * 100 + 0.5) / 100
end

-- Deep copy a table
local function DeepCopy(orig)
  local orig_type = type(orig)
  local copy
  if orig_type == 'table' then
    copy = {}
    for orig_key, orig_value in next, orig, nil do
      copy[DeepCopy(orig_key)] = DeepCopy(orig_value)
    end
  else
    copy = orig
  end
  return copy
end

-- Compact a table by using short keys and rounding numbers
local function CompactTable(tbl, defaults)
  if type(tbl) ~= "table" then return tbl end
  
  local compact = {}
  for k, v in pairs(tbl) do
    -- Skip if value equals default
    local shouldInclude = true
    if defaults and defaults[k] == v then
      shouldInclude = false
    end
    
    if shouldInclude then
      -- Use short key if available
      local shortKey = KEY_MAP[k] or k
      
      -- Process value
      if type(v) == "table" then
        local defaultSub = defaults and defaults[k]
        compact[shortKey] = CompactTable(v, defaultSub)
      elseif type(v) == "number" then
        compact[shortKey] = RoundNumber(v)
      else
        compact[shortKey] = v
      end
    end
  end
  
  return compact
end

-- Expand a compacted table back to full keys
local function ExpandTable(tbl)
  if type(tbl) ~= "table" then return tbl end
  
  local expanded = {}
  for k, v in pairs(tbl) do
    -- Use full key if we have a mapping
    local fullKey = REVERSE_KEY_MAP[k] or k
    
    -- Process value recursively
    if type(v) == "table" then
      expanded[fullKey] = ExpandTable(v)
    else
      expanded[fullKey] = v
    end
  end
  
  return expanded
end

-- ===================================================================
-- EXPORT FUNCTION
-- ===================================================================
function ns.ImportExport.ExportProfile()
  local db = ns.API.GetDB()
  if not db then
    return nil, "Failed to get database"
  end
  
  -- Export ALL profile settings (comprehensive export)
  local exportData = {
    version = EXPORT_VERSION,
    
    -- Display mode and sizing
    displayMode = db.displayMode,
    globalSize = db.globalSize,
    globalWidth = db.globalWidth,
    globalHeight = db.globalHeight,
    spacing = db.spacing,
    
    -- Positioning (all modes)
    offset = DeepCopy(db.offset),
    offsetIconMode = DeepCopy(db.offsetIconMode),
    offsetBarMode = DeepCopy(db.offsetBarMode),
    scale = db.scale,
    baseSize = db.baseSize,
    
    -- Stack text
    showStackText = db.showStackText,
    stackTextSize = db.stackTextSize,
    stackTextColor = DeepCopy(db.stackTextColor),
    stackTextPos = db.stackTextPos,
    
    -- Colors
    emptyTint = DeepCopy(db.emptyTint),
    emptyTintBack = DeepCopy(db.emptyTintBack),
    
    -- Effects
    glowPulseSpeed = db.glowPulseSpeed,
    
    -- Movable
    movable = db.movable,
    
    -- Stacks (icon settings) - deep copy each
    stacks = {},
    
    -- Bar mode (ALWAYS export, regardless of current display mode)
    barMode = DeepCopy(db.barMode),
    
    -- Real MSW Bar (ALWAYS export, regardless of current display mode)
    realMSWBar = DeepCopy(db.realMSWBar),
    
    -- Thresholds - deep copy to preserve nested colors
    threshold1 = DeepCopy(db.threshold1),
    threshold2 = DeepCopy(db.threshold2),
    
    -- Free form positions
    slotsPos = DeepCopy(db.slotsPos),
    layoutPositions = DeepCopy(db.layoutPositions),
  }
  
  -- Copy all stack settings (1-10) with deep copy for color tables
  for i = 1, 10 do
    if db.stacks[i] then
      exportData.stacks[i] = DeepCopy(db.stacks[i])
    end
  end
  
  -- Compact the data (compress keys but don't skip values)
  local compactData = CompactTable(exportData, nil)  -- Pass nil to disable default comparison
  
  -- Serialize to string
  local serialized = ns.ImportExport.Serialize(compactData)
  if not serialized then
    return nil, "Failed to serialize data"
  end
  
  local encoded
  if LibDeflate then
    -- Compress with LibDeflate if available
    local compressed = LibDeflate:CompressDeflate(serialized)
    if not compressed then
      return nil, "Failed to compress data"
    end
    encoded = LibDeflate:EncodeForPrint(compressed)
    if not encoded then
      return nil, "Failed to encode data"
    end
  else
    -- Fallback: URL encode without compression
    encoded = serialized:gsub(".", function(c)
      return string.format("%%%02X", string.byte(c))
    end)
  end
  
  -- Add version header
  local exportString = "MWRB" .. EXPORT_VERSION .. ":" .. encoded
  
  return exportString
end

-- ===================================================================
-- IMPORT FUNCTION
-- ===================================================================
function ns.ImportExport.ImportProfile(importString)
  if not importString or importString == "" then
    return false, "Import string is empty"
  end
  
  -- Check header
  local header, encoded = importString:match("^(MWRB%d+):(.+)$")
  if not header then
    return false, "Invalid import string format"
  end
  
  -- Check version
  local version = tonumber(header:match("MWRB(%d+)"))
  if not version or version > EXPORT_VERSION then
    return false, "Incompatible version (expected " .. EXPORT_VERSION .. " or lower, got " .. tostring(version) .. ")"
  end
  
  local serialized
  if LibDeflate then
    -- Decompress with LibDeflate if available
    local compressed = LibDeflate:DecodeForPrint(encoded)
    if not compressed then
      return false, "Failed to decode data"
    end
    serialized = LibDeflate:DecompressDeflate(compressed)
    if not serialized then
      return false, "Failed to decompress data"
    end
  else
    -- Fallback: URL decode
    serialized = encoded:gsub("%%(%x%x)", function(hex)
      return string.char(tonumber(hex, 16))
    end)
  end
  
  -- Deserialize
  local compactData = ns.ImportExport.Deserialize(serialized)
  if not compactData then
    return false, "Failed to deserialize data"
  end
  
  -- Expand compact keys
  local importData = ExpandTable(compactData)
  
  -- Validate version
  if not importData.version or importData.version > EXPORT_VERSION then
    return false, "Incompatible profile version"
  end
  
  -- Apply to current settings
  local db = ns.API.GetDB()
  if not db then
    return false, "Failed to get database"
  end
  
  -- Helper to deep merge tables (preserves existing keys not in import)
  local function DeepMerge(target, source)
    if type(source) ~= "table" then return end
    for k, v in pairs(source) do
      if type(v) == "table" then
        target[k] = target[k] or {}
        if type(target[k]) == "table" then
          DeepMerge(target[k], v)
        else
          target[k] = DeepCopy(v)
        end
      else
        target[k] = v
      end
    end
  end
  
  -- Apply display mode settings
  if importData.displayMode then db.displayMode = importData.displayMode end
  if importData.globalSize then db.globalSize = importData.globalSize end
  if importData.globalWidth then db.globalWidth = importData.globalWidth end
  if importData.globalHeight then db.globalHeight = importData.globalHeight end
  if importData.spacing then db.spacing = importData.spacing end
  
  -- Positioning
  if importData.offset then db.offset = DeepCopy(importData.offset) end
  if importData.offsetIconMode then db.offsetIconMode = DeepCopy(importData.offsetIconMode) end
  if importData.offsetBarMode then db.offsetBarMode = DeepCopy(importData.offsetBarMode) end
  if importData.scale then db.scale = importData.scale end
  if importData.baseSize then db.baseSize = importData.baseSize end
  
  -- Stack text
  if importData.showStackText ~= nil then db.showStackText = importData.showStackText end
  if importData.stackTextSize then db.stackTextSize = importData.stackTextSize end
  if importData.stackTextColor then db.stackTextColor = DeepCopy(importData.stackTextColor) end
  if importData.stackTextPos then db.stackTextPos = importData.stackTextPos end
  
  -- Colors
  if importData.emptyTint then db.emptyTint = DeepCopy(importData.emptyTint) end
  if importData.emptyTintBack then db.emptyTintBack = DeepCopy(importData.emptyTintBack) end
  
  -- Effects
  if importData.glowPulseSpeed then db.glowPulseSpeed = importData.glowPulseSpeed end
  
  -- Movable
  if importData.movable ~= nil then db.movable = importData.movable end
  
  -- Free form positions
  if importData.slotsPos then db.slotsPos = DeepCopy(importData.slotsPos) end
  if importData.layoutPositions then db.layoutPositions = DeepCopy(importData.layoutPositions) end
  
  -- Apply bar mode (ALWAYS import)
  if importData.barMode then
    db.barMode = db.barMode or {}
    DeepMerge(db.barMode, importData.barMode)
  end
  
  -- Apply Real MSW Bar (ALWAYS import)
  if importData.realMSWBar then
    db.realMSWBar = db.realMSWBar or {}
    DeepMerge(db.realMSWBar, importData.realMSWBar)
  end
  
  -- Apply stacks with deep copy
  if importData.stacks then
    for i = 1, 10 do
      if importData.stacks[i] then
        db.stacks[i] = db.stacks[i] or {}
        DeepMerge(db.stacks[i], importData.stacks[i])
      end
    end
  end
  
  -- Apply thresholds with deep copy
  if importData.threshold1 then
    db.threshold1 = db.threshold1 or {}
    DeepMerge(db.threshold1, importData.threshold1)
  end
  if importData.threshold2 then
    db.threshold2 = db.threshold2 or {}
    DeepMerge(db.threshold2, importData.threshold2)
  end
  
  -- Refresh display with comprehensive mode handling
  if ns.API.RefreshDisplay then
    ns.API.RefreshDisplay()
  end
  
  -- Apply positioning for all frames
  if ns.API.ApplyBarFramePosition then
    ns.API.ApplyBarFramePosition()
  end
  if ns.API.ApplyStatusBarPosition then
    ns.API.ApplyStatusBarPosition()
  end
  if ns.API.ApplyStackTextPosition then
    ns.API.ApplyStackTextPosition()
  end
  
  -- Ensure correct frame visibility for the new mode
  if db.displayMode == "realMSW" then
    -- Real MSW Bar mode
    if ns.API.HideDisplay then
      ns.API.HideDisplay()
    end
    if ns.RealMSW and ns.RealMSW.Enable then
      ns.RealMSW.Enable()
    end
    if ns.RealMSW and ns.RealMSW.RefreshAppearance then
      ns.RealMSW.RefreshAppearance()
    end
  elseif db.displayMode == "bar" then
    -- Bar mode
    if ns.RealMSW and ns.RealMSW.Disable then
      ns.RealMSW.Disable()
    end
    if ns.API.ShowDisplay then
      ns.API.ShowDisplay()
    end
  else
    -- Icon modes (5icons, 10spaces, freeform)
    if ns.RealMSW and ns.RealMSW.Disable then
      ns.RealMSW.Disable()
    end
    if ns.API.ShowDisplay then
      ns.API.ShowDisplay()
    end
  end
  
  -- Update movability state
  if ns.API.UpdateMovability then
    ns.API.UpdateMovability()
  end
  
  -- Force one final refresh after everything is set up
  C_Timer.After(0.1, function()
    if ns.API.RefreshDisplay then
      ns.API.RefreshDisplay()
    end
    -- Also refresh Real MSW if in that mode
    if db.displayMode == "realMSW" and ns.RealMSW and ns.RealMSW.RefreshAppearance then
      ns.RealMSW.RefreshAppearance()
    end
  end)
  
  return true, "Profile imported successfully"
end

-- ===================================================================
-- SIMPLE SERIALIZATION (Lua table to string)
-- ===================================================================
function ns.ImportExport.Serialize(tbl)
  local function SerializeValue(v)
    local vtype = type(v)
    if vtype == "string" then
      return string.format("%q", v)
    elseif vtype == "number" then
      return tostring(v)
    elseif vtype == "boolean" then
      return tostring(v)
    elseif vtype == "table" then
      local parts = {}
      for k, val in pairs(v) do
        local key = type(k) == "string" and string.format("[%q]", k) or string.format("[%d]", k)
        table.insert(parts, key .. "=" .. SerializeValue(val))
      end
      return "{" .. table.concat(parts, ",") .. "}"
    else
      return "nil"
    end
  end
  
  return SerializeValue(tbl)
end

function ns.ImportExport.Deserialize(str)
  if not str or str == "" then return nil end
  
  -- Use loadstring (or load in newer Lua)
  local func = loadstring("return " .. str)
  if not func then return nil end
  
  local success, result = pcall(func)
  if not success then return nil end
  
  return result
end

-- ===================================================================
-- END OF MWRB_ImportExport.lua
-- ===================================================================