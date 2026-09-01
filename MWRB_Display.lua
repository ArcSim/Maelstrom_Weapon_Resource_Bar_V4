-- ===================================================================
-- MWRB_Display.lua
-- Maelstrom Weapon Resource Bar v3 - Display Module (Visuals Only)
-- 
-- This module handles ALL visual rendering of MSW stacks.
-- It does NOT register combat events or compute prediction logic.
-- Input: MSW count (0â€“10) from ns.API.OnMSWChanged(count)
-- ===================================================================

-- ===================================================================
-- SECTION 01 â€“ Namespace & Frames
-- ===================================================================
-- Class check - Exit if not Shaman
local _, playerClass = UnitClass("player")
if playerClass ~= "SHAMAN" then return end

local ADDON, ns = ...
ns = ns or {}
ns.API = ns.API or {}

-- Main bar container frame
local BarFrame = CreateFrame("Frame", "MWRB_BarFrame", UIParent)
BarFrame:SetSize(350, 64)
BarFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
BarFrame:SetFrameStrata("MEDIUM")  -- Below stack text (HIGH strata)
BarFrame:SetMovable(true)
BarFrame:EnableMouse(false)
BarFrame:SetClampedToScreen(true)

-- Stack text (shows current MSW count)
-- Create draggable frame for stack text (parented to screen, not bar)
local StackTextFrame = CreateFrame("Frame", "MWRB_StackTextFrame", UIParent)
StackTextFrame:SetSize(80, 60)
StackTextFrame:SetFrameStrata("HIGH")  -- Ensure stack text is always in front
StackTextFrame:SetFrameLevel(100)  -- High frame level
-- Don't set initial position here - let applyStackTextPosition handle it
StackTextFrame:SetMovable(true)
StackTextFrame:EnableMouse(false)
StackTextFrame:RegisterForDrag("LeftButton")

-- Create the actual text
local StackText = StackTextFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
StackText:SetPoint("CENTER", StackTextFrame, "CENTER", 0, 0)
StackText:SetText("0")

StackTextFrame:SetScript("OnDragStart", function(self)
  local db = ns.API.GetDB()
  if db.movable then
    self:StartMoving()
  end
end)

StackTextFrame:SetScript("OnDragStop", function(self)
  self:StopMovingOrSizing()
  local db = ns.API.GetDB()
  -- Save full position including anchor points
  local point, _, relPoint, x, y = self:GetPoint(1)
  db.stackTextPos = {
    point = point or "CENTER",
    relPoint = relPoint or "CENTER",
    x = x or 0,
    y = y or 0
  }
  
  if db.debug then
    print("|cff00ccffMWRB|r[DISPLAY] Saved stack text position:", point, relPoint, x, y)
  end
end)

-- Icon slots (1â€“10)
local iconSlots = {}

-- Current MSW count
local currentMSW = 0

-- ===================================================================
-- SECTION 01.5 - Color Safety Helpers
-- ===================================================================
-- Safe color extraction - prevents nil errors in SetVertexColor
local function SafeColor(color, defaultColor)
  if not color then
    color = defaultColor or {r=1, g=1, b=1, a=1}
  end
  return color.r or 1, color.g or 1, color.b or 1, color.a or 1
end

-- ===================================================================
-- SECTION 02 â€“ Texture Path Resolution
-- ===================================================================
local TEXTURE_BASE = "Interface\\AddOns\\Maelstrom_Weapon_Resource_Bar_V4\\Textures\\"

-- Only using FILL textures now - no separate empty textures
-- The fill texture is used for both filled and empty states (just different colors/alpha)
--
-- NOTE: For best results with colored outline borders, circle and lightning textures
-- can have black outlines baked into them for extra definition. Not required though!
-- Square textures work great as flat textures.
local SHAPE_FILL_TEXTURES = {
  circle1 = TEXTURE_BASE .. "Points_Fill_1.blp",
  circle2 = TEXTURE_BASE .. "Points_Fill_2.tga",
  circle3 = TEXTURE_BASE .. "Points_Fill_Solid.tga",
  circle4 = TEXTURE_BASE .. "sky_8.tga",
  square = TEXTURE_BASE .. "Points_Fill_Square.tga",
  lightning1 = TEXTURE_BASE .. "Points_Fill_Lightning.tga",
  lightning2 = TEXTURE_BASE .. "Points_Fill_Lightning_Gradiant.tga",
  lightning3 = TEXTURE_BASE .. "Points_Fill_Lightning_old.tga",
}


local BORDER_TEXTURES = {
  circle1 = TEXTURE_BASE .. "Circle_Border1.tga",
  circle2 = TEXTURE_BASE .. "Circle_Border1.tga",
  circle3 = TEXTURE_BASE .. "Circle_Border1.tga",
  circle4 = TEXTURE_BASE .. "Circle_Border1.tga",
}

-- Square border texture options
local SQUARE_BORDER_TEXTURES = {
  Square_Border1 = TEXTURE_BASE .. "Square_Border1.tga",
  Square_Border2 = TEXTURE_BASE .. "Square_Border2.tga",
  Sqaure_Border3 = TEXTURE_BASE .. "Sqaure_Border3.tga",  -- Note: typo in original filename
}

-- Get fill texture for a shape
local function getShapeFillTexture(shape)
  return SHAPE_FILL_TEXTURES[shape] or SHAPE_FILL_TEXTURES.square
end


local function getShapeBorderTexture(shape)
  return BORDER_TEXTURES[shape]
end

local function getSquareBorderTexture(textureName)
  return SQUARE_BORDER_TEXTURES[textureName] or SQUARE_BORDER_TEXTURES.Square_Border1
end

-- ===================================================================
-- SECTION 03.5 â€“ Bar Mode Textures & Helpers
-- ===================================================================

-- Bar textures now fetched from LibSharedMedia via ns.LSM.FetchStatusBar()

-- Bar frame for bar mode (separate from icon container)
local StatusBar = CreateFrame("StatusBar", "MWRB_StatusBar", UIParent)
StatusBar:SetSize(200, 30)
StatusBar:SetPoint("CENTER")
StatusBar:SetFrameStrata("MEDIUM")  -- Below stack text (HIGH strata)
StatusBar:Hide()

-- Background texture
local StatusBarBG = StatusBar:CreateTexture(nil, "BACKGROUND")
StatusBarBG:SetAllPoints(StatusBar)

-- Border frame
local StatusBarBorder = CreateFrame("Frame", nil, StatusBar, BackdropTemplateMixin and "BackdropTemplate")
StatusBarBorder:SetAllPoints(StatusBar)
StatusBarBorder:Hide()

-- Text overlay on bar (reusing StackText positioning logic)
local BarText = StatusBar:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
BarText:SetPoint("CENTER", StatusBar, "CENTER", 0, 0)

-- Tick marks for bar (vertical dividers)
local BarTickMarks = {}
for i = 1, 9 do  -- 9 ticks for 10 segments
  local tick = StatusBar:CreateLine(nil, "OVERLAY")
  tick:SetColorTexture(0, 0, 0, 1)  -- Default black with full opacity
  tick:SetThickness(2)  -- Default thickness (will be scaled later)
  tick:Hide()
  BarTickMarks[i] = tick
end

-- ===================================================================
-- SECTION 03 â€“ Icon Slot Creation
-- ===================================================================
local function createIconSlot(index)
  local slot = CreateFrame("Frame", "MWRB_IconSlot" .. index, BarFrame)
  slot:SetSize(64, 64)
  
  -- Only one texture layer - the fill texture used for both filled and empty states
  -- Use inset to make texture smaller than frame (provides larger hit area)
  slot.texture = slot:CreateTexture(nil, "ARTWORK", nil, 4)
  slot.texture:SetPoint("TOPLEFT", slot, "TOPLEFT", 4, -4)
  slot.texture:SetPoint("BOTTOMRIGHT", slot, "BOTTOMRIGHT", -4, 4)
  slot.texture:SetBlendMode("BLEND")
  
  -- Texture border (for shapes with border textures)
  slot.border = slot:CreateTexture(nil, "OVERLAY", nil, 5)
  slot.border:SetAllPoints(slot.texture)
  slot.border:SetBlendMode("BLEND")
  slot.border:Hide()
  
  -- Colored outline border (for circles/lightning - uses texture layers)
  slot.outerStroke = slot:CreateTexture(nil, "ARTWORK", nil, 1)
  slot.outerStroke:SetPoint("CENTER", slot.texture, "CENTER", 0, 0)
  slot.outerStroke:SetBlendMode("BLEND")
  slot.outerStroke:Hide()
  
  slot.coloredBorder = slot:CreateTexture(nil, "ARTWORK", nil, 2)
  slot.coloredBorder:SetPoint("CENTER", slot.texture, "CENTER", 0, 0)
  slot.coloredBorder:SetBlendMode("BLEND")
  slot.coloredBorder:Hide()
  
  -- Backdrop border (for squares - uses frame positioning, never covers icon)
  slot.backdropBorder = CreateFrame("Frame", nil, slot, BackdropTemplateMixin and "BackdropTemplate")
  slot.backdropBorder:SetFrameLevel(slot:GetFrameLevel() + 2)
  slot.backdropBorder:Hide()
  
  -- Outer black stroke for square borders
  slot.backdropStroke = CreateFrame("Frame", nil, slot, BackdropTemplateMixin and "BackdropTemplate")
  slot.backdropStroke:SetFrameLevel(slot:GetFrameLevel() + 1)
  slot.backdropStroke:Hide()
  
  -- Inner black stroke for square borders (between border and icon)
  slot.backdropInnerStroke = CreateFrame("Frame", nil, slot, BackdropTemplateMixin and "BackdropTemplate")
  slot.backdropInnerStroke:SetFrameLevel(slot:GetFrameLevel() + 3)
  slot.backdropInnerStroke:Hide()
  
  -- Add stack number label (for free form mode)
  slot.label = slot:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
  slot.label:SetPoint("CENTER", slot, "CENTER", 0, 0)
  slot.label:SetText(tostring(index))
  slot.label:SetTextColor(1, 1, 1, 0.9)
  slot.label:Hide()  -- Hidden by default, shown only in free form mode
  
  -- Add shadow/outline for better visibility
  slot.label:SetShadowOffset(1, -1)
  slot.label:SetShadowColor(0, 0, 0, 1)
  
  -- Slot properties
  slot.index = index
  slot.isFilled = false
  
  -- Make slots draggable in freeform mode
  slot:SetMovable(true)
  slot:EnableMouse(false)
  slot:RegisterForDrag("LeftButton")
  
  slot:SetScript("OnDragStart", function(self)
    local db = ns.API.GetDB()
    if db.displayMode == "freeform" and db.movable then
      self:StartMoving()
    end
  end)
  
  slot:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local db = ns.API.GetDB()
    if db.displayMode == "freeform" then
      -- Save position relative to BarFrame
      local point, _, relPoint, x, y = self:GetPoint(1)
      db.slotsPos[self.index] = {x=x, y=y}
    end
  end)
  
  return slot
end

-- Create all 10 icon slots
for i = 1, 10 do
  iconSlots[i] = createIconSlot(i)
end

-- ===================================================================
-- SECTION 04 â€“ Layout Management
-- ===================================================================
local function layoutFiveIcons()
  local db = ns.API.GetDB()
  local spacing = db.spacing or 2
  local globalSize = db.globalSize or 1.0
  local globalWidth = db.globalWidth or 1.0
  local globalHeight = db.globalHeight or 1.0
  
  -- Position only slots 1-5 horizontally in a row
  for i = 1, 5 do
    local slot = iconSlots[i]
    local cfg = db.stacks[i] or {size=1.0}
    local baseSize = (cfg.size or 1.0) * globalSize * 64
    local width = baseSize * globalWidth
    local height = baseSize * globalHeight
    
    slot:ClearAllPoints()
    slot:SetSize(width, height)
    
    if i == 1 then
      slot:SetPoint("LEFT", BarFrame, "LEFT", 0, 0)
    else
      slot:SetPoint("LEFT", iconSlots[i-1], "RIGHT", spacing, 0)
    end
  end
  
  -- Hide slots 6-10 in 5 icons mode
  for i = 6, 10 do
    iconSlots[i]:Hide()
  end
end

local function layoutFiveOverlapping()
  local db = ns.API.GetDB()
  local spacing = db.spacing or 2
  local globalSize = db.globalSize or 1.0
  local globalWidth = db.globalWidth or 1.0
  local globalHeight = db.globalHeight or 1.0
  
  -- First, set explicit frame levels for slots 1-5 to ensure consistency
  local baseFrameLevel = BarFrame:GetFrameLevel() + 1
  for i = 1, 5 do
    iconSlots[i]:SetFrameLevel(baseFrameLevel)
  end
  
  -- Position slots 1â€“5 horizontally
  for i = 1, 5 do
    local slot = iconSlots[i]
    local cfg = db.stacks[i] or {size=1.0}
    local baseSize = (cfg.size or 1.0) * globalSize * 64
    local width = baseSize * globalWidth
    local height = baseSize * globalHeight
    
    slot:ClearAllPoints()
    slot:SetSize(width, height)
    
    if i == 1 then
      slot:SetPoint("LEFT", BarFrame, "LEFT", 0, 0)
    else
      slot:SetPoint("LEFT", iconSlots[i-1], "RIGHT", spacing, 0)
    end
  end
  
  -- Position slots 6â€“10 paired with 1â€“5
  for i = 6, 10 do
    local slot = iconSlots[i]
    local pairIndex = i - 5  -- 6â†’1, 7â†’2, etc.
    local cfg = db.stacks[i] or {size=1.0}
    local baseSize = (cfg.size or 1.0) * globalSize * 64
    local width = baseSize * globalWidth
    local height = baseSize * globalHeight
    
    slot:ClearAllPoints()
    slot:SetSize(width, height)
    slot:SetPoint("CENTER", iconSlots[pairIndex], "CENTER", 0, 0)
    
    -- Set frame level based on predLayerMode
    -- Now using the explicitly set baseFrameLevel for consistency
    if db.predLayerMode == "behind" then
      slot:SetFrameLevel(baseFrameLevel - 1)
    else  -- "front"
      slot:SetFrameLevel(baseFrameLevel + 1)
    end
  end
end

local function layoutTenSpaces()
  local db = ns.API.GetDB()
  local spacing = db.spacing or 2
  local globalSize = db.globalSize or 1.0
  local globalWidth = db.globalWidth or 1.0
  local globalHeight = db.globalHeight or 1.0
  
  -- Position all 10 slots horizontally in a row
  for i = 1, 10 do
    local slot = iconSlots[i]
    local cfg = db.stacks[i] or {size=1.0}
    local baseSize = (cfg.size or 1.0) * globalSize * 64
    local width = baseSize * globalWidth
    local height = baseSize * globalHeight
    
    slot:ClearAllPoints()
    slot:SetSize(width, height)
    
    if i == 1 then
      slot:SetPoint("LEFT", BarFrame, "LEFT", 0, 0)
    else
      slot:SetPoint("LEFT", iconSlots[i-1], "RIGHT", spacing, 0)
    end
  end
end

local function layoutTenOverlapping()
  local db = ns.API.GetDB()
  local globalSize = db.globalSize or 1.0
  local globalWidth = db.globalWidth or 1.0
  local globalHeight = db.globalHeight or 1.0
  
  -- Set frame levels for all 10 icons
  local baseFrameLevel = BarFrame:GetFrameLevel() + 1
  
  -- Position all 10 slots overlapping in the center
  for i = 1, 10 do
    local slot = iconSlots[i]
    local cfg = db.stacks[i] or {size=1.0}
    local baseSize = (cfg.size or 1.0) * globalSize * 64
    local width = baseSize * globalWidth
    local height = baseSize * globalHeight
    
    slot:ClearAllPoints()
    slot:SetSize(width, height)
    
    -- All icons centered on the same point
    if i == 1 then
      slot:SetPoint("CENTER", BarFrame, "CENTER", 0, 0)
    else
      slot:SetPoint("CENTER", iconSlots[1], "CENTER", 0, 0)
    end
    
    -- Set frame level based on predLayerMode
    -- In "behind" mode: icons 1-5 in front, 6-10 behind
    -- In "front" mode: icons 6-10 in front, 1-5 behind
    if db.predLayerMode == "behind" then
      -- Icons 1-5 have higher frame level (in front)
      if i <= 5 then
        slot:SetFrameLevel(baseFrameLevel + 1)
      else
        slot:SetFrameLevel(baseFrameLevel - 1)
      end
    else  -- "front"
      -- Icons 6-10 have higher frame level (in front)
      if i <= 5 then
        slot:SetFrameLevel(baseFrameLevel - 1)
      else
        slot:SetFrameLevel(baseFrameLevel + 1)
      end
    end
  end
end

local function layoutFreeForm()
  local db = ns.API.GetDB()
  local globalSize = db.globalSize or 1.0
  local globalWidth = db.globalWidth or 1.0
  local globalHeight = db.globalHeight or 1.0
  
  -- Check if all icons are stacked at the same position (common issue)
  local allStacked = true
  if db.slotsPos and db.slotsPos[1] then
    local firstX, firstY = db.slotsPos[1].x, db.slotsPos[1].y
    for i = 2, 10 do
      if db.slotsPos[i] and (db.slotsPos[i].x ~= firstX or db.slotsPos[i].y ~= firstY) then
        allStacked = false
        break
      end
    end
  else
    allStacked = false  -- No saved positions
  end
  
  -- If all icons are stacked, reset to horizontal line
  if allStacked then
    if db.debug then
      print("|cff00ccffMWRB|r[FREEFORM] Detected stacked icons - spreading them out in a line")
    end
    db.slotsPos = {}  -- Clear stacked positions
  end
  
  for i = 1, 10 do
    local slot = iconSlots[i]
    local cfg = db.stacks[i] or {size=1.0}
    local baseSize = (cfg.size or 1.0) * globalSize * 64
    local width = baseSize * globalWidth
    local height = baseSize * globalHeight
    local pos = db.slotsPos[i]
    
    slot:ClearAllPoints()
    slot:SetSize(width, height)
    
    if pos and pos.x and pos.y then
      -- Use saved position (always relative to BarFrame TOPLEFT)
      slot:SetPoint("TOPLEFT", BarFrame, "TOPLEFT", pos.x, pos.y)
    else
      -- Initialize with spacing in a horizontal line, BUT anchored to BarFrame
      -- This ensures each icon can be dragged independently
      local spacing = db.spacing or 2
      local xOffset = (i - 1) * (width + spacing)
      slot:SetPoint("TOPLEFT", BarFrame, "TOPLEFT", xOffset, 0)
      
      -- Save the initial position
      db.slotsPos[i] = {x=xOffset, y=0}
    end
  end
end

-- ===================================================================
-- SECTION 04.3 â€“ Bar Mode Layout
-- ===================================================================
local function layoutBarMode()
  local db = ns.API.GetDB()
  local cfg = db.barMode or {}
  
  -- Hide icon slots in bar mode
  for i = 1, 10 do
    iconSlots[i]:Hide()
  end
  
  -- Configure status bar
  local scale = cfg.scale or 1.0
  local scaledWidth = (cfg.width or 200) * scale
  local scaledHeight = (cfg.height or 30) * scale
  StatusBar:SetSize(scaledWidth, scaledHeight)
  
  -- Set orientation
  if cfg.direction == "VERTICAL" then
    StatusBar:SetOrientation("VERTICAL")
  else
    StatusBar:SetOrientation("HORIZONTAL")
  end
  
  -- Set fill direction (handled by SetReverseFill)
  if cfg.fillDirection == "RIGHT_TO_LEFT" or cfg.fillDirection == "TOP_TO_BOTTOM" then
    StatusBar:SetReverseFill(true)
  else
    StatusBar:SetReverseFill(false)
  end
  
  -- Set texture using LSM (handles atlas textures automatically)
  local textureName = cfg.texture or "Blizzard"
  if ns.LSM and ns.LSM.ApplyStatusBarTexture then
    ns.LSM.ApplyStatusBarTexture(StatusBar, textureName)
  else
    local texturePath = ns.LSM and ns.LSM.FetchStatusBar(textureName) or "Interface\\TargetingFrame\\UI-StatusBar"
    StatusBar:SetStatusBarTexture(texturePath)
  end
  
  -- Set opacity
  local opacity = cfg.opacity or 1.0
  StatusBar:SetAlpha(opacity)
  
  -- Set background
  if cfg.showBackground then
    StatusBarBG:SetTexture(texturePath)  -- Uses same texture from LSM
    local bgColor = cfg.backgroundColor or {r=0.2, g=0.2, b=0.2, a=0.8}
    local r, g, b, a = SafeColor(bgColor, {r=0.2, g=0.2, b=0.2, a=0.8})
    StatusBarBG:SetVertexColor(r, g, b)
    StatusBarBG:Show()
  else
    StatusBarBG:Hide()
  end
  
  -- Set border
  if cfg.showBorder then
    local borderColor = cfg.borderColor or {r=0, g=0, b=0, a=1}
    local thickness = (cfg.borderThickness or 2) * scale
    StatusBarBorder:SetBackdrop({
      edgeFile = "Interface\\Buttons\\WHITE8X8",
      edgeSize = thickness,
    })
    local r, g, b, a = SafeColor(borderColor, {r=0, g=0, b=0, a=1})

    StatusBarBorder:SetBackdropBorderColor(r, g, b, a)
    StatusBarBorder:Show()
  else
    StatusBarBorder:Hide()
  end
  
  -- Set min/max values
  StatusBar:SetMinMaxValues(0, 10)
  
  -- Update tick marks
  local ticksToShow = {}
  
  if cfg.showTickMarks then
    -- Show all 9 tick marks (dividing 10 segments)
    for i = 1, 9 do
      ticksToShow[i] = true
    end
  elseif cfg.showCustomTicks and cfg.customTicks then
    -- Show only custom tick marks at specified positions
    for _, stackPos in ipairs(cfg.customTicks) do
      if stackPos >= 1 and stackPos <= 9 then
        ticksToShow[stackPos] = true
      end
    end
  end
  
  -- Apply tick mark visibility and styling
  if next(ticksToShow) then
    local tickColor = cfg.tickColor or {r=0, g=0, b=0, a=1}
    
    -- Use scaled dimensions for tick mark positioning
    local scale = cfg.scale or 1.0
    -- Ensure tickThickness always defaults to 2 if not set
    local baseThickness = cfg.tickThickness or 2
    local tickThickness = baseThickness * scale
    local barWidth = (cfg.width or 200) * scale
    local barHeight = (cfg.height or 30) * scale
    local isVertical = cfg.direction == "VERTICAL"
    
    -- Calculate segment size (divide by 10 for 10 segments)
    local segmentSize = (isVertical and barHeight or barWidth) / 10
    
    -- Position and show tick marks (ALL ticks get same thickness)
    for i = 1, 9 do
      local tick = BarTickMarks[i]
      
      -- ALWAYS set thickness for ALL ticks (even hidden ones) to prevent size jumping
      tick:SetThickness(tickThickness)
      
      if ticksToShow[i] then
        tick:ClearAllPoints()
        
        if isVertical then
          -- Vertical bar - horizontal tick marks
          local yOffset = segmentSize * i
          tick:SetStartPoint("BOTTOMLEFT", StatusBar, 0, yOffset)
          tick:SetEndPoint("BOTTOMLEFT", StatusBar, barWidth, yOffset)
        else
          -- Horizontal bar - vertical tick marks
          local xOffset = segmentSize * i
          tick:SetStartPoint("TOPLEFT", StatusBar, xOffset, 0)
          tick:SetEndPoint("TOPLEFT", StatusBar, xOffset, -barHeight)
        end
        
        -- Use individual color if enabled, otherwise use global color
        local color
        if cfg.useIndividualTickColors and cfg.tickColors and cfg.tickColors[i] then
          color = cfg.tickColors[i]
        else
          color = tickColor
        end
        
        -- Ensure alpha is properly set (default to 1.0 for full opacity)
        local r, g, b, a = color.r or 0, color.g or 0, color.b or 0, color.a or 1.0
        tick:SetColorTexture(r, g, b, a)
        tick:Show()
      else
        tick:Hide()
      end
    end
  else
    -- Hide all tick marks but keep consistent thickness
    local scale = cfg.scale or 1.0
    local baseThickness = cfg.tickThickness or 2
    local tickThickness = baseThickness * scale
    
    for i = 1, 9 do
      -- Set thickness even when hidden to maintain consistency
      BarTickMarks[i]:SetThickness(tickThickness)
      BarTickMarks[i]:Hide()
    end
  end
  
  -- Show status bar only if not force hidden
  local db2 = ns.API.GetDB()
  if not db2.forceHide and ns.API.ShouldShowUI() then
    StatusBar:Show()
  else
    StatusBar:Hide()
  end
end

-- ===================================================================
-- SECTION 04.4 â€“ Bar Frame Position Helpers
-- ===================================================================
local function saveBarFramePosition()
  local db = ns.API.GetDB()
  local point, _, relPoint, x, y = BarFrame:GetPoint(1)
  
  -- Save to icon mode offset (for 5icons, 10spaces, freeform)
  db.offsetIconMode = db.offsetIconMode or {}
  db.offsetIconMode.point = point or "CENTER"
  db.offsetIconMode.relPoint = relPoint or "CENTER"
  db.offsetIconMode.x = x or 0
  db.offsetIconMode.y = y or 0
end

-- ===================================================================
-- SECTION 04.5 â€“ Middle Icon Drag Setup
-- ===================================================================
local function setupIconDrag()
  local db = ns.API.GetDB()
  
  -- In freeform mode, individual slot dragging is handled separately
  if db.displayMode == "freeform" then return end
  
  -- For all other modes, make ALL visible icons draggable to move the whole bar
  local maxIcon = 10
  if db.displayMode == "5icons" then
    maxIcon = 5
  end
  
  for i = 1, maxIcon do
    local icon = iconSlots[i]
    if icon then
      icon:SetScript("OnMouseDown", function(self, button)
        local db = ns.API.GetDB()
        if button == "LeftButton" and db.movable then
          BarFrame:StartMoving()
        end
      end)
      
      icon:SetScript("OnMouseUp", function(self, button)
        if button == "LeftButton" then
          BarFrame:StopMovingOrSizing()
          saveBarFramePosition()
        end
      end)
    end
  end
end

-- Forward declaration (defined later in file)
local updateBarFrameMovability

local function applyLayout()
  local db = ns.API.GetDB()
  local mode = db.displayMode or "5icons"  -- Default to 5icons
  
  -- Check if Real MSW Bar mode is active - hide all predictive displays
  if db.displayMode == "realMSW" then
    BarFrame:Hide()
    StatusBar:Hide()
    -- Hide all icon slots explicitly
    for i = 1, 10 do
      iconSlots[i]:Hide()
    end
    return
  end
  
  -- Check if we should hide everything due to forceHide or spec/talent
  local shouldHide = db.forceHide or not ns.API.ShouldShowUI()
  
  if mode == "bar" then
    layoutBarMode()
    BarFrame:Hide()  -- Hide icon container
    -- Hide all icon slots explicitly
    for i = 1, 10 do
      iconSlots[i]:Hide()
    end
    -- StatusBar visibility is handled by layoutBarMode
  elseif mode == "5icons" then
    StatusBar:Hide()  -- Hide status bar
    if not shouldHide then
      BarFrame:Show()
    else
      BarFrame:Hide()
    end
    layoutFiveIcons()
    -- Show slots 1-5 only (6-10 hidden by layoutFiveIcons)
    for i = 1, 5 do
      if not shouldHide then
        iconSlots[i]:Show()
      else
        iconSlots[i]:Hide()
      end
      iconSlots[i].label:Hide()  -- Hide labels in 5icons mode
    end
  elseif mode == "10spaces" then
    StatusBar:Hide()
    if not shouldHide then
      BarFrame:Show()
    else
      BarFrame:Hide()
    end
    layoutTenSpaces()
    -- Show all icon slots
    for i = 1, 10 do
      if not shouldHide then
        iconSlots[i]:Show()
      else
        iconSlots[i]:Hide()
      end
      iconSlots[i].label:Hide()  -- Hide labels in 10spaces mode
    end
  elseif mode == "freeform" then
    StatusBar:Hide()
    if not shouldHide then
      BarFrame:Show()
    else
      BarFrame:Hide()
    end
    layoutFreeForm()
    -- Show all icon slots with labels
    for i = 1, 10 do
      if not shouldHide then
        iconSlots[i]:Show()
      else
        iconSlots[i]:Hide()
      end
      if not shouldHide then
        iconSlots[i].label:Show()  -- Show labels in free form mode
      else
        iconSlots[i].label:Hide()
      end
    end
  else
    -- Fallback to 5icons for any unknown mode
    StatusBar:Hide()
    if not shouldHide then
      BarFrame:Show()
    else
      BarFrame:Hide()
    end
    layoutFiveIcons()
    for i = 1, 5 do
      if not shouldHide then
        iconSlots[i]:Show()
      else
        iconSlots[i]:Hide()
      end
      iconSlots[i].label:Hide()
    end
  end
  
  -- Setup middle icon drag after layout (not needed for bar mode)
  if mode ~= "bar" then
    setupIconDrag()
  end
  
  -- Update movability for the current mode (fixes bar/icon mode switching)
  updateBarFrameMovability()
end

-- ===================================================================
-- SECTION 05 â€“ Texture & Color Application
-- ===================================================================
local function applySlotAppearance(slot, currentCount, configIndex)
  local db = ns.API.GetDB()
  local index = configIndex or slot.index  -- Use provided configIndex or fall back to slot.index
  local cfg = db.stacks[index] or {}
  
  local shape = cfg.shape or "square"
  local fillTex = getShapeFillTexture(shape)
  
  -- Set texture
  slot.texture:SetTexture(fillTex)
  
  -- Handle borders (both texture and outline types)
  local borderEnabled = cfg.borderEnabled or false
  local borderType = cfg.borderType or "outline"  -- "texture" or "outline"
  
  -- ALWAYS hide square backdrop borders for non-square shapes
  if shape ~= "square" then
    slot.backdropBorder:Hide()
    slot.backdropStroke:Hide()
    slot.backdropInnerStroke:Hide()
  end
  
  if borderEnabled then
    if borderType == "texture" then
      -- Texture-based border (uses dedicated border texture files)
      slot.coloredBorder:Hide()
      slot.outerStroke:Hide()
      
      -- Hide square backdrop borders (only used by outline borders on squares)
      slot.backdropBorder:Hide()
      slot.backdropStroke:Hide()
      slot.backdropInnerStroke:Hide()
      
      local borderTex
      if string.match(shape, "circle") then
        borderTex = getShapeBorderTexture(shape)
      elseif string.match(shape, "lightning") then
        -- Lightning shapes don't have border textures - skip
        borderTex = nil
      elseif shape == "square" then
        local texName = cfg.borderTexture or "Square_Border1"
        borderTex = getSquareBorderTexture(texName)
      end
      
      if borderTex then
        local borderColor = cfg.borderColor or {r=1, g=1, b=1, a=1}
        local borderThickness = cfg.borderThickness or 2
        local borderOffset = cfg.borderOffset or 0
        
        -- Get main texture size
        local mainWidth = slot.texture:GetWidth() or 64
        local mainHeight = slot.texture:GetHeight() or 64
        
        -- Size border texture based on offset and thickness
        local borderWidth = mainWidth + (borderOffset * 2) + (borderThickness * 2)
        local borderHeight = mainHeight + (borderOffset * 2) + (borderThickness * 2)
        
        slot.border:ClearAllPoints()
        slot.border:SetPoint("CENTER", slot.texture, "CENTER", 0, 0)
        slot.border:SetSize(borderWidth, borderHeight)
        slot.border:SetTexture(borderTex)
        local r, g, b = SafeColor(borderColor, {r=1, g=1, b=1})

        slot.border:SetVertexColor(r, g, b)
        slot.border:SetAlpha(borderColor.a or 1)
        slot.border:Show()
      else
        slot.border:Hide()
      end
      
    else
      -- Colored Outline border
      slot.border:Hide()
      
      -- Use BACKDROP for squares (never covers icon), TEXTURE LAYERS for circles/lightning
      if shape == "square" then
        -- BACKDROP BORDER for squares with BLACK inner and outer edges
        slot.coloredBorder:Hide()
        slot.outerStroke:Hide()
        
        local borderColor = cfg.borderColor or {r=1, g=1, b=1, a=1}
        local borderThickness = cfg.borderThickness or 2
        local borderOffset = cfg.borderOffset or 0
        local strokeSize = 1  -- Black stroke thickness (1px to fit in 4px gap)
        local textureInset = 4  -- Texture is inset 4px from slot edges
        
        -- Round the offset to prevent sub-pixel positioning
        borderOffset = math.floor(borderOffset + 0.5)
        
        -- All borders positioned to work within the texture inset area
        -- Layer 1: OUTER BLACK STROKE (outermost, against slot edge)
        slot.backdropStroke:ClearAllPoints()
        slot.backdropStroke:SetPoint("TOPLEFT", slot, "TOPLEFT", borderOffset, -borderOffset)
        slot.backdropStroke:SetPoint("BOTTOMRIGHT", slot, "BOTTOMRIGHT", -borderOffset, borderOffset)
        
        slot.backdropStroke:SetBackdrop({
          edgeFile = "Interface\\Buttons\\WHITE8X8",
          edgeSize = strokeSize,
        })
        slot.backdropStroke:SetBackdropBorderColor(0, 0, 0, 1)
        slot.backdropStroke:Show()
        
        -- Layer 2: COLORED BORDER (middle)
        slot.backdropBorder:ClearAllPoints()
        slot.backdropBorder:SetPoint("TOPLEFT", slot, "TOPLEFT", 
          borderOffset + strokeSize, 
          -(borderOffset + strokeSize))
        slot.backdropBorder:SetPoint("BOTTOMRIGHT", slot, "BOTTOMRIGHT", 
          -(borderOffset + strokeSize), 
          borderOffset + strokeSize)
        
        slot.backdropBorder:SetBackdrop({
          edgeFile = "Interface\\Buttons\\WHITE8X8",
          edgeSize = borderThickness,
        })
        local r, g, b, a = SafeColor(borderColor, {r=1, g=1, b=1, a=1})

        slot.backdropBorder:SetBackdropBorderColor(r, g, b, a)
        slot.backdropBorder:Show()
        
        -- Layer 3: INNER BLACK STROKE (innermost, against texture)
        slot.backdropInnerStroke:ClearAllPoints()
        slot.backdropInnerStroke:SetPoint("TOPLEFT", slot, "TOPLEFT", 
          borderOffset + strokeSize + borderThickness, 
          -(borderOffset + strokeSize + borderThickness))
        slot.backdropInnerStroke:SetPoint("BOTTOMRIGHT", slot, "BOTTOMRIGHT", 
          -(borderOffset + strokeSize + borderThickness), 
          borderOffset + strokeSize + borderThickness)
        
        slot.backdropInnerStroke:SetBackdrop({
          edgeFile = "Interface\\Buttons\\WHITE8X8",
          edgeSize = strokeSize,
        })
        slot.backdropInnerStroke:SetBackdropBorderColor(0, 0, 0, 1)
        slot.backdropInnerStroke:Show()
        
      else
        -- TEXTURE LAYERS for circles/lightning (always show, even when empty)
        slot.backdropBorder:Hide()
        slot.backdropStroke:Hide()
        slot.backdropInnerStroke:Hide()
        
        local borderColor = cfg.borderColor or {r=1, g=1, b=1, a=1}
        local borderThickness = cfg.borderThickness or 2
        
        -- Get main texture size
        local mainWidth = slot.texture:GetWidth() or 64
        local mainHeight = slot.texture:GetHeight() or 64
        
        -- Use the icon's fill texture for border layers
        local borderTex = fillTex
        
        -- Layer 2: Colored border
        local coloredWidth = mainWidth + (borderThickness * 2)
        local coloredHeight = mainHeight + (borderThickness * 2)
        
        slot.coloredBorder:SetTexture(borderTex)
        slot.coloredBorder:SetSize(coloredWidth, coloredHeight)
        local r, g, b = SafeColor(borderColor, {r=1, g=1, b=1})

        slot.coloredBorder:SetVertexColor(r, g, b)
        slot.coloredBorder:SetAlpha(borderColor.a or 1)
        slot.coloredBorder:Show()
        
        -- Layer 1: Outer black stroke
        local outerStrokeWidth = coloredWidth + 4
        local outerStrokeHeight = coloredHeight + 4
        
        slot.outerStroke:SetTexture(borderTex)
        slot.outerStroke:SetSize(outerStrokeWidth, outerStrokeHeight)
        slot.outerStroke:SetVertexColor(0, 0, 0)
        slot.outerStroke:SetAlpha(1)
        slot.outerStroke:Show()
      end
    end
  else
    -- Hide all borders when disabled
    slot.border:Hide()
    slot.coloredBorder:Hide()
    slot.outerStroke:Hide()
    slot.backdropBorder:Hide()
    slot.backdropStroke:Hide()
    slot.backdropInnerStroke:Hide()
  end
  
  -- If filled, use filled tint (with threshold override)
  -- If empty, use empty tint
  if slot.isFilled then
    local tint = cfg.tint or {r=0.024, g=0, b=1, a=1}
    
    -- Check for threshold color override (per-threshold enable)
    if currentCount then
      local threshold2 = db.threshold2
      local threshold1 = db.threshold1
      
      -- Apply highest reached threshold that is enabled (check both threshold AND color enabled)
      if db.threshold2Enabled and threshold2 and threshold2.colorEnabled and threshold2.stacks and threshold2.color and currentCount >= threshold2.stacks then
        tint = threshold2.color
      elseif db.threshold1Enabled and threshold1 and threshold1.colorEnabled and threshold1.stacks and threshold1.color and currentCount >= threshold1.stacks then
        tint = threshold1.color
      end
    end
    
    -- Apply color
    slot.texture:SetVertexColor(SafeColor(tint, {r=1, g=1, b=1}))
    slot.texture:SetAlpha(tint.a or 1)
  else
    -- Empty state: use empty tint with proper priority
    local emptyTint
    
    if cfg.emptyTint then
      -- Priority 1: Use per-stack empty color if set
      emptyTint = cfg.emptyTint
    else
      -- Priority 2: Use global empty color
      emptyTint = db.emptyTint or {r=0.9, g=0.9, b=1, a=0.25}
    end
    
    local r, g, b = SafeColor(emptyTint, {r=0.9, g=0.9, b=1})

    
    slot.texture:SetVertexColor(r, g, b)
    slot.texture:SetAlpha(emptyTint.a or 0.25)
  end
end

local function refreshAllSlots()
  for i = 1, 10 do
    applySlotAppearance(iconSlots[i], currentMSW)
  end
end

-- ===================================================================
-- SECTION 06 â€“ Drawing Logic (Respond to MSW Changes)
-- ===================================================================
-- Dedicated MSW count debug (always prints if any debug flag is on)
local function dprintMSW(...)
  local db = ns.API.GetDB()
  if db.debugMSW or db.debug or db.debugOverlay or db.debugPredictor then
    print("|cffff9900MWRB[DISPLAY]|r", ...)
  end
end

-- Get bar color based on stack count (supports gradient color ranges)
local function GetBarColor(stackCount)
  local db = ns.API.GetDB()
  if not db or not db.barMode then
    return 0.024, 0, 1, 1  -- Default blue
  end
  
  local cfg = db.barMode
  
  -- If gradient disabled, use base color
  if not cfg.useGradient then
    local c = cfg.barColor or {r=0.024, g=0, b=1, a=1}
    return c.r, c.g, c.b, c.a
  end
  
  -- Use gradient system with color ranges
  local ranges = cfg.colorRanges or {}
  
  -- Check high range first (highest stacks)
  if ranges.high and ranges.high.enabled and stackCount >= (ranges.high.maxStacks or 10) then
    local c = ranges.high.color or {r=0.875, g=0, b=1, a=1}
    return c.r, c.g, c.b, c.a
  end
  
  -- Check mid range
  if ranges.mid and ranges.mid.enabled and stackCount >= (ranges.mid.maxStacks or 5) then
    local c = ranges.mid.color or {r=1, g=0.761, b=0.051, a=1}
    return c.r, c.g, c.b, c.a
  end
  
  -- Check low range
  if ranges.low and ranges.low.enabled and stackCount >= (ranges.low.maxStacks or 1) then
    local c = ranges.low.color or {r=0.024, g=0, b=1, a=1}
    return c.r, c.g, c.b, c.a
  end
  
  -- Below all ranges, use base color
  local c = cfg.barColor or {r=0.024, g=0, b=1, a=1}
  return c.r, c.g, c.b, c.a
end

local function drawIcons(count)
  count = math.max(0, math.min(10, count or 0))
  
  dprintMSW(string.format("<<< DISPLAY RECEIVED: MSW = %d (drawing %d filled, %d empty)", 
    count, count, 10 - count))
  
  local db = ns.API.GetDB()
  
  -- Check if we're in bar mode
  if db.displayMode == "bar" then
    -- Update status bar
    StatusBar:SetValue(count)
    
    -- Use gradient color system
    local r, g, b, a = GetBarColor(count)

    -- Safety check: ensure StatusBar and its texture exist
    if StatusBar and StatusBar.GetStatusBarTexture then
      local texture = StatusBar:GetStatusBarTexture()
      if texture then
        texture:SetVertexColor(r, g, b, a)
      end
    end
  else
    -- Icon mode rendering
    for i = 1, 10 do
      local slot = iconSlots[i]
      
      if i <= count then
        -- Filled
        slot.isFilled = true
      else
        -- Empty
        slot.isFilled = false
      end
      
      -- Special handling for 5icons mode: when count > 5, apply stack 6-10 configs to slots 1-5
      local configIndex = i
      if db.displayMode == "5icons" and i <= 5 and count > 5 then
        -- Map slot to config based on progression
        -- Slot 1 gets config 6 when count=6, config 6 when count=7+, etc.
        if i <= (count - 5) then
          configIndex = 5 + i  -- slot 1 -> config 6, slot 2 -> config 7, etc.
        end
      end
      
      -- Apply appearance (texture + color based on filled/empty state)
      -- Pass configIndex to use different stack config in 5icons mode
      applySlotAppearance(slot, count, configIndex)
      slot.texture:Show()
    end
  end
  
  -- Hide the predictive stack text (RealMSW textFrame is used instead)
  if StackText then
    StackText:Hide()
    StackTextFrame:Hide()
  end
  
  dprintMSW(string.format("    Display state: filled slots = %d, empty slots = %d", 
    count, 10 - count))
end

-- ===================================================================
-- SECTION 07 â€“ Public API (Display Module Interface)
-- ===================================================================
-- Called by Tracker when MSW count changes (ignored in preview mode)
-- ===================================================================
-- SECTION 09 â€“ Glow System (Synchronized Shape-based)
-- ===================================================================

-- Table to track all active glows
local activeGlows = {}

-- Shared pulsing state (0 to 1, cycles continuously)
local glowPulsePhase = 0

-- Create a frame to handle synchronized glow pulsing
local GlowPulseFrame = CreateFrame("Frame")
local lastUpdate = 0

GlowPulseFrame:SetScript("OnUpdate", function(self, elapsed)
  lastUpdate = lastUpdate + elapsed
  
  -- Get pulse speed from database
  local db = ns.API.GetDB()
  local GLOW_PULSE_SPEED = db.glowPulseSpeed or 2.0
  
  -- Update pulse phase (0 to 1, loops)
  glowPulsePhase = (glowPulsePhase + elapsed * GLOW_PULSE_SPEED) % 1
  
  -- Convert phase to smooth sine wave (0 to 1 and back)
  local pulseValue = (math.sin(glowPulsePhase * math.pi * 2) + 1) / 2
  
  -- Map to alpha range (0.4 to 0.7)
  local alpha = 0.4 + (pulseValue * 0.3)
  
  -- Map to scale range (1.0 to 1.05)
  local scale = 1.0 + (pulseValue * 0.05)
  
  -- Update all active glows
  for iconFrame, glowData in pairs(activeGlows) do
    if glowData.texture and glowData.texture:IsShown() then
      -- Update alpha
      local color = glowData.color or {r=1, g=1, b=1}
      local r, g, b = SafeColor(color, {r=1, g=1, b=1})

      glowData.texture:SetVertexColor(r, g, b)
      glowData.texture:SetAlpha(alpha)
      
      -- Update scale
      local baseWidth = glowData.baseWidth or 64
      local baseHeight = glowData.baseHeight or 64
      glowData.texture:SetSize(baseWidth * scale, baseHeight * scale)
    end
  end
end)

-- Create glow texture for an icon frame if it doesn't exist
local function EnsureGlowTexture(iconFrame)
  if not iconFrame then return end
  
  if not iconFrame.glowTexture then
    -- Create a glow layer that sits behind the main icon texture
    -- Using BACKGROUND layer so it appears behind the icon
    iconFrame.glowTexture = iconFrame:CreateTexture(nil, "BACKGROUND")
    
    -- Position it the same as the main icon texture but slightly larger
    iconFrame.glowTexture:SetPoint("CENTER", iconFrame.texture, "CENTER", 0, 0)
    
    -- Make it 20% larger than the icon for a nice glow halo
    local texWidth = iconFrame.texture:GetWidth()
    local texHeight = iconFrame.texture:GetHeight()
    iconFrame.glowTexture:SetSize(texWidth * 1.2, texHeight * 1.2)
    
    -- Use the same shape texture as the icon for cohesive look
    iconFrame.glowTexture:SetTexture(iconFrame.texture:GetTexture())
    
    -- Use additive blending for a glowing effect
    iconFrame.glowTexture:SetBlendMode("ADD")
    iconFrame.glowTexture:Hide()
  end
  
  return iconFrame.glowTexture
end

-- Update glow texture to match current icon shape
local function UpdateGlowTexture(iconFrame)
  if not iconFrame or not iconFrame.glowTexture then return end
  
  -- Update to match current icon texture and size
  iconFrame.glowTexture:SetTexture(iconFrame.texture:GetTexture())
  
  local texWidth = iconFrame.texture:GetWidth()
  local texHeight = iconFrame.texture:GetHeight()
  iconFrame.glowTexture:SetSize(texWidth * 1.2, texHeight * 1.2)
  
  -- Update base size in active glows table
  if activeGlows[iconFrame] then
    activeGlows[iconFrame].baseWidth = texWidth * 1.2
    activeGlows[iconFrame].baseHeight = texHeight * 1.2
  end
end

-- Show glow on an icon frame with custom color
local function ShowGlow(iconFrame, glowColor)
  if not iconFrame or not iconFrame.isFilled then return end
  
  local glowTex = EnsureGlowTexture(iconFrame)
  if not glowTex then return end
  
  -- Update the glow to match current icon shape/size
  UpdateGlowTexture(iconFrame)
  
  -- Apply color (default to white/blue if not specified)
  local color = glowColor or {r=0.5, g=0.7, b=1, a=0.7}
  
  -- Store glow data for synchronized pulsing
  local texWidth = iconFrame.texture:GetWidth()
  local texHeight = iconFrame.texture:GetHeight()
  activeGlows[iconFrame] = {
    texture = glowTex,
    color = color,
    baseWidth = texWidth * 1.2,
    baseHeight = texHeight * 1.2
  }
  
  -- Show the glow
  glowTex:Show()
  iconFrame.glowActive = true
end

-- Hide glow from an icon frame  
local function HideGlow(iconFrame)
  if not iconFrame then return end
  
  if iconFrame.glowActive and iconFrame.glowTexture then
    iconFrame.glowTexture:Hide()
    activeGlows[iconFrame] = nil  -- Remove from synchronized pulse list
    iconFrame.glowActive = false
  end
end

-- Update all icon glows based on current stack count
local function UpdateAllGlows(currentStackCount)
  local db = ns.API.GetDB()
  
  for i = 1, 10 do
    local iconFrame = iconSlots[i]
    if iconFrame then
      local isFilled = i <= currentStackCount
      local shouldGlow = false
      local glowColor = nil
      
      -- Check threshold glows first (they have priority)
      if isFilled then
        -- Threshold 2 has highest priority
        if db.threshold2Enabled and db.threshold2 and
           db.threshold2.stacks and currentStackCount >= db.threshold2.stacks and 
           db.threshold2.glowEnabled then
          shouldGlow = true
          glowColor = db.threshold2.glowColor
        -- Then threshold 1
        elseif db.threshold1Enabled and db.threshold1 and
               db.threshold1.stacks and currentStackCount >= db.threshold1.stacks and 
               db.threshold1.glowEnabled then
          shouldGlow = true
          glowColor = db.threshold1.glowColor
        end
      end
      
      -- If no threshold glow, check per-icon glow
      if not shouldGlow and isFilled and db.stacks[i] and db.stacks[i].glowEnabled then
        shouldGlow = true
        glowColor = db.stacks[i].glowColor
      end
      
      -- Apply or remove glow
      if shouldGlow then
        ShowGlow(iconFrame, glowColor)
      else
        HideGlow(iconFrame)
      end
    end
  end
end

-- ===================================================================
-- SECTION 10 â€“ API Functions
-- ===================================================================

function ns.API.OnMSWChanged(count)
  local db = ns.API.GetDB()
  
  -- Store the overlay event MSW count for threshold checks
  ns.overlayMSWCount = count or 0
  
  -- Check force hide first - don't update display if force hidden
  if db.forceHide then
    return
  end
  
  -- Check hide out of combat setting
  if db.hideOutOfCombat then
    local inCombat = UnitAffectingCombat("player") or InCombatLockdown() or false
    if not inCombat then
      return
    end
  end
  
  if db.previewMode then
    -- In preview mode, ignore tracker updates
    return
  end
  currentMSW = count or 0
  drawIcons(currentMSW)
  UpdateAllGlows(currentMSW)
  
  -- Also trigger Real MSW bar color update based on overlay event MSW count
  -- This allows conditionals (threshold colors) to affect Real MSW bar
  if db.displayMode == "realMSW" and ns.RealMSW and ns.RealMSW.UpdateThresholdColor then
    ns.RealMSW.UpdateThresholdColor(count)
  end
end

-- Force update display (used by options preview)
function ns.API.ForceDisplayUpdate(count)
  local db = ns.API.GetDB()
  
  -- Check force hide - don't update if force hidden (except in preview mode)
  if db.forceHide and not db.previewMode then
    return
  end
  
  currentMSW = count or 0
  drawIcons(currentMSW)
  UpdateAllGlows(currentMSW)
end

-- Enter preview mode
function ns.API.EnterPreviewMode(stackCount)
  local db = ns.API.GetDB()
  db.previewMode = true
  db.previewStack = stackCount or 0
  ns.API.ForceDisplayUpdate(stackCount)
end

-- Exit preview mode and return to normal tracking
function ns.API.ExitPreviewMode()
  local db = ns.API.GetDB()
  db.previewMode = false
  db.previewStack = 0
  -- Get current MSW from tracker
  local currentMSW = ns.API.GetMSWCount and ns.API.GetMSWCount() or 0
  ns.API.ForceDisplayUpdate(currentMSW)
end

-- Refresh display (re-apply layout and appearance)
function ns.API.RefreshDisplay()
  local db = ns.API.GetDB()
  
  -- Check force hide - don't update if force hidden
  if db.forceHide then
    -- Make sure everything is hidden
    BarFrame:Hide()
    StatusBar:Hide()
    StackTextFrame:Hide()
    return
  end
  
  applyLayout()
  refreshAllSlots()
  if db.previewMode then
    drawIcons(db.previewStack)
  else
    drawIcons(currentMSW)
  end
end

-- Show/hide display
function ns.API.ShowDisplay()
  local db = ns.API.GetDB()
  
  -- Check force hide first - overrides everything
  if db.forceHide then
    BarFrame:Hide()
    StatusBar:Hide()
    StackTextFrame:Hide()
    return
  end
  
  -- Check hide out of combat setting
  if db.hideOutOfCombat then
    local inCombat = UnitAffectingCombat("player") or InCombatLockdown() or false
    if not inCombat then
      BarFrame:Hide()
      StatusBar:Hide()
      StackTextFrame:Hide()
      return
    end
  end
  
  -- Check if Real MSW Bar mode is active - hide predictive displays
  if db.displayMode == "realMSW" then
    BarFrame:Hide()
    StatusBar:Hide()
    StackTextFrame:Hide()
    return
  end
  
  -- Check spec/talent requirements
  if not ns.API.ShouldShowUI() then
    BarFrame:Hide()
    StatusBar:Hide()
    StackTextFrame:Hide()
    return
  end
  
  if db.displayMode == "bar" then
    StatusBar:Show()
    BarFrame:Hide()
  else
    BarFrame:Show()
    StatusBar:Hide()
  end
  
  -- Show stack text if enabled (but NOT if using Real MSW text)
  if db.showStackText and not (db.realMSWBar and db.realMSWBar.showText) then
    StackTextFrame:Show()
  end
end

function ns.API.HideDisplay()
  BarFrame:Hide()
  StatusBar:Hide()
  StackTextFrame:Hide()
end

-- Enable/disable stack text
function ns.API.SetStackTextEnabled(enabled)
  if enabled then
    StackText:Show()
    StackTextFrame:Show()
  else
    StackText:Hide()
    StackTextFrame:Hide()
  end
end

-- Apply stack text position from DB
local function applyStackTextPosition()
  local db = ns.API.GetDB()
  
  -- Ensure position table exists with defaults
  if not db.stackTextPos then
    db.stackTextPos = {
      point = "CENTER",
      relPoint = "CENTER",
      x = 0,
      y = 0
    }
  end
  
  -- Apply position using saved anchor points
  StackTextFrame:ClearAllPoints()
  StackTextFrame:SetPoint(
    db.stackTextPos.point or "CENTER",
    UIParent,
    db.stackTextPos.relPoint or "CENTER",
    db.stackTextPos.x or 0,
    db.stackTextPos.y or 0
  )
  
  if db.debug then
    print("|cff00ccffMWRB|r[DISPLAY] Applied stack text position:", 
      db.stackTextPos.point, db.stackTextPos.relPoint, 
      db.stackTextPos.x, db.stackTextPos.y)
  end
  
  -- Apply color (from realMSWBar settings)
  db.realMSWBar = db.realMSWBar or {}
  local color = db.realMSWBar.textColor or {r=1, g=1, b=1, a=1}
  StackText:SetTextColor(color.r, color.g, color.b, color.a)
  
  -- Apply size (from realMSWBar settings)
  local size = db.realMSWBar.fontSize or 32
  local fontPath = StackText:GetFont()
  StackText:SetFont(fontPath or "Fonts\\FRIZQT__.TTF", size, "OUTLINE")
end

-- ===================================================================
-- SECTION 08 â€“ Bar Frame Positioning & Movability
-- ===================================================================
local function applyBarFramePosition()
  local db = ns.API.GetDB()
  local parent = UIParent
  
  BarFrame:SetParent(parent)
  BarFrame:ClearAllPoints()
  
  -- Use icon mode offset (for 5icons, 10spaces, freeform)
  local offset = db.offsetIconMode or db.offset or {point="CENTER", relPoint="CENTER", x=0, y=0}
  BarFrame:SetPoint(offset.point or "CENTER", parent, offset.relPoint or "CENTER", 
    offset.x or 0, offset.y or 0)
  
  local scale = db.scale or 1.0
  local baseSize = db.baseSize or {w=350, h=64}
  BarFrame:SetScale(scale)
  BarFrame:SetSize(baseSize.w or 350, baseSize.h or 64)
end

-- Make bar frame movable
BarFrame:SetScript("OnMouseDown", function(self, button)
  local db = ns.API.GetDB()
  if button == "LeftButton" and db.movable and db.displayMode ~= "freeform" then
    self:StartMoving()
  end
end)

BarFrame:SetScript("OnMouseUp", function(self, button)
  if button == "LeftButton" then
    self:StopMovingOrSizing()
    saveBarFramePosition()
  end
end)

-- Make status bar movable
StatusBar:SetMovable(true)
StatusBar:EnableMouse(false)  -- Will be enabled by updateBarFrameMovability

StatusBar:SetScript("OnMouseDown", function(self, button)
  local db = ns.API.GetDB()
  if button == "LeftButton" and db.movable and db.displayMode == "bar" then
    self:StartMoving()
  end
end)

StatusBar:SetScript("OnMouseUp", function(self, button)
  if button == "LeftButton" then
    self:StopMovingOrSizing()
    -- Save StatusBar position to bar mode offset
    local db = ns.API.GetDB()
    local point, _, relPoint, x, y = self:GetPoint(1)
    db.offsetBarMode = db.offsetBarMode or {}
    db.offsetBarMode.point = point or "CENTER"
    db.offsetBarMode.relPoint = relPoint or "CENTER"
    db.offsetBarMode.x = x or 0
    db.offsetBarMode.y = y or 0
  end
end)

local function applyStatusBarPosition()
  local db = ns.API.GetDB()
  local parent = UIParent
  
  StatusBar:SetParent(parent)
  StatusBar:ClearAllPoints()
  
  -- Use bar mode offset (for bar mode display)
  local offset = db.offsetBarMode or db.offset or {point="CENTER", relPoint="CENTER", x=0, y=-100}
  StatusBar:SetPoint(offset.point or "CENTER", parent, offset.relPoint or "CENTER", 
    offset.x or 0, offset.y or 0)
end

updateBarFrameMovability = function()
  local db = ns.API.GetDB()
  
  if db.displayMode == "bar" then
    -- In bar mode, enable StatusBar dragging
    if db.movable then
      StatusBar:EnableMouse(true)
    else
      StatusBar:EnableMouse(false)
    end
    BarFrame:EnableMouse(false)
  elseif db.displayMode == "freeform" then
    -- In freeform mode, disable BarFrame mouse so individual icons can be dragged
    BarFrame:EnableMouse(false)
    StatusBar:EnableMouse(false)
    
    -- Enable individual icon dragging in freeform mode
    if db.movable then
      for i = 1, 10 do
        iconSlots[i]:EnableMouse(true)
      end
    else
      for i = 1, 10 do
        iconSlots[i]:EnableMouse(false)
      end
    end
  else
    -- Enable bar frame mouse for 5icons and 10spaces modes
    if db.movable and (db.displayMode == "5icons" or db.displayMode == "10spaces") then
      BarFrame:EnableMouse(true)
    else
      BarFrame:EnableMouse(false)
    end
    StatusBar:EnableMouse(false)
  end
  
  -- Enable stack text frame dragging if movable (works for all modes)
  if db.movable then
    StackTextFrame:EnableMouse(true)
  else
    StackTextFrame:EnableMouse(false)
  end
  
  -- Setup middle icon drag handlers (still needed for icon-specific interactions)
  if db.displayMode ~= "bar" then
    setupIconDrag()
  end
end


-- ===================================================================
-- SECTION 08B – Combat Visibility
-- ===================================================================

-- Update visibility based on combat state and setting
local function updateCombatVisibility()
  local db = ns.API.GetDB()
  if not db then return end
  
  -- Check force hide first - overrides everything
  if db.forceHide then
    BarFrame:Hide()
    StackTextFrame:Hide()
    if StatusBar then
      StatusBar:Hide()
    end
    -- Also hide RealMSW frames
    if ns.RealMSW then
      ns.RealMSW.Disable()
    end
    return
  end
  
  -- Check spec/talent requirements
  if not ns.API.ShouldShowUI() then
    BarFrame:Hide()
    StackTextFrame:Hide()
    if StatusBar then
      StatusBar:Hide()
    end
    -- Also hide RealMSW frames
    if ns.RealMSW then
      ns.RealMSW.Disable()
    end
    return
  end
  
  -- Use multiple methods to detect combat state for reliability
  local inCombat = UnitAffectingCombat("player") or InCombatLockdown() or false
  
  -- Debug output (only when debug is enabled)
  if db.debug or db.debugOverlay then
    print("|cff00ccffMWRB|r[COMBAT] Combat state - hideOutOfCombat:", db.hideOutOfCombat, 
          "| UnitAffectingCombat:", UnitAffectingCombat("player") or false,
          "| InCombatLockdown:", InCombatLockdown() or false,
          "| Final inCombat:", inCombat)
  end
  
  if db.hideOutOfCombat and not inCombat then
    -- Hide when out of combat if setting is enabled
    if db.debug or db.debugOverlay then
      print("|cff00ccffMWRB|r[COMBAT] Hiding display (out of combat)")
    end
    
    -- Hide predictive frames
    BarFrame:Hide()
    StackTextFrame:Hide()
    if StatusBar then
      StatusBar:Hide()
    end
    
    -- Also hide RealMSW frames (both bar and text)
    if ns.RealMSW then
      ns.RealMSW.Disable()
    end
  else
    -- Show when in combat or setting is disabled
    if db.debug or db.debugOverlay then
      print("|cff00ccffMWRB|r[COMBAT] Showing display (in combat or setting disabled)")
    end
    
    -- Handle display based on mode
    if db.displayMode == "realMSW" then
      -- Real MSW mode - hide predictive, enable Real MSW
      BarFrame:Hide()
      StackTextFrame:Hide()
      if StatusBar then
        StatusBar:Hide()
      end
      if ns.RealMSW and ns.RealMSW.Enable then
        ns.RealMSW.Enable()
      end
    else
      -- Predictive modes - show appropriate frames
      if db.displayMode == "bar" then
        BarFrame:Hide()  -- Hide icon frame in bar mode
        if StatusBar then
          StatusBar:Show()
        end
      else
        BarFrame:Show()  -- Show icon frame in icon modes
        if StatusBar then
          StatusBar:Hide()  -- Hide status bar in icon modes
        end
      end
      
      -- Hide predictive stack text (Real MSW text is used instead)
      StackTextFrame:Hide()
      
      -- Ensure Real MSW system is running for text display
      if db.realMSWBar and db.realMSWBar.showText then
        -- Need to keep Real MSW updates running for text
        if ns.RealMSW and ns.RealMSW.Initialize then
          ns.RealMSW.Initialize()
        end
      end
    end
  end
end

-- Export function for options panel
function ns.API.UpdateCombatVisibility()
  updateCombatVisibility()
end

-- Combat event frame
local combatFrame = CreateFrame("Frame")
combatFrame:RegisterEvent("PLAYER_REGEN_DISABLED")  -- Entering combat
combatFrame:RegisterEvent("PLAYER_REGEN_ENABLED")   -- Leaving combat

combatFrame:SetScript("OnEvent", function(_, event)
  if event == "PLAYER_REGEN_DISABLED" or event == "PLAYER_REGEN_ENABLED" then
    updateCombatVisibility()
  end
end)

-- ===================================================================
-- SECTION 09 â€“ Initialization
-- ===================================================================
local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("ADDON_LOADED")
initFrame:RegisterEvent("PLAYER_LOGIN")
initFrame:RegisterEvent("PLAYER_ENTERING_WORLD")

initFrame:SetScript("OnEvent", function(_, event, addonName)
  if event == "ADDON_LOADED" and addonName == ADDON then
    -- Don't load positions yet - AceDB isn't initialized until PLAYER_LOGIN
    -- Just set up the frames at default positions
    ns.API.DebugPrintOverlay("Display module loaded (waiting for PLAYER_LOGIN to apply saved positions)")
    
  elseif event == "PLAYER_LOGIN" then
    -- Wait a tiny bit for AceDB to be initialized in Options_Core.lua
    C_Timer.After(0.05, function()
      if not ns.db then
        -- Safety fallback if somehow database isn't ready
        C_Timer.After(0.2, function()
          if ns.db then
            applyBarFramePosition()
            applyStatusBarPosition()
            applyStackTextPosition()
            updateBarFrameMovability()
            ns.API.RefreshDisplay()
            ns.API.DebugPrintOverlay("Display initialized (delayed for DB)")
          else
            ns.API.DebugPrintOverlay("WARNING: Database not initialized, using defaults")
          end
        end)
        return
      end
      
      -- Database is ready, apply saved positions
      applyBarFramePosition()
      applyStatusBarPosition()
      applyStackTextPosition()
      updateBarFrameMovability()
      ns.API.RefreshDisplay()
      ns.API.DebugPrintOverlay("Display module initialized with saved positions")
      
      -- Initialize with 0 stacks but DON'T show yet
      -- Let the Tracker module control initial visibility based on spec/talent
      currentMSW = 0
      drawIcons(0)
      
      -- Hide everything initially - Tracker will show if appropriate
      BarFrame:Hide()
      StatusBar:Hide()
      StackTextFrame:Hide()
      
      ns.API.DebugPrintOverlay("Display hidden initially - waiting for Tracker to control visibility")
    end)
  
  elseif event == "PLAYER_ENTERING_WORLD" then
    -- Re-check visibility on zone changes/reloads
    C_Timer.After(0.1, function()
      if ns.db then
        updateCombatVisibility()
        ns.API.RefreshDisplay()
      end
    end)
  end
end)

-- ===================================================================
-- SECTION 10 â€“ Public Utility Functions
-- ===================================================================
-- Get bar frame (for external modules like options)
function ns.API.GetBarFrame()
  return BarFrame
end

-- Get stack text frame (for external modules)
function ns.API.GetStackTextFrame()
  return StackTextFrame
end

-- Get stack text fontstring (for external modules)
function ns.API.GetStackText()
  return StackText
end

-- Update movability (call after changing db.movable)
function ns.API.UpdateMovability()
  updateBarFrameMovability()
end

-- Apply layout (call after changing display mode)
function ns.API.ApplyLayout()
  applyLayout()
end

-- Apply positioning (call after importing profiles)
function ns.API.ApplyBarFramePosition()
  applyBarFramePosition()
end

function ns.API.ApplyStatusBarPosition()
  applyStatusBarPosition()
end

function ns.API.ApplyStackTextPosition()
  applyStackTextPosition()
end

-- ===================================================================
-- END OF MWRB_Display.lua
-- ===================================================================