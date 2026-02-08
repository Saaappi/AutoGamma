local addonName = ...

---@class AutoGammaAddon
---@field name string
---@field db table
---@field events Frame
---@field modules table<string, table>
local Addon = {
  name = addonName,
  db = nil,
  events = nil,
  modules = {},
}

_G.AutoGamma = Addon

---@return AutoGammaAddon
function Addon:Get()
  return self
end
