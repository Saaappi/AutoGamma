local Addon = _G.AutoGamma
local Database = Addon.modules.Database

---@class AutoGammaSettings
local SettingsModule = {}

Addon.modules.Settings = SettingsModule

local SETTINGS_VAR = "AUTOGAMMA_AUTO_PROMPT"

---@return boolean
function SettingsModule:GetAutoPromptEnabled()
  if Database and Database.GetAutoPromptEnabled then
    return Database:GetAutoPromptEnabled()
  end
  local db = Addon.db
  return (db and db.autoPrompt) == true
end

---@param enabled boolean
function SettingsModule:SetAutoPromptEnabled(enabled)
  if Database and Database.SetAutoPromptEnabled then
    Database:SetAutoPromptEnabled(enabled)
    return
  end
  local db = Addon.db
  if not db then
    return
  end
  db.autoPrompt = enabled == true
end

function SettingsModule:Init()
  if not Settings or not Settings.RegisterVerticalLayoutCategory then
    return
  end

  if self.category then
    return
  end

  local category = Settings.RegisterVerticalLayoutCategory(Addon.name)
  self.category = category

  local setting = Settings.RegisterAddOnSetting(
    category,
    SETTINGS_VAR,
    "autoPrompt",
    Addon.db,
    Settings.VarType.Boolean,
    "Auto Prompt",
    Settings.Default.True
  )

  setting:SetValueChangedCallback(function(_, value)
    SettingsModule:SetAutoPromptEnabled(value == true)
  end)

  Settings.CreateCheckbox(category, setting)
  Settings.RegisterAddOnCategory(category)
end

function SettingsModule:Open()
  if not self.category then
    self:Init()
  end

  if not self.category or not Settings or not Settings.OpenToCategory then
    return
  end

  Settings.OpenToCategory(self.category:GetID())
end

return SettingsModule
