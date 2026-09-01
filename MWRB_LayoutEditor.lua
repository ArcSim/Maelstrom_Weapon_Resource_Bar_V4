-- ===================================================================
-- MWRB_LayoutEditor.lua
-- Maelstrom Weapon Resource Bar - Layout Editor Module
-- Allows users to drag and reposition options panel elements
-- ===================================================================

-- ===================================================================
-- SECTION 01 â€“ Namespace & Setup
-- ===================================================================
-- Class check - Exit if not Shaman
local _, playerClass = UnitClass("player")
if playerClass ~= "SHAMAN" then return end

local ADDON, ns = ...
ns = ns or {}
ns.API = ns.API or {}
ns.LayoutEditor = ns.LayoutEditor or {}

local LE = ns.LayoutEditor

-- ===================================================================
-- SECTION 02 â€“ State Management
-- ===================================================================
LE.editMode = false
LE.trackedElements = {}
LE.originalPositions = {}
LE.dragFrames = {}
LE.selectedElements = {} -- Multi-select support
LE.isDraggingGroup = false

-- ===================================================================
-- SECTION 03 â€“ Helper Functions
-- ===================================================================
local function GetDB()
  return ns.API.GetDB()
end

local function DebugPrint(...)
  if GetDB().debug then
    print("|cff00ccffMWRB|r[LAYOUT]", ...)
  end
end

-- Counter for stable IDs
local elementCounters = {}

-- Generate unique STABLE ID for element (survives reloads)
local function GenerateElementID(element)
  if element.layoutEditorID then
    return element.layoutEditorID
  end
  
  -- Get element type and name
  local elementType = element:GetObjectType()
  local name = element:GetName()
  
  -- If element has a name, use it (most stable)
  if name and name ~= "" then
    element.layoutEditorID = name
    return name
  end
  
  -- For unnamed elements, use type + creation counter
  elementCounters[elementType] = (elementCounters[elementType] or 0) + 1
  local id = elementType .. "_" .. elementCounters[elementType]
  
  element.layoutEditorID = id
  return id
end

-- ===================================================================
-- SECTION 04 â€“ Element Tracking
-- ===================================================================
function LE:RegisterElement(element, parent, prefix)
  if not element or not parent then return end
  
  prefix = prefix or ""
  local id = prefix .. GenerateElementID(element)
  
  -- Store element reference
  self.trackedElements[id] = {
    element = element,
    parent = parent,
    id = id,
    tabPrefix = prefix
  }
  
  -- Store original position
  if not self.originalPositions[id] then
    local point, relativeTo, relativePoint, x, y = element:GetPoint(1)
    self.originalPositions[id] = {
      point = point,
      relativeTo = relativeTo,
      relativePoint = relativePoint,
      x = x,
      y = y
    }
  end
  
  DebugPrint("Registered element:", id)
end

function LE:UnregisterElement(element)
  local id = element.layoutEditorID
  if id then
    self.trackedElements[id] = nil
    if self.dragFrames[id] then
      self.dragFrames[id]:Hide()
      self.dragFrames[id] = nil
    end
  end
end

-- ===================================================================
-- SECTION 05 â€“ Drag Frame Creation
-- ===================================================================
function LE:CreateDragFrame(elementData)
  local element = elementData.element
  local id = elementData.id
  
  if self.dragFrames[id] then
    return self.dragFrames[id]
  end
  
  -- FontStrings need special handling since they can't be moved easily
  -- We'll create a wrapper frame for them
  local isFontString = element:IsObjectType("FontString")
  
  -- Create invisible drag frame overlay
  local dragFrame = CreateFrame("Frame", nil, element:GetParent())
  dragFrame:SetAllPoints(element)
  
  -- Set frame level safely
  if isFontString then
    dragFrame:SetFrameLevel(100) -- High level for FontStrings
  else
    local parentLevel = 1
    if element.GetFrameLevel then
      parentLevel = element:GetFrameLevel()
    end
    dragFrame:SetFrameLevel(parentLevel + 10)
  end
  
  dragFrame:EnableMouse(true)
  dragFrame:SetMovable(true)
  dragFrame:RegisterForDrag("LeftButton")
  
  -- Handle right-click for context menu (OnMouseUp to avoid drag conflicts)
  dragFrame:SetScript("OnMouseUp", function(self, button)
    -- Handle right-click for context menu
    if button == "RightButton" and not IsControlKeyDown() then
      -- Stop any active drag first
      if self.isMoving then
        if isFontString then
          self:StopMovingOrSizing()
        else
          element:StopMovingOrSizing()
        end
        self.isMoving = false
      end
      
      DebugPrint("Right-click on element:", id, "Type:", element:GetObjectType())
      
      -- Show context menu
      local menu = CreateFrame("Frame", "MWRB_LayoutContextMenu", UIParent, BackdropTemplateMixin and "BackdropTemplate")
      menu:SetSize(160, 40)
      
      -- Position at cursor
      local scale = UIParent:GetEffectiveScale()
      local x, y = GetCursorPosition()
      menu:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x / scale, y / scale)
      
      menu:SetFrameStrata("TOOLTIP")
      menu:SetFrameLevel(1000)
      menu:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 16, edgeSize = 16,
        insets = {left = 4, right = 4, top = 4, bottom = 4}
      })
      menu:SetBackdropColor(0, 0, 0, 1)
      
      DebugPrint("Showing context menu for element:", id)
      
      -- Determine target tab
      local currentPrefix = elementData.tabPrefix or ""
      local targetTab, targetPrefix
      if currentPrefix == "main_" then
        targetTab = "Advanced"
        targetPrefix = "adv_"
      else
        targetTab = "Main"
        targetPrefix = "main_"
      end
      
      -- Menu button
      local btn = CreateFrame("Button", nil, menu, "UIPanelButtonTemplate")
      btn:SetSize(145, 25)
      btn:SetPoint("CENTER")
      btn:SetText("Move to " .. targetTab .. " Tab")
      btn:SetScript("OnClick", function()
        LE:MoveElementToTab(id, targetPrefix)
        menu:Hide()
      end)
      
      -- Close on any click outside
      menu:SetScript("OnMouseDown", function(self)
        self:Hide()
      end)
      
      -- Auto-hide menu after 10 seconds
      menu:SetScript("OnUpdate", function(self, elapsed)
        self.timer = (self.timer or 0) + elapsed
        if self.timer > 10 then
          self:Hide()
        end
      end)
      
      menu:SetScript("OnHide", function(self)
        self:SetParent(nil)
      end)
      
      menu:Show()
    end
  end)
  
  -- Visual indicator (different color for FontStrings and selected state)
  dragFrame.texture = dragFrame:CreateTexture(nil, "OVERLAY")
  dragFrame.texture:SetAllPoints()
  
  -- Border for clarity (create this BEFORE UpdateColors function)
  dragFrame.border = dragFrame:CreateTexture(nil, "BORDER")
  dragFrame.border:SetAllPoints()
  dragFrame.border:SetDrawLayer("OVERLAY", 1)
  
  -- Function to update colors based on selection state
  local function UpdateColors(isHover)
    local isSelected = LE.selectedElements[id] ~= nil
    
    if isSelected then
      -- Selected elements are purple
      if isHover then
        dragFrame.texture:SetColorTexture(0.8, 0, 1, 0.4)
        dragFrame.border:SetColorTexture(0.8, 0, 1, 0.9)
      else
        dragFrame.texture:SetColorTexture(0.6, 0, 0.8, 0.3)
        dragFrame.border:SetColorTexture(0.6, 0, 0.8, 0.7)
      end
    elseif isFontString then
      -- FontStrings are orange
      if isHover then
        dragFrame.texture:SetColorTexture(1, 0.9, 0.2, 0.4)
        dragFrame.border:SetColorTexture(1, 0.9, 0.2, 0.8)
      else
        dragFrame.texture:SetColorTexture(1, 0.8, 0, 0.2)
        dragFrame.border:SetColorTexture(1, 0.8, 0, 0.5)
      end
    else
      -- Regular frames are green
      if isHover then
        dragFrame.texture:SetColorTexture(0, 1, 1, 0.3)
        dragFrame.border:SetColorTexture(0, 1, 1, 0.7)
      else
        dragFrame.texture:SetColorTexture(0, 1, 0, 0.2)
        dragFrame.border:SetColorTexture(0, 1, 0, 0.5)
      end
    end
  end
  
  UpdateColors(false)
  dragFrame.UpdateColors = UpdateColors
  
  -- Info text
  dragFrame.label = dragFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  dragFrame.label:SetPoint("TOP", 0, 0)
  
  -- Function to update label based on selection
  local function UpdateLabel()
    local isSelected = LE.selectedElements[id] ~= nil
    local tabPrefix = elementData.tabPrefix or ""
    local tabIndicator = ""
    
    if tabPrefix == "main_" then
      tabIndicator = "[M] "
    elseif tabPrefix == "adv_" then
      tabIndicator = "[A] "
    end
    
    if isSelected then
      dragFrame.label:SetText(tabIndicator .. "SELECTED")
      dragFrame.label:SetTextColor(1, 0, 1, 1) -- Purple
    elseif isFontString then
      dragFrame.label:SetText(tabIndicator .. "TEXT")
      dragFrame.label:SetTextColor(1, 1, 0, 1) -- Yellow
    else
      dragFrame.label:SetText(tabIndicator .. "DRAG")
      dragFrame.label:SetTextColor(1, 1, 1, 1) -- White
    end
  end
  
  UpdateLabel()
  dragFrame.UpdateLabel = UpdateLabel
  
  -- Handle Ctrl+Click selection with OnMouseDown
  dragFrame:SetScript("OnMouseDown", function(self, button)
    if button == "LeftButton" and IsControlKeyDown() then
      -- Ctrl+Click to toggle selection
      if LE.selectedElements[id] then
        LE.selectedElements[id] = nil
      else
        LE.selectedElements[id] = elementData
      end
      UpdateLabel()
      UpdateColors(false)
    end
  end)
  
  -- Drag handlers with multi-select support
  if isFontString then
    -- For FontStrings, we move the drag frame and update the FontString position
    dragFrame:SetScript("OnDragStart", function(self)
      -- Don't start drag on Ctrl+Click
      if IsControlKeyDown() then return end
      
      -- If this element is selected, drag all selected elements
      if LE.selectedElements[id] then
        LE.isDraggingGroup = true
        -- Store initial positions for all selected elements
        for selId, selData in pairs(LE.selectedElements) do
          local selElem = selData.element
          selData.dragStartX = selElem:GetLeft()
          selData.dragStartY = selElem:GetTop()
        end
        -- Store drag start for this element
        elementData.dragStartX = element:GetLeft()
        elementData.dragStartY = element:GetTop()
      end
      
      self:StartMoving()
      self.isMoving = true
    end)
    
    dragFrame:SetScript("OnDragStop", function(self)
      self:StopMovingOrSizing()
      self.isMoving = false
      
      if LE.isDraggingGroup then
        -- Calculate how much this element moved
        local newX = element:GetLeft()
        local newY = element:GetTop()
        local deltaX = newX - elementData.dragStartX
        local deltaY = newY - elementData.dragStartY
        
        -- Move all selected elements by the same delta
        for selId, selData in pairs(LE.selectedElements) do
          local selElem = selData.element
          local selParent = selData.parent
          local selDragFrame = LE.dragFrames[selId]
          
          -- Calculate new position
          local targetX = selData.dragStartX + deltaX
          local targetY = selData.dragStartY + deltaY
          
          -- Convert to parent-relative coordinates
          local parentLeft = selParent:GetLeft()
          local parentTop = selParent:GetTop()
          
          if targetX and targetY and parentLeft and parentTop then
            local relX = targetX - parentLeft
            local relY = targetY - parentTop
            
            -- Update element position
            selElem:ClearAllPoints()
            selElem:SetPoint("TOPLEFT", selParent, "TOPLEFT", relX, relY)
            
            -- Update drag frame if it exists
            if selDragFrame then
              selDragFrame:ClearAllPoints()
              selDragFrame:SetAllPoints(selElem)
            end
            
            -- Save position
            LE:SaveElementPosition(selId, selElem)
          end
        end
        
        LE.isDraggingGroup = false
      else
        -- Single element drag
        local dragLeft = self:GetLeft()
        local dragTop = self:GetTop()
        local parent = element:GetParent()
        local parentLeft = parent:GetLeft()
        local parentTop = parent:GetTop()
        
        if dragLeft and dragTop and parentLeft and parentTop then
          local relX = dragLeft - parentLeft
          local relY = dragTop - parentTop
          
          element:ClearAllPoints()
          element:SetPoint("TOPLEFT", parent, "TOPLEFT", relX, relY)
          
          self:ClearAllPoints()
          self:SetAllPoints(element)
        end
        
        LE:SaveElementPosition(id, element)
      end
    end)
  else
    -- For regular frames, move the element itself
    dragFrame:SetScript("OnDragStart", function(self)
      -- Don't start drag on Ctrl+Click
      if IsControlKeyDown() then return end
      
      -- If this element is selected, drag all selected elements
      if LE.selectedElements[id] then
        LE.isDraggingGroup = true
        -- Store initial positions for all selected elements
        for selId, selData in pairs(LE.selectedElements) do
          local selElem = selData.element
          selData.dragStartX = selElem:GetLeft()
          selData.dragStartY = selElem:GetTop()
        end
        -- Store drag start for this element
        elementData.dragStartX = element:GetLeft()
        elementData.dragStartY = element:GetTop()
      end
      
      element:StartMoving()
      self.isMoving = true
    end)
    
    dragFrame:SetScript("OnDragStop", function(self)
      element:StopMovingOrSizing()
      self.isMoving = false
      
      if LE.isDraggingGroup then
        -- Calculate how much this element moved
        local newX = element:GetLeft()
        local newY = element:GetTop()
        local deltaX = newX - elementData.dragStartX
        local deltaY = newY - elementData.dragStartY
        
        -- Move all selected elements by the same delta
        for selId, selData in pairs(LE.selectedElements) do
          local selElem = selData.element
          local selParent = selData.parent
          
          -- Calculate new position
          local targetX = selData.dragStartX + deltaX
          local targetY = selData.dragStartY + deltaY
          
          -- Convert to parent-relative coordinates
          local parentLeft = selParent:GetLeft()
          local parentTop = selParent:GetTop()
          
          if targetX and targetY and parentLeft and parentTop then
            local relX = targetX - parentLeft
            local relY = targetY - parentTop
            
            -- Update element position
            selElem:ClearAllPoints()
            selElem:SetPoint("TOPLEFT", selParent, "TOPLEFT", relX, relY)
            
            -- Save position
            LE:SaveElementPosition(selId, selElem)
          end
        end
        
        LE.isDraggingGroup = false
      else
        -- Single element drag
        local elemLeft = element:GetLeft()
        local elemTop = element:GetTop()
        local parent = element:GetParent()
        local parentLeft = parent:GetLeft()
        local parentTop = parent:GetTop()
        
        if elemLeft and elemTop and parentLeft and parentTop then
          local relX = elemLeft - parentLeft
          local relY = elemTop - parentTop
          
          element:ClearAllPoints()
          element:SetPoint("TOPLEFT", parent, "TOPLEFT", relX, relY)
        end
        
        LE:SaveElementPosition(id, element)
      end
    end)
  end
  
  dragFrame:SetScript("OnEnter", function(self)
    UpdateColors(true)
  end)
  
  dragFrame:SetScript("OnLeave", function(self)
    UpdateColors(false)
  end)
  
  self.dragFrames[id] = dragFrame
  return dragFrame
end

-- ===================================================================
-- SECTION 06 â€“ Position Management
-- ===================================================================
function LE:SaveElementPosition(id, element)
  -- Get the element's parent (should be the content frame)
  local parent = element:GetParent()
  
  -- Get position relative to parent
  local point, relativeTo, relativePoint, x, y = element:GetPoint(1)
  
  -- Make sure we're saving relative to the parent, not absolute screen coords
  if relativeTo ~= parent then
    -- Recalculate position relative to parent
    local elementLeft = element:GetLeft()
    local elementTop = element:GetTop()
    local parentLeft = parent:GetLeft()
    local parentTop = parent:GetTop()
    
    if elementLeft and elementTop and parentLeft and parentTop then
      x = elementLeft - parentLeft
      y = elementTop - parentTop
      point = "TOPLEFT"
      relativePoint = "TOPLEFT"
    end
  end
  
  local db = GetDB()
  db.layoutPositions = db.layoutPositions or {}
  
  db.layoutPositions[id] = {
    point = point,
    relativeTo = "Parent", -- Always save relative to parent
    relativePoint = relativePoint,
    x = x,
    y = y
  }
end

function LE:LoadElementPosition(id, element, parent)
  local db = GetDB()
  if not db.layoutPositions or not db.layoutPositions[id] then
    return false
  end
  
  local pos = db.layoutPositions[id]
  
  -- Clear existing points
  element:ClearAllPoints()
  
  -- Always restore position relative to parent
  element:SetPoint(
    pos.point or "TOPLEFT", 
    parent, 
    pos.relativePoint or "TOPLEFT", 
    pos.x or 0, 
    pos.y or 0
  )
  
  return true
end

function LE:ResetElementPosition(id, element, parent)
  if not self.originalPositions[id] then return end
  
  local pos = self.originalPositions[id]
  
  element:ClearAllPoints()
  
  -- Restore original position - use parent if relativeTo was parent, otherwise try to find the frame
  local relativeTo = pos.relativeTo
  if not relativeTo or relativeTo == parent then
    relativeTo = parent
  end
  
  element:SetPoint(pos.point, relativeTo, pos.relativePoint, pos.x, pos.y)
  
  -- Remove saved position
  local db = GetDB()
  if db.layoutPositions then
    db.layoutPositions[id] = nil
  end
  
  DebugPrint("Reset position for", id)
end

-- ===================================================================
-- SECTION 07 â€“ Edit Mode Management
-- ===================================================================
function LE:EnterEditMode()
  if self.editMode then return end
  
  self.editMode = true
  self.selectedElements = {} -- Clear any previous selections
  DebugPrint("Entering edit mode")
  
  -- Create drag frames for all tracked elements
  for id, elementData in pairs(self.trackedElements) do
    local dragFrame = self:CreateDragFrame(elementData)
    dragFrame:Show()
    
    -- Make element movable (only for frames, not FontStrings)
    if not elementData.element:IsObjectType("FontString") then
      elementData.element:SetMovable(true)
    end
  end
  
  -- Show notification
  print("|cff00ccffMWRB|r |cff00ff00Layout Edit Mode ENABLED|r")
  print("|cff00ccffMWRB|r â€¢ Drag elements to reposition")
  print("|cff00ccffMWRB|r â€¢ Ctrl+Click to multi-select")
  print("|cff00ccffMWRB|r â€¢ Right-click element to move between tabs")
end

function LE:ExitEditMode(saveChanges)
  if not self.editMode then return end
  
  self.editMode = false
  self.selectedElements = {} -- Clear selections
  self.isDraggingGroup = false
  DebugPrint("Exiting edit mode, save:", saveChanges)
  
  -- Hide and clean up all drag frames
  for id, dragFrame in pairs(self.dragFrames) do
    if dragFrame then
      dragFrame:Hide()
      dragFrame:SetScript("OnMouseDown", nil)
      dragFrame:SetScript("OnMouseUp", nil)
      dragFrame:SetScript("OnDragStart", nil)
      dragFrame:SetScript("OnDragStop", nil)
      dragFrame:SetScript("OnEnter", nil)
      dragFrame:SetScript("OnLeave", nil)
    end
  end
  
  -- Clear drag frames table
  self.dragFrames = {}
  
  if not saveChanges then
    -- Restore all positions to saved or original
    for id, elementData in pairs(self.trackedElements) do
      local element = elementData.element
      local parent = elementData.parent
      
      -- Try to load saved position first, otherwise use original
      if not self:LoadElementPosition(id, element, parent) then
        self:ResetElementPosition(id, element, parent)
      end
    end
    print("|cff00ccffMWRB|r Layout changes |cffff0000DISCARDED|r")
  else
    -- Force save to disk by updating the SavedVariables
    -- This ensures positions persist across reloads
    local db = GetDB()
    if db.layoutPositions then
      -- Count how many positions we're saving and show examples
      local count = 0
      local examples = {}
      for id, _ in pairs(db.layoutPositions) do
        count = count + 1
        if count <= 3 then
          table.insert(examples, id)
        end
      end
      
      -- Touch the database to ensure it's marked as modified
      MWRBDB_V4.layoutPositions = db.layoutPositions
      
      print("|cff00ccffMWRB|r Layout changes |cff00ff00SAVED|r (" .. count .. " positions)")
      if #examples > 0 then
        print("|cff00ccffMWRB|r Example IDs: " .. table.concat(examples, ", "))
      end
    else
      print("|cff00ccffMWRB|r Layout changes |cff00ff00SAVED|r")
    end
  end
  
  -- Make elements non-movable again (only for frames, not FontStrings)
  for id, elementData in pairs(self.trackedElements) do
    if elementData.element and not elementData.element:IsObjectType("FontString") then
      elementData.element:SetMovable(false)
    end
  end
end

function LE:ToggleEditMode()
  if self.editMode then
    self:ExitEditMode(false)
  else
    self:EnterEditMode()
  end
end

-- ===================================================================
-- SECTION 08 â€“ Reset Functions
-- ===================================================================
function LE:RefreshDragFrames()
  -- Update visibility of drag frames based on parent visibility
  for id, dragFrame in pairs(self.dragFrames) do
    local elementData = self.trackedElements[id]
    if elementData and elementData.element then
      local parent = elementData.element:GetParent()
      if parent and parent:IsVisible() then
        dragFrame:Show()
      else
        dragFrame:Hide()
      end
    end
  end
end

function LE:MoveElementToTab(oldId, newPrefix)
  local elementData = self.trackedElements[oldId]
  if not elementData then 
    print("|cff00ccffMWRB|r Error: Element not found in tracking")
    return 
  end
  
  local element = elementData.element
  local oldPrefix = elementData.tabPrefix or ""
  local oldParent = elementData.parent
  
  -- Get target content frame
  local targetParent
  if newPrefix == "main_" then
    targetParent = _G["MWRB_MainContent"]
  else
    targetParent = _G["MWRB_AdvancedContent"]
  end
  
  if not targetParent then
    print("|cff00ccffMWRB|r Error: Could not find target tab content frame")
    return
  end
  
  -- Don't move if already in target tab
  if oldPrefix == newPrefix then
    print("|cff00ccffMWRB|r Element is already in this tab")
    return
  end
  
  -- Generate new ID with new prefix
  local baseId = oldId:gsub("^" .. oldPrefix, "")
  local newId = newPrefix .. baseId
  
  print("|cff00ccffMWRB|r Moving element: " .. oldId .. " â†’ " .. newId)
  
  -- IMPORTANT: Hide the element first
  element:Hide()
  
  -- Re-parent the element
  element:SetParent(targetParent)
  
  -- Clear all points to remove any absolute positioning
  element:ClearAllPoints()
  
  -- Position relative to new parent (NOT screen coordinates)
  -- Use a safe default position in the new tab
  element:SetPoint("TOPLEFT", targetParent, "TOPLEFT", 16, -100)
  
  -- Show element again
  element:Show()
  
  -- Update tracking with new ID
  self.trackedElements[newId] = {
    element = element,
    parent = targetParent,
    id = newId,
    tabPrefix = newPrefix
  }
  self.trackedElements[oldId] = nil
  
  -- Update original positions
  self.originalPositions[newId] = {
    point = "TOPLEFT",
    relativeTo = targetParent,
    relativePoint = "TOPLEFT",
    x = 16,
    y = -100
  }
  self.originalPositions[oldId] = nil
  
  -- Update saved positions in database
  local db = GetDB()
  if db.layoutPositions then
    -- Create new position entry for moved element
    db.layoutPositions[newId] = {
      point = "TOPLEFT",
      relativeTo = "Parent",
      relativePoint = "TOPLEFT",
      x = 16,
      y = -100
    }
    -- Remove old position
    db.layoutPositions[oldId] = nil
    
    -- Save to global DB immediately
    MWRBDB_V4.layoutPositions = db.layoutPositions
  end
  
  -- Clean up old drag frame completely
  if self.dragFrames[oldId] then
    local oldDragFrame = self.dragFrames[oldId]
    oldDragFrame:Hide()
    oldDragFrame:SetParent(nil)
    oldDragFrame:SetScript("OnMouseDown", nil)
    oldDragFrame:SetScript("OnMouseUp", nil)
    oldDragFrame:SetScript("OnDragStart", nil)
    oldDragFrame:SetScript("OnDragStop", nil)
    oldDragFrame:SetScript("OnEnter", nil)
    oldDragFrame:SetScript("OnLeave", nil)
    self.dragFrames[oldId] = nil
  end
  
  -- Update element's layoutEditorID
  element.layoutEditorID = newId
  
  -- Create new drag frame if in edit mode
  if self.editMode then
    local newDragFrame = self:CreateDragFrame(self.trackedElements[newId])
    -- Only show if target parent is currently visible
    if targetParent:IsVisible() then
      newDragFrame:Show()
    else
      newDragFrame:Hide()
    end
  end
  
  -- Update selections if element was selected
  if self.selectedElements[oldId] then
    self.selectedElements[newId] = self.trackedElements[newId]
    self.selectedElements[oldId] = nil
  end
  
  local tabName = newPrefix == "main_" and "Main" or "Advanced"
  print("|cff00ccffMWRB|r âœ“ Element moved to " .. tabName .. " tab")
  print("|cff00ccffMWRB|r Switch to " .. tabName .. " tab to see it")
end

function LE:ResetAllPositions()
  for id, elementData in pairs(self.trackedElements) do
    self:ResetElementPosition(id, elementData.element, elementData.parent)
  end
  
  print("|cff00ccffMWRB|r All layout positions reset to defaults")
end

function LE:RestoreAllPositions()
  local loaded = 0
  local db = GetDB()
  
  -- Check if we even have saved positions
  if not db.layoutPositions or next(db.layoutPositions) == nil then
    print("|cff00ccffMWRB|r No saved layout positions found")
    return
  end
  
  -- Count saved positions and get examples
  local savedCount = 0
  local savedExamples = {}
  for id, _ in pairs(db.layoutPositions) do
    savedCount = savedCount + 1
    if savedCount <= 3 then
      table.insert(savedExamples, id)
    end
  end
  
  print("|cff00ccffMWRB|r Found " .. savedCount .. " saved positions")
  if #savedExamples > 0 then
    print("|cff00ccffMWRB|r Saved IDs: " .. table.concat(savedExamples, ", "))
  end
  
  -- Track what IDs we're looking for
  local trackingExamples = {}
  local trackingCount = 0
  
  -- First pass: try to load positions normally
  for id, elementData in pairs(self.trackedElements) do
    trackingCount = trackingCount + 1
    if trackingCount <= 3 then
      table.insert(trackingExamples, id)
    end
    if self:LoadElementPosition(id, elementData.element, elementData.parent) then
      loaded = loaded + 1
    end
  end
  
  -- Second pass: check if any elements have been moved between tabs
  -- Look for saved positions with opposite prefix
  for id, elementData in pairs(self.trackedElements) do
    local currentPrefix = elementData.tabPrefix or ""
    local oppositePrefix = ""
    
    if currentPrefix == "main_" then
      oppositePrefix = "adv_"
    elseif currentPrefix == "adv_" then
      oppositePrefix = "main_"
    end
    
    -- Check if there's a saved position with the opposite prefix
    if oppositePrefix ~= "" then
      local baseId = id:gsub("^" .. currentPrefix, "")
      local oppositeId = oppositePrefix .. baseId
      
      if db.layoutPositions[oppositeId] then
        -- Element was saved in the other tab, move it there
        print("|cff00ccffMWRB|r Found saved position for element in opposite tab, moving it")
        
        local targetPrefix = oppositePrefix
        local targetParent
        if targetPrefix == "main_" then
          targetParent = _G["MWRB_MainContent"]
        else
          targetParent = _G["MWRB_AdvancedContent"]
        end
        
        if targetParent then
          -- Move element to target parent
          local element = elementData.element
          element:SetParent(targetParent)
          
          -- Load the saved position
          local pos = db.layoutPositions[oppositeId]
          element:ClearAllPoints()
          element:SetPoint(
            pos.point or "TOPLEFT",
            targetParent,
            pos.relativePoint or "TOPLEFT",
            pos.x or 0,
            pos.y or 0
          )
          
          -- Update tracking with new ID
          local newId = oppositeId
          self.trackedElements[newId] = {
            element = element,
            parent = targetParent,
            id = newId,
            tabPrefix = targetPrefix
          }
          self.trackedElements[id] = nil
          
          element.layoutEditorID = newId
          loaded = loaded + 1
        end
      end
    end
  end
  
  print("|cff00ccffMWRB|r Current IDs: " .. table.concat(trackingExamples, ", "))
  
  if loaded > 0 then
    print("|cff00ccffMWRB|r Successfully loaded " .. loaded .. " custom layout positions")
  else
    print("|cff00ccffMWRB|r WARNING: Saved IDs don't match current element IDs!")
  end
end

-- ===================================================================
-- SECTION 09 â€“ Auto-Track Options Panel Elements
-- ===================================================================
function LE:AutoTrackOptionsPanel(optionsPanel)
  if not optionsPanel then 
    DebugPrint("No options panel provided")
    return 
  end
  
  -- Clear existing tracked elements
  self.trackedElements = {}
  self.originalPositions = {}
  
  -- Track elements in both Main and Advanced content frames
  local contentFrames = {
    {frame = optionsPanel.mainContent, prefix = "main_"},
    {frame = optionsPanel.advancedContent, prefix = "adv_"}
  }
  
  for _, tabInfo in ipairs(contentFrames) do
    local contentFrame = tabInfo.frame
    local prefix = tabInfo.prefix
    
    if contentFrame then
      -- Reset element counters for stable ID generation
      elementCounters = {}
      
      DebugPrint("Auto-tracking content frame elements with prefix:", prefix)
      
      -- Track all children of the content frame
      local children = {contentFrame:GetChildren()}
      for _, child in ipairs(children) do
        if child:IsObjectType("Frame") or child:IsObjectType("Button") or 
           child:IsObjectType("CheckButton") or child:IsObjectType("Slider") then
          self:RegisterElement(child, contentFrame, prefix)
        end
      end
      
      -- Also track font strings
      local regions = {contentFrame:GetRegions()}
      for _, region in ipairs(regions) do
        if region:IsObjectType("FontString") then
          self:RegisterElement(region, contentFrame, prefix)
        end
      end
    end
  end
  
  DebugPrint("Tracked", self:GetTrackedElementCount(), "elements total")
end

function LE:GetTrackedElementCount()
  local count = 0
  for _ in pairs(self.trackedElements) do
    count = count + 1
  end
  return count
end

-- ===================================================================
-- SECTION 10 â€“ API Exposure
-- ===================================================================
function ns.API.EnterLayoutEditMode()
  LE:EnterEditMode()
end

function ns.API.ExitLayoutEditMode(save)
  LE:ExitEditMode(save)
end

function ns.API.ToggleLayoutEditMode()
  LE:ToggleEditMode()
end

function ns.API.RegisterLayoutElement(element, parent)
  LE:RegisterElement(element, parent)
end

function ns.API.LoadLayoutPositions()
  LE:RestoreAllPositions()
end

function ns.API.ResetLayoutPositions()
  LE:ResetAllPositions()
end

function ns.API.AutoTrackOptionsPanel(panel)
  LE:AutoTrackOptionsPanel(panel)
end

function ns.API.IsLayoutEditMode()
  return LE.editMode
end

function ns.API.RefreshDragFrames()
  LE:RefreshDragFrames()
end

-- ===================================================================
-- SECTION 11 â€“ Initialization
-- ===================================================================
DebugPrint("Layout Editor module loaded")

-- ===================================================================
-- END OF MWRB_LayoutEditor.lua
-- ===================================================================