-- Knapsack (singleton) class

local Knapsack = {
  -- class constants
  width = display.contentWidth,
  height = 128 * 1.5,
  xc = display.contentWidth / 2,
  yc = display.contentHeight - (128 * 0.75),

  -- class data
  items = nil,
  -- class display objects

  group = nil,
  rect = nil,
  pauseButton = nil,
  pauseButtonIcon = nil,
  gauges = nil,
}

local types = {
  'health',
  'teleport',
  -- 'action',
  'illumination',
  'fireball',
}

function Knapsack:new()
  local o = {}
  self.__index = Knapsack
  setmetatable(o, self)

  local slotWidth = display.contentWidth / (#types + 1)
  o.slots = {
    o.xc - slotWidth * 2,
    o.xc - slotWidth,
    -- o.xc,   -- middle/three slot reserved for pause button
    o.xc + slotWidth,
    o.xc + slotWidth * 2,
  }

  -- array of stacks, indexed by item.slot
  o.items = {
    {},
    {},
    {},
    {},
  }

  o.gauges = {}

  return o
end

local function dummyEventHandler(event)
  debug_log('knapsack dummy event', event.name, event.phase)
  return true
end

function Knapsack:setGroup(group)

  local function setPauseButtonIcon(n)
    self.pauseButtonIcon = display.newImage(self.group, _G.iconImageSheet, n)
    self.pauseButtonIcon.x = self.xc
    self.pauseButtonIcon.y = self.yc
    self.pauseButtonIcon.width = 128/2
    self.pauseButtonIcon.height = 128/2
  end

  -- adding dummy touch/tap handlers stops events propagating to tile, don't know why
  group:addEventListener('tap', dummyEventHandler)
  group:addEventListener('touch', dummyEventHandler)

  self.group = group
  self.rect = display.newRect(self.group, self.xc, self.yc, self.width, self.height)
  self.rect:setFillColor(unpack(_G.colors.black))
  self.rect.alpha = 0.5

  for s=1, #types do
    local stack = self.items[s]
    for i = 1,#stack do
      local item = stack[i]
      item:createGraphics()
      self:transition(item)
    end
  end

  -- tried using widget.newButton() but the touch event leaked onto the grid
  -- even when 'return true' from event handler

  self.pauseButton = display.newCircle(self.group, self.xc, self.yc, 128/2)
  self.pauseButton:setFillColor(unpack(_G.colors.pixie))
  -- self.pauseButton.alpha = 0.5

  self.pauseButton:addEventListener('tap', function(event)
    -- debug_table('pauseButton tap event', event)
    -- debug_log('pauseButton tap event')
    if _G.game.paused then
      _G.game.paused = false
      _G.game:resumeTimers()
      display.remove(self.pauseButtonIcon)
      setPauseButtonIcon(8)
    else
      _G.game.paused = true
      _G.game:pauseTimers()
      display.remove(self.pauseButtonIcon)
      setPauseButtonIcon(9)
    end
    return true
  end)
  -- TODO remove this event listener

  setPauseButtonIcon(8)

  self:setGauges()
end

function Knapsack:setGauges()
  for s=1, #types do
    if self.gauges[s] then
      display.remove(self.gauges[s])
      self.gauges[s] = nil
    end

    local stack = self.items[s]
    if #stack > 0 then
      local height = math.round(128 / 10)
      local item = stack[1]

      local xpos = self.slots[s]
      local ypos = self.yc + (128/2) + height
      local len = math.min(128, (128 / 8) * #stack)
      self.gauges[s] = display.newRoundedRect(self.group, xpos, ypos, len, height, height / 2)
      self.gauges[s]:setFillColor(unpack(item.color))
    end
  end
end

function Knapsack:count(item)
  assert(item.slot)
  return #self.items[item.slot]
end

function Knapsack:transition(item)
  -- item is a MagicItem
  assert(item.slot)
  local xpos = self.slots[item.slot]
  transition.moveTo(item.group, {x=xpos, y=self.yc, time=1000, transition=easing.outQuart})
end

function Knapsack:add(item)
  -- item is a MagicItem
  assert(item.slot)
  -- local indicator = display.newRoundedRect(self.group, self.slots[item.slot], self.yc, item.width, item.height, item.width / 5)
  -- indicator:setFillColor(0,0,0, 0)
  -- indicator:setStrokeColor(unpack(_G.colors.pixie))
  -- indicator.strokeWidth = 8
  -- indicator:toFront()
  table.insert(self.items[item.slot], item)
  self:setGauges()
end

function Knapsack:contains(type)
  local contains, index = table.contains(types, type)
  if contains then
    return #self.items[index] > 0
  end
  return false
end

function Knapsack:remove(item)
  -- item is a MagicItem
  assert(item.slot)
  table.remove(self.items[item.slot])
  self:setGauges()
end

function Knapsack:report()
  for i = 1, #types do
    debug_log(types[i], #self.items[i])
  end
end

return Knapsack
