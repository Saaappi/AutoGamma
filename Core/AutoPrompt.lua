local Addon = _G.AutoGamma
local Database = Addon.modules.Database
local Logger = Addon.modules.Logger

local type = type

---@class AutoGammaAutoPrompt
---@field lastInstanceID number|nil
local AutoPrompt = {
  lastInstanceID = nil
}

Addon.modules.AutoPrompt = AutoPrompt

local POPUP_KEY = "AUTOGAMMA_AUTO_PROMPT"

local FINALITY_COLOR = "|cffFF2020"
local COLOR_RESET = "|r"

local function GetCurrentInstanceInfo()
  local inInstance, instanceType = IsInInstance()
  if not inInstance then
    return nil
  end

  if instanceType ~= "party" and instanceType ~= "raid" and instanceType ~= "scenario" then
    return nil
  end

  local name, _, _, _, _, _, _, instanceID = GetInstanceInfo()
  if type(instanceID) ~= "number" or instanceID <= 0 then
    return nil
  end

  return {
    name = name or "Unknown",
    instanceID = instanceID
  }
end

local function GetPlayerMapID()
  if not C_Map or not C_Map.GetBestMapForUnit then
    return nil
  end
  return C_Map.GetBestMapForUnit("player")
end

local function EnsurePopup()
  if StaticPopupDialogs[POPUP_KEY] then
    return
  end

  StaticPopupDialogs[POPUP_KEY] = {
    text = "Would you like to adjust the gamma for %s?\n\n"
      .. FINALITY_COLOR
      .. "Your decision here is final and will not be shown for this instance again."
      .. COLOR_RESET,
    button1 = YES,
    button2 = NO,
    hideOnEscape = true,
    timeout = 0,
    whileDead = true,
    preferredIndex = 3,
    OnAccept = function(_, data)
      if data and type(data.instanceID) == "number" then
        Database:SetInstancePromptDecision(data.instanceID, true)
      end

      local mapID = GetPlayerMapID()
      if Addon.modules.UI and Addon.modules.UI.OpenForMap then
        Addon.modules.UI:OpenForMap(mapID)
      elseif Addon.modules.UI and Addon.modules.UI.Toggle then
        if not Addon.modules.UI.frame or not Addon.modules.UI.frame:IsShown() then
          Addon.modules.UI:Toggle()
        end
      end
    end,
    OnCancel = function(_, data)
      if data and type(data.instanceID) == "number" then
        Database:SetInstancePromptDecision(data.instanceID, false)
      end
    end
  }
end

---@return boolean
function AutoPrompt:IsEnabled()
  if Database and Database.GetAutoPromptEnabled then
    return Database:GetAutoPromptEnabled()
  end
  local db = Addon.db
  return (db and db.autoPrompt) == true
end

---@param instanceID number
---@return boolean
function AutoPrompt:HasFinalDecision(instanceID)
  if Database and Database.HasInstancePromptDecision then
    return Database:HasInstancePromptDecision(instanceID)
  end
  local db = Addon.db
  return db and db.SetInstancePromptDecision and db.SetInstancePromptDecision[instanceID] ~= nil
end

function AutoPrompt:MaybePrompt()
  if not self:IsEnabled() then
    return
  end

  local info = GetCurrentInstanceInfo()
  if not info then
    self.lastInstanceID = nil
    return
  end

  -- Avoid duped prompts during the same transition.
  if self.lastInstanceID == info.instanceID then
    return
  end
  self.lastInstanceID = info.instanceID

  if self:HasFinalDecision(info.instanceID) then
    return
  end

  EnsurePopup()

  StaticPopup_Show(POPUP_KEY, info.name, nil, { instanceID = info.instanceID })
end

return AutoPrompt
