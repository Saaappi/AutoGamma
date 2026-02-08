local Addon = _G.AutoGamma

local tostring = tostring
local format = string.format

---@class AutoGammaLogger
---@field enabled boolean
local Logger = {
  enabled = false,
}

Addon.modules.Logger = Logger

---@param enabled boolean
function Logger:SetEnabled(enabled)
  self.enabled = enabled == true
end

---@param msg string
---@param ... any
function Logger:Debug(msg, ...)
  if not self.enabled then
    return
  end

  msg = tostring(msg)
  print(format("|cff66C0FF%s|r: %s", Addon.name, format(msg, ...)))
end

---@param msg string
---@param ... any
function Logger:Info(msg, ...)
  msg = tostring(msg)
  print(format("|cff66C0FF%s|r: %s", Addon.name, format(msg, ...)))
end
