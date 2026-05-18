local Addon = _G.AutoGamma
local Database = Addon.modules.Database
local Gamma = Addon.modules.Gamma

local format = string.format
local floor = math.floor
local tonumber = tonumber
local type = type

---@class AutoGammaUI
---@field frame Frame
---@field preview table
local UI = {
  frame = nil,
  preview = nil,
}

Addon.modules.UI = UI

---@param frame Frame
local function ApplySavedPosition(frame)
  local db = Addon.db
  if not db or not db.ui then
    return
  end

  frame:ClearAllPoints()
  frame:SetPoint(db.ui.point, UIParent, db.ui.relPoint, db.ui.x, db.ui.y)
end

---@param frame Frame
local function SavePosition(frame)
  local db = Addon.db
  if not db then
    return
  end
  db.ui = db.ui or {}

  local point, _, relPoint, x, y = frame:GetPoint(1)
  if not point or not relPoint then
    return
  end

  db.ui.point = point
  db.ui.relPoint = relPoint
  db.ui.x = x or 0
  db.ui.y = y or 0
end

---@param mapID number|nil
---@return string
local function GetMapDisplayText(mapID)
  if type(mapID) ~= "number" then
    return "Unknown"
  end

  local info = C_Map.GetMapInfo(mapID)
  if info and info.name then
    return format("%s (%d)", info.name, mapID)
  end

  return format("MapID %d", mapID)
end

---@return number|nil
local function GetPlayerMapID()
  if not C_Map or not C_Map.GetBestMapForUnit then
    return nil
  end
  return C_Map.GetBestMapForUnit("player")
end

---@param value number
---@param minValue number
---@param maxValue number
---@return number
local function ToPercent(value, minValue, maxValue)
  if maxValue <= minValue then
    return 0
  end
  local t = (value - minValue) / (maxValue - minValue)
  if t < 0 then t = 0 end
  if t > 1 then t = 1 end
  return floor(t * 100 + 0.5)
end

function UI:ResetCurrentMap()
  local mapID = GetPlayerMapID()
  if type(mapID) ~= "number" then
    return
  end

  if Gamma.ClearOverrideForMap then
    Gamma:ClearOverrideForMap(mapID)
  else
    if Database.ClearMapGamma then
      Database:ClearMapGamma(mapID)
    else
      local db = Addon.db
      if db and db.perMap then
        db.perMap[mapID] = nil
      end
    end
    Gamma:ApplyForMap(mapID)
  end

  self:Refresh(mapID)
end

---@param mapID number|nil
function UI:Refresh(mapID)
  if not self.frame or not self.frame:IsShown() then
    return
  end

  self.frame.MapValue:SetText(GetMapDisplayText(mapID))

  if type(mapID) == "number" then
    local value = Database:GetMapGamma(mapID)
    if type(value) ~= "number" then
      value = Gamma:GetCurrent()
    end
    self.frame.GammaSlider:SetValue(value)
    local slider = self.frame.GammaSlider
    if slider and slider.GammaPercent then
      local minValue, maxValue = slider:GetMinMaxValues()
      slider.GammaPercent:SetText(format("%d%%", ToPercent(value, minValue, maxValue)))
    end

    if self.frame.ResetButton then
      if Gamma:HasOverride(mapID) then
        self.frame.ResetButton:Enable()
      else
        self.frame.ResetButton:Disable()
      end
    end

    if self.preview and self.preview.SetMapID then
      self.preview:SetMapID(mapID)
    end
  else
    if self.frame.ResetButton then
      self.frame.ResetButton:Disable()
    end
  end
end

function UI:Toggle()
  if not self.frame then
    self:Init()
  end

  if self.frame:IsShown() then
    self.frame:Hide()
    return
  end

  self.frame:Show()
  self:Refresh(GetPlayerMapID())
end

---@param mapID number|nil
function UI:OpenForMap(mapID)
  if not self.frame then
    self:Init()
  end

  if not self.frame:IsShown() then
    self.frame:Show()
  end

  if self.frame.Raise then
    self.frame:Raise()
  end

  if type(mapID) ~= "number" then
    mapID = GetPlayerMapID()
  end

  self:Refresh(mapID)
end

function UI:Init()
  if self.frame then
    return
  end

  local frame = _G.AutoGammaFrame
  self.frame = frame

  -- Preview backdrop
  do
    local preview = frame.Preview
    if preview and preview.SetBackdrop then
      preview:SetBackdrop({
        bgFile = "Interface/Tooltips/UI-Tooltip-Background",
        edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
        tile = true,
        tileSize = 16,
        edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
      })
      preview:SetBackdropColor(0, 0, 0, 0.35)
      preview:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)
    end
  end

  -- Portrait icon and title
  if frame.PortraitContainer and frame.PortraitContainer.portrait then
    frame.PortraitContainer.portrait:SetTexture(7127723)
  end
  if frame.TitleText then
    frame.TitleText:SetText("")
  end

  -- Make the addon closable with ESC key
  table.insert(UISpecialFrames, frame:GetName())

  -- Restore the saved position.
  ApplySavedPosition(frame)

  -- Drag on the title region overlay so none of the child widgets eat mouse
  -- input.
  local dragRegion = frame.DragRegion
  if dragRegion then
    dragRegion:RegisterForDrag("LeftButton")
    dragRegion:SetScript("OnDragStart", function()
      frame:StartMoving()
    end)
    dragRegion:SetScript("OnDragStop", function()
      frame:StopMovingOrSizing()
      SavePosition(frame)
    end)
  end

  frame:HookScript("OnHide", function()
    SavePosition(frame)
  end)

  -- Slider
  local slider = frame.GammaSlider
  local db = Addon.db
  local minGamma = (db and db.minGamma) or 0.3
  local maxGamma = (db and db.maxGamma) or 2.8
  local step = (db and db.step) or 0.01

  slider:SetMinMaxValues(minGamma, maxGamma)
  slider:SetValueStep(step)
  slider:SetObeyStepOnDrag(true)

  local percentLabel = frame.GammaSlider.GammaPercent
  if percentLabel then
    local current = slider:GetValue()
    percentLabel:SetText(format("%d%%", ToPercent(current, minGamma, maxGamma)))
  end

  _G[slider:GetName() .. "Low"]:SetText(format("%0.1f", minGamma))
  _G[slider:GetName() .. "High"]:SetText(format("%0.1f", maxGamma))
  _G[slider:GetName() .. "Text"]:SetText("Gamma (this map)")

  slider:SetScript("OnValueChanged", function(_, value, userInput)
    value = tonumber(value)
    if type(value) ~= "number" then
      return
    end

    if frame.GammaSlider.GammaPercent then
      frame.GammaSlider.GammaPercent:SetText(format("%d%%", ToPercent(value, minGamma, maxGamma)))
    end

    if not userInput then
      return
    end

    -- Persist to current map first, then apply through Gamma:ApplyForMap so
    -- that the baseline is captured and activeMapID is set correctly. This
    -- ensures RestoreBaselineIfNeeded works when the player leaves the area.
    -- Fall back to a direct Set when there is no valid mapID (e.g. open world).
    local mapID = GetPlayerMapID()
    if type(mapID) == "number" then
      Database:SetMapGamma(mapID, value)
      Gamma:ApplyForMap(mapID)
    else
      Gamma:Set(value)
    end

    if frame.ResetButton then
      frame.ResetButton:Enable()
    end
  end)

  -- Reset button
  do
    local resetButton = frame.ResetButton
    if resetButton then
      resetButton:SetScript("OnClick", function()
        UI:ResetCurrentMap()
      end)
      resetButton:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Reset Gamma", 1, 1, 1)
        GameTooltip:AddLine("Remove the saved gamma override for the current map and restore your default gamma.", nil, nil, nil, true)
        GameTooltip:Show()
      end)
      resetButton:SetScript("OnLeave", function()
        GameTooltip:Hide()
      end)
      resetButton:Disable()
    end
  end

  -- Preview module
  do
    local previewParent = frame.Preview
    if Addon.modules.MapPreview and previewParent then
      self.preview = Addon.modules.MapPreview:Create(previewParent)
    else
      self.preview = nil
    end
  end
end
