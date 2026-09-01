-- ===================================================================
-- MWRB_RealMSWDisplay.lua
-- Status Bar Display - Separate Bar and Text Frames
-- Shows MSW buff count via direct aura query (non-secret in WoW 12.0)
-- Only displays when Enhancement spec with MSW talent is active
-- ===================================================================

-- Class check - Exit if not Shaman
local _, playerClass = UnitClass("player")
if playerClass ~= "SHAMAN" then return end

local ADDON, ns = ...
ns.RealMSW = ns.RealMSW or {}

-- ===================================================================
-- ENSURE REALMSW DEFAULTS EXIST
-- Call this when enabling Real MSW mode to ensure old profiles work
-- ===================================================================
local function EnsureRealMSWDefaults()
  local db = ns.API.GetDB()
  if not db then return end
  
  -- Initialize realMSWBar table if missing
  if not db.realMSWBar then
    db.realMSWBar = {}
  end
  
  local cfg = db.realMSWBar
  
  -- Set defaults for any missing values
  if cfg.enabled == nil then cfg.enabled = true end
  if cfg.showBar == nil then cfg.showBar = true end
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
  
  -- Initialize color ranges if missing
  if not cfg.colorRanges then
    cfg.colorRanges = {
      low = {enabled = false, maxStacks = 3, color = {r=0.024, g=0, b=1, a=1}},
      mid = {enabled = false, maxStacks = 7, color = {r=1, g=0.761, b=0.051, a=1}},
      high = {enabled = false, maxStacks = 10, color = {r=0.875, g=0, b=1, a=1}}
    }
  end
  
  local dbg = ns.API.GetDB()
  if dbg and dbg.debugRealMSW then
    print("|cff00ccffMWRB|r[REALMSW] Ensured defaults for realMSWBar config")
  end
end

-- Export for use by other modules
ns.RealMSW.EnsureDefaults = EnsureRealMSWDefaults

-- Display frames (separate)
local barFrame = nil
local textFrame = nil
local updateFrame = nil

-- References to bar components
local statusBar = nil
local barBackground = nil
local barBorder = nil
local drawnBorderLines = {}  -- For simple drawn borders (not textures)

-- Layered bars (for combo point style display)
local layeredBars = {}

-- Folded bars (stacked 5+5 display) - TWO SEPARATE bar containers
local foldedContainerFrame = nil  -- Master container (for positioning both bars together)
local foldedBottomFrame = nil     -- Container for bottom bar (1-5)
local foldedBottomBar = nil       -- StatusBar for stacks 1-5
local foldedBottomBg = nil        -- Background for bottom bar
local foldedBottomBorderLines = {} -- Border lines for bottom bar
local foldedBottomTickMarks = {}   -- Tick marks for bottom bar
local foldedBottomTickOverlay = nil -- Tick overlay frame for bottom bar

local foldedTopFrame = nil        -- Container for top bar (6-10)
local foldedTopBar = nil          -- StatusBar for stacks 6-10
local foldedTopBg = nil           -- Background for top bar
local foldedTopBorderLines = {}    -- Border lines for top bar
local foldedTopTickMarks = {}      -- Tick marks for top bar
local foldedTopTickOverlay = nil   -- Tick overlay frame for top bar

-- Segment bars (10 individual status bars, one per stack)
local segmentFrames = {}  -- 10 separate frames
local segmentBars = {}    -- 10 status bars
local segmentBgs = {}     -- 10 backgrounds

-- Tick mark frames
local tickMarks = {}
local tickOverlayFrame = nil

-- Bar textures now fetched from LibSharedMedia via ns.LSM.FetchStatusBar()

-- ===================================================================
-- GET MSW STACKS
-- Uses C_UnitAuras API for direct aura data access
-- Returns the actual stack value (might be secret in combat)
-- ===================================================================
local function GetMSWStacks()
  -- Use the Tracker's centralized MSW count (MSW stacks are non-secret in WoW 12.0)
  if ns.API.GetMSWCount then
    return ns.API.GetMSWCount()
  end
  return 0
end


-- ===================================================================
-- SAVE POSITIONS
-- ===================================================================
local function SaveBarPosition()
  if not barFrame then return end
  
  local db = ns.API.GetDB()
  if not db or not db.realMSWBar then return end
  
  local point, _, relPoint, x, y = barFrame:GetPoint()
  
  db.realMSWBar.barPosition = {
    point = point or "CENTER",
    relPoint = relPoint or "CENTER",
    x = x or 0,
    y = y or 200
  }
  
  if db.debugRealMSW then
    print("|cff00ccffMWRB|r[REALMSW] Saved bar position:", point, relPoint, x, y)
  end
end

local function SaveTextPosition()
  if not textFrame then return end
  
  local db = ns.API.GetDB()
  if not db or not db.realMSWBar then return end
  
  local point, _, relPoint, x, y = textFrame:GetPoint()
  
  db.realMSWBar.textPosition = {
    point = point or "CENTER",
    relPoint = relPoint or "CENTER",
    x = x or 0,
    y = y or 230
  }
  
  if db.debugRealMSW then
    print("|cff00ccffMWRB|r[REALMSW] Saved text position:", point, relPoint, x, y)
  end
end

-- Save folded bottom bar position
local function SaveFoldedBottomPosition()
  if not foldedContainerFrame then return end
  
  local db = ns.API.GetDB()
  if not db or not db.realMSWBar then return end
  
  local point, _, relPoint, x, y = foldedContainerFrame:GetPoint()
  
  db.realMSWBar.foldedBottomPosition = {
    point = point or "CENTER",
    relPoint = relPoint or "CENTER",
    x = x or 0,
    y = y or 180
  }
end

-- ===================================================================
-- GET BAR COLOR BASED ON STACK COUNT
-- Uses ns.overlayMSWCount (from overlay events) for threshold comparisons
-- since the real MSW value from CD Manager is a "secret value" that can't be compared
-- ===================================================================
local function GetBarColor(stackCount)
  local db = ns.API.GetDB()
  if not db or not db.realMSWBar then
    return 0, 0.5, 1, 1
  end
  
  local cfg = db.realMSWBar
  
  -- Use overlay MSW count for ALL comparisons (the stackCount param is secret and can't be compared)
  local overlayCount = ns.overlayMSWCount or 0
  
  -- Check threshold color overrides first (from Conditionals tab)
  -- These are triggered by overlay events and have priority
  if db.threshold2Enabled and db.threshold2 and db.threshold2.colorEnabled then
    local thresh = db.threshold2
    if thresh.stacks and overlayCount >= thresh.stacks then
      local c = thresh.color or {r=1, g=0, b=0, a=1}
      return c.r, c.g, c.b, c.a or 1
    end
  end
  
  if db.threshold1Enabled and db.threshold1 and db.threshold1.colorEnabled then
    local thresh = db.threshold1
    if thresh.stacks and overlayCount >= thresh.stacks then
      local c = thresh.color or {r=1, g=0.5, b=0, a=1}
      return c.r, c.g, c.b, c.a or 1
    end
  end
  
  -- If gradient disabled, use base color
  if not cfg.useGradient then
    local c = cfg.barColor or {r=0, g=0.5, b=1, a=1}
    return c.r, c.g, c.b, c.a
  end
  
  -- Use gradient system (similar to predictive bar)
  -- Also use overlayCount for gradient comparisons
  local ranges = cfg.colorRanges or {}
  
  -- Check high range first (highest stacks)
  if ranges.high and ranges.high.enabled and overlayCount >= (ranges.high.maxStacks or 10) then
    local c = ranges.high.color or {r=0.875, g=0, b=1, a=1}
    return c.r, c.g, c.b, c.a
  end
  
  -- Check mid range
  if ranges.mid and ranges.mid.enabled and overlayCount >= (ranges.mid.maxStacks or 5) then
    local c = ranges.mid.color or {r=1, g=0.761, b=0.051, a=1}
    return c.r, c.g, c.b, c.a
  end
  
  -- Check low range
  if ranges.low and ranges.low.enabled and overlayCount >= (ranges.low.maxStacks or 1) then
    local c = ranges.low.color or {r=0.024, g=0, b=1, a=1}
    return c.r, c.g, c.b, c.a
  end
  
  -- Below all ranges, use base color
  local c = cfg.barColor or {r=0, g=0.5, b=1, a=1}
  return c.r, c.g, c.b, c.a
end

-- ===================================================================
-- GET FOLDED BAR COLORS BASED ON THRESHOLDS
-- Returns separate colors for bottom (1-5) and top (6-10) bars
-- Uses ns.overlayMSWCount for threshold comparisons
-- ===================================================================
local function GetFoldedBarColors()
  local db = ns.API.GetDB()
  if not db or not db.realMSWBar then
    return {r=0, g=0.5, b=1, a=1}, {r=1, g=0.5, b=0, a=1}
  end
  
  local cfg = db.realMSWBar
  local overlayCount = ns.overlayMSWCount or 0
  
  -- Default colors from folded bar settings
  local bottomColor = cfg.foldedBottomColor or {r=0, g=0.5, b=1, a=1}
  local topColor = cfg.foldedTopColor or {r=1, g=0.5, b=0, a=1}
  
  -- Check threshold 1 (typically 5 stacks) - affects bottom bar color
  if db.threshold1Enabled and db.threshold1 and db.threshold1.colorEnabled then
    local thresh = db.threshold1
    if thresh.stacks and overlayCount >= thresh.stacks then
      -- Threshold 1 met - override bottom bar color
      bottomColor = thresh.color or {r=1, g=0.5, b=0, a=1}
    end
  end
  
  -- Check threshold 2 (typically 10 stacks) - affects top bar color
  if db.threshold2Enabled and db.threshold2 and db.threshold2.colorEnabled then
    local thresh = db.threshold2
    if thresh.stacks and overlayCount >= thresh.stacks then
      -- Threshold 2 met - override top bar color
      topColor = thresh.color or {r=1, g=0, b=0, a=1}
    end
  end
  
  return bottomColor, topColor
end

-- ===================================================================
-- APPLY FOLDED BAR THRESHOLD COLORS
-- Called when overlay MSW count changes to update folded bar colors
-- ===================================================================
local function ApplyFoldedBarThresholdColors()
  if not foldedBottomBar or not foldedTopBar then return end
  
  local db = ns.API.GetDB()
  if not db or db.displayMode ~= "realMSW" then return end
  
  local cfg = db.realMSWBar or {}
  if cfg.displayMode ~= "folded" then return end
  
  local bottomColor, topColor = GetFoldedBarColors()
  
  foldedBottomBar:SetStatusBarColor(bottomColor.r, bottomColor.g, bottomColor.b, bottomColor.a or 1)
  foldedTopBar:SetStatusBarColor(topColor.r, topColor.g, topColor.b, topColor.a or 1)
  
  if db.debugRealMSW then
    local overlayCount = ns.overlayMSWCount or 0
    print(string.format("|cff00ccffMWRB|r[REALMSW] Applied folded bar threshold colors (overlay count: %d)", overlayCount))
  end
end

-- ===================================================================
-- CREATE BAR FRAME
-- ===================================================================
local function CreateBarFrame()
  if barFrame then return end
  
  local db = ns.API.GetDB()
  local cfg = db.realMSWBar or {}
  
  -- Create container frame
  barFrame = CreateFrame("Frame", "MWRB_RealMSWBarFrame", UIParent)
  barFrame:SetSize(cfg.width or 200, cfg.height or 20)
  barFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 200)
  barFrame:SetFrameStrata(cfg.barFrameStrata or "MEDIUM")
  if cfg.barFrameLevel then
    barFrame:SetFrameLevel(cfg.barFrameLevel)
  end
  
  -- Create status bar
  statusBar = CreateFrame("StatusBar", nil, barFrame)
  statusBar:SetAllPoints(barFrame)
  
  -- Set texture using LSM (handles atlas textures automatically)
  local textureName = cfg.texture or "Blizzard"
  if ns.LSM and ns.LSM.ApplyStatusBarTexture then
    ns.LSM.ApplyStatusBarTexture(statusBar, textureName)
  else
    local texturePath = "Interface\\TargetingFrame\\UI-StatusBar"
    statusBar:SetStatusBarTexture(texturePath)
  end
  
  -- Set initial color
  statusBar:SetStatusBarColor(0, 0.5, 1, 1)
  statusBar:SetMinMaxValues(0, 10)
  statusBar:SetValue(0)
  
  -- Set fill style (Beta 3: now uses enum instead of string)
  local fillStyle = cfg.fillStyle or "STANDARD"
  if fillStyle == "CENTER" then
    statusBar:SetFillStyle(Enum.StatusBarFillStyle.Center)
  elseif fillStyle == "REVERSE" then
    statusBar:SetFillStyle(Enum.StatusBarFillStyle.Reverse)
  else
    statusBar:SetFillStyle(Enum.StatusBarFillStyle.Standard)
  end
  
  -- Set orientation and fill direction
  local fillDir = cfg.fillDirection or "LEFT_TO_RIGHT"
  
  if fillDir == "BOTTOM_TO_TOP" or fillDir == "TOP_TO_BOTTOM" then
    statusBar:SetOrientation("VERTICAL")
  else
    statusBar:SetOrientation("HORIZONTAL")
  end
  
  if fillDir == "RIGHT_TO_LEFT" or fillDir == "TOP_TO_BOTTOM" then
    statusBar:SetReverseFill(true)
  end
  
  -- Set rotates texture
  if cfg.rotatesTexture then
    statusBar:SetRotatesTexture(true)
  end
  
  -- Create layered bars if in layered mode (combo point style)
  if cfg.displayMode == "layered" then
    for i = 1, 10 do
      local layerBar = CreateFrame("StatusBar", nil, barFrame)
      layerBar:SetAllPoints(barFrame)
      
      -- Apply texture (handles atlas textures automatically)
      if ns.LSM and ns.LSM.ApplyStatusBarTexture then
        ns.LSM.ApplyStatusBarTexture(layerBar, textureName)
      else
        layerBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
      end
      
      -- Each bar maxes out at its stack number
      layerBar:SetMinMaxValues(0, i)
      layerBar:SetValue(0)
      
      -- Set orientation same as main bar
      if fillDir == "BOTTOM_TO_TOP" or fillDir == "TOP_TO_BOTTOM" then
        layerBar:SetOrientation("VERTICAL")
      else
        layerBar:SetOrientation("HORIZONTAL")
      end
      
      if fillDir == "RIGHT_TO_LEFT" or fillDir == "TOP_TO_BOTTOM" then
        layerBar:SetReverseFill(true)
      end
      
      -- Set color from layeredBarColors
      local color = cfg.layeredBarColors and cfg.layeredBarColors[i] or {r=1, g=1, b=1, a=1}
      layerBar:SetStatusBarColor(color.r, color.g, color.b, color.a or 1)
      
      -- Higher frame levels for higher stacks (so they show on top)
      layerBar:SetFrameLevel(barFrame:GetFrameLevel() + i)
      
      layeredBars[i] = layerBar
    end
    
    -- Hide main statusBar when using layered mode
    statusBar:Hide()
  elseif cfg.displayMode == "folded" then
    -- =================================================================
    -- FOLDED MODE: Two SEPARATE draggable frames (1-5 and 6-10)
    -- Uses SetMinMaxValues trick to avoid secret value comparisons!
    -- Each frame can be positioned independently.
    -- =================================================================
    
    -- Hide main statusBar - we use separate frames for folded mode
    statusBar:Hide()
    
    -- Don't create folded bars here - they're created by CreateFoldedFrames()
    -- Just hide main bar frame in folded mode
    barFrame:Hide()
    
  else
    -- Hide layered bars when not in use
    for i = 1, #layeredBars do
      if layeredBars[i] then
        layeredBars[i]:Hide()
      end
    end
    
    -- Hide folded bars when not in use
    if foldedContainerFrame then foldedContainerFrame:Hide() end
    if foldedBottomBar then foldedBottomBar:Hide() end
    if foldedTopBar then foldedTopBar:Hide() end
    if foldedBottomBg then foldedBottomBg:Hide() end
    if foldedTopBg then foldedTopBg:Hide() end
  end
  
  -- Create background
  barBackground = statusBar:CreateTexture(nil, "BACKGROUND")
  barBackground:SetAllPoints(statusBar)
  barBackground:SetColorTexture(0, 0, 0, 0.5)
  
  -- Create border frame
  barBorder = CreateFrame("Frame", nil, statusBar, "BackdropTemplate")
  barBorder:SetAllPoints(statusBar)
  
  -- Make movable
  barFrame:SetMovable(true)
  barFrame:EnableMouse(true)
  barFrame:RegisterForDrag("LeftButton")
  
  barFrame:SetScript("OnDragStart", function(self)
    local db = ns.API.GetDB()
    if db and db.realMSWBar and db.realMSWBar.barMovable then
      self:StartMoving()
    end
  end)
  
  barFrame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    SaveBarPosition()
  end)
  
  -- Create tick overlay frame (sits above statusBar and layeredBars)
  tickOverlayFrame = CreateFrame("Frame", nil, barFrame)
  tickOverlayFrame:SetAllPoints(barFrame)
  tickOverlayFrame:SetFrameLevel(barFrame:GetFrameLevel() + 100)  -- Way above everything
  
  -- Create drawn border lines on tickOverlayFrame (so they're always on top)
  drawnBorderLines.top = tickOverlayFrame:CreateLine(nil, "OVERLAY")
  drawnBorderLines.bottom = tickOverlayFrame:CreateLine(nil, "OVERLAY")
  drawnBorderLines.left = tickOverlayFrame:CreateLine(nil, "OVERLAY")
  drawnBorderLines.right = tickOverlayFrame:CreateLine(nil, "OVERLAY")
  
  for _, line in pairs(drawnBorderLines) do
    line:SetDrawLayer("OVERLAY", 5)  -- Below ticks (which are 7) but above everything else
    line:Hide()
  end
  
  barFrame:Hide()
end

-- ===================================================================
-- ENSURE TEXT ON TOP
-- Keeps the stack count text 5 frame levels above all bars and icons
-- so it can never be hidden behind them.
-- ===================================================================
local STRATA_ORDER = {
  BACKGROUND = 1, LOW = 2, MEDIUM = 3, HIGH = 4,
  DIALOG = 5, FULLSCREEN = 6, FULLSCREEN_DIALOG = 7, TOOLTIP = 8,
}

local function EnsureTextOnTop()
  if not textFrame then return end

  local db = ns.API.GetDB()
  local cfg = db and db.realMSWBar or {}

  -- Text strata: match the bar strata, but never drop below MEDIUM
  -- (icon displays live on MEDIUM)
  local barStrata = cfg.barFrameStrata or "MEDIUM"
  if (STRATA_ORDER[barStrata] or 3) < 3 then
    barStrata = "MEDIUM"
  end
  textFrame:SetFrameStrata(barStrata)

  -- Frame level: 5 above the highest bar/icon element
  local maxLevel = 0
  if barFrame then
    -- Tick overlay sits at barFrame level + 100
    maxLevel = math.max(maxLevel, barFrame:GetFrameLevel() + 100)
  end
  if foldedBottomTickOverlay then
    maxLevel = math.max(maxLevel, foldedBottomTickOverlay:GetFrameLevel())
  end
  if foldedTopTickOverlay then
    maxLevel = math.max(maxLevel, foldedTopTickOverlay:GetFrameLevel())
  end
  -- Icon display container (icon modes use the text frame too when enabled)
  local iconBar = ns.API.GetBarFrame and ns.API.GetBarFrame()
  if iconBar then
    maxLevel = math.max(maxLevel, iconBar:GetFrameLevel() + 3)
  end

  textFrame:SetFrameLevel(maxLevel + 5)
end

-- ===================================================================
-- CREATE TEXT FRAME
-- ===================================================================
local function CreateTextFrame()
  if textFrame then return end
  
  local db = ns.API.GetDB()
  local cfg = db.realMSWBar or {}
  
  -- Create container frame
  textFrame = CreateFrame("Frame", "MWRB_RealMSWTextFrame", UIParent)
  textFrame:SetSize(100, 50)
  textFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 230)
  EnsureTextOnTop()  -- Always 5 frame levels above all bars and icons
  
  -- Create font string
  local text = textFrame:CreateFontString(nil, "OVERLAY")
  
  -- Set font
  local fontPath = "Fonts\\FRIZQT__.TTF"
  local fontName = cfg.font or "Friz Quadrata TT"
  
  -- Handle basic fonts first
  if fontName == "Friz Quadrata TT" then
    fontPath = "Fonts\\FRIZQT__.TTF"
  elseif fontName == "Arial Narrow" then
    fontPath = "Fonts\\ARIALN.TTF"
  elseif ns.LSM then
    -- Try LSM
    fontPath = ns.LSM.FetchFont(fontName)
  end
  
  local fontSize = cfg.fontSize or 32
  local fontOutline = cfg.fontOutline or "OUTLINE"
  
  text:SetFont(fontPath, fontSize, fontOutline)
  text:SetPoint("CENTER", textFrame, "CENTER", 0, 0)
  text:SetText("0")
  
  -- Set alignment
  local alignment = cfg.textAlignment or "CENTER"
  text:SetJustifyH(alignment)
  
  -- Set color
  local c = cfg.textColor or {r=1, g=1, b=1, a=1}
  text:SetTextColor(c.r, c.g, c.b, c.a)
  text:SetShadowOffset(2, -2)
  text:SetShadowColor(0, 0, 0, 1)
  
  textFrame.text = text
  
  -- Make movable
  textFrame:SetMovable(true)
  textFrame:EnableMouse(true)
  textFrame:RegisterForDrag("LeftButton")
  
  textFrame:SetScript("OnDragStart", function(self)
    local db = ns.API.GetDB()
    if db and db.realMSWBar and db.realMSWBar.textMovable then
      self:StartMoving()
    end
  end)
  
  textFrame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    SaveTextPosition()
  end)
  
  textFrame:Hide()
end

-- ===================================================================
-- ===================================================================
-- CREATE FOLDED FRAMES (Two separate bars with per-bar settings)
-- Uses SEPARATE settings from standard bar (folded-specific)
-- ===================================================================
local function CreateFoldedFrames()
  local db = ns.API.GetDB()
  local cfg = db.realMSWBar or {}
  
  -- Get per-bar settings
  local bottomScale = cfg.foldedBottomScale or 1.0
  local bottomWidth = cfg.foldedBottomWidth or 200
  local bottomHeight = cfg.foldedBottomHeight or 20
  local bottomOpacity = cfg.foldedBottomOpacity or 1.0
  
  local topScale = cfg.foldedTopScale or 1.0
  local topWidth = cfg.foldedTopWidth or 200
  local topHeight = cfg.foldedTopHeight or 20
  local topOpacity = cfg.foldedTopOpacity or 1.0
  
  local stackOrder = cfg.foldedStackOrder or "bottom_on_bottom"
  
  local textureName = cfg.foldedTexture or "Blizzard"
  local fillDir = cfg.foldedFillDirection or "LEFT_TO_RIGHT"
  
  -- =================================================================
  -- MASTER CONTAINER (for moving both bars together)
  -- =================================================================
  if not foldedContainerFrame then
    foldedContainerFrame = CreateFrame("Frame", "MWRB_FoldedContainerFrame", UIParent)
    foldedContainerFrame:SetFrameStrata(cfg.barFrameStrata or "MEDIUM")
    if cfg.barFrameLevel then
      foldedContainerFrame:SetFrameLevel(cfg.barFrameLevel)
    end
    foldedContainerFrame:SetMovable(true)
    foldedContainerFrame:EnableMouse(true)
    foldedContainerFrame:RegisterForDrag("LeftButton")
    
    local pos = cfg.foldedBottomPosition or {point="CENTER", relPoint="CENTER", x=0, y=180}
    foldedContainerFrame:SetPoint(pos.point, UIParent, pos.relPoint, pos.x, pos.y)
    
    foldedContainerFrame:SetScript("OnDragStart", function(self)
      local db = ns.API.GetDB()
      if db and db.realMSWBar and db.realMSWBar.foldedBottomMovable ~= false then
        self:StartMoving()
      end
    end)
    
    foldedContainerFrame:SetScript("OnDragStop", function(self)
      self:StopMovingOrSizing()
      SaveFoldedBottomPosition()
    end)
  end
  
  -- Calculate container size (overlaid bars, so use max dimensions)
  local maxWidth = math.max(bottomWidth * bottomScale, topWidth * topScale)
  local maxHeight = math.max(bottomHeight * bottomScale, topHeight * topScale)
  foldedContainerFrame:SetSize(maxWidth, maxHeight)
  
  -- =================================================================
  -- BOTTOM BAR FRAME (stacks 1-5)
  -- =================================================================
  if not foldedBottomFrame then
    foldedBottomFrame = CreateFrame("Frame", "MWRB_FoldedBottomBarFrame", foldedContainerFrame, "BackdropTemplate")
    foldedBottomFrame:SetFrameStrata(cfg.barFrameStrata or "MEDIUM")
    
    -- Background
    foldedBottomBg = foldedBottomFrame:CreateTexture(nil, "BACKGROUND")
    foldedBottomBg:SetAllPoints()
    
    -- StatusBar
    foldedBottomBar = CreateFrame("StatusBar", nil, foldedBottomFrame)
    foldedBottomBar:SetAllPoints()
    foldedBottomBar:SetMinMaxValues(0, 5)
    foldedBottomBar:SetValue(0)
    
    -- Tick overlay frame (above StatusBar) - level set later
    foldedBottomTickOverlay = CreateFrame("Frame", nil, foldedBottomFrame)
    foldedBottomTickOverlay:SetAllPoints()
    
    -- Border lines (on tick overlay so they're above everything)
    foldedBottomBorderLines.top = foldedBottomTickOverlay:CreateLine(nil, "OVERLAY")
    foldedBottomBorderLines.bottom = foldedBottomTickOverlay:CreateLine(nil, "OVERLAY")
    foldedBottomBorderLines.left = foldedBottomTickOverlay:CreateLine(nil, "OVERLAY")
    foldedBottomBorderLines.right = foldedBottomTickOverlay:CreateLine(nil, "OVERLAY")
    for _, line in pairs(foldedBottomBorderLines) do
      line:SetDrawLayer("OVERLAY", 7)
    end
  end
  
  -- =================================================================
  -- TOP BAR FRAME (stacks 6-10)
  -- =================================================================
  if not foldedTopFrame then
    foldedTopFrame = CreateFrame("Frame", "MWRB_FoldedTopBarFrame", foldedContainerFrame, "BackdropTemplate")
    foldedTopFrame:SetFrameStrata(cfg.barFrameStrata or "MEDIUM")
    
    -- Background
    foldedTopBg = foldedTopFrame:CreateTexture(nil, "BACKGROUND")
    foldedTopBg:SetAllPoints()
    
    -- StatusBar
    foldedTopBar = CreateFrame("StatusBar", nil, foldedTopFrame)
    foldedTopBar:SetAllPoints()
    foldedTopBar:SetMinMaxValues(5, 10)
    foldedTopBar:SetValue(5)  -- Start at 5 (empty for 6-10 range)
    
    -- Tick overlay frame (above StatusBar) - level set later
    foldedTopTickOverlay = CreateFrame("Frame", nil, foldedTopFrame)
    foldedTopTickOverlay:SetAllPoints()
    
    -- Border lines (on tick overlay so they're above everything)
    foldedTopBorderLines.top = foldedTopTickOverlay:CreateLine(nil, "OVERLAY")
    foldedTopBorderLines.bottom = foldedTopTickOverlay:CreateLine(nil, "OVERLAY")
    foldedTopBorderLines.left = foldedTopTickOverlay:CreateLine(nil, "OVERLAY")
    foldedTopBorderLines.right = foldedTopTickOverlay:CreateLine(nil, "OVERLAY")
    for _, line in pairs(foldedTopBorderLines) do
      line:SetDrawLayer("OVERLAY", 7)
    end
  end
  
  -- =================================================================
  -- APPLY SETTINGS TO BOTH BARS
  -- =================================================================
  
  -- Apply size and scale to bottom bar
  foldedBottomFrame:SetSize(bottomWidth, bottomHeight)
  foldedBottomFrame:SetScale(bottomScale)
  foldedBottomFrame:SetAlpha(bottomOpacity)
  
  -- Apply size and scale to top bar
  foldedTopFrame:SetSize(topWidth, topHeight)
  foldedTopFrame:SetScale(topScale)
  foldedTopFrame:SetAlpha(topOpacity)
  
  -- Update container size (uses the larger of the two bars)
  local maxWidth = math.max(bottomWidth * bottomScale, topWidth * topScale)
  local maxHeight = math.max(bottomHeight * bottomScale, topHeight * topScale)
  foldedContainerFrame:SetSize(maxWidth, maxHeight)
  
  -- Position BOTH bars overlaid at the same location (centered in container)
  foldedBottomFrame:ClearAllPoints()
  foldedTopFrame:ClearAllPoints()
  foldedBottomFrame:SetPoint("CENTER", foldedContainerFrame, "CENTER", 0, 0)
  foldedTopFrame:SetPoint("CENTER", foldedContainerFrame, "CENTER", 0, 0)
  
  -- Set frame levels based on stacking order (which bar renders in front)
  if stackOrder == "top_on_bottom" then
    -- 6-10 bar renders behind, 1-5 bar renders in front
    foldedTopFrame:SetFrameLevel(foldedContainerFrame:GetFrameLevel() + 1)
    foldedBottomFrame:SetFrameLevel(foldedContainerFrame:GetFrameLevel() + 2)
  else
    -- 1-5 bar renders behind (default), 6-10 bar renders in front
    foldedBottomFrame:SetFrameLevel(foldedContainerFrame:GetFrameLevel() + 1)
    foldedTopFrame:SetFrameLevel(foldedContainerFrame:GetFrameLevel() + 2)
  end
  
  -- Set tick overlay frame levels AFTER parent frame levels are set
  if foldedBottomTickOverlay then
    foldedBottomTickOverlay:SetFrameLevel(foldedBottomFrame:GetFrameLevel() + 10)
  end
  if foldedTopTickOverlay then
    foldedTopTickOverlay:SetFrameLevel(foldedTopFrame:GetFrameLevel() + 10)
  end
  
  -- =================================================================
  -- APPLY TEXTURES AND COLORS
  -- =================================================================
  
  -- Bottom bar texture and color
  if ns.LSM and ns.LSM.ApplyStatusBarTexture then
    ns.LSM.ApplyStatusBarTexture(foldedBottomBar, textureName)
  else
    foldedBottomBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
  end
  local bottomColor = cfg.foldedBottomColor or {r=0, g=0.5, b=1, a=1}
  foldedBottomBar:SetStatusBarColor(bottomColor.r, bottomColor.g, bottomColor.b, bottomColor.a or 1)
  
  -- Top bar texture and color
  if ns.LSM and ns.LSM.ApplyStatusBarTexture then
    ns.LSM.ApplyStatusBarTexture(foldedTopBar, textureName)
  else
    foldedTopBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
  end
  local topColor = cfg.foldedTopColor or {r=1, g=0.5, b=0, a=1}
  foldedTopBar:SetStatusBarColor(topColor.r, topColor.g, topColor.b, topColor.a or 1)
  
  -- Apply fill direction
  local isVertical = (fillDir == "BOTTOM_TO_TOP" or fillDir == "TOP_TO_BOTTOM")
  local isReverse = (fillDir == "RIGHT_TO_LEFT" or fillDir == "TOP_TO_BOTTOM")
  
  foldedBottomBar:SetOrientation(isVertical and "VERTICAL" or "HORIZONTAL")
  foldedTopBar:SetOrientation(isVertical and "VERTICAL" or "HORIZONTAL")
  foldedBottomBar:SetReverseFill(isReverse)
  foldedTopBar:SetReverseFill(isReverse)
  
  -- =================================================================
  -- APPLY BOTTOM BAR BACKGROUND
  -- =================================================================
  local showBottomBg = cfg.foldedBottomShowBackground ~= false
  if not showBottomBg then
    foldedBottomBg:Hide()
  else
    foldedBottomBg:Show()
    local bgColor = cfg.foldedBottomBackgroundColor or {r=0.2, g=0.2, b=0.2, a=0.8}
    local bgTextureName = cfg.foldedBottomBackgroundTexture or "Solid"
    
    if bgTextureName == "None" then
      foldedBottomBg:Hide()
    elseif bgTextureName == "Solid" then
      foldedBottomBg:SetColorTexture(bgColor.r, bgColor.g, bgColor.b, bgColor.a or 0.8)
    else
      local bgTexPath = ns.LSM and ns.LSM.FetchBackground(bgTextureName) or nil
      if bgTexPath then
        foldedBottomBg:SetTexture(bgTexPath)
        foldedBottomBg:SetVertexColor(bgColor.r, bgColor.g, bgColor.b, bgColor.a or 0.8)
      else
        foldedBottomBg:SetColorTexture(bgColor.r, bgColor.g, bgColor.b, bgColor.a or 0.8)
      end
    end
  end
  
  -- =================================================================
  -- APPLY TOP BAR BACKGROUND
  -- =================================================================
  local showTopBg = cfg.foldedTopShowBackground ~= false
  if not showTopBg then
    foldedTopBg:Hide()
  else
    foldedTopBg:Show()
    local bgColor = cfg.foldedTopBackgroundColor or {r=0.2, g=0.2, b=0.2, a=0.8}
    local bgTextureName = cfg.foldedTopBackgroundTexture or "Solid"
    
    if bgTextureName == "None" then
      foldedTopBg:Hide()
    elseif bgTextureName == "Solid" then
      foldedTopBg:SetColorTexture(bgColor.r, bgColor.g, bgColor.b, bgColor.a or 0.8)
    else
      local bgTexPath = ns.LSM and ns.LSM.FetchBackground(bgTextureName) or nil
      if bgTexPath then
        foldedTopBg:SetTexture(bgTexPath)
        foldedTopBg:SetVertexColor(bgColor.r, bgColor.g, bgColor.b, bgColor.a or 0.8)
      else
        foldedTopBg:SetColorTexture(bgColor.r, bgColor.g, bgColor.b, bgColor.a or 0.8)
      end
    end
  end
  
  -- =================================================================
  -- APPLY BOTTOM BAR BORDER
  -- =================================================================
  local showBottomBorder = cfg.foldedBottomShowBorder ~= false
  local bottomBorderColor = cfg.foldedBottomBorderColor or {r=1, g=1, b=1, a=1}
  local bottomBorderThickness = cfg.foldedBottomBorderThickness or 2
  
  if not showBottomBorder then
    for _, line in pairs(foldedBottomBorderLines) do
      if line then line:Hide() end
    end
  else
    for _, line in pairs(foldedBottomBorderLines) do
      line:SetThickness(bottomBorderThickness)
      line:SetColorTexture(bottomBorderColor.r, bottomBorderColor.g, bottomBorderColor.b, bottomBorderColor.a or 1)
    end
    
    foldedBottomBorderLines.top:ClearAllPoints()
    foldedBottomBorderLines.top:SetStartPoint("TOPLEFT", foldedBottomFrame, 0, 0)
    foldedBottomBorderLines.top:SetEndPoint("TOPRIGHT", foldedBottomFrame, 0, 0)
    foldedBottomBorderLines.top:Show()
    
    foldedBottomBorderLines.bottom:ClearAllPoints()
    foldedBottomBorderLines.bottom:SetStartPoint("BOTTOMLEFT", foldedBottomFrame, 0, 0)
    foldedBottomBorderLines.bottom:SetEndPoint("BOTTOMRIGHT", foldedBottomFrame, 0, 0)
    foldedBottomBorderLines.bottom:Show()
    
    foldedBottomBorderLines.left:ClearAllPoints()
    foldedBottomBorderLines.left:SetStartPoint("TOPLEFT", foldedBottomFrame, 0, 0)
    foldedBottomBorderLines.left:SetEndPoint("BOTTOMLEFT", foldedBottomFrame, 0, 0)
    foldedBottomBorderLines.left:Show()
    
    foldedBottomBorderLines.right:ClearAllPoints()
    foldedBottomBorderLines.right:SetStartPoint("TOPRIGHT", foldedBottomFrame, 0, 0)
    foldedBottomBorderLines.right:SetEndPoint("BOTTOMRIGHT", foldedBottomFrame, 0, 0)
    foldedBottomBorderLines.right:Show()
  end
  
  -- =================================================================
  -- APPLY TOP BAR BORDER
  -- =================================================================
  local showTopBorder = cfg.foldedTopShowBorder ~= false
  local topBorderColor = cfg.foldedTopBorderColor or {r=1, g=1, b=1, a=1}
  local topBorderThickness = cfg.foldedTopBorderThickness or 2
  
  if not showTopBorder then
    for _, line in pairs(foldedTopBorderLines) do
      if line then line:Hide() end
    end
  else
    for _, line in pairs(foldedTopBorderLines) do
      line:SetThickness(topBorderThickness)
      line:SetColorTexture(topBorderColor.r, topBorderColor.g, topBorderColor.b, topBorderColor.a or 1)
    end
    
    foldedTopBorderLines.top:ClearAllPoints()
    foldedTopBorderLines.top:SetStartPoint("TOPLEFT", foldedTopFrame, 0, 0)
    foldedTopBorderLines.top:SetEndPoint("TOPRIGHT", foldedTopFrame, 0, 0)
    foldedTopBorderLines.top:Show()
    
    foldedTopBorderLines.bottom:ClearAllPoints()
    foldedTopBorderLines.bottom:SetStartPoint("BOTTOMLEFT", foldedTopFrame, 0, 0)
    foldedTopBorderLines.bottom:SetEndPoint("BOTTOMRIGHT", foldedTopFrame, 0, 0)
    foldedTopBorderLines.bottom:Show()
    
    foldedTopBorderLines.left:ClearAllPoints()
    foldedTopBorderLines.left:SetStartPoint("TOPLEFT", foldedTopFrame, 0, 0)
    foldedTopBorderLines.left:SetEndPoint("BOTTOMLEFT", foldedTopFrame, 0, 0)
    foldedTopBorderLines.left:Show()
    
    foldedTopBorderLines.right:ClearAllPoints()
    foldedTopBorderLines.right:SetStartPoint("TOPRIGHT", foldedTopFrame, 0, 0)
    foldedTopBorderLines.right:SetEndPoint("BOTTOMRIGHT", foldedTopFrame, 0, 0)
    foldedTopBorderLines.right:Show()
  end
  
  -- =================================================================
  -- APPLY TICK MARKS
  -- =================================================================
  -- Clear old tick marks
  for _, tick in ipairs(foldedBottomTickMarks) do
    if tick then tick:Hide() end
  end
  foldedBottomTickMarks = {}
  
  for _, tick in ipairs(foldedTopTickMarks) do
    if tick then tick:Hide() end
  end
  foldedTopTickMarks = {}
  
  local tickColor = cfg.foldedTickColor or {r=1, g=1, b=1, a=0.8}
  local tickThickness = cfg.foldedTickThickness or 2
  
  -- Bottom bar tick marks (on tick overlay frame)
  if cfg.foldedTicksBottomEnabled and foldedBottomTickOverlay then
    for i = 1, 4 do
      local tick = foldedBottomTickOverlay:CreateLine(nil, "OVERLAY")
      tick:SetDrawLayer("OVERLAY", 5)
      tick:SetThickness(tickThickness)
      tick:SetColorTexture(tickColor.r, tickColor.g, tickColor.b, tickColor.a or 0.8)
      
      local xPos = (bottomWidth / 5) * i
      tick:SetStartPoint("TOPLEFT", foldedBottomFrame, xPos, 0)
      tick:SetEndPoint("BOTTOMLEFT", foldedBottomFrame, xPos, 0)
      tick:Show()
      
      foldedBottomTickMarks[i] = tick
    end
  end
  
  -- Top bar tick marks (on tick overlay frame)
  if cfg.foldedTicksTopEnabled and foldedTopTickOverlay then
    for i = 1, 4 do
      local tick = foldedTopTickOverlay:CreateLine(nil, "OVERLAY")
      tick:SetDrawLayer("OVERLAY", 5)
      tick:SetThickness(tickThickness)
      tick:SetColorTexture(tickColor.r, tickColor.g, tickColor.b, tickColor.a or 0.8)
      
      local xPos = (topWidth / 5) * i
      tick:SetStartPoint("TOPLEFT", foldedTopFrame, xPos, 0)
      tick:SetEndPoint("BOTTOMLEFT", foldedTopFrame, xPos, 0)
      tick:Show()
      
      foldedTopTickMarks[i] = tick
    end
  end
  
  -- Initially hidden
  foldedContainerFrame:Hide()
end

-- ===================================================================
-- UPDATE TICK MARKS
-- ===================================================================
local function UpdateTickMarks()
  if not barFrame or not statusBar or not tickOverlayFrame then return end
  
  local db = ns.API.GetDB()
  if not db or not db.realMSWBar then return end
  
  local cfg = db.realMSWBar
  
  -- DEBUG
  if cfg.debugRealMSW or db.debugRealMSW then
    print("|cff00ccffMWRB|r[TICK DEBUG] UpdateTickMarks called")
    print("  showTickMarks:", tostring(cfg.showTickMarks))
    print("  showCustomTicks:", tostring(cfg.showCustomTicks))
  end
  
  -- IMPORTANT: Completely clear and recreate tick marks (old ones might be textures)
  for i = 1, #tickMarks do
    if tickMarks[i] then
      tickMarks[i]:Hide()
      tickMarks[i]:SetParent(nil)
    end
  end
  tickMarks = {}
  
  -- Check if tick marks should be shown
  if not cfg.showTickMarks and not cfg.showCustomTicks then
    if cfg.debugRealMSW or db.debugRealMSW then
      print("|cff00ccffMWRB|r[TICK DEBUG] Neither showTickMarks nor showCustomTicks enabled - exiting")
    end
    return
  end
  
  local positions = {}
  
  if cfg.showTickMarks then
    -- Show all 9 tick marks (at positions 1-9)
    for i = 1, 9 do
      table.insert(positions, i)
    end
  elseif cfg.showCustomTicks and cfg.customTicks then
    -- Show only custom positions
    for _, pos in ipairs(cfg.customTicks) do
      table.insert(positions, pos)
    end
  end
  
  -- DEBUG
  if cfg.debugRealMSW or db.debugRealMSW then
    print("|cff00ccffMWRB|r[TICK DEBUG] Positions array:", #positions, "items")
    for i, pos in ipairs(positions) do
      print("  Position[" .. i .. "]:", pos)
    end
  end
  
  -- Create tick marks using LINES for consistent thickness
  -- IMPORTANT: Calculate thickness ONCE for ALL ticks to ensure consistency
  local thickness = cfg.tickThickness or 2
  local width = cfg.width or 200
  local height = cfg.height or 20
  local fillDir = cfg.fillDirection or "HORIZONTAL"
  local tc = cfg.tickColor or {r=0, g=0, b=0, a=1}
  
  -- DEBUG
  if cfg.debugRealMSW or db.debugRealMSW then
    print("|cff00ccffMWRB|r[TICK DEBUG] Bar dimensions:")
    print("  width:", width, "height:", height)
    print("  fillDirection:", fillDir)
    print("  thickness:", thickness)
  end
  
  -- Determine if bar is vertical based on fillDirection
  local isVertical = (fillDir == "BOTTOM_TO_TOP" or fillDir == "TOP_TO_BOTTOM" or fillDir == "VERTICAL")
  
  -- Calculate segment size
  local segmentSize = isVertical and (height / 10) or (width / 10)
  
  for _, stackPos in ipairs(positions) do
    -- Create tick marks on tickOverlayFrame (which sits above statusBar and layeredBars)
    tickMarks[stackPos] = tickOverlayFrame:CreateLine(nil, "OVERLAY")
    
    local tick = tickMarks[stackPos]
    
    -- Set draw layer to OVERLAY
    tick:SetDrawLayer("OVERLAY", 7)
    
    -- Set color and thickness IMMEDIATELY after creation
    tick:SetColorTexture(tc.r, tc.g, tc.b, tc.a or 1.0)
    tick:SetThickness(thickness)
    
    -- Clear any existing points
    tick:ClearAllPoints()
    
    -- Position based on orientation - anchor to tickOverlayFrame (which has same size as barFrame)
    if isVertical then
      -- Vertical bar - horizontal tick marks
      tick:SetThickness(thickness)
      
      -- ROUND to integer pixels to avoid anti-aliasing issues
      local yOffset = math.floor(segmentSize * stackPos + 0.5)
      tick:SetStartPoint("BOTTOMLEFT", tickOverlayFrame, 0, yOffset)
      tick:SetEndPoint("BOTTOMLEFT", tickOverlayFrame, width, yOffset)
      
      if cfg.debugRealMSW or db.debugRealMSW then
        local tickWidth = width
        local tickHeight = thickness
        print("|cff00ccffMWRB|r[TICK DEBUG] Created VERTICAL tick at position", stackPos, "yOffset:", yOffset, "thickness:", thickness, "width:", tickWidth, "height:", tickHeight)
      end
    else
      -- Horizontal bar - vertical tick marks
      tick:SetThickness(thickness)
      
      -- ROUND to integer pixels to avoid anti-aliasing issues
      local xOffset = math.floor(segmentSize * stackPos + 0.5)
      tick:SetStartPoint("TOPLEFT", tickOverlayFrame, xOffset, 0)
      tick:SetEndPoint("TOPLEFT", tickOverlayFrame, xOffset, -height)
      
      if cfg.debugRealMSW or db.debugRealMSW then
        local tickWidth = thickness
        local tickHeight = height
        print("|cff00ccffMWRB|r[TICK DEBUG] Created HORIZONTAL tick at position", stackPos, "xOffset:", xOffset, "thickness:", thickness, "width:", tickWidth, "height:", tickHeight)
      end
    end
    
    tick:Show()
    
    if cfg.debugRealMSW or db.debugRealMSW then
      print("|cff00ccffMWRB|r[TICK DEBUG] Tick", stackPos, "shown - IsShown:", tick:IsShown())
    end
  end
  
  -- DEBUG final count
  if cfg.debugRealMSW or db.debugRealMSW then
    print("|cff00ccffMWRB|r[TICK DEBUG] Total tick marks created:", #positions)
  end
end

-- ===================================================================
-- UPDATE BAR APPEARANCE
-- ===================================================================
local function UpdateBarAppearance()
  if not barFrame or not statusBar or not barBackground or not barBorder then 
    -- Frames not created yet
    return 
  end
  
  local db = ns.API.GetDB()
  if not db or not db.realMSWBar then return end
  
  local cfg = db.realMSWBar
  
  -- Update size (apply scale if present)
  local baseWidth = cfg.width or 200
  local baseHeight = cfg.height or 20
  local scale = cfg.barScale or 1.0
  
  barFrame:SetSize(baseWidth, baseHeight)
  barFrame:SetScale(scale)  -- Apply uniform scale
  
  -- Update texture using LSM (handles atlas textures automatically)
  local textureName = cfg.texture or "Blizzard"
  if ns.LSM and ns.LSM.ApplyStatusBarTexture then
    ns.LSM.ApplyStatusBarTexture(statusBar, textureName)
  else
    statusBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
  end
  
  -- Update layered bars if in layered mode
  if cfg.displayMode == "layered" then
    for i = 1, 10 do
      if layeredBars[i] then
        -- Apply texture (handles atlas textures automatically)
        if ns.LSM and ns.LSM.ApplyStatusBarTexture then
          ns.LSM.ApplyStatusBarTexture(layeredBars[i], textureName)
        else
          layeredBars[i]:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
        end
        
        -- Update color from layeredBarColors
        local color = cfg.layeredBarColors and cfg.layeredBarColors[i] or {r=1, g=1, b=1, a=1}
        layeredBars[i]:SetStatusBarColor(color.r, color.g, color.b, color.a or 1)
        
        -- Update orientation
        if fillDir == "BOTTOM_TO_TOP" or fillDir == "TOP_TO_BOTTOM" then
          layeredBars[i]:SetOrientation("VERTICAL")
        else
          layeredBars[i]:SetOrientation("HORIZONTAL")
        end
        
        if fillDir == "RIGHT_TO_LEFT" or fillDir == "TOP_TO_BOTTOM" then
          layeredBars[i]:SetReverseFill(true)
        else
          layeredBars[i]:SetReverseFill(false)
        end
      end
    end
  end
  
  -- Update fill style (Beta 3: now uses enum instead of string)
  local fillStyle = cfg.fillStyle or "STANDARD"
  if fillStyle == "CENTER" then
    statusBar:SetFillStyle(Enum.StatusBarFillStyle.Center)
  elseif fillStyle == "REVERSE" then
    statusBar:SetFillStyle(Enum.StatusBarFillStyle.Reverse)
  else
    statusBar:SetFillStyle(Enum.StatusBarFillStyle.Standard)
  end
  
  -- Update orientation and reverse fill based on fillDirection
  local fillDir = cfg.fillDirection or "LEFT_TO_RIGHT"
  if fillDir == "BOTTOM_TO_TOP" or fillDir == "TOP_TO_BOTTOM" then
    statusBar:SetOrientation("VERTICAL")
  else
    statusBar:SetOrientation("HORIZONTAL")
  end
  
  if fillDir == "RIGHT_TO_LEFT" or fillDir == "TOP_TO_BOTTOM" then
    statusBar:SetReverseFill(true)
  else
    statusBar:SetReverseFill(false)
  end
  
  -- Update rotates texture
  if cfg.rotatesTexture then
    statusBar:SetRotatesTexture(true)
  else
    statusBar:SetRotatesTexture(false)
  end
  
  -- Update background
  if cfg.showBackground then
    barBackground:Show()
    
    local bgTextureName = cfg.backgroundTexture or "Solid"
    
    -- Handle special cases
    if bgTextureName == "None" then
      barBackground:Hide()
    elseif bgTextureName == "Solid" then
      -- Use solid color
      local bg = cfg.backgroundColor or {r=0, g=0, b=0, a=0.5}
      barBackground:SetColorTexture(bg.r, bg.g, bg.b, bg.a)
    else
      -- Try to use background texture from LSM
      local bgTexPath = ns.LSM and ns.LSM.FetchBackground(bgTextureName) or nil
      
      if bgTexPath then
        barBackground:SetTexture(bgTexPath)
        -- Apply background color as tint
        local bg = cfg.backgroundColor or {r=1, g=1, b=1, a=0.8}
        barBackground:SetVertexColor(bg.r, bg.g, bg.b, bg.a)
      else
        -- Fallback to solid color if texture not found
        local bg = cfg.backgroundColor or {r=0, g=0, b=0, a=0.5}
        barBackground:SetColorTexture(bg.r, bg.g, bg.b, bg.a)
      end
    end
  else
    barBackground:Hide()
  end
  
  -- Update border
  if cfg.showBorder then
    local borderStyle = cfg.borderStyle or "Drawn"  -- Default to Drawn
    
    if borderStyle == "Drawn" then
      -- Use drawn borders (Line objects)
      barBorder:Hide()  -- Hide texture border frame
      
      local thickness = cfg.drawnBorderThickness or 2
      local bc = cfg.borderColor or {r=0.5, g=0.5, b=0.5, a=1}
      local width = cfg.width or 200
      local height = cfg.height or 20
      
      -- Update all border lines
      for _, line in pairs(drawnBorderLines) do
        line:SetColorTexture(bc.r, bc.g, bc.b, bc.a or 1)
        line:SetThickness(thickness)
      end
      
      -- Top border
      drawnBorderLines.top:ClearAllPoints()
      drawnBorderLines.top:SetStartPoint("TOPLEFT", tickOverlayFrame, 0, 0)
      drawnBorderLines.top:SetEndPoint("TOPLEFT", tickOverlayFrame, width, 0)
      drawnBorderLines.top:Show()
      
      -- Bottom border
      drawnBorderLines.bottom:ClearAllPoints()
      drawnBorderLines.bottom:SetStartPoint("BOTTOMLEFT", tickOverlayFrame, 0, 0)
      drawnBorderLines.bottom:SetEndPoint("BOTTOMLEFT", tickOverlayFrame, width, 0)
      drawnBorderLines.bottom:Show()
      
      -- Left border
      drawnBorderLines.left:ClearAllPoints()
      drawnBorderLines.left:SetStartPoint("TOPLEFT", tickOverlayFrame, 0, 0)
      drawnBorderLines.left:SetEndPoint("TOPLEFT", tickOverlayFrame, 0, -height)
      drawnBorderLines.left:Show()
      
      -- Right border
      drawnBorderLines.right:ClearAllPoints()
      drawnBorderLines.right:SetStartPoint("TOPRIGHT", tickOverlayFrame, 0, 0)
      drawnBorderLines.right:SetEndPoint("TOPRIGHT", tickOverlayFrame, 0, -height)
      drawnBorderLines.right:Show()
    else
      -- Fallback: also use drawn borders for any other value
      barBorder:Hide()
      for _, line in pairs(drawnBorderLines) do
        line:Hide()
      end
    end
  else
    barBorder:Hide()
    for _, line in pairs(drawnBorderLines) do
      line:Hide()
    end
  end
  
  -- Update opacity
  barFrame:SetAlpha(cfg.opacity or 1.0)
  
  -- Update desaturation
  if cfg.desaturated then
    statusBar:SetStatusBarDesaturated(true)
    local desatAmount = cfg.desaturation or 0.5
    statusBar:SetStatusBarDesaturation(desatAmount)
  else
    statusBar:SetStatusBarDesaturated(false)
  end
  
  -- Update tick marks
  UpdateTickMarks()
  
  -- NOTE: Folded bar is NOT updated here - it has separate settings
  -- Use UpdateFoldedAppearance() or Refresh(true) to update folded bar
end

-- ===================================================================
-- UPDATE FOLDED APPEARANCE (separate from standard bar)
-- ===================================================================
local function UpdateFoldedAppearance()
  if not foldedContainerFrame then return end
  
  local db = ns.API.GetDB()
  if not db or not db.realMSWBar then return end
  
  local cfg = db.realMSWBar
  
  -- Get per-bar settings
  local bottomScale = cfg.foldedBottomScale or 1.0
  local bottomWidth = cfg.foldedBottomWidth or 200
  local bottomHeight = cfg.foldedBottomHeight or 20
  local bottomOpacity = cfg.foldedBottomOpacity or 1.0
  
  local topScale = cfg.foldedTopScale or 1.0
  local topWidth = cfg.foldedTopWidth or 200
  local topHeight = cfg.foldedTopHeight or 20
  local topOpacity = cfg.foldedTopOpacity or 1.0
  
  local stackOrder = cfg.foldedStackOrder or "bottom_on_bottom"
  
  local textureName = cfg.foldedTexture or "Blizzard"
  local fillDir = cfg.foldedFillDirection or "LEFT_TO_RIGHT"
  
  -- Update container size (overlaid bars, so use max dimensions)
  local maxWidth = math.max(bottomWidth * bottomScale, topWidth * topScale)
  local maxHeight = math.max(bottomHeight * bottomScale, topHeight * topScale)
  foldedContainerFrame:SetSize(maxWidth, maxHeight)
  
  -- Apply size and scale to bottom bar
  if foldedBottomFrame then
    foldedBottomFrame:SetSize(bottomWidth, bottomHeight)
    foldedBottomFrame:SetScale(bottomScale)
    foldedBottomFrame:SetAlpha(bottomOpacity)
  end
  
  -- Apply size and scale to top bar
  if foldedTopFrame then
    foldedTopFrame:SetSize(topWidth, topHeight)
    foldedTopFrame:SetScale(topScale)
    foldedTopFrame:SetAlpha(topOpacity)
  end
  
  -- Position BOTH bars overlaid at the same location (centered in container)
  if foldedBottomFrame and foldedTopFrame then
    foldedBottomFrame:ClearAllPoints()
    foldedTopFrame:ClearAllPoints()
    foldedBottomFrame:SetPoint("CENTER", foldedContainerFrame, "CENTER", 0, 0)
    foldedTopFrame:SetPoint("CENTER", foldedContainerFrame, "CENTER", 0, 0)
    
    -- Set frame levels based on stacking order (which bar renders in front)
    if stackOrder == "top_on_bottom" then
      -- 6-10 bar renders behind, 1-5 bar renders in front
      foldedTopFrame:SetFrameLevel(foldedContainerFrame:GetFrameLevel() + 1)
      foldedBottomFrame:SetFrameLevel(foldedContainerFrame:GetFrameLevel() + 2)
    else
      -- 1-5 bar renders behind (default), 6-10 bar renders in front
      foldedBottomFrame:SetFrameLevel(foldedContainerFrame:GetFrameLevel() + 1)
      foldedTopFrame:SetFrameLevel(foldedContainerFrame:GetFrameLevel() + 2)
    end
    
    -- Set tick overlay frame levels AFTER parent frame levels are set
    if foldedBottomTickOverlay then
      foldedBottomTickOverlay:SetFrameLevel(foldedBottomFrame:GetFrameLevel() + 10)
    end
    if foldedTopTickOverlay then
      foldedTopTickOverlay:SetFrameLevel(foldedTopFrame:GetFrameLevel() + 10)
    end
  end
  
  -- Update textures and colors
  if foldedBottomBar then
    if ns.LSM and ns.LSM.ApplyStatusBarTexture then
      ns.LSM.ApplyStatusBarTexture(foldedBottomBar, textureName)
    end
    local bottomColor = cfg.foldedBottomColor or {r=0, g=0.5, b=1, a=1}
    foldedBottomBar:SetStatusBarColor(bottomColor.r, bottomColor.g, bottomColor.b, bottomColor.a or 1)
  end
  
  if foldedTopBar then
    if ns.LSM and ns.LSM.ApplyStatusBarTexture then
      ns.LSM.ApplyStatusBarTexture(foldedTopBar, textureName)
    end
    local topColor = cfg.foldedTopColor or {r=1, g=0.5, b=0, a=1}
    foldedTopBar:SetStatusBarColor(topColor.r, topColor.g, topColor.b, topColor.a or 1)
  end
  
  -- Apply fill direction
  local isVertical = (fillDir == "BOTTOM_TO_TOP" or fillDir == "TOP_TO_BOTTOM")
  local isReverse = (fillDir == "RIGHT_TO_LEFT" or fillDir == "TOP_TO_BOTTOM")
  
  if foldedBottomBar then
    foldedBottomBar:SetOrientation(isVertical and "VERTICAL" or "HORIZONTAL")
    foldedBottomBar:SetReverseFill(isReverse)
  end
  if foldedTopBar then
    foldedTopBar:SetOrientation(isVertical and "VERTICAL" or "HORIZONTAL")
    foldedTopBar:SetReverseFill(isReverse)
  end
  
  -- =================================================================
  -- UPDATE BOTTOM BAR BACKGROUND
  -- =================================================================
  if foldedBottomBg then
    local showBg = cfg.foldedBottomShowBackground ~= false
    if not showBg then
      foldedBottomBg:Hide()
    else
      foldedBottomBg:Show()
      local bgColor = cfg.foldedBottomBackgroundColor or {r=0.2, g=0.2, b=0.2, a=0.8}
      local bgTextureName = cfg.foldedBottomBackgroundTexture or "Solid"
      
      if bgTextureName == "None" then
        foldedBottomBg:Hide()
      elseif bgTextureName == "Solid" then
        foldedBottomBg:SetColorTexture(bgColor.r, bgColor.g, bgColor.b, bgColor.a or 0.8)
      else
        local bgTexPath = ns.LSM and ns.LSM.FetchBackground(bgTextureName) or nil
        if bgTexPath then
          foldedBottomBg:SetTexture(bgTexPath)
          foldedBottomBg:SetVertexColor(bgColor.r, bgColor.g, bgColor.b, bgColor.a or 0.8)
        else
          foldedBottomBg:SetColorTexture(bgColor.r, bgColor.g, bgColor.b, bgColor.a or 0.8)
        end
      end
    end
  end
  
  -- =================================================================
  -- UPDATE TOP BAR BACKGROUND
  -- =================================================================
  if foldedTopBg then
    local showBg = cfg.foldedTopShowBackground ~= false
    if not showBg then
      foldedTopBg:Hide()
    else
      foldedTopBg:Show()
      local bgColor = cfg.foldedTopBackgroundColor or {r=0.2, g=0.2, b=0.2, a=0.8}
      local bgTextureName = cfg.foldedTopBackgroundTexture or "Solid"
      
      if bgTextureName == "None" then
        foldedTopBg:Hide()
      elseif bgTextureName == "Solid" then
        foldedTopBg:SetColorTexture(bgColor.r, bgColor.g, bgColor.b, bgColor.a or 0.8)
      else
        local bgTexPath = ns.LSM and ns.LSM.FetchBackground(bgTextureName) or nil
        if bgTexPath then
          foldedTopBg:SetTexture(bgTexPath)
          foldedTopBg:SetVertexColor(bgColor.r, bgColor.g, bgColor.b, bgColor.a or 0.8)
        else
          foldedTopBg:SetColorTexture(bgColor.r, bgColor.g, bgColor.b, bgColor.a or 0.8)
        end
      end
    end
  end
  
  -- =================================================================
  -- UPDATE BOTTOM BAR BORDER
  -- =================================================================
  if foldedBottomBorderLines.top then
    local showBorder = cfg.foldedBottomShowBorder ~= false
    local borderColor = cfg.foldedBottomBorderColor or {r=1, g=1, b=1, a=1}
    local borderThickness = cfg.foldedBottomBorderThickness or 2
    
    if not showBorder then
      for _, line in pairs(foldedBottomBorderLines) do
        if line then line:Hide() end
      end
    else
      for _, line in pairs(foldedBottomBorderLines) do
        line:SetThickness(borderThickness)
        line:SetColorTexture(borderColor.r, borderColor.g, borderColor.b, borderColor.a or 1)
      end
      
      foldedBottomBorderLines.top:ClearAllPoints()
      foldedBottomBorderLines.top:SetStartPoint("TOPLEFT", foldedBottomFrame, 0, 0)
      foldedBottomBorderLines.top:SetEndPoint("TOPRIGHT", foldedBottomFrame, 0, 0)
      foldedBottomBorderLines.top:Show()
      
      foldedBottomBorderLines.bottom:ClearAllPoints()
      foldedBottomBorderLines.bottom:SetStartPoint("BOTTOMLEFT", foldedBottomFrame, 0, 0)
      foldedBottomBorderLines.bottom:SetEndPoint("BOTTOMRIGHT", foldedBottomFrame, 0, 0)
      foldedBottomBorderLines.bottom:Show()
      
      foldedBottomBorderLines.left:ClearAllPoints()
      foldedBottomBorderLines.left:SetStartPoint("TOPLEFT", foldedBottomFrame, 0, 0)
      foldedBottomBorderLines.left:SetEndPoint("BOTTOMLEFT", foldedBottomFrame, 0, 0)
      foldedBottomBorderLines.left:Show()
      
      foldedBottomBorderLines.right:ClearAllPoints()
      foldedBottomBorderLines.right:SetStartPoint("TOPRIGHT", foldedBottomFrame, 0, 0)
      foldedBottomBorderLines.right:SetEndPoint("BOTTOMRIGHT", foldedBottomFrame, 0, 0)
      foldedBottomBorderLines.right:Show()
    end
  end
  
  -- =================================================================
  -- UPDATE TOP BAR BORDER
  -- =================================================================
  if foldedTopBorderLines.top then
    local showBorder = cfg.foldedTopShowBorder ~= false
    local borderColor = cfg.foldedTopBorderColor or {r=1, g=1, b=1, a=1}
    local borderThickness = cfg.foldedTopBorderThickness or 2
    
    if not showBorder then
      for _, line in pairs(foldedTopBorderLines) do
        if line then line:Hide() end
      end
    else
      for _, line in pairs(foldedTopBorderLines) do
        line:SetThickness(borderThickness)
        line:SetColorTexture(borderColor.r, borderColor.g, borderColor.b, borderColor.a or 1)
      end
      
      foldedTopBorderLines.top:ClearAllPoints()
      foldedTopBorderLines.top:SetStartPoint("TOPLEFT", foldedTopFrame, 0, 0)
      foldedTopBorderLines.top:SetEndPoint("TOPRIGHT", foldedTopFrame, 0, 0)
      foldedTopBorderLines.top:Show()
      
      foldedTopBorderLines.bottom:ClearAllPoints()
      foldedTopBorderLines.bottom:SetStartPoint("BOTTOMLEFT", foldedTopFrame, 0, 0)
      foldedTopBorderLines.bottom:SetEndPoint("BOTTOMRIGHT", foldedTopFrame, 0, 0)
      foldedTopBorderLines.bottom:Show()
      
      foldedTopBorderLines.left:ClearAllPoints()
      foldedTopBorderLines.left:SetStartPoint("TOPLEFT", foldedTopFrame, 0, 0)
      foldedTopBorderLines.left:SetEndPoint("BOTTOMLEFT", foldedTopFrame, 0, 0)
      foldedTopBorderLines.left:Show()
      
      foldedTopBorderLines.right:ClearAllPoints()
      foldedTopBorderLines.right:SetStartPoint("TOPRIGHT", foldedTopFrame, 0, 0)
      foldedTopBorderLines.right:SetEndPoint("BOTTOMRIGHT", foldedTopFrame, 0, 0)
      foldedTopBorderLines.right:Show()
    end
  end
  
  -- =================================================================
  -- UPDATE TICK MARKS
  -- =================================================================
  local tickColor = cfg.foldedTickColor or {r=1, g=1, b=1, a=0.8}
  local tickThickness = cfg.foldedTickThickness or 2
  
  -- Update bottom bar tick marks
  if cfg.foldedTicksBottomEnabled and foldedBottomTickOverlay then
    if #foldedBottomTickMarks == 0 then
      -- Create tick marks on overlay frame
      for i = 1, 4 do
        local tick = foldedBottomTickOverlay:CreateLine(nil, "OVERLAY")
        tick:SetDrawLayer("OVERLAY", 5)
        tick:SetThickness(tickThickness)
        tick:SetColorTexture(tickColor.r, tickColor.g, tickColor.b, tickColor.a or 0.8)
        
        local xPos = (bottomWidth / 5) * i
        tick:SetStartPoint("TOPLEFT", foldedBottomFrame, xPos, 0)
        tick:SetEndPoint("BOTTOMLEFT", foldedBottomFrame, xPos, 0)
        tick:Show()
        
        foldedBottomTickMarks[i] = tick
      end
    else
      for i, tick in ipairs(foldedBottomTickMarks) do
        if tick then
          tick:SetThickness(tickThickness)
          tick:SetColorTexture(tickColor.r, tickColor.g, tickColor.b, tickColor.a or 0.8)
          local xPos = (bottomWidth / 5) * i
          tick:ClearAllPoints()
          tick:SetStartPoint("TOPLEFT", foldedBottomFrame, xPos, 0)
          tick:SetEndPoint("BOTTOMLEFT", foldedBottomFrame, xPos, 0)
          tick:Show()
        end
      end
    end
  else
    for _, tick in ipairs(foldedBottomTickMarks) do
      if tick then tick:Hide() end
    end
  end
  
  -- Update top bar tick marks
  if cfg.foldedTicksTopEnabled and foldedTopTickOverlay then
    if #foldedTopTickMarks == 0 then
      -- Create tick marks on overlay frame
      for i = 1, 4 do
        local tick = foldedTopTickOverlay:CreateLine(nil, "OVERLAY")
        tick:SetDrawLayer("OVERLAY", 5)
        tick:SetThickness(tickThickness)
        tick:SetColorTexture(tickColor.r, tickColor.g, tickColor.b, tickColor.a or 0.8)
        
        local xPos = (topWidth / 5) * i
        tick:SetStartPoint("TOPLEFT", foldedTopFrame, xPos, 0)
        tick:SetEndPoint("BOTTOMLEFT", foldedTopFrame, xPos, 0)
        tick:Show()
        
        foldedTopTickMarks[i] = tick
      end
    else
      for i, tick in ipairs(foldedTopTickMarks) do
        if tick then
          tick:SetThickness(tickThickness)
          tick:SetColorTexture(tickColor.r, tickColor.g, tickColor.b, tickColor.a or 0.8)
          local xPos = (topWidth / 5) * i
          tick:ClearAllPoints()
          tick:SetStartPoint("TOPLEFT", foldedTopFrame, xPos, 0)
          tick:SetEndPoint("BOTTOMLEFT", foldedTopFrame, xPos, 0)
          tick:Show()
        end
      end
    end
  else
    for _, tick in ipairs(foldedTopTickMarks) do
      if tick then tick:Hide() end
    end
  end
end


-- ===================================================================
-- UPDATE TEXT APPEARANCE
-- ===================================================================
local function UpdateTextAppearance()
  if not textFrame or not textFrame.text then return end
  
  local db = ns.API.GetDB()
  if not db or not db.realMSWBar then return end
  
  local cfg = db.realMSWBar
  
  -- Update font
  local fontPath = "Fonts\\FRIZQT__.TTF"
  local fontName = cfg.font or "Friz Quadrata TT"
  
  -- Handle basic fonts first
  if fontName == "Friz Quadrata TT" then
    fontPath = "Fonts\\FRIZQT__.TTF"
  elseif fontName == "Arial Narrow" then
    fontPath = "Fonts\\ARIALN.TTF"
  elseif ns.LSM then
    -- Try LSM
    fontPath = ns.LSM.FetchFont(fontName)
  end
  
  local fontSize = cfg.fontSize or 32
  local fontOutline = cfg.fontOutline or "OUTLINE"
  
  textFrame.text:SetFont(fontPath, fontSize, fontOutline)
  
  -- Update frame strata/level (always 5 levels above all bars and icons)
  EnsureTextOnTop()
  
  -- Update alignment
  local alignment = cfg.textAlignment or "CENTER"
  textFrame.text:SetJustifyH(alignment)
  
  -- Update color
  local c = cfg.textColor or {r=1, g=1, b=1, a=1}
  textFrame.text:SetTextColor(c.r, c.g, c.b, c.a)
  
  -- Update shadow
  textFrame.text:SetShadowOffset(2, -2)
  textFrame.text:SetShadowColor(0, 0, 0, 1)
  
  -- Show/hide text based on showText setting
  if cfg.showText == false then
    textFrame:Hide()
  else
    if db.displayMode == "realMSW" then
      textFrame:Show()
    end
  end
end

-- ===================================================================
-- UPDATE DISPLAY
-- ===================================================================
local function UpdateDisplay()
  -- Create frames if they don't exist
  if not barFrame then
    CreateBarFrame()
  end
  if not textFrame then
    CreateTextFrame()
  end
  
  if not barFrame or not textFrame then return end
  
  local db = ns.API.GetDB()
  if not db then return end
  
  -- Get stack value (works in all modes)
  local stackValue = GetMSWStacks()
  
  -- Check force hide (affects everything)
  if db.forceHide then
    barFrame:Hide()
    textFrame:Hide()
    if foldedContainerFrame then foldedContainerFrame:Hide() end
    return
  end
  
  -- Check hide out of combat setting
  if db.hideOutOfCombat then
    local inCombat = UnitAffectingCombat("player") or InCombatLockdown() or false
    if not inCombat then
      barFrame:Hide()
      textFrame:Hide()
      if foldedContainerFrame then foldedContainerFrame:Hide() end
      return
    end
  end
  
  -- Check spec/talent (skip for realMSW mode - user explicitly selected Status Bar)
  if db.displayMode ~= "realMSW" then
    if ns.API.ShouldShowUI and not ns.API.ShouldShowUI() then
      barFrame:Hide()
      textFrame:Hide()
      if foldedContainerFrame then foldedContainerFrame:Hide() end
      return
    end
  end
  
  -- Handle BAR display (only in realMSW mode)
  if db.displayMode == "realMSW" then
    local cfg = db.realMSWBar or {}
    
    -- Check if bar should be shown (showBar toggle)
    local showBar = cfg.showBar ~= false
    
    if not showBar then
      -- Text-only mode - hide all bar frames
      barFrame:Hide()
      if foldedContainerFrame then foldedContainerFrame:Hide() end
      statusBar:Hide()
      for i = 1, 10 do
        if layeredBars[i] then
          layeredBars[i]:Hide()
        end
      end
    elseif cfg.displayMode == "layered" then
      -- Layered bars mode: update all layers with same value
      barFrame:Show()
      for i = 1, 10 do
        if layeredBars[i] then
          layeredBars[i]:SetValue(stackValue)
          layeredBars[i]:Show()
        end
      end
      -- Hide main status bar and folded frame in layered mode
      statusBar:Hide()
      if foldedContainerFrame then foldedContainerFrame:Hide() end
      
    elseif cfg.displayMode == "folded" then
      -- =================================================================
      -- FOLDED MODE: Two overlaid status bars in ONE frame
      -- Bottom bar (0-5): fills for stacks 1-5, stays full at 6+
      -- Top bar (5-10): empty at 0-5, fills for stacks 6-10
      -- 
      -- THE MAGIC: We pass the SAME stackValue to both bars!
      -- SetMinMaxValues handles the clamping internally, so we never
      -- need to do math on the secret value ourselves.
      -- =================================================================
      
      -- Create folded frames if they don't exist
      if not foldedBottomFrame then
        CreateFoldedFrames()
      end
      
      -- Show and update both bars (both in the same frame)
      if foldedBottomFrame then
        if foldedBottomBar then
          foldedBottomBar:SetValue(stackValue)
        end
        if foldedTopBar then
          foldedTopBar:SetValue(stackValue)
        end
        foldedContainerFrame:Show()
        
        -- Apply threshold colors to folded bars
        ApplyFoldedBarThresholdColors()
      end
      
      -- Hide main bar frame and layered bars in folded mode
      barFrame:Hide()
      statusBar:Hide()
      for i = 1, 10 do
        if layeredBars[i] then
          layeredBars[i]:Hide()
        end
      end
      
    else
      -- Normal single bar mode
      barFrame:Show()
      statusBar:SetValue(stackValue)
      statusBar:Show()
      
      -- Hide layered bars
      for i = 1, 10 do
        if layeredBars[i] then
          layeredBars[i]:Hide()
        end
      end
      
      -- Hide folded frame
      if foldedContainerFrame then foldedContainerFrame:Hide() end
      
      -- Update bar color based on stack count
      local r, g, b, a = GetBarColor(stackValue)
      statusBar:SetStatusBarColor(r, g, b, a)
    end
  else
    -- Hide bar in non-realMSW modes
    barFrame:Hide()
    -- Also hide folded frame
    if foldedContainerFrame then foldedContainerFrame:Hide() end
  end
  
  -- Handle TEXT display (works in ALL modes when enabled)
  if db.realMSWBar and db.realMSWBar.showText then
    textFrame:Show()
    textFrame.text:SetText(stackValue)
  else
    textFrame:Hide()
  end
end

-- ===================================================================
-- APPLY POSITIONS
-- ===================================================================
local function ApplyPositions()
  if not barFrame or not textFrame then return end
  
  local db = ns.API.GetDB()
  if not db or not db.realMSWBar then return end
  
  local cfg = db.realMSWBar
  
  -- Apply bar position
  if not cfg.barPosition then
    cfg.barPosition = {point="CENTER", relPoint="CENTER", x=0, y=200}
  end
  
  local bPos = cfg.barPosition
  barFrame:ClearAllPoints()
  barFrame:SetPoint(
    bPos.point or "CENTER",
    UIParent,
    bPos.relPoint or "CENTER",
    bPos.x or 0,
    bPos.y or 200
  )
  
  -- Apply text position
  if not cfg.textPosition then
    cfg.textPosition = {point="CENTER", relPoint="CENTER", x=0, y=230}
  end
  
  local tPos = cfg.textPosition
  textFrame:ClearAllPoints()
  textFrame:SetPoint(
    tPos.point or "CENTER",
    UIParent,
    tPos.relPoint or "CENTER",
    tPos.x or 0,
    tPos.y or 230
  )
  
  if db.debugRealMSW then
    print("|cff00ccffMWRB|r[REALMSW] Applied positions")
  end
end

-- ===================================================================
-- START/STOP UPDATES
-- ===================================================================

-- Polling system (like ArcUI) - catch rapid aura updates
local pollTimers = {}

local function SchedulePolls()
  -- Cancel any existing polls
  for _, timer in ipairs(pollTimers) do
    if timer then
      timer:Cancel()
    end
  end
  pollTimers = {}
  
  -- Poll 3 times after event: 0.05s, 0.1s, 0.2s (like ArcUI)
  local pollTimes = {0.05, 0.1, 0.2}
  
  for _, delay in ipairs(pollTimes) do
    local timer = C_Timer.NewTimer(delay, function()
      UpdateDisplay()
    end)
    table.insert(pollTimers, timer)
  end
end

local function StartUpdates()
  if updateFrame then return end
  
  updateFrame = CreateFrame("Frame")
  updateFrame:RegisterUnitEvent("UNIT_AURA", "player")
  updateFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
  updateFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
  updateFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
  updateFrame:RegisterEvent("TRAIT_CONFIG_UPDATED")
  updateFrame:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
  
  updateFrame:SetScript("OnEvent", function(self, event, ...)
    -- Immediate update
    UpdateDisplay()
    
    -- Schedule 3 polls to catch rapid updates
    -- Some MSW generations/refunds don't register on first aura update
    if event == "UNIT_AURA" then
      SchedulePolls()
    end
  end)
  
  UpdateDisplay()
end

local function StopUpdates()
  if updateFrame then
    updateFrame:UnregisterAllEvents()
    updateFrame = nil
  end
  
  if barFrame then
    barFrame:Hide()
  end
  
  if textFrame then
    textFrame:Hide()
  end
end

-- Check if updates should be running based on current settings
local function ShouldRunUpdates()
  local db = ns.API.GetDB()
  if not db then return false end
  
  -- Run updates if in realMSW mode OR if text is enabled for other modes
  return db.displayMode == "realMSW" or (db.realMSWBar and db.realMSWBar.showText)
end

-- ===================================================================
-- PUBLIC API
-- ===================================================================
function ns.RealMSW.Initialize()
  CreateBarFrame()
  CreateTextFrame()
  
  local db = ns.API.GetDB()
  if not db then return end
  
  -- Always apply positions and appearance
  ApplyPositions()
  UpdateBarAppearance()
  UpdateTextAppearance()
  
  -- Start updates if either:
  -- 1. We're in realMSW display mode, OR
  -- 2. Real MSW text is enabled (for use in other display modes)
  if db.displayMode == "realMSW" or (db.realMSWBar and db.realMSWBar.showText) then
    StartUpdates()
    
    -- Force immediate update to show existing stacks
    C_Timer.After(0.2, function()
      if UpdateDisplay then
        UpdateDisplay()
      end
    end)
  end
end

function ns.RealMSW.Enable()
  -- Ensure defaults exist (fixes old profiles)
  EnsureRealMSWDefaults()
  
  CreateBarFrame()
  CreateTextFrame()
  ApplyPositions()
  UpdateBarAppearance()
  UpdateTextAppearance()
  StartUpdates()
  
  -- Immediately update display to show frames
  UpdateDisplay()
end

function ns.RealMSW.Disable()
  -- Immediately hide all frames first
  if barFrame then
    barFrame:Hide()
  end
  if textFrame then
    textFrame:Hide()
  end
  if foldedContainerFrame then
    foldedContainerFrame:Hide()
  end
  if foldedBottomFrame then
    foldedBottomFrame:Hide()
  end
  if foldedTopFrame then
    foldedTopFrame:Hide()
  end
  
  -- Check if we should keep updates running for text display
  local db = ns.API.GetDB()
  if db and db.realMSWBar and db.realMSWBar.showText and db.displayMode ~= "realMSW" then
    -- Keep updates running for text in icon modes
    -- Show text frame again if needed
    if textFrame then
      textFrame:Show()
    end
    UpdateDisplay()
  else
    -- Stop updates completely
    StopUpdates()
  end
end

function ns.RealMSW.Refresh(forceRecreate)
  -- If forceRecreate or if bar display mode changed, destroy and recreate
  if forceRecreate or barFrame then
    -- Destroy existing bar frame to recreate with new mode
    if barFrame then
      barFrame:Hide()
      barFrame:SetScript("OnDragStart", nil)
      barFrame:SetScript("OnDragStop", nil)
      barFrame = nil
    end
    
    -- Destroy folded frames
    if foldedContainerFrame then
      foldedContainerFrame:Hide()
      foldedContainerFrame:SetScript("OnDragStart", nil)
      foldedContainerFrame:SetScript("OnDragStop", nil)
      foldedContainerFrame = nil
    end
    if foldedBottomFrame then
      foldedBottomFrame = nil
    end
    if foldedTopFrame then
      foldedTopFrame = nil
    end
    foldedBottomBar = nil
    foldedTopBar = nil
    foldedBottomBg = nil
    foldedTopBg = nil
    foldedBottomBorderLines = {}
    foldedTopBorderLines = {}
    foldedBottomTickMarks = {}
    foldedTopTickMarks = {}
    foldedBottomTickOverlay = nil
    foldedTopTickOverlay = nil
    
    -- Clear all bar references
    statusBar = nil
    barBackground = nil
    barBorder = nil
    drawnBorderLines = {}
    layeredBars = {}
    foldedBottomBar = nil
    foldedTopBar = nil
    foldedBottomBg = nil
    foldedTopBg = nil
    foldedBottomBorder = nil
    foldedTopBorder = nil
    foldedBottomBorderLines = {}
    foldedTopBorderLines = {}
    foldedBottomTickMarks = {}
    foldedTopTickMarks = {}
    foldedBottomTickOverlay = nil
    foldedTopTickOverlay = nil
    tickMarks = {}
    tickOverlayFrame = nil
  end
  
  if not barFrame then
    CreateBarFrame()
  end
  if not textFrame then
    CreateTextFrame()
  end
  
  ApplyPositions()
  UpdateBarAppearance()
  UpdateTextAppearance()
  UpdateDisplay()
end

function ns.RealMSW.UpdateMovability(barMovable, textMovable)
  local db = ns.API.GetDB()
  if db and db.realMSWBar then
    if barMovable ~= nil then
      db.realMSWBar.barMovable = barMovable
    end
    if textMovable ~= nil then
      db.realMSWBar.textMovable = textMovable
    end
  end
end

-- Update frame strata for all bar frames
function ns.RealMSW.UpdateFrameStrata(strata)
  local db = ns.API.GetDB()
  if db and db.realMSWBar then
    db.realMSWBar.barFrameStrata = strata
  end
  
  -- Apply to all bar frames
  if barFrame then
    barFrame:SetFrameStrata(strata or "MEDIUM")
  end
  if foldedContainerFrame then
    foldedContainerFrame:SetFrameStrata(strata or "MEDIUM")
  end
  if foldedBottomFrame then
    foldedBottomFrame:SetFrameStrata(strata or "MEDIUM")
  end
  if foldedTopFrame then
    foldedTopFrame:SetFrameStrata(strata or "MEDIUM")
  end
  
  -- Keep stack text above the bars on the new strata
  EnsureTextOnTop()
end

-- Update exact frame level for all bar frames (within the chosen strata)
function ns.RealMSW.UpdateFrameLevel(level)
  local db = ns.API.GetDB()
  if db and db.realMSWBar then
    db.realMSWBar.barFrameLevel = level
  end
  
  if not level then return end
  
  -- Child frames (status bar, tick overlay, layered/folded bars) shift
  -- with their parent automatically, preserving relative offsets
  if barFrame then
    barFrame:SetFrameLevel(level)
  end
  if foldedContainerFrame then
    foldedContainerFrame:SetFrameLevel(level)
  end
  
  -- Keep stack text 5 levels above the new bar level
  EnsureTextOnTop()
end

-- Get current bar frame level (for options panel display)
function ns.RealMSW.GetBarFrameLevel()
  local db = ns.API.GetDB()
  if db and db.realMSWBar and db.realMSWBar.barFrameLevel then
    return db.realMSWBar.barFrameLevel
  end
  if barFrame then
    return barFrame:GetFrameLevel()
  end
  return 1
end

-- Set bar position X/Y directly (from options panel inputs)
function ns.RealMSW.SetBarPositionXY(x, y)
  local db = ns.API.GetDB()
  if not db or not db.realMSWBar then return end
  
  local cfg = db.realMSWBar
  cfg.barPosition = cfg.barPosition or {point="CENTER", relPoint="CENTER", x=0, y=200}
  if x ~= nil then cfg.barPosition.x = x end
  if y ~= nil then cfg.barPosition.y = y end
  ApplyPositions()
end

-- Get bar position X/Y (for options panel display)
function ns.RealMSW.GetBarPositionXY()
  local db = ns.API.GetDB()
  local pos = db and db.realMSWBar and db.realMSWBar.barPosition
  if pos then
    return pos.x or 0, pos.y or 200
  end
  return 0, 200
end

-- Set text position X/Y directly (from options panel inputs)
function ns.RealMSW.SetTextPositionXY(x, y)
  local db = ns.API.GetDB()
  if not db or not db.realMSWBar then return end
  
  local cfg = db.realMSWBar
  cfg.textPosition = cfg.textPosition or {point="CENTER", relPoint="CENTER", x=0, y=230}
  if x ~= nil then cfg.textPosition.x = x end
  if y ~= nil then cfg.textPosition.y = y end
  ApplyPositions()
end

-- Get text position X/Y (for options panel display)
function ns.RealMSW.GetTextPositionXY()
  local db = ns.API.GetDB()
  local pos = db and db.realMSWBar and db.realMSWBar.textPosition
  if pos then
    return pos.x or 0, pos.y or 230
  end
  return 0, 230
end

-- Update stacking order for folded bars (both in same frame)
function ns.RealMSW.UpdateFoldedStacking()
  if not foldedBottomFrame or not foldedBottomBar or not foldedTopBar then return end
  
  local db = ns.API.GetDB()
  local stackingOrder = db and db.realMSWBar and db.realMSWBar.foldedStackingOrder or "top_front"
  
  if stackingOrder == "bottom_front" then
    -- Bottom bar (1-5) in front
    foldedTopBar:SetFrameLevel(foldedBottomFrame:GetFrameLevel() + 1)
    foldedBottomBar:SetFrameLevel(foldedBottomFrame:GetFrameLevel() + 2)
  else
    -- Top bar (6-10) in front (default)
    foldedBottomBar:SetFrameLevel(foldedBottomFrame:GetFrameLevel() + 1)
    foldedTopBar:SetFrameLevel(foldedBottomFrame:GetFrameLevel() + 2)
  end
end

-- Export UpdateBarAppearance for options panel
function ns.RealMSW.UpdateBarAppearance()
  UpdateBarAppearance()
end

-- Export UpdateFoldedAppearance for options panel
function ns.RealMSW.UpdateFoldedAppearance()
  UpdateFoldedAppearance()
end

-- Export ApplyFoldedBarThresholdColors for options panel
function ns.RealMSW.ApplyFoldedBarThresholdColors()
  ApplyFoldedBarThresholdColors()
end

-- Export UpdateTextAppearance for options panel
function ns.RealMSW.UpdateTextAppearance()
  UpdateTextAppearance()
  
  -- Ensure updates are running if text is enabled, or stopped if it should be
  if ShouldRunUpdates() then
    if not updateFrame then
      StartUpdates()
    else
      UpdateDisplay()
    end
  else
    if updateFrame then
      StopUpdates()
    end
  end
end

-- Update bar color based on overlay event MSW count (for threshold conditionals)
-- This is called from OnMSWChanged to apply threshold color overrides
function ns.RealMSW.UpdateThresholdColor(overlayCount)
  if not statusBar then return end
  
  local db = ns.API.GetDB()
  if not db or db.displayMode ~= "realMSW" then return end
  
  local cfg = db.realMSWBar or {}
  
  -- Handle folded mode separately
  if cfg.displayMode == "folded" then
    -- Apply threshold colors to folded bars
    ApplyFoldedBarThresholdColors()
  else
    -- Use the overlay event count for threshold checks (single bar mode)
    local r, g, b, a = GetBarColor(overlayCount or 0)
    statusBar:SetStatusBarColor(r, g, b, a)
  end
  
  -- Also update text color if threshold text color is enabled
  if textFrame and textFrame.text then
    local textR, textG, textB, textA
    local count = overlayCount or 0
    
    -- Check threshold 2 first (higher priority)
    if db.threshold2Enabled and db.threshold2 and db.threshold2.textColorEnabled then
      if db.threshold2.stacks and count >= db.threshold2.stacks then
        local c = db.threshold2.textColor or {r=1, g=0, b=0, a=1}
        textR, textG, textB, textA = c.r, c.g, c.b, c.a or 1
      end
    end
    
    -- Check threshold 1 if threshold 2 didn't apply
    if not textR and db.threshold1Enabled and db.threshold1 and db.threshold1.textColorEnabled then
      if db.threshold1.stacks and count >= db.threshold1.stacks then
        local c = db.threshold1.textColor or {r=1, g=0.5, b=0, a=1}
        textR, textG, textB, textA = c.r, c.g, c.b, c.a or 1
      end
    end
    
    -- Apply threshold text color if set, otherwise use default
    if textR then
      textFrame.text:SetTextColor(textR, textG, textB, textA)
    else
      -- Use default text color from settings
      local c = cfg.textColor or {r=1, g=1, b=1, a=1}
      textFrame.text:SetTextColor(c.r, c.g, c.b, c.a or 1)
    end
  end
end

function ns.RealMSW.SetBuffIconVisibility(hide)
  local db = ns.API.GetDB()
  if db and db.realMSWBar then
    db.realMSWBar.hideBuffIconMSW = hide
  end
  -- CDM icon hiding removed - use Blizzard's Edit Mode to hide buff icons
end

function ns.RealMSW.ResetBarPosition()
  local db = ns.API.GetDB()
  if db and db.realMSWBar then
    db.realMSWBar.barPosition = {point="CENTER", relPoint="CENTER", x=0, y=200}
    ApplyPositions()
  end
end

function ns.RealMSW.ResetTextPosition()
  local db = ns.API.GetDB()
  if db and db.realMSWBar then
    db.realMSWBar.textPosition = {point="CENTER", relPoint="CENTER", x=0, y=230}
    ApplyPositions()
  end
end

-- Export GetMSWStacks for stack text display
function ns.RealMSW.GetMSWStacks()
  return GetMSWStacks()
end

-- ===================================================================
-- INITIALIZATION
-- ===================================================================
local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("PLAYER_LOGIN")
initFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
initFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
initFrame:RegisterEvent("TRAIT_CONFIG_UPDATED")

initFrame:SetScript("OnEvent", function(_, event)
  if event == "PLAYER_LOGIN" then
    C_Timer.After(0.5, function()
      ns.RealMSW.Initialize()
    end)
    
  elseif event == "PLAYER_ENTERING_WORLD" then
    -- Handle reloads and zone transitions
    C_Timer.After(0.3, function()
      local db = ns.API and ns.API.GetDB()
      if not db then return end
      
      -- Check if we should show UI (Enhancement spec with MSW talent)
      if ns.API.ShouldShowUI and not ns.API.ShouldShowUI() then
        -- Not Enhancement spec - ensure frames are hidden
        if barFrame then barFrame:Hide() end
        if textFrame then textFrame:Hide() end
        if foldedContainerFrame then foldedContainerFrame:Hide() end
        return
      end
      
      -- Re-initialize if needed
      if db.displayMode == "realMSW" or (db.realMSWBar and db.realMSWBar.showText) then
        ns.RealMSW.Initialize()
      end
    end)
    
  elseif event == "PLAYER_SPECIALIZATION_CHANGED" or event == "TRAIT_CONFIG_UPDATED" then
    -- Spec or talent changed - check if we should show/hide
    C_Timer.After(0.2, function()
      local shouldShow = ns.API.ShouldShowUI and ns.API.ShouldShowUI()
      local db = ns.API and ns.API.GetDB()
      
      if db and db.debugRealMSW then
        print("|cff00ccffMWRB|r[REALMSW] Spec/talent changed. Should show:", shouldShow and "YES" or "NO")
      end
      
      if not shouldShow then
        -- Not Enhancement spec or MSW talent not learned - hide all frames
        if barFrame then barFrame:Hide() end
        if textFrame then textFrame:Hide() end
        if foldedContainerFrame then foldedContainerFrame:Hide() end
        if foldedBottomFrame then foldedBottomFrame:Hide() end
        if foldedTopFrame then foldedTopFrame:Hide() end
        StopUpdates()
      else
        -- Spec is valid - re-initialize if in Status Bar mode
        if db and (db.displayMode == "realMSW" or (db.realMSWBar and db.realMSWBar.showText)) then
          ns.RealMSW.Initialize()
        end
      end
    end)
  end
end)

-- ===================================================================
-- END OF MWRB_RealMSWDisplay.lua
-- ===================================================================