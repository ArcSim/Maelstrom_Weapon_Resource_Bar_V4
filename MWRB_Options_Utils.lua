-- ===================================================================
-- MWRB_Options_Utils.lua
-- Shared utilities for options system
-- ===================================================================

-- Class check - Exit if not Shaman
local _, playerClass = UnitClass("player")
if playerClass ~= "SHAMAN" then return end

local ADDON, ns = ...
ns.Options = ns.Options or {}
ns.LSM = ns.LSM or {}

-- Sound path
local SOUND_PATH = "Interface/AddOns/" .. ADDON .. "/Sounds/"

-- ===================================================================
-- LIBSHAREDMEDIA-3.0 INTEGRATION
-- ===================================================================
-- Load LibSharedMedia
local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)

if not LSM then
  print("|cff00ccffMWRB|r |cffff0000ERROR:|r LibSharedMedia-3.0 not found!")
else
  -- Store reference
  ns.LSM.lib = LSM
  
  -- Texture base path
  local TEXTURE_BASE = "Interface\\AddOns\\Maelstrom_Weapon_Resource_Bar_V4\\Textures\\"
  
  -- Register custom textures on load
  -- Newer LibSharedMedia errors on paths the client does not ship, which aborts every later registration
  local function RegisterGameFile(mediaType, name, path)
    if GetFileIDFromPath(path) then
      LSM:Register(mediaType, name, path)
    end
  end

  local function RegisterCustomTextures()
    -- ===================================================================
    -- BLIZZARD STATUSBAR TEXTURES
    -- ===================================================================
    
    -- Core Blizzard UI bars (always work)
    RegisterGameFile(LSM.MediaType.STATUSBAR, "Blizzard", [[Interface\TargetingFrame\UI-StatusBar]])
    RegisterGameFile(LSM.MediaType.STATUSBAR, "Blizzard Raid Bar", [[Interface\RaidFrame\Raid-Bar-Hp-Fill]])
    RegisterGameFile(LSM.MediaType.STATUSBAR, "Blizzard Character Skills", [[Interface\PaperDollInfoFrame\UI-Character-Skills-Bar]])
    
    -- ===================================================================
    -- SHAMAN MAELSTROM TEXTURES
    -- ===================================================================
    -- "Blizzard Maelstrom" uses atlas directly (handled in ApplyStatusBarTexture)
    
    -- ===================================================================
    -- BLIZZARD CLASS POWER BARS (Atlas-Based - WeakAuras Method)
    -- ===================================================================
    -- WeakAuras uses PowerBarColor global table and registers with "statusbar_atlas"
    -- This loops through Blizzard's class power data and registers atlas names
    
    if PowerBarColor then
      local function capitalizeFirstLetter(str)
        local words = {}
        for word in string.gmatch(str, "[^_]+") do
          table.insert(words, word)
        end
        for i, word in ipairs(words) do
          words[i] = word:sub(1, 1):upper() .. word:sub(2):lower()
        end
        return table.concat(words, " ")
      end
      
      -- Blacklist of broken textures (atlas textures that don't work as StatusBars)
      -- Include both underscore format (from power key) and atlasElementName format
      local brokenTextureBlacklist = {
        -- Underscore format (capitalizeFirstLetter converts EBON_MIGHT -> Ebon Might)
        ["Blizzard Ebon Might"] = true,
        ["Blizzard Energy"] = true,
        ["Blizzard Focus"] = true,
        ["Blizzard Fury"] = true,
        ["Blizzard Insanity"] = true,
        ["Blizzard Lunar Power"] = true,
        -- Note: "Blizzard Maelstrom" is handled via texture coordinates now, so NOT blacklisted
        ["Blizzard Mana"] = true,
        ["Blizzard Pain"] = true,
        ["Blizzard Rage"] = true,
        ["Blizzard Runic Power"] = true,
        -- atlasElementName format (used directly without processing)
        ["Blizzard EbonMight"] = true,
        ["Blizzard RunicPower"] = true,
        ["Blizzard LunarPower"] = true,
      }
      
      -- Track already registered textures to prevent duplicates
      local registeredTextures = {}
      
      -- Register all class power bars from Blizzard's PowerBarColor table
      for power, data in pairs(PowerBarColor) do
        local name, atlasName
        if type(power) == "string" and data.atlas then
          name = "Blizzard " .. capitalizeFirstLetter(power)
          atlasName = data.atlas
        elseif data.atlasElementName then
          name = "Blizzard " .. data.atlasElementName
          atlasName = "UI-HUD-UnitFrame-Player-PortraitOff-Bar-" .. data.atlasElementName
        end
        
        if name and atlasName then
          -- Skip broken textures and duplicates
          if brokenTextureBlacklist[name] or registeredTextures[name] then
            -- Skip this texture
          else
            -- Note: LSM 3.0 doesn't have "statusbar_atlas" type by default
            -- So we'll try to fetch the atlas texture info and register as regular statusbar
            local atlasInfo = C_Texture.GetAtlasInfo(atlasName)
            if atlasInfo and atlasInfo.file then
              -- Found the actual texture file from atlas!
              LSM:Register(LSM.MediaType.STATUSBAR, name, atlasInfo.file)
              registeredTextures[name] = true
            end
          end
        end
      end
    end
    
    -- ===================================================================
    -- BLIZZARD BORDER TEXTURES (PROPER BORDERS ONLY!)
    -- ===================================================================
    
    -- Tooltip borders (most commonly used - these work great!)
    RegisterGameFile(LSM.MediaType.BORDER, "Blizzard Tooltip", [[Interface\Tooltips\UI-Tooltip-Border]])
    
    -- Dialog and frame borders
    RegisterGameFile(LSM.MediaType.BORDER, "Blizzard Dialog", [[Interface\DialogFrame\UI-DialogBox-Border]])
    RegisterGameFile(LSM.MediaType.BORDER, "Blizzard Dialog Gold", [[Interface\DialogFrame\UI-DialogBox-Gold-Border]])
    
    -- Button borders (clean square borders)
    RegisterGameFile(LSM.MediaType.BORDER, "Blizzard Button", [[Interface\BUTTONS\UI-Panel-Button-Up]])
    RegisterGameFile(LSM.MediaType.BORDER, "Blizzard Button Highlight", [[Interface\BUTTONS\UI-Panel-Button-Highlight]])
    
    -- Achievement borders (ornate frames)
    RegisterGameFile(LSM.MediaType.BORDER, "Blizzard Achievement Wood", [[Interface\AchievementFrame\UI-Achievement-WoodBorder]])
    RegisterGameFile(LSM.MediaType.BORDER, "Blizzard Achievement Icon", [[Interface\AchievementFrame\UI-Achievement-IconFrame]])
    
    -- Chat and nameplate borders
    RegisterGameFile(LSM.MediaType.BORDER, "Blizzard Chat Bubble", [[Interface\Tooltips\ChatBubble-Backdrop]])
    RegisterGameFile(LSM.MediaType.BORDER, "Blizzard Nameplate", [[Interface\Tooltips\Nameplate-Border]])
    
    -- Common UI borders
    RegisterGameFile(LSM.MediaType.BORDER, "Blizzard White Icon Frame", [[Interface\Common\WhiteIconFrame]])
    
    -- ===================================================================
    -- BLIZZARD BACKGROUND TEXTURES
    -- ===================================================================
    
    -- Solid backgrounds
    RegisterGameFile(LSM.MediaType.BACKGROUND, "Blizzard Solid", [[Interface\Buttons\WHITE8X8]])
    RegisterGameFile(LSM.MediaType.BACKGROUND, "Blizzard Black", [[Interface\DialogFrame\UI-DialogBox-Background-Dark]])
    
    -- Dialog backgrounds
    RegisterGameFile(LSM.MediaType.BACKGROUND, "Blizzard Dialog Background", [[Interface\DialogFrame\UI-DialogBox-Background]])
    RegisterGameFile(LSM.MediaType.BACKGROUND, "Blizzard Dialog Gold", [[Interface\DialogFrame\UI-DialogBox-Gold-Background]])
    
    -- Tooltip backgrounds
    RegisterGameFile(LSM.MediaType.BACKGROUND, "Blizzard Tooltip", [[Interface\Tooltips\UI-Tooltip-Background]])
    
    -- Textured backgrounds
    RegisterGameFile(LSM.MediaType.BACKGROUND, "Blizzard Marble", [[Interface\FrameGeneral\UI-Background-Marble]])
    RegisterGameFile(LSM.MediaType.BACKGROUND, "Blizzard Rock", [[Interface\FrameGeneral\UI-Background-Rock]])
    RegisterGameFile(LSM.MediaType.BACKGROUND, "Blizzard Tabard", [[Interface\TabardFrame\TabardFrameBackground]])
    RegisterGameFile(LSM.MediaType.BACKGROUND, "Blizzard Parchment", [[Interface\AchievementFrame\UI-Achievement-Parchment-Horizontal]])
    RegisterGameFile(LSM.MediaType.BACKGROUND, "Blizzard Achievement Parchment", [[Interface\AchievementFrame\UI-Achievement-Parchment]])
    
    -- Low alpha backgrounds (for subtle effects)
    RegisterGameFile(LSM.MediaType.BACKGROUND, "Blizzard Low Alpha", [[Interface\TAXIFRAME\UI-TaxiFrame-BackgroundTile]])
    
    -- ===================================================================
    -- YOUR CUSTOM TEXTURES GO HERE
    -- ===================================================================
    -- Texture files should be in: Interface\AddOns\Maelstrom_Weapon_Resource_Bar_V4\Textures\
    -- Supported formats: .tga, .blp
    
    local TEXTURE_BASE = "Interface\\AddOns\\Maelstrom_Weapon_Resource_Bar_V4\\Textures\\"
    
    -- Example: Register custom statusbar textures
    -- LSM:Register(LSM.MediaType.STATUSBAR, "MWRB Custom Bar", TEXTURE_BASE .. "MyCustomBar.tga")
    -- LSM:Register(LSM.MediaType.STATUSBAR, "MWRB Gradient", TEXTURE_BASE .. "MyGradient.blp")
    
    -- Example: Register custom background textures
    -- LSM:Register(LSM.MediaType.BACKGROUND, "MWRB Dark BG", TEXTURE_BASE .. "DarkBackground.tga")
    -- LSM:Register(LSM.MediaType.BACKGROUND, "MWRB Pattern", TEXTURE_BASE .. "PatternBG.blp")
    
    -- Example: Register custom border textures
    -- LSM:Register(LSM.MediaType.BORDER, "MWRB Square Border", TEXTURE_BASE .. "SquareBorder.tga")
    -- LSM:Register(LSM.MediaType.BORDER, "MWRB Fancy Border", TEXTURE_BASE .. "FancyBorder.blp")
    
    -- Example: Register custom fonts (must be .ttf format)
    -- LSM:Register(LSM.MediaType.FONT, "MWRB Custom Font", TEXTURE_BASE .. "MyFont.ttf")
    
    -- ===================================================================
    
    local db = ns.API and ns.API.GetDB and ns.API.GetDB()
    if db and db.debug then
      print("|cff00ccffMWRB|r LibSharedMedia-3.0 initialized:")
      print("  - 5 core statusbar textures")
      print("  - Auto-registered class power bars from PowerBarColor")
      print("  - 11 border textures")
      print("  - 10 background textures")
      print("|cff00ff00Using WeakAuras method for class textures! ⚡|r")
    end
  end
  
  -- Register on addon loaded
  local initFrame = CreateFrame("Frame")
  initFrame:RegisterEvent("ADDON_LOADED")
  initFrame:SetScript("OnEvent", function(_, event, addonName)
    if event == "ADDON_LOADED" and addonName == ADDON then
      RegisterCustomTextures()
    end
  end)
  
  -- Helper functions
  function ns.LSM.GetStatusBarList()
    local list = LSM:List(LSM.MediaType.STATUSBAR)
    local options = {}
    
    -- Include ALL textures registered with LSM
    -- If user has other LSM addons (SCRB, ElvUI, etc), their textures will work!
    for _, name in ipairs(list) do
      options[name] = name
    end
    
    -- Add atlas-based textures (not registered with LSM but handled by ApplyStatusBarTexture)
    options["Blizzard Maelstrom"] = "Blizzard Maelstrom"
    
    -- If list is empty, add fallback
    if not next(options) then
      options["Blizzard"] = "Blizzard"
    end
    
    return options
  end
  
  function ns.LSM.GetBackgroundList()
    local list = LSM:List(LSM.MediaType.BACKGROUND)
    local options = {}
    
    -- Include ALL textures registered with LSM
    for _, name in ipairs(list) do
      options[name] = name
    end
    
    -- If list is empty, add fallback
    if not next(options) then
      options["Solid"] = "Solid"
    end
    
    return options
  end
  
  function ns.LSM.GetBorderList()
    local list = LSM:List(LSM.MediaType.BORDER)
    local options = {}
    
    -- Include ALL textures registered with LSM
    for _, name in ipairs(list) do
      options[name] = name
    end
    
    -- If list is empty, add fallback
    if not next(options) then
      options["Blizzard Tooltip"] = "Blizzard Tooltip"
    end
    
    return options
  end
  
  function ns.LSM.GetFontList()
    local list = LSM:List(LSM.MediaType.FONT)
    local options = {}
    
    -- Include ALL fonts registered with LSM
    for _, name in ipairs(list) do
      options[name] = name
    end
    
    -- If list is empty, add fallback
    if not next(options) then
      options["Friz Quadrata TT"] = "Friz Quadrata TT"
    end
    
    return options
  end
  
  function ns.LSM.FetchStatusBar(name)
    if not name then return "Interface\\TargetingFrame\\UI-StatusBar" end
    local success, path = pcall(LSM.Fetch, LSM, LSM.MediaType.STATUSBAR, name)
    if success and path then return path end
    return "Interface\\TargetingFrame\\UI-StatusBar"
  end
  
  function ns.LSM.FetchBackground(name)
    if not name then return "Interface\\Buttons\\WHITE8X8" end
    local success, path = pcall(LSM.Fetch, LSM, LSM.MediaType.BACKGROUND, name)
    if success and path then return path end
    return "Interface\\Buttons\\WHITE8X8"
  end
  
  function ns.LSM.FetchBorder(name)
    if not name then return "Interface\\Tooltips\\UI-Tooltip-Border" end
    local success, path = pcall(LSM.Fetch, LSM, LSM.MediaType.BORDER, name)
    if success and path then return path end
    return "Interface\\Tooltips\\UI-Tooltip-Border"
  end
  
  function ns.LSM.FetchFont(name)
    if not name then return "Fonts\\FRIZQT__.TTF" end
    local success, path = pcall(LSM.Fetch, LSM, LSM.MediaType.FONT, name)
    if success and path then return path end
    return "Fonts\\FRIZQT__.TTF"
  end
  
  -- ===================================================================
  -- ATLAS-BASED TEXTURES
  -- Some textures need to use Blizzard's atlas system directly
  -- ===================================================================
  local atlasTextures = {
    -- Blizzard Maelstrom: Use atlas directly for proper cropping
    ["Blizzard Maelstrom"] = "Unit_Shaman_Maelstrom_Fill",
  }
  
  -- Check if a texture should use atlas
  function ns.LSM.GetAtlasName(textureName)
    return atlasTextures[textureName]
  end
  
  -- Apply texture to a StatusBar (handles both atlas and regular textures)
  function ns.LSM.ApplyStatusBarTexture(statusBar, textureName)
    if not statusBar then return end
    
    -- Check if this texture uses atlas
    local atlasName = atlasTextures[textureName]
    if atlasName then
      -- Use atlas directly - Blizzard handles tex coords automatically
      statusBar:SetStatusBarTexture(atlasName, "ARTWORK")
    else
      -- Use LSM path
      local texPath = ns.LSM.FetchStatusBar(textureName)
      statusBar:SetStatusBarTexture(texPath)
    end
  end
end

-- ===================================================================
-- COLOR HELPERS
-- ===================================================================
function ns.Options.ColorToRGBA(color)
  if not color or type(color) ~= "table" then
    return 0, 0, 0, 1
  end
  return color.r or 0, color.g or 0, color.b or 0, color.a or 1
end

function ns.Options.RGBAToColor(r, g, b, a)
  return {r = r, g = g, b = b, a = a}
end

-- Color picker for AceConfig
function ns.Options.CreateColorOption(name, desc, getter, setter, hasAlpha)
  return {
    type = "color",
    name = name,
    desc = desc,
    hasAlpha = hasAlpha or true,
    get = function(info)
      local color = getter()
      return ns.Options.ColorToRGBA(color)
    end,
    set = function(info, r, g, b, a)
      setter(ns.Options.RGBAToColor(r, g, b, a))
      if ns.API.RefreshDisplay then
        ns.API.RefreshDisplay()
      end
    end
  }
end

-- ===================================================================
-- SLIDER HELPERS
-- ===================================================================
function ns.Options.CreateSliderOption(name, desc, min, max, step, getter, setter)
  return {
    type = "range",
    name = name,
    desc = desc,
    min = min,
    max = max,
    step = step,
    get = getter,
    set = function(info, value)
      setter(value)
      if ns.API.RefreshDisplay then
        ns.API.RefreshDisplay()
      end
    end
  }
end

-- ===================================================================
-- DROPDOWN HELPERS
-- ===================================================================
function ns.Options.CreateSelectOption(name, desc, values, getter, setter)
  return {
    type = "select",
    name = name,
    desc = desc,
    values = values,
    get = getter,
    set = function(info, value)
      setter(value)
      if ns.API.RefreshDisplay then
        ns.API.RefreshDisplay()
      end
    end
  }
end

-- ===================================================================
-- LSM TEXTURE SELECT HELPERS (with SharedMediaWidgets preview)
-- ===================================================================
function ns.Options.CreateStatusBarSelectOption(name, desc, values, getter, setter)
  return {
    type = "select",
    dialogControl = "LSM30_Statusbar",  -- Enable texture preview!
    name = name,
    desc = desc,
    values = values,
    width = "double",  -- Make dropdown wider to show full names!
    get = getter,
    set = function(info, value)
      setter(value)
      if ns.API.RefreshDisplay then
        ns.API.RefreshDisplay()
      end
    end
  }
end

function ns.Options.CreateBackgroundSelectOption(name, desc, values, getter, setter)
  return {
    type = "select",
    dialogControl = "LSM30_Background",  -- Enable texture preview!
    name = name,
    desc = desc,
    values = values,
    width = "double",  -- Make dropdown wider!
    get = getter,
    set = function(info, value)
      setter(value)
      if ns.API.RefreshDisplay then
        ns.API.RefreshDisplay()
      end
    end
  }
end

function ns.Options.CreateBorderSelectOption(name, desc, values, getter, setter)
  return {
    type = "select",
    dialogControl = "LSM30_Border",  -- Enable texture preview!
    name = name,
    desc = desc,
    values = values,
    width = "double",  -- Make dropdown wider!
    get = getter,
    set = function(info, value)
      setter(value)
      if ns.API.RefreshDisplay then
        ns.API.RefreshDisplay()
      end
    end
  }
end

function ns.Options.CreateFontSelectOption(name, desc, values, getter, setter)
  return {
    type = "select",
    dialogControl = "LSM30_Font",  -- Enable font preview!
    name = name,
    desc = desc,
    values = values,
    width = "double",  -- Make dropdown wider!
    get = getter,
    set = function(info, value)
      setter(value)
      if ns.API.RefreshDisplay then
        ns.API.RefreshDisplay()
      end
    end
  }
end

-- ===================================================================
-- TOGGLE HELPERS
-- ===================================================================
function ns.Options.CreateToggleOption(name, desc, getter, setter)
  return {
    type = "toggle",
    name = name,
    desc = desc,
    get = getter,
    set = function(info, value)
      setter(value)
      if ns.API.RefreshDisplay then
        ns.API.RefreshDisplay()
      end
    end
  }
end

-- ===================================================================
-- EXECUTE BUTTON HELPER
-- ===================================================================
function ns.Options.CreateExecuteOption(name, desc, func)
  return {
    type = "execute",
    name = name,
    desc = desc,
    func = func
  }
end

-- ===================================================================
-- DESCRIPTION/HEADER HELPER
-- ===================================================================
function ns.Options.CreateHeader(name, fontSize)
  return {
    type = "header",
    name = name,
    order = fontSize or 1
  }
end

function ns.Options.CreateDescription(text)
  return {
    type = "description",
    name = text,
    fontSize = "medium"
  }
end

-- ===================================================================
-- SOUND SELECTION HELPER
-- ===================================================================
function ns.Options.GetAvailableSounds()
  -- Return list of available sound files
  return {
    ["sound1"] = "Sound 1",
    ["sound2"] = "Sound 2",
    ["sound3"] = "Sound 3",
    ["custom"] = "Custom Sound"
  }
end

function ns.Options.PlaySound(soundFile)
  if soundFile then
    local ext = "ogg" -- default extension
    PlaySoundFile(SOUND_PATH .. soundFile .. "." .. ext, "Master")
  end
end

-- ===================================================================
-- PREVIEW MODE HELPERS
-- ===================================================================
function ns.Options.EnterPreview(stackCount)
  if ns.API.EnterPreviewMode then
    ns.API.EnterPreviewMode(stackCount or 5)
  end
end

function ns.Options.ExitPreview()
  if ns.API.ExitPreviewMode then
    ns.API.ExitPreviewMode()
  end
end

-- ===================================================================
-- GROUP HELPER (for sections)
-- ===================================================================
function ns.Options.CreateGroup(name, desc, inline, order, args)
  return {
    type = "group",
    name = name,
    desc = desc,
    inline = inline or false,
    order = order or 1,
    args = args or {}
  }
end

-- ===================================================================
-- VALIDATION HELPERS
-- ===================================================================
function ns.Options.ValidateNumber(value, min, max, default)
  if not value or type(value) ~= "number" then
    return default
  end
  if min and value < min then
    return min
  end
  if max and value > max then
    return max
  end
  return value
end

-- ===================================================================
-- END OF MWRB_Options_Utils.lua
-- ===================================================================