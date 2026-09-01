-- ===================================================================
-- MWRB_Options_Core.lua
-- Main entry point for options system using AceConfig/AceGUI
-- ===================================================================

-- Class check - Exit if not Shaman
local _, playerClass = UnitClass("player")
if playerClass ~= "SHAMAN" then return end

local ADDON, ns = ...
ns = ns or {}
ns.API = ns.API or {}
ns.Options = ns.Options or {}

-- Load AceConfig and AceConfigDialog
local AceConfig = LibStub("AceConfig-3.0")
local AceConfigDialog = LibStub("AceConfigDialog-3.0")
local AceConfigRegistry = LibStub("AceConfigRegistry-3.0")
local AceDB = LibStub("AceDB-3.0")

-- ===================================================================
-- OPTIONS TABLE STRUCTURE (Modular)
-- ===================================================================
local function GetOptionsTable()
  local db = ns.API.GetDB()
  
  local options = {
    type = "group",
    name = "Maelstrom Weapon Resource Bar",
    args = {
      -- Main tab
      main = {
        type = "group",
        name = "Main Settings",
        order = 1,
        args = ns.Options.GetMainTabOptions and ns.Options.GetMainTabOptions() or {}
      },
      
      -- Status Bar Appearance tab (shown when Status Bar display mode is active)
      realMSWAppearance = {
        type = "group",
        name = "Status Bar Appearance",
        order = 2,
        hidden = function()
          return not (db and db.displayMode == "realMSW")
        end,
        args = ns.Options.GetRealMSWAppearanceOptions and ns.Options.GetRealMSWAppearanceOptions() or {}
      },
      
      -- Visual Settings tab (hidden when Real MSW Bar display mode is active)
      visual = {
        type = "group",
        name = "Visual Settings",
        order = 3,
        hidden = function()
          return db and db.displayMode == "realMSW"
        end,
        args = ns.Options.GetVisualTabOptions and ns.Options.GetVisualTabOptions() or {}
      },
      
      -- Conditionals tab
      conditionals = {
        type = "group",
        name = "Conditionals",
        order = 4,
        args = ns.Options.GetConditionalsTabOptions and ns.Options.GetConditionalsTabOptions() or {}
      }
    }
  }
  
  -- Add profile management
  if ns.Options.GetProfileOptions then
    local profileOptions = ns.Options.GetProfileOptions()
    profileOptions.order = 5
    options.args.profiles = profileOptions
  end
  
  -- Add debug tab last (order 6) - only visible in dev mode
  options.args.debug = {
    type = "group",
    name = "Debug",
    order = 6,
    hidden = function()
      return not ns.devMode
    end,
    args = ns.Options.GetDebugTabOptions and ns.Options.GetDebugTabOptions() or {}
  }
  
  return options
end

-- ===================================================================
-- OPEN OPTIONS PANEL
-- ===================================================================
function ns.API.OpenOptions()
  -- Check and reset preview mode if it's somehow stuck
  local db = ns.API.GetDB and ns.API.GetDB()
  if db and db.previewMode then
    db.previewMode = false
    db.previewStack = 0
    if ns.API.ExitPreviewMode then ns.API.ExitPreviewMode() end
    if ns.API.OnMSWChanged and ns.API.GetMSWCount then
      ns.API.OnMSWChanged(ns.API.GetMSWCount())
    end
  end

  -- Restore saved position/size into AceConfig status table BEFORE Open
  do
    local globalDB = ns.API.GetGlobalDB and ns.API.GetGlobalDB()
    local pos  = globalDB and globalDB.mwrbPanelPos
    local size = globalDB and globalDB.mwrbPanelSize
    if pos or size then
      local status = AceConfigDialog:GetStatusTable("MWRB")
      if status then
        if pos  then status.top = pos.top; status.left = pos.left end
        if size then status.width = size.width; status.height = size.height end
        -- Clamp to screen so saved positions from different resolutions don't go offscreen
        local sw, sh = GetScreenWidth(), GetScreenHeight()
        local w = status.width  or 800
        local h = status.height or 1000
        if status.top  then status.top  = math.max(h,   math.min(status.top,  sh))     end
        if status.left then status.left = math.max(0,   math.min(status.left, sw - w)) end
        if w > sw       then status.width  = sw      end
        if h > sh - 50  then status.height = sh - 50 end
      end
    end
  end

  AceConfigDialog:Open("MWRB")

  -- Stretch drag area + save pos on hide (runs once per frame object)
  C_Timer.After(0.05, function()
    local widget = AceConfigDialog.OpenFrames and AceConfigDialog.OpenFrames["MWRB"]
    if not widget or not widget.frame then return end
    local actualFrame = widget.frame

    -- Stretch the title drag handle across the full top of the frame
    if not actualFrame._mwrbTitleStretched then
      actualFrame._mwrbTitleStretched = true
      if widget.titletext then
        local titleFrame = widget.titletext:GetParent()
        if titleFrame and titleFrame ~= actualFrame then
          titleFrame:ClearAllPoints()
          titleFrame:SetPoint("TOPLEFT",  actualFrame, "TOPLEFT",  0, 0)
          titleFrame:SetPoint("TOPRIGHT", actualFrame, "TOPRIGHT", 0, 0)
          titleFrame:SetHeight(28)
        end
      end
    end

    -- Hook OnHide to save position/size when panel closes
    if not actualFrame._mwrbOnHideHooked then
      actualFrame._mwrbOnHideHooked = true
      local orig = actualFrame:GetScript("OnHide")
      actualFrame:SetScript("OnHide", function(self, ...)
        if orig then orig(self, ...) end
        local globalDB = ns.API.GetGlobalDB and ns.API.GetGlobalDB()
        if globalDB then
          local status = AceConfigDialog:GetStatusTable("MWRB")
          if status then
            globalDB.mwrbPanelPos  = { top = status.top,   left = status.left   }
            globalDB.mwrbPanelSize = { width = status.width, height = status.height }
          end
        end
      end)
    end
  end)
end

-- ===================================================================
-- REGISTER OPTIONS
-- ===================================================================

-- Function to fully exit preview mode
local function ExitPreviewMode()
  local db = ns.API.GetDB and ns.API.GetDB()
  
  if db then
    db.previewMode = false
    db.previewStack = 0
  end
  
  if ns.API.ExitPreviewMode then
    ns.API.ExitPreviewMode()
  end
  
  C_Timer.After(0.05, function()
    if db then
      db.previewMode = false
      db.previewStack = 0
    end
    
    local actualCount = 0
    if ns.API.GetMSWCount then
      actualCount = ns.API.GetMSWCount()
    end
    
    if ns.API.OnMSWChanged then
      ns.API.OnMSWChanged(actualCount)
    end
    
    if ns.API.RefreshDisplay then
      ns.API.RefreshDisplay()
    end
    
    C_Timer.After(0.1, function()
      if db then
        db.previewMode = false
        db.previewStack = 0
      end
      
      if ns.API.OnMSWChanged then
        local count = ns.API.GetMSWCount and ns.API.GetMSWCount() or 0
        ns.API.OnMSWChanged(count)
      end
    end)
  end)
end

local function RegisterOptions()
  -- Register main options table
  AceConfig:RegisterOptionsTable("MWRB", GetOptionsTable)
  
  -- Set larger default size for the options panel
  AceConfigDialog:SetDefaultSize("MWRB", 800, 1000)
  
  -- Add to Blizzard options window
  local frame = AceConfigDialog:AddToBlizOptions("MWRB", "MWRB")
  
  -- Hook AceConfigDialog close event safely
  hooksecurefunc(AceConfigDialog, "Close", function(self, appName)
    if appName == "MWRB" then
      ExitPreviewMode()
    end
  end)
  
  -- Also hook frame hide for Blizzard interface panel
  if frame then
    frame:HookScript("OnHide", function()
      ExitPreviewMode()
    end)
  end
end

-- ===================================================================
-- INITIALIZATION
-- ===================================================================
local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_LOGIN")

initFrame:SetScript("OnEvent", function(_, event)
  if event == "PLAYER_LOGIN" then
    -- Initialize AceDB with defaults
    ns.db = AceDB:New("Maelstrom_Weapon_Resource_Bar_V4DB", ns.DB_DEFAULTS, true)
    
    -- Run migration/validation after DB load
    local db = ns.db.profile
    if db then
      local currentVersion = 3
      local savedVersion = db.configVersion or 1
      
      -- Migration from v1/v2 to v3
      if savedVersion < 3 then
        -- Ensure realMSWBar exists and has all required fields
        if not db.realMSWBar then
          db.realMSWBar = {}
        end
        
        local cfg = db.realMSWBar
        if cfg.enabled == nil then cfg.enabled = true end
        if cfg.width == nil then cfg.width = 200 end
        if cfg.height == nil then cfg.height = 20 end
        if cfg.barScale == nil then cfg.barScale = 1.0 end
        if cfg.opacity == nil then cfg.opacity = 1.0 end
        if cfg.texture == nil then cfg.texture = "Blizzard" end
        if cfg.fillDirection == nil then cfg.fillDirection = "LEFT_TO_RIGHT" end
        if cfg.useGradient == nil then cfg.useGradient = false end
        if cfg.barColor == nil then cfg.barColor = {r=0, g=0.5, b=1, a=1} end
        if cfg.showBackground == nil then cfg.showBackground = true end
        if cfg.backgroundColor == nil then cfg.backgroundColor = {r=0.2, g=0.2, b=0.2, a=0.8} end
        if cfg.showBorder == nil then cfg.showBorder = true end
        if cfg.borderStyle == nil then cfg.borderStyle = "Drawn" end
        if cfg.drawnBorderThickness == nil then cfg.drawnBorderThickness = 2 end
        if cfg.borderColor == nil then cfg.borderColor = {r=0, g=0, b=0, a=1} end
        if cfg.showTickMarks == nil then cfg.showTickMarks = true end
        if cfg.tickThickness == nil then cfg.tickThickness = 1 end
        if cfg.tickColor == nil then cfg.tickColor = {r=0, g=0, b=0, a=1} end
        if cfg.showText == nil then cfg.showText = true end
        if cfg.font == nil then cfg.font = "Friz Quadrata TT" end
        if cfg.fontSize == nil then cfg.fontSize = 24 end
        if cfg.textColor == nil then cfg.textColor = {r=1, g=1, b=1, a=1} end
        if cfg.hideBuffIconMSW == nil then cfg.hideBuffIconMSW = false end
        if cfg.barMovable == nil then cfg.barMovable = true end
        if cfg.textMovable == nil then cfg.textMovable = true end
        if cfg.displayMode == nil then cfg.displayMode = "single" end
        
        -- Ensure threshold text color fields exist
        if db.threshold1 then
          if db.threshold1.textColorEnabled == nil then db.threshold1.textColorEnabled = false end
          if db.threshold1.textColor == nil then db.threshold1.textColor = {r=1, g=0.5, b=0, a=1} end
          if db.threshold1.operator == "==" then db.threshold1.operator = ">=" end
        end
        if db.threshold2 then
          if db.threshold2.textColorEnabled == nil then db.threshold2.textColorEnabled = false end
          if db.threshold2.textColor == nil then db.threshold2.textColor = {r=1, g=0, b=0, a=1} end
          if db.threshold2.operator == "==" then db.threshold2.operator = ">=" end
        end
        
        -- Remove deprecated prediction-related settings
        db.predLayerMode = nil
        db.debugOverlay = nil
        db.debugPredictor = nil
        
        print("|cff00ccffMWRB|r Profile migrated from v" .. savedVersion .. " to v" .. currentVersion .. " (now using direct aura tracking)")
      end
      
      -- Update version
      db.configVersion = currentVersion
    end
    
    -- Register options after DB is initialized
    C_Timer.After(0.1, function()
      RegisterOptions()
      
      -- Initialize minimap button if enabled
      if ns.Options.InitMinimapButton then
        ns.Options.InitMinimapButton()
      end
      
      -- Only print if debug is enabled
      local db = ns.API.GetDB()
      if db and db.debug then
        print("|cff00ccffMWRB|r Addon loaded successfully!")
      end
    end)
  end
end)

-- ===================================================================
-- END OF MWRB_Options_Core.lua
-- ===================================================================