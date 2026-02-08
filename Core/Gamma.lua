local Addon = _G.AutoGamma
local Logger = Addon.modules.Logger
local Database = Addon.modules.Database

local tonumber = tonumber
local min = math.min
local max = math.max

---@class AutoGammaGamma
---@field baseline number|nil
---@field activeMapID number|nil
local Gamma = {
  baseline = nil,
  activeMapID = nil,
}

Addon.modules.Gamma = Gamma

local CVAR_NAME = "Gamma"

---@return number
function Gamma:GetCurrent()
  local value = C_CVar.GetCVar(CVAR_NAME)
  return tonumber(value) or 1.0
end

---@param value number
---@return number
function Gamma:Clamp(value)
  local db = Addon.db
  local lo = (db and db.minGamma) or 0.3
  local hi = (db and db.maxGamma) or 2.8
  return max(lo, min(hi, value))
end

---@param value number
function Gamma:Set(value)
  value = self:Clamp(value)
  C_CVar.SetCVar(CVAR_NAME, value)
  Logger:Debug("Set Gamma=%0.2f", value)
end

---@param mapID number
---@return boolean
function Gamma:HasOverride(mapID)
  local value = Database:GetMapGamma(mapID)
  return type(value) == "number" and value ~= 1.0
end

---@param mapID number
function Gamma:ApplyForMap(mapID)
  if type(mapID) ~= "number" then
    self:RestoreBaselineIfNeeded()
    return false, nil
  end

  local override = Database:GetMapGamma(mapID)
  if type(override) ~= "number" or override == 1.0 then
    -- No override for this map, so restore if a previous override was in place.
    self:RestoreBaselineIfNeeded()
    return false, nil
  end

  -- If we're entering override mode from baseline, capture the baseline once.
  if self.activeMapID == nil then
    self.baseline = self:GetCurrent()
  end

  self.activeMapID = mapID
  self:Set(override)
  return true, override
end

---@param mapID number
function Gamma:ClearOverrideForMap(mapID)
  if type(mapID) ~= "number" then
    return
  end

  -- Clear persistence.
  Database:ClearMapGamma(mapID)

  -- If this override is currently active, revert it immediately.
  if self.activeMapID == mapID then
    self:RestoreBaselineIfNeeded()
    return
  end
end

function Gamma:RestoreBaselineIfNeeded()
  if self.activeMapID == nil then
    return
  end

  local baseline = self.baseline
  self.activeMapID = nil
  self.baseline = nil

  if type(baseline) == "number" then
    self:Set(baseline)
  end
end
