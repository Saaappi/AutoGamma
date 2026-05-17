local Addon = _G.AutoGamma
local Logger = Addon.modules.Logger
local Database = Addon.modules.Database
local Gamma = Addon.modules.Gamma
local SettingsModule = Addon.modules.Settings
local AutoPrompt = Addon.modules.AutoPrompt

local type = type
local strtrim = string.trim
local strlower = string.lower

---@class AutoGammaEvents
local Events = {}

Events.lastMapID = nil ---@type number|nil
Events.retryScheduled = false
Events.retryCount = 0
Events.retryToken = 0

Addon.modules.Events = Events

local MAP_RETRY_DELAY_SECONDS = 0.25
local MAX_MAP_RETRY_ATTEMPTS = 8

---@return number|nil
local function GetPlayerMapID()
  if not C_Map or not C_Map.GetBestMapForUnit then
    return nil
  end
  return C_Map.GetBestMapForUnit("player")
end

function Events:ResetMapRetry()
  self.retryToken = self.retryToken + 1
  self.retryScheduled = false
  self.retryCount = 0
end

function Events:ScheduleMapRetry()
  if self.retryScheduled then
    return
  end

  if not C_Timer or not C_Timer.After then
    return
  end

  if self.retryCount >= MAX_MAP_RETRY_ATTEMPTS then
    Logger:Debug("Map lookup remained unavailable after %d retry attempts.", self.retryCount)
    return
  end

  local token = self.retryToken
  self.retryScheduled = true

  C_Timer.After(MAP_RETRY_DELAY_SECONDS, function()
    if self.retryToken ~= token then
      return
    end

    self.retryScheduled = false
    self.retryCount = self.retryCount + 1
    self:OnMapPossiblyChanged(GetPlayerMapID())
  end)
end

---@param mapID number|nil
function Events:OnMapPossiblyChanged(mapID)
  local prevMapID = self.lastMapID
  local inInstance, instanceType = IsInInstance()

  -- Not in an instance - restore regardless of mapID availability.
  if not inInstance or instanceType == "none" then
    self:ResetMapRetry()
    self.lastMapID = mapID
    Gamma:RestoreBaselineIfNeeded()

    if Addon.modules.UI and Addon.modules.UI.Refresh then
      Addon.modules.UI:Refresh(mapID)
    end
    return
  end

  -- In an instance, but mapID is not available yet.
  if type(mapID) ~= "number" then
    self:ScheduleMapRetry()
    return
  end

  -- In an instance with a valid mapID.
  self:ResetMapRetry()
  self.lastMapID = mapID

  local applied, appliedValue = Gamma:ApplyForMap(mapID)
  if applied and prevMapID ~= mapID then
    local mapName = tostring(mapID)
    if C_Map and C_Map.GetMapInfo then
      local info = C_Map.GetMapInfo(mapID)
      if info and info.name then
        mapName = info.name
      end
    end

    Logger:Info("Applying saved gamma for %s (%0.2f).", mapName, appliedValue or 1.0)
  end

  -- If UI is open, refresh it.
  if Addon.modules.UI and Addon.modules.UI.Refresh then
    Addon.modules.UI:Refresh(mapID)
  end
end

---@param event string
function Events:OnEvent(event, ...)
  if event == "ADDON_LOADED" then
    local name = ...
    if name ~= Addon.name then
      return
    end

    Database:Init()

    if SettingsModule and SettingsModule.Init then
      SettingsModule:Init()
    end

    -- Slash commands
    SLASH_AUTOGAMMA1 = "/autogamma"
    SlashCmdList.AUTOGAMMA = function(msg)
      msg = strlower(strtrim(msg or ""))

      if msg == "settings" then
        if SettingsModule and SettingsModule.Open then
          SettingsModule:Open()
        end
        return
      end

      if Addon.modules.UI and Addon.modules.UI.Toggle then
          Addon.modules.UI:Toggle()
      end
    end

    self:OnMapPossiblyChanged(GetPlayerMapID())
    return
  end

  -- A loading screen is starting (zone/instance transition).
  -- Restore baseline eagerly so gamma is correct before the new area loads.
  -- This is a no-op if no override is currently active.
  if event == "LOADING_SCREEN_ENABLED" then
    Gamma:RestoreBaselineIfNeeded()
    return
  end

  if event == "PLAYER_ENTERING_WORLD"
    or event == "ZONE_CHANGED"
    or event == "ZONE_CHANGED_INDOORS"
    or event == "ZONE_CHANGED_NEW_AREA"
    or event == "LOADING_SCREEN_DISABLED"
  then
    self:OnMapPossiblyChanged(GetPlayerMapID())

    if AutoPrompt and AutoPrompt.MaybePrompt then
      AutoPrompt:MaybePrompt()
    end

    return
  end
end

---@return Frame
function Events:Init()
  if Addon.events then
    return Addon.events
  end

  local f = CreateFrame("Frame")
  Addon.events = f

  f:SetScript("OnEvent", function(_, event, ...)
    Events:OnEvent(event, ...)
  end)

  f:RegisterEvent("ADDON_LOADED")
  f:RegisterEvent("LOADING_SCREEN_ENABLED")
  f:RegisterEvent("LOADING_SCREEN_DISABLED")
  f:RegisterEvent("PLAYER_ENTERING_WORLD")
  f:RegisterEvent("ZONE_CHANGED")
  f:RegisterEvent("ZONE_CHANGED_INDOORS")
  f:RegisterEvent("ZONE_CHANGED_NEW_AREA")

  Logger:Debug("Events initialized.")
  return f
end

Events:Init()

-- Addon compartment global click handler
function _G.AutoGamma_OnAddonCompartmentClick(_, button)
  if button == "RightButton" then
    if SettingsModule and SettingsModule.Open then
      SettingsModule:Open()
    end
    return
  end

  if Addon.modules.UI and Addon.modules.UI.Toggle then
    Addon.modules.UI:Toggle()
  end
end
