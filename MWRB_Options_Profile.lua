-- ===================================================================
-- MWRB_Options_Profile.lua
-- Snapshot-based profile system
-- You're always in "Current Settings" - profiles are just saved snapshots
-- ===================================================================

-- Class check - Exit if not Shaman
local _, playerClass = UnitClass("player")
if playerClass ~= "SHAMAN" then return end

local ADDON, ns = ...
ns.Options = ns.Options or {}

local function GetDB()
  return ns.API.GetDB()
end

local function GetGlobalDB()
  return ns.API.GetGlobalDB()
end

-- ===================================================================
-- PROFILE SNAPSHOT FUNCTIONS
-- ===================================================================

-- Initialize snapshots table
local function InitSnapshots()
  local globalDB = GetGlobalDB()
  if not globalDB.profileSnapshots then
    globalDB.profileSnapshots = {}
  end
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
    setmetatable(copy, DeepCopy(getmetatable(orig)))
  else
    copy = orig
  end
  return copy
end

-- Save current settings as a snapshot
local function SaveSnapshot(snapshotName)
  InitSnapshots()
  local globalDB = GetGlobalDB()
  local currentSettings = GetDB()
  
  -- Deep copy current settings
  globalDB.profileSnapshots[snapshotName] = DeepCopy(currentSettings)
  
  -- Only print if debug is enabled
  if currentSettings.debug then
    print("|cff00ccffMWRB|r Saved current settings as: |cff00ff00" .. snapshotName .. "|r")
    print("|cff00ccffMWRB|r |cffff0000Type /reload to save to disk|r")
  end
end

-- Load a snapshot (copies settings to current work area)
local function LoadSnapshot(snapshotName)
  InitSnapshots()
  local globalDB = GetGlobalDB()
  
  if not globalDB.profileSnapshots[snapshotName] then
    local db = GetDB()
    if db and db.debug then
      print("|cff00ccffMWRB|r |cffff0000ERROR:|r Snapshot '" .. snapshotName .. "' not found!")
    end
    return false
  end
  
  local currentSettings = GetDB()
  local snapshot = globalDB.profileSnapshots[snapshotName]
  
  -- Copy all settings from snapshot to current working area
  for k, v in pairs(snapshot) do
    currentSettings[k] = DeepCopy(v)
  end
  
  -- Only print if debug is enabled
  if currentSettings.debug then
    print("|cff00ccffMWRB|r Loaded settings from: |cff00ff00" .. snapshotName .. "|r")
  end
  
  -- Refresh display
  if ns.API.RefreshDisplay then
    ns.API.RefreshDisplay()
  end
  if ns.API.ApplyLayout then
    ns.API.ApplyLayout()
  end
  
  return true
end

-- Delete a snapshot
local function DeleteSnapshot(snapshotName)
  InitSnapshots()
  local globalDB = GetGlobalDB()
  local db = GetDB()
  
  if globalDB.profileSnapshots[snapshotName] then
    globalDB.profileSnapshots[snapshotName] = nil
    
    -- Only print if debug is enabled
    if db and db.debug then
      print("|cff00ccffMWRB|r Deleted snapshot: |cff00ff00" .. snapshotName .. "|r")
      print("|cff00ccffMWRB|r |cffff0000Type /reload to save to disk|r")
    end
    return true
  end
  
  return false
end

-- Get list of saved snapshots
local function GetSnapshotList()
  InitSnapshots()
  local globalDB = GetGlobalDB()
  local snapshots = {}
  
  for name, _ in pairs(globalDB.profileSnapshots) do
    snapshots[name] = name
  end
  
  -- Always have at least one option to prevent empty dropdown
  if not next(snapshots) then
    snapshots[""] = "No saved profiles"
  end
  
  return snapshots
end

-- ===================================================================
-- PROFILE OPTIONS UI
-- ===================================================================
function ns.Options.GetProfileOptions()
  InitSnapshots()
  
  return {
    type = "group",
    name = "Profiles",
    args = {
      spacer1 = {
        type = "header",
        name = "Save Current Settings as Profile",
        order = 10
      },
      
      saveProfileName = {
        type = "input",
        name = "Profile Name",
        desc = "Enter a name to save your current settings",
        get = function() 
          return ns.tempSnapshotName or ""
        end,
        set = function(info, value)
          ns.tempSnapshotName = value
        end,
        order = 11,
        width = "full"
      },
      
      saveButton = {
        type = "execute",
        name = "Save as New Profile",
        desc = "Save your current settings as a new profile",
        func = function()
          local snapshotName = ns.tempSnapshotName or ""
          snapshotName = strtrim(snapshotName)
          local db = GetDB()
          
          if snapshotName == "" then
            if db and db.debug then
              print("|cff00ccffMWRB|r |cffff0000ERROR:|r Please enter a profile name first!")
            end
            return
          end
          
          local snapshots = GetSnapshotList()
          if snapshots[snapshotName] and snapshots[snapshotName] ~= "No saved profiles" then
            if db and db.debug then
              print("|cff00ccffMWRB|r |cffff0000ERROR:|r Profile '" .. snapshotName .. "' already exists! Use Overwrite instead.")
            end
            return
          end
          
          SaveSnapshot(snapshotName)
          ns.tempSnapshotName = ""
        end,
        order = 12
      },
      
      spacer2 = {
        type = "header",
        name = "Load Profile",
        order = 20
      },
      
      loadProfile = {
        type = "select",
        name = "Select Profile to Load",
        desc = "Choose a saved profile to load (copies its settings to your current work)",
        values = GetSnapshotList,
        get = function() return "" end,
        set = function(info, value)
          if value and value ~= "" then
            LoadSnapshot(value)
          end
        end,
        order = 21
      },
      
      profileList = {
        type = "description",
        name = function()
          local snapshots = GetSnapshotList()
          if snapshots[""] == "No saved profiles" then
            return "|cffff6b6bNo saved profiles yet|r"
          end
          
          local list = "|cff00ff00Saved Profiles:|r\n"
          local sorted = {}
          for name, _ in pairs(snapshots) do
            if name ~= "" then
              table.insert(sorted, name)
            end
          end
          table.sort(sorted)
          
          for _, name in ipairs(sorted) do
            list = list .. "  • " .. name .. "\n"
          end
          
          return list
        end,
        fontSize = "medium",
        order = 22
      },
      
      spacer3 = {
        type = "header",
        name = "Overwrite Existing Profile",
        order = 30
      },
      
      overwriteProfile = {
        type = "select",
        name = "Select Profile to Overwrite",
        desc = "Save current settings over an existing profile",
        values = GetSnapshotList,
        get = function() return "" end,
        set = function(info, value)
          if value and value ~= "" then
            SaveSnapshot(value)
          end
        end,
        order = 31,
        confirm = true,
        confirmText = "This will overwrite the selected profile with your current settings. Continue?"
      },
      
      spacer4 = {
        type = "header",
        name = "Delete Profile",
        order = 40
      },
      
      deleteProfile = {
        type = "select",
        name = "Select Profile to Delete",
        desc = "Permanently delete a saved profile",
        values = GetSnapshotList,
        get = function() return "" end,
        set = function(info, value)
          if value and value ~= "" then
            DeleteSnapshot(value)
          end
        end,
        order = 41,
        confirm = true,
        confirmText = "Are you sure you want to delete this profile?"
      },
      
      spacer5 = {
        type = "header",
        name = "Import/Export",
        order = 50
      },
      
      exportDesc = {
        type = "description",
        name = "Export your current settings as a shareable string that others can import.",
        fontSize = "medium",
        order = 51
      },
      
      exportButton = {
        type = "execute",
        name = "Export Current Settings",
        desc = "Generate an export string from your current settings",
        func = function()
          local db = GetDB()
          
          if not ns.ImportExport then
            if db and db.debug then
              print("|cff00ccffMWRB|r |cffff0000ERROR:|r Import/Export module not loaded!")
            end
            return
          end
          
          local exportString, err = ns.ImportExport.ExportProfile()
          if not exportString then
            if db and db.debug then
              print("|cff00ccffMWRB|r |cffff0000ERROR:|r " .. (err or "Export failed"))
            end
            return
          end
          
          -- Store for display
          ns.tempExportString = exportString
          
          if db and db.debug then
            print("|cff00ccffMWRB|r Export string generated! Copy it from the text box below.")
          end
        end,
        order = 52
      },
      
      exportString = {
        type = "input",
        name = "Export String",
        desc = "Copy this string to share your profile",
        multiline = 8,
        width = "full",
        get = function()
          return ns.tempExportString or "Click 'Export Current Settings' to generate"
        end,
        set = function() end,  -- Read-only
        order = 53
      },
      
      importDesc = {
        type = "description",
        name = "\nImport a profile from an export string.",
        fontSize = "medium",
        order = 54
      },
      
      importString = {
        type = "input",
        name = "Import String",
        desc = "Paste an export string here",
        multiline = 8,
        width = "full",
        get = function()
          return ns.tempImportString or ""
        end,
        set = function(info, value)
          ns.tempImportString = value
        end,
        order = 55
      },
      
      importButton = {
        type = "execute",
        name = "Import Profile",
        desc = "Load settings from the import string above",
        func = function()
          local db = GetDB()
          
          if not ns.ImportExport then
            if db and db.debug then
              print("|cff00ccffMWRB|r |cffff0000ERROR:|r Import/Export module not loaded!")
            end
            return
          end
          
          local importString = ns.tempImportString or ""
          if importString == "" then
            if db and db.debug then
              print("|cff00ccffMWRB|r |cffff0000ERROR:|r Please paste an import string first!")
            end
            return
          end
          
          local success, msg = ns.ImportExport.ImportProfile(importString)
          if success then
            if db and db.debug then
              print("|cff00ccffMWRB|r |cff00ff00" .. msg .. "|r")
            end
            ns.tempImportString = ""
          else
            if db and db.debug then
              print("|cff00ccffMWRB|r |cffff0000ERROR:|r " .. msg)
            end
          end
        end,
        order = 56,
        confirm = true,
        confirmText = "This will overwrite your current settings. Continue?"
      }
    }
  }
end

-- Initialize temp variables
ns.tempSnapshotName = ""
ns.tempExportString = ""
ns.tempImportString = ""

-- ===================================================================
-- END OF MWRB_Options_Profile.lua
-- ===================================================================