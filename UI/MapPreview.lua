local Addon = _G.AutoGamma

local format = string.format
local floor = math.floor

---@class AutoGammaMapPreview
---@field frame Frame
---@field swatches Texture[]
---@field labels FontString[]
local MapPreview = {}

Addon.modules.MapPreview = MapPreview

---@param parent Frame
---@return AutoGammaMapPreview
function MapPreview:Create(parent)
  if not parent then
    return nil
  end

  local obj = {
    frame = parent,
    swatches = {},
    labels = {},
    mapID = nil
  }
  setmetatable(obj, { __index = self })

  local pad = 14
  local topOffset = 62
  local width = parent:GetWidth() - (pad * 2)
  local height = parent:GetHeight() - (pad * 2) - topOffset

  local rows = 2
  local columns = 4
  local cellWidth = width / columns
  local cellHeight = height / rows

  local values = {
    { 0.125, 0.25, 0.375, 0.50 },
    { 0.625, 0.75, 0.875, 1.00 }
  }

  for row = 1, rows do
    for column = 1, columns do
      local idx = (row - 1) * columns + column

      local tex = parent:CreateTexture(nil, "ARTWORK")
      tex:SetSize(cellWidth - 6, cellHeight - 6)
      tex:SetPoint("TOPLEFT", parent, "TOPLEFT", pad + (column - 1) * cellWidth + 3, -topOffset - (row - 1) * cellHeight - 3)
      tex:SetColorTexture(values[row][column], values[row][column], values[row][column], 1)
      obj.swatches[idx] = tex

      local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
      fs:SetPoint("CENTER", tex, "CENTER", 0, 0)
      fs:SetText(format("%d%%", floor(values[row][column] * 100 + 0.5)))
      obj.labels[idx] = fs
    end
  end

  local border = parent:CreateTexture(nil, "BORDER")
  border:SetAllPoints(parent)
  border:SetColorTexture(0, 0, 0, 0)

  return obj
end

---@param mapID number|nil
function MapPreview:SetMapID(mapID)
  self.mapID = mapID
end
