local Addon = _G.AutoGamma

local type = type

---@class AutoGammaDatabase
local Database = {}

Addon.modules.Database = Database

---@param db table
local function EnsureDefaults(db)
  db = db or {}
  db.perMap = db.perMap or {} ---@type table<number, number>
  db.minGamma = db.minGamma or 0.3
  db.maxGamma = db.maxGamma or 2.8
  db.step = db.step or 0.01

  -- Settings
  if db.autoPrompt == nil then
    db.autoPrompt = true
  end

  -- Per instance decisions (final)
  db.instancePromptDecisions = db.instancePromptDecisions or {} ---@type table<number, boolean>

  -- UI position
  db.ui = db.ui or {}
  db.ui.point = db.ui.point or "CENTER"
  db.ui.relPoint = db.ui.relPoint or "CENTER"
  db.ui.x = db.ui.x or 0
  db.ui.y = db.ui.y or 0

  return db
end

---@return table
function Database:Init()
  _G.AutoGammaDB = EnsureDefaults(_G.AutoGammaDB)
  Addon.db = _G.AutoGammaDB

  -- Data hygiene: older versions cleared overrides as 1.000000.
  -- Treat that as "no override" and delete it so baseline restoration
  -- works properly.
  local db = Addon.db
  if db and db.perMap then
    for mapID, value in pairs(db.perMap) do
      if type(value) == "number" and value == 1.0 then
        db.perMap[mapID] = nil
      end
    end
  end

  return Addon.db
end

---@param mapID number
---@return number|nil
function Database:GetMapGamma(mapID)
  local db = Addon.db
  if not db or type(mapID) ~= "number" then
    return nil
  end
  return db.perMap[mapID]
end

---@param mapID number
---@param value number
function Database:SetMapGamma(mapID, value)
  local db = Addon.db
  if not db or type(mapID) ~= "number" or type(value) ~= "number" then
    return
  end
  db.perMap[mapID] = value
end

---@param mapID number
function Database:ClearMapGamma(mapID)
  local db = Addon.db
  if not db or type(mapID) ~= "number" then
    return
  end
  db.perMap[mapID] = nil
end

---@return boolean
function Database:GetAutoPromptEnabled()
  local db = Addon.db
  return (db and db.autoPrompt) == true
end

---@param enabled boolean
function Database:SetAutoPromptEnabled(enabled)
  local db = Addon.db
  if not db then
    return
  end
  db.autoPrompt = enabled == true
end

---@param instanceID number
---@return boolean
function Database:HasInstancePromptDecision(instanceID)
  local db = Addon.db
  if not db or type(instanceID) ~= "number" then
    return false
  end
  db.instancePromptDecisions = db.instancePromptDecisions or {}
  return db.instancePromptDecisions[instanceID] ~= nil
end

---@param instanceID number
---@param decision boolean
function Database:SetInstancePromptDecision(instanceID, decision)
  local db = Addon.db
  if not db or type(instanceID) ~= "number" then
    return
  end
  db.instancePromptDecisions = db.instancePromptDecisions or {}
  db.instancePromptDecisions[instanceID] = decision == true
end
