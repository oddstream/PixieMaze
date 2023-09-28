-- class MagicItem

local MagicItem = {
  -- prototype object
  -- class constants
  width = 128,
  height = 128,

  -- class data
  type = nil,
  color = nil,
  colorText = nil,
  slot = nil,
  duration = nil,

  -- class display objects
  group = nil,
  rect = nil,
  icon = nil,
}

function MagicItem:new(o)
  o = o or {}
  self.__index = self
  setmetatable(o, self)

  assert(o.type)

  o:createGraphics()

  return o
end

function MagicItem:createGraphics()

  self.group = display.newGroup()
  self.group.x = self.x
  self.group.y = self.y
  self.rect = display.newRoundedRect(self.group, 0, 0, self.width, self.height, self.width / 5) -- corner radius is 20% of width
  self.rect:setFillColor(unpack(self.color))
  self.rect:addEventListener('tap', function()
    _G.game:magic(self)
    return true
  end)
  self.rect.alpha = 1

  self.icon = display.newImage(self.group, _G.iconImageSheet, self.slot)
  self.icon.width = self.width * 0.8
  self.icon.height = self.height * 0.8

  _G.game.knapsack.group:insert(self.group)

end

--[[
function MagicItem:transitionToPixie()
  -- self is in knapsackGroup, not mazeGroup, so need to adjust coords
  local xc, yc = _G.game.pixie.tile.center.x, _G.game.pixie.tile.center.x
  local halfViewPortWidth = display.contentWidth / 2
  local halfViewPortHeight = display.contentHeight / 2
  local xNew, yNew = xc - halfViewPortWidth, yc - halfViewPortHeight
  transition.moveTo(self.rect, {
    x = xNew,
    y = yNew,
    time = 1000,
    transition = easing.outQuart,
    onComplete = function()
      self:destroy()
    end
  })
end
]]

--[[
  General destructor; need to dispose of
    Runtime listeners
    transitions and timers
    audio
    open files
]]
function MagicItem:destroy()
  -- debug_log('destroy item', self.type)
  self.rect:removeEventListener('tap', self)
  self.group:removeSelf()
end

return MagicItem
