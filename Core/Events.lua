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

Addon.modules.Events = Events

---@return number|nil
local function GetPlayerMapID()
  if not C_Map or not C_Map.GetBestMapForUnit then
    return nil
  end
  return C_Map.GetBestMapForUnit("player")
end

---@param mapID number|nil
function Events:OnMapPossiblyChanged(mapID)
  local prevMapID = self.lastMapID
  self.lastMapID = mapID

  local inInstance, instanceType = IsInInstance()
  if not inInstance or instanceType == "none" then
    Gamma:RestoreBaselineIfNeeded()

    if Addon.modules.UI and Addon.modules.UI.Refresh then
      Addon.modules.UI:Refresh(mapID)
    end
    return
  end

  if type(mapID) ~= "number" then
    --Gamma:RestoreBaselineIfNeeded()
    return
  end

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

  if event == "PLAYER_ENTERING_WORLD" or event == "ZONE_CHANGED_NEW_AREA" then
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
  f:RegisterEvent("PLAYER_ENTERING_WORLD")
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
